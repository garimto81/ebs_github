---
title: Engineering — Frontend (Flutter)
owner: team1
tier: internal
last-updated: 2026-04-22
reimplementability: UNKNOWN
reimplementability_checked: 2026-04-22
reimplementability_notes: "Foundation.md 2026-04-22 재설계 반영 (B-T1-FND-01) — §1.5 설치 관점(Ch.4 §4.4) + §2.0 런타임 모드(§5.0) + §2.2 프로세스 경계(§6.3) + §6.0 실시간 동기화(§6.4) 신설. 재검증 후 PASS 재판정."
---

# Engineering — Frontend (Flutter)

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-22 | Foundation 재설계 반영 (B-T1-FND-01) | §1.5 설치 관점(Ch.4 §4.4), §2.0 런타임 모드(§5.0), §2.2 프로세스 경계(§6.3), §6.0 실시간 동기화(§6.4) 신설 |
| 2026-04-21 | features 정렬 완료 | 선언 8 → 실측 6 일치. players → lobby 통합, audit_log + hand_history → reports 통합. CLAUDE.md §아키텍처 동기화 |
| 2026-04-20 | Conductor audit | SG-001 resolution 반영 + features 실측/선언 공백 §0 명시 |
| 2026-04-16 | Flutter 전환 | Quasar→Flutter 전면 재작성. Riverpod+Freezed+Dio+go_router+rive |
| 2026-04-15 | (이전) | Quasar/Vue 3 아키텍처 최종본 — §12 아카이브 참조 |

---

## 0. features 선언 vs 실측 정렬 (2026-04-21 resolved)

### 0.1 최종 상태 (6 feature)

team1 CLAUDE.md §"아키텍처" 와 `team1-frontend/lib/features/` 가 완전 일치:

```
auth / lobby / settings / graphic_editor / staff / reports
```

| Feature | 역할 | 관련 기획 |
|---------|------|-----------|
| `auth` | 로그인 + 2FA StateNotifier | `Login/` |
| `lobby` | Series→Event→Flight→Table 드릴다운 + **Player 관리 서브뷰** | `Lobby/` |
| `settings` | 6탭 (Outputs / GFX / Display / Rules / Statistics / Preferences) | `Settings/` |
| `graphic_editor` | `.gfskin` 허브 + Rive 프리뷰 (Flutter rive ^0.13) | `Graphic_Editor/` |
| `staff` | 운영자 관리 (RBAC 3역할) | BS-01 Authentication |
| `reports` | **Hand History + Audit Log 뷰어** (읽기 전용, BO DB 소비) | API-01 §Hands + §Audit |

### 0.2 이관 매핑 (과거 선언 → 현재 통합)

2026-04-20 audit 에서 발견된 선언/실측 공백 3건이 아래와 같이 해소됨:

| 과거 선언 | 최종 위치 | 사유 |
|----------|----------|------|
| `players` | `lobby/` 하위 서브뷰 | Player 관리는 Lobby 드릴다운의 독립 레이어 (`Lobby/UI.md` §5 Player 독립 레이어 참조). 별도 feature 디렉토리 불필요 — Lobby 라우트 내부에서 Series/Event 와 직교 |
| `audit_log` | `reports/` 통합 | BO 가 감사 로그 SSOT. team1 은 읽기 전용 뷰만 제공 → reports 하위 탭으로 통합 자연 |
| `hand_history` | `reports/` 통합 | 핸드 기록도 읽기 전용 뷰어 성격. reports 하위 탭으로 통합 — 공통 페이지네이션/필터/Export UX |

### 0.3 결정 근거

- **"feature 디렉토리 = 독립 라우트"** 원칙 유지. 읽기 전용 뷰 3개 (players/audit_log/hand_history) 를 각각 feature 로 만들면 의미 중복.
- `reports` feature 하위에 탭 구조로 hand_history + audit_log 배치가 Material3 `DefaultTabController` 로 즉시 구현 가능.
- Player 관리는 Lobby 드릴다운 맥락 강함 (Series/Event/Flight 선택 후 Player 배치) → Lobby 하위가 맥락 보존.

### 0.4 영향 받은 문서

