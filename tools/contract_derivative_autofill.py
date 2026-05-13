#!/usr/bin/env python3
"""
contract_derivative_autofill.py — Phase 3 자동화 도구

contract tier 파일에 경로 기반 derivative-of 자동 추가.
Operations 폴더에 잘못 태깅된 contract는 tier:operations 로 재분류.

매핑 룰 (Product_SSOT_Policy.md §8 인과관계 매핑 기반):
  2.2 Backend/APIs/*.md           → ../Back_Office/Overview.md (DEV-02)
  2.3 Game Engine/APIs/*.md       → ../Rules/Multi_Hand_v03.md (DEV-03)
  2.3 Game Engine/Behavioral/*.md → ../Rules/Multi_Hand_v03.md (DEV-03)
  2.3 Game Engine/Rules/*.md      → ./Multi_Hand_v03.md (또는 Equity_Calculator 이미 있음)
  2.4 Command Center/APIs/*.md    → ../Command_Center_UI/Overview.md (DEV-04)
  2.4 Command Center/Overlay/*.md → ../Command_Center_UI/Overview.md (DEV-04)
  2.5 Shared/Authentication/*.md  → ../../2.2 Backend/Back_Office/Overview.md (DEV-02)
  2.5 Shared/*.md (root)          → related-spec: [DEV-01, DEV-02, DEV-03, DEV-04]
  4. Operations/*.md (잘못 태깅)   → tier 재분류 (contract → operations)

사용:
  python tools/contract_derivative_autofill.py --dry-run
  python tools/contract_derivative_autofill.py --confirm

Exit: 0 OK / 1 변경 있음 / 2 오류
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

THIS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(THIS_DIR))
from ssot_verify import iter_docs, read_frontmatter, classify_file  # noqa: E402

DOCS_ROOT = (THIS_DIR.parent / "docs").resolve()


# 매핑 룰: (경로 substring, derivative-of value, comment)
MAPPING_RULES = [
    # 2.2 Backend APIs
    ("2.2 Backend/APIs/", "../Back_Office/Overview.md", "DEV-02"),
    # 2.3 Game Engine
    ("2.3 Game Engine/APIs/", "../Rules/Multi_Hand_v03.md", "DEV-03"),
    ("2.3 Game Engine/Behavioral_Specs/", "../Rules/Multi_Hand_v03.md", "DEV-03"),
    ("2.3 Game Engine/Rules/Engine_Defaults", "./Multi_Hand_v03.md", "DEV-03 sibling"),
    # 2.4 Command Center
    ("2.4 Command Center/APIs/", "../Command_Center_UI/Overview.md", "DEV-04"),
    ("2.4 Command Center/Overlay/", "../Command_Center_UI/Overview.md", "DEV-04"),
    # 2.5 Shared/Authentication → BO derivative (인증은 Backend 관할)
    ("2.5 Shared/Authentication/", "../../2.2 Backend/Back_Office/Overview.md", "DEV-02 (auth via BO)"),
]

# Shared root (cross-cutting) — related-spec 목록으로 처리
SHARED_ROOT_RELATED = [
    "../2.1 Frontend/Lobby/Overview.md",
    "../2.2 Backend/Back_Office/Overview.md",
    "../2.3 Game Engine/Rules/Multi_Hand_v03.md",
    "../2.4 Command Center/Command_Center_UI/Overview.md",
]

# Operations 폴더의 잘못 태깅된 contract → tier 재분류
OPERATIONS_RECLASSIFY_TIER = "operations"


def determine_action(md: Path) -> tuple[str, str]:
    """파일 경로 기반 행동 결정.
    return: (action, value)
       action: 'add-derivative' / 'add-related-spec' / 'reclassify-tier' / 'skip'
       value: derivative-of value OR related-spec list OR new tier
    """
    rel = str(md.relative_to(DOCS_ROOT)).replace("\\", "/")

    # Operations 폴더 → tier 재분류
    if rel.startswith("4. Operations/"):
        return ("reclassify-tier", OPERATIONS_RECLASSIFY_TIER)

    # Shared root (Authentication 하위 제외)
    if rel.startswith("2. Development/2.5 Shared/") and "/Authentication/" not in rel:
        # Shared 루트 파일 (Chip_Count_State, Naming_Conventions, Network_Config, Stream_Entry_Guide)
        # rel format: "2. Development/2.5 Shared/XXX.md" → slash count = 2
        if rel.count("/") == 2:
            return ("add-related-spec", ",".join(SHARED_ROOT_RELATED))

    # 매핑 룰 매칭
    for pattern, deriv_value, _ in MAPPING_RULES:
        if pattern in rel:
            return ("add-derivative", deriv_value)

    return ("skip", "")


# Frontmatter 수정 함수 (단순 line-based, 안전성 우선)

FRONTMATTER_BLOCK_RE = re.compile(
    r"^(---\s*\n)(.*?)(\n---\s*\n)", re.DOTALL
)


def inject_frontmatter_field(text: str, key: str, value: str) -> tuple[str, bool]:
    """frontmatter 에 key: value 라인 추가. 이미 있으면 skip.
    list value 는 inline list 로 추가 (related-spec: [a, b, c])."""
    m = FRONTMATTER_BLOCK_RE.match(text)
    if not m:
        # frontmatter 없음 — 신규 생성
        new_fm = f"---\n{key}: {value}\n---\n\n"
        return new_fm + text, True

    head, body, tail = m.group(1), m.group(2), m.group(3)
    # 이미 키가 있으면 skip
    if re.search(rf"^{re.escape(key)}\s*:", body, re.MULTILINE):
        return text, False

    # comma 포함이면 list (related-spec)
    if "," in value and key == "related-spec":
        items = [v.strip() for v in value.split(",")]
        # YAML inline list 형식
        new_body = body.rstrip() + f"\n{key}:\n" + "\n".join(f"  - {i}" for i in items)
    else:
        new_body = body.rstrip() + f"\n{key}: {value}"

    return head + new_body + tail + text[m.end():], True


def update_tier(text: str, new_tier: str) -> tuple[str, bool]:
    """frontmatter 의 tier 필드를 new_tier 로 변경."""
    m = FRONTMATTER_BLOCK_RE.match(text)
    if not m:
        return text, False
    head, body, tail = m.group(1), m.group(2), m.group(3)
    new_body, n = re.subn(
        r"^(tier\s*:\s*)\S+(.*)$",
        rf"\1{new_tier}\2",
        body,
        flags=re.MULTILINE,
    )
    if n == 0:
        return text, False
    return head + new_body + tail + text[m.end():], True


# ----------------------------------------------------------------------------
# main
# ----------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(description="Phase 3 contract derivative-of autofill")
    parser.add_argument("--dry-run", action="store_true", help="변경 list만 출력")
    parser.add_argument("--confirm", action="store_true", help="실제 파일 수정")
    args = parser.parse_args()

    if not args.dry_run and not args.confirm:
        args.dry_run = True

    changes = []  # (path, action, value)
    for md in iter_docs(DOCS_ROOT):
        fm = read_frontmatter(md)
        cat = classify_file(md, DOCS_ROOT, fm)
        if cat != "B":
            continue
        fm = fm or {}
        if (
            fm.get("derivative-of")
            or fm.get("related-spec")
            or fm.get("references")
        ):
            continue
        action, value = determine_action(md)
        if action == "skip":
            continue
        changes.append((md, action, value))

    print(f"Phase 3 변경 대상: {len(changes)} 파일")
    print()
    by_action: dict[str, list] = {}
    for path, action, value in changes:
        by_action.setdefault(action, []).append((path, value))

    for action, items in sorted(by_action.items()):
        print(f"--- [{action}] {len(items)} 파일 ---")
        for path, value in items:
            rel = str(path.relative_to(DOCS_ROOT)).replace("\\", "/")
            v_short = value if len(value) <= 60 else value[:60] + "..."
            print(f"  {rel}")
            print(f"    → {v_short}")
        print()

    if args.confirm:
        print()
        print("실제 파일 수정 중...")
        success = 0
        for path, action, value in changes:
            text = path.read_text(encoding="utf-8")
            if action == "add-derivative":
                new_text, modified = inject_frontmatter_field(text, "derivative-of", value)
                # if-conflict 라인도 추가 (Product_SSOT_Policy §2)
                if modified:
                    new_text, _ = inject_frontmatter_field(
                        new_text, "if-conflict", "derivative-of takes precedence"
                    )
            elif action == "add-related-spec":
                new_text, modified = inject_frontmatter_field(text, "related-spec", value)
            elif action == "reclassify-tier":
                new_text, modified = update_tier(text, value)
            else:
                continue
            if modified:
                path.write_text(new_text, encoding="utf-8")
                success += 1
        print(f"OK: {success}/{len(changes)} 파일 수정 완료.")
        return 0

    return 1 if changes else 0


if __name__ == "__main__":
    sys.exit(main())
