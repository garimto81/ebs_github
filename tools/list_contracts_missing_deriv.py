#!/usr/bin/env python3
"""list_contracts_missing_deriv.py — Phase 3 작업 list 추출"""
from __future__ import annotations
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from ssot_verify import iter_docs, read_frontmatter, classify_file  # noqa: E402

docs = (Path(__file__).resolve().parent.parent / "docs").resolve()
print(f"docs root: {docs}")
print()

contracts = []
for md in iter_docs(docs):
    fm = read_frontmatter(md)
    cat = classify_file(md, docs, fm)
    if cat != "B":
        continue
    fm = fm or {}
    has_link = bool(
        fm.get("derivative-of") or fm.get("related-spec") or fm.get("references")
    )
    if not has_link:
        rel = str(md.relative_to(docs)).replace("\\", "/")
        contracts.append(rel)

print(f"Contract files missing derivative-of/related-spec: {len(contracts)}")
print()
for c in contracts:
    print(f"  {c}")