- `team1-frontend/CLAUDE.md §"아키텍처"` 선언 목록 6개로 재작성
- `team1-frontend/INDEX.md` 전면 Flutter v10 재작성 (Quasar 경로 참조 제거)
- 본 Engineering.md frontmatter `reimplementability: UNKNOWN → PASS`
- `Roadmap.md §"2.1 Frontend"` 의 "features 미정렬" 라인 — Conductor 세션이 resolved 반영 후속

관련 SG: 없음 (team1 내부 결정, 공식 spec_gap 승격 불필요).

---

## 1. 기술 스택

| 영역 | 선정 | 버전 | 근거 |
|------|------|:----:|------|
| Framework | **Flutter** (Windows desktop) | `^3.29` | team4 CC 와 스택 통일, 크로스 플랫폼 |
| Language | **Dart** (strict analysis) | `^3.7` | Flutter 네이티브, null-safety |
| State | **Riverpod** (`flutter_riverpod`) | `^2.6` | 컴파일 타임 안전, Provider 트리 독립, 테스트 용이 |
| Code-gen | **Freezed** + `json_serializable` | `^2.5` | immutable 모델 + `fromJson`/`toJson` 자동 생성 |
| HTTP | **Dio** | `^5.7` | interceptor 체이닝(Idempotency, Auth refresh) |
| Router | **go_router** | `^14.6` | 선언적 라우팅, redirect guard, ShellRoute |
| WebSocket | `web_socket_channel` + 커스텀 래퍼 | `^3.0` | seq 검증 직접 제어, reconnect 로직 |
| Rive preview | **`rive`** (flutter) | `^0.13` | CCR-011 GE 프리뷰 (`.gfskin` artboard 렌더) |
| i18n | `flutter_localizations` + `intl` | — | ARB 기반 3 locale (ko/en/es) |
| Testing | `flutter_test` + `mocktail` | — | 단위/위젯 테스트 |
| Lint | `flutter_lints` + `custom_lint` | — | `analysis_options.yaml` strict |
| Shared | **ebs_common** (path dep) | — | CCR-017/019/021 공용 유틸 |

---

## 1.5 설치 관점 (Foundation Ch.4 §4.4)

Foundation §4.4 는 EBS 시스템을 **기능 6개 ↔ 설치 3 소프트웨어 + 1 하드웨어** 두 렌즈로 구분한다. team1 관점 핵심 사실:

| 구분 | 내용 |
|------|------|
| **설치 단위** | `EBS Desktop App` — 로비 + 커맨드 센터 + 오버레이 뷰 3 기능의 **단일 Flutter 바이너리** |
| **팀 소유** | team1 (Lobby/Settings/Graphic Editor) + team4 (CC/Overlay) **공동 소유** |
| **빌드 산출물** | 동일 바이너리. 팀별 코드는 `team1-frontend/` / `team4-cc/` 로 분리되지만 배포 시 하나의 앱으로 묶임 |
| **런타임 모드** | 이 단일 바이너리가 두 가지 런타임 모드 중 하나로 동작 — §2.0 참조 |

**개발 규약**:
- team1/team4 코드는 feature 디렉토리 경계로만 분리. 공통 의존성은 `ebs_common` (§10)
- 빌드·릴리즈는 conductor 세션이 통합 수행 (`docs/4. Operations/Docker_Runtime.md` §3)

---

## 2. 아키텍처 개요

team4 CC 패턴과 동일한 feature-based 디렉토리 구조를 따른다.

```mermaid
flowchart LR
    A[lib/] --> B[data/]
    A --> C[features/]
    A --> D[models/]
    A --> E[repositories/]
    A --> F[foundation/]
```

### 2.0 런타임 모드 (Foundation §5.0)

단일 Flutter 바이너리가 두 가지 런타임 모드 중 하나로 실행된다. Lobby Settings → Preferences 에서 Admin 이 선택 (`Settings/Preferences.md §11`).

| 모드 | 용도 | 프로세스 모델 |
|------|------|--------------|
| **탭/슬라이딩 (기본)** | 소형 화면, 단일 운영자, 향후 태블릿 폼팩터 | 단일 Flutter 프로세스 내 Lobby/CC/Overlay 라우팅 전환 |
| **다중창 (PC 옵션)** | Desktop 멀티 모니터, 역할 분리 환경 | Lobby/CC/Overlay 각각 **독립 OS 프로세스** |

**구현 선택**:

