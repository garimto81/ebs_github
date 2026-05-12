#!/usr/bin/env python3
"""
post_build_fail.py — PostToolUse hook (EBS Conductor)

v1 (2026-04-20): 프로토타입 빌드/테스트 실패 감지 시 Type A/B/C 분류 프로토콜 stdout reminder.
v2 (2026-05-11, S11 Cycle 2/3/5 #240/#254/#284): broker MCP publish + retry + observer dispatch.
v3 (2026-05-12, S11 Cycle 7 #322): false-positive 4-layer filter + severity 분류.
v4 (2026-05-12, S11 Cycle 8 #340): cross-process debounce/dedup + KPI < 1/시간.

Cycle 7 결과: cascade:build-fail 36→4회/시간 (88% 감소). Cycle 8 추가 90% 목표 — 동일
(matched_pattern + severity) 가 60초 내 재발 시 publish skip (L5 debounce). 파일 기반
atomic-rename 으로 8 세션 worktree 병렬 안전.

Trigger: PostToolUse(Bash)
Mechanism:
  stdin payload 의 tool_input.command + tool_response.exit_code/stderr 검사.
  4-layer filter + L5 dedup 게이트 통과 시 severity 분류 후 broker publish.

False-positive 5-layer filter (v4):
  L1. Whitelist prefix : gh / git commit|push|stash / cat > / claude --bg  → skip
  L2. Heredoc body strip : <<EOF 이후 body 는 매칭 대상 제외
  L3. Pattern match (head only) : strip 된 head 에 BUILD_PATTERNS 매치 시만 진행
  L4. Signal-less skip : exit_code = -1 + empty stderr → info severity (publish skip)
  L5. Debounce dedup (v4) : 동일 (matched_pattern + severity) 60초 내 재발 → skip

Severity matrix:
  critical : exit_code ∈ [1,255] + stderr len >= 20  → Circuit Breaker 카운트 대상
  warning  : exit_code ∈ [1,255] + 0 < stderr < 20  → 모니터링만
  info     : exit_code = -1/None + empty stderr → publish skip (forensic only)

KPI (Issue #340):
  - cascade:build-fail < 1회/시간 (Cycle 7 4회/시간 대비 추가 75%+ 감소)
  - false-positive 비율 ≈ 0
  - Iron Law trigger 신뢰성 향상

관련 문서:
  - docs/4. Operations/Docker_Runtime.md §5.1 cascade:build-fail severity contract
  - docs/4. Operations/Spec_Gap_Triage.md (Type A/B/C/D)
  - PR #314 (Cycle 6 진단) + PR #336 (Cycle 7 v3)
"""
from __future__ import annotations

import hashlib
import json
import os
import re
import sys
import time
from pathlib import Path


BUILD_PATTERNS = re.compile(
    r"\b("
    r"flutter\s+(pub|run|test|build|analyze)"
    r"|dart\s+(run|test|pub)"
    r"|pytest"
    r"|ruff\s+check"
    r"|pnpm\s+(install|run|test|build|dev)"
    r"|npm\s+(install|run|test|build)"
    r"|quasar\s+(dev|build)"
    r"|python\s+-m\s+(alembic|pytest|uvicorn)"
    r"|uvicorn"
    r"|docker(?:-compose|\s+compose)?\s+(?:up|build)"  # v3: `docker compose` (modern) + `docker-compose` (legacy) 모두 매치
    r"|build_runner"
    r")\b",
    re.I,
)


# L1: Whitelist prefix — git/gh/cat heredoc, claude --bg spawn 명령은 빌드 실패 아님.
# Cycle 6 #305 진단: 22+ false-positive 모두 이 카테고리.
# `cd <path> && <cmd>` 패턴도 매칭하기 위해 `\s*(?:cd\s+\S+\s*&&\s*)?` prefix 허용.
WHITELIST_PREFIX = re.compile(
    r"^\s*(?:cd\s+\S+\s*&&\s*)?("
    r"gh\s+(issue|pr|repo|api|search|workflow|run|release|auth|browse|cache)"
    r"|git\s+(commit|stash|push|fetch|tag|notes|log|show|diff|status|branch|checkout|cherry-pick|rebase|reset|reflog|worktree|remote|config|clean|rm|add)"
    r"|cat\s*>"
    r"|claude\s+(--bg|--background|--continue|--resume)"
    r"|echo\s+"
    r"|printf\s+"
    r"|sleep\s+"
    r")",
    re.I,
)


