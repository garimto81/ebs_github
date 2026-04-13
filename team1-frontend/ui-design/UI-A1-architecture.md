# UI-A1 Frontend Architecture — Router / Pinia / API Client / WebSocket

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 신규 작성 | Vue Router 트리, Pinia 5 store 설계, API client wrapper(CCR-019 Idempotency-Key), WS client(CCR-021 seq 검증 + replay), MSW mock 전략, vue-i18n 3 locale, Quasar build 명령 |
| 2026-04-13 | WSOP LIVE 정렬 | Router 경로 변경(Flight 독립 경로 제거→Day 탭), Staff 경로 추가, 신규 컴포넌트 9개 |
| 2026-04-13 | Player 독립 레이어 | Player를 Table 종속→독립 경로로 분리, 5계층→3계층+독립 레이어 |

---

## 0. 이 문서를 읽는 법

이 문서는 **"무엇을"이 아니라 "어떻게"를 말한다.** Team 1 frontend 가 Quasar + Vue 3 + TypeScript 로 실제 구현을 시작할 때 필요한 **아키텍처 결정**을 기록한다.

| 당신이 | 참조할 곳 |
|--------|-----------|
| 새 화면의 URL 을 정하려 한다 | §2 Vue Router 트리 |
| 서버 상태를 어떤 store 에 넣을지 모르겠다 | §3 Pinia stores |
| API 호출을 작성한다 | §4 API Client wrapper |
| WebSocket 이벤트를 구독한다 | §5 WebSocket Client |
| 백엔드 없이 화면만 만들고 싶다 | §6 Mock Server 전략 |
| 영문/스페인어 문자열을 추가한다 | §7 i18n 전략 |
| `pnpm dev` 가 뭐 하는지 모르겠다 | §8 Build/Dev 명령 |

`contracts/` 의 계약 변경이 필요하면 이 문서를 고치지 말고 CCR-DRAFT 경로를 사용한다.

---

## 1. Overview

### 1.1 기술 스택 (확정)

| 영역 | 선정 | 버전 | 근거 |
|------|------|:----:|------|
| Framework | **Quasar Framework** (Vue 3) | `^2.16` | CCR-016 tech-stack-ssot APPLIED. Quasar CLI 로 SPA/SSR/PWA/Electron 전환 자유, 100+ 컴포넌트 내장, TypeScript 1급 |
| Language | **TypeScript** (strict) | `^5.5` | 타입 안정성 + 계약(`contracts/data/*`) 스키마 파싱 |
| State | **Pinia** | `^2.2` | Vue 3 공식 state, Composition API 친화, TS 타입 추론 우수 |
| Router | **vue-router** | `^4.4` | Pinia 와 함께 Vue 3 표준 |
| HTTP | **axios** (`boot/axios.ts`) | `^1.7` | interceptor 로 Idempotency-Key 주입 용이, 취소 토큰 지원 |
| WebSocket | 네이티브 `WebSocket` + 커스텀 래퍼 | — | 외부 라이브러리 최소화, seq 검증 로직 직접 제어 |
| Mock | **MSW 2.x** | `^2.4` | 개발/테스트 양쪽에서 동일 핸들러 재사용 |
| i18n | **vue-i18n** | `^9.14` | Vue 3 Composition API 지원, ko/en/es 3 locale |
| Rive preview | **`@rive-app/canvas`** | `^2.21` | CCR-011 Graphic Editor 허브의 `.gfskin` 프리뷰. DOM canvas 렌더링 |
| Testing | **Vitest** + **@vue/test-utils** + **Playwright** | `^2.1` / `^2.4` / `^1.48` | QA-LOBBY-06 상세 |
| Lint | **ESLint** + **vue-tsc** | — | Quasar CLI 기본 |

### 1.2 소스 트리 (목표)

