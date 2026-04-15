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


_FRONTMATTER_RE = __import__("re").compile(r"^---\n(.*?)\n---\n", __import__("re").DOTALL)


def _read_dir_items(d: Path) -> list[dict]:
    """디렉토리 내 *.md 파일을 frontmatter 기반으로 읽어 항목 리스트 반환.
    frontmatter 누락 시 파일명을 ID로 fallback.
    """
    if not d.exists() or not d.is_dir():
        return []
    items = []
    for f in sorted(d.glob("*.md")):
        text = f.read_text(encoding="utf-8")
        meta = {"id": f.stem, "title": "", "status": "UNKNOWN"}
        m = _FRONTMATTER_RE.match(text)
        if m:
            for line in m.group(1).splitlines():
                if ":" in line:
                    k, _, v = line.partition(":")
                    meta[k.strip()] = v.strip().strip('"')
            body = text[m.end():]
        else:
            body = text
        items.append({**meta, "body": body.rstrip(), "file": f})
    return items


def _section_for(team_dir: Path, team_label: str, lines: list[str]) -> int:
    """팀 디렉토리에서 항목을 읽어 status별로 그룹화하여 lines에 추가. 항목 수 반환."""
    items = _read_dir_items(team_dir)
    if not items:
        return 0
    by_status: dict[str, list[dict]] = {}
    for it in items:
        by_status.setdefault(it["status"], []).append(it)
    lines.append(f"## {team_label.upper()}")
    lines.append("")
    lines.append(f"> 원본 디렉토리: `{team_dir.relative_to(PROJECT).as_posix()}` ({len(items)} 항목)")
    lines.append("")
    for status in ("PENDING", "IN_PROGRESS", "OPEN", "DONE", "RESOLVED",
                   "ARCHIVE", "TODO", "UNCATEGORIZED", "UNKNOWN"):
        if status not in by_status:
            continue
        lines.append(f"### {status}")
        for it in by_status[status]:
            title = it.get("title") or it["id"]
            lines.append(f"- **[{it['id']}]** {title} — `{it['file'].name}`")
        lines.append("")
    return len(items)


def main() -> None:
    team_paths, conductor_path, output = _resolve_paths()

    lines: list[str] = [
        "# EBS 백로그 — 집계 뷰 (읽기 전용)",
        "",
        f"> **생성 시각**: {datetime.now():%Y-%m-%d %H:%M:%S}",
        "> **편집 금지**: 이 파일은 `tools/backlog_aggregate.py`가 덮어씁니다.",
        "> **수정은 항목 파일에서만** (디렉토리화 후 항목당 1파일 구조).",
        "",
        "---",
        "",
    ]
    total = 0
    # 1) v6: 디렉토리화된 구조 우선
    team_dirs = {team: (path.parent / "Backlog") for team, path in team_paths.items()}
    conductor_dir = conductor_path.parent / "Conductor_Backlog"
    for team, d in team_dirs.items():
        n = _section_for(d, team, lines)
        if n:
            total += n
            lines += ["---", ""]
        elif team_paths[team].exists():
            # 구 단일파일 fallback
            lines.append(f"## {team.upper()} (legacy single-file)")
            lines.append("")
            lines.append(team_paths[team].read_text(encoding="utf-8").rstrip())
            lines += ["", "---", ""]
    n = _section_for(conductor_dir, "conductor", lines)
    if n:
        total += n
        lines += ["---", ""]
    elif conductor_path.exists():
        lines.append("## CONDUCTOR (legacy single-file)")
        lines.append("")
        lines.append(conductor_path.read_text(encoding="utf-8").rstrip())
        lines += ["", "---", ""]

    # Spec_Gaps 디렉토리도 동일 규칙으로 추가 (있는 팀만)
    for team, path in team_paths.items():
        gap_dir = path.parent / "Spec_Gaps"
        if gap_dir.exists() and gap_dir.is_dir():
            _section_for(gap_dir, f"{team}-spec-gaps", lines)
            lines += ["---", ""]

    lines.append(f"_총 항목: {total}_")

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(lines), encoding="utf-8")
    print(f"wrote {output} ({total} items)")


if __name__ == "__main__":
    main()
