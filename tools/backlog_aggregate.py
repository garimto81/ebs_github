#!/usr/bin/env python3
"""팀별 백로그를 집계하여 읽기 전용 뷰를 생성한다.

v5 경로 (기본):
- 팀별: `docs/2. Development/2.{N} {팀명}/Backlog.md` (Phase 3 이주 후 활성)
- Conductor: `docs/4. Operations/Conductor_Backlog.md`
- 출력: `docs/4. Operations/Backlog_Aggregate.md`

v4 경로 (fallback, EBS_SCOPE_GUARD_VERSION=v4):
- `docs/backlog/team{N}.md` + `conductor.md` → `docs/backlog/_aggregate.md`

Phase 3 이주 완료 전에는 v5 팀별 경로에 파일이 없으므로, 구 `docs/backlog/team{N}.md`
잔존본도 동시 인식한다(팀별 파일이 둘 다 존재하면 v5 우선).
"""
from __future__ import annotations

import os
from datetime import datetime
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent

_V5_TEAM_PATHS = {
    "team1": PROJECT / "docs" / "2. Development" / "2.1 Frontend" / "Backlog.md",
    "team2": PROJECT / "docs" / "2. Development" / "2.2 Backend" / "Backlog.md",
    "team3": PROJECT / "docs" / "2. Development" / "2.3 Game Engine" / "Backlog.md",
    "team4": PROJECT / "docs" / "2. Development" / "2.4 Command Center" / "Backlog.md",
}
_V5_CONDUCTOR = PROJECT / "docs" / "4. Operations" / "Conductor_Backlog.md"
_V5_OUTPUT = PROJECT / "docs" / "4. Operations" / "Backlog_Aggregate.md"

_V4_DIR = PROJECT / "docs" / "backlog"
_V4_TEAM_PATHS = {
    "team1": _V4_DIR / "team1.md",
    "team2": _V4_DIR / "team2.md",
    "team3": _V4_DIR / "team3.md",
    "team4": _V4_DIR / "team4.md",
}
_V4_CONDUCTOR = _V4_DIR / "conductor.md"
_V4_OUTPUT = _V4_DIR / "_aggregate.md"


def _resolve_paths() -> tuple[dict[str, Path], Path, Path]:
    """환경변수에 따라 v4/v5 경로 세트 선택. v5에서 팀 파일 부재 시 v4 잔존본 사용."""
    version = os.environ.get("EBS_SCOPE_GUARD_VERSION", "v5").lower()
    if version == "v4":
        return _V4_TEAM_PATHS, _V4_CONDUCTOR, _V4_OUTPUT

    team_paths: dict[str, Path] = {}
    for team, v5_path in _V5_TEAM_PATHS.items():
        if v5_path.exists():
            team_paths[team] = v5_path
        else:
            team_paths[team] = _V4_TEAM_PATHS[team]
    conductor = _V5_CONDUCTOR if _V5_CONDUCTOR.exists() else _V4_CONDUCTOR
    output = _V5_OUTPUT if _V5_CONDUCTOR.exists() else _V4_OUTPUT
    return team_paths, conductor, output


def main() -> None:
    team_paths, conductor_path, output = _resolve_paths()
    sources: list[tuple[str, Path]] = list(team_paths.items()) + [("conductor", conductor_path)]

    lines: list[str] = [
        "# EBS 백로그 — 집계 뷰 (읽기 전용)",
        "",
        f"> **생성 시각**: {datetime.now():%Y-%m-%d %H:%M:%S}",
        "> **편집 금지**: 이 파일은 `tools/backlog_aggregate.py`가 덮어씁니다.",
        "> **수정은 팀별 원본 파일에서만**.",
        "",
        "---",
        "",
    ]
    for team, path in sources:
        if not path.exists():
            continue
        lines.append(f"## {team.upper()}")
        lines.append("")
        try:
            rel = path.relative_to(PROJECT).as_posix()
        except ValueError:
            rel = str(path)
        lines.append(f"> 원본: `{rel}`")
        lines.append("")
        lines.append(path.read_text(encoding="utf-8").rstrip())
        lines += ["", "", "---", ""]

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(lines), encoding="utf-8")
    print(f"wrote {output}")


if __name__ == "__main__":
    main()
