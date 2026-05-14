---
title: Quasar → Flutter 이전 누락 / 매칭 실패 감사
owner: conductor
tier: internal
last-updated: 2026-04-21
audit-scope: team1-frontend
confluence-page-id: 3818619411
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818619411/EBS+Quasar+Flutter
---

# Quasar → Flutter 이전 감사 — 누락 · 매칭 실패 · 기획 drift

## 0. 요약

| 항목 | 건수 | 우선순위 |
|------|:----:|:-------:|
| 누락 screen | 2 | P1 |
| 누락 widget | 4 | P2 |
| 미이식/통합 repository | 3 | P2 |
| WS dispatch 이벤트 규약 drift | 1 계열 | P2 |
| Engineering.md §2.1 디렉토리 구조 drift | 1 대형 | **P1** |
| Engineering.md §4.3 라우트 table drift | 10 라인 | **P1** |
| Engineering.md §5.2 Repository 선언 drift | 3 drift | P2 |
| Engineering.md §6.4 WS dispatch 매핑 drift | 20+ 이벤트 | P2 |
| 총합 | **45+ 아이템** | — |

**판정**: features 디렉토리 수준 (6/6 선언=실측) 은 정렬되어 있으나, **Engineering.md 본문 §2-6 섹션 다수가 Quasar 시대 원본을 그대로 유지 중**. 코드 또한 Quasar 대비 일부 screen / widget / repository 이식 미완.

---

## 1. 감사 베이스라인

- **Quasar archive**: `team1-frontend/_archive-quasar/src-late/`
- **Flutter 실측**: `team1-frontend/lib/`
- **기획 문서 SSOT**: `docs/2. Development/2.1 Frontend/`
- **외부 계약**: `docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md` (180 endpoint), `WebSocket_Events.md`
- **비교 시점**: 2026-04-21 commit `a709b2f` (main)

---

## 2. 코드 누락 감사

### 2.1 Screens (pages) 매핑 매트릭스

| Quasar page | Flutter screen | 상태 |
|-------------|----------------|:----:|
| `LoginPage.vue` | `features/auth/screens/login_screen.dart` | ✅ |
| `ForgotPasswordPage.vue` | `features/auth/screens/forgot_password_screen.dart` | ✅ |
| `SeriesListPage.vue` | `lobby_dashboard_screen.dart` (series selector 통합) | ✅ 통합 |
| `EventListPage.vue` | `lobby_dashboard_screen.dart` (events section 통합) | ✅ 통합 |
| `FlightListPage.vue` | `lobby_dashboard_screen.dart` (active flight 통합) | ✅ 통합 |
| `TableListPage.vue` | `lobby_dashboard_screen.dart` (tables section 통합) | ✅ 통합 |
| `TableDetailPage.vue` | `features/lobby/screens/table_detail_screen.dart` | ✅ |
| **`PlayerListPage.vue`** | **❌ 미이식** | **P1** |
| **`PlayerDetailPage.vue`** | **❌ 미이식** | **P1** |
| `StaffListPage.vue` | `features/staff/screens/staff_list_screen.dart` | ✅ |
| `AuditLogPage.vue` | `features/reports/screens/reports_screen.dart` (4탭 중 session-log) | ✅ 통합 |
| `HandHistoryPage.vue` | `features/reports/screens/reports_screen.dart` (4탭 중 hands-summary) | ✅ 통합 |
| `graphic-editor/GraphicEditorHubPage.vue` | `features/graphic_editor/screens/ge_hub_screen.dart` | ✅ |
| `graphic-editor/GraphicEditorDetailPage.vue` | `features/graphic_editor/screens/ge_detail_screen.dart` | ✅ |
| `settings/OutputsPage.vue` | `features/settings/screens/outputs_screen.dart` | ✅ |
| `settings/GfxPage.vue` | `features/settings/screens/gfx_screen.dart` | ✅ |
| `settings/DisplayPage.vue` | `features/settings/screens/display_screen.dart` | ✅ |
| `settings/RulesPage.vue` | `features/settings/screens/rules_screen.dart` | ✅ |
| `settings/StatsPage.vue` | `features/settings/screens/stats_screen.dart` | ✅ |
| `settings/PreferencesPage.vue` | `features/settings/screens/preferences_screen.dart` | ✅ |
| `settings/SettingsLayout.vue` | `features/settings/screens/settings_layout.dart` | ✅ |
| `NotFoundPage.vue` | `app_router.dart` `errorBuilder: _PlaceholderScreen` | ⚠️ 간소 |
| — | `features/settings/screens/blind_structure_screen.dart` | ✨ 신규 |
| — | `features/settings/screens/prize_structure_screen.dart` | ✨ 신규 |

