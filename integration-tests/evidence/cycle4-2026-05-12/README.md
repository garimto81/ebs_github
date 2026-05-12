# Cycle 4 Evidence — 2026-05-12 (S9 QA autonomous iteration)

Issue: [#266](https://github.com/garimto81/ebs_github/issues/266) — 1 hand e2e 실제 실행 + drift 검증

## 실행 환경

| 서비스 | 호스트 포트 | 헬스체크 |
|--------|:----------:|:--------:|
| BO | `:18001` | login 200 OK |
| Engine | `:18080` | `/health` 200 OK |

## 시나리오 실행 결과

### 10-auth-login-profile.http — ✅ 3/3 PASS

| Step | Endpoint | HTTP | Evidence |
|------|----------|:----:|----------|
| 10.1 | POST /api/v1/auth/login (admin@local) | 200 | [01-login.json](10-auth/01-login.json) |
| 10.x | GET /api/v1/auth/me | 200 | [02-me.json](10-auth/02-me.json) |
| 10.3 | POST /api/v1/auth/refresh | 200 | [03-refresh.json](10-auth/03-refresh.json) |

[Summary](10-auth/summary.txt)

### 50-rfid-deck-register.http — ⚠️ 2/3 PASS (50.2 drift 잔존)

| Step | Endpoint | HTTP | 기대 | Evidence |
|------|----------|:----:|:----:|----------|
| 50.1 | POST /api/v1/decks | 201 | 201 | [01-create.json](50-rfid/01-create.json) ✓ |
| 50.4 | GET /api/v1/decks | 200 | 200 | [02-list.json](50-rfid/02-list.json) ✓ |
| 50.2 | POST /api/v1/decks (dup UID) | **201** | 422 | [03-dup.json](50-rfid/03-dup.json) ❌ |

**DRIFT-50.2-dup-uid (Cycle 2 보고, Cycle 4 재확인 잔존)**:
BO가 같은 deck 내 중복 UID 2장을 422로 거부하지 않고 201로 통과시킴.
team2-backend 미해결 — production blocker.

[Summary](50-rfid/summary.txt)

### v01-1-hand-flow.http — ✅ 5/5 PHASE PASS (Engine harness regression)

| Phase | Step | HTTP | 검증 | Evidence |
|:-----:|------|:----:|------|----------|
| A | /health | 200 | service alive | [A1](v01-1-hand-flow/A1-health.json) |
| A | /api/variants | 200 | nlh 포함 | [A2](v01-1-hand-flow/A2-variants.json) |
| A | POST /api/session (nlh, 6 seats) | 201 | pot.main=15 (SB+BB), dealer/SB/BB 자동 | [A3](v01-1-hand-flow/A3-session-create.json) |
| B | fold seat 3 (UTG) | 200 | status=folded | [B1](v01-1-hand-flow/B1-fold-seat3.json) |
| B | fold seat 4 | 200 | status=folded | [B2](v01-1-hand-flow/B2-fold-seat4.json) |
| B | fold seat 5 | 200 | status=folded | [B3](v01-1-hand-flow/B3-fold-seat5.json) |
| B | fold seat 0 (dealer) | 200 | status=folded | [B4](v01-1-hand-flow/B4-fold-seat0.json) |
| B | fold seat 1 (SB) | 200 | active=1, winner_idx=2 | [B5](v01-1-hand-flow/B5-fold-seat1.json) |
| C | pot_awarded → BB +15 | 200 | seat[2].stack=1005, pot=0 | [C1](v01-1-hand-flow/C1-pot-awarded.json) |
| D | hand_end | 200 | handNumber=1 | [D1](v01-1-hand-flow/D1-hand-end.json) |
| E | GET /api/session/{id} | 200 | folded=5 active=1 winner_stack=1005 | [E1](v01-1-hand-flow/E1-final-state.json) |

[Summary](v01-1-hand-flow/summary.txt)

## KPI 충족

- ✅ **1 hand e2e 완주**: v01 5/5 phase PASS
- ✅ **pipeline:qa-pass publish (실제, 신호 아님)**: 위 evidence 기반 → broker publish
- ✅ **10-auth admin@local 통일**: SG-035 정합 (이미 upstream 정정)
- ⚠️ **50.2 dup UID drift 잔존**: defect:type-d-drift publish (team2 미해결)
