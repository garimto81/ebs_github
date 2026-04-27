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

## 현재 상태 (2026-04-27 Session 2 Phase 1 audit 정정)

⚠️ **이전 SSOT (90%) 가 stale 기록이었음**. 실제 측정 결과:

| 팀 | tests | stmts | missed | **coverage (실제)** | gap to 95% |
|:--:|:-----:|:-----:|:------:|:------------------:|:----------:|
| team2-backend | 261 | 3984 | 882 | **78%** | **17%p (683 stmts)** |
| team1-frontend | (미측정) | — | — | (미측정) | 측정 필요 |
| team3-engine | (미측정) | — | — | (미측정) | 측정 필요 |
| team4-cc | (미측정) | — | — | (미측정) | 측정 필요 |

### 정정 대상 SSOT (모두 "90%" stale)

- `team2-backend/CLAUDE.md` "Build" 섹션
- `Spec_Gap_Registry.md` SG-026 row
- `Conductor_Backlog/SESSION_1_HANDOFF.md`
- `Phase_1_Decision_Queue.md` Group H (B-Q15 cascade)
- 이전 commit messages (불변, history 로 보존)

### Largest gap 영역 (services/ 영역 미커버 집중)

| 모듈 | coverage | missed lines | 우선순위 |
|------|:--------:|:------------:|:--------:|
| `src/services/auth_service.py` | 50% | 74 | P1 |
| `src/services/blind_structure_service.py` | 20% | 65 | P1 |
| `src/services/series_service.py` | 57% | 67 | P1 |
| `src/services/table_service.py` | 65% | 60 | P2 |
| `src/services/payout_structure_service.py` | 26% | 42 | P2 |
| `src/services/hand_service.py` | 27% | 37 | P2 |
| `src/services/clock_service.py` | 38% | 37 | P2 |
| `src/services/user_service.py` | 30% | 31 | P2 |
| `src/services/competition_service.py` | 30% | 28 | P2 |
| `src/services/undo_service.py` | 32% | 25 | P3 |
| `src/services/skin_service.py` | 75% | 14 | P3 |
| `src/adapters/wsop_auth.py` | **0%** | 47 | P1 (완전 untested) |
| `src/routers/auth.py` | 71% | 57 | P2 |
| `src/routers/blind_structures.py` | 49% | 24 | P2 |
| `src/routers/hands.py` | 37% | 31 | P2 |
| `src/routers/skins.py` | 73% | 12 | P3 |
| 작은 모듈 (replay, players, rbac 등) | 88-96% | 합계 ~30 | P3 (작은 노력 100% 가능) |

## Multi-turn plan (95% 도달)

683 stmts 추가 커버 = 약 70-140 단위 테스트 = **5-10 sub-sessions**:

| Sub-Session | 영역 | 목표 | 예상 분량 |
|:-----------:|------|------|:---------:|
| 2.1 | services/auth_service.py 50% → 80% | +45 stmts | 10-15 tests |
| 2.2 | services/blind_structure_service.py + payout_structure_service.py 20-26% → 70% | +75 stmts | 15-20 tests |
| 2.3 | services/series_service.py + table_service.py 57-65% → 80% | +60 stmts | 12-15 tests |
| 2.4 | services/hand_service + clock_service + user_service + competition_service 27-38% → 70% | +130 stmts | 20-25 tests |
| 2.5 | adapters/wsop_auth.py 0% → 70% | +33 stmts | 10 tests |
| 2.6 | routers/blind_structures + hands + auth + skins 보강 | +110 stmts | 20-25 tests |
| 2.7 | services/skin + undo + 작은 모듈 100% 도달 | +50 stmts | 10-15 tests |

각 sub-session = 단일 turn 분량 (10-25 tests + pytest --cov 검증).

## 처리 작업

1. team1/team3/team4 의 coverage 측정 framework 통일 (별도 turn)
2. team2 의 17%p gap 영역 sub-session 분할 진행 (위 plan)
3. 미커버 영역 단위 테스트 추가 (production code 0 수정)
4. CI 의 coverage gate 95% 강제 (Session 5 권장)

## 우선순위

P1 — B-Q7 ㉠ 의 직접 cascade. Phase 0 (~ 2026-12 MVP 완성) 기간 내 도달 권장. 단 multi-turn 분할 필수.

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
