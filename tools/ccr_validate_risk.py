#!/usr/bin/env python3
"""CCR Draft 리스크 등급 자동 분류 도구.

Usage:
    python tools/ccr_validate_risk.py --draft CCR-DRAFT-team2-20260412-add-field.md
    python tools/ccr_validate_risk.py --all
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

# ccr_promote.py 에서 공용 상수/함수 import
sys.path.insert(0, str(Path(__file__).resolve().parent))
from ccr_promote import (  # noqa: E402
    parse_draft, INBOX, PROJECT, DraftError,
    BREAKING_KEYWORDS, classify_risk, _extract_diff_section,
)

# v5: docs/2. Development/2.5 Shared/team-policy.json (신규 SSOT)
# v4 fallback: contracts/team-policy.json
import os as _os
_V5_POLICY = PROJECT / "docs" / "2. Development" / "2.5 Shared" / "team-policy.json"
_V4_POLICY = PROJECT / "contracts" / "team-policy.json"
if _os.environ.get("EBS_SCOPE_GUARD_VERSION", "v5").lower() == "v4":
    TEAM_POLICY = _V4_POLICY
else:
    TEAM_POLICY = _V5_POLICY if _V5_POLICY.exists() else _V4_POLICY


def load_team_policy() -> dict:
    """team-policy.json 로드."""
    if not TEAM_POLICY.exists():
        return {}
    return json.loads(TEAM_POLICY.read_text(encoding="utf-8"))


def extract_diff_section(body: str) -> str | None:
    """draft body에서 ## Diff 초안 ~ 다음 ## 사이 텍스트 추출."""
    m = re.search(
        r"^##\s+Diff\s+초안\s*\n(.*?)(?=\n##\s|\Z)",
        body,
        re.MULTILINE | re.DOTALL,
    )
    if not m:
        return None
    return m.group(1)


def count_diff_lines(diff_text: str) -> dict[str, int]:
    """diff 코드 블록 내 +/- 라인 카운트.

    ```diff ... ``` 블록을 모두 찾아서 집계.
    --- / +++ 헤더 라인은 제외.
    """
    added = 0
    deleted = 0
    # 코드 블록 추출
    blocks = re.findall(r"```diff\s*\n(.*?)```", diff_text, re.DOTALL)
    if not blocks:
        # 코드 블록 없이 직접 diff 라인이 있을 수도 있음
        blocks = [diff_text]

    for block in blocks:
        for line in block.splitlines():
            stripped = line.rstrip()
            if stripped.startswith("---") or stripped.startswith("+++"):
                continue
            if stripped.startswith("+"):
                added += 1
            elif stripped.startswith("-"):
                deleted += 1

    return {"added": added, "deleted": deleted}


def find_breaking_keywords(body: str) -> list[str]:
    """본문에서 breaking 키워드 탐지."""
    found = []
    lower = body.lower()
    for kw in BREAKING_KEYWORDS:
        if kw.lower() in lower:
            found.append(kw)
    return found


def check_publisher_eligible(
    target_files: list[str], proposing_team: str, policy: dict
) -> bool:
    """제안팀이 target_files의 publisher인지 확인.

    team-policy.json의 api_publishes와 target_files의 API 매칭으로 판단.
    """
    teams = policy.get("teams", {})
    team_info = teams.get(proposing_team, {})
    publishes = set(team_info.get("api_publishes", []))
    if not publishes:
        return False

    # target_files에서 API-NN 추출
    for tf in target_files:
        m = re.search(r"API-(\d+)", tf)
        if m:
            api_id = f"API-{m.group(1).lstrip('0') or '0'}"
            # 정규화: API-01 → API-1? 아니, policy에는 API-01 형식
            api_id_padded = f"API-{int(m.group(1)):02d}"
            if api_id_padded not in publishes and api_id not in publishes:
                return False
        # contracts/specs/ 는 publisher 개념이 없으므로 무시
    return bool(publishes)


