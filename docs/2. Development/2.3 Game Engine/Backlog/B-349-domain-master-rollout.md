---
id: B-349
title: "Behavioral_Specs 4 Domain Master Rollout — Deprecation Shim + Audit Mapping + Cross-team 정합 검증"
status: IN_PROGRESS
priority: P1
created: 2026-04-28
source: docs/2. Development/2.3 Game Engine/Backlog.md
related-prs:
  - "PR #7 (Phase 1 Lifecycle)"
  - "PR #9 (Phase 2 Triggers)"
  - "PR #12 (Phase 3 Betting)"
  - "PR #14 (Phase 4 Variants)"
related-spec:
  - "Behavioral_Specs/Lifecycle_and_State_Machine.md"
  - "Behavioral_Specs/Triggers_and_Event_Pipeline.md"
  - "Behavioral_Specs/Betting_and_Pots.md"
  - "Behavioral_Specs/Variants_and_Evaluation.md"
---

# [B-349] Behavioral_Specs 4 Domain Master Rollout (P1)

## 배경

2026-04-27 ~ 04-28 동안 `docs/2. Development/2.3 Game Engine/Behavioral_Specs/` 디렉토리의 17 개 BS-06-XX 문서를 **4 도메인 마스터** 로 무손실 통합 (PR #7/#9/#12/#14, 총 6,301 줄). 본 Backlog 는 그 후속 작업을 추적한다.

## 통합 결과 요약

| Phase | 도메인 마스터 | 입력 | 출력 | 압축률 | PR |
|:-----:|------------|:----:|:----:|:------:|:--:|
| 1 | Lifecycle_and_State_Machine.md | BS-06-01/10 + Overview lifecycle 발췌 | 1,176 | -4% (메타 +) | #7 ✅ |
| 2 | Triggers_and_Event_Pipeline.md | BS-06-00-triggers/04/09/12 | 1,836 | 19% | #9 ✅ |
| 3 | Betting_and_Pots.md | BS-06-02/03/06/07 | 1,706 | 38% | #12 ✅ |
| 4 | Variants_and_Evaluation.md | BS-06-05/08/1X/2X/3X + Eval_Ref | 1,583 | 37% | #14 (auto-merge) |
| **합계** | 4 마스터 | ~8,622 줄 | **6,301 줄** | **27% 평균** | 4 PR |

## 후속 작업 항목

### 1. Deprecation Shim ✅ (본 PR)

16 원본 BS-06-XX 파일을 redirect frontmatter stub 으로 교체:
- Phase 1: Holdem/Lifecycle.md, Action_Rotation.md (2)
- Phase 2: Triggers.md, Event_Catalog.md, Holdem/Coalescence.md, Card_Pipeline_Overview.md (4)
- Phase 3: Holdem/Betting.md, Holdem/Blinds_and_Ante.md, Holdem/Side_Pot.md, Holdem/Showdown.md (4)
- Phase 4: Holdem/Evaluation.md, Evaluation_Reference.md, Flop_Variants.md, Draw_Games.md, Stud_Games.md, Holdem/Exceptions.md (6)

원본 내용은 git history (commit hash) 에 영구 보존.

### 2. Legacy-ID Redirect Mapping ✅ (본 PR)

- `docs/_generated/legacy-id-redirect.json` 생성
- 16 legacy-id → 4 도메인 마스터 매핑
- audit 도구 / IDE 점프 / cross-ref 검증에서 활용

### 3. 외부 SSOT 정합 검증 (P1, 후속 PR)

| 항목 | 권위 | 검증 |
|------|------|------|
| BS-06-09 OutputEvent 19개 ↔ API-04 §6.0 OutputEvent 21종 | API-04 권위 | 19 ↔ 21 차이 (2개) 분석 + 정합 매핑 |
| Triggers 도메인 IT-01~16 ↔ engine.dart 구현 | 코드 권위 | reduce() switch case ↔ IT 매트릭스 일치 |
| Variants 도메인 25 게임 마스터 테이블 ↔ `lib/core/variants/` 디렉토리 | 코드 권위 | game_id 0-24 ↔ variant 클래스 1:1 매핑 |

### 4. ssot_auditor.py 보강 (P2, 후속 PR)

`tools/ssot_auditor.py` 는 SG-022 키워드 추적기로 본 작업과 별개. 단, deprecation shim 들이 audit false positive 일으키지 않도록 frontmatter `tier: deprecated` 인식 추가 권장:

```python
# tools/ssot_auditor.py 보강 (예시)
def is_deprecation_shim(file_path: Path) -> bool:
    """frontmatter 에 tier: deprecated 가 있으면 본문 검사 skip"""
    content = file_path.read_text(encoding="utf-8")
    if not content.startswith("---"):
        return False
    end = content.index("---", 3)
    fm = content[3:end]
    return "tier: deprecated" in fm and "redirect-to:" in fm
```

### 5. Behavioral_Specs/Overview.md 정리 (P2, 후속 PR)

Overview.md (1,759 줄) 의 lifecycle 발췌 (§1.1, §1.2.4, §1.4.5, §1.5.2, §1.9, §2.1, §2.2, §7.4, §7.5) 는 Lifecycle 도메인 마스터에 흡수됨. 그러나 Overview.md 는 lifecycle 외 enum / data model / 출력 / Docker 등 다양한 도메인 포함하므로 **전체 deprecation 대상 아님**. Lifecycle 발췌 부분에 cross-ref 추가 권장:

```markdown
> ℹ️ §1.9 게임 페이즈 Enum, §2.1 GameState, §2.2 Player 는 Lifecycle 도메인 마스터 §2.2/§5.1/§5.2 로 흡수되었습니다. 본 Overview 의 해당 섹션은 cross-reference 로 유지됩니다.
```

또는 Overview.md 자체도 도메인별로 분할 검토 (별도 backlog 항목으로 추후 평가).

### 6. Cross-team 영향 검증 (P2, 후속 PR)

다음 팀 문서들이 BS-06-XX 를 인용할 가능성:

| 팀 | 인용 위치 추정 | 대응 |
|----|-------------|------|
| team1 (Frontend) | UI 화면 → game_phase 매핑 | legacy-id-redirect.json 으로 점프 가능 |
| team2 (Backend) | API 스펙 → 베팅 액션 | 동일 |
| team4 (CC) | RFID → Coalescence | 동일 |

cross-team `grep -rn "BS-06-"` 후 발견된 인용을 redirect 로 갱신.

## 수락 기준

- [x] 16 deprecation shim 작성 (frontmatter + redirect 안내)
- [x] `legacy-id-redirect.json` 생성 (audit 도구용 mapping)
- [x] 본 Backlog 항목 등재
- [ ] 외부 SSOT 정합 검증 (별도 PR 후속)
- [ ] ssot_auditor.py 보강 (별도 PR 후속)
- [ ] Overview.md cross-ref 추가 (별도 PR 후속)
- [ ] Cross-team 인용 검증 (별도 PR 후속)

## 관련

- 4 도메인 마스터 PR (#7 / #9 / #12 / #14)
- legacy-id-redirect.json (`docs/_generated/legacy-id-redirect.json`)
- 1,400 줄 증발 사고 (2026-04-27 subdir conflict) — 본 작업의 sibling worktree + chunk-by-chunk commit 패턴은 이 사고의 학습 결과