```
team1-frontend/
├── package.json
├── quasar.config.js          # Quasar 프로젝트 설정 (boot files, framework, build, dev)
├── tsconfig.json
├── index.html
├── .env.development          # VITE_API_BASE_URL, VITE_USE_MOCK=true
├── .env.production           # VITE_API_BASE_URL=https://bo.wsop.../api/v1
├── public/
└── src/
    ├── boot/                 # Quasar boot files (순서대로 실행)
    │   ├── axios.ts          # API client 생성 + interceptor 등록
    │   ├── pinia.ts          # createPinia() 등록
    │   ├── i18n.ts           # vue-i18n 등록
    │   ├── msw.ts            # dev 에서만 MSW worker start
    │   └── router-guards.ts  # beforeEach auth + RBAC
    ├── router/
    │   ├── index.ts          # createRouter
    │   └── routes.ts         # route 정의 (§2)
    ├── stores/               # Pinia stores (§3)
    │   ├── authStore.ts
    │   ├── lobbyStore.ts
    │   ├── settingsStore.ts
    │   ├── geStore.ts
    │   └── wsStore.ts
    ├── api/                  # API client modules (§4)
    │   ├── client.ts         # axios instance
    │   ├── auth.ts
    │   ├── series.ts
    │   ├── events.ts
    │   ├── flights.ts
    │   ├── tables.ts
    │   ├── seats.ts
    │   ├── players.ts
    │   ├── hands.ts
    │   ├── configs.ts
    │   ├── skins.ts
    │   ├── blind-structures.ts
    │   ├── audit-logs.ts
    │   └── reports.ts
    ├── mocks/                # MSW 핸들러 (§6)
    │   ├── browser.ts
    │   ├── handlers.ts
    │   └── data.ts
    ├── types/                # 공유 TS 타입 (DATA-02 정렬)
    │   ├── entities.ts
    │   ├── api.ts
    │   └── ws.ts
    ├── i18n/                 # vue-i18n 사전 (§7)
    │   ├── index.ts
    │   ├── ko.json
    │   ├── en.json
    │   └── es.json
    ├── layouts/
    │   ├── MainLayout.vue    # Quasar q-layout
    │   ├── AppHeader.vue     # Red header bar (WSOP LIVE 정렬)
    │   └── AppSidebar.vue    # Left sidebar navigation
    ├── pages/                # 각 URL 에 대응 (§2)
    │   ├── LoginPage.vue
    │   ├── SeriesListPage.vue
    │   ├── EventListPage.vue
    │   ├── TableListPage.vue
    │   ├── TableDetailPage.vue
    │   ├── PlayerListPage.vue
    │   ├── PlayerDetailPage.vue
    │   ├── HandHistoryPage.vue
    │   ├── settings/
    │   │   ├── SettingsLayout.vue
    │   │   ├── OutputsPage.vue
    │   │   ├── GfxPage.vue
    │   │   ├── DisplayPage.vue
    │   │   ├── RulesPage.vue
    │   │   ├── StatsPage.vue
    │   │   └── PreferencesPage.vue
    │   ├── staff/
    │   │   ├── StaffListPage.vue           # User list (Admin only)
    │   │   └── StaffDetailPage.vue
    │   └── graphic-editor/
    │       ├── GraphicEditorHubPage.vue
    │       └── GraphicEditorDetailPage.vue
    ├── components/
    │   ├── common/           # 공용 컴포넌트 (LoadingState, ErrorBanner, EmptyState)
    │   ├── auth/
    │   │   └── GoogleLoginBtn.vue          # Google OAuth button
    │   ├── event/
    │   │   └── EventFilterBar.vue          # Multi-filter bar + status tabs
    │   ├── table/
    │   │   ├── SeatGrid.vue                # Seat color grid
    │   │   └── DayTabs.vue                 # Day tab switcher
    │   ├── staff/
    │   │   ├── UserFormDialog.vue           # User create/edit dialog
    │   │   └── TableAssignment.vue          # Operator table assignment
    │   ├── lobby/            # Lobby 전용 (TableCard, PlayerRow, FlightAccordion)
    │   └── graphic-editor/   # GE 전용 (RiveCanvasPreview, UploadDropzone, MetadataForm)
    └── utils/
        ├── permissions.ts    # Bit Flag RBAC 헬퍼 (CCR-017)
        ├── date.ts
        └── idempotency.ts    # crypto.randomUUID() 래퍼
```

### 1.3 데이터 흐름 한눈에

```
                 ┌─────────┐
                 │  Pages  │ ← vue-router
                 └────┬────┘
                      │ store 호출 / computed
                      ▼
                 ┌─────────┐
                 │  Stores │ (Pinia: auth/lobby/settings/ge/ws)
                 └────┬────┘
                      │ state mutation / actions
         ┌────────────┼────────────┐
         ▼            ▼            ▼
    ┌────────┐   ┌────────┐   ┌────────┐
    │  api/  │   │mocks/  │   │ WS     │
    │ axios  │──▶│ MSW    │   │ client │
    │        │   │ (dev)  │   │(seq)   │
    └───┬────┘   └────────┘   └───┬────┘
        │                          │
        ▼                          ▼
   HTTP to BO                  ws://host/ws/lobby
   (Team 2, prod)              (Team 2, prod)
```

---

