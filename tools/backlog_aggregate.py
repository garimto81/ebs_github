#!/usr/bin/env python3
"""docs/backlog/team{N}.md + conductor.md 를 읽어 _aggregate.md 생성.

Conductor 전용 읽기 뷰. 팀별 파일은 각 팀이 독립 편집, 집계는 이 스크립트로만.
실행: `python tools/backlog_aggregate.py`
"""
from __future__ import annotations

from datetime import datetime
from pathlib import Path

BACKLOG_DIR = Path(__file__).resolve().parent.parent / "docs" / "backlog"

SOURCES = [
    ("team1", "team1.md"),
    ("team2", "team2.md"),
    ("team3", "team3.md"),
    ("team4", "team4.md"),
    ("conductor", "conductor.md"),
]


def main() -> None:
    out: list[str] = [
        "# EBS 백로그 — 집계 뷰 (읽기 전용)",
        "",
        f"> **생성 시각**: {datetime.now():%Y-%m-%d %H:%M:%S}",
        "> **원본**: `docs/backlog/team{1..4}.md` + `conductor.md`",
        "> **편집 금지**: 이 파일은 `tools/backlog_aggregate.py`가 덮어씁니다.",
        "> **수정은 팀별 원본 파일에서만**. hook이 경계를 강제합니다.",
        "",
        "---",
        "",
    ]
    for team, fname in SOURCES:
        path = BACKLOG_DIR / fname
        if not path.exists():
            continue
        out.append(f"## {team.upper()}")
        out.append("")
        out.append(f"> 원본: `docs/backlog/{fname}`")
        out.append("")
        out.append(path.read_text(encoding="utf-8").rstrip())
        out += ["", "", "---", ""]

    target = BACKLOG_DIR / "_aggregate.md"
    target.write_text("\n".join(out), encoding="utf-8")
    print(f"wrote {target}")


if __name__ == "__main__":
    main()