**P1 누락 2건**: `PlayerListPage` + `PlayerDetailPage`. `player_provider.dart` 는 존재하나 UI 미구현.

### 2.2 Widgets (컴포넌트) 매핑

> **2026-04-21 correction**: 초기 감사에서 3건을 "미이식" 으로 판정했으나 실측 재확인 결과 commit `70d6d7a` (2026-04-16 Flutter 전면 전환) 이미 포함. audit 스크립트의 false positive. 아래 표는 정정된 최종 상태.

| Quasar component | Flutter widget | 상태 |
|------------------|----------------|:----:|
| `common/EmptyState.vue` | `foundation/widgets/empty_state.dart` | ✅ |
| `common/ErrorBanner.vue` | `foundation/widgets/error_banner.dart` | ✅ |
| `common/LoadingState.vue` | `foundation/widgets/loading_state.dart` | ✅ |
| `common/WsDisconnectBanner.vue` | `foundation/widgets/ws_disconnect_banner.dart` | ✅ (70d6d7a 기존) |
| `event/EventFormDialog.vue` | `features/lobby/widgets/event_form_dialog.dart` | ✅ (70d6d7a 기존) |
| `table/TableFormDialog.vue` | `features/lobby/widgets/table_form_dialog.dart` | ✅ (70d6d7a 기존) |
| `staff/UserFormDialog.vue` | `features/staff/widgets/user_form_dialog.dart` | ✅ |
| `table/AddPlayerDialog.vue` | `features/lobby/widgets/add_player_dialog.dart` | ✅ |
| `table/DayTabs.vue` | `features/lobby/widgets/day_tabs.dart` | ✅ (2026-04-21 eventFlightId 정렬) |
| `table/SeatGrid.vue` | `features/lobby/widgets/seat_grid.dart` | ✅ |
| `hand-history/HandDetail.vue` | `features/reports/widgets/hand_detail.dart` | ✨ **신규 (B-087-3)** |

**Widgets 상태**: 11/11 모두 이식 완료. B-087-3 DONE.

**audit false positive 교훈**: 초기 `find` 명령어가 feature 별 widgets/ 디렉토리를 완전 순회하지 않아 3건 widget 누락으로 오판. 후속 audit 에는 `git ls-files team1-frontend/lib/features/*/widgets/*.dart` 전수 비교 필수.

### 2.3 Repositories 매핑

