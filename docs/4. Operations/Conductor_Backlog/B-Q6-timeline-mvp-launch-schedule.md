---
title: B-Q6 — timeline / MVP 정의 / 런칭 일정 (사용자 명시 대기)
owner: conductor
tier: internal
status: PENDING
type: backlog-deferred-decision
linked-sg: SG-023
linked-decision-pending: user (timeline 구체 명시 부재)
last-updated: 2026-04-27
---

## 개요

SG-023 (인텐트 = production 출시) cascade 의 후속 결정. **사용자 명시 결정 필요**.

## 결정 사항

- production 런칭 일정 (예: 2027-01? 2027-06? 다른 일정?)
- MVP 정의 (어느 게임? 어느 기능 범위?)
- Phase 정의 (단계별 출시 vs 일괄?)

## 참고 자료

memory `project_2027_launch_strategy.md` [LEGACY 2026-04-20 무효화] — SG-023 채택 후 reactivate 후보:
- 2027-01 런칭, 2027-06 Vegas (이전 plan)
- MVP=홀덤1종 (이전 plan, memory `project_architecture_v33` 에 명시)
- Phase 0 업체 선정 (이전 plan, [INACTIVE])

## 선택지

| 옵션 | 의미 |
|:----:|------|
| ㉠ | 이전 LEGACY plan reactivate (2027-01 런칭, 2027-06 Vegas, MVP=홀덤) |
| ㉡ | 새 timeline 명시 (사용자 직접 입력) |
| ㉢ | timeline 결정 보류, 기능 완성도 기반 진행 (일정 미정) |

## 영향

- ㉠ 채택 시: Roadmap.md 재작성, vendor 일정 연동 (B-Q8 자동 활성화), 단계별 cascade 계획 가능
- ㉡ 채택 시: 사용자 입력 후 동일 cascade
- ㉢ 채택 시: vendor / 운영 일정 등 부수 결정도 보류, agile 진행

## 후속 cascade (사용자 결정 후)

- Roadmap.md 재작성 (production 일정 기준)
- memory `project_2027_launch_strategy` 상태 갱신 (LEGACY → ACTIVE 또는 SUPERSEDED)
- 각 팀 Backlog 의 우선순위 재정렬

## 참조

- memory `project_intent_production_2026_04_27` (SG-023 SSOT)
- memory `project_2027_launch_strategy.md` [LEGACY]
- `docs/4. Operations/Roadmap.md` (현재 SSOT Alignment Roadmap)
- SG-023, SG-024 (선행 결정)