def assess_risk(draft_data: dict, policy: dict) -> dict:
    """단일 draft의 리스크 등급 판정."""
    change_type = draft_data["change_type"].lower()
    impacted = draft_data["impacted"]
    target_files = draft_data["target_files"]
    body = draft_data["body"]

    reasons = []
    risk_level = "LOW"

    # 1. change_type에 remove/rename 포함
    if "remove" in change_type or "rename" in change_type:
        risk_level = "HIGH"
        reasons.append(f"change_type contains '{change_type}'")

    # 2. Diff 초안에서 삭제 라인 카운트
    diff_section = extract_diff_section(body)
    diff_stats = {"added": 0, "deleted": 0}
    if diff_section:
        diff_stats = count_diff_lines(diff_section)
        if diff_stats["deleted"] > 0 and risk_level != "HIGH":
            risk_level = "HIGH"
            reasons.append(
                f"diff has {diff_stats['deleted']} deleted line(s)"
            )

    # 3. 영향팀 수 >= 3
    if len(impacted) >= 3:
        if risk_level != "HIGH":
            risk_level = "HIGH"
        reasons.append(f"affects {len(impacted)} teams")

    # 4. breaking 키워드
    breaking = find_breaking_keywords(body)
    if breaking:
        if risk_level != "HIGH":
            risk_level = "HIGH"
        reasons.append(f"breaking keywords: {breaking}")

    # 5. change_type에 modify 포함 (MEDIUM 이상으로)
    if "modify" in change_type and risk_level == "LOW":
        risk_level = "MEDIUM"
        reasons.append("change_type contains 'modify'")

    # 6. 영향팀 수 == 2
    if len(impacted) == 2 and risk_level == "LOW":
        risk_level = "MEDIUM"
        reasons.append(f"affects {len(impacted)} teams")

    # 이유 없으면 기본 이유
    if not reasons:
        reasons.append(
            f"additive only: {diff_stats['added']} added, "
            f"0 modified, {diff_stats['deleted']} deleted lines in diff"
        )

    # publisher 검증
    publisher_eligible = check_publisher_eligible(
        target_files, draft_data["proposing"], policy
    )

    # auto_approve 판정: LOW만 가능
    auto_approve = risk_level == "LOW"

    return {
        "draft": Path(draft_data.get("_path", "")).name
        if "_path" in draft_data
        else "unknown",
        "risk_level": risk_level,
        "reason": "; ".join(reasons),
        "change_type": draft_data["change_type"],
        "affected_teams": impacted,
        "affected_team_count": len(impacted),
        "diff_stats": diff_stats,
        "breaking_keywords": breaking if breaking else [],
        "auto_approve_eligible": auto_approve,
        "publisher_direct_eligible": publisher_eligible,
    }


def cmd_single(draft_name: str) -> int:
    """단일 draft 리스크 판정."""
    draft_path = INBOX / draft_name
    if not draft_path.exists():
        print(
            f"ERROR: draft 없음: {draft_path}",
            file=sys.stderr,
        )
        return 1

    try:
        data = parse_draft(draft_path)
    except DraftError as e:
        print(f"ERROR: parse 실패: {e}", file=sys.stderr)
        return 1

    data["_path"] = str(draft_path)
    policy = load_team_policy()
    result = assess_risk(data, policy)
    result["draft"] = draft_name
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


def cmd_all() -> int:
    """inbox의 모든 draft 일괄 리스크 분류."""
    if not INBOX.exists():
        print(
            json.dumps({"error": f"inbox 없음: {INBOX}"}, ensure_ascii=False)
        )
        return 1

    drafts = sorted(INBOX.glob("CCR-DRAFT-*.md"))
    if not drafts:
        print(json.dumps([], ensure_ascii=False))
        return 0

    policy = load_team_policy()
    results = []

    for draft_path in drafts:
        try:
            data = parse_draft(draft_path)
            data["_path"] = str(draft_path)
            result = assess_risk(data, policy)
            result["draft"] = draft_path.name
            results.append(result)
        except DraftError as e:
            results.append({
                "draft": draft_path.name,
                "risk_level": "UNKNOWN",
                "reason": f"parse error: {e}",
                "change_type": None,
                "affected_teams": [],
                "affected_team_count": 0,
                "diff_stats": {"added": 0, "deleted": 0},
                "breaking_keywords": [],
                "auto_approve_eligible": False,
                "publisher_direct_eligible": False,
            })

    print(json.dumps(results, ensure_ascii=False, indent=2))
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="CCR Draft 리스크 등급 자동 분류 도구",
    )
    parser.add_argument(
        "--draft",
        metavar="FILENAME",
        help="단일 draft 파일명 (inbox/ 기준)",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="inbox의 모든 draft 일괄 분류",
    )
    args = parser.parse_args()

    if args.draft:
        return cmd_single(args.draft)
    if args.all:
        return cmd_all()

    parser.print_help(sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
