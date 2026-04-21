---
id: NOTIFY-team2-B088-PR4
title: "B-088 PR-4 — team2 Backend router REST path kebab→PascalCase (URGENT)"
status: BLOCKING
created: 2026-04-21
from: team1 (B-088 PR-6b 완료 후 notify)
target: team2
priority: P1 (실 BO 연결 복원 차단)
---

# NOTIFY → team2: B-088 PR-4 urgency

## 현재 상태 (2026-04-21 17:30)

team1 이 B-088 PR-6b (Repository REST path + MockDioAdapter) 및 B-088-B (기획 문서 374건) 를 **선제 commit 완료** (`ce7a063`). 이로 인해:

| 환경 | 상태 |
|------|------|
| **Mock (`USE_MOCK=true`)** | ✅ 정상 (MockDioAdapter 동기화 완료) |
| **실 Backend 연결 (`EBS_BO_HOST=...`)** | ❌ **전 endpoint 404** (team2 router 아직 kebab-case) |

## 차단 원인 분석

team1 세션은 team2-backend/ 코드를 수정할 수 없음 (CLAUDE.md 경계 + hook 강제). team1 선제 cut-over 는 사용자 지시 "남은 미해결 작업 대기하지 말고 진행" 에 따른 결정.

**end-to-end 정합 복원**은 team2 세션에서 PR-4 수행해야만 가능.

## team2 세션 작업 요청

### 대상 파일 (17 files)

| 파일 | kebab paths 수 | 예시 |
|------|:---:|------|
| `team2-backend/src/routers/auth.py` | 14 | `/login`, `/verify-2fa`, `/2fa/setup`, `/password/reset` |
| `team2-backend/src/routers/audit.py` | 3 | `/audit-logs`, `/audit-logs/download`, `/audit-events` |
| `team2-backend/src/routers/blind_structures.py` | 7 | `/blind-structures`, `/flights/{flight_id}/blind-structure` |
| `team2-backend/src/routers/competitions.py` | 5 | `/competitions`, `/competitions/{competition_id}` |
| `team2-backend/src/routers/configs.py` | 2 | `/configs/{section}` |
| `team2-backend/src/routers/hands.py` | 4 | `/hands`, `/hands/{hand_id}/players`, `/hands/{hand_id}/actions` |
| `team2-backend/src/routers/payout_structures.py` | 7 | `/payout-structures`, `/flights/{flight_id}/payout-structure` |
| `team2-backend/src/routers/series.py` | 5 | `/series`, `/series/{series_id}` |
| `team2-backend/src/routers/events.py` | 5 | `/events`, `/events/{event_id}/flights` |
| `team2-backend/src/routers/flights.py` | 5 | `/flights`, `/flights/{flight_id}/rebalance` |
| `team2-backend/src/routers/tables.py` | 10 | `/tables`, `/tables/{id}/launch-cc`, `/tables/rebalance` |
| `team2-backend/src/routers/players.py` | 4 | `/players`, `/players/search` |
| `team2-backend/src/routers/users.py` | 5 | `/users`, `/users/{id}/force-logout` |
| `team2-backend/src/routers/skins.py` | 7 | `/skins`, `/skins/{id}/activate`, `/skins/upload` |
| `team2-backend/src/routers/sync.py` | 2 | `/sync/trigger/{source}`, `/sync/status` |
| `team2-backend/src/routers/reports.py` | 1 | `/reports/{report_type}` |
| `team2-backend/src/main.py` | - | router include prefix 조정 (필요 시) |

### 확정 매핑 (Naming_Conventions.md v2 §1 SSOT)

- `@router.get("/tables")` → `@router.get("/Tables")`
- `@router.get("/hand-history")` → `@router.get("/HandHistory")`
- `@router.get("/blind-structures")` → `@router.get("/BlindStructures")`
- `@router.get("/payout-structures")` → `@router.get("/PayoutStructures")`
- `@router.get("/audit-logs")` → `@router.get("/AuditLogs")`
- `@router.post("/login")` → `@router.post("/Login")`
- `@router.post("/verify-2fa")` → `@router.post("/Verify2FA")`
- `@router.post("/2fa/setup")` → `@router.post("/2FA/Setup")`
- `@router.post("/password/reset/send")` → `@router.post("/Password/Reset/Send")`
- `@router.get("/users/{id}/force-logout")` → `@router.get("/Users/{id}/ForceLogout")`
- `@router.post("/tables/rebalance")` → `@router.post("/Tables/Rebalance")`
- `@router.post("/tables/{id}/launch-cc")` → `@router.post("/Tables/{id}/LaunchCc")`

### Path variable 처리

WSOP LIVE 규약: path variable 은 **camelCase** (snake 금지).
- `{competition_id}` → `{competitionId}`
- `{flight_id}` → `{flightId}`
- `{bs_id}` → `{bsId}`
- `{ps_id}` → `{psId}`
- `{hand_id}` → `{handId}`
- `{report_type}` → `{reportType}`

### 예외 (변경 불필요)

- `/health`, `/metrics` — k8s/Prometheus 관행 (`tools/naming_check.exceptions.yaml` 등록)
- `/api/v1` prefix — 마운트 prefix (segment 아님)

### 테스트 수정

`team2-backend/tests/` 내 kebab-case path 참조도 동일 전환:
- `test_flat_endpoints.py`, `test_auth_security.py` 등
- pytest 실행 시 URL match 깨짐 방지

## 수락 기준

- [ ] 17 router 파일 전수 PascalCase 전환
- [ ] path variable snake → camelCase 전환
- [ ] `pytest team2-backend/tests/` 0 errors
- [ ] `tools/naming_check.py --rest --team team2` → 0 violations (예외 제외)
- [ ] team1 실 BO 연결 (`flutter test test/integration/api_e2e_test.dart`) 복원

## 선행 상태

- ✅ PR-0: Naming_Conventions.md v2 확립 (Conductor)
- ✅ PR-5: team1 Freezed `@JsonKey(name: 'camelCase')` (team1, `1c7c834`)
- ✅ PR-5a/5b: team1 Mock + 기획 문서 camelCase (team1)
- ✅ PR-6 (a): team1 ws_dispatch.dart PascalCase (team1, `38a0ed4`)
- ✅ **PR-6b: team1 Repository REST path PascalCase (team1, `ce7a063`)** ← 본 NOTIFY 트리거
- ⏳ **PR-4: team2 Backend router REST path PascalCase** ← team2 작업 대상
- ⏳ PR-2: team2 Pydantic alias_generator=to_camel (별건 NOTIFY `NOTIFY-conductor-B088-PR2bis-service-layer.md`)
- ⏳ PR-3: team2 WS publisher snake→PascalCase event type
- ⏳ PR-7: team4 CC consumer
- ⏳ PR-8: team3 Engine OutputEvent

## 관련

- Master: `docs/4. Operations/Conductor_Backlog/B-088-naming-convention-camelcase-migration.md`
- SSOT: `docs/2. Development/2.5 Shared/Naming_Conventions.md` v2
- team1 선행 commit: `ce7a063 feat(team1): B-088 PR-6b + B-088-B REST path kebab→PascalCase 선제 전환`
- team1 기획 문서: `docs/2. Development/2.1 Frontend/Backlog/B-088-B-team1-docs-rest-path-pascal.md`