- **탭 모드 (기본)**: `go_router` + `IndexedStack` 기반 라우팅 전환. 상태 유지 (Riverpod). 추가 의존성 없음
- **다중창 모드**: **`window_manager` ^0.4** (pub.dev, Flutter 3.x 지원). 각 창은 별도 `runApp` entrypoint 로 spawn. IPC 금지 — 모든 통신은 BO 경유 (§2.2)

**모드 전환 시 app restart 필수** (프로세스 모델이 근본 차이). `preferences.runtime_mode` 변경 → 재시작 안내 다이얼로그 → 사용자 재시작.

**Fallback**: Linux headless / Web(Chrome) 런타임에서는 탭 모드 강제. Preferences UI 에서 다중창 선택지 비활성화 (`window_manager.isSupported` 체크).

### 2.2 프로세스 경계 및 IPC 금지 (Foundation §6.3)

Foundation §6.3 은 **앱 간 직접 IPC 금지** 를 명문화한다. 다중창 모드에서 각 앱은 별개 OS 프로세스이나 shared memory / 파이프 / 소켓으로 직접 통신하지 않는다.

| 경로 | 허용 | 근거 |
|------|:----:|------|
| Lobby → BO REST (API-01) | ✅ | 동기 CRUD |
| Lobby ← BO WebSocket (`/ws/lobby`) | ✅ | 모니터링 전용 |
| CC ↔ BO WebSocket (`/ws/cc`) | ✅ | 양방향 명령·이벤트 |
| CC → Engine REST | ✅ | stateless query |
| **Lobby ↔ CC 직접 IPC** | ❌ | **금지** — BO DB 경유 |
| **Lobby ↔ Overlay 직접 IPC** | ❌ | **금지** — BO DB 경유 |

**일관성 원리**: 모든 상태 변경은 BO DB 에 commit 되고, BO WS broadcast 가 관련 앱에 전파된다. 자세한 2채널 동기화 모델은 §6.0.

### 2.1 디렉토리 구조 (2026-04-21 실측 재작성)

```
team1-frontend/lib/
├── main.dart
├── app.dart                            # MaterialApp.router + ProviderScope
├── data/
│   ├── remote/
│   │   ├── bo_api_client.dart          # Dio + Idempotency + Auth refresh interceptor
│   │   ├── lobby_websocket_client.dart # WS + seq 단조증가 + replay
│   │   └── ws_dispatch.dart            # 중앙 이벤트 라우터 (25+ 이벤트)
│   └── local/
│       ├── mock_dio_adapter.dart       # MockDioAdapter (개발용)
│       └── mock_data.dart              # 10 competitions / 10 flights / 20 tables / 100 players fixture
├── features/                           # 7 feature (2026-04-21 Players 독립 레이어 추가)
│   ├── auth/                           # login_screen + forgot_password + auth_provider
│   ├── lobby/                          # lobby_dashboard (series/event/flight/table 통합 드릴다운) + table_detail
│   ├── players/                        # players_screen + player_detail_dialog (Lobby/UI.md §화면 4 독립 레이어)
│   ├── settings/                       # 8 screens (blind_structure / prize_structure / outputs / gfx / display / rules / stats / preferences + layout)
│   ├── graphic_editor/                 # ge_hub + ge_detail + rive_preview (rive ^0.13)
│   ├── staff/                          # staff_list + user_form_dialog
│   └── reports/                        # reports_screen (4탭: hands-summary / player-stats / session-log / table-activity — hand_history + audit_log 통합)
├── models/entities/                    # 19 @freezed entities
│   ├── series / ebs_event / event_flight / table / table_seat
│   ├── player / session_user / user / staff
│   ├── hand / hand_player / hand_action
│   ├── config / skin / skin_metadata
│   ├── blind_structure / blind_structure_level
│   ├── competition / audit_log / output_preset
│   └── (각 entity 당 .freezed.dart + .g.dart 자동 생성)
├── repositories/                       # 14 Repository (API-01 계약 소비)
│   ├── auth / competition / series / event / flight
│   ├── table (seat endpoints 통합) / player / hand
│   ├── settings (configs rename) / skin / staff (users rename)
│   ├── audit_log / report / payout_structure
│   └── (blind_structure 는 settings_repository 에 통합 — B-084 재평가 대상)
├── foundation/
│   ├── theme/ebs_theme.dart            # Material3 dark (team4 기반 동일 colorSchemeSeed)
│   ├── router/app_router.dart          # go_router 9 routes (§4.3)
│   ├── i18n/ (+ resources/l10n/)       # ARB 3 locale (ko/en/es, 231 keys)
│   ├── configs/env_config.dart         # --dart-define 환경변수
│   └── widgets/                        # empty_state / error_banner / loading_state 등 공통
└── resources/l10n/                     # app_{ko,en,es}.arb
```

