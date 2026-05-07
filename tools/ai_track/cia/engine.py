"""CIA Engine main orchestrator — 4-step pipeline.

L0 intent classify -> L1 static graph -> L2 hybrid RAG -> L3 LLM verify -> L4 cascade output
"""
from __future__ import annotations

import os
import re
import subprocess
import sys
import time
from dataclasses import dataclass, field, asdict
from pathlib import Path

from . import config, edge_cases as ec
from .gemma_client import generate, parse_json, GemmaError, health


_SUBPROC_ENV = {**os.environ, "PYTHONIOENCODING": "utf-8", "PYTHONUTF8": "1"}


@dataclass
class IntentMeta:
    type: str
    scope: str
    keywords: list[str]
    skip_reason: str = ""
    confidence: float = 0.0


@dataclass
class Candidate:
    path: str
    source: str
    score: float
    snippet: str = ""


@dataclass
class Verified:
    path: str
    impact: bool
    confidence: float
    reason: str
    suggested_patch: str = ""


@dataclass
class CIAReport:
    intent: IntentMeta
    candidates_l1: list[Candidate] = field(default_factory=list)
    candidates_l2: list[Candidate] = field(default_factory=list)
    verified: list[Verified] = field(default_factory=list)
    edge_cases_triggered: list[str] = field(default_factory=list)
    elapsed_ms: int = 0

    def high_confidence(self) -> list[Verified]:
        return [v for v in self.verified
                if v.impact and v.confidence >= config.CONFIDENCE_AUTO_APPLY]

    def needs_review(self) -> list[Verified]:
        return [v for v in self.verified
                if v.impact and config.CONFIDENCE_REVIEW <= v.confidence < config.CONFIDENCE_AUTO_APPLY]

    def rejected(self) -> list[Verified]:
        return [v for v in self.verified
                if (not v.impact) or v.confidence < config.CONFIDENCE_REVIEW]

    def to_dict(self) -> dict:
        return {
            "intent": asdict(self.intent),
            "candidates_l1": [asdict(c) for c in self.candidates_l1],
            "candidates_l2": [asdict(c) for c in self.candidates_l2],
            "verified": [asdict(v) for v in self.verified],
            "edge_cases_triggered": self.edge_cases_triggered,
            "elapsed_ms": self.elapsed_ms,
            "summary": {
                "high_conf": len(self.high_confidence()),
                "review": len(self.needs_review()),
                "rejected": len(self.rejected()),
            },
        }

    def to_markdown(self) -> str:
        lines = [f"# CIA Report -- {self.intent.scope}", ""]
        lines.append(f"**Intent**: type={self.intent.type}, conf={self.intent.confidence:.2f}")
        if self.intent.skip_reason:
            lines.append(f"**Skipped**: {self.intent.skip_reason}")
        if self.edge_cases_triggered:
            lines.append(f"**Edge cases**: {', '.join(self.edge_cases_triggered)}")
        lines.append("")
        if self.high_confidence():
            lines.append("## High Confidence Cascade (auto-apply)")
            for v in self.high_confidence():
                lines.append(f"- `{v.path}` (conf={v.confidence:.2f}) -- {v.reason}")
                if v.suggested_patch:
                    lines.append(f"  - patch: {v.suggested_patch[:200]}")
        if self.needs_review():
            lines.append("\n## Needs Review")
            for v in self.needs_review():
                lines.append(f"- `{v.path}` (conf={v.confidence:.2f}) -- {v.reason}")
        if not self.verified:
            lines.append("(no candidates verified)")
        return "\n".join(lines)


INTENT_PROMPT = """You classify a documentation change intent.
Output ONLY a JSON object with these fields:
  type     : one of "A","B","C","D"
  scope    : short concept e.g. "CC visual design"
  keywords : array of strings
  confidence : float 0.0 to 1.0
  skip_reason : string (set if change is trivial like typo only, formatting only, _generated, history archive, last-updated bump)

Type definitions:
  A = code/text fix matching existing spec
  B = new feature, spec gap
  C = spec contradiction repair
  D = code-spec drift repair

DESCRIPTION:
__DESC__

DIFF (first lines):
__DIFF__
"""


def _normalize_skip(v) -> str:
    """Treat 'None'/'null'/'n/a' string responses as empty (Gemma artifact)."""
    s = str(v or "").strip()
    if s.lower() in ("", "none", "null", "n/a", "(none)", "false", "no", "-"):
        return ""
    return s[:240]


def _heuristic_intent(desc, diff, error: str = "") -> IntentMeta:
    text = ((desc or "") + " " + (diff or "")).lower()
    keywords = re.findall(r"[A-Za-zㄱ-ㆎ가-힣][A-Za-zㄱ-ㆎ가-힣0-9_-]{2,}", text)
    keywords = list(dict.fromkeys(keywords))[:8]
    return IntentMeta(
        type="?",
        scope=(desc or "(heuristic)")[:60],
        keywords=keywords,
        confidence=0.3,
        skip_reason=(f"LLM unavailable ({error}), heuristic fallback" if error else ""),
    )


