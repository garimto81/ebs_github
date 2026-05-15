---
title: V9.5 결과물 E2E Iteration — Phase / Task Plan + P5/P6 진행
owner: conductor
tier: operations
last-updated: 2026-04-29
governance: v9.5
related: ["2026-04-29-v95-ssot-implementation-gap-triage.md"]
confluence-page-id: 3819766194
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819766194/EBS+V9.5+E2E+Iteration+Phase+Task+Plan+P5+P6
mirror: none
---

# V9.5 결과물 E2E Iteration Phase Plan

> **사용자 의도 trigger (2026-04-29)**: "phase and task 작성하여 구현 진행".
> V9.5 SSOT-구현 gap 처리 후 결과물 e2e 검증을 위한 Phase 분해.

## 🎯 본 cycle 진행 (P5 + P6 부분)

| Phase | Task | 상태 |
|:-----:|------|:----:|
| **P5** | Blind levels CRUD service pytest 추가 (8 cases) | ✅ 8/8 PASS |
| **P6** | 새 발견 4 unknown 진단 + Type 분류 | ✅ 본 보고서 |

## 📊 P6 — 새 발견 4 unknown Type 분류

PR #85+#86 머지 후 drift audit 재실행으로 발견된 신규 unknown:

| Frontend 호출 | BO 제공 endpoint | Type | 처리 방향 |
|--------------|------------------|:----:|----------|
| `POST /skins/{id}/deactivate` | `POST/PUT /api/v1/skins/{id}/activate` 만 제공 | **A3 (BO missing)** | BO 측 deactivate endpoint 추가 |
| `POST /users/{id}/force-logout` | (없음) | **A3 (BO missing)** | BO 측 admin force-logout 추가 |
| `POST /tables/{id}/seats` | `GET /api/v1/tables/{id}/seats` 만 제공 | **A3 (BO missing)** | BO 측 seat 추가 endpoint |
| `DELETE /tables/{id}/seats/{seat_no}` | `PUT /api/v1/tables/{id}/seats/{seat_no}` 만 제공 | **A3 (BO missing)** | BO 측 seat delete endpoint |

**전부 Type A3 (backend missing)** — team2-backend publisher Fast-Track 작업.

## 🗂 전체 Phase Plan (V9.5 결과물 e2e iteration)

### ✅ 완료 (오늘 cycle)

| Phase | 결과 | PR |
|:-----:|------|:--:|
| P1 | SSOT-구현 gap 진단 (16 unknown) | #84 |
| P2 | team1 frontend 11 paths fix | #85 |
| P3 | team2 backend blind levels CRUD endpoints | #86 |
| P5 | Blind levels CRUD pytest 8 cases | (본 PR) |
| P6 | 새 unknown 4 paths 진단 | (본 PR) |

### 📅 후속 Phase (별도 cycle, 분량 control)

| Phase | 작업 | 분량 | trigger |
|:-----:|------|:----:|--------|
| **P4** | Flaky test 격리 (test_update_series_partial_fields, 본 PR 무관) | 작음 | 사용자 의도 trigger 시 |
| **P7** | 새 4 unknown Type A3 처리 — BO endpoints 추가 | 큼 (4 endpoints + service + tests) | trigger 시 |
| **P8** | Docker BO + lobby-web rebuild + drift audit re-run | 큼 (build 5~10분) | trigger 시 |
| **P9** | E2E browser flow (Playwright) — login → series → blind structure → levels | 매우 큼 (env 설정 + 시나리오) | trigger 시 |
| **P10** | 결과물 quality metric 산출 (re-implementability + WSOP LIVE 정렬 + SSOT 일관성) | 중간 | 30일 cycle 종료 시 |

## 🛠 P7 상세 Task (다음 cycle 자율 진행 가능)

### Task P7-1: `POST /api/v1/skins/{id}/deactivate`

```python
# team2-backend/src/routers/skins.py 추가:
@router.post("/skins/{skin_id}/deactivate")
def api_deactivate_skin(skin_id: int, ...):
    # service.deactivate_skin(skin_id, db)
    # 활성 스킨 상태 → inactive
```

### Task P7-2: `POST /api/v1/users/{id}/force-logout` (admin only)

```python
# team2-backend/src/routers/users.py 추가:
@router.post("/users/{user_id}/force-logout")
def api_force_logout(user_id: int, _user: User = Depends(require_role("admin")), ...):
    # JWT blacklist + WS disconnect
```

### Task P7-3: `POST /api/v1/tables/{id}/seats`

```python
# 시트 추가 (테이블 정원 확장)
@router.post("/tables/{table_id}/seats")
def api_add_seat(table_id: int, body: SeatCreate, ...):
```

### Task P7-4: `DELETE /api/v1/tables/{id}/seats/{seat_no}`

```python
# 시트 삭제 (정원 축소)
@router.delete("/tables/{table_id}/seats/{seat_no}")
def api_delete_seat(table_id: int, seat_no: int, ...):
```

## 🛠 P9 상세 Task (E2E Playwright)

| Task | 시나리오 |
|------|---------|
| P9-1 | Login → /api/v1/auth/login + /auth/session 검증 |
| P9-2 | Series CRUD → /api/v1/series 정합 |
| P9-3 | Blind Structure CRUD → /api/v1/blind-structures (V9.5 P2 fix 반영) |
| P9-4 | **Blind Levels CRUD → /api/v1/blind-structures/{id}/levels** (P3 신규) |
| P9-5 | Logout → POST /api/v1/auth/logout (V9.5 P2 fix 반영) |

## 📐 V9.5 결과물 quality 척도

본 plan 의 정당화:

| 척도 | 목표 | 현재 상태 |
|------|------|----------|
| **Re-implementability** | 외부 개발팀이 docs/ + team1~4/ 로 동일 시스템 재구현 가능 | P1-P6 으로 SSOT-구현 정합 강화 |
| **WSOP LIVE 정렬** | 원칙 1 (CLAUDE.md) | 영향 없음 (HTTP routing 정합 작업) |
| **SSOT 일관성** | 충돌 0 | P1-P3 으로 16 → 6 unknown 축소 |
| **E2E 동작 증명** | login → CRUD → logout 시나리오 | P9 후속 cycle 필요 |
| **Production deploy** | Docker compose green | P8 후속 cycle 필요 |

## 🔗 관련

- PR #84 (Phase 1): SSOT-구현 gap 진단
- PR #85 (Phase 2): team1 frontend fix
- PR #86 (Phase 3): team2 backend levels CRUD
- 본 PR (P5 + P6): test 추가 + 새 unknown 진단
- `Spec_Gap_Triage.md` (Type A/B/C/D 정책)
- `team-policy.json` `governance_model.intent_execution_boundary.ssot_first_judgment`
