#!/usr/bin/env python3
"""Stop hook: 자기 claim 파일 삭제 + remote에서 제거."""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from _common import detect_team, read_payload  # noqa: E402
from _registry import remove_claim, session_id  # noqa: E402


def main() -> int:
    payload = read_payload()
    team = detect_team(payload.get("cwd"))
    sid = session_id(team)
    ok = remove_claim(sid)
    sys.stderr.write(f"[active-edits] session_end: removed claim {sid} (push={'ok' if ok else 'fail'})\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
