"""One-shot script: 16 BS-06-XX deprecation shim 일괄 생성.

도메인 마스터 4 작성 (PR #7/#9/#12/#14) 후 후속 작업.
2026-04-28 — Behavioral_Specs deprecation rollout.

각 원본 BS-06-XX 파일을 redirect stub 으로 교체:
- frontmatter: redirect-to + deprecated date + status
- 본문: 짧은 deprecation 안내 + 도메인 마스터 링크 + 부록 A 참조
- 원본 내용은 git history 에 보존

실행:
    python tools/_create_deprecation_shims.py

사용 후 본 스크립트는 삭제 (one-shot, _underscore prefix).
"""
from __future__ import annotations

from pathlib import Path
from typing import NamedTuple

REPO_ROOT = Path(__file__).resolve().parent.parent
BS_ROOT = REPO_ROOT / "docs" / "2. Development" / "2.3 Game Engine" / "Behavioral_Specs"


class Shim(NamedTuple):
    file: str               # BS_ROOT 기준 상대
    legacy_id: str          # BS-06-XX
    title: str              # 원본 title
    domain_master: str      # 본 BS_ROOT 기준 상대 (./Lifecycle_and_State_Machine.md 등)
    domain_label: str       # "Lifecycle & State Machine" 등 (인간 가독)


SHIMS: list[Shim] = [
    # ── Phase 1: Lifecycle & State Machine ──
    Shim("Holdem/Lifecycle.md", "BS-06-01", "Lifecycle",
         "../Lifecycle_and_State_Machine.md", "Lifecycle & State Machine"),
    Shim("Action_Rotation.md", "BS-06-10", "Action Rotation",
         "./Lifecycle_and_State_Machine.md", "Lifecycle & State Machine"),
    # ── Phase 2: Triggers & Event Pipeline ──
    Shim("Triggers.md", "BS-06-00-triggers", "Triggers",
         "./Triggers_and_Event_Pipeline.md", "Triggers & Event Pipeline"),
    Shim("Event_Catalog.md", "BS-06-09", "Event Catalog",
         "./Triggers_and_Event_Pipeline.md", "Triggers & Event Pipeline"),
    Shim("Holdem/Coalescence.md", "BS-06-04", "Coalescence",
         "../Triggers_and_Event_Pipeline.md", "Triggers & Event Pipeline"),
    Shim("Card_Pipeline_Overview.md", "BS-06-12", "Card Pipeline Overview",
         "./Triggers_and_Event_Pipeline.md", "Triggers & Event Pipeline"),
    # ── Phase 3: Betting & Pots ──
    Shim("Holdem/Betting.md", "BS-06-02", "Betting",
         "../Betting_and_Pots.md", "Betting & Pots"),
    Shim("Holdem/Blinds_and_Ante.md", "BS-06-03", "Blinds and Ante",
         "../Betting_and_Pots.md", "Betting & Pots"),
    Shim("Holdem/Side_Pot.md", "BS-06-06", "Side Pot",
         "../Betting_and_Pots.md", "Betting & Pots"),
    Shim("Holdem/Showdown.md", "BS-06-07", "Showdown",
         "../Betting_and_Pots.md", "Betting & Pots"),
    # ── Phase 4: Variants & Evaluation ──
    Shim("Holdem/Evaluation.md", "BS-06-05", "Evaluation",
         "../Variants_and_Evaluation.md", "Variants & Evaluation"),
    Shim("Evaluation_Reference.md", "Hand-Eval-Ref-v1.1", "Hand Evaluation 통합 레퍼런스",
         "./Variants_and_Evaluation.md", "Variants & Evaluation"),
    Shim("Flop_Variants.md", "BS-06-1X", "Flop Variants",
         "./Variants_and_Evaluation.md", "Variants & Evaluation"),
    Shim("Draw_Games.md", "BS-06-2X", "Draw Games",
         "./Variants_and_Evaluation.md", "Variants & Evaluation"),
    Shim("Stud_Games.md", "BS-06-3X", "Stud Games",
         "./Variants_and_Evaluation.md", "Variants & Evaluation"),
    Shim("Holdem/Exceptions.md", "BS-06-08", "Exceptions",
         "../Variants_and_Evaluation.md", "Variants & Evaluation"),
]


SHIM_TEMPLATE = """---
title: {title}
owner: team3
tier: deprecated
legacy-id: {legacy_id}
deprecated: 2026-04-28
redirect-to: "{domain_master}"
status: superseded
supersedes-by: "{domain_master}"
---

# [DEPRECATED 2026-04-28] {legacy_id}: {title}

> ⚠️ **본 문서는 deprecated 되었습니다 (2026-04-28).**
>
> 모든 내용은 [{domain_label}]({domain_master}) 도메인 마스터에 **무손실 통합** 되었으며, 후속 변경은 도메인 마스터에서 이루어집니다.

## 흡수 위치

본 문서의 매트릭스 / 알고리즘 / pseudocode / 유저 스토리 / WSOP Rule 매핑 등 모든 항목은 [`{domain_master}`]({domain_master}) 의 **부록 A: Legacy-ID Mapping** 에서 정확한 위치를 확인할 수 있습니다.

| 원본 | → 통합 위치 |
|------|------------|
| {legacy_id} ({title}) | {domain_label} 도메인 마스터 §부록 A |

## 원본 보존

원본 내용은 **git history 에 영구 보존** 됩니다 — 본 deprecation 직전 commit hash 에서 전체 내용 조회 가능:

```bash
git log --all --follow -- "docs/2. Development/2.3 Game Engine/Behavioral_Specs/{shim_path}"
git show <commit-hash>:"docs/2. Development/2.3 Game Engine/Behavioral_Specs/{shim_path}"
```

## 통합 PR

| 도메인 | PR | 일자 |
|--------|----|------|
| Lifecycle & State Machine | #7 | 2026-04-27 |
| Triggers & Event Pipeline | #9 | 2026-04-27 |
| Betting & Pots | #12 | 2026-04-28 |
| Variants & Evaluation | #14 | 2026-04-28 |
| **Deprecation Shim (본 PR)** | TBD | 2026-04-28 |

## 신규 참조

- 도메인 마스터 본문: [`{domain_master}`]({domain_master})
- 도메인 마스터 부록 A (legacy-id 매핑): 같은 파일 §부록 A
- Legacy-ID redirect mapping (audit 도구용): [`docs/_generated/legacy-id-redirect.json`](../../../../_generated/legacy-id-redirect.json) (Conductor 자동 생성)
"""


def main() -> int:
    written = []
    skipped = []
    for shim in SHIMS:
        target = BS_ROOT / shim.file
        if not target.exists():
            skipped.append(f"NOT FOUND: {shim.file}")
            continue

        # frontmatter + body 작성
        body = SHIM_TEMPLATE.format(
            title=shim.title,
            legacy_id=shim.legacy_id,
            domain_master=shim.domain_master,
            domain_label=shim.domain_label,
            shim_path=shim.file,
        )

        # 백업: git history 가 보존하므로 별도 백업 불필요
        target.write_text(body, encoding="utf-8")
        original_lines = "?"  # 보존 안 함, git log 로 조회
        written.append(f"  {shim.file:50s} → {shim.domain_label}")

    print(f"Wrote {len(written)} deprecation shims:")
    for w in written:
        print(w)
    if skipped:
        print(f"\n⚠️  Skipped {len(skipped)}:")
        for s in skipped:
            print(f"  {s}")
    return 0 if not skipped else 1


if __name__ == "__main__":
    raise SystemExit(main())