# L2: Heredoc body strip — <<EOF / <<'EOF' / <<"EOF" / <<-EOF 이후 body 는 매칭 대상 아님.
# PR description / commit message body 에 'pytest', 'docker build' 등 단어가 들어가도
# 실제 build 실행이 아니므로 cascade publish 금지.
HEREDOC_SPLIT = re.compile(r"<<-?\s*['\"]?\w+['\"]?")


# L5 (v4, Cycle 8): cross-process dedup window — file-based atomic rename.
# 동일 (matched_pattern + severity) key 가 DEDUP_WINDOW_SEC 내 재발 시 publish skip.
# 파일 락 없이 atomic rename(=POSIX 보장) 으로 race-free.
# Windows: rename 도 atomic. 8 세션 worktree 병렬 안전.
DEDUP_WINDOW_SEC = 60
DEDUP_STATE_DIR = Path.home() / ".claude" / "state" / "post_build_fail_dedup"


def _strip_heredoc(command: str) -> str:
    """L2: heredoc body 제거. <<EOF 이전 head 만 반환."""
    parts = HEREDOC_SPLIT.split(command, maxsplit=1)
    return parts[0]


def _is_whitelisted(command_head: str) -> bool:
    """L1: whitelist prefix 매칭 시 false-positive 로 간주."""
    return bool(WHITELIST_PREFIX.match(command_head))


def _classify_severity(exit_code, stderr_excerpt: str) -> str:
    """
    severity 분류:
      critical : exit_code ∈ [1,255] + stderr len >= 20  (실제 build/test 실패 신호)
      warning  : exit_code ∈ [1,255] + stderr len < 20 (약한 신호; 빈 stderr 포함)
      info     : 그 외 (exit_code = -1/None — 시그널 부재, forensic only)
    """
    err = (stderr_excerpt or "").strip()
    code = exit_code if isinstance(exit_code, int) else -1

    if code in range(1, 256):
        if len(err) >= 20:
            return "critical"
        return "warning"
    # exit_code = -1 (Claude bash tool internal failure), 0 등 → info
    return "info"


def _matched_pattern(command_head: str) -> str:
    """Forensic visibility: 매치된 build pattern 반환."""
    m = BUILD_PATTERNS.search(command_head)
    return m.group(0) if m else ""


def _dedup_key(matched_pattern: str, severity: str) -> str:
    """dedup state file 식별자. matched_pattern 은 trim+lower normalize."""
    norm = re.sub(r"\s+", "_", matched_pattern.strip().lower())
    if not norm:
        norm = "unknown"
    digest = hashlib.sha1(f"{norm}|{severity}".encode("utf-8")).hexdigest()[:16]
    return f"{severity}_{digest}"


def _should_dedup(matched_pattern: str, severity: str, window_sec: int = DEDUP_WINDOW_SEC) -> bool:
    """L5: 동일 key 가 window_sec 내 재발 시 True 반환 (publish skip 신호).

    Atomic rename 으로 race-free. 실패 시 publish 허용 (fail-open).
    """
    try:
        DEDUP_STATE_DIR.mkdir(parents=True, exist_ok=True)
        key = _dedup_key(matched_pattern, severity)
        state_file = DEDUP_STATE_DIR / f"{key}.ts"
        now = time.time()
        if state_file.exists():
            try:
                last = float(state_file.read_text(encoding="utf-8").strip())
                if (now - last) < window_sec:
                    return True  # debounce hit — skip publish
            except (ValueError, OSError):
                pass  # corrupt state → treat as miss
        # write fresh timestamp (atomic via temp + rename)
        tmp = state_file.with_suffix(".tmp")
        tmp.write_text(f"{now:.3f}", encoding="utf-8")
        os.replace(str(tmp), str(state_file))
        return False
    except Exception:
        # fail-open: dedup 실패 시 publish 허용 (Cycle 2 contract 보존)
        return False


def _broker_publish_build_fail(cascade_payload: dict, source: str, max_retries: int = 3) -> bool:
    """publish cascade:build-fail with retry + exp backoff.

    Returns:
      True if publish succeeded or daemon dead (silent skip).
      False if all retries exhausted.

    Retry policy: 3 attempts at [0s, 0.5s, 1.5s]. Each attempt timeout=2.0s.
    Total worst-case: 8.0s. Silent if broker daemon dead (TCP probe fail).
    """
    import socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(1.0)
    try:
        sock.connect(("127.0.0.1", 7383))
    except OSError:
        return True  # daemon dead - silent skip (Cycle 2 contract preserved)
    finally:
        sock.close()

    backoffs = [0.0, 0.5, 1.5]
    for attempt in range(max_retries):
        if backoffs[attempt] > 0:
            time.sleep(backoffs[attempt])
        try:
            import asyncio
            from mcp import ClientSession
            from mcp.client.streamable_http import streamablehttp_client

            async def _run():
                async with streamablehttp_client("http://127.0.0.1:7383/mcp") as (r, w, _gs):
                    async with ClientSession(r, w) as s:
                        await s.initialize()
                        await s.call_tool("publish_event", {
                            "topic": "cascade:build-fail",
                            "payload": cascade_payload,
                            "source": source,
                        })

            asyncio.run(asyncio.wait_for(_run(), timeout=2.0))
            return True
        except Exception:
            continue
    return False