## 2. Vue Router 트리

### 2.1 경로 정의

```typescript
// src/router/routes.ts
export const routes: RouteRecordRaw[] = [
  { path: '/login', name: 'login', component: () => import('pages/LoginPage.vue'), meta: { public: true } },

  {
    path: '/',
    component: () => import('layouts/MainLayout.vue'),
    meta: { requiresAuth: true },
    children: [
      { path: '', redirect: '/series' },

      // 3계층 Lobby 네비게이션 + Player 독립 레이어 (UI-01 §화면 1~3)
      { path: 'series', name: 'series-list', component: () => import('pages/SeriesListPage.vue') },
      { path: 'series/:seriesId/events', name: 'event-list', component: () => import('pages/EventListPage.vue'), props: true },
      { path: 'events/:eventId/tables', name: 'table-list', component: () => import('pages/TableListPage.vue'), props: true }, // Day tab = query param ?day=2
      { path: 'tables/:tableId', name: 'table-detail', component: () => import('pages/TableDetailPage.vue'), props: true },

      // Player 독립 레이어 (Table 종속 아님, 어디서든 접근 가능)
      { path: 'players', name: 'player-list', component: () => import('pages/PlayerListPage.vue') },
      { path: 'players/:playerId', name: 'player-detail', component: () => import('pages/PlayerDetailPage.vue'), props: true },

      { path: 'hand-history/:tableId?', name: 'hand-history', component: () => import('pages/HandHistoryPage.vue'), props: true },

      // Settings 6탭 (UI-03)
      {
        path: 'settings',
        component: () => import('pages/settings/SettingsLayout.vue'),
        meta: { requiredPermission: 'Settings:Read' },
        children: [
          { path: '', redirect: '/settings/outputs' },
          { path: 'outputs', name: 'settings-outputs', component: () => import('pages/settings/OutputsPage.vue') },
          { path: 'gfx', name: 'settings-gfx', component: () => import('pages/settings/GfxPage.vue') },
          { path: 'display', name: 'settings-display', component: () => import('pages/settings/DisplayPage.vue') },
          { path: 'rules', name: 'settings-rules', component: () => import('pages/settings/RulesPage.vue') },
          { path: 'stats', name: 'settings-stats', component: () => import('pages/settings/StatsPage.vue') },
          { path: 'preferences', name: 'settings-preferences', component: () => import('pages/settings/PreferencesPage.vue') },
        ],
      },

      // Graphic Editor 허브 (CCR-011 Team 1 이관)
      {
        path: 'lobby/graphic-editor',
        name: 'ge-hub',
        component: () => import('pages/graphic-editor/GraphicEditorHubPage.vue'),
        meta: { requiredPermission: 'GraphicEditor:Read' },
      },
      {
        path: 'lobby/graphic-editor/:skinId',
        name: 'ge-detail',
        component: () => import('pages/graphic-editor/GraphicEditorDetailPage.vue'),
        props: true,
        meta: { requiredPermission: 'GraphicEditor:Read' },
      },

      // Staff 관리 (Admin only)
      { path: 'staff', name: 'staff-list', component: () => import('pages/staff/StaffListPage.vue'), meta: { requireRole: 'admin' } },
      { path: 'staff/:id', name: 'staff-detail', component: () => import('pages/staff/StaffDetailPage.vue'), props: true, meta: { requireRole: 'admin' } },
    ],
  },

  // 404
  { path: '/:pathMatch(.*)*', name: 'not-found', component: () => import('pages/NotFoundPage.vue'), meta: { public: true } },
];
```

### 2.2 Navigation Guards (boot/router-guards.ts)

```typescript
// boot/router-guards.ts
router.beforeEach(async (to) => {
  const auth = useAuthStore();

  // public route (login, 404)
  if (to.meta.public) return true;

  // requiresAuth 체크
  if (to.meta.requiresAuth && !auth.isAuthenticated) {
    // session restore 시도 (GET /auth/session)
    const restored = await auth.tryRestoreSession();
    if (!restored) {
      return { name: 'login', query: { redirect: to.fullPath } };
    }
  }

  // 역할 체크 (Staff 등 Admin only 경로)
  if (to.meta.requireRole) {
    if (auth.role !== to.meta.requireRole) {
      return { name: 'series-list' };
    }
  }

  // 권한 체크 (CCR-017 Bit Flag)
  if (to.meta.requiredPermission) {
    const [resource, action] = (to.meta.requiredPermission as string).split(':');
    if (!auth.hasPermission(resource, action)) {
      return { name: 'series-list' }; // 권한 없으면 기본 화면으로
    }
  }

  return true;
});
```