def classify_intent(description, diff) -> IntentMeta:
    if not description and not diff:
        return IntentMeta("?", "(empty)", [], skip_reason="empty input", confidence=0.0)

    diff_lines = (diff or "").splitlines()[:80]
    diff_short = "\n".join(diff_lines) or "(no diff)"
    desc_safe = (description or "(no description)")[:1200]

    prompt = INTENT_PROMPT.replace("__DESC__", desc_safe).replace("__DIFF__", diff_short[:3000])

    try:
        resp = generate(prompt, model=config.INTENT_MODEL, json_mode=True, timeout=60)
        data = parse_json(resp.text)
        return IntentMeta(
            type=str(data.get("type", "?"))[:2],
            scope=str(data.get("scope", "(unknown)"))[:120],
            keywords=[str(k)[:40] for k in (data.get("keywords") or [])][:10],
            confidence=float(data.get("confidence", 0.5) or 0.5),
            skip_reason=_normalize_skip(data.get("skip_reason")),
        )
    except GemmaError as e:
        return _heuristic_intent(description, diff, error=str(e))


def parse_changed_paths(diff) -> list[str]:
    if not diff:
        return []
    paths: list[str] = []
    seen: set[str] = set()
    for line in diff.splitlines():
        m = re.match(r"^diff --git a/(.+?) b/", line)
        if not m:
            m = re.match(r"^\+\+\+\s+b/(.+)$", line)
        if m:
            p = m.group(1).strip()
            if p and p not in seen:
                seen.add(p)
                paths.append(p)
    return paths


_PATH_RE = "docs/[^" + chr(10) + chr(13) + chr(9) + chr(60) + chr(62) + chr(124) + chr(42) + chr(63) + r"]+?\.md"
_RAG_RE = r"(\d+\.\d+)\s+(" + _PATH_RE + ")"


def static_graph_lookup(intent: IntentMeta, changed_paths: list[str]) -> list[Candidate]:
    if not config.DOC_DISCOVERY.exists():
        return []

    cands: dict[str, Candidate] = {}

    for path in changed_paths[:10]:
        try:
            r = subprocess.run(
                [sys.executable, str(config.DOC_DISCOVERY), "--impact-of", path],
                capture_output=True, text=True, timeout=30,
                encoding="utf-8", errors="ignore",
                env=_SUBPROC_ENV,
            )
            for line in (r.stdout or "").splitlines():
                m = re.search(_PATH_RE, line)
                if not m:
                    continue
                p = m.group(0)
                if p not in cands:
                    cands[p] = Candidate(path=p, source="L1-static", score=1.0,
                                         snippet=line.strip()[:160])
        except (subprocess.TimeoutExpired, OSError):
            continue

    for kw in intent.keywords[:3]:
        if not kw:
            continue
        try:
            r = subprocess.run(
                [sys.executable, str(config.DOC_DISCOVERY), kw],
                capture_output=True, text=True, timeout=30,
                encoding="utf-8", errors="ignore",
                env=_SUBPROC_ENV,
            )
            for line in (r.stdout or "").splitlines():
                m = re.search(_PATH_RE, line)
                if not m:
                    continue
                p = m.group(0)
                if p not in cands:
                    cands[p] = Candidate(path=p, source="L1-static", score=0.7,
                                         snippet=line.strip()[:160])
        except (subprocess.TimeoutExpired, OSError):
            continue

    return list(cands.values())


def hybrid_rag_lookup(intent: IntentMeta) -> list[Candidate]:
    if not config.DOC_RAG.exists():
        return []
    query_parts = [intent.scope] + intent.keywords[:5]
    query = " ".join([q for q in query_parts if q]).strip()
    if not query:
        return []
    try:
        r = subprocess.run(
            [sys.executable, str(config.DOC_RAG), "--top", "20", query],
            capture_output=True, text=True, timeout=90,
            encoding="utf-8", errors="ignore",
            env=_SUBPROC_ENV,
        )
        cands: list[Candidate] = []
        for line in (r.stdout or "").splitlines():
            m = re.search(_RAG_RE, line)
            if m:
                cands.append(Candidate(
                    path=m.group(2),
                    source="L2-rag",
                    score=float(m.group(1)),
                    snippet=line.strip()[:160],
                ))
        return cands
    except (subprocess.TimeoutExpired, OSError):
        return []


VERIFY_PROMPT = """You verify if a documentation change cascades to a candidate document.
Output ONLY a JSON object with these fields:
  impact          : true or false
  confidence      : float 0.0 to 1.0
  reason          : one short sentence
  suggested_patch : what should change in the candidate doc, or empty string

Set impact=false if the candidate is unrelated, archived, or trivial.

INTENT: __SCOPE__ (type __TYPE__)
KEYWORDS: __KWS__

DIFF SUMMARY:
__DIFF__

CANDIDATE PATH: __PATH__
CANDIDATE SNIPPET:
__SNIPPET__
"""


