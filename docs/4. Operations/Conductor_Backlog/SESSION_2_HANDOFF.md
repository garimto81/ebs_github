---
title: SESSION 2 HANDOFF — Core Logic & Backend Engine (Phase 1 audit 완료)
owner: conductor
tier: internal
type: session-handoff
session: 2
phase: 1 (audit)
session-status: PHASE_1_COMPLETED, PHASE_2_PENDING (Session 2.1)
linked-sg: SG-026, SG-027
linked-decision: 사용자 Session 2 진입 — Option D B-Q10 95% Coverage
last-updated: 2026-04-27
---

## Session 2 — Core Logic & Backend Engine

### 목표 (사용자 명시)

> Session 2: Core Logic & Backend Engine — Team 2(Backend) 및 Team 5(SDET/QA). B-Q10 95% Coverage 도달 (Strict: production code 0 수정).

## 1. Phase 1 — Gap Analysis 결과 (2026-04-27 본 turn)

### 1.1 baseline 정정 (🚨 stale SSOT 발견)

| 항목 | 이전 SSOT | 실제 측정 |
|------|----------|----------|
| pytest | 261 passed | ✅ 261 passed |
| coverage | "90%" (stale 2026-04-14) | **78%** (실제) |
| stmts | (미명시) | **3984 stmts / 882 missed** |
| 95% gap | "5%p" | **17%p (683 stmts)** |

**정정 cascade**:
- ✅ `B-Q10-95-coverage-roadmap.md` baseline 정정
- ✅ `Spec_Gap_Registry.md` SG-026 row 정정
- ✅ `team2-backend/CLAUDE.md` Build 섹션 정정
- ✅ `Phase_1_Decision_Queue.md` Group K + Changelog v1.8

### 1.2 Largest gaps (services/ 영역 미커버 집중)

```
  services/auth_service.py             50%   (74/149 missed)
  services/blind_structure_service.py  20%   (65/81 missed)
  services/series_service.py           57%   (67/157 missed)
  services/table_service.py            65%   (60/172 missed)
  services/payout_structure_service.py 26%   (42/57 missed)
  services/hand_service.py             27%   (37/51 missed)
  services/clock_service.py            38%   (37/60 missed)
  services/user_service.py             30%   (31/44 missed)
  services/competition_service.py      30%   (28/40 missed)
  adapters/wsop_auth.py                 0%   (47/47 missed) ← 완전 untested
  routers/auth.py                      71%   (57/194 missed)
  routers/hands.py                     37%   (31/49 missed)
```

### 1.3 사용자 Strict 룰 준수

- Production code 0 수정 ✅
- tests/ 만 추가 (본 turn 추가 0건 — Phase 2 는 Session 2.1)
- pytest 261 passed regression 0 ✅

## 2. Phase 2 — Test Harness Augmentation (다음 turn = Session 2.1)

### 2.1 단일 turn 17%p 도달 = 비현실 (정직 보고)

- 17%p = 683 stmts = 70-140 단위 테스트
- 단일 turn 토큰/시간 한계 (이미 본 turn pytest 116s 사용, 추가 cycle 시 timeout)
- 사용자 명시 "95% 도달까지 멈추지 마십시오" 와 정직 충돌

### 2.2 Multi-turn 분할 plan (Session 2.1 ~ 2.7)

| Sub-Session | 영역 | 목표 coverage | 예상 분량 | tests 추가 |
|:-----------:|------|:-------------:|:---------:|:----------:|
| **2.1** | auth_service.py 50% → 80% | +45 stmts | 1 turn | 10-15 tests |
| 2.2 | blind/payout structure services 20-26% → 70% | +75 stmts | 1 turn | 15-20 tests |
| 2.3 | series + table services 57-65% → 80% | +60 stmts | 1 turn | 12-15 tests |
| 2.4 | hand/clock/user/competition services 27-38% → 70% | +130 stmts | 1-2 turns | 20-25 tests |
| 2.5 | adapters/wsop_auth.py 0% → 70% | +33 stmts | 1 turn | 10 tests |
| 2.6 | routers (blind/hands/auth/skins) 보강 | +110 stmts | 1-2 turns | 20-25 tests |
| 2.7 | skin/undo/작은 모듈 100% 도달 + final 95% 검증 | +50 stmts | 1 turn | 10-15 tests |

