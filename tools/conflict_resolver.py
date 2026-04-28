#!/usr/bin/env python3
"""conflict_resolver.py — v7.5 Autonomous Conflict Triage engine.

SG-028 (2026-04-28). Mode B 멀티세션 의미적 충돌 판정 자동화.

Architecture:
  Python  = 메카닉 (충돌 추출, SSOT lookup, Git 명령 적용, 검증, audit)
  LLM     = 의미 판정 (Claude Code session 이 analyze JSON 읽고 decision JSON 작성)

  Local flow (team_v5_merge.py rebase conflict 시):
    1. analyze  → .conflict_request.json 작성, exit 0
    2. (외부 LLM session 이 decision 작성)
    3. apply    → decision 적용, 검증, rebase --continue, registry 갱신, issue 등록

  CI flow (.github/workflows/pr-auto-merge.yml rebase conflict 시):
    ci-only → issue 등록 + auto-merge 라벨 제거. LLM 없이 사후 처리만.

Subcommands:
  analyze         conflict 감지 + SSOT lookup + decision request JSON 출력
  apply           decision JSON 받아 Git 명령 적용 + 검증 + rebase --continue
  ci-only         CI workflow 용. issue 등록 + label 제거 (LLM 호출 없음)
  self-test       내부 dry-run (인공 conflict 시나리오 시뮬레이션)

Exit codes:
  0  success
  1  conflict detected, decision request written (analyze 정상)
  2  apply 실패 (verification fail, rebase --continue 실패 등)
  3  환경 오류 (gh 미설치, repo 경로 이상)
  4  user-escalation 필요 (모든 자율 판정 실패)
"""
from __future__ import annotations

import argparse
import datetime
import json
import os
import re
import subprocess
import sys
import uuid
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parents[1]
POLICY_PATH = REPO / "docs" / "2. Development" / "2.5 Shared" / "team-policy.json"
REGISTRY_PATH = REPO / "docs" / "4. Operations" / "Conflict_Registry.md"
REQUEST_FILE = REPO / ".conflict_request.json"
DECISION_FILE = REPO / ".conflict_decision.json"
SCHEMA_VERSION = "v7.5"


def _run(cmd: list[str], check: bool = False) -> tuple[int, str, str]:
    r = subprocess.run(cmd, cwd=REPO, capture_output=True, text=True, timeout=120)
    if check and r.returncode != 0:
        raise RuntimeError(f"{cmd}: {r.stderr[:200]}")
    return r.returncode, r.stdout, r.stderr


def _load_policy() -> dict[str, Any]:
    if not POLICY_PATH.exists():
        return {}
    try:
        return json.loads(POLICY_PATH.read_text(encoding="utf-8"))
    except Exception:
        return {}


def _conflicted_files() -> list[str]:
    rc, out, _ = _run(["git", "diff", "--name-only", "--diff-filter=U"])
    return [f for f in out.strip().splitlines() if f]


def _is_rebase_in_progress() -> bool:
    return (REPO / ".git" / "rebase-merge").exists() or (REPO / ".git" / "rebase-apply").exists()


def _extract_hunks(file_path: str) -> list[dict[str, Any]]:
    """Conflict marker (<<<<, ====, >>>>) 단위 hunk 추출."""
    p = REPO / file_path
    if not p.exists():
        return []
    try:
        content = p.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return [{"error": "binary or unreadable"}]
    lines = content.splitlines(keepends=False)
    hunks: list[dict[str, Any]] = []
    i = 0
    while i < len(lines):
        if lines[i].startswith("<<<<<<<"):
            start = i
            ours: list[str] = []
            theirs: list[str] = []
            i += 1
            while i < len(lines) and not lines[i].startswith("======="):
                ours.append(lines[i])
                i += 1
            i += 1  # skip ======
            while i < len(lines) and not lines[i].startswith(">>>>>>>"):
                theirs.append(lines[i])
                i += 1
            end = i
            hunks.append({
                "line_start": start + 1,
                "line_end": end + 1,
                "ours_label": lines[start].replace("<<<<<<<", "").strip(),
                "theirs_label": lines[end].replace(">>>>>>>", "").strip() if end < len(lines) else "",
                "ours": "\n".join(ours),
                "theirs": "\n".join(theirs),
            })
        i += 1
    return hunks


