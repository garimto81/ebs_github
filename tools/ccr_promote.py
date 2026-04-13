#!/usr/bin/env python3
"""CCR Inbox Promoter — Draft 메타 검증/마감 전용 결정적 연산 도구.

역할 (v3 배치 모드 이후):
1. `--validate-only`: inbox 스캔 → 각 draft 파싱·검증 → JSON 출력 (번호 후보 포함)
2. `--complete <draft> --number <N> --applied-files <csv> [--skipped]`:
   한 draft의 마감 처리 (log 파일 생성, NOTIFY append, archive 이동)

참고: v3 워크플로우에서 LLM은 전체 draft를 먼저 **일괄 Read → target_files
교집합 기준 그룹핑/배치 플랜 → 그룹별 1회 통합 Edit → 각 draft별 --complete
마감** 순으로 수행한다. 이 스크립트의 CLI 계약은 v2와 동일하다 — 변경 없이
배치 모드에서 그대로 재사용된다. 상세 절차는 CLAUDE.md §계약 관리 및
docs/05-plans/ccr-inbox/README.md §Conductor 작업 (v3) 참조.

**중요**: 실제 `contracts/` 파일 편집은 Conductor LLM이 Claude Code 세션에서
직접 수행한다. 이 스크립트는 결정적 작업(파싱·번호 할당·파일 이동)만 담당한다.
"작업 실행" = 실제 contracts/ 문서 수정이며, --complete 호출은 편집이 끝난
draft를 마감하는 후속 절차일 뿐이다. 편집 없이 마감만 호출하는 것은 금지
(의도적 skip은 반드시 --skipped 플래그 사용).

기존 전체 파이프라인 진입점(인자 없음)은 deprecation 경고 후 새 워크플로우를
안내하고 종료한다.

사용 예:
    python tools/ccr_promote.py --validate-only
    python tools/ccr_promote.py --complete CCR-DRAFT-team2-20260410-jwt-expiry.md \
        --number 6 --applied-files "contracts/specs/BS-01-auth/BS-01-auth.md,contracts/api/API-06-auth-session.md"
    python tools/ccr_promote.py --complete CCR-DRAFT-... --number 7 --skipped
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent
INBOX = PROJECT / "docs" / "05-plans" / "ccr-inbox"
ARCHIVED = INBOX / "archived"
# 승격 로그 저장 폴더 (ccr-inbox 내부).
PROMOTING = INBOX / "promoting"
BACKLOG_DIR = PROJECT / "docs" / "backlog"

VALID_TEAMS = {"team1", "team2", "team3", "team4", "conductor"}
VALID_CHANGE_TYPES = {"add", "modify", "remove", "rename"}


class DraftError(Exception):
    pass


# ============================================================
# 리스크 등급 분류
# ============================================================

BREAKING_KEYWORDS = [
    "breaking", "삭제", "deprecated", "구조 변경",
    "마이그레이션 필수", "migration required", "schema change",
]


def _extract_diff_section(body: str) -> str:
    """본문에서 ## Diff 초안 섹션의 코드 블록 내용 추출."""
    m = re.search(r"## Diff 초안.*?```(?:diff)?\n(.*?)```", body, re.DOTALL)
    return m.group(1) if m else ""


def classify_risk(change_type: str, impacted: list[str], body: str) -> str:
    """CCR 리스크 등급 분류: LOW / MEDIUM / HIGH."""
    change_tokens = set(change_type.lower().replace("+", " ").split())

    # HIGH 조건
    if change_tokens & {"remove", "rename"}:
        return "HIGH"
    if len(impacted) >= 3:
        return "HIGH"
    body_lower = body.lower()
    if any(kw in body_lower for kw in BREAKING_KEYWORDS):
        return "HIGH"

    # Diff 초안에서 삭제 라인 확인
    diff_section = _extract_diff_section(body)
    if diff_section:
        del_count = sum(1 for line in diff_section.splitlines()
                       if line.startswith("-") and not line.startswith("---"))
        if del_count > 0:
            return "HIGH"

    # MEDIUM 조건
    if "modify" in change_tokens:
        return "MEDIUM"
    if len(impacted) >= 2:
        return "MEDIUM"

    return "LOW"


# ============================================================
# Draft 파싱/검증
# ============================================================

