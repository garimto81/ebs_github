# Team 1: Frontend Web — CLAUDE.md (코드 전용)

## Role

Login UI + Lobby + Settings 6탭 (Outputs / GFX / Display / Rules / Stats / Preferences) + Graphic Editor Import/Activate 허브 (CCR-011)

**기술 스택**: Quasar Framework (Vue 3) + TypeScript + `@rive-app/canvas` (rive-js, GE 프리뷰 전용)

---

## 문서 위치 (docs v10)

**팀 문서는 모두 `docs/2. Development/2.1 Frontend/` 에 있다. 이 폴더는 코드 전용.**

| 문서 카테고리 | 경로 |
|--------------|------|
| 섹션 landing / 인덱스 | `../docs/2. Development/2.1 Frontend/2.1 Frontend.md` |
| Login 화면 | `../docs/2. Development/2.1 Frontend/Login/` |
| Lobby | `../docs/2. Development/2.1 Frontend/Lobby/` |
| Settings 6탭 | `../docs/2. Development/2.1 Frontend/Settings/` |
| Graphic Editor | `../docs/2. Development/2.1 Frontend/Graphic_Editor/` |
| Legacy Console UI (역사 기록) | `../docs/2. Development/2.1 Frontend/Settings/Legacy_Console_UI.md` |
| Engineering / Architecture | `../docs/2. Development/2.1 Frontend/Engineering.md` |
| Backlog | `../docs/2. Development/2.1 Frontend/Backlog.md` |

## 소유 경로 (코드)

| 경로 | 내용 |
|------|------|
| `src/` | Quasar 소스 코드 |
| `test/`, `e2e/` | Vitest + Playwright |
| `index.html`, `quasar.config.js`, `package.json`, `tsconfig.json`, `eslint.config.js`, `vitest.config.ts`, `playwright.config.ts` | 프로젝트 설정 |

## 계약 참조 (읽기 전용)

팀 간 공통 계약 — publisher 팀이 소유, 이 팀은 consume만 함:

| 계약 | 경로 | 소유 |
|------|------|------|
| API-01 REST | `../docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md` | team2 |
| API-05 WebSocket | `../docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md` | team2 |
| API-06 Auth | `../docs/2. Development/2.2 Backend/APIs/Auth_and_Session.md` | team2 |
| DATA Schema | `../docs/2. Development/2.2 Backend/Database/Schema.md` | team2 |
| BS-00 공통 정의 | `../docs/2. Development/2.5 Shared/BS_Overview.md` | conductor |
| BS-01 Authentication | `../docs/2. Development/2.5 Shared/Authentication.md` | conductor |

수정은 CR 프로세스 경유 (`../docs/3. Change Requests/pending/CR-team1-YYYYMMDD-*.md`).

## API / WebSocket 경계

- 모든 HTTP 호출은 Backend (team2)로만 전송
- CC, Game Engine과의 직접 통신 금지
- WebSocket `ws://[host]/ws/lobby` — 모니터링 전용 (write 명령 없음)
- CCR-019 Idempotency-Key 자동 주입 (`src/api/client.ts` axios interceptor)
- CCR-021 seq 단조증가 검증 + `/ws/replay?from_seq=N` (`src/stores/wsStore.ts`)

## Mock Server (병렬 개발)

MSW 2.x (`src/mocks/`). `.env.development` 의 `VITE_USE_MOCK=true` (기본값).

## i18n

vue-i18n 9.x, locale 3종 (`ko` 기본, `en` Vegas, `es` Vegas sub). 위치: `src/i18n/{ko,en,es}.json`.

## 기획 공백 발견 시

개발 중 기획 문서에 없는 판단이 필요하면 해당 기획 문서를 **즉시 보강**한다. Spec_Gaps.md · CR draft · CCR-first 프로세스는 폐지되었다. 상세: `../CLAUDE.md` §"기획 공백 발견 시 프로세스".

## 금지

- `../docs/1. Product/`, `../docs/2. Development/2.{2,3,4,5}*/`, `../docs/3. Change Requests/{in-progress,done}/`, `../docs/4. Operations/` 수정 금지 (CR 프로세스)
- 다른 팀 코드 폴더(`../team2-backend/`, `../team3-engine/`, `../team4-cc/`) 접근 금지
- **Overlay 실제 렌더링 구현 금지** (team4 영역)
- **Rive 에디터 기능 재구현 금지** (CCR-011 out-of-scope) — rive-js 프리뷰만

## Build / Dev

```bash
cd team1-frontend
pnpm install
pnpm dev                      # http://localhost:9000
pnpm build                    # → dist/spa/
pnpm lint
pnpm typecheck                # vue-tsc --noEmit
pnpm test                     # Vitest
pnpm e2e                      # Playwright
```

**커밋 전 필수**: `pnpm lint && pnpm typecheck && pnpm test` 통과.

**환경변수**:
- `.env.development` — `VITE_USE_MOCK=true`, `VITE_API_BASE_URL=/api/v1`, `VITE_WS_BASE_URL=ws://localhost:9080`
- `.env.production` — 배포 시점 주입

## 이전 코드 참조

React 19 + Vite 6 선행 작업물: `C:/claude/ebs-archive-backup/07-archive/legacy-repos/ebs_lobby-react/` (Quasar 전환으로 아카이브)
