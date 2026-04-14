#!/usr/bin/env python3
"""Stage A — /ssot-align planner.

.ssot-align.yaml 을 읽어 대상 파일 목록, 섹션 분류, source_id 매핑,
Rovo 질의 배치, MCP fetch manifest 를 JSON 으로 출력한다.

LLM 토큰 소모 0 — 모든 판단은 결정론적 규칙.

Usage:
    python tools/ssot_align_plan.py                              # 전체 스코프
    python tools/ssot_align_plan.py contracts/data/DATA-04-db-schema.md   # 단일 파일
    python tools/ssot_align_plan.py contracts/data                        # 디렉토리
    python tools/ssot_align_plan.py --team conductor                      # 팀 override
    python tools/ssot_align_plan.py --out tools/.ssot-align-plan.json

출력: tools/.ssot-align-plan.json
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import yaml

PROJECT = Path(__file__).resolve().parent.parent
CONFIG_PATH = PROJECT / ".ssot-align.yaml"
DEFAULT_OUT = PROJECT / "tools" / ".ssot-align-plan.json"
CACHE_DIR = PROJECT / "tools" / ".ssot-align-cache"

ALIGNED_MARKER = "📎 원본 SSOT"
NATIVE_MARKER = "🏷️ 프로젝트 고유"


@dataclass
class SectionEntry:
    heading: str
    anchor: str
    line_start: int
    line_end: int
    status: str           # aligned | cached | unmapped | native
    source_id: str | None = None
    confluence_hints: list[str] = field(default_factory=list)
    cache_hit: bool = False
    cache_version: str | None = None
    flagged: bool = False


@dataclass
class FileEntry:
    path: str
    owner: str
    sections: list[SectionEntry] = field(default_factory=list)


def load_config(path: Path = CONFIG_PATH) -> dict[str, Any]:
    if not path.exists():
        raise SystemExit(f"[ssot-align-plan] config not found: {path}")
    with path.open("r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def detect_team(cfg: dict[str, Any], override: str | None = None) -> str:
    if override:
        return override
    rules = cfg.get("team_detection", {})
    env_var = rules.get("env_var")
    if env_var and os.environ.get(env_var):
        return os.environ[env_var]
    if rules.get("git_branch_prefix"):
        try:
            branch = subprocess.check_output(
                ["git", "-C", str(PROJECT), "branch", "--show-current"],
                stderr=subprocess.DEVNULL,
                text=True,
            ).strip()
            m = re.match(r"(team[1-4])/", branch)
            if m:
                return m.group(1)
        except Exception:
            pass
    if rules.get("cwd_prefix"):
        cwd = Path.cwd()
        try:
            rel = cwd.relative_to(PROJECT).parts
            if rel and rel[0].startswith(("team1-", "team2-", "team3-", "team4-")):
                return rel[0].split("-")[0]
        except ValueError:
            pass
    return rules.get("default", "conductor")


def iter_target_paths(cfg: dict[str, Any], team: str, scope: list[str] | None) -> list[tuple[Path, str]]:
    """config.targets 와 scope 교집합. return [(abspath, owner), ...]."""
    entries = cfg.get("targets", [])
    enforce = cfg.get("scope_guard", {}).get("enforce_team_ownership", True)
    results: list[tuple[Path, str]] = []
    seen: set[Path] = set()
    scope_paths = [PROJECT / s for s in scope] if scope else None

    for entry in entries:
        owner = entry.get("owner", "")
        if enforce and owner != team:
            continue
        pattern = entry["path"]
        for match in PROJECT.glob(pattern):
            if not match.is_file() or match.suffix != ".md":
                continue
            if "_templates" in match.parts:
                continue
            if scope_paths and not any(_is_under(match, sp) for sp in scope_paths):
                continue
            if match in seen:
                continue
            seen.add(match)
            results.append((match, owner))
    results.sort(key=lambda t: str(t[0]))
    return results


def _is_under(path: Path, base: Path) -> bool:
    try:
        path.relative_to(base)
        return True
    except ValueError:
        return path == base


HEADING_RE = re.compile(r"^(#{1,6})\s+(.+?)\s*$")
SECTION_HEADING_RE = re.compile(r"^(##)\s+(?:§[\d.]+\.?\s*)?(.+?)\s*$")


def parse_sections(md: str) -> list[tuple[str, int, int]]:
    """## 레벨 섹션만 추출. return [(heading_text, line_start, line_end(exclusive)), ...]."""
    lines = md.splitlines()
    starts: list[tuple[int, str]] = []
    for i, line in enumerate(lines):
        m = HEADING_RE.match(line)
        if not m:
            continue
        level = len(m.group(1))
        if level != 2:
            continue
        heading = m.group(2).strip()
        heading = re.sub(r"^§[\d.]+\.?\s*", "", heading)
        starts.append((i, heading))
    out: list[tuple[str, int, int]] = []
    for idx, (line_no, heading) in enumerate(starts):
        end = starts[idx + 1][0] if idx + 1 < len(starts) else len(lines)
        out.append((heading, line_no, end))
    return out