**이전 설계와의 차이** (Quasar 시대 원안 대비):
- Settings 4 분할 (`settings_output/settings_gfx/settings_display/settings_rules`) → 단일 `settings/` 통합
- `player/` 독립 feature → `lobby/` 하위 서브뷰 (드릴다운 맥락 보존)
- `staff/`, `reports/` 신규 feature (Quasar → Flutter 이전 중 분리)
- 파일명: `dio_client` → `bo_api_client`, `lobby_ws_client` → `lobby_websocket_client`
- Repository 11 → 14 (staff/audit_log/report/payout_structure 신규, settings rename, seat 통합)

---

## 3. 상태 관리 — Riverpod

### 3.1 Provider 패턴

| 패턴 | 용도 | 예시 |
|------|------|------|
| `StateNotifierProvider` | stateful feature | `authProvider`, `lobbyListProvider`, `settingsProvider`, `geProvider` |
| `StateProvider` | 단순 선택값 | `navBreadcrumbProvider` (현재 Series → Event → … 경로) |
| `Provider.family` | 파라미터 목록 | `eventsBySeriesProvider(seriesId)`, `tablesByFlightProvider(flightId)` |
| `Provider` | 싱글턴 의존성 | `dioClientProvider`, `wsClientProvider` |

### 3.2 WS dispatch 패턴

WebSocket 이벤트는 중앙 라우터(`ws_dispatch.dart`)가 수신 후 해당 StateNotifier 에 분배한다.

```mermaid
flowchart LR
    WS[lobby_ws_client] --> D[ws_dispatch]
    D --> L[lobbyListNotifier]
    D --> T[tableDetailNotifier]
    D --> P[playerNotifier]
```

### 3.3 초기화 순서

```mermaid
flowchart LR
    A[main.dart] --> B[ProviderScope]
    B --> C[authProvider<br/>login/token]
    C --> D[dioClient<br/>interceptors]
    D --> E[wsClient<br/>connect]
    E --> F[ws_dispatch<br/>subscribe]
```

---

## 4. 라우팅 — go_router

### 4.1 Auth redirect guard

`redirect` 콜백에서 `authProvider` 상태 확인. 미인증이면 `/Login` 으로 리디렉트, 인증 후 원래 경로 복원.

### 4.2 ShellRoute + NavigationRail

`ShellRoute` 내부에 좌측 `NavigationRail` 배치. 하위 경로 전환 시 Rail 유지.

### 4.3 Route table (14 routes)

### 4.3 Route table (10 routes, 2026-04-21 실측 — Players 추가)

| # | Path | Feature | Builder | 비고 |
|---|------|---------|---------|------|
| 1 | `/Login` | auth | `LoginScreen` | 미인증 진입점. `redirect` 로 로그인 후 원래 경로 복원 |
| 2 | `/ForgotPassword` | auth | `ForgotPasswordScreen` | 비밀번호 초기화 플로우 |
| 3 | `/Lobby` | lobby | `LobbyDashboardScreen` | **단일 대시보드** — Series selector + Events + Tables 3 section 통합 (이전 `/Series`, `/Series/:id/events`, `/Flights`, `/Tables` 드릴다운 라우트를 단일 화면 state 로 통합) |
| 4 | `/Tables/:tableId` | lobby | `TableDetailScreen` | Table 상세 (SeatGrid) |
| 5 | `/Players` | players | `PlayersScreen` | **독립 레이어** — Player DataTable + 검색 + Status filter + 상세 dialog. `Lobby/UI.md §화면 4` 스펙 |
| 6 | `/Staff` | staff | `StaffListScreen` | 운영자 관리 |
| 6 | `/Settings` → `/Settings/BlindStructure` | settings | redirect | Settings 진입 시 기본 탭 |
| 7 | `/Settings/:section` | settings | `SettingsLayout(section:)` | dynamic section 파라미터. 허용 값: `blind-structure / prize-structure / outputs / gfx / display / rules / stats / preferences` (8 탭) |
| 8 | `/GraphicEditor` | graphic_editor | `GeHubScreen` | `.gfskin` 허브 |
| 9 | `/GraphicEditor/:skinId` | graphic_editor | `GeDetailScreen` | 스킨 상세 편집 |
| 10 | `/Reports` → `/Reports/HandsSummary` | reports | redirect | Reports 진입 시 기본 탭 |
| 11 | `/Reports/:type` | reports | `ReportsScreen(reportType:)` | dynamic type 파라미터. 허용 값: `hands-summary / player-stats / session-log / table-activity` (4탭) |