def _ssot_for_path(file_path: str, policy: dict[str, Any]) -> dict[str, Any]:
    """team-policy.json contract_ownership + teams[].owns 매핑."""
    refs: list[str] = []
    contract_path: str | None = None
    publisher: str | None = None
    direct_edit_risk: str | None = None

    contracts = policy.get("contract_ownership", {})
    for contract_doc, meta in contracts.items():
        if file_path == contract_doc or file_path.startswith(contract_doc.rstrip(".md")):
            refs.append(contract_doc)
            contract_path = contract_doc
            publisher = meta.get("publisher")
            direct_edit_risk = meta.get("direct_edit")
            break

    teams = policy.get("teams", {})
    for team_id, team_meta in teams.items():
        for owned in team_meta.get("owns", []):
            if file_path.startswith(owned):
                if not publisher:
                    publisher = team_id
                # 같은 팀의 docs/ 경로를 SSOT 후보로 추가
                for ref in team_meta.get("owns", []):
                    if ref.startswith("docs/") and ref not in refs:
                        refs.append(ref)
                break

    return {
        "contract_path": contract_path,
        "publisher": publisher,
        "direct_edit_risk": direct_edit_risk,
        "ssot_refs": refs[:5],  # 최대 5개로 제한 (LLM context 보호)
    }


def _current_branch() -> str:
    rc, out, _ = _run(["git", "branch", "--show-current"])
    return out.strip() if rc == 0 else "(detached)"


def _build_request() -> dict[str, Any]:
    policy = _load_policy()
    files = _conflicted_files()
    rebase_phase = _is_rebase_in_progress()
    branch = _current_branch()

    rc, base_log, _ = _run(["git", "log", "-1", "--format=%H %s", "ORIG_HEAD"])
    orig_head = base_log.strip() if rc == 0 else ""

    conflicts: list[dict[str, Any]] = []
    for f in files:
        hunks = _extract_hunks(f)
        ssot = _ssot_for_path(f, policy)
        conflicts.append({
            "file": f,
            "hunks": hunks,
            "ssot": ssot,
            "is_contract": ssot["contract_path"] is not None,
        })

    return {
        "schema_version": SCHEMA_VERSION,
        "request_id": str(uuid.uuid4()),
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
        "branch": branch,
        "rebase_phase": rebase_phase,
        "orig_head": orig_head,
        "conflicts": conflicts,
        "fallback_hints": {
            "rebase_semantics": "ours = base (origin/main, where rebase replays onto), theirs = work HEAD (new)",
            "new_side_is": "theirs",
            "fallback_priority_1": "lower side-effect wins (contract paths, DB schema, API signatures = high side-effect)",
            "fallback_priority_2": "if tied on priority 1, prefer 'theirs' (new code, system progress)",
        },
        "decision_schema_hint": {
            "schema_version": SCHEMA_VERSION,
            "decisions": [
                {
                    "file": "<from conflicts[].file>",
                    "action": "use_ours | use_theirs | use_merged | abort_branch",
                    "rationale": "<reason>",
                    "merged_content": "<only if action=use_merged, full file content>",
                }
            ],
            "global_action": "continue | abort",
        },
    }


