#!/usr/bin/env python3
"""SessionStart hook: meta/active-edits fetch + 활성 항목 컨텍스트 주입 + 자기 claim 생성."""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from _common import detect_team, read_payload  # noqa: E402
from _registry import (  # noqa: E402
    fetch_registry, list_active, session_id, write_claim, push_claim, now_iso,
)


def main() -> int:
    payload = read_payload()
    team = detect_team(payload.get("cwd"))
    sid = session_id(team)

    fetch_registry()
    active = list_active()

    claim = {
        "session_id": sid,
        "team": team,
        "branch": "",
        "files": [],
        "started_at": now_iso(),
        "heartbeat_at": now_iso(),
        "ttl_minutes": 120,
    }
    write_claim(sid, claim)
    push_claim(sid)

    others = [a for a in active if a.get("session_id") != sid]
    if others:
        sys.stderr.write(f"[active-edits] 현재 활성 세션 {len(others)}개:\n")
        for a in others:
            files = ", ".join(f.get("path", "") for f in a.get("files", [])) or "(no claims yet)"
            sys.stderr.write(f"  · {a.get('team')}/{a.get('session_id')}: {files}\n")
    else:
        sys.stderr.write("[active-edits] 다른 활성 세션 없음.\n")
    sys.stderr.write(f"[active-edits] 내 세션 ID: {sid}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
