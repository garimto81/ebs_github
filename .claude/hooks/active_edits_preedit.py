#!/usr/bin/env python3
"""PreToolUse Write/Edit hook: 다른 세션이 같은 파일 편집 중이면 1회 경고.

- 1회 경고 후 같은 호출 재시도 시 통과 (override 캐시)
- decision_owner 표시 (team-policy.json 의 owns/contract_ownership)
- bypass 모드: 침묵
"""
from __future__ import annotations

import hashlib
import json
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from _common import (  # noqa: E402
    detect_team, is_bypass_mode, read_payload, emit, load_policy, PROJECT,
)
from _registry import (  # noqa: E402
    list_active, session_id, my_claim_path, write_claim, push_claim, now_iso,
)

OVERRIDE_DIR = PROJECT / ".claude" / ".active-edits-overrides"
OVERRIDE_TTL_SEC = 300


def _override_key(sid: str, target: str) -> Path:
    h = hashlib.sha1(f"{sid}:{target}".encode("utf-8")).hexdigest()[:16]
    return OVERRIDE_DIR / f"{h}.flag"


def _has_override(sid: str, target: str) -> bool:
    f = _override_key(sid, target)
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
    _override_key(sid, target).touch()


def _decision_owner(target: str, policy: dict) -> str:
    """target 경로의 decision_owner를 policy.teams[*].owns 와 contract_ownership 에서 추출."""
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


def _normalize(path: str) -> str:
    p = Path(path)
    if not p.is_absolute():
        p = PROJECT / p
    try:
        return str(p.resolve()).replace("\\", "/")
    except Exception:
        return str(p).replace("\\", "/")


def _update_my_claim(sid: str, team: str, target: str) -> None:
    cp = my_claim_path(sid)
    if cp.exists():
        try:
            data = json.loads(cp.read_text(encoding="utf-8"))
        except Exception:
            data = {}
    else:
        data = {}
    data.setdefault("session_id", sid)
    data.setdefault("team", team)
    data.setdefault("started_at", now_iso())
    data["heartbeat_at"] = now_iso()
    data["ttl_minutes"] = 120
    files = data.get("files", [])
    target_rel = target
    try:
        target_rel = str(Path(target).resolve().relative_to(PROJECT)).replace("\\", "/")
    except Exception:
        pass
    if not any(f.get("path") == target_rel for f in files):
        files.append({"path": target_rel, "intent": "", "claimed_at": now_iso()})
    data["files"] = files
    write_claim(sid, data)
    push_claim(sid)


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
    sid = session_id(team)
    bypass = is_bypass_mode(payload)

    target_norm = _normalize(target)

    # 다른 세션의 활성 claim 검사
    conflicts = []
    for a in list_active():
        if a.get("session_id") == sid:
            continue
        for f in a.get("files", []):
            other_path = _normalize(f.get("path", ""))
            if other_path and other_path == target_norm:
                conflicts.append((a.get("team"), a.get("session_id")))
                break

    if conflicts and not bypass and not _has_override(sid, target_norm):
        policy = load_policy()
        owner = _decision_owner(target, policy)
        msg = (
            f"[active-edits] 다른 세션이 같은 파일 편집 중: {target}\n"
            f"  · 충돌 세션: " + ", ".join(f"{t}/{s}" for t, s in conflicts) + "\n"
            f"  · decision_owner: {owner}\n"
            f"  · 계속하려면 동일 호출을 다시 실행하세요 (override 5분).\n"
        )
        _set_override(sid, target_norm)
        emit(decision="block", reason=msg)

    # 통과: 자기 claim 갱신
    try:
        _update_my_claim(sid, team, target)
    except Exception as e:
        sys.stderr.write(f"[active-edits] claim update failed: {e}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