def cmd_analyze(args: argparse.Namespace) -> int:
    if not _conflicted_files():
        print("[info] no conflicts detected", file=sys.stderr)
        return 0
    request = _build_request()
    REQUEST_FILE.write_text(json.dumps(request, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[info] {len(request['conflicts'])} conflicted file(s). Request → {REQUEST_FILE}")
    print(f"[info] Next: LLM session reads {REQUEST_FILE.name}, writes {DECISION_FILE.name}, runs:")
    print(f"        python tools/conflict_resolver.py apply")
    if args.print_request:
        print(json.dumps(request, indent=2, ensure_ascii=False))
    return 1  # signal "decision needed"


def _verify_changes() -> tuple[bool, str]:
    """Touched 파일 기반 lint/test."""
    rc, out, _ = _run(["git", "diff", "--name-only", "--cached"])
    changed = out.strip().splitlines()

    py_changed = any(f.endswith(".py") for f in changed)
    dart_changed = any(f.endswith(".dart") for f in changed)

    notes: list[str] = []

    if py_changed:
        rc, _, err = _run([sys.executable, "-c", "import ast,sys; [ast.parse(open(f,encoding='utf-8').read()) for f in sys.argv[1:]]"]
                          + [f for f in changed if f.endswith(".py")])
        if rc != 0:
            return False, f"python syntax check failed: {err[:200]}"
        notes.append("python syntax OK")

    if dart_changed:
        rc, _, err = _run(["dart", "analyze", "--fatal-warnings"])
        if rc != 0:
            return False, f"dart analyze failed: {err[:200]}"
        notes.append("dart analyze OK")

    return True, "; ".join(notes) or "no lint targets"


def _append_registry(entry: dict[str, Any]) -> None:
    REGISTRY_PATH.parent.mkdir(parents=True, exist_ok=True)
    if not REGISTRY_PATH.exists():
        REGISTRY_PATH.write_text(_registry_header(), encoding="utf-8")
    line = (
        f"| {entry['timestamp']} | `{entry['branch']}` | {entry['conflict_count']} | "
        f"{entry['decision_summary']} | {entry.get('issue_url', '-')} | "
        f"`{entry['request_id'][:8]}` |\n"
    )
    with REGISTRY_PATH.open("a", encoding="utf-8") as f:
        f.write(line)


def _registry_header() -> str:
    return """---
title: Conflict Registry (v7.5 Autonomous Triage Audit Trail)
owner: conductor
tier: contract
last-updated: 2026-04-28
---

# Conflict Registry

자율 충돌 판정 (v7.5 SG-028) 의 audit trail. 모든 결정 (자동 적용 + abort + ci-only) 이 여기 누적된다.

| timestamp (UTC) | branch | files | decision summary | issue | req_id |
|-----------------|--------|-------|------------------|-------|--------|
"""


def _create_issue(title: str, body: str) -> str | None:
    """gh issue create. 실패 시 None 반환 (best-effort)."""
    rc, _, _ = _run(["gh", "--version"])
    if rc != 0:
        return None
    rc, out, err = _run(["gh", "issue", "create", "--title", title, "--body", body, "--label", "conflict-audit"])
    if rc != 0:
        # 라벨 부재 시 재시도
        _run(["gh", "label", "create", "conflict-audit", "--color", "B60205",
              "--description", "v7.5 autonomous triage audit"])
        rc, out, err = _run(["gh", "issue", "create", "--title", title, "--body", body, "--label", "conflict-audit"])
        if rc != 0:
            return None
    return out.strip().splitlines()[-1] if out.strip() else None


def _summarize_decisions(decision: dict[str, Any]) -> str:
    counts: dict[str, int] = {}
    for d in decision.get("decisions", []):
        counts[d["action"]] = counts.get(d["action"], 0) + 1
    parts = [f"{k}:{v}" for k, v in sorted(counts.items())]
    parts.append(f"global={decision.get('global_action', '?')}")
    return ", ".join(parts)


def _apply_one(decision: dict[str, Any]) -> tuple[bool, str]:
    """단일 파일 결정 적용. (success, message)."""
    file_path = decision["file"]
    action = decision["action"]
    p = REPO / file_path

    if action == "use_ours":
        rc, _, err = _run(["git", "checkout", "--ours", "--", file_path])
        if rc != 0:
            return False, f"checkout --ours failed: {err[:120]}"
    elif action == "use_theirs":
        rc, _, err = _run(["git", "checkout", "--theirs", "--", file_path])
        if rc != 0:
            return False, f"checkout --theirs failed: {err[:120]}"
    elif action == "use_merged":
        merged = decision.get("merged_content")
        if merged is None:
            return False, "use_merged requires merged_content"
        p.write_text(merged, encoding="utf-8")
    elif action == "abort_branch":
        return True, "abort_branch deferred to global handler"
    else:
        return False, f"unknown action: {action}"

    rc, _, err = _run(["git", "add", "--", file_path])
    if rc != 0:
        return False, f"git add failed: {err[:120]}"
    return True, f"{action} applied"


def cmd_apply(args: argparse.Namespace) -> int:
    decision_path = Path(args.decision_file) if args.decision_file else DECISION_FILE
    if not decision_path.exists():
        print(f"[error] decision file not found: {decision_path}", file=sys.stderr)
        return 2
    try:
        decision = json.loads(decision_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        print(f"[error] decision JSON invalid: {e}", file=sys.stderr)
        return 2

    if decision.get("schema_version") != SCHEMA_VERSION:
        print(f"[warn] schema version mismatch: {decision.get('schema_version')} vs {SCHEMA_VERSION}", file=sys.stderr)

    branch = _current_branch()
    request_id = decision.get("request_id", "unknown")

    if decision.get("global_action") == "abort":
        print("[info] global_action=abort. rebase --abort + Spec_Gap escalation")
        if _is_rebase_in_progress():
            _run(["git", "rebase", "--abort"])
        REQUEST_FILE.unlink(missing_ok=True)
        decision_path.unlink(missing_ok=True)
        title = f"[v7.5 Triage] ABORT — {branch}"
        body = _format_issue_body(decision, "abort", outcome="rebase aborted, branch left intact")
        url = _create_issue(title, body)
        _append_registry({
            "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
            "branch": branch,
            "conflict_count": len(decision.get("decisions", [])),
            "decision_summary": "GLOBAL ABORT",
            "issue_url": url or "-",
            "request_id": request_id,
        })
        return 4 if not args.no_escalation else 0

    failures: list[str] = []
    for d in decision.get("decisions", []):
        ok, msg = _apply_one(d)
        if not ok:
            failures.append(f"{d['file']}: {msg}")

    if failures:
        print("[error] some decisions failed:", file=sys.stderr)
        for f in failures:
            print(f"  - {f}", file=sys.stderr)
        return 2

    # Verification (lint/syntax)
    if not args.skip_verify:
        ok, msg = _verify_changes()
        if not ok:
            print(f"[error] verification failed: {msg}", file=sys.stderr)
            print("[info] auto-rollback: rebase --abort", file=sys.stderr)
            if _is_rebase_in_progress():
                _run(["git", "rebase", "--abort"])
            title = f"[v7.5 Triage] VERIFY-FAIL — {branch}"
            body = _format_issue_body(decision, "verify_fail", outcome=msg)
            url = _create_issue(title, body)
            _append_registry({
                "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
                "branch": branch,
                "conflict_count": len(decision.get("decisions", [])),
                "decision_summary": f"VERIFY FAIL: {msg[:60]}",
                "issue_url": url or "-",
                "request_id": request_id,
            })
            return 2
        print(f"[info] verify: {msg}")

    # Rebase --continue if applicable
    if _is_rebase_in_progress():
        env = os.environ.copy()
        env["GIT_EDITOR"] = "true"
        rc = subprocess.run(["git", "rebase", "--continue"], cwd=REPO, env=env).returncode
        if rc != 0:
            print(f"[error] rebase --continue failed (rc={rc})", file=sys.stderr)
            return 2

    # Audit
    summary = _summarize_decisions(decision)
    title = f"[v7.5 Triage] RESOLVED — {branch}"
    body = _format_issue_body(decision, "resolved", outcome=summary)
    url = _create_issue(title, body) if not args.no_issue else None
    _append_registry({
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
        "branch": branch,
        "conflict_count": len(decision.get("decisions", [])),
        "decision_summary": summary,
        "issue_url": url or "-",
        "request_id": request_id,
    })

    REQUEST_FILE.unlink(missing_ok=True)
    decision_path.unlink(missing_ok=True)
    print(f"[ok] resolved: {summary}")
    return 0


def _format_issue_body(decision: dict[str, Any], state: str, outcome: str) -> str:
    lines = [
        f"## v7.5 Autonomous Triage — {state.upper()}",
        "",
        f"- branch: `{_current_branch()}`",
        f"- request_id: `{decision.get('request_id', 'unknown')}`",
        f"- timestamp: {datetime.datetime.utcnow().isoformat()}Z",
        f"- outcome: {outcome}",
        "",
        "### Decisions",
        "",
        "| file | action | rationale |",
        "|------|--------|-----------|",
    ]
    for d in decision.get("decisions", []):
        rat = (d.get("rationale") or "").replace("\n", " ").replace("|", "\\|")[:200]
        lines.append(f"| `{d['file']}` | {d['action']} | {rat} |")
    lines.append("")
    lines.append(f"_Audit: see `docs/4. Operations/Conflict_Registry.md`._")
    return "\n".join(lines)


def cmd_ci_only(args: argparse.Namespace) -> int:
    """workflow 환경: LLM 없이 issue 만 생성 + auto-merge 라벨 제거."""
    pr_number = args.pr_number or os.environ.get("PR_NUMBER")
    branch = _current_branch()
    request = _build_request()
    REQUEST_FILE.write_text(json.dumps(request, indent=2, ensure_ascii=False), encoding="utf-8")

    title = f"[v7.5 Triage] CI-CONFLICT — {branch}"
    body_parts = [
        f"## v7.5 CI Conflict (LLM judgment unavailable in workflow)",
        "",
        f"- branch: `{branch}`",
        f"- request_id: `{request['request_id']}`",
        f"- pr: #{pr_number}" if pr_number else "- pr: (not provided)",
        "",
        "### Conflicted files",
        "",
    ]
    for c in request["conflicts"]:
        ssot_str = ", ".join(c["ssot"]["ssot_refs"]) or "(no SSOT mapping)"
        body_parts.append(f"- `{c['file']}` — SSOT: {ssot_str}")
    body_parts.append("")
    body_parts.append("**Action required**: re-run from local Claude Code session for LLM judgment, or resolve manually.")
    body_parts.append("")
    body_parts.append("```bash")
    body_parts.append("git fetch origin")
    body_parts.append(f"git checkout {branch}")
    body_parts.append("git rebase origin/main  # triggers conflict_resolver.py analyze")
    body_parts.append("```")

    url = _create_issue(title, "\n".join(body_parts))

    if pr_number:
        _run(["gh", "pr", "edit", str(pr_number), "--remove-label", "auto-merge"])
        _run(["gh", "pr", "comment", str(pr_number), "--body",
              f"❌ v7.5 CI rebase conflict. Audit issue: {url or '(creation failed)'}"])

    _append_registry({
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
        "branch": branch,
        "conflict_count": len(request["conflicts"]),
        "decision_summary": "CI-DEFERRED",
        "issue_url": url or "-",
        "request_id": request["request_id"],
    })

    print(f"[ci-only] issue: {url}")
    return 1  # non-zero so workflow knows it didn't auto-resolve


def cmd_self_test(args: argparse.Namespace) -> int:
    """인공 시나리오로 hunk 추출 + SSOT lookup 검증 (no Git mutation)."""
    sample = """before
<<<<<<< HEAD
ours line A
ours line B
=======
theirs line A
>>>>>>> origin/main
after
"""
    tmp = REPO / ".self_test_conflict.tmp"
    try:
        tmp.write_text(sample, encoding="utf-8")
        hunks = _extract_hunks(".self_test_conflict.tmp")
        assert len(hunks) == 1, f"expected 1 hunk, got {len(hunks)}"
        assert "ours line A" in hunks[0]["ours"]
        assert "theirs line A" in hunks[0]["theirs"]
        print(f"[ok] hunk extraction: {hunks[0]['line_start']}-{hunks[0]['line_end']}")

        policy = _load_policy()
        ssot = _ssot_for_path("docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md", policy)
        assert ssot["publisher"] == "team2", f"expected team2, got {ssot}"
        print(f"[ok] SSOT lookup: contract={ssot['contract_path']}, publisher={ssot['publisher']}")

        ssot2 = _ssot_for_path("team1-frontend/lib/foo.dart", policy)
        assert ssot2["publisher"] == "team1", f"expected team1, got {ssot2}"
        print(f"[ok] team-owns lookup: publisher={ssot2['publisher']}")

        print("[ok] self-test passed")
        return 0
    finally:
        tmp.unlink(missing_ok=True)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)

    p_an = sub.add_parser("analyze", help="conflict 감지 + decision request JSON 출력")
    p_an.add_argument("--print-request", action="store_true", help="JSON 도 stdout 으로 출력")
    p_an.set_defaults(func=cmd_analyze)

    p_ap = sub.add_parser("apply", help="decision JSON 적용 + 검증 + rebase --continue")
    p_ap.add_argument("--decision-file", default="", help=f"기본: {DECISION_FILE.name}")
    p_ap.add_argument("--skip-verify", action="store_true", help="lint/syntax 검증 생략")
    p_ap.add_argument("--no-issue", action="store_true", help="audit issue 생성 생략")
    p_ap.add_argument("--no-escalation", action="store_true", help="abort 시 exit 4 → 0 변경")
    p_ap.set_defaults(func=cmd_apply)

    p_ci = sub.add_parser("ci-only", help="workflow 환경. issue 등록 + label 제거")
    p_ci.add_argument("--pr-number", default="", help="PR 번호 (없으면 PR_NUMBER env)")
    p_ci.set_defaults(func=cmd_ci_only)

    p_st = sub.add_parser("self-test", help="hunk 추출 + SSOT lookup 단위 테스트")
    p_st.set_defaults(func=cmd_self_test)

    args = ap.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