**규칙**:
- `meta.public = true` — 로그인 불필요 (login, 404)
- `meta.requiresAuth = true` — 로그인 필수 (layout 단위)
- `meta.requiredPermission = 'Resource:Action'` — 추가 권한 (Settings, GE 등)
- 권한 체크는 **문자열 비교 금지**. `auth.hasPermission()` 은 내부에서 `role.permission & Permission.Write` 비트 연산 (UI-01 §9.5)

---

## 3. Pinia Stores

### 3.1 Store 분할 원칙

| 원칙 | 예 |
|------|------|
| **도메인 경계로 분할** | auth / lobby / settings / ge / ws 5개. API 파일 그룹과 거의 1:1 |
| **서버 캐시는 persist 하지 않는다** | lobby/settings/ge 는 `persist` 미사용. 새로고침 시 재요청 |
| **민감 데이터는 메모리만** | Access Token 은 메모리, Refresh Token 은 HttpOnly Cookie (Team 2 가 세팅) |
| **UI 선호만 localStorage** | `uiStore` 같은 건 만들지 않고, 필요 시 sessionStorage 보조 |
| **WS 상태는 전용 store** | 재연결 상태, seq cursor, 이벤트 버퍼는 `wsStore` 에만 |

### 3.2 Store 5개 설계

#### 3.2.1 `useAuthStore`

```typescript
// src/stores/authStore.ts
import { defineStore } from 'pinia';
import * as authApi from 'src/api/auth';

interface AuthState {
  user: { id: string; email: string; displayName: string } | null;
  accessToken: string | null;
  role: 'admin' | 'operator' | 'viewer' | null;
  permissions: Record<string, number>; // { 'Series': 7, 'Table': 3, ... } bit flag
  status: 'idle' | 'loading' | 'authenticated' | 'error';
  error: string | null;
}

export const useAuthStore = defineStore('auth', {
  state: (): AuthState => ({
    user: null,
    accessToken: null,
    role: null,
    permissions: {},
    status: 'idle',
    error: null,
  }),

  getters: {
    isAuthenticated: (state) => state.status === 'authenticated' && state.accessToken !== null,
    isAdmin: (state) => state.role === 'admin',
  },

  actions: {
    async login(email: string, password: string, totpCode?: string) {
      this.status = 'loading';
      try {
        const res = await authApi.login(email, password, totpCode);
        this.user = res.user;
        this.accessToken = res.accessToken;
        this.role = res.role;
        this.permissions = res.permissions;
        this.status = 'authenticated';
      } catch (e: any) {
        this.status = 'error';
        this.error = e.message;
        throw e;
      }
    },

    async tryRestoreSession(): Promise<boolean> {
      // Refresh Token(HttpOnly Cookie) 이 있으면 서버가 자동 처리
      try {
        const res = await authApi.getSession();
        if (res) {
          this.$patch({ ...res, status: 'authenticated' });
          return true;
        }
      } catch {
        // 401 정상 — 복원 실패
      }
      return false;
    },

    async logout() {
      await authApi.logout();
      this.$reset();
    },

    hasPermission(resource: string, action: 'Read' | 'Write' | 'Delete'): boolean {
      const perm = this.permissions[resource] ?? 0;
      const mask = { Read: 1, Write: 2, Delete: 4 }[action];
      return (perm & mask) !== 0;
    },
  },
});
```

persist: `user` 만 SessionStorage (새 탭에서도 동일 세션 유지). Access Token 은 persist 하지 않고 refresh 로 복구.

#### 3.2.2 `useLobbyStore`

```typescript
interface LobbyState {
  series: Series[];
  events: Record<string, Event[]>;        // seriesId → events
  flights: Record<string, Flight[]>;      // eventId → flights
  tables: Record<string, Table[]>;        // flightId → tables
  players: Record<string, Player[]>;      // tableId → players

  selection: {
    seriesId: string | null;
    eventId: string | null;
    flightId: string | null;
    tableId: string | null;
    playerId: string | null;
  };

  loading: Record<string, boolean>;       // 'series', 'events:{id}', ...
  errors: Record<string, string | null>;
}
```

Actions: `fetchSeries()`, `fetchEvents(seriesId)`, `fetchFlights(eventId)`, `fetchTables(flightId)`, `fetchPlayers(tableId)`, `select({seriesId?, eventId?, ...})`, `rebalance(flightId)` — 마지막은 CCR-020 saga 를 구독.

persist: 없음. 새로고침 시 현재 route 기반 재요청.