**이전 설계와의 차이** (Quasar 시대 14 routes 대비):
- Series/Event/Flight 3단계 드릴다운 (4 routes) → 단일 `/Lobby` 대시보드 내부 state 로 통합 (UX 단순화 결정)
- `/Players` — **2026-04-21 구현** (`Lobby/UI.md §화면 4 독립 레이어` 준수). 상세는 dialog (별도 라우트 없음)
- Settings 4 하드코딩 path → 단일 dynamic `/Settings/:section`
- `/ForgotPassword`, `/Staff`, `/Reports/:type`, `/GraphicEditor/:skinId` 추가 (Quasar 이후 신규 화면)
- `errorBuilder: _PlaceholderScreen(title: '404 Not Found')` — 간소화된 NotFound 처리 (Quasar `NotFoundPage.vue` 의 경량 대체)

---

## 5. API 클라이언트 — Dio

### 5.1 Interceptor 체인

```mermaid
flowchart LR
    REQ[Request] --> I1[IdempotencyInterceptor<br/>CCR-019]
    I1 --> I2[AuthInterceptor<br/>Bearer token]
    I2 --> DIO[Dio execute]
    DIO --> R1[401 감지]
    R1 --> R2[refresh token retry]
```

**IdempotencyInterceptor (CCR-019)**: POST/PUT/PATCH 요청에 `Idempotency-Key: {UUID v4}` 헤더 자동 주입. `UuidIdempotency` 는 `ebs_common` 패키지에서 제공.

**AuthInterceptor**: `Authorization: Bearer {token}` 주입. 401 응답 시 refresh token 으로 재발급 → 원래 요청 재시도. refresh 실패 시 `/Login` 으로 리디렉트. 무한 루프 방지를 위해 refresh 요청 자체에는 interceptor 미적용.

### 5.2 Repository 매핑 (14 classes, 2026-04-21 실측)

| Repository | Base path | 주요 메서드 | 비고 |
|------------|-----------|------------|------|
| `AuthRepository` | `/Auth` | `login`, `refresh`, `logout`, `verify2FA` | |
| `CompetitionRepository` | `/Competitions` | `list`, `get` | 신규 (Quasar api 이식) |
| `SeriesRepository` | `/Series` | `list`, `get`, `create`, `update`, `delete` | |
| `EventRepository` | `/Series/:id/events`, `/Events/:id` | `list`, `get`, `create`, `update` | |
| `FlightRepository` | `/Events/:id/flights`, `/Flights/:id` | `list`, `get`, `create`, `update` | |
| `TableRepository` | `/Tables`, `/Flights/:id/tables`, `/Tables/:id/seats` | `list` (flight_id query), `get`, `create`, `update`, `updateStatus`, `listSeats`, `seatPlayer`, `unseatPlayer`, `launchCc`, `rebalance` | **SeatRepository 통합** — Seat endpoints 를 테이블 맥락에서 노출 |
| `PlayerRepository` | `/Players` | `list`, `get`, `create`, `update`, `search` | UI 미구현 (B-080) |
| `HandRepository` | `/Tables/:id/hands`, `/Hands/:id` | `list`, `current`, `get` | |
| `SettingsRepository` | `/Configs` | `get`, `update` (scope: series/event/table/global) | `ConfigRepository` rename |
| `SkinRepository` | `/Skins` | `list`, `get`, `uploadSkin`, `activate`, `delete`, `updateMetadata` | Graphic Editor 소비 |
| `StaffRepository` | `/Users` | `list`, `get`, `create`, `update`, `delete` | `UsersRepository` rename |
| `AuditLogRepository` | `/AuditLogs` | `list` (filter: actor/action/date) | Reports 소비 |
| `ReportRepository` | `/Reports/{hands-summary/PlayerStats/SessionLog/table-activity}` | `getReport(type, filter)`, `exportCsv(type, filter)` | 4탭 통합 |
| `PayoutStructureRepository` | `/PayoutStructures` | `list`, `get`, `create`, `update` | 신규 |