def parse_draft(path: Path) -> dict:
    """필수 필드 파싱. 누락/형식 오류 시 DraftError.

    지원 포맷:
      - **key**: value                    (단일 라인)
      - **key**: a, b, c                  (콤마 구분 다중 값)
      - **key**:                          (빈 값 → 다음 줄들의 들여쓴 bullet 수집)
          - `path/a.md`
          - `path/b.md` (신규)
    """
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    fields: dict[str, str] = {}

    i = 0
    while i < len(lines):
        line = lines[i]
        m = re.match(r"^\s*-\s*\*\*([^*]+)\*\*\s*:\s*(.*)$", line)
        if m:
            key = m.group(1).strip()
            val = m.group(2).strip()
            # 같은 줄에 값이 없으면 다음 줄들의 들여쓴 bullet을 서브아이템으로 수집
            if not val:
                sub_items: list[str] = []
                j = i + 1
                while j < len(lines):
                    next_line = lines[j]
                    sub_m = re.match(r"^\s+[-*]\s+(.+)$", next_line)
                    if sub_m:
                        item = sub_m.group(1).strip()
                        # backtick 제거 (`path.md` → path.md)
                        item = re.sub(r"`([^`]+)`", r"\1", item)
                        # 뒤쪽 괄호 주석 제거 (" (신규)", " (참조 보강)" 등)
                        item = re.sub(r"\s*\([^)]*\)\s*$", "", item).strip()
                        if item:
                            sub_items.append(item)
                        j += 1
                    elif next_line.strip() == "":
                        break
                    else:
                        break
                if sub_items:
                    val = ", ".join(sub_items)
                    i = j - 1
            fields[key] = val
        i += 1

    # 제목
    title_m = re.search(r"^#\s+CCR-DRAFT:\s*(.+)$", text, re.MULTILINE)
    if not title_m:
        raise DraftError("제목 '# CCR-DRAFT: ...' 누락")
    title = title_m.group(1).strip()

    # 필수 필드 검증
    required = ["제안팀", "제안일", "영향팀", "변경 대상 파일", "변경 유형", "변경 근거"]
    for key in required:
        if key not in fields or not fields[key]:
            raise DraftError(f"필수 필드 누락: {key}")

    # 제안팀 형식
    proposing = fields["제안팀"]
    if proposing not in VALID_TEAMS:
        raise DraftError(
            f"제안팀 형식 오류: '{proposing}' ({'/'.join(sorted(VALID_TEAMS))} 중 하나)"
        )

    # 파일명 prefix와 제안팀 일치 확인
    expected_prefix = f"CCR-DRAFT-{proposing}-"
    if not path.name.startswith(expected_prefix):
        raise DraftError(
            f"파일명 prefix 불일치: {path.name} (제안팀={proposing}이면 {expected_prefix}로 시작)"
        )

    # 제안일 형식
    if not re.match(r"\d{4}-\d{2}-\d{2}$", fields["제안일"]):
        raise DraftError(f"제안일 형식 오류: '{fields['제안일']}' (YYYY-MM-DD)")

    # 영향팀 파싱 (빈 배열 금지)
    impact_raw = fields["영향팀"].strip()
    m = re.match(r"^\[([^\]]*)\]$", impact_raw)
    if not m:
        raise DraftError(f"영향팀 형식 오류: '{impact_raw}' ([teamN, ...] 형식)")
    impacted = [t.strip() for t in m.group(1).split(",") if t.strip()]
    if not impacted:
        raise DraftError("영향팀 빈 배열 금지 — 최소 1개 팀 기재 필수")
    invalid = [t for t in impacted if t not in VALID_TEAMS]
    if invalid:
        raise DraftError(f"영향팀에 알 수 없는 값: {invalid}")

    # 변경 대상 파일 (단일 또는 콤마 구분 다중)
    # 각 경로를 정규화: backtick 제거 + 뒤쪽 괄호 주석 제거 ("(add)", "(신규)" 등)
    target_raw = fields["변경 대상 파일"]
    target_files = []
    for token in target_raw.split(","):
        t = token.strip()
        if not t:
            continue
        t = re.sub(r"`([^`]+)`", r"\1", t)
        t = re.sub(r"\s*\([^)]*\)\s*$", "", t).strip()
        if t:
            target_files.append(t)
    if not target_files:
        raise DraftError("변경 대상 파일 비어있음")
    non_contracts = [t for t in target_files if not t.startswith("contracts/")]
    if non_contracts:
        raise DraftError(
            f"변경 대상 파일은 contracts/ 하위여야 함: {non_contracts}"
        )
    target = ", ".join(target_files)

    # 변경 유형 (단일 또는 조합: "add", "add + modify", "add, modify" 등 허용)
    change_raw = fields["변경 유형"]
    change_tokens = [t for t in re.split(r"[\s,+|/]+", change_raw.strip()) if t]
    invalid_change = [t for t in change_tokens if t not in VALID_CHANGE_TYPES]
    if not change_tokens or invalid_change:
        raise DraftError(
            f"변경 유형 오류: '{change_raw}' ({'/'.join(sorted(VALID_CHANGE_TYPES))} 중 하나 또는 조합)"
        )
    change_type = " + ".join(change_tokens)

    # 리스크 등급 분류
    risk = classify_risk(change_type, impacted, text)

    return {
        "title": title,
        "proposing": proposing,
        "date": fields["제안일"],
        "impacted": impacted,
        "target_file": target,
        "target_files": target_files,
        "change_type": change_type,
        "rationale": fields["변경 근거"],
        "body": text,
        "risk_level": risk,
    }