**예상 총 분량**: 5-10 sub-sessions, 100-140 단위 테스트.

## 3. Session 2.1 진입 권고 (다음 turn)

### 우선 작업 — auth_service.py 50% → 80%

**대상**: `team2-backend/src/services/auth_service.py` (149 stmts, 75 covered, 74 missed)

**Missing line ranges** (audit 결과):
- `30, 33, 37-42` — module-level helpers
- `102, 111, 115` — auth flow branches
- `132-137, 148-160, 165-171, 176-185` — password reset paths
- `203-207, 215-236, 258-277` — OAuth + 2FA service paths

**예상 단위 테스트**: 10-15개 (auth flow edge cases, password reset, 2FA setup, OAuth callback variants)

**Production code 0 수정 룰 준수**: tests/ 만 추가.

### 검증 방식

- pytest tests/ --cov=src --cov-report=term-missing 재실행
- 결과: 261 + 신규 N tests passed, regression 0
- coverage: 78% → 78%+α (auth_service 보강분)

## 4. Session 2.7 완료 시 commit

목표 달성 시:
```
test(backend): increase test coverage to 95% (B-Q10)
```

본 commit message 는 95% 도달한 turn (Session 2.7) 에서만 사용.

## 5. 발견 사항 (Session 1 잔존 + Session 2)

| 발견 | 영향 | Backlog |
|------|------|---------|
| ebs-v2-* 외부 운영 자산 1분 전 부활 | 별개 프로젝트 (V2 audit closed) | V2_PURGE_REPORT (closed) |
| ebs-v2-engine healthcheck Type A | 본 repo 외부, B-Q17 보류 | B-Q17 |
| **78% baseline (이전 90% stale)** | 17%p gap multi-turn 필수 | B-Q10 (정정 완료) |
| services/ 영역 미커버 집중 | Multi-turn 분할 plan | B-Q10 §"Largest gap" |

## 6. 검증 체크리스트 (Session 2 Phase 1)

- [x] pytest 261 passed 검증 (regression 0)
- [x] coverage 측정 (78% baseline)
- [x] Largest gap 영역 식별 (services/auth_service, blind_structure 등)
- [x] Multi-turn plan 작성 (Session 2.1 ~ 2.7)
- [x] baseline SSOT 정정 (B-Q10/SG-026/team2 CLAUDE.md/Phase_1_Decision_Queue)
- [x] SESSION_2_HANDOFF.md 작성 (본 파일)
- [ ] Phase 2 단위 테스트 추가 — Session 2.1 (다음 turn)
- [ ] Phase 3 95% Zero-Regression — Session 2.7 완료 후
- [ ] Phase 4 commit + Session 2 종료 — Session 2.7 완료 후

## 7. Session 2.1 진입 조건 (다음 turn)

- 본 SESSION_2_HANDOFF.md 확인
- auth_service.py 의 missing line 정확한 의미 read
- 10-15 단위 테스트 작성 (production code 0 수정)
- pytest tests/test_auth_service_extended.py -v 실행 (개별 파일)
- 신규 tests 100% pass 확인
- 후속 commit `test(backend): auth_service coverage 50% → 80% (B-Q10 Session 2.1)`
- SESSION_2_1_HANDOFF.md 출력

## 참조

- `docs/4. Operations/Conductor_Backlog/B-Q10-95-coverage-roadmap.md` (정정 완료)
- `docs/4. Operations/Conductor_Backlog/SESSION_1_HANDOFF.md` (이전 session)
- `docs/4. Operations/Phase_1_Decision_Queue.md` Group K
- `docs/4. Operations/Spec_Gap_Registry.md` SG-026 (정정 완료)
- `team2-backend/CLAUDE.md` Build 섹션 (정정 완료)