def classify_section(body: str) -> str:
    """섹션 본문에서 상태 분류."""
    if ALIGNED_MARKER in body:
        return "aligned"
    if NATIVE_MARKER in body:
        return "native"
    return "candidate"


def find_cached_source_id(cfg: dict[str, Any], file_rel: str, heading: str) -> str | None:
    for entry in cfg.get("section_map", []) or []:
        m = entry.get("match", {})
        f = m.get("file")
        h = m.get("heading")
        if f != file_rel:
            continue
        if h == "*" or h == heading:
            return str(entry["source_id"])
    return None


CONFLUENCE_HINT_RE = re.compile(
    r"(?:page\s*id|pageId|page_id)\s*[:=]?\s*`?(\d{6,})`?|"
    r"atlassian\.net/wiki/spaces/[^/\s]+/pages/(\d+)",
    re.IGNORECASE,
)


def extract_confluence_hints(body: str) -> list[str]:
    """섹션 본문에서 이미 언급된 Confluence page id 추출 (매핑 후보)."""
    hints: set[str] = set()
    for m in CONFLUENCE_HINT_RE.finditer(body):
        pid = m.group(1) or m.group(2)
        if pid:
            hints.add(pid)
    return sorted(hints)


def cache_status(page_id: str) -> tuple[bool, str | None]:
    """cache 파일 존재 여부 + version 반환."""
    path = CACHE_DIR / f"page-{page_id}.json"
    if not path.exists():
        return False, None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        return True, str(data.get("version", ""))
    except Exception:
        return False, None


def load_previous_plan(path: Path) -> dict[str, Any] | None:
    if not path.exists():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None


def merge_previous_section(prev_section: dict[str, Any], new_section: "SectionEntry") -> "SectionEntry":
    """--resume 시 Stage B patch 결과 (source_id, flagged, status) 를 새 section 에 주입."""
    # preserve source_id / flagged / status if previously resolved
    if prev_section.get("source_id") and not new_section.source_id:
        new_section.source_id = prev_section["source_id"]
        if new_section.status == "unmapped":
            new_section.status = "cached"
    if prev_section.get("flagged"):
        new_section.flagged = True
    return new_section


