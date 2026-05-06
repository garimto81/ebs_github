"""
doc_discovery.py — 기획 작업 시작 전 mandatory pre-work 도구
==============================================================

문제: 직전 turn 에서 `docs/1. Product/Command_Center_PRD.md` (tier=external,
audience=외부 stakeholder, derivative-of=Command_Center_UI/Overview.md) 의
존재를 인지하지 못한 채 Overview.md 를 보강. 외부 인계 PRD 가 stale 됨.

해결: 키워드 + frontmatter (tier / derivative-of / audience-target) 기반
검색 도구. 기획 작업 시작 시 필수 호출.

사용법:
    python tools/doc_discovery.py "Command Center"
    python tools/doc_discovery.py --tier external
    python tools/doc_discovery.py --derives-from "Command_Center_UI/Overview.md"
    python tools/doc_discovery.py --topic CC --tier external
    python tools/doc_discovery.py --impact-of "docs/2. Development/2.4 Command Center/Command_Center_UI/Overview.md"

Layer 1 (이 도구) → Layer 2 (RAG, doc_rag.py) → Layer 3 (pre-edit hook).
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
DOCS = REPO / "docs"
INDEX = DOCS / "_generated" / "full-index.md"


@dataclass
class DocMeta:
    path: Path
    title: str = ""
    owner: str = ""
    tier: str = ""
    audience_target: str = ""
    derivative_of: str = ""
    related_docs: list[str] | None = None
    last_updated: str = ""
    legacy_id: str = ""

    @property
    def relpath(self) -> str:
        return str(self.path.relative_to(REPO)).replace("\\", "/")


# --------------------------------------------------------------------------
# Frontmatter parser (YAML subset — no external deps)
# --------------------------------------------------------------------------


def parse_frontmatter(text: str) -> dict[str, str | list[str]]:
    if not text.startswith("---"):
        return {}
    end = text.find("\n---", 3)
    if end < 0:
        return {}
    block = text[3:end].strip()
    out: dict[str, str | list[str]] = {}
    current_key: str | None = None
    current_list: list[str] = []
    for raw in block.splitlines():
        line = raw.rstrip()
        if not line or line.startswith("#"):
            continue
        m_kv = re.match(r"^([\w-]+):\s*(.*)$", line)
        if m_kv and not line.startswith(" "):
            if current_key:
                out[current_key] = current_list if current_list else out.get(current_key, "")
            key, val = m_kv.group(1).strip(), m_kv.group(2).strip()
            if val == "":
                current_key = key
                current_list = []
            else:
                # strip quotes
                val = val.strip('"').strip("'")
                out[key] = val
                current_key = None
                current_list = []
        elif line.lstrip().startswith("- "):
            item = line.lstrip()[2:].strip().strip('"').strip("'")
            current_list.append(item)
    if current_key:
        out[current_key] = current_list if current_list else out.get(current_key, "")
    return out


def load_meta(path: Path) -> DocMeta:
    try:
        text = path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return DocMeta(path=path)
    fm = parse_frontmatter(text)
    related = fm.get("related-docs") or fm.get("related_docs") or []
    if isinstance(related, str):
        related = [related]
    return DocMeta(
        path=path,
        title=str(fm.get("title", "")),
        owner=str(fm.get("owner", "")),
        tier=str(fm.get("tier", "")),
        audience_target=str(fm.get("audience-target", "")),
        derivative_of=str(fm.get("derivative-of", "")),
        related_docs=related,
        last_updated=str(fm.get("last-updated", "") or fm.get("last_updated", "")),
        legacy_id=str(fm.get("legacy-id", "") or fm.get("legacy_id", "")),
    )


def scan_docs() -> list[DocMeta]:
    out: list[DocMeta] = []
    for md in DOCS.rglob("*.md"):
        if "_generated" in md.parts and md.name != "full-index.md":
            continue
        if "archive" in [p.lower() for p in md.parts]:
            continue
        out.append(load_meta(md))
    return out


# --------------------------------------------------------------------------
# Search modes
# --------------------------------------------------------------------------


def keyword_search(docs: list[DocMeta], term: str) -> list[DocMeta]:
    t = term.lower()
    hits = []
    for d in docs:
        if t in d.title.lower() or t in d.relpath.lower() or t in (d.legacy_id or "").lower():
            hits.append(d)
    return hits


def filter_tier(docs: list[DocMeta], tier: str) -> list[DocMeta]:
    return [d for d in docs if d.tier == tier]


def derives_from(docs: list[DocMeta], target_substr: str) -> list[DocMeta]:
    t = target_substr.lower().replace("\\", "/")
    return [d for d in docs if t in (d.derivative_of or "").lower().replace("\\", "/")]


def impact_of(docs: list[DocMeta], changed_path: str) -> dict[str, list[DocMeta]]:
    """주어진 파일을 변경하면 영향 받는 문서 발견."""
    changed = changed_path.replace("\\", "/")
    # derivative-of values are relative paths (e.g., "../2. Development/...").
    # Match by basename + parent dir tail (last 3 segments) for robustness.
    parts = [p for p in changed.split("/") if p and p != "."]
    tail = "/".join(parts[-3:]) if len(parts) >= 3 else changed
    basename = parts[-1] if parts else changed

    derivatives: list[DocMeta] = []
    for d in docs:
        derived = (d.derivative_of or "").replace("\\", "/")
        if not derived:
            continue
        if tail in derived or basename == derived.rsplit("/", 1)[-1]:
            derivatives.append(d)

    related: list[DocMeta] = []
    for d in docs:
        for r in (d.related_docs or []):
            r_norm = r.replace("\\", "/")
            if tail in r_norm or basename == r_norm.split()[0].rsplit("/", 1)[-1]:
                related.append(d)
                break
    legacy_match: list[DocMeta] = []
    src = Path(changed_path)
    if src.exists():
        try:
            src_meta = load_meta(REPO / changed)
            if src_meta.legacy_id:
                legacy_match = [
                    d for d in docs if d.legacy_id == src_meta.legacy_id and d.path != src_meta.path
                ]
        except Exception:
            pass
    return {
        "derivatives_of_this": derivatives,
        "related_docs_referencing_this": related,
        "same_legacy_id": legacy_match,
    }


# --------------------------------------------------------------------------
# Output
# --------------------------------------------------------------------------


def emoji_tier(t: str) -> str:
    return {
        "external": "🌐",
        "contract": "🔒",
        "internal": "📄",
        "feature": "✨",
        "generated": "⚙️",
    }.get(t, "  ")


def fmt(d: DocMeta) -> str:
    flag = emoji_tier(d.tier or "")
    parts = [f"{flag} [{d.tier or '-':<8}] {d.relpath}"]
    if d.title:
        parts.append(f"     └ {d.title}")
    if d.derivative_of:
        parts.append(f"     ← derivative-of: {d.derivative_of}")
    if d.audience_target:
        parts.append(f"     👥 audience: {d.audience_target}")
    if d.last_updated:
        parts.append(f"     📅 {d.last_updated}")
    return "\n".join(parts)


def print_block(title: str, docs: list[DocMeta]) -> None:
    print(f"\n=== {title} ({len(docs)}) ===")
    if not docs:
        print("  (none)")
        return
    docs.sort(key=lambda d: (d.tier != "external", d.tier != "contract", d.relpath))
    for d in docs:
        print(fmt(d))


# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------


def main(argv: list[str]) -> int:
    p = argparse.ArgumentParser(description="Doc discovery — pre-work mandatory tool")
    p.add_argument("keyword", nargs="?", help="키워드 검색 (title / path / legacy-id)")
    p.add_argument("--tier", choices=["external", "contract", "internal", "feature", "generated"])
    p.add_argument("--derives-from", help="derivative-of 매칭 substring")
    p.add_argument("--impact-of", help="이 파일 변경 시 영향 받는 문서 검색")
    p.add_argument("--topic", help="topic tag (CC, lobby, bo, engine 등)")
    args = p.parse_args(argv)

    docs = scan_docs()
    print(f"📚 Scanned {len(docs)} docs under docs/ (excluded: _generated/, archive/)")

    if args.impact_of:
        impact = impact_of(docs, args.impact_of)
        print(f"\n## 변경 시 영향 매트릭스 — {args.impact_of}")
        print_block("이 파일을 derivative-of 로 가진 PRD (외부 인계 동기화 필수)",
                    impact["derivatives_of_this"])
        print_block("이 파일을 related-docs 에 포함한 문서", impact["related_docs_referencing_this"])
        print_block("동일 legacy-id 문서", impact["same_legacy_id"])
        return 0

    candidates = docs
    if args.tier:
        candidates = filter_tier(candidates, args.tier)
    if args.derives_from:
        candidates = derives_from(candidates, args.derives_from)
    if args.keyword:
        candidates = keyword_search(candidates, args.keyword)
    if args.topic:
        topic_map = {
            "cc": ["command_center", "command center"],
            "lobby": ["lobby"],
            "bo": ["back_office", "back office", "backend"],
            "engine": ["game engine", "game_engine", "engine"],
            "rfid": ["rfid"],
            "overlay": ["overlay"],
        }
        topic_keys = topic_map.get(args.topic.lower(), [args.topic.lower()])
        candidates = [
            d for d in candidates
            if any(k in d.relpath.lower() or k in d.title.lower() for k in topic_keys)
        ]

    print_block(
        f"검색 결과 (tier={args.tier or '*'}, keyword={args.keyword or '*'}, "
        f"derives_from={args.derives_from or '*'}, topic={args.topic or '*'})",
        candidates,
    )

    # Always show external-tier reminder
    external = filter_tier(docs, "external")
    print(f"\n🚨 전체 external tier (외부 인계 PRD) 항상 동기화 검토 필요: {len(external)} 종")
    for d in external:
        print(f"   {emoji_tier('external')} {d.relpath}  ←  {d.derivative_of}")

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