**미구현 / 통합 결정**:
- **BlindStructureRepository** — settings_repository 에 통합 (`blind_structure_screen.dart` 가 settings_provider 경유 접근). 분리 재평가 B-084.
- **SeatRepository** — `TableRepository` 의 seat* 메서드로 통합 (별도 파일 없음).
- **SyncRepository** — Backend (team2) 가 WSOP LIVE 폴링 담당. Frontend 미이식. B-085 관찰.

---

## 6. WebSocket 및 실시간 동기화

### 6.0 DB polling + WS push 2채널 모델 (Foundation §6.4, SG-002 해소)

Foundation §6.4 는 **DB 를 단일 진실(SSOT)** 로 두고, 두 가지 채널로 동기화를 수행한다:

| 채널 | 용도 | 지연 |
|------|------|:----:|
| DB polling (REST GET) | 복구/재진입 시 baseline snapshot | 1-5초 |
| WebSocket push (`/ws/lobby`) | 실시간 상태 변경 알림 | < 100ms |

**Lobby 정책**:

- **쓰기** — 상태 변경은 Lobby → BO REST (PUT/POST). BO 가 DB commit 후 WS broadcast
- **읽기 (초기)** — 앱 시작 시 REST GET 으로 DB snapshot 로드 (Series/Event/Flight/Table/Player/Config)
- **읽기 (실시간)** — 이후 WS push 로 델타 적용 (series.*, event.*, flight.*, table.*, player.*, config.*)
- **crash 복구** — 프로세스 재시작 시 DB snapshot 재로드 (이전 상태 복원) + WS reconnect → `/ws/replay?from_seq=N` 으로 누락분 수신
- **Engine SSOT** — 게임 상태(hands/cards/pots)는 Engine 응답이 최종 SSOT. Lobby 는 BO 를 통해 간접 구독 (직접 Engine 호출 없음)

**적용 모드 차이** (§2.0 런타임 모드 연동):

- **다중창 모드** — 각 프로세스 독립적으로 DB snapshot 로드 + WS 구독
- **탭 모드** — 단일 프로세스 in-memory state 1차. DB 는 재시작 복구용

> **⚠ DB polling endpoint 실제 스키마는 team2 SSOT**. Foundation §6.4 는 정책 선언, team2 가 Wave 2 에서 `docs/2. Development/2.2 Backend/APIs/` 에 발행. 본 섹션은 Lobby 관점 소비 패턴만 기술.

### 6.1 연결

읽기 전용 `/Ws/Lobby`. 모니터링 이벤트만 수신 (write 명령 없음).

### 6.2 SeqTracker gap 감지 (CCR-021)

수신 메시지마다 `seq` 필드를 `SeqTracker` (ebs_common) 로 검증. gap 감지 시 `/Ws/replay?from_seq=N` 으로 누락분 요청.

### 6.3 Reconnect

Exponential backoff: 1s → 2s → 4s → 8s → 16s (max). 연결 복구 시 마지막 `seq` 부터 replay.

### 6.4 ws_dispatch 라우팅

| 이벤트 타입 | 수신자 |
|------------|--------|
| `series.*`, `event.*`, `flight.*`, `table.*` | `lobbyListNotifier` |
| `table.detail.*`, `seat.*` | `tableDetailNotifier` |
| `player.*` | `playerNotifier` |
| `hand.*` | `handNotifier` |
| `config.*` | `settingsNotifier` |

---

## 7. Mock 서버 — MockDioAdapter

### 7.1 구현 방식

Dio 의 `HttpClientAdapter` 를 구현한 `MockDioAdapter`. 요청 URL + method 패턴 매칭으로 JSON 응답 반환.

### 7.2 토글

`--dart-define=USE_MOCK=true` (기본값: development). `env_config.dart` 에서 분기:

```dart
final useMock = const bool.fromEnvironment('USE_MOCK', defaultValue: true);
```

### 7.3 데이터 소스

기존 Quasar MSW `data.ts`/`handlers.ts` 의 fixture 데이터를 Dart 로 포팅. `test/fixtures/` 에 JSON 파일로 관리.

---

## 8. 국제화 — flutter_localizations + intl

