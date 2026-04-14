# Team 1: Frontend Web — CLAUDE.md

## Role

Login UI + Lobby + Settings 6탭 (Outputs / GFX / Display / Rules / Stats / Preferences) + **Graphic Editor Import/Activate 허브** (CCR-011)

**기술 스택**: Quasar Framework (Vue 3) + TypeScript + `@rive-app/canvas` (rive-js, GE 프리뷰 전용)

> **Graphic Editor 범위 (CCR-011 APPLIED 2026-04-10)**: Team 1 Lobby `/lobby/graphic-editor` 탭에서 `.gfskin` ZIP Import·검증·메타데이터 편집(GEM-01~25)·Activate + `skin_updated` WS broadcast 를 담당한다. **Transform/Animation/keyframe/color adjust 편집은 out-of-scope** — 디자이너는 Rive 공식 에디터(외부)에서 `.riv` 완성 후 `.gfskin` ZIP 으로 묶어 업로드.
> CC(Team 4 Flutter)는 `skin_updated` 이벤트를 수신하여 Overlay 를 리렌더하는 **소비자** 역할로 재정의되었다.

## 소유 경로

| 경로 | 내용 |
|------|------|
| `qa/lobby/` | Lobby QA 전략, 체크리스트, spec-gap, 테스트 전략(QA-LOBBY-06) |
| `ui-design/` | UI-00 (디자인 시스템), UI-01 (Lobby), UI-03 (Settings), **UI-04 (Graphic Editor)**, **UI-A1 (Architecture)** |
| `ui-design/reference/skin-editor/` | PokerGFX Skin Editor 역설계 PRD 15종 (2026-04-14 team4에서 이관, CCR-011 후속). BS-08 구현 시 참고 |
| `src/` | Quasar 소스 코드 |
| `specs/BS-02-lobby/` | Lobby 행동 명세 (팀 내부 설계, contracts/에서 이관) |
| `specs/BS-03-settings/` | Settings 행동 명세 (팀 내부 설계, contracts/에서 이관) |
| `specs/BS-08-graphic-editor/` | GE 행동 명세 (팀 내부 설계, contracts/에서 이관) |

## 계약 참조 (읽기 전용 — 수정 금지)

- 행동 명세: `../../contracts/specs/` (BS-01-auth, BS-02-lobby, BS-03-settings, **BS-08-graphic-editor**)
- API 계약: `../../contracts/api/` (API-01, API-05 ws/lobby 채널, API-06 Auth, **API-07 Graphic Editor**)
- 데이터 스키마: `../../contracts/data/` (DATA-04 DB Schema + Entity 정의, **DATA-07 gfskin ZIP schema**)
- 공유 정의: `../../contracts/specs/BS-00-definitions.md`

## Architecture 참조 (필수)

실제 구현(Vue Router / Pinia / API client / WebSocket client / Mock / i18n) 은 전부 **`ui-design/UI-A1-architecture.md`** 를 따른다. 본 CLAUDE.md 는 경계와 책임만 규정하고, "어떻게"는 UI-A1 이 SSOT.

## Settings 범위 (Team 1) — 6탭 CRUD

`UI-03-settings.md` 및 `specs/BS-03-settings/` 과 정렬한 6탭 구조. 변경 이유: WSOP LIVE Parity(CCR-017) 및 Tech Stack SSOT(CCR-016), Graphic Editor 소유권 이관(CCR-011), BS-03-02 Graphic Settings 세부화(CCR-025) 반영.