# ============================================================
# 번호 할당 / slug
# ============================================================

def next_ccr_number() -> int:
    """promoting/ 하위의 기존 log 파일을 스캔하여 다음 번호 반환."""
    if not PROMOTING.exists():
        return 1
    existing = list(PROMOTING.glob("CCR-[0-9][0-9][0-9]-*.md"))
    nums = []
    for p in existing:
        m = re.match(r"CCR-(\d{3})-", p.name)
        if m:
            nums.append(int(m.group(1)))
    return (max(nums) + 1) if nums else 1


def slugify(title: str) -> str:
    """title을 영문 kebab-case slug으로 변환. 한글은 제거된다."""
    s = title.lower()
    s = re.sub(r"[^a-z0-9\s-]", "", s)
    s = re.sub(r"\s+", "-", s).strip("-")
    return s[:50] if s else "untitled"


def extract_slug_from_filename(draft_name: str) -> str | None:
    """Draft 파일명에서 slug 추출.

    형식: CCR-DRAFT-{team}-{YYYYMMDD}[-{slug}].md
    slug 부분이 존재하면 반환, 없으면 None.
    """
    m = re.match(
        r"^CCR-DRAFT-[a-z0-9]+-\d{8}(?:-(?P<slug>[a-z0-9][a-z0-9-]*))?\.md$",
        draft_name,
    )
    if not m:
        return None
    return m.group("slug")


# ============================================================
# 로그 파일 렌더링
# ============================================================

def render_ccr_log(
    draft: dict,
    number: int,
    applied_files: list[str],
    skipped: bool,
    archived_draft_name: str,
    risk_level: str | None = None,
) -> str:
    """간결한 로그 파일. 원본 draft body 임베드 없음.

    skipped=True : 이미 contracts/에 반영되어 있어 적용을 건너뛴 경우.
    """
    nnn = f"{number:03d}"
    if skipped:
        status = f"SKIPPED (already applied; reprocessed {datetime.now():%Y-%m-%d})"
    else:
        status = f"APPLIED ({datetime.now():%Y-%m-%d})"

    target_files = draft.get("target_files") or [draft["target_file"]]
    if len(target_files) == 1:
        target_cell = f"`{target_files[0]}`"
    else:
        target_cell = "<br/>".join(f"`{f}`" for f in target_files)

    if applied_files:
        applied_section = "\n".join(f"- `{f}`" for f in applied_files)
    elif skipped:
        applied_section = "_(없음 — 이전 세션에서 이미 반영됨)_"
    else:
        applied_section = "_(없음)_"

    edit_checkbox = "x" if (applied_files or skipped) else " "

    return (
        f"# CCR-{nnn}: {draft['title']}\n"
        f"\n"
        f"| 필드 | 값 |\n"
        f"|------|-----|\n"
        f"| **상태** | {status} |\n"
        f"| **제안팀** | {draft['proposing']} |\n"
        f"| **제안일** | {draft['date']} |\n"
        f"| **처리일** | {datetime.now():%Y-%m-%d} |\n"
        f"| **영향팀** | {', '.join(draft['impacted'])} |\n"
        f"| **변경 대상** | {target_cell} |\n"
        f"| **변경 유형** | {draft['change_type']} |\n"
        f"| **리스크 등급** | {risk_level or 'N/A'} |\n"
        f"\n"
        f"## 변경 근거\n"
        f"\n"
        f"{draft['rationale']}\n"
        f"\n"
        f"## 적용된 파일\n"
        f"\n"
        f"{applied_section}\n"
        f"\n"
        f"## 원본 Draft\n"
        f"\n"
        f"`docs/05-plans/ccr-inbox/archived/{archived_draft_name}` 참조\n"
        f"\n"
        f"## 체크리스트\n"
        f"\n"
        f"- [{edit_checkbox}] contracts/ 편집 완료\n"
        f"- [ ] 영향팀({', '.join(draft['impacted'])}) 개별 확인\n"
        f"- [ ] 통합 테스트 업데이트 (`integration-tests/`)\n"
        f"- [ ] git commit `[CCR-{nnn}] {draft['title']}`\n"
    )


