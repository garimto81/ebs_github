"""CIA edge case detectors — pure functions, no LLM calls.

Registry lists 36 known scenarios. Each detector is fast and deterministic,
serving as a prefilter before expensive LLM verification.
"""
from __future__ import annotations

import os
import re
from dataclasses import dataclass


@dataclass
class EdgeCaseInfo:
    id: str
    name: str
    category: str  # input | graph | llm | semantic | scope
    severity: str  # skip | low | normal | high | block


REGISTRY: list[EdgeCaseInfo] = [
    EdgeCaseInfo("E01", "empty input (no desc + no diff)", "input", "skip"),
    EdgeCaseInfo("E02", "binary diff (PNG/PDF)", "input", "low"),
    EdgeCaseInfo("E03", "typo-only (<=6 char delta)", "input", "low"),
    EdgeCaseInfo("E04", "frontmatter-only", "input", "low"),
    EdgeCaseInfo("E05", "huge diff (>5000 lines)", "input", "high"),
    EdgeCaseInfo("E06", "Mermaid diagram only", "input", "normal"),
    EdgeCaseInfo("E07", "CC visual cross-PRD cascade", "scope", "high"),
    EdgeCaseInfo("E08", "circular dep in graph", "graph", "block"),
    EdgeCaseInfo("E09", "dangling reference", "graph", "block"),
    EdgeCaseInfo("E10", "skip_reason from LLM", "input", "skip"),
    EdgeCaseInfo("E11", "_generated/ path (auto)", "scope", "skip"),
    EdgeCaseInfo("E12", "history archive (Change Requests)", "scope", "skip"),
    EdgeCaseInfo("E13", "JSON inside markdown fence", "llm", "normal"),
    EdgeCaseInfo("E14", "JSON with prose preamble", "llm", "normal"),
    EdgeCaseInfo("E15", "broken JSON from LLM", "llm", "block"),
    EdgeCaseInfo("E16", "multilingual ko/en intent", "semantic", "normal"),
    EdgeCaseInfo("E17", "confluence-page-id changed", "semantic", "normal"),
    EdgeCaseInfo("E18", "derivative-of relink", "graph", "high"),
    EdgeCaseInfo("E19", "new file create", "input", "normal"),
    EdgeCaseInfo("E20", "file delete", "input", "normal"),
    EdgeCaseInfo("E21", "Gemma timeout", "llm", "block"),
    EdgeCaseInfo("E22", "Ollama unreachable / model missing", "llm", "block"),
    EdgeCaseInfo("E23", "confidence 0.0 (uncertain)", "llm", "normal"),
    EdgeCaseInfo("E24", "BOM / CRLF encoding", "input", "normal"),
    EdgeCaseInfo("E25", "mixed concern intent", "semantic", "normal"),
    EdgeCaseInfo("E26", "RFID hardware (out of scope per memory)", "scope", "low"),
    EdgeCaseInfo("E27", "all paths in ignore list", "scope", "skip"),
    EdgeCaseInfo("E28", "deep cascade depth limit", "graph", "normal"),
    EdgeCaseInfo("E29", "cross-team shared contract", "scope", "high"),
    EdgeCaseInfo("E30", "frontmatter cosmetic (last-updated)", "input", "low"),
    EdgeCaseInfo("E31", "no description (only diff)", "input", "normal"),
    EdgeCaseInfo("E32", "no diff (only description)", "input", "normal"),
    EdgeCaseInfo("E33", "Foundation section anchor change", "semantic", "high"),
    EdgeCaseInfo("E34", "path normalization (../)", "input", "normal"),
    EdgeCaseInfo("E35", "Mermaid newline rule (rule 11)", "semantic", "normal"),
    EdgeCaseInfo("E36", "path-with-spaces regex", "input", "normal"),
]


def is_empty_diff(diff) -> bool:
    if diff is None:
        return True
    return not str(diff).strip()


def is_binary_diff(diff) -> bool:
    if not diff:
        return False
    return ("Binary files" in diff) or ("GIT binary patch" in diff)


def is_huge_diff(diff, max_lines: int = 5000) -> bool:
    if not diff:
        return False
    return diff.count("\n") > max_lines


def is_typo_change(diff) -> bool:
    if not diff:
        return False
    plus = [l[1:] for l in diff.splitlines() if l.startswith("+") and not l.startswith("+++")]
    minus = [l[1:] for l in diff.splitlines() if l.startswith("-") and not l.startswith("---")]
    if not (plus and minus):
        return False
    if len(plus) > 5 or len(minus) > 5:
        return False
    delta = sum(abs(len(p) - len(m)) for p, m in zip(plus, minus))
    return delta <= 6


def is_frontmatter_only(diff) -> bool:
    if not diff:
        return False
    body = [
        l[1:].rstrip()
        for l in diff.splitlines()
        if (l.startswith("+") or l.startswith("-"))
        and not l.startswith(("+++", "---"))
    ]
    if not body:
        return False
    fm_like = sum(1 for l in body if re.match(r"^\s*[\w-]+\s*:\s*\S", l))
    return fm_like / max(1, len(body)) >= 0.7


def is_mermaid_only(diff) -> bool:
    if not diff:
        return False
    return ("```mermaid" in diff) and ("flowchart" in diff or "sequenceDiagram" in diff or "graph " in diff)


def is_ignored_path(path: str, patterns: list[str]) -> bool:
    if not path:
        return False
    norm = path.replace("\\", "/")
    return any(p in norm for p in patterns)


def has_circular_dep(graph: dict[str, list[str]]) -> bool:
    visited: set[str] = set()
    stack: set[str] = set()

    def dfs(n: str) -> bool:
        if n in stack:
            return True
        if n in visited:
            return False
        stack.add(n)
        visited.add(n)
        for m in graph.get(n, []):
            if dfs(m):
                return True
        stack.discard(n)
        return False

    return any(dfs(n) for n in graph)


def has_dangling_ref(refs: list[str], existing: set[str]) -> list[str]:
    return [r for r in refs if r not in existing]


def normalize_path(path: str) -> str:
    return os.path.normpath(path).replace("\\", "/")


def detect_rule11_violation(diff) -> bool:
    """Rule 11: Mermaid label must use <br/>, not literal \n."""
    if not diff:
        return False
    return bool(re.search(r'\["[^"]*\n[^"]*"\]', diff)) and "mermaid" in diff.lower()


def has_bom_or_crlf(text) -> bool:
    if not text:
        return False
    return text.startswith("﻿") or "\r\n" in text


def bfs_depth(graph: dict[str, list[str]], start: str, limit: int) -> int:
    seen: dict[str, int] = {start: 0}
    queue: list[str] = [start]
    max_d = 0
    while queue:
        n = queue.pop(0)
        d = seen[n]
        if d >= limit:
            continue
        for m in graph.get(n, []):
            if m not in seen:
                seen[m] = d + 1
                max_d = max(max_d, d + 1)
                queue.append(m)
    return max_d


def is_low_priority(diff) -> bool:
    if is_typo_change(diff):
        return True
    if is_frontmatter_only(diff):
        return True
    return False


def categorize_diff(diff) -> dict:
    return {
        "empty": is_empty_diff(diff),
        "binary": is_binary_diff(diff),
        "huge": is_huge_diff(diff),
        "typo": is_typo_change(diff),
        "frontmatter_only": is_frontmatter_only(diff),
        "mermaid_only": is_mermaid_only(diff),
        "rule11_violation": detect_rule11_violation(diff),
        "bom_or_crlf": has_bom_or_crlf(diff),
    }