def build_plan(
    cfg: dict[str, Any],
    team: str,
    scope: list[str] | None,
    heading: str | None = None,
    previous_plan: dict[str, Any] | None = None,
) -> dict[str, Any]:
    files: list[FileEntry] = []
    unmapped_sections: list[dict[str, str]] = []
    fetch_ids: set[str] = set()

    # build lookup of previous sections for --resume
    prev_lookup: dict[tuple[str, str], dict[str, Any]] = {}
    if previous_plan:
        for pf in previous_plan.get("files", []):
            for ps in pf.get("sections", []):
                prev_lookup[(pf["path"], ps["heading"])] = ps

    for abspath, owner in iter_target_paths(cfg, team, scope):
        rel = str(abspath.relative_to(PROJECT)).replace("\\", "/")
        md = abspath.read_text(encoding="utf-8")
        lines = md.splitlines()
        sections = parse_sections(md)
        file_entry = FileEntry(path=rel, owner=owner)

        for h_text, l_start, l_end in sections:
            if heading and h_text != heading:
                continue
            heading_name = h_text
            body = "\n".join(lines[l_start:l_end])
            status = classify_section(body)
            source_id = find_cached_source_id(cfg, rel, heading_name)
            hints = extract_confluence_hints(body)

            if status == "aligned":
                # 이미 aligned — audit 대상. source_id 추출
                hinted = hints[0] if hints else source_id
                entry_status = "aligned"
                src = hinted
            elif status == "native":
                entry_status = "native"
                src = None
            elif source_id:
                entry_status = "cached"
                src = source_id
            elif hints:
                entry_status = "cached"  # 본문 링크에서 유추
                src = hints[0]
            else:
                entry_status = "unmapped"
                src = None
                unmapped_sections.append({
                    "file": rel,
                    "heading": heading_name,
                    "owner": owner,
                })

            anchor = re.sub(r"[^\w\- ]", "", heading_name).strip().replace(" ", "-").lower()
            section_entry = SectionEntry(
                heading=heading_name,
                anchor=anchor,
                line_start=l_start,
                line_end=l_end,
                status=entry_status,
                source_id=src,
                confluence_hints=hints,
                cache_hit=False,
                cache_version=None,
            )

            # --resume merge: pull Stage-B-patched fields from previous plan
            prev = prev_lookup.get((rel, heading_name))
            if prev:
                section_entry = merge_previous_section(prev, section_entry)

            if section_entry.source_id:
                hit, ver = cache_status(section_entry.source_id)
                section_entry.cache_hit = hit
                section_entry.cache_version = ver
                fetch_ids.add(section_entry.source_id)
                # if previously unmapped got a source_id via resume, drop from unmapped list
                if unmapped_sections and unmapped_sections[-1].get("heading") == heading_name:
                    unmapped_sections.pop()

            file_entry.sections.append(section_entry)
        files.append(file_entry)

    # Rovo 배치 — unmapped 섹션을 file 단위로 묶는다 (도메인 연관성 높음)
    rovo_batches: list[dict[str, Any]] = []
    by_file: dict[str, list[dict[str, str]]] = {}
    for s in unmapped_sections:
        by_file.setdefault(s["file"], []).append(s)
    for fp, items in by_file.items():
        # 한 배치 당 최대 15개 섹션
        for i in range(0, len(items), 15):
            chunk = items[i:i + 15]
            rovo_batches.append({
                "file": fp,
                "sections": [f"{x['file']}#{x['heading']}" for x in chunk],
                "query": _build_rovo_query(fp, chunk, cfg),
            })

    # fetch manifest — 캐시 없는 source_id 만
    fetch_manifest = []
    for pid in sorted(fetch_ids):
        hit, ver = cache_status(pid)
        fetch_manifest.append({"page_id": pid, "cached": hit, "cached_version": ver})

    return {
        "schema": "ssot-align-plan/v1",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "team": team,
        "scope_files": len(files),
        "scope_sections": sum(len(f.sections) for f in files),
        "config_path": str(CONFIG_PATH.relative_to(PROJECT)),
        "space_key": cfg.get("source", {}).get("options", {}).get("space_key"),
        "files": [
            {
                "path": f.path,
                "owner": f.owner,
                "sections": [asdict(s) for s in f.sections],
            }
            for f in files
        ],
        "rovo_batches": rovo_batches,
        "fetch_manifest": fetch_manifest,
        "summary": {
            "aligned": sum(1 for f in files for s in f.sections if s.status == "aligned"),
            "cached": sum(1 for f in files for s in f.sections if s.status == "cached"),
            "unmapped": sum(1 for f in files for s in f.sections if s.status == "unmapped"),
            "native": sum(1 for f in files for s in f.sections if s.status == "native"),
            "unique_pages": len(fetch_ids),
            "fetch_needed": sum(1 for f in fetch_manifest if not f["cached"]),
        },
    }


def _build_rovo_query(file_path: str, sections: list[dict[str, str]], cfg: dict[str, Any]) -> str:
    space = cfg.get("source", {}).get("options", {}).get("space_key", "WSOPLive")
    headings = [s["heading"] for s in sections]
    return (
        f'Find Confluence pages in the "{space}" space that correspond to the following '
        f'EBS contract sections from `{file_path}`. For each section, return JSON '
        f'{{"section": "<name>", "page_id": "<id>", "title": "<page title>", '
        f'"confidence": 0.0..1.0}}. Sections: {headings}.'
    )


def main() -> None:
    ap = argparse.ArgumentParser(description="Stage A planner for /ssot-align")
    ap.add_argument("scope", nargs="*", help="optional file/dir paths to restrict scope")
    ap.add_argument("--team", help="override team detection")
    ap.add_argument("--heading", help="restrict to sections whose ## heading matches exactly")
    ap.add_argument("--resume", action="store_true",
                    help="preserve Stage B patches (source_id/flagged) from an existing plan")
    ap.add_argument("--out", default=str(DEFAULT_OUT), help="output JSON path")
    ap.add_argument("--stdout", action="store_true", help="also print JSON to stdout")
    args = ap.parse_args()

    cfg = load_config()
    team = detect_team(cfg, args.team)
    previous = load_previous_plan(Path(args.out)) if args.resume else None
    plan = build_plan(cfg, team, args.scope or None, heading=args.heading, previous_plan=previous)

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(plan, ensure_ascii=False, indent=2), encoding="utf-8")

    if args.stdout:
        print(json.dumps(plan, ensure_ascii=False, indent=2))

    s = plan["summary"]
    print(
        f"[ssot-align-plan] team={team} files={plan['scope_files']} "
        f"sections={plan['scope_sections']} "
        f"aligned={s['aligned']} cached={s['cached']} "
        f"unmapped={s['unmapped']} native={s['native']} "
        f"rovo_batches={len(plan['rovo_batches'])} "
        f"fetch_needed={s['fetch_needed']}/{s['unique_pages']} "
        f"→ {out_path.relative_to(PROJECT)}"
    )


if __name__ == "__main__":
    main()
