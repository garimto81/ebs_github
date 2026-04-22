---
id: B-100
title: "2026-04-22 회의록 기반 전면 재설계 Wave (7결정 통합)"
status: PENDING
source: docs/4. Operations/Plans/Redesign_Plan_2026_04_22.md
owner: conductor
created: 2026-04-22
---

# B-100 — 2026-04-22 재설계 Wave

## 배경

2026-04-22 회의에서 7건 결정 — 아키텍처 전면 재설계 트리거. Critic 5-Phase 완료 결과 GO 2건 / GO-WITH-REVISION 5건 / BLOCK 0건.

**분석**: `docs/4. Operations/Critic_Reports/Meeting_Analysis_2026_04_22.md`
**계획**: `docs/4. Operations/Plans/Redesign_Plan_2026_04_22.md`

## 결정 요약

| # | 결정 | Type | Judgement |
|:--:|------|:----:|:---------:|
| D1 | 1PC=1테이블 | A→D | GO-REVISION |
| D2 | 탭 단일화 + 다중창 옵션 | D | GO-REVISION |
| D3 | GE 제거 | C | GO-REVISION |
| D4 | 배경 투명화 | A | GO |
| D5 | 프로세스 독립 + DB SSOT | A | GO |
| D6 | 모바일 추상화 | B | GO-REVISION |
| D7 | CC 카드 비노출 | A | GO |

## Wave 1 (Conductor)

| Task | 파일 | 상태 |
|------|------|:---:|
| F1 | docs/1. Product/Foundation.md Ch.5-7 재작성 | PENDING |
| F2 | docs/2. Development/2.5 Shared/BS_Overview.md 용어 + 런타임 모드 | PENDING |
| F3 | docs/4. Operations/Spec_Gap_Registry.md SG-002~008 갱신 | PENDING |
| F4 | docs/2. Development/2.5 Shared/team-policy.json 재정의 | PENDING |

## Wave 2 (팀 세션)

| 팀 | Backlog ID | 주제 |
|:--:|-----------|------|
| team1 | B-team1-R01~R03 | Graphic_Editor archive + Rive_Manager + 런타임 모드 + Overlay config |
| team4 | B-team4-R01~R04 | Form Factor HAL + CC 카드 경계 + Overlay 투명 + 독립 프로세스 |
| team2 | B-team2-R01~R02 | DB State Broadcast + 복수 PC 세션 격리 |
| team3 | — | 영향 없음 (OutputEvent 분리 기구현) |

## Wave 3 (검증)

| Task | 주제 |
|------|------|
| V1 | Integration Test 5 시나리오 |
| V2 | WSOP LIVE Confluence 패턴 대조 (원칙 1) |

## Spec_Gap 영향

| SG | 변화 |
|:--:|------|
| SG-002 | PENDING → DONE (F1.3) |
| SG-003 | PENDING → IN_PROGRESS (Rive_Manager 재정의) |
| SG-004 | PENDING → **CANCELLED** (D3) |
| SG-005 | PENDING → DONE (F1.2) |
| SG-007 | 신설 — 폼팩터 추상화 (D6) |
| SG-008 | 신설 — Rive 외부 메타 관리 (D3 revision) |

## 완결 기준

- Wave 1/2/3 체크리스트 8건 PASS (Plan §8 참조)
- 외부 개발팀 재구현 가능성 검증: reimplementability PASS 복귀

## 실행 방법

후속 /team 호출 매트릭스: Plan §7 참조. 각 Task 별 독립 /team 호출로 atomic 진행.