| 항목 | 값 |
|------|-----|
| 기본 locale | `ko` |
| 지원 locale | `ko`, `en` (Vegas), `es` (Vegas sub) |
| 키 수 | 231 (기존 vue-i18n 동일) |
| 형식 | ARB (`app_{locale}.arb`) |
| 설정 | `l10n.yaml` — `arb-dir: lib/foundation/i18n`, `output-class: AppLocalizations` |

`flutter gen-l10n` 으로 타입 안전 접근자 자동 생성.

---

## 9. 테마 — Material3 Dark

team4 CC `ebs_theme` 패키지를 기반으로 동일 color scheme 적용.

| 속성 | 값 |
|------|-----|
| `useMaterial3` | `true` |
| `brightness` | `Brightness.dark` |
| `colorSchemeSeed` | team4 와 동일 primary seed |
| Typography | `GoogleFonts.notoSansKr` (한글) + `Roboto` (영문) |

`foundation/theme/ebs_theme.dart` 에 정의. `ebs_common` 에 공유 색상 상수를 두고 두 앱이 참조.

---

## 10. Shared Package — ebs_common

`../Shared/ebs_common` path dependency. team1 + team4 공용.

| 모듈 | CCR | 역할 |
|------|-----|------|
| `permission.dart` | CCR-017 | `Role` enum + `hasPermission()` 헬퍼 |
| `uuid_idempotency.dart` | CCR-019 | Dio interceptor 용 UUID v4 생성 |
| `seq_tracker.dart` | CCR-021 | WebSocket seq 단조증가 검증 + gap 감지 |
| `ebs_colors.dart` | — | 공용 색상 상수 |

```yaml
# team1-frontend/pubspec.yaml
dependencies:
  ebs_common:
    path: ../Shared/ebs_common
```

---

## 11. 빌드 & 테스트

```bash
# 의존성
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# 정적 분석
flutter analyze

# 테스트
flutter test

# 개발 실행 (Windows)
flutter run -d windows

# 프로덕션 빌드
flutter build windows --release
```

**커밋 전 필수**: `flutter analyze && flutter test` 통과.

**환경 변수** (`--dart-define`):

| 키 | 개발 기본값 | 프로덕션 |
|----|-----------|---------|
| `EBS_BO_HOST` | (미설정 → localhost) | LAN IP 주입 |
| `EBS_BO_PORT` | `8000` | 배포 시점 주입 |
| `USE_MOCK` | `false` | `false` |
| `API_BASE_URL` | `http://localhost:8000/api/v1` | fallback (호스트 미설정 시) |
| `WS_BASE_URL` | `ws://localhost:8000` | fallback (호스트 미설정 시) |

### 네트워크 배포

| 시나리오 | 명령 |
|----------|------|
| 개발 (localhost) | `flutter run -d windows` |
| LAN | `flutter run -d windows --dart-define=EBS_BO_HOST=192.168.1.100` |
| 빌드 (LAN) | `flutter build windows --release --dart-define=EBS_BO_HOST=192.168.1.100` |
| 커스텀 | `flutter run -d windows --dart-define=API_BASE_URL=http://host:port/api/v1 --dart-define=WS_BASE_URL=ws://host:port` |

---

## 12. 이전 아키텍처 (아카이브)

Quasar (Vue 3) + TypeScript 기반의 이전 아키텍처는 Flutter 크로스 플랫폼 통일 결정에 따라 교체되었다.

| 항목 | 이전 (Quasar) | 현재 (Flutter) |
|------|-------------|---------------|
| State | Pinia 5 stores | Riverpod providers |
| Router | vue-router 계층 트리 | go_router 14 routes |
| HTTP | axios + interceptor | Dio + interceptor |
| WebSocket | 네이티브 WebSocket 래퍼 | web_socket_channel 래퍼 |
| Mock | MSW 2.x | MockDioAdapter |
| i18n | vue-i18n (JSON) | flutter_localizations (ARB) |
| Rive | `@rive-app/canvas` | `rive` (Flutter) |

이전 코드 참조: `C:/Claude/EbsArchiveBackup/07-archive/LegacyRepos/ebs_lobby-react/`

이전 Engineering.md (Quasar 버전) 이력: 2026-04-10 신규 작성 → 2026-04-13 WSOP LIVE 정렬 → 2026-04-15 Store 초기화/401 refresh 상세 추가.
