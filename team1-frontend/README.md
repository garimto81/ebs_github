# team1-frontend — EBS Lobby (Flutter Web)

EBS (Event Broadcast System) Team 1 frontend: Login + Lobby + Settings 6탭 + Graphic Editor 허브.

> **⚠ README 진행 중 정리** — 본 문서 본문 일부는 v3 Quasar 시점 잔재. 정본 stack 은
> Flutter/Dart (CLAUDE.md `Role` 섹션 참조). 본 § Architecture Decisions 가 현재 SSOT.

## Architecture Decisions (2026-04-28, post-PR #18)

### AD-1 — Flutter SDK Pinning (deterministic build)

`team1-frontend/docker/lobby-web/Dockerfile` 의 builder image 는 **`ghcr.io/cirruslabs/flutter:3.41.7`** 로 explicit pin.

| 항목 | 내용 |
|------|------|
| **결정** | `:stable` 부동 tag 사용 금지. semver 명시 tag 만 허용. |
| **이유** | PR #17 cascade 에서 발견된 5-layer 갭 (intl pin / Dart SDK / `--web-renderer` / `--obfuscate`) 은 모두 Flutter SDK minor 업그레이드가 trigger. `:stable` 은 CI/local 결과 비결정성 발생원. |
| **현 pin** | `flutter:3.41.7` (digest `sha256:644e3cea0a8440ce75804b67ceab77b16a87b39d9e9d89b07aceca7a98af1aa3`, 2026-04-15 release) |
| **업그레이드 protocol** | (1) 새 pin 후보 explicit tag 로 옵션 PR 작성, (2) cascade 갭 (intl pin / web flag) 재현 여부 확인, (3) pubspec.yaml 의존성 일괄 점검, (4) PR-#18 패턴으로 머지 |
| **CI 가드** | `.github/workflows/team1-e2e.yml` 의 docker build gate 가 PR pre-merge 단계에서 빌드 실패 즉시 차단 |

### AD-2 — Frontend Wiring (single host variable)

Frontend 는 **`EBS_BO_HOST` 단일 환경변수** 로 backend (BO) 만 가리킨다. **Engine (8080) 은 frontend 에서 직접 호출하지 않는다**.

| 항목 | 내용 |
|------|------|
| **단일 host** | `EBS_BO_HOST` (+ optional `EBS_BO_PORT`, default `8000`) |
| **유도 변수** | `apiBaseUrl = http://$EBS_BO_HOST:$EBS_BO_PORT/api/v1` <br> `wsBaseUrl  = ws://$EBS_BO_HOST:$EBS_BO_PORT` (frontend lobby_websocket_client → `/ws/lobby`) |
| **금지** | `BO_URL`, `ENGINE_URL`, `CC_URL` 등 별도 frontend env 변수. 모두 `EBS_BO_HOST` 1 곳에서 derive 되어야 함 (DRY + 잘못된 endpoint 분기 방지) |
| **Engine 경계** | team3 engine (port 8080) 은 BO ↔ Engine 간 backend-internal 통신 전용. frontend 가 직접 호출하면 multi-tenant 보안 / WS auth gate 우회 위험. |
| **검증** | `team1-frontend/tools/verify_team1_e2e.py` 의 S2 (apiBaseUrl) + S3 (wsBaseUrl) + S4 (engine HTTP-only NOTE) 가 wiring 정합성 보증 |
| **SSOT 코드** | `lib/foundation/configs/app_config.dart` `AppConfig.fromEnvironment()` |

### AD-3 — Build Context (monorepo root)