# ============================================================
# Backlog NOTIFY (중복 방지)
# ============================================================

def notification_exists(team: str, ccr_number: int) -> bool:
    """backlog 파일에 `[NOTIFY-CCR-NNN]` 항목이 이미 존재하는지 확인."""
    target = BACKLOG_DIR / f"{team}.md"
    if not target.exists():
        return False
    nnn = f"{ccr_number:03d}"
    text = target.read_text(encoding="utf-8")
    return f"[NOTIFY-CCR-{nnn}]" in text


def append_notification(team: str, ccr_number: int, draft: dict) -> str:
    """영향팀 backlog에 NOTIFY 항목 append. 이미 존재하면 skip.

    Returns: 'added' / 'skipped (exists)' / 'no target file'
    """
    target = BACKLOG_DIR / f"{team}.md"
    if not target.exists():
        return "no target file"
    if notification_exists(team, ccr_number):
        return "skipped (exists)"

    nnn = f"{ccr_number:03d}"
    entry = (
        f"\n\n### [NOTIFY-CCR-{nnn}] 검토 요청: {draft['title']}\n"
        f"- **알림일**: {datetime.now():%Y-%m-%d}\n"
        f"- **CCR**: `docs/05-plans/ccr-inbox/promoting/CCR-{nnn}-*.md`\n"
        f"- **제안팀**: {draft['proposing']}\n"
        f"- **변경 대상**: `{draft['target_file']}`\n"
        f"- **조치**: 영향 범위 검토 후 승인 또는 이의 제기\n"
    )
    text = target.read_text(encoding="utf-8")
    if "## PENDING" in text:
        m = re.search(r"(## PENDING\n)(.*?)(\n## |\Z)", text, re.DOTALL)
        if m:
            before = text[: m.end(2)]
            after = text[m.end(2):]
            target.write_text(before + entry + after, encoding="utf-8")
            return "added"
    target.write_text(text.rstrip() + entry, encoding="utf-8")
    return "added"


# ============================================================
# 서브커맨드
# ============================================================

def cmd_validate_only() -> int:
    """inbox 전체 스캔 → JSON 출력."""
    if not INBOX.exists():
        print(json.dumps({"error": f"inbox 없음: {INBOX}"}, ensure_ascii=False))
        return 1

    drafts = sorted(INBOX.glob("CCR-DRAFT-*.md"))
    base_number = next_ccr_number()
    results = []
    valid_count = 0

    for draft_path in drafts:
        try:
            draft = parse_draft(draft_path)
            results.append({
                "draft": draft_path.name,
                "number": base_number + valid_count,
                "valid": True,
                "title": draft["title"],
                "proposing": draft["proposing"],
                "impacted": draft["impacted"],
                "target_files": draft["target_files"],
                "change_type": draft["change_type"],
                "rationale": draft["rationale"],
                "risk_level": draft.get("risk_level", "HIGH"),
                "error": None,
            })
            valid_count += 1
        except DraftError as e:
            results.append({
                "draft": draft_path.name,
                "number": None,
                "valid": False,
                "title": None,
                "proposing": None,
                "impacted": None,
                "target_files": None,
                "change_type": None,
                "rationale": None,
                "error": str(e),
            })

    print(json.dumps({
        "inbox": str(INBOX.relative_to(PROJECT)),
        "total": len(drafts),
        "valid": valid_count,
        "invalid": len(drafts) - valid_count,
        "base_number": base_number,
        "drafts": results,
    }, ensure_ascii=False, indent=2))
    return 0 if valid_count == len(drafts) else 1


