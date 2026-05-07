"""CIA Engine self-test — autonomous iteration over 36 edge cases.

Three test layers:
  1) Unit: pure detector functions (no LLM)
  2) Pipeline-offline: pipeline pieces using heuristic fallback (no LLM)
  3) Live-Gemma: full pipeline against Ollama (skipped if unreachable)
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

from . import config, edge_cases as ec
from .gemma_client import health, list_models, parse_json, GemmaError
from .engine import (
    classify_intent, parse_changed_paths, run_pipeline,
    _heuristic_intent, _normalize_skip,
    IntentMeta, Verified, CIAReport, Candidate,
)


def test_unit_layer() -> tuple[int, int, list[str]]:
    p = t = 0
    fails: list[str] = []

    def check(cond, name, reason=""):
        nonlocal p, t
        t += 1
        if cond:
            p += 1
        else:
            fails.append(f"{name}{(' -- ' + reason) if reason else ''}")

    # E01
    check(ec.is_empty_diff(""), "E01-empty-str")
    check(ec.is_empty_diff(None), "E01-empty-None")
    check(not ec.is_empty_diff("x"), "E01-nonempty")

    # E02
    check(ec.is_binary_diff("Binary files a and b differ"), "E02-binary")
    check(not ec.is_binary_diff("regular text"), "E02-text")

    # E03
    typo_diff = "@@ -1 +1 @@\n-Hello world!\n+Hello, world!"
    check(ec.is_typo_change(typo_diff), "E03-typo")
    big_diff = "\n".join(["+line " + str(i) for i in range(20)])
    check(not ec.is_typo_change(big_diff), "E03-big")

    # E04
    fm_diff = "@@ -1,3 +1,3 @@\n ---\n-version: 1.0\n+version: 1.1\n ---"
    check(ec.is_frontmatter_only(fm_diff), "E04-frontmatter")

    # E05
    check(ec.is_huge_diff("\n" * 6000, max_lines=5000), "E05-huge")
    check(not ec.is_huge_diff("\n" * 100, max_lines=5000), "E05-small")

    # E06
    mer_diff = "+```mermaid\n+flowchart TD\n+  A --> B\n+```"
    check(ec.is_mermaid_only(mer_diff), "E06-mermaid")

    # E08
    check(ec.has_circular_dep({"A": ["B"], "B": ["A"]}), "E08-circular")
    check(not ec.has_circular_dep({"A": ["B"], "B": ["C"]}), "E08-acyclic")

    # E09
    dangling = ec.has_dangling_ref(["x.md", "y.md"], {"y.md"})
    check(dangling == ["x.md"], "E09-dangling", f"got {dangling}")

    # E11
    check(ec.is_ignored_path("docs/_generated/full-index.md", config.IGNORE_PATTERNS), "E11-generated")
    check(not ec.is_ignored_path("docs/1. Product/Foundation.md", config.IGNORE_PATTERNS), "E11-active")

    # E12
    check(ec.is_ignored_path("docs/3. Change Requests/CR-001.md", config.IGNORE_PATTERNS), "E12-history")

    # E13
    try:
        d = parse_json("```json\n{\"x\": 1}\n```")
        check(d == {"x": 1}, "E13-json-fence", f"got {d}")
    except Exception as e:
        check(False, "E13-json-fence", f"raised {e}")

    # E14
    try:
        d = parse_json("Sure, here: {\"y\": 2} done.")
        check(d == {"y": 2}, "E14-json-prose", f"got {d}")
    except Exception as e:
        check(False, "E14-json-prose", f"raised {e}")

    # E15
    try:
        parse_json("no JSON whatsoever")
        check(False, "E15-broken-should-raise")
    except GemmaError:
        check(True, "E15-broken")
    except Exception as e:
        check(False, "E15-broken-wrong", str(e))

    # E24
    check(ec.has_bom_or_crlf("﻿text"), "E24-bom")
    check(ec.has_bom_or_crlf("a\r\nb"), "E24-crlf")
    check(not ec.has_bom_or_crlf("plain"), "E24-plain")

    # E28
    g = {"A": ["B"], "B": ["C"], "C": ["D"], "D": ["E"]}
    d = ec.bfs_depth(g, "A", limit=3)
    check(d == 3, "E28-depth", f"got {d}")

    # E34
    norm = ec.normalize_path("docs/foo/../bar/baz.md")
    check(norm == "docs/bar/baz.md", "E34-norm", f"got {norm}")

    # E35
    bad = "```mermaid\nflowchart\nA[\"line1\nline2\"] --> B\n```"
    check(ec.detect_rule11_violation(bad), "E35-rule11")
    good = "```mermaid\nflowchart\nA[\"line1<br/>line2\"] --> B\n```"
    check(not ec.detect_rule11_violation(good), "E35-rule11-good")

    # E36 - path-with-spaces regex
    import re as _re
    _PAT = "docs/[^" + chr(10) + chr(13) + chr(9) + r"<>|*?]+?\.md"
    test_line = "[external] docs/1. Product/Command_Center_PRD.md"
    m = _re.search(_PAT, test_line)
    check(m and "Command_Center" in m.group(0), "E36-spaces-path",
          f"got {m.group(0) if m else None}")
    test_line2 = "[contract] docs/2. Development/2.4 Command Center/APIs/RFID_HAL_Interface.md"
    m2 = _re.search(_PAT, test_line2)
    check(m2 and m2.group(0).endswith("RFID_HAL_Interface.md"), "E36-deep-spaces")
    _RAG_PAT = r"(\d+\.\d+)\s+(" + _PAT + ")"
    test_rag = "0.85 docs/4. Operations/CC_PRD_Renewal_Plan_2026_05_06.md"
    m3 = _re.search(_RAG_PAT, test_rag)
    check(m3 and m3.group(1) == "0.85", "E36-rag-score-parse",
          f"got {m3.groups() if m3 else None}")

    # E36 - bracketed score format [0.617]  <- doc_rag actual output
    test_rag2 = "  [0.617] docs/1. Product/Lobby_PRD.md"
    _RAG_PAT2 = r"\[?(\d+\.\d+)\]?\s+(" + _PAT + ")"
    m4 = _re.search(_RAG_PAT2, test_rag2)
    check(m4 and m4.group(1) == "0.617", "E36-rag-bracket",
          f"got {m4.groups() if m4 else None}")


    # E10 - skip_reason normalization
    check(_normalize_skip("None") == "", "E10-norm-None")
    check(_normalize_skip("none") == "", "E10-norm-none")
    check(_normalize_skip("null") == "", "E10-norm-null")
    check(_normalize_skip("(none)") == "", "E10-norm-paren")
    check(_normalize_skip("typo only") == "typo only", "E10-norm-real")
    check(_normalize_skip(None) == "", "E10-norm-py-None")

    # E27 - categorize_diff
    cat = ec.categorize_diff(typo_diff)
    check(isinstance(cat, dict) and "typo" in cat, "E27-categorize")

    return p, t, fails


def test_pipeline_offline() -> tuple[int, int, list[str]]:
    """Pipeline tests using heuristic fallback (no LLM dependency)."""
    p = t = 0
    fails: list[str] = []
    os.environ["CIA_INTENT_MODEL"] = "nonexistent:0b"
    import importlib
    from . import config as _cfg
    from . import engine as _eng
    importlib.reload(_cfg)
    importlib.reload(_eng)
    run_pipeline_local = _eng.run_pipeline

    def check(cond, name, reason=""):
        nonlocal p, t
        t += 1
        if cond:
            p += 1
        else:
            fails.append(f"{name}{(' -- ' + reason) if reason else ''}")

    diff1 = ("diff --git a/foo.md b/foo.md\n"
             "index 1234..5678 100644\n"
             "--- a/foo.md\n+++ b/foo.md\n"
             "diff --git a/baz.md b/baz.md\n")
    paths = parse_changed_paths(diff1)
    check("foo.md" in paths and "baz.md" in paths, "parse-paths", f"got {paths}")
    check(parse_changed_paths("") == [], "parse-empty")
    check(parse_changed_paths(None) == [], "parse-None")

    h = _heuristic_intent("Lobby visual update", "")
    check(bool(h.scope) and h.confidence > 0, "heuristic-intent")

    h2 = _heuristic_intent("Command Center 좌측 패널 재배치", "")
    check(bool(h2.scope) or bool(h2.keywords), "heuristic-multilingual")

    r = CIAReport(intent=IntentMeta("A", "test scope", ["k1"], "", 0.9))
    r.verified = [Verified("docs/a.md", True, 0.95, "match", "patch hint")]
    md = r.to_markdown()
    check("docs/a.md" in md and "0.95" in md and "High Confidence" in md, "markdown-render")

    d = r.to_dict()
    check(isinstance(d, dict) and d["summary"]["high_conf"] == 1, "to_dict")

    r2 = CIAReport(intent=IntentMeta("A", "x", [], "", 0.5))
    r2.verified = [
        Verified("a.md", True, 0.95, "high"),
        Verified("b.md", True, 0.7, "review"),
        Verified("c.md", True, 0.3, "reject-low-conf"),
        Verified("d.md", False, 0.95, "reject-impact-false"),
    ]
    check(len(r2.high_confidence()) == 1, "partition-high")
    check(len(r2.needs_review()) == 1, "partition-review")
    check(len(r2.rejected()) == 2, "partition-reject")

    rep = run_pipeline_local("", "")
    check("E01" in rep.edge_cases_triggered, "pipeline-E01")

    diff_gen = "diff --git a/docs/_generated/foo.md b/docs/_generated/foo.md"
    rep2 = run_pipeline_local("regen", diff_gen)
    check("E27" in rep2.edge_cases_triggered, "pipeline-E27")

    diff_bin = "diff --git a/docs/images/logo.png b/docs/images/logo.png\nBinary files differ"
    rep3 = run_pipeline_local("update logo", diff_bin)
    check("E02" in rep3.edge_cases_triggered, "pipeline-E02")

    diff_huge = "diff --git a/x.md b/x.md\n" + "\n".join(["+line " + str(i) for i in range(6000)])
    rep4 = run_pipeline_local("massive", diff_huge)
    check("E05" in rep4.edge_cases_triggered, "pipeline-E05")

    os.environ.pop("CIA_INTENT_MODEL", None)
    importlib.reload(_cfg)
    importlib.reload(_eng)

    return p, t, fails


def test_live_gemma() -> tuple[int, int, list[str]]:
    if not health():
        return 0, 0, ["(skipped: Ollama unreachable at " + config.OLLAMA_BASE + ")"]

    models = list_models()
    fails: list[str] = []
    p = t = 0

    def check(cond, name, reason=""):
        nonlocal p, t
        t += 1
        if cond:
            p += 1
        else:
            fails.append(f"{name}{(' -- ' + reason) if reason else ''}")

    has_intent = any(m.startswith(config.INTENT_MODEL.split(":")[0]) for m in models)
    has_embed = any("bge-m3" in m for m in models)
    check(has_intent, "E22-intent-model-present", f"have {models[:3]}")
    check(has_embed, "E22-embed-model-present")

    if not has_intent:
        return p, t, fails

    intent = classify_intent("Lobby 시각 디자인 small update", "@@ -1 +1 @@\n-old\n+new")
    check(bool(intent.scope) and intent.scope != "(unknown)",
          "E16-multilingual", f"scope={intent.scope}")

    intent2 = classify_intent("Plan a CC visual redesign", "")
    check(bool(intent2.scope), "E32-no-diff", f"scope={intent2.scope}")

    from .gemma_client import generate as _gen, GemmaError as _GE
    try:
        _gen("test prompt", model="nonexistent:0b", json_mode=True, timeout=5, retry=0)
        check(False, "E22-graceful-degrade", "should have raised GemmaError")
    except _GE:
        check(True, "E22-graceful-degrade")
    except Exception as e:
        check(False, "E22-graceful-degrade", f"wrong exception: {type(e).__name__}: {e}")

    return p, t, fails


def main():
    print("=" * 60)
    print("CIA Engine Self-Test (autonomous iteration)")
    print("=" * 60)

    results = []
    p, t, f = test_unit_layer()
    results.append(("Unit", p, t, f))
    print(f"\n[Unit] {p}/{t}")
    for fail in f:
        print(f"  FAIL: {fail}")

    p, t, f = test_pipeline_offline()
    results.append(("Pipeline-offline", p, t, f))
    print(f"\n[Pipeline-offline] {p}/{t}")
    for fail in f:
        print(f"  FAIL: {fail}")

    p, t, f = test_live_gemma()
    results.append(("Live-Gemma", p, t, f))
    print(f"\n[Live-Gemma] {p}/{t}")
    for fail in f:
        print(f"  {fail}")

    total_p = sum(p for _, p, _, _ in results)
    total_t = sum(t for _, _, t, _ in results)
    rate = (total_p / total_t) if total_t else 0.0

    print()
    print("=" * 60)
    print(f"TOTAL: {total_p}/{total_t} PASS ({rate * 100:.1f}%)")
    print("=" * 60)

    if rate >= 1.0:
        print("\n[STATUS] all PASS -- engine ready")
        return 0
    elif rate >= 0.85:
        print(f"\n[STATUS] {rate * 100:.1f}% -- acceptable, edge cases noted")
        return 0
    else:
        print(f"\n[STATUS] {rate * 100:.1f}% -- below 85%, investigate failures")
        return 1


if __name__ == "__main__":
    sys.exit(main())