def verify_candidate(intent: IntentMeta, diff, cand: Candidate) -> Verified:
    diff_short = "\n".join((diff or "").splitlines()[:40])
    prompt = (VERIFY_PROMPT
              .replace("__SCOPE__", intent.scope or "")
              .replace("__TYPE__", intent.type or "?")
              .replace("__KWS__", ", ".join(intent.keywords[:5]))
              .replace("__DIFF__", diff_short or "(no diff)")
              .replace("__PATH__", cand.path)
              .replace("__SNIPPET__", (cand.snippet or "(no snippet)")[:240]))
    try:
        resp = generate(prompt, model=config.CIA_MODEL, json_mode=True,
                        timeout=config.LLM_TIMEOUT_SEC)
        d = parse_json(resp.text)
        return Verified(
            path=cand.path,
            impact=bool(d.get("impact", False)),
            confidence=float(d.get("confidence", 0.0) or 0.0),
            reason=str(d.get("reason", ""))[:240],
            suggested_patch=str(d.get("suggested_patch", ""))[:480],
        )
    except GemmaError as e:
        return Verified(
            path=cand.path, impact=False, confidence=0.0,
            reason=f"verify failed: {type(e).__name__}: {e}",
        )


def run_pipeline(description, diff) -> CIAReport:
    t0 = time.time()
    triggered: list[str] = []

    cat = ec.categorize_diff(diff)
    if cat["empty"] and not description:
        rep = CIAReport(intent=IntentMeta("?", "(empty)", [], "empty input", 0.0))
        rep.edge_cases_triggered = ["E01"]
        rep.elapsed_ms = int((time.time() - t0) * 1000)
        return rep

    if cat["binary"]:
        triggered.append("E02")
        diff_for_llm = "(binary diff -- paths only)"
    elif cat["huge"]:
        triggered.append("E05")
        diff_for_llm = "\n".join((diff or "").splitlines()[:config.MAX_DIFF_LINES]) + "\n... (truncated)"
    else:
        diff_for_llm = diff

    if cat["rule11_violation"]:
        triggered.append("E35")
    if cat["typo"]:
        triggered.append("E03")
    if cat["frontmatter_only"]:
        triggered.append("E04")
    if cat["mermaid_only"]:
        triggered.append("E06")

    changed = parse_changed_paths(diff)
    changed_active = [p for p in changed if not ec.is_ignored_path(p, config.IGNORE_PATTERNS)]
    if changed and not changed_active:
        triggered.append("E27")
        rep = CIAReport(intent=IntentMeta("A", "(all paths ignored)", [],
                                          "all changes in ignore list", 0.0))
        rep.edge_cases_triggered = triggered
        rep.elapsed_ms = int((time.time() - t0) * 1000)
        return rep

    intent = classify_intent(description, diff_for_llm)
    if intent.skip_reason:
        triggered.append("E10")
        rep = CIAReport(intent=intent, edge_cases_triggered=triggered)
        rep.elapsed_ms = int((time.time() - t0) * 1000)
        return rep

    l1 = static_graph_lookup(intent, changed_active or changed)
    l2 = hybrid_rag_lookup(intent)

    merged: dict[str, Candidate] = {}
    for c in l1 + l2:
        if ec.is_ignored_path(c.path, config.IGNORE_PATTERNS):
            continue
        if c.path in merged:
            existing = merged[c.path]
            if existing.source != c.source:
                existing.score = max(existing.score, c.score) + 0.3
                existing.source = "L1+L2"
            else:
                existing.score = max(existing.score, c.score)
        else:
            merged[c.path] = c

    candidates = sorted(merged.values(), key=lambda x: -x.score)[:config.MAX_CANDIDATES]

    verified: list[Verified] = []
    for cand in candidates:
        v = verify_candidate(intent, diff_for_llm, cand)
        verified.append(v)

    rep = CIAReport(
        intent=intent,
        candidates_l1=l1, candidates_l2=l2,
        verified=verified,
        edge_cases_triggered=triggered,
        elapsed_ms=int((time.time() - t0) * 1000),
    )
    return rep


def _cli():
    import argparse
    import json as _json
    ap = argparse.ArgumentParser(prog="cia")
    ap.add_argument("--desc", help="change description / intent")
    ap.add_argument("--diff", help="path to diff file (or - for stdin)")
    ap.add_argument("--diff-from-git", action="store_true",
                    help="use git diff HEAD~1 HEAD")
    ap.add_argument("--json", action="store_true",
                    help="output JSON instead of markdown")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()

    if args.self_test:
        from .self_test import main as st_main
        return st_main()

    diff_text = ""
    if args.diff_from_git:
        try:
            r = subprocess.run(["git", "diff", "HEAD~1", "HEAD"],
                               capture_output=True, text=True, timeout=30,
                               encoding="utf-8", errors="ignore")
            diff_text = r.stdout or ""
        except Exception as e:
            print("git diff failed: " + str(e), file=sys.stderr)
            return 2
    elif args.diff:
        if args.diff == "-":
            diff_text = sys.stdin.read()
        else:
            diff_text = Path(args.diff).read_text(encoding="utf-8", errors="ignore")

    rep = run_pipeline(args.desc or "", diff_text)
    if args.json:
        print(_json.dumps(rep.to_dict(), ensure_ascii=False, indent=2))
    else:
        print(rep.to_markdown())
    return 0


if __name__ == "__main__":
    sys.exit(_cli())
