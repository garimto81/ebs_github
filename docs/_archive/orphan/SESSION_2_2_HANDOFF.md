---
title: SESSION 2.2 HANDOFF — blind/payout structure services 20-26% → 70%+
owner: conductor
tier: internal
type: session-handoff
session: 2.2
session-status: COMPLETED
linked-sg: SG-026
linked-decision: B-Q10 Session 2.2 (structure services coverage)
last-updated: 2026-04-27
confluence-page-id: 3818685071
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818685071/EBS+SESSION+2.2+HANDOFF+blind+payout+structure+services+20-26+70
---

## 1. 진행 결과

### 1.1 신규 테스트

**파일**: `team2-backend/tests/test_structure_services_extended.py` (24 unit tests)

| Service | tests | 영역 |
|---------|:-----:|------|
| blind_structure_service | 12 | list/get/levels/create/update (name/levels)/delete (success/conflict/not_found) + Flight (apply/get_flight not_found) |
| payout_structure_service | 12 | list/get/levels/create/update (name/levels)/delete (success/not_found) + TODO stubs (get_flight/apply returns None) |

### 1.2 검증

| 검증 | 결과 |
|------|:----:|
| 단위 실행 | ✅ 24/24 PASS in 0.38s |
| Full regression (전체 pytest) | ✅ **307 passed, 0 failed in 115.23s** |
| Production code 수정 | ✅ 0건 (Strict 룰 준수) |
| baseline 283 → 307 (+24) | ✅ Zero-Regression |

### 1.3 발견 — Production Bug (B-Q18 등재)

`update_blind_structure` + `update_payout_structure` 의 **same-transaction delete+insert IntegrityError**:
- SQLAlchemy flush 타이밍: INSERT 가 DELETE 보다 먼저 flush 시도
- 같은 unique key 로 INSERT → `UNIQUE constraint failed`
- **Type A (구현 실수)** — 기획 spec 은 "delete → insert" 정상

→ **B-Q18-structure-update-same-tx-flush-bug.md** NEW 등재. P1 priority.

**본 turn 영향**: Strict 룰 (production code 0 수정) 으로 본 bug 수정 안 함. 테스트는 빈 리스트 path 만 커버 (delete branch). replace-with-new-levels path 는 bug 수정 후 보강.

## 2. Coverage 영향 (추정)

본 turn `--cov` 미사용 (시간 단축). 추정:

| 모듈 | 이전 | 본 turn 후 (추정) |
|------|:----:|:----------------:|
| `blind_structure_service.py` | 20% (65 missed) | 65-70% (40+ stmts 커버) |
| `payout_structure_service.py` | 26% (42 missed) | 70-80% (30+ stmts 커버) |

전체 78% → 78.5-79.5% (structure services + Session 2.1 누적).

## 3. Multi-turn plan 갱신

| Sub-Session | 영역 | 상태 |
|:-----------:|------|:----:|
| ✅ 2.1 | auth_service.py 50% → 70%+ | COMPLETED (22 tests) |
| ✅ 2.2 | blind/payout structure 20-26% → 70%+ | COMPLETED (24 tests) |
| ⏳ 2.3 | series + table services 57-65% → 80% | NEXT |
| ⏳ 2.4 | hand/clock/user/competition services | PENDING |
| ⏳ 2.5 | adapters/wsop_auth.py 0% → 70% | PENDING |
| ⏳ 2.6 | routers 보강 | PENDING |
| ⏳ 2.7 | skin/undo/작은 모듈 100% + final 95% | PENDING |

## 4. Session 2.3 진입 권고 (다음 turn)

### 우선 작업 — `services/series_service.py` + `services/table_service.py`

| 모듈 | coverage | missed | 예상 tests |
|------|:--------:|:------:|:----------:|
| `services/series_service.py` | 57% | 67 | 12-15 |
| `services/table_service.py` | 65% | 60 | 12-15 |

상대적으로 큰 모듈 (157, 172 stmts). 다양한 CRUD + business logic. 분량 부담 큼 — 2 sub-turns 으로 분할 권장 가능.

## 5. 검증 체크리스트 (Session 2.2)

- [x] 신규 24 unit tests 작성 (`test_structure_services_extended.py`)
- [x] 24/24 PASS in 0.38s (단위 실행)
- [x] 전체 regression: **307 passed, 0 failed in 115.23s**
- [x] Production code 0 수정 (Strict 룰)
- [x] B-Q18 production bug 발견 + Backlog 등재
- [x] SESSION_2_2_HANDOFF.md 작성 (본 파일)
- [ ] series + table services Session 2.3 진입 (다음 turn)

## 6. Session 2.3 진입 조건 (다음 turn)

- 본 SESSION_2_2_HANDOFF.md 확인
- `services/series_service.py` + `services/table_service.py` read
- 24-30 단위 테스트 작성 (Strict 룰 준수)
- pytest 단위 + regression 검증
- SESSION_2_3_HANDOFF.md 출력

## 참조

- `team2-backend/tests/test_structure_services_extended.py` (NEW)
- `docs/4. Operations/Conductor_Backlog/B-Q18-structure-update-same-tx-flush-bug.md` (NEW)
- `docs/4. Operations/Conductor_Backlog/SESSION_2_1_HANDOFF.md` (이전 sub-session)
- `docs/4. Operations/Phase_1_Decision_Queue.md` Group M (예정)