(PR #17, 2026-04-28) `docker-compose.yml` 의 `lobby-web` build context 는 **project root (`.`)** 로 승격됨. Dockerfile 의 모든 `COPY` 경로는 `team1-frontend/` 로 prefix.

이유: `pubspec.yaml` 의 `ebs_common: path: ../shared/ebs_common` 의존성을 docker build 가 resolve 하려면 `shared/` 가 build context 안에 포함되어야 함.

CI 차단: `.github/workflows/team1-e2e.yml` docker build gate.

## 기술 스택

- **Quasar Framework** (Vue 3) + **TypeScript**
- **Pinia** — 상태 관리 (5 stores: auth/lobby/settings/ge/ws)
- **vue-router** — SPA 라우팅 (history 모드)
- **axios** — HTTP 클라이언트 ( Idempotency-Key 자동 주입)
- **네이티브 WebSocket** + 커스텀 래퍼 ( seq 검증 + replay)
- **MSW 2.x** — 개발/테스트 mock server
- **@rive-app/canvas** — Graphic Editor 허브의 `.gfskin` 프리뷰 (team1 소유)
- **vue-i18n** — 다국어 (ko/en/es)
- **Vitest** + **@vue/test-utils** + **Playwright** — 테스트 피라미드

## 문서 참조

| 문서 | 역할 |
|------|------|
| `CLAUDE.md` | 팀 범위, API 경계, 금지 사항 |
| `ui-design/UI-A1-architecture.md` | **구현 아키텍처 SSOT** (Router, Pinia, API, WS, Mock, i18n) |
| `ui-design/UI-00-design-system.md` | 디자인 토큰, Quasar 컴포넌트 매핑, 접근성, 성능 |
| `ui-design/UI-01-lobby.md` | Lobby 3계층 + Player 독립 레이어 화면 설계 + Login + WSOP Parity Notes |
| `ui-design/UI-03-settings.md` | Settings 6탭 |
| `ui-design/UI-04-graphic-editor.md` | Graphic Editor 허브 |
| `qa/lobby/QA-LOBBY-06-quasar-test-strategy.md` | 테스트 전략 |
| `../contracts/` | 계약 (API, DATA, Specs) — 읽기 전용 |

## 개발 환경 요구사항

- **Node.js** ≥ 20
- **pnpm** ≥ 9 (`npm install -g pnpm` 또는 `corepack enable`)

## 첫 셋업

```bash
cd team1-frontend
pnpm install              # 의존성 설치
pnpm dev                  # Quasar dev server 시작 (http://localhost:9000)
```

기본적으로 `.env.development` 가 `VITE_USE_MOCK=true` 이므로 **백엔드 없이** MSW mock 으로 동작한다. Team 2 FastAPI 가 준비되면 `.env.development` 의 `VITE_USE_MOCK=false` + `VITE_API_BASE_URL=http://localhost:8000/api/v1` 로 변경.

## 주요 명령

```bash
pnpm dev                  # 개발 서버
pnpm build                # 프로덕션 빌드 → dist/spa/
pnpm lint                 # ESLint
pnpm typecheck            # vue-tsc --noEmit
pnpm test                 # Vitest unit + component
pnpm test:watch           # Vitest watch
pnpm test:coverage        # 커버리지 리포트
pnpm e2e                  # Playwright E2E (headless)
pnpm e2e:ui               # Playwright UI 모드
```

커밋 전 필수: `pnpm lint && pnpm typecheck && pnpm test`.

## 디렉터리 구조

```
team1-frontend/
├── package.json
├── quasar.config.js
├── tsconfig.json
├── index.html
├── .env.development           # Mock 활성화 (기본)
├── .env.production            # 배포 시 주입
├── src/
│   ├── boot/                  # Quasar boot files
│   │   ├── i18n.ts
│   │   ├── pinia.ts
│   │   ├── axios.ts           # Idempotency-Key interceptor ()
│   │   ├── ws-client.ts       # WS seq validation ()
│   │   ├── msw.ts             # MSW worker (dev only)
│   │   └── router-guards.ts   # Auth + RBAC guards
│   ├── router/
│   │   ├── index.ts
│   │   └── routes.ts          # UI-A1 §2.1 참조
│   ├── stores/                # Pinia stores
│   │   ├── authStore.ts       # Bit Flag RBAC
│   │   ├── lobbyStore.ts
│   │   ├── settingsStore.ts
│   │   ├── geStore.ts         # Graphic Editor (team1 소유)
│   │   └── wsStore.ts         # WS seq cursor
│   ├── api/                   # API client modules
│   │   ├── client.ts          # axios instance
│   │   ├── auth.ts
│   │   ├── series.ts
│   │   ├── events.ts
│   │   ├── flights.ts
│   │   ├── tables.ts
│   │   ├── seats.ts
│   │   ├── players.ts
│   │   ├── hands.ts
│   │   ├── configs.ts
│   │   ├── skins.ts           # GE 허브 API (API-07)
│   │   ├── blind-structures.ts
│   │   ├── audit-logs.ts
│   │   └── reports.ts
│   ├── mocks/                 # MSW handlers
│   │   ├── browser.ts
│   │   ├── server.ts          # Node mode (test only)
│   │   ├── handlers.ts
│   │   └── data.ts            # DATA-04 seed
│   ├── i18n/                  # vue-i18n 사전
│   │   ├── index.ts
│   │   ├── ko.json
│   │   ├── en.json
│   │   └── es.json
│   ├── types/                 # 공유 TS 타입 (DATA-04 정렬)
│   ├── css/
│   │   ├── app.scss
│   │   └── quasar.variables.scss
│   ├── layouts/
│   │   └── MainLayout.vue
│   ├── pages/
│   │   ├── LoginPage.vue
│   │   ├── SeriesListPage.vue
│   │   ├── EventListPage.vue
│   │   ├── FlightListPage.vue
│   │   ├── TableListPage.vue
│   │   ├── TableDetailPage.vue
│   │   ├── PlayerListPage.vue
│   │   ├── PlayerDetailPage.vue
│   │   ├── HandHistoryPage.vue
│   │   ├── NotFoundPage.vue
│   │   ├── settings/
│   │   │   ├── SettingsLayout.vue
│   │   │   └── {Outputs,Gfx,Display,Rules,Stats,Preferences}Page.vue
│   │   └── graphic-editor/
│   │       ├── GraphicEditorHubPage.vue
│   │       └── GraphicEditorDetailPage.vue
│   └── components/
│       ├── common/            # LoadingState, ErrorBanner, EmptyState
│       ├── lobby/             # TableCard, PlayerRow, FlightAccordion 등
│       └── graphic-editor/    # RiveCanvasPreview, UploadDropzone, MetadataForm
├── test/                      # Vitest unit/component tests
└── e2e/                       # Playwright E2E specs
```

상세: `ui-design/UI-A1-architecture.md` §1.2.

## 이전 코드 참조

Quasar 이식 원본: `../C:/claude/ebs-archive-backup/07-archive/legacy-repos/ebs_lobby-react/` (React 19 + Vite 6 + Zustand). Pages / API client / Zustand stores / mock handler 를 Vue 3 + Pinia + MSW 2.x 로 재작성.

## 금지

- `../contracts/**` 직접 수정 금지 (publisher 팀 소유)
- `../team2-backend/`, `../team3-engine/`, `../team4-cc/` 접근 금지
- Overlay 실제 렌더링 구현 금지 (Team 4 BS-07)
- Rive 에디터 기능 재구현 금지 (out-of-scope, Rive 공식 에디터 외부 사용)
