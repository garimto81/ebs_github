#!/usr/bin/env python3
"""문서 집계 스크립트 — docs/_generated/ 자동 생성.

모든 docs/**/*.md 의 frontmatter 를 파싱하여 다음을 생성:
- docs/_generated/full-index.md            — 전체 TOC + 메타 표
- docs/_generated/by-topic/{APIs,Database,Back_Office}.md
- docs/_generated/by-feature/{feature명}.md  (Lobby, RFID_Cards, Overlay 등)
- docs/_generated/by-owner/{owner}.md
- docs/2. Development/2.N {팀명}.md 등 섹션 landing .md 자동 갱신

CLI:
    python tools/spec_aggregate.py              # 모든 산출물 생성
    python tools/spec_aggregate.py --check      # frontmatter 누락 / legacy-id 중복만 검증

PyYAML 의존. 없으면 정규식 fallback 사용.
"""
from __future__ import annotations

import argparse
import re
import sys
from collections import defaultdict
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DOCS_ROOT = REPO_ROOT / "docs"
GENERATED_ROOT = DOCS_ROOT / "_generated"

CHECK_EXCLUDE_DIRS = {"Backlog", "archive", "3. Change Requests"}
CHECK_EXCLUDE_NAMES = {"Backlog.md", "Active_Work.md", "Conductor_Backlog.md",
                       "Backlog_Aggregate.md"}
CHECK_EXCLUDE_PREFIXES = ("NOTIFY-",)


def is_check_excluded(path: Path) -> bool:
    """frontmatter 검증 제외 대상.

    제외:
    - Backlog/ 항목 디렉토리 (각 팀 + Conductor_Backlog)
    - NOTIFY-*.md 메시지 파일
    - archive/ 폴더 (역사 기록)
    - 3. Change Requests/ 폴더 (v7 거버넌스로 폐기, 역사 보존)
    - 집계 인덱스 (Active_Work, Backlog, Backlog_Aggregate, Conductor_Backlog)
    """
    parts = path.parts
    if any(part in CHECK_EXCLUDE_DIRS for part in parts):
        return True
    if any(part.startswith("_archived-") for part in parts):
        return True
    name = path.name
    if name in CHECK_EXCLUDE_NAMES:
        return True
    if any(name.startswith(prefix) for prefix in CHECK_EXCLUDE_PREFIXES):
        return True
    if path.parent.name == "Conductor_Backlog":
        return True
    return False

try:
    import yaml  # type: ignore

    _HAS_YAML = True
except ImportError:
    _HAS_YAML = False


def parse_frontmatter(text: str) -> dict[str, object]:
    """마크다운 앞부분 frontmatter 를 dict 로 파싱."""
    if not text.startswith("---"):
        return {}
    lines = text.splitlines()
    if len(lines) < 2:
        return {}
    end_idx = None
    for i in range(1, len(lines)):
        if lines[i].rstrip() == "---":
            end_idx = i
            break
    if end_idx is None:
        return {}
    block = "\n".join(lines[1:end_idx])
    if _HAS_YAML:
        try:
            data = yaml.safe_load(block) or {}
            if isinstance(data, dict):
                return data
        except yaml.YAMLError:
            pass
    out: dict[str, object] = {}
    for line in block.splitlines():
        if ":" in line and not line.startswith(" "):
            key, _, value = line.partition(":")
            out[key.strip()] = value.strip()
    return out


def collect_docs() -> list[tuple[Path, dict[str, object]]]:
    """모든 docs/**/*.md 수집 (_generated/ 제외)."""
    out: list[tuple[Path, dict[str, object]]] = []
    if not DOCS_ROOT.exists():
        return out
    for path in DOCS_ROOT.rglob("*.md"):
        if "_generated" in path.parts:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        fm = parse_frontmatter(text)
        out.append((path, fm))
    return out


def rel(path: Path) -> str:
    """REPO_ROOT 기준 상대 경로 (forward slash)."""
    return path.relative_to(REPO_ROOT).as_posix()


