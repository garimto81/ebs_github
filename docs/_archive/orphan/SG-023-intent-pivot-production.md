---
title: SG-023 — 인텐트 전환 (기획서 완결 → production 출시)
owner: conductor
tier: internal
status: DONE
resolved: 2026-04-27
resolved-by: conductor (사용자 명시 결정 cascade)
type: spec-gap
spec-gap-type: C
linked-decision: user 2026-04-27 (B 옵션 채택)
last-updated: 2026-04-27
reimplementability: PASS
reimplementability_checked: 2026-05-03
reimplementability_notes: "status=DONE — 인텐트 전환 (기획서 완결 → 인계 준비) governance 적용"
confluence-page-id: 3820552961
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3820552961/EBS+SG-023+production
mirror: none
---
## 결정 (사용자 명시 2026-04-27)

> "B 가 사용자 진정 의도. Conductor 가 자율 진행 전에 memory + Foundation 명시 갱신 PR 먼저 필요. 사실상 Phase 1 의 추가 결정 (SG-023 — 인텐트 변경) 으로 분류되며 cascade 재실행"

**EBS 의 프로젝트 인텐트 전환**: 기획서 완결 + 프로토타입 검증 → production 출시 프로젝트.

## 분류

| 항목 | 값 |
|------|-----|
| Spec Gap Type | **C (기획 모순)** — 사용자 본인 2026-04-20 결정 vs 2026-04-27 결정 reversal |
| 영향 범위 | 프로젝트 전체 (memory / CLAUDE.md / Foundation / NOTIFY / 거버넌스 / timeline / vendor) |
| Decision Owner | 사용자 (의사결정), Conductor (cascade 처리) |
| 후속 결정 필요 | Yes (B-Q5~Q9, 사용자 명시 대기) |

## Cascade 처리 (본 turn, Conductor 자율 범위)

| 파일 | 처리 | 비고 |
|------|------|------|
| memory `project_intent_spec_validation.md` | [SUPERSEDED 2026-04-27] callout 마크 | history 보존 |
| memory `user_role_planner.md` | [SUPERSEDED 2026-04-27] callout 마크 | history 보존 |
| memory `project_intent_production_2026_04_27.md` | NEW (인텐트 SSOT) | 본 SG-023 결정 명시 |
| memory `MEMORY.md` 인덱스 | SUPERSEDED 마킹 + 신규 entry | |
| CLAUDE.md (project) "🎯 프로젝트 의도" 섹션 | 재작성 (production 인텐트) | supersedes + 후속 결정 명시 |
| `Spec_Gap_Registry.md` | SG-023 row 신규 + changelog | |
| `Phase_1_Decision_Queue.md` | Group E 추가 + changelog v1.2 | |
| `NOTIFY-ALL-SG023-INTENT-PIVOT.md` | NEW broadcast | 각 팀 작업 일시 standby |
| 본 파일 (`SG-023-intent-pivot-production.md`) | NEW (백로그 항목) | |

## Cascade 미처리 (후속 결정 필요 — Backlog 등재)

본 SG-023 은 **인텐트 명시 변경만** 처리. 다음 cascade 는 사용자 명시 결정 대기:

| ID | 후속 결정 | decision_owner |
|----|-----------|----------------|
| B-Q5 | Conductor 의 team1~4 코드 영역 진입 권한 (현재 CLAUDE.md 명시 금지) | 사용자 |
| B-Q6 | timeline / MVP 정의 / 런칭 일정 | 사용자 |
| B-Q7 | 품질 기준 (prototype vs production-grade 측정 기준) | 사용자 |
| B-Q8 | vendor 모델 reactivate (RFI/RFQ 재개 여부) | 사용자 |
| B-Q9 | Type 분류 재해석 (Type A/B/C/D 의 production 의미) | 사용자 |

각 항목은 별도 turn 에서 사용자 결정 후 새 SG (SG-023.X) 또는 별도 SG 로 cascade.

## Verification (본 turn 한정)

- [x] 새 인텐트 SSOT 명시 (memory project_intent_production_2026_04_27.md)
- [x] 이전 인텐트 SUPERSEDED 마킹 (memory project_intent_spec_validation, user_role_planner)
- [x] CLAUDE.md (project) 의도 섹션 갱신
- [x] Spec_Gap_Registry SG-023 row 추가
- [x] Phase_1_Decision_Queue Group E 추가
- [x] NOTIFY-ALL-SG023-INTENT-PIVOT 발행
- [x] 후속 결정 사항 Backlog 등재 (B-Q5~Q9 후보)
- [ ] 거버넌스 / timeline / 품질 / vendor / Type 분류 = **명시 보류** (사용자 결정 대기)

## 참조

- memory `project_intent_production_2026_04_27` (NEW SSOT)
- `Phase_1_Decision_Queue.md` Group E
- `NOTIFY-ALL-SG023-INTENT-PIVOT.md` (broadcast)
- 폐기: memory `project_intent_spec_validation` [SUPERSEDED]
- 폐기: memory `user_role_planner` [SUPERSEDED]
- 후속: B-Q5~Q9 (사용자 결정 대기)