| Quasar api client | Flutter repository | 상태 |
|-------------------|---------------------|:----:|
| `auth.ts` | `auth_repository.dart` | ✅ |
| `audit-logs.ts` | `audit_log_repository.dart` | ✅ |
| `competitions.ts` | `competition_repository.dart` | ✅ |
| `configs.ts` | `settings_repository.dart` (rename) | ✅ |
| `events.ts` | `event_repository.dart` | ✅ |
| `flights.ts` | `flight_repository.dart` | ✅ |
| `hands.ts` | `hand_repository.dart` | ✅ |
| `players.ts` | `player_repository.dart` | ✅ |
| `reports.ts` | `report_repository.dart` | ✅ |
| `series.ts` | `series_repository.dart` | ✅ |
| `skins.ts` | `skin_repository.dart` | ✅ |
| `tables.ts` | `table_repository.dart` | ✅ (seat endpoints 통합) |
| `users.ts` | `staff_repository.dart` (rename) | ✅ |
| `client.ts` (axios 래퍼) | `data/remote/bo_api_client.dart` | ✅ |
| — | `payout_structure_repository.dart` | ✨ 신규 |
| **`blind-structures.ts`** | **❌ 미이식** | **P2** (Engineering.md §5.2 선언됨, 파일 없음) |
| **`blind-structure-levels.ts`** | **❌ 미이식** | **P2** |
| **`seats.ts`** | **⚠️ table_repository 에 통합?** | 확인 필요 |
| **`sync.ts`** | **❌ 미이식** | **P3** (WSOP LIVE 폴링 — Backend 가 담당이면 불필요) |

### 2.4 WebSocket dispatch 이벤트 규약 drift

**기획 SSOT**: `WebSocket_Events.md §1` "**type**: string, PascalCase".

**실제 코드 `lib/data/remote/ws_dispatch.dart`** — 25+ switch case:
- snake_case: `series.updated`, `table_status_changed`, `hand_started`, `player_moved`, `config_changed`, `skin.updated`...
- 일부는 도트 케이스 (`series.updated`) — 이것도 기획 PascalCase 와 불일치

**BO 정의 이벤트 (7개, CC-centric)**:
`HandStarted`, `HandEnded`, `ActionPerformed`, `CardDetected`, `GameChanged`, `RfidStatusChanged`, `OutputStatusChanged`

**Lobby 실제 처리 이벤트 (25+)**: 대부분 CRUD 미러 (series.*, event.*, flight.*, table.*, player.*). 기획 문서에 명시적으로 정의되지 않음.

**판정**:
- **규약 drift**: PascalCase 기획 vs snake_case/dot-case 구현. 양쪽 모두 작동하나 계약 표기 일치 필요.
- **이벤트 정의 gap**: Lobby 가 실제 구독 중인 CRUD mirror 이벤트 (series.created 등) 가 `WebSocket_Events.md` 에 미정의. team2 publisher 와 합의 필요.

---

## 3. 기획 문서 drift 감사

### 3.1 Engineering.md §2.1 (디렉토리 구조) — **CRITICAL**

**선언**:
```
features/{auth, lobby, player, settings_output, settings_gfx, settings_display, settings_rules, graphic_editor} (8개)
repositories/{auth, series, event, flight, table, seat, player, hand, config, skin, blind_structure} (11개)
data/remote/{dio_client, lobby_ws_client}
```

**실측**:
```
features/{auth, lobby, settings, graphic_editor, staff, reports} (6개)
repositories/ 14개 (settings/staff/payout_structure/audit_log/report + 기존 9)
data/remote/{bo_api_client, lobby_websocket_client, ws_dispatch}
```

**drift 요약**:
- Settings 4 분할 → 단일 settings 통합 (변경)
- Player 독립 feature → lobby 하위 서브뷰 (결정 반영 완료)
- Staff/Reports 신규 feature 선언 누락
- Repository 수 11 → 14 (payout_structure 신규, staff 신규, audit_log 신규, settings rename, seat 누락)
- 파일명 `dio_client` → `bo_api_client`, `lobby_ws_client` → `lobby_websocket_client`

### 3.2 Engineering.md §4.3 (라우트 table) — **CRITICAL**

**선언 14 routes**:
`/login`, `/`, `/series`, `/series/:id/events`, `/series/:sid/events/:eid/flights`, `/series/:sid/events/:eid/flights/:fid/tables`, `/tables/:id`, `/players`, `/players/:id`, `/settings/outputs`, `/settings/gfx`, `/settings/display`, `/settings/rules`, `/graphic-editor`