def check_mode(docs: list[tuple[Path, dict[str, object]]]) -> int:
    """frontmatter 누락, legacy-id 중복 검증.

    Backlog 항목·NOTIFY 메시지·집계 인덱스는 검사 대상 아님
    (메모리 feedback_audit_scope_discipline 정책: 계약 문서만 audit).
    """
    missing = []
    legacy_ids: dict[str, list[str]] = defaultdict(list)
    checked = 0
    for path, fm in docs:
        if is_check_excluded(path):
            continue
        checked += 1
        if not fm:
            missing.append(rel(path))
            continue
        if "owner" not in fm:
            missing.append(f"{rel(path)} (owner 누락)")
        lid = fm.get("legacy-id")
        if lid:
            legacy_ids[str(lid)].append(rel(path))

    errors = 0
    if missing:
        print("[ERR] frontmatter 누락 / owner 미지정 파일:")
        for m in missing[:30]:
            print(f"  - {m}")
        if len(missing) > 30:
            print(f"  ... (+{len(missing) - 30} more)")
        errors += len(missing)

    dupes = {k: v for k, v in legacy_ids.items() if len(v) > 1}
    if dupes:
        print("[ERR] legacy-id 중복:")
        for lid, paths in dupes.items():
            print(f"  {lid}:")
            for p in paths:
                print(f"    - {p}")
        errors += len(dupes)

    if errors == 0:
        print(f"[OK] 검증 통과 — 검사 {checked} / 총 {len(docs)} 파일 ({len(docs) - checked} 제외)")
    return 0 if errors == 0 else 1


def write_full_index(docs: list[tuple[Path, dict[str, object]]]) -> None:
    GENERATED_ROOT.mkdir(parents=True, exist_ok=True)
    out = GENERATED_ROOT / "full-index.md"
    lines = [
        "---",
        "title: 전체 문서 인덱스",
        "owner: ci",
        "tier: generated",
        "---",
        "",
        "# 전체 문서 인덱스",
        "",
        "> 자동 생성 — `python tools/spec_aggregate.py`",
        "",
        "| 경로 | 제목 | Owner | Tier | Legacy |",
        "|------|------|-------|------|--------|",
    ]
    for path, fm in sorted(docs, key=lambda x: rel(x[0])):
        title = str(fm.get("title", path.stem))
        owner = str(fm.get("owner", "-"))
        tier = str(fm.get("tier", "-"))
        legacy = str(fm.get("legacy-id", "-"))
        lines.append(f"| `{rel(path)}` | {title} | {owner} | {tier} | {legacy} |")
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"[생성] {rel(out)} ({len(docs)} 항목)")


def write_by_topic(docs: list[tuple[Path, dict[str, object]]]) -> None:
    by_topic_dir = GENERATED_ROOT / "by-topic"
    by_topic_dir.mkdir(parents=True, exist_ok=True)
    topics = {
        "APIs": lambda p: "/APIs/" in p.as_posix(),
        "Database": lambda p: "/Database/" in p.as_posix(),
        "Back_Office": lambda p: "/Back_Office/" in p.as_posix(),
    }
    for topic, pred in topics.items():
        matched = [(p, fm) for p, fm in docs if pred(p)]
        lines = [
            "---",
            f"title: {topic} 집계",
            "owner: ci",
            "tier: generated",
            "---",
            "",
            f"# {topic}",
            "",
            "| 경로 | Publisher | Legacy |",
            "|------|-----------|--------|",
        ]
        for p, fm in sorted(matched, key=lambda x: rel(x[0])):
            lines.append(
                f"| `{rel(p)}` | {fm.get('owner', '-')} | {fm.get('legacy-id', '-')} |"
            )
        out = by_topic_dir / f"{topic}.md"
        out.write_text("\n".join(lines) + "\n", encoding="utf-8")
        print(f"[생성] {rel(out)} ({len(matched)} 항목)")


def _sanitize_filename(s: str) -> str:
    """Windows-safe filename — strips chars Windows rejects in paths.

    Forbidden on Windows: <>:"/\\|?* (and trailing dot/space).
    Also replace Unicode arrows/special markers commonly used in
    cross-stream owner labels (e.g. 'stream:S2 → notify ...').
    """
    cleaned = re.sub(r'[<>:"/\\|?*←-⇿]', "_", s)
    cleaned = re.sub(r"\s+", " ", cleaned).strip(" .")
    return cleaned or "unknown"