#### 3.2.3 `useSettingsStore`

```typescript
interface SettingsState {
  outputs: OutputsConfig | null;
  gfx: GfxConfig | null;
  display: DisplayConfig | null;
  rules: RulesConfig | null;
  stats: StatsConfig | null;
  preferences: PreferencesConfig | null;
  dirty: Record<keyof SettingsState, boolean>;
  status: 'idle' | 'loading' | 'saving' | 'error';
}
```

Actions: `fetchSection(section)`, `updateField(section, key, value)` (dirty=true), `saveSection(section)` (`PUT /configs/{section}`), `revertSection(section)`.

WS 구독: `ConfigChanged` 이벤트 → 해당 섹션만 덮어쓰기 (다른 탭에서 변경 시 반영).

#### 3.2.4 `useGeStore`

```typescript
interface GeState {
  skins: Skin[];
  selectedSkinId: string | null;
  metadata: SkinMetadata | null;            // 편집 중 draft
  metadataDirty: boolean;
  uploadProgress: number | null;
  validationErrors: ValidationError[];
  preview: { riveInstance: Rive | null; loading: boolean };
  activationState: 'idle' | 'warning' | 'confirming' | 'activating' | 'activated' | 'error';
}
```

Actions: `fetchSkins()`, `uploadSkin(file)` (ZIP → validate → preview), `editMetadata(field, value)`, `saveMetadata()`, `activateSkin(id)` (`PUT /api/v1/skins/{id}/activate` with `X-Game-State` + `If-Match ETag`).

WS 구독: `skin_updated` (CCR-015) → `skins` 배열 동기화.

#### 3.2.5 `useWsStore`

```typescript
interface WsState {
  status: 'disconnected' | 'connecting' | 'connected' | 'reconnecting';
  lastSeq: number;                          // CCR-021 단조증가 cursor
  subscriptions: Set<string>;               // 구독 중인 채널/토픽
  eventBuffer: WsEvent[];                   // 재연결 중 수신 이벤트 버퍼
  reconnectAttempts: number;
  reconnectDelay: number;                   // ms, exponential backoff
}
```

Actions: `connect()`, `disconnect()`, `subscribe(topic)`, `unsubscribe(topic)`, `replay(fromSeq)` (`GET /ws/replay?from_seq=N`). 내부적으로 WebSocket 인스턴스 1개 유지. §5 상세.

---

## 4. API Client Wrapper

### 4.1 `src/api/client.ts`

```typescript
import axios, { AxiosInstance, AxiosError } from 'axios';
import { useAuthStore } from 'src/stores/authStore';

export class ApiError extends Error {
  constructor(
    public status: number,
    public code: string,
    message: string,
    public details?: unknown,
  ) {
    super(message);
  }
}

export function createApiClient(): AxiosInstance {
  const client = axios.create({
    baseURL: import.meta.env.VITE_API_BASE_URL || '/api/v1',
    withCredentials: true, // Refresh Token cookie
    timeout: 10_000,
  });

  // Request interceptor: Bearer token + Idempotency-Key (CCR-019)
  client.interceptors.request.use((config) => {
    const auth = useAuthStore();
    if (auth.accessToken) {
      config.headers.Authorization = `Bearer ${auth.accessToken}`;
    }

    // CCR-019: 모든 mutation 에 Idempotency-Key 자동 주입
    const method = (config.method ?? 'get').toLowerCase();
    if (['post', 'put', 'patch', 'delete'].includes(method)) {
      // 호출측에서 명시적으로 지정하면 그걸 사용 (재시도 시 동일 key 필요)
      if (!config.headers['Idempotency-Key']) {
        config.headers['Idempotency-Key'] = crypto.randomUUID();
      }
    }

    return config;
  });

  // Response interceptor: 에러 정규화 + 401 refresh 시도
  client.interceptors.response.use(
    (res) => res,
    async (err: AxiosError<{ error?: { code: string; message: string; details?: unknown } }>) => {
      if (err.response?.status === 401 && !err.config?._retry) {
        // Access Token 만료 → Refresh 시도
        const auth = useAuthStore();
        const refreshed = await auth.tryRestoreSession();
        if (refreshed && err.config) {
          err.config._retry = true;
          return client(err.config);
        }
      }

      const body = err.response?.data?.error;
      throw new ApiError(
        err.response?.status ?? 0,
        body?.code ?? 'UNKNOWN',
        body?.message ?? err.message,
        body?.details,
      );
    },
  );

  return client;
}

export const api = createApiClient();
```

### 4.2 재시도 정책

