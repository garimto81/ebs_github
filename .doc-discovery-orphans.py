"""EBS Orphan + Duplicate analyzer (one-shot, throwaway).

Run from C:\\claude\\ebs:
    python .doc-discovery-orphans.py

Outputs:
    .doc-discovery-orphans.txt   — files with 0 incoming references
    .doc-discovery-duplicates.txt — high-similarity pairs in suspect folders
"""
from __future__ import annotations

import sys
from collections import defaultdict
from pathlib import Path

SKILL = Path.home() / ".claude" / "skills" / "doc-discovery"
sys.path.insert(0, str(SKILL))

from lib.embedder import Embedder, cosine  # noqa: E402
from lib.unified_graph import build_unified_graph  # noqa: E402

ROOT = Path(__file__).parent.resolve()


def analyze_orphans() -> list[str]:
    """Find .md files with zero incoming references in the doc graph."""
    graph = build_unified_graph(ROOT, cache=None, include_code=False, include_doc=True)

    # Build reverse adjacency: target → set of sources
    in_degree: dict[str, int] = defaultdict(int)
    for src, edge_map in graph.forward.items():
        for _edge_type, targets in edge_map.items():
            for target in targets:
                in_degree[target] += 1

    # Collect every node that is an .md path inside our root and has 0 in-edges
    orphans = []
    for node in graph.nodes:
        if not node.endswith(".md"):
            continue
        # Skip nodes that are out-of-corpus paths (../) or external labels
        if node.startswith("../") or "://" in node:
            continue
        if "/archive/" in node or "/_archived" in node:
            continue  # already archived, not relevant
        if in_degree.get(node, 0) == 0:
            orphans.append(node)

    orphans.sort()
    return orphans


def analyze_duplicates() -> list[tuple[str, str, float]]:
    """Compare suspect-cluster files pairwise via embeddings."""
    suspect_dirs = [
        "docs/2. Development/2.1 Frontend/Graphic_Editor/References/skin-editor",
        "docs/2. Development/2.3 Game Engine/Behavioral_Specs",
        "docs/4. Operations",
    ]
    files: list[Path] = []
    for sub in suspect_dirs:
        base = ROOT / sub
        if not base.exists():
            continue
        for path in base.rglob("*.md"):
            if "/archive/" in str(path).replace("\\", "/"):
                continue
            if path.is_file() and path.stat().st_size < 200_000:
                files.append(path)

    if len(files) < 2:
        return []

    embedder = Embedder()
    if not embedder.available:
        print("WARN: no embedding backend; skipping duplicate analysis")
        return []

    # Use the first 4000 chars of each doc as its "summary" for embedding
    texts = []
    for f in files:
        try:
            t = f.read_text(encoding="utf-8", errors="replace")
            # strip frontmatter
            if t.startswith("---"):
                end = t.find("\n---", 3)
                if end != -1:
                    t = t[end + 4 :]
            texts.append(t.strip()[:4000] or f.name)
        except OSError:
            texts.append(f.name)

    print(f"Embedding {len(files)} files...")
    vectors = embedder.embed(texts)

    pairs: list[tuple[str, str, float]] = []
    for i in range(len(files)):
        for j in range(i + 1, len(files)):
            sim = cosine(vectors[i], vectors[j])
            if sim >= 0.75:
                pairs.append((str(files[i].relative_to(ROOT)).replace("\\", "/"),
                              str(files[j].relative_to(ROOT)).replace("\\", "/"),
                              sim))
    pairs.sort(key=lambda p: -p[2])
    return pairs


def main() -> int:
    print("=" * 60)
    print("A. Orphan analysis (in-degree = 0)")
    print("=" * 60)
    orphans = analyze_orphans()
    out_a = ROOT / ".doc-discovery-orphans.txt"
    out_a.write_text("\n".join(orphans), encoding="utf-8")
    print(f"  total: {len(orphans)}")
    print(f"  saved: {out_a}")
    print("\n  preview (top 25):")
    for o in orphans[:25]:
        print(f"    {o}")
    if len(orphans) > 25:
        print(f"    ... and {len(orphans) - 25} more")

    print()
    print("=" * 60)
    print("B. Duplicate analysis (cosine ≥ 0.75 in suspect folders)")
    print("=" * 60)
    pairs = analyze_duplicates()
    out_b = ROOT / ".doc-discovery-duplicates.txt"
    body = "\n".join(f"{p[2]:.3f}\t{p[0]}\t<>\t{p[1]}" for p in pairs)
    out_b.write_text(body, encoding="utf-8")
    print(f"  total pairs: {len(pairs)}")
    print(f"  saved: {out_b}")
    print("\n  preview (top 15):")
    for sim, a, b in [(p[2], p[0], p[1]) for p in pairs[:15]]:
        print(f"    {sim:.3f}  {a}")
        print(f"           ↔  {b}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