def _read_team_id():
    """Read team_id from .team if present. Return None for main session."""
    team_file = Path.cwd() / '.team'
    if not team_file.exists():
        return None
    try:
        import yaml
        return (yaml.safe_load(team_file.read_text(encoding='utf-8')) or {}).get('team_id')
    except Exception:
        return None


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except json.JSONDecodeError:
        return 0

    tool_input = payload.get("tool_input") or {}
    tool_response = payload.get("tool_response") or {}

    command = tool_input.get("command", "") if isinstance(tool_input, dict) else ""
    exit_code = tool_response.get("exit_code") if isinstance(tool_response, dict) else None
    is_error = tool_response.get("is_error") if isinstance(tool_response, dict) else False

    # 성공 → 조용히 통과
    if exit_code == 0 and not is_error:
        return 0

    # === False-positive 5-layer filter (v4) ===

    # L2 먼저: heredoc body 제거 (L1 prefix 가 head 에서 매칭하려면 strip 선행 필요)
    command_head = _strip_heredoc(command)

    # L1: whitelist prefix → silent skip
    if _is_whitelisted(command_head):
        return 0

    # L3: BUILD_PATTERNS 가 head 에 매치 안 되면 빌드 명령 아님
    if not BUILD_PATTERNS.search(command_head):
        return 0

    # === Severity 분류 ===
    stderr_excerpt = ""
    if isinstance(tool_response, dict):
        stderr_excerpt = tool_response.get("stderr") or tool_response.get("error") or ""
    if not isinstance(stderr_excerpt, str):
        stderr_excerpt = str(stderr_excerpt)

    severity = _classify_severity(exit_code, stderr_excerpt)
    matched = _matched_pattern(command_head)

    # L4: severity=info → publish skip + reminder skip (Circuit Breaker false-positive 차단 핵심)
    if severity == "info":
        return 0

    # L5 (v4): cross-process debounce dedup — 동일 (pattern + severity) 60s 내 재발 시 skip
    if _should_dedup(matched, severity):
        return 0

    # === Broker publish (critical/warning + L5 통과만) ===
    team_id = _read_team_id() or "main"
    cascade_payload = {
        "command_excerpt": command[:200],
        "exit_code": exit_code if isinstance(exit_code, int) else -1,
        "stderr_excerpt": stderr_excerpt[:500],
        "auto_published": True,
        "trigger": "PostToolUse:Bash exit!=0",
        "severity": severity,                 # NEW v3
        "matched_pattern": matched,           # NEW v3 (forensic)
        "filter_version": "v4",               # v4: dedup gate 추가
        "dedup_window_sec": DEDUP_WINDOW_SEC,  # NEW v4 (subscriber forensic)
        "next_action": {
            "type": "inbox-drop",
            "target": "S9,S10-A" if severity == "critical" else "S10-A",
            "reason": "QA + Gap Analysis attention" if severity == "critical" else "Gap signal (warning)",
        },
    }
    _broker_publish_build_fail(cascade_payload, source=team_id)

    # 프로토콜 reminder — critical 만 stdout 노출 (warning 은 broker 만, 노이즈 절감)
    if severity == "critical":
        print(
            "\n[post_build_fail] 프로토타입 빌드/테스트 실패 감지 (severity=critical).\n"
            f"matched_pattern: {matched}\n"
            "프로젝트 의도: 앱 실행 실패는 기획 공백/모순의 신호일 수 있음.\n\n"
            "다음 3-Type 분류를 먼저 수행한 후 대응 순서를 결정하십시오:\n"
            "  Type A (빌드 실수)   → 기획엔 답 있음. 구현 PR.\n"
            "  Type B (기획 공백)   → 팀마다 다른 가정. 기획 보강 PR 먼저.\n"
            "  Type C (기획 모순)   → 기획서 간 충돌. 기획 정렬 PR 먼저.\n\n"
            "상세 프로토콜: docs/4. Operations/Spec_Gap_Triage.md\n"
            "실패를 Type B/C 로 판정하면 `docs/4. Operations/Conductor_Backlog/SG-*.md` 생성으로 추적.\n",
            flush=True,
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