def cmd_complete(
    draft_name: str,
    number: int,
    applied_files: list[str],
    skipped: bool,
    risk_level: str | None = None,
) -> int:
    """한 draft의 마감 처리 (log 생성 + NOTIFY + archive 이동)."""
    inbox_path = INBOX / draft_name
    archived_path = ARCHIVED / draft_name

    if inbox_path.exists():
        draft_path = inbox_path
        need_move_to_archive = True
    elif archived_path.exists():
        draft_path = archived_path
        need_move_to_archive = False
    else:
        print(f"ERROR: draft 없음: {draft_name}", file=sys.stderr)
        print(f"  확인한 경로:", file=sys.stderr)
        print(f"    - {inbox_path}", file=sys.stderr)
        print(f"    - {archived_path}", file=sys.stderr)
        return 1

    try:
        draft = parse_draft(draft_path)
    except DraftError as e:
        print(f"ERROR: parse 실패: {e}", file=sys.stderr)
        return 1

    # 로그 파일 생성
    PROMOTING.mkdir(parents=True, exist_ok=True)
    slug = extract_slug_from_filename(draft_name) or slugify(draft["title"])
    log_name = f"CCR-{number:03d}-{slug}.md"
    log_path = PROMOTING / log_name
    log_content = render_ccr_log(
        draft=draft,
        number=number,
        applied_files=applied_files,
        skipped=skipped,
        archived_draft_name=draft_name,
        risk_level=risk_level or draft.get("risk_level"),
    )
    log_path.write_text(log_content, encoding="utf-8")
    print(f"log: {log_path.relative_to(PROJECT)}")

    # NOTIFY append (중복 방지)
    for team in draft["impacted"]:
        result = append_notification(team, number, draft)
        print(f"  notify {team}: {result}")

    # archive 이동
    if need_move_to_archive:
        ARCHIVED.mkdir(parents=True, exist_ok=True)
        draft_path.rename(archived_path)
        print(f"archived: {archived_path.relative_to(PROJECT)}")
    else:
        print(f"archive: already in archived/ (no-op)")

    return 0


def cmd_legacy_main() -> int:
    """기존 전체 파이프라인 진입점 — deprecated."""
    print("=" * 68, file=sys.stderr)
    print("DEPRECATION WARNING — ccr_promote.py 전체 파이프라인 모드", file=sys.stderr)
    print("=" * 68, file=sys.stderr)
    print(
        "\n이 진입점(인자 없음)은 더 이상 사용되지 않습니다.\n"
        "\n"
        "기존 동작은 메타데이터 승격본만 생성하고 실제 `contracts/` 파일을\n"
        "수정하지 않았습니다. 이는 'ccr promote'의 의도와 다릅니다.\n"
        "\n"
        "새 워크플로우:\n"
        "  Claude Code 세션에서 'ccr promote' 라고 입력하면 Conductor LLM이\n"
        "  CLAUDE.md §계약 관리의 절차를 따라 직접 contracts/를 편집합니다.\n"
        "\n"
        "이 스크립트는 LLM 워크플로우에서 결정적 연산용으로만 호출됩니다:\n"
        "  python tools/ccr_promote.py --validate-only\n"
        "  python tools/ccr_promote.py --complete <draft-filename> \\\n"
        "      --number <NNN> --applied-files <csv>\n"
        "  python tools/ccr_promote.py --complete <draft-filename> \\\n"
        "      --number <NNN> --skipped\n"
        "\n"
        "상세: docs/05-plans/ccr-inbox/README.md\n",
        file=sys.stderr,
    )
    return 2


def main() -> int:
    parser = argparse.ArgumentParser(
        description="CCR Inbox 검증/마감 도구 (contracts/ 편집은 Claude LLM이 수행)",
    )
    parser.add_argument(
        "--validate-only",
        action="store_true",
        help="inbox 전체 검증 후 JSON 출력. 파일 변경 없음.",
    )
    parser.add_argument(
        "--complete",
        metavar="DRAFT_FILENAME",
        help="단일 draft 마감 처리 (log 생성 + NOTIFY + archive 이동)",
    )
    parser.add_argument(
        "--number",
        type=int,
        help="--complete와 함께 사용. 할당할 CCR 번호",
    )
    parser.add_argument(
        "--applied-files",
        default="",
        help="--complete와 함께 사용. 적용된 파일 경로 (콤마 구분)",
    )
    parser.add_argument(
        "--skipped",
        action="store_true",
        help="--complete와 함께 사용. 이미 반영되어 있어 편집을 건너뜀",
    )
    parser.add_argument(
        "--risk-level",
        choices=["LOW", "MEDIUM", "HIGH"],
        default=None,
        help="--complete와 함께 사용. CCR 리스크 등급 (로그 기록용)",
    )
    args = parser.parse_args()

    if args.validate_only:
        return cmd_validate_only()
    if args.complete:
        if args.number is None:
            print("ERROR: --complete 사용 시 --number 필수", file=sys.stderr)
            return 1
        applied = [f.strip() for f in args.applied_files.split(",") if f.strip()]
        return cmd_complete(args.complete, args.number, applied, args.skipped, args.risk_level)

    return cmd_legacy_main()


if __name__ == "__main__":
    sys.exit(main())