- **5xx** (서버 오류): 최대 3회, exponential backoff (500ms → 1s → 2s). Idempotency-Key 는 **원래 값 재사용** (서버가 중복 요청 감지 가능).
- **4xx** (클라이언트 오류): 즉시 실패. 재시도 금지.
- **network error**: 5xx 와 동일 취급.

재시도 로직은 각 API 모듈에서 `withRetry()` 래퍼로 감싼다:
```typescript
// src/api/series.ts
export const fetchSeries = () => withRetry(() => api.get<Series[]>('/series'));
```

### 4.3 주의 사항

- **Bearer token 은 store 에서만**. localStorage 에 저장 금지.
- **Idempotency-Key 는 재시도 시 동일 값**. 매 요청 새로 발급하면 CCR-019 의미가 없어진다.
- **401 루프 방지**. `_retry` 플래그로 재시도 1회 제한.
- **CORS**: dev 는 Vite proxy (`vite.config.ts` / `quasar.config.js > devServer.proxy`), prod 는 동일 도메인 가정.

---

## 5. WebSocket Client

### 5.1 연결

```typescript
// src/stores/wsStore.ts (부분)
actions: {
  connect() {
    const auth = useAuthStore();
    if (!auth.accessToken) return;

    const url = `${import.meta.env.VITE_WS_BASE_URL}/ws/lobby?token=${auth.accessToken}`;
    this.socket = new WebSocket(url);

    this.socket.onopen = () => {
      this.status = 'connected';
      this.reconnectAttempts = 0;
      // 재연결 후 누락 이벤트 replay
      if (this.lastSeq > 0) {
        this.replay(this.lastSeq + 1);
      }
    };

    this.socket.onmessage = (ev) => this.handleMessage(ev.data);
    this.socket.onclose = () => this.scheduleReconnect();
    this.socket.onerror = (e) => console.error('[ws] error', e);
  },

  handleMessage(data: string) {
    const msg: WsEvent = JSON.parse(data);

    // CCR-021: seq 단조증가 검증
    if (msg.seq <= this.lastSeq) {
      console.warn(`[ws] out-of-order: got ${msg.seq}, have ${this.lastSeq}`);
      return; // 중복 무시
    }
    if (msg.seq > this.lastSeq + 1) {
      // gap 감지 → replay 요청
      console.warn(`[ws] gap: expected ${this.lastSeq + 1}, got ${msg.seq}`);
      this.replay(this.lastSeq + 1);
      return;
    }

    this.lastSeq = msg.seq;
    this.dispatch(msg);
  },

  dispatch(msg: WsEvent) {
    switch (msg.type) {
      case 'ConfigChanged':
        useSettingsStore().applyRemoteChange(msg.payload);
        break;
      case 'skin_updated':
        useGeStore().applyRemoteSkinUpdate(msg.payload);
        break;
      case 'table_status_changed':
      case 'player_moved':
        useLobbyStore().applyRemoteChange(msg);
        break;
      // ...
    }
  },

  async replay(fromSeq: number) {
    const events: WsEvent[] = await api.get('/ws/replay', { params: { from_seq: fromSeq } }).then(r => r.data);
    for (const ev of events) {
      this.lastSeq = Math.max(this.lastSeq, ev.seq);
      this.dispatch(ev);
    }
  },

  scheduleReconnect() {
    if (this.reconnectAttempts >= 10) {
      this.status = 'disconnected';
      Notify.create({ type: 'negative', message: '실시간 연결이 끊겼습니다. 페이지를 새로고침하세요.' });
      return;
    }
    this.status = 'reconnecting';
    this.reconnectAttempts++;
    this.reconnectDelay = Math.min(1000 * 2 ** (this.reconnectAttempts - 1), 30_000);
    setTimeout(() => this.connect(), this.reconnectDelay);
  },
}
```

### 5.2 seq 정책 요약 (CCR-021)

| 상황 | 동작 |
|------|------|
| `msg.seq === lastSeq + 1` | 정상. dispatch + `lastSeq++` |
| `msg.seq <= lastSeq` | 중복. 무시 |
| `msg.seq > lastSeq + 1` | gap. `replay(lastSeq+1)` 호출 후 dispatch 재개 |
| 재연결 성공 | 연결 직후 `replay(lastSeq+1)` 자동 호출 |
| `lastSeq === 0` | 첫 연결. replay 하지 않고 수신 이벤트부터 시작 |

### 5.3 재연결 정책

