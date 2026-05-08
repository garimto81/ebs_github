#!/usr/bin/env python3
"""Phase 5 통합 사전 점검 스크립트.

Track A 8 audit PR 머지 + Track B Phase 4 완료 + feat/message-bus 동기화
+ Phase 5 PR ready 모두 확인. 모든 조건 만족 시 "PHASE 5 READY" 출력.

Usage:
  python tools/orchestrator/check_phase5_trigger.py
  python tools/orchestrator/check_phase5_trigger.py --json   # 기계 판독
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

# 8 audit stream IDs (Plan §0.4)
AUDIT_STREAMS = ["S1", "S2", "S3", "S4", "S5", "S6", "S7", "S8"]

# Phase 4 completion marker — feat/message-bus 의 commit 또는 그 이후
PHASE_4_MARKER_FILE = "docs/4. Operations/Message_Bus_Runbook.md"
PHASE_5_PREP_MARKER_FILE = ".claude/hooks/orch_SessionStart.py"
PHASE_5_PREP_MARKER_FUNC = "ensure_message_bus"


def run_gh(args: list[str]) -> tuple[int, str, str]:
    proc = subprocess.run(
        ["gh"] + args, capture_output=True, text=True, timeout=30
    )
    return proc.returncode, proc.stdout, proc.stderr


def check_audit_merged() -> dict:
    """Track A: 8 audit PR 머지 확인."""
    result = {"merged": [], "open": [], "missing": []}
    for sid in AUDIT_STREAMS:
        rc, out, _ = run_gh([
            "pr", "list",
            "--label", f"stream:{sid}",
            "--label", "consistency-audit",
            "--state", "all", "--limit", "5",
            "--json", "number,state",
        ])
        if rc != 0:
            result["missing"].append(sid)
            continue
        prs = json.loads(out or "[]")
        merged = [p for p in prs if p.get("state") == "MERGED"]
        if merged:
            result["merged"].append((sid, merged[0]["number"]))
        elif prs:
            result["open"].append((sid, prs[0]["number"], prs[0]["state"]))
        else:
            result["missing"].append(sid)
    return result


def check_track_b_phase4() -> dict:
    """Track B: Phase 4 완료 확인 (origin/feat/message-bus 브랜치, git 직접 query)."""
    project_root = Path(__file__).resolve().parents[2]
    branch = "origin/feat/message-bus"

    # Ensure we have latest origin refs
    subprocess.run(
        ["git", "-C", str(project_root), "fetch", "origin", "feat/message-bus"],
        capture_output=True, timeout=15,
    )

    # Check Runbook exists on branch
    rc1 = subprocess.run(
        ["git", "-C", str(project_root), "cat-file", "-e",
         f"{branch}:{PHASE_4_MARKER_FILE}"],
        capture_output=True, timeout=5,
    ).returncode
    runbook_exists = rc1 == 0

    # Check hook patch (look for ensure_message_bus function)
    proc = subprocess.run(
        ["git", "-C", str(project_root), "show",
         f"{branch}:{PHASE_5_PREP_MARKER_FILE}"],
        capture_output=True, text=True, timeout=5,
    )
    prep_present = (
        proc.returncode == 0 and PHASE_5_PREP_MARKER_FUNC in proc.stdout
    )

    return {
        "runbook_present": runbook_exists,
        "phase5_prep_present": prep_present,
        "phase4_complete": runbook_exists and prep_present,
    }


def check_phase5_pr() -> dict:
    """Phase 5 통합 PR (feat/message-bus → main) 존재/상태."""
    rc, out, _ = run_gh([
        "pr", "list",
        "--head", "feat/message-bus", "--base", "main",
        "--state", "all", "--limit", "5",
        "--json", "number,state,isDraft,title",
    ])
    if rc != 0:
        return {"present": False, "error": "gh failed"}
    prs = json.loads(out or "[]")
    if not prs:
        return {"present": False}
    pr = prs[0]
    return {
        "present": True,
        "number": pr["number"],
        "state": pr["state"],
        "is_draft": pr.get("isDraft", False),
        "title": pr["title"],
    }


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--json", action="store_true")
    args = p.parse_args()

    result = {
        "track_a": check_audit_merged(),
        "track_b": check_track_b_phase4(),
        "phase5_pr": check_phase5_pr(),
    }

    track_a_ok = (
        len(result["track_a"]["merged"]) == 8
        and not result["track_a"]["missing"]
    )
    track_b_ok = result["track_b"]["phase4_complete"]
    pr_ok = result["phase5_pr"].get("present", False)

    all_ok = track_a_ok and track_b_ok and pr_ok
    result["all_ok"] = all_ok
    result["next_action"] = (
        "PHASE 5 READY — mark draft as ready: gh pr ready " + str(result["phase5_pr"].get("number", "?"))
        if all_ok
        else "Wait for Track A completion + sync"
    )

    if args.json:
        print(json.dumps(result, indent=2))
        return 0 if all_ok else 1

    # Human-readable output
    print("=" * 70)
    print("Phase 5 통합 trigger 사전 점검")
    print("=" * 70)
    print()
    print(f"[Track A] 8 audit PR 머지 상태:")
    print(f"  merged ({len(result['track_a']['merged'])}/8):")
    for sid, num in result["track_a"]["merged"]:
        print(f"    ✓ {sid}  PR #{num}")
    if result["track_a"]["open"]:
        print(f"  open ({len(result['track_a']['open'])}/8):")
        for sid, num, state in result["track_a"]["open"]:
            print(f"    🔄 {sid}  PR #{num}  [{state}]")
    if result["track_a"]["missing"]:
        print(f"  missing ({len(result['track_a']['missing'])}/8):")
        for sid in result["track_a"]["missing"]:
            print(f"    ⏳ {sid}  (PR 미생성)")
    print()
    print(f"[Track B] Phase 4 완료 + Phase 5 prep:")
    print(f"  runbook 존재:      {'✓' if result['track_b']['runbook_present'] else '✗'}")
    print(f"  hook 패치 존재:    {'✓' if result['track_b']['phase5_prep_present'] else '✗'}")
    print(f"  Phase 4 완료:      {'✓' if track_b_ok else '✗'}")
    print()
    print(f"[Phase 5 PR]")
    if result["phase5_pr"].get("present"):
        pr = result["phase5_pr"]
        print(f"  존재:  ✓ PR #{pr['number']}  [{pr['state']}{' DRAFT' if pr['is_draft'] else ''}]")
        print(f"  title: {pr['title']}")
    else:
        print(f"  존재:  ✗ (PR 미생성)")
    print()
    print("=" * 70)
    if all_ok:
        print(f"  ✅ PHASE 5 READY")
        print(f"  머지 명령:")
        print(f"    gh pr ready {result['phase5_pr']['number']}")
        print(f"    gh pr merge {result['phase5_pr']['number']} --squash")
    else:
        wait_for = []
        if not track_a_ok:
            missing = result["track_a"]["missing"]
            opn = [sid for sid, _, _ in result["track_a"]["open"]]
            wait_for.append(f"Track A: {missing + opn}")
        if not track_b_ok:
            wait_for.append("Track B: Phase 4 commit/push")
        if not pr_ok:
            wait_for.append("Phase 5 PR: 생성 필요 (gh pr create)")
        print(f"  ⏳ 대기 중: {', '.join(wait_for)}")
    print("=" * 70)

    return 0 if all_ok else 1


if __name__ == "__main__":
    sys.exit(main())