| 탭 | Team 1 담당 | Team 4 담당 |
|----|-------------|-------------|
| **Outputs** | 해상도/프레임레이트, NDI/RTMP/SRT/DIRECT 파이프라인 설정, Fill & Key 라우팅 CRUD | — |
| **GFX** | Layout/Card/Player/Animation 옵션 **CRUD 폼 + rive-js 프리뷰** (via Graphic Editor 허브) | Overlay 렌더링 소비자 (Flutter), 시각 asset 정의 제공 (BS-03-02-gfx, CCR-025) |
| **Display** | Blinds/Precision/Mode 수치 표시 옵션 **폼** | 오버레이 상의 실제 수치 렌더링 결과 (BS-07) |
| **Rules** | Game Rules (Bomb Pot, Straddle, Sleeper), Player Display (Seat #, Order, Hilite) CRUD | — |
| **Stats** | Equity/Outs/Leaderboard/Score Strip 표시 옵션 CRUD | 통계 오버레이 렌더링 결과 |
| **Preferences** | Table 인증(Name/Password), Diagnostics 보기, Export 폴더 설정 | — |

**경계 원칙**:

- **GFX 탭**은 Team 1 이 설정 값 CRUD 와 **rive-js 기반 프리뷰** 모두 담당한다 (CCR-011: Graphic Editor Import/Activate 허브가 Team 1 Lobby 로 이관). 프리뷰용 `.riv` 자산은 Designer 가 Rive 공식 에디터(외부)에서 완성한 후 `.gfskin` ZIP 으로 업로드한다 — Team 1 은 Rive keyframe/transform 편집 UI 를 만들지 않는다.
- **Display 탭**은 Team 1 이 설정 값만 저장한다. 실제 Overlay 렌더링은 Team 4 Flutter+Rive Overlay(BS-07) 가 담당한다.
- **Blind 레벨/타이머 편집은 Settings 가 아니다**. Blind 구조는 Event/Flight 단위로 달라지므로 Settings(글로벌)가 아닌 **Lobby 의 Flight 생성/편집 플로우**가 소유한다 (`UI-01 §화면 3 Flight` 참조).
- Settings 는 **글로벌 원칙**을 따른다. 모든 CC 인스턴스/모든 Table 에 동일 적용되며, 테이블별 오버라이드 UI 는 만들지 않는다. 근거: 메모리 `feedback_settings_global.md`.

## Graphic Editor 범위 (Team 1, CCR-011)

`/lobby/graphic-editor` 탭으로 구현. Quasar + `@rive-app/canvas`(rive-js) 스택.

| 책임 | 세부 |
|------|------|
| **Authoring 허브** | `.gfskin` ZIP Upload → 구조 검증 → JSON Schema 검증(DATA-07) → Rive 파싱 확인 → rive-js 프리뷰 렌더링 |
| **Metadata 편집** | `skin.json` 의 name/version/colors/fonts/resolution/animation duration (GEM-01~25) 만 수정 |
| **Activate 지점** | `PUT /api/v1/skins/{id}/activate` (If-Match ETag + X-Game-State) → `skin_updated` WS broadcast |
| **RBAC gate** | Admin 편집, Operator 읽기 전용, Viewer 접근 차단 (BS-08-04) |

**out-of-scope (Team 1 이 구현하지 않음)**:

- Transform/Animation/keyframe/color adjust 편집 → Rive 공식 에디터(외부)에서 수행
- `.riv` 파일 신규 작성 → Designer 가 Rive 에디터에서 완성
- Overlay 실제 방송 렌더링 → Team 4 Flutter+Rive Overlay

> Team 4 는 Graphic Editor UI 를 더 이상 소유하지 않는다. CC(Flutter) 는 `skin_updated` WS 이벤트를 수신한 **소비자** 로서 Overlay 를 리렌더한다.

## API 경계

- 모든 HTTP 호출은 Backend (Team 2)로만 전송
- CC, Game Engine과의 직접 통신 금지
- WebSocket `ws://[host]/ws/lobby` — 모니터링 전용 (write 명령 없음)
- **CCR-019 Idempotency-Key 자동 주입**: 모든 `POST`/`PUT`/`PATCH`/`DELETE` 요청은 `Idempotency-Key: <uuid-v4>` 헤더를 자동으로 주입한다. 구현 위치: `src/api/client.ts` 의 axios request interceptor. 재시도 시 동일 key 재사용 (서버 중복 감지용). 상세: UI-A1 §4.1.

## WebSocket

- 연결: `ws://[host]/ws/lobby?token={accessToken}` (token 은 `useAuthStore` 에서)
- 재연결: Exponential backoff 1s→2s→…→30s max, 최대 10회
- **CCR-021 seq validation**: 수신 메시지의 `seq` 필드 단조증가 검증. gap 감지 시 `GET /ws/replay?from_seq=N` 호출해서 누락 이벤트 replay. 구현 위치: `src/stores/wsStore.ts`. 상세: UI-A1 §5.
- 구독 이벤트: `ConfigChanged` (Settings), `skin_updated` (GE), `table_status_changed`, `player_moved`, `hand_started`, `hand_ended`, `operator_connected/disconnected`

## Mock Server (병렬 개발 전략)

Team 2 FastAPI backend 가 미구현이므로 Team 1 은 **MSW 2.x** 로 로컬 mock 을 돌린다.

- **활성화**: `.env.development` 의 `VITE_USE_MOCK=true` (기본값)
- **위치**: `src/mocks/` (`browser.ts`, `handlers.ts`, `data.ts`)
- **seed**: DATA-04 엔티티 기반 최소 데이터 (Series 2 / Events 5 / Flights 10 / Tables 20 / Players 100)
- **test**: Vitest 는 `src/mocks/server.ts` (Node 모드) 사용
- **real backend 전환**: `.env.development` 에서 `VITE_USE_MOCK=false` + `VITE_API_BASE_URL=http://localhost:8000/api/v1` 로 변경. 코드 수정 0. 상세: UI-A1 §6.

## i18n (다국어)

- **vue-i18n 9.x**, locale 3종: `ko`(기본), `en`(Vegas), `es`(Vegas sub)
- **위치**: `src/i18n/{ko,en,es}.json`
- **원칙**: 모든 UI 문자열은 `$t('...')` 호출. 하드코딩 금지. 키 구조는 `lobby.series.title` 같은 dot-notation.
- **locale 전환**: Settings > Preferences > Language 드롭다운. `localStorage.lobby.locale` 에 persist.
- 상세: UI-A1 §7.

## Spec Gap (CCR-first)

- **contracts/ 변경 필요 시**: 먼저 `../docs/05-plans/ccr-inbox/CCR-DRAFT-team1-YYYYMMDD-slug.md` 작성 (**필수**).
  QA Gap 문서(`qa/lobby/QA-LOBBY-03-spec-gap.md`)에는 "CCR-DRAFT-XXX 제출됨" pointer + 임시 구현 1줄만 기록. 장문 근거는 CCR-DRAFT 본문에만.
- **팀 내부 판단만 필요 시** (contracts/ 영향 없음): QA Gap 문서에 직접 기록.
- 형식: `GAP-L-{NNN}`
- 상세 절차: `../CLAUDE.md` §"Spec Gap 프로세스 (CRITICAL — CCR-first)" 참조.

## 이전 코드 참조

React 19 + Vite 6 선행 작업물: `C:/claude/ebs-archive-backup/07-archive/legacy-repos/ebs_lobby-react/`
(Quasar 전환으로 아카이브됨. API 구조/Mock 데이터 참고용)

## 금지

- `../../contracts/` 파일 수정 금지 (CCR 프로세스 경유)
- `../team2-backend/`, `../team3-engine/`, `../team4-cc/` 접근 금지
- **Overlay 실제 렌더링 구현 금지** (Team 4 BS-07 영역). Team 1 은 Overlay 를 표시하지 않고, Settings/GE 설정 값만 저장한다.
- **Rive 에디터 기능 재구현 금지** (CCR-011 out-of-scope). Transform/keyframe/color adjust 편집은 Rive 공식 에디터에 위임. Team 1 은 rive-js 로 프리뷰만 한다.

## Build / Dev 명령

```bash
cd team1-frontend
pnpm install                  # 첫 설치 (또는 의존성 업데이트 후)
pnpm dev                      # Quasar dev server (http://localhost:9000 또는 9080)
pnpm build                    # 프로덕션 빌드 → dist/spa/
pnpm lint                     # ESLint
pnpm typecheck                # vue-tsc --noEmit
pnpm test                     # Vitest unit + component
pnpm test:watch               # Vitest watch 모드
pnpm e2e                      # Playwright E2E
pnpm e2e:ui                   # Playwright UI 모드
```

**커밋 전 필수**: `pnpm lint && pnpm typecheck && pnpm test` 통과.

**환경변수**:
- `.env.development` — `VITE_USE_MOCK=true`, `VITE_API_BASE_URL=/api/v1`, `VITE_WS_BASE_URL=ws://localhost:9080`
- `.env.production` — 배포 시점에 주입

상세: UI-A1 §8.

---

## 문서 동기화 규칙

### 문서 계층
- **L0 계약** (contracts/): 읽기 전용, Conductor 소유. 이 팀은 수정 불가.
- **L1 파생** (이 팀의 ui-design/, qa/, 구현 가이드): 이 팀 소유. contracts/ 기준 일관성은 AI 책임.

### 사용자의 동기화 지시 시
1. 지정된 contracts/ 파일 Read
2. 자기 파생 문서와 비교 → 불일치 수정 (contracts/가 맞음)
3. 변경 사항 보고

### 파생 문서 생성/수정 시
- 반드시 contracts/ 참조하여 일관성 확인
- contracts/와 다르면 → CCR draft 제출 (contracts/ 직접 수정 금지)
- 파생 문서 = 인간이 읽지 않는 AI 산출물 (일관성은 AI 책임)

### 금지
- contracts/와 불일치하는 파생 문서 생성 금지
- 불일치 발견 시 "어느 쪽이 맞나요?" 질문 금지 (contracts/가 맞음, 파생 문서 수정)
- 파생 문서(ui-design/, qa/, LLD)를 인간에게 읽으라고 제시 금지