def write_by_owner(docs: list[tuple[Path, dict[str, object]]]) -> None:
    by_owner_dir = GENERATED_ROOT / "by-owner"
    by_owner_dir.mkdir(parents=True, exist_ok=True)
    buckets: dict[str, list[tuple[Path, dict[str, object]]]] = defaultdict(list)
    for p, fm in docs:
        buckets[str(fm.get("owner", "unknown"))].append((p, fm))
    for owner, items in buckets.items():
        lines = [
            "---",
            f"title: {owner} 소유 문서",
            "owner: ci",
            "tier: generated",
            "---",
            "",
            f"# {owner}",
            "",
        ]
        for p, fm in sorted(items, key=lambda x: rel(x[0])):
            lines.append(f"- `{rel(p)}` — {fm.get('title', p.stem)}")
        safe_name = _sanitize_filename(owner)
        out = by_owner_dir / f"{safe_name}.md"
        out.write_text("\n".join(lines) + "\n", encoding="utf-8")
        print(f"[생성] {rel(out)} ({len(items)} 항목)")


def write_by_feature(docs: list[tuple[Path, dict[str, object]]]) -> None:
    by_feature_dir = GENERATED_ROOT / "by-feature"
    by_feature_dir.mkdir(parents=True, exist_ok=True)
    feature_pattern = re.compile(r"2\. Development/2\.\d [^/]+/([^/]+)/")
    buckets: dict[str, list[tuple[Path, dict[str, object]]]] = defaultdict(list)
    for p, fm in docs:
        m = feature_pattern.search(p.as_posix())
        if m:
            feature = m.group(1)
            if feature.endswith(".md"):
                continue
            buckets[feature].append((p, fm))
    for feature, items in buckets.items():
        lines = [
            "---",
            f"title: {feature} 통합 집계",
            "owner: ci",
            "tier: generated",
            "---",
            "",
            f"# {feature}",
            "",
        ]
        for p, fm in sorted(items, key=lambda x: rel(x[0])):
            lines.append(f"- `{rel(p)}` — {fm.get('title', p.stem)} ({fm.get('owner', '-')})")
        out = by_feature_dir / f"{feature}.md"
        out.write_text("\n".join(lines) + "\n", encoding="utf-8")
        print(f"[생성] {rel(out)} ({len(items)} 항목)")


def write_section_landings(docs: list[tuple[Path, dict[str, object]]]) -> None:
    """docs/2. Development/2.N {팀명}.md landing 자동 생성/갱신.

    landing 파일이 이미 있어도 tier: generated 면 재생성 (stale 링크 자동 정리).
    수동 작성 landing (tier != generated) 은 보존.
    """
    section_pattern = re.compile(r"(docs/2\. Development/2\.\d [^/]+)/")
    buckets: dict[str, list[Path]] = defaultdict(list)
    for p, _ in docs:
        posix = p.as_posix()
        m = section_pattern.search(posix)
        if m:
            buckets[m.group(1)].append(p)
    for section, files in buckets.items():
        section_dir = REPO_ROOT / section
        if not section_dir.exists():
            continue
        section_name = section.split("/")[-1]
        landing = section_dir / f"{section_name}.md"
        if landing.exists():
            existing_fm = parse_frontmatter(landing.read_text(encoding="utf-8"))
            if existing_fm.get("tier") != "generated":
                continue
        lines = [
            "---",
            f"title: {section_name}",
            "owner: ci",
            "tier: generated",
            "---",
            "",
            f"# {section_name}",
            "",
            "> 자동 생성 landing — 하위 문서 목록",
            "",
        ]
        for f in sorted(files, key=lambda x: x.as_posix()):
            if f == landing:
                continue
            rel_to_section = f.relative_to(section_dir).as_posix()
            lines.append(f"- [{rel_to_section}]({rel_to_section})")
        landing.write_text("\n".join(lines) + "\n", encoding="utf-8")
        print(f"[생성] {rel(landing)}")


def main() -> int:
    parser = argparse.ArgumentParser(description="문서 집계 스크립트")
    parser.add_argument("--check", action="store_true", help="검증만 수행")
    args = parser.parse_args()

    docs = collect_docs()
    print(f"[스캔] docs/ 하위 markdown 파일 {len(docs)} 개")

    if args.check:
        return check_mode(docs)

    write_full_index(docs)
    write_by_topic(docs)
    write_by_owner(docs)
    write_by_feature(docs)
    write_section_landings(docs)
    print("[완료] _generated/ 전체 갱신")
    return 0


if __name__ == "__main__":
    sys.exit(main())