- Exponential backoff: 1s → 2s → 4s → 8s → 16s → 30s (max) → 30s → ...
- 최대 10회 시도 후 `disconnected` 로 전환, 사용자에게 알림
- `accessToken` 이 없으면 연결 시도 하지 않음 (logout 후)

---

## 6. Mock Server 전략

### 6.1 배경

Team 2 FastAPI backend 가 아직 구현되지 않은 상태에서 Team 1 이 병렬 개발하려면 **브라우저에서 직접 API 를 가로채는 mock** 이 필요하다. MSW (Mock Service Worker) 를 채택한다.

### 6.2 활성화 조건

```bash
# .env.development
VITE_USE_MOCK=true
VITE_API_BASE_URL=/api/v1
VITE_WS_BASE_URL=ws://localhost:9080
```

```typescript
// src/boot/msw.ts
import { boot } from 'quasar/wrappers';

export default boot(async () => {
  if (import.meta.env.VITE_USE_MOCK !== 'true') return;
  if (import.meta.env.PROD) return;

  const { worker } = await import('src/mocks/browser');
  await worker.start({
    onUnhandledRequest: 'bypass',
    serviceWorker: { url: '/mockServiceWorker.js' },
  });
  console.info('[MSW] worker started');
});
```

### 6.3 Handler 구조

```typescript
// src/mocks/handlers.ts
import { http, HttpResponse } from 'msw';
import * as db from './data';

export const handlers = [
  // Auth
  http.post('/api/v1/auth/login', async ({ request }) => {
    const body = await request.json() as { email: string; password: string };
    const user = db.users.find(u => u.email === body.email);
    if (!user) return HttpResponse.json({ error: { code: 'INVALID_CREDENTIALS', message: '...' } }, { status: 401 });
    return HttpResponse.json({
      user: { id: user.id, email: user.email, displayName: user.displayName },
      accessToken: 'mock-jwt-' + user.id,
      role: user.role,
      permissions: user.permissions,
    });
  }),

  // Series
  http.get('/api/v1/series', () => HttpResponse.json(db.series)),
  http.get('/api/v1/series/:id/events', ({ params }) =>
    HttpResponse.json(db.events.filter(e => e.seriesId === params.id)),
  ),

  // Tables (CCR-020 saga 시나리오 포함)
  http.post('/api/v1/tables/rebalance', async ({ request }) => {
    const body = await request.json() as { flightId: string };
    return HttpResponse.json({
      sagaId: crypto.randomUUID(),
      status: 'in_progress',
      totalSteps: 8,
      completedSteps: 0,
    });
  }),

  // ... (19개 API 모듈별로)
];
```

### 6.4 Seed Data

`src/mocks/data.ts` 는 DATA-02 엔티티 구조를 따르는 TS 상수. Playground 에서 사용할 최소 데이터:
- Series 2개 (WSOP Main, WSOPC Cyprus)
- Events 5개
- Flights 10개
- Tables 20개
- Players 100명
- Skins 3개 (default, custom-bracelet, playground)

### 6.5 Test 모드

Vitest 는 브라우저 없이 Node 에서 실행하므로 MSW 는 **server 모드**로 돌린다:

```typescript
// src/mocks/server.ts (test only)
import { setupServer } from 'msw/node';
import { handlers } from './handlers';
export const server = setupServer(...handlers);
```