**실측 9 routes (`app_router.dart`)**:
`/login`, `/forgot-password`, `/lobby`, `/tables/:tableId`, `/staff`, `/settings/:section` (dynamic), `/graphic-editor`, `/graphic-editor/:skinId`, `/reports/:type`

**drift**:
- Series/Event/Flight 3단계 드릴다운 → 단일 `/lobby` 대시보드로 통합 (설계 변경)
- `/players`, `/players/:id` 미구현 (Player 독립 UI 없음)
- Settings 4개 하드코딩 path → 단일 dynamic `/settings/:section`
- `/staff`, `/reports/:type`, `/graphic-editor/:skinId`, `/forgot-password` 선언 누락

### 3.3 Engineering.md §5.2 Repository 매핑 — P2

선언 11 vs 실측 14. `SeatRepository` 선언만 되어 있고 파일 없음 (table_repository 에 통합 가정).

### 3.4 Engineering.md §6.4 WS dispatch 매핑 — P2

선언 5 이벤트 카테고리 (series.*/table.detail.*/player.*/hand.*/config.*) vs 실측 25+ 이벤트. drift 큼.

### 3.5 CLAUDE.md §"아키텍처" features 트리

2026-04-21 commit `a709b2f` 에서 이미 실측 정렬 완료 (6/6). ✅

---

## 4. 수정 계획 (우선순위별)

### P1 — 즉시 수정 필요 (기획 SSOT 오염)

| ID | 작업 | 대상 파일 | 예상 규모 |
|----|------|----------|:---------:|
| B-078 | Engineering.md §2.1 디렉토리 구조 실측 재작성 | `docs/2. Development/2.1 Frontend/Engineering.md` | M |
| B-079 | Engineering.md §4.3 라우트 table 실측 재작성 | 동상 | M |
| B-080 | Player UI 구현 결정 | `PlayerListPage` / `PlayerDetailPage` Flutter 이식 OR "lobby 하위 통합 완결" 선언 | L |

### P2 — 후속 정리

| ID | 작업 | 대상 | 예상 규모 |
|----|------|------|:---------:|
| B-081 | Engineering.md §5.2 Repository 매핑 갱신 + SeatRepository 통합 명시 | Engineering.md | S |
| B-082 | Engineering.md §6.4 WS dispatch 매핑 실측 정렬 + PascalCase vs snake_case 규약 결정 | Engineering.md + WebSocket_Events.md (team2 publisher 합의) | M |
| B-083 | 누락 widget 이식 (WsDisconnectBanner / EventFormDialog / TableFormDialog / HandDetail 필요성 판정 후 구현 or Backlog close) | `lib/foundation/widgets/`, `lib/features/*/widgets/` | M |
| B-084 | BlindStructure / BlindStructureLevel Repository 분리 결정 (settings_repository 통합 유지 or 분리) | `lib/repositories/` | S |

### P3 — 관찰 (즉시 조치 불필요)

| ID | 작업 | 사유 |
|----|------|------|
| B-085 | `sync.ts` → Flutter sync_repository 미이식 | WSOP LIVE 폴링은 Backend 담당. Frontend 는 /api 소비만 해도 충분. "기획 의도 재확인 후 B-085 close or activate" |

---

## 5. Notify

- **team2**: WS 이벤트 타입 네이밍 규약 (PascalCase vs snake_case/dot-case) 결정 — `WebSocket_Events.md §1` 강화 필요
- **conductor**: Engineering.md (team1 소유) 대규모 drift 수정은 team1 내부 처리. 단 본 audit report 는 `docs/4. Operations/Reports/` 에 Conductor 영역으로 기록

---

## 6. 관련

- 선행 commit: `2cc13b1` (Flutter 단일 스택 확정), `a709b2f` (INDEX.md + features 정렬)
- 기획 SSOT: `docs/2. Development/2.1 Frontend/Engineering.md`
- Quasar archive: `team1-frontend/_archive-quasar/src-late/`
- 백로그 디렉토리: `docs/2. Development/2.1 Frontend/Backlog/`
