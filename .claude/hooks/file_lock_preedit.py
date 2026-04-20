#!/usr/bin/env python3
"""PreToolUse Write/Edit hook: filesystem advisory lock 기반 파일 편집 충돌 감지.

설계 근거: 멀티 세션 워크플로우 MVI Phase 3.
기존 active_edits_preedit (orphan branch + git push) 는 네트워크 의존 + 5일 dormant 위험.
→ 로컬 파일 락으로 교체. 네트워크 0, 즉시 반응, TTL 자동 만료.

락 포맷: .claude/locks/<sha256(abs_path)[:16]>.json
  {"sid": "<session-id>", "path": "<abs>", "team": "<t>", "ts": <unix>, "heartbeat": <unix>}

충돌 정책 (기존 active_edits 와 동일):
  - 다른 세션이 같은 파일 claim 중 + TTL 미만 → block + 1회 경고
  - 동일 호출 재시도 시 override (5분 TTL)
  - bypass 모드 시 침묵 통과
"""
from __future__ import annotations

import hashlib
import json
import os
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from _common import (  # noqa: E402
    detect_team, is_bypass_mode, read_payload, emit, load_policy, PROJECT,
)

LOCK_DIR = PROJECT / ".claude" / "locks"
LOCK_TTL_SEC = 300  # 5분: 세션이 idle 되면 자동 해제
HEARTBEAT_TTL_SEC = 900  # 15분: heartbeat 없으면 stale 로 간주
OVERRIDE_DIR = PROJECT / ".claude" / ".file-lock-overrides"
OVERRIDE_TTL_SEC = 300


def _sid() -> str:
    sid_file = PROJECT / ".claude" / ".session-id"
    if sid_file.exists():
        s = sid_file.read_text(encoding="utf-8").strip()
        if s:
            return s
    return f"pid-{os.getpid()}"


def _lock_path(abs_path: str) -> Path:
    h = hashlib.sha256(abs_path.encode("utf-8")).hexdigest()[:16]
    return LOCK_DIR / f"{h}.json"


def _override_path(sid: str, target: str) -> Path:
    h = hashlib.sha1(f"{sid}:{target}".encode("utf-8")).hexdigest()[:16]
    return OVERRIDE_DIR / f"{h}.flag"


def _has_override(sid: str, target: str) -> bool:
    f = _override_path(sid, target)
    if not f.exists():
        return False
    if time.time() - f.stat().st_mtime > OVERRIDE_TTL_SEC:
        try:
            f.unlink()
        except Exception:
            pass
        return False
    return True


def _set_override(sid: str, target: str) -> None:
    OVERRIDE_DIR.mkdir(parents=True, exist_ok=True)
    _override_path(sid, target).touch()


def _normalize(path: str) -> str:
    p = Path(path)
    if not p.is_absolute():
        p = PROJECT / p
    try:
        return str(p.resolve()).replace("\\", "/")
    except Exception:
        return str(p).replace("\\", "/")


def _read_lock(lock_file: Path) -> dict | None:
    if not lock_file.exists():
        return None
    try:
        return json.loads(lock_file.read_text(encoding="utf-8"))
    except Exception:
        return None


def _is_stale(lock: dict) -> bool:
    now = time.time()
    hb = lock.get("heartbeat", lock.get("ts", 0))
    return (now - hb) > HEARTBEAT_TTL_SEC


def _write_lock(lock_file: Path, sid: str, target: str, team: str) -> None:
    LOCK_DIR.mkdir(parents=True, exist_ok=True)
    now = time.time()
    existing = _read_lock(lock_file) or {}
    # 동일 세션 재진입: heartbeat 만 갱신
    if existing.get("sid") == sid:
        existing["heartbeat"] = now
        lock_file.write_text(json.dumps(existing), encoding="utf-8")
        return
    lock_file.write_text(
        json.dumps({
            "sid": sid, "path": target, "team": team,
            "ts": now, "heartbeat": now,
        }),
        encoding="utf-8",
    )


def _decision_owner(target: str, policy: dict) -> str:
    """target 경로의 decision_owner (team-policy.json)."""
    target = target.replace("\\", "/")
    co = policy.get("contract_ownership", {})
    for path, info in co.items():
        if target.endswith(path) or path in target:
            return info.get("publisher", "?")
    teams = policy.get("teams", {})
    best = ("conductor", 0)
    for team, info in teams.items():
        for owns in info.get("owns", []):
            owns_norm = owns.replace("\\", "/")
            if owns_norm in target and len(owns_norm) > best[1]:
                best = (team, len(owns_norm))
    return best[0]


def main() -> int:
    payload = read_payload()
    tool = payload.get("tool_name") or payload.get("tool")
    if tool not in ("Write", "Edit", "MultiEdit"):
        return 0
    target = (payload.get("tool_input") or {}).get("file_path") \
        or (payload.get("tool_input") or {}).get("path") or ""
    if not target:
        return 0

    team = detect_team(payload.get("cwd"))
    sid = _sid()
    bypass = is_bypass_mode(payload)
    abs_target = _normalize(target)

    lock_file = _lock_path(abs_target)
    existing = _read_lock(lock_file)

    # 충돌 체크: 다른 세션의 활성 락이 있고 stale 아니면 경고
    if (existing and existing.get("sid") != sid and not _is_stale(existing)
            and not bypass and not _has_override(sid, abs_target)):
        policy = load_policy()
        owner = _decision_owner(abs_target, policy)
        other_team = existing.get("team", "?")
        other_sid = existing.get("sid", "?")
        reason = (
            f"[file-lock] 다른 세션이 같은 파일 편집 중: {target}\n"
            f"  · 충돌 세션: {other_team}/{other_sid}\n"
            f"  · decision_owner: {owner}\n"
            f"  · 계속하려면 동일 호출을 다시 실행하세요 (override 5분).\n"
        )
        _set_override(sid, abs_target)
        emit(decision="block", reason=reason)

    # stale 락은 overwrite
    _write_lock(lock_file, sid, abs_target, team)
    return 0


if __name__ == "__main__":
    sys.exit(main())