`vitest.setup.ts`:
```typescript
import { server } from 'src/mocks/server';
beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

### 6.6 Real backend 전환

```bash
# .env.development (backend 준비 후)
VITE_USE_MOCK=false
VITE_API_BASE_URL=http://localhost:8000/api/v1
VITE_WS_BASE_URL=ws://localhost:8000
```

`VITE_USE_MOCK=false` 로 바꾸고 `pnpm dev` 재시작하면 MSW 는 로드되지 않는다. 코드 변경 0.

---

## 7. i18n 전략

### 7.1 Locale

| Locale | 용도 | Fallback |
|--------|------|:--------:|
| `ko` | 기본 (한국 운영팀) | — |
| `en` | Vegas WSOP 운영 | `ko` |
| `es` | Vegas 스페인어 운영 | `en` |

### 7.2 파일 구조

```
src/i18n/
├── index.ts       # createI18n() + locale detection
├── ko.json
├── en.json
└── es.json
```

`ko.json` 예시:
```json
{
  "common": {
    "save": "저장",
    "cancel": "취소",
    "loading": "불러오는 중...",
    "error": "오류가 발생했습니다"
  },
  "lobby": {
    "series": {
      "title": "시리즈 목록",
      "empty": "등록된 시리즈가 없습니다"
    },
    "table": {
      "status": {
        "empty": "빈 테이블",
        "setup": "설정 중",
        "live": "진행 중",
        "paused": "일시정지",
        "closed": "종료"
      }
    }
  },
  "graphicEditor": {
    "upload": {
      "dropzone": ".gfskin 파일을 여기에 끌어놓거나 클릭하여 선택",
      "validating": "ZIP 구조 검증 중...",
      "preview": "프리뷰 로드 중..."
    }
  }
}
```

### 7.3 컴포넌트 사용

```vue
<template>
  <q-btn :label="$t('common.save')" color="primary" @click="save" />
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n';
const { t, locale } = useI18n();
</script>
```

### 7.4 Locale 전환

- 초기값: `navigator.language` 에서 추출. 지원 목록에 없으면 `ko`
- 사용자 수동 전환: Settings > Preferences 탭의 "Language" 드롭다운
- persist: `localStorage.lobby.locale`

### 7.5 번역 workflow

- 개발자는 `ko.json` 에만 key 추가. `en`/`es` 는 추후 번역가 담당
- 누락 key 는 개발 환경에서 콘솔 경고 + `ko` fallback
- **절대 문자열 하드코딩 금지**. 새 UI 추가 시 즉시 i18n key 도 같이 추가

---

## 8. Build / Dev 명령

### 8.1 개발

```bash
cd team1-frontend
pnpm install           # 첫 설치
pnpm dev               # Quasar dev server, localhost:9000 (또는 9080)
```

환경변수는 `.env.development` 참조 (MSW 활성화 기본).

### 8.2 빌드

```bash
pnpm build             # quasar build (SPA), 출력 → dist/spa/
pnpm build:ssr         # (옵션) SSR 모드
```

### 8.3 테스트

```bash
pnpm test              # Vitest unit + component
pnpm test:watch
pnpm e2e               # Playwright E2E
pnpm e2e:ui            # Playwright UI 모드
```

QA-LOBBY-06 참조.

### 8.4 린트 / 타입 체크

```bash
pnpm lint              # eslint
pnpm typecheck         # vue-tsc --noEmit
```

커밋 전에 `pnpm lint && pnpm typecheck && pnpm test` 통과 필수.

---

## 9. 관련 CCR

본 문서의 아키텍처 결정이 참조하는 APPLIED CCR:

| CCR | 관련 섹션 | 반영 내용 |
|-----|-----------|----------|
| **CCR-011** ge-ownership-move | §1.1, §2.1, §3.2.4 | Graphic Editor 허브 라우팅 + `useGeStore` + rive-js 프리뷰 |
| **CCR-012** gfskin-format-unify | §3.2.4, §6 seed | `.gfskin` ZIP 구조 mock data |
| **CCR-013** ge-api-spec (API-07) | §4, `src/api/skins.ts` | GE 엔드포인트 정의 |
| **CCR-015** skin-updated-ws | §5.1 dispatch | WS `skin_updated` → `useGeStore` 동기화 |
| **CCR-016** tech-stack-ssot | §1.1 | Quasar (Vue 3) + TS 확정 근거 (BS-00-definitions) |
| **CCR-017** wsop-parity | §2.2 guards, §3.2.1 permissions, §5 dispatch | Bit Flag RBAC, dayIndex, isPause, BlindDetailType enum |
| **CCR-019** idempotency-key | §4.1 interceptor | 모든 mutation 자동 헤더 주입 |
| **CCR-020** table-rebalance-saga | §3.2.2 rebalance, §6.3 handler | saga 응답 구조 + UI 진행 표시 연동 |
| **CCR-021** ws-event-seq | §5.1 seq validation | 단조증가 검증 + replay 엔드포인트 |
| **CCR-025** bs03-graphic-settings-tab | §3.2.3 gfx config | Settings GFX 탭의 시각 asset 메타 필드 |

---

## 10. Non-Goals

이 문서는 다음을 **다루지 않는다**:

- **서버 측 구현** (Team 2): FastAPI 엔드포인트, DB 스키마, 인증 로직 — `team2-backend/` 소유
- **CC/Overlay/Engine** (Team 4, Team 3): Flutter 앱, Rive 렌더링, 게임 엔진 — 각 팀 소유
- **Figma/Sketch 디자인 파일**: UI-00 및 `reference/` 참조. 본 문서는 구현 아키텍처만
- **배포 파이프라인 (CI/CD)**: 별도 DevOps 작업. `team1-frontend/README.md` 에 docker/vercel 가이드
- **End-user 매뉴얼**: 운영팀 교육 자료는 별도 문서
