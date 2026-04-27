---
title: B-Q10 — 95% test coverage 도달 plan (B-Q7 ㉠ Production-strict cascade)
owner: conductor
tier: internal
status: PENDING
type: backlog
linked-sg: SG-026
linked-decision: B-Q7 ㉠ (Production-strict)
last-updated: 2026-04-27
---

## 개요

B-Q7 ㉠ (Production-strict) 채택으로 95%+ test coverage 가 production 게이트. 현재 team2 baseline = 247 tests / 90% coverage. **5%p gap 메우기 위한 plan 필요**.

## 현재 상태 (2026-04-27)

| 팀 | tests | coverage | gap to 95% |
|:--:|:-----:|:--------:|:----------:|
| team2-backend | 247 | 90% | 5%p |
| team1-frontend | (미측정) | (미측정) | 측정 필요 |
| team3-engine | (미측정) | (미측정) | 측정 필요 |
| team4-cc | (미측정) | (미측정) | 측정 필요 |

## 처리 작업

1. team1/team3/team4 의 coverage 측정 framework 통일 (예: pytest-cov, dart_coverage)
2. team2 의 5%p gap 분석 (어느 모듈/branch 가 미커버)
3. 미커버 영역 단위 테스트 추가 (각 팀 자체 진행 또는 Conductor Mode A)
4. CI 의 coverage gate 95% 강제 (현재 100%? unknown)

## 우선순위

P1 — B-Q7 ㉠ 의 직접 cascade. Phase 0 (~ 2026-12 MVP 완성) 기간 내 도달 권장.

## 참조

- Spec_Gap_Registry SG-026 (B-Q7 quality gates)
- memory `project_intent_production_2026_04_27`
- team2-backend/CLAUDE.md "Build" 섹션 (현재 90% coverage 기준)
