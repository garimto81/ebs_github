---
title: S-11 Lobby Hand History — E2E Automation Scaffold
owner: team4
tier: internal
legacy-id: ITP-AUTO-S11
last-updated: 2026-04-21
---

## 개요

`Integration_Test_Plan.md §S-11` (Lobby Hand History 조회 + 필터 + RBAC) 시나리오의 **실행 가능한 자동화 스캐폴드**.

| 레이어 | 도구 | 검증 대상 |
|--------|------|----------|
| API + RBAC + WS | **Playwright (TypeScript)** | `/api/v1/hands` 필터/페이지네이션, `/hands/:id/players` hole_card 마스킹, `ws://.../ws/lobby` HandStarted/ActionPerformed |
| Lobby UI | **flutter_driver (Dart)** | 사이드바 → Hand Browser → Hand Detail, 필터 입력, RBAC 별 UI 차이, 당일 한정 배너 |

## 디렉토리

```
automation/s11/
├── README.md                          (이 파일)
├── run_s11.sh                         (Bash orchestrator)
├── run_s11.ps1                        (PowerShell orchestrator)
├── fixtures/
│   └── fixtures.json                  (accounts + seed + expected API/WS assertions)
├── playwright/
│   ├── package.json                   (deps: @playwright/test, ws)
│   ├── playwright.config.ts           (projects: api-rbac, ws-realtime)
│   ├── tsconfig.json
│   └── tests/
│       ├── helpers/
│       │   ├── auth.ts                (login + authHeaders)
│       │   └── time.ts                (today/yesterday ISO, Asia/Seoul)
│       ├── s11.api.spec.ts            (6 tests: filter, detail, RBAC Operator/Viewer, pagination, 당일)
│       └── s11.ws.spec.ts             (3 tests: HandStarted, ActionPerformed, seq monotonicity)
├── flutter_driver/
│   ├── s11_lobby_test.dart            (skeleton, 6 testWidgets, TODO(team1))
│   └── integration_test_driver.dart   (test_driver entry template)
└── scripts/
    └── seed_s11.py                    (stub — team2 가 실제 INSERT 구현 예정)
```

## 사전 요구

| 항목 | 버전/상태 |
|------|----------|
| Node.js | 20+ |
| npm | 10+ |
| Flutter SDK | 3.22+ (Windows Desktop target enabled) |
| Python | 3.10+ (seeder stub) |
| team2 BO 가동 | `http://localhost:8000` 에서 `/health` 200 |
| team2 seeder | **Backlog** — S-11 fixtures INSERT 로직 추가 필요 (현재 stub) |
| team1 Lobby | **Backlog** — `integration_test/` 디렉토리 생성 + `s11_lobby_test.dart` 복제 + widget key 부착 |

## 실행

### 전체 (seed + API + UI)

```bash
# Bash / Git Bash
./run_s11.sh

# PowerShell
.\run_s11.ps1
```

### API/WS 만 (team2 BO 준비 시 즉시 실행 가능)

```bash
./run_s11.sh --api-only
# 또는
cd playwright && npm install && npx playwright test
```

### 특정 태그만

```bash
cd playwright
npx playwright test --grep @rbac   # RBAC 중심
npx playwright test --grep @ws     # WebSocket 중심
```

### UI 만 (team1 wiring 완료 후)

```bash
./run_s11.sh --ui-only
```

## 소유권 경계 (v7 free_write + decision_owner)

| 자산 | decision_owner | 비고 |
|------|---------------|------|
| `fixtures/fixtures.json` | team4 | team2/team1 이 참조 |
| `playwright/**` | team4 | 계약(API/WS) 레이어 |
| `flutter_driver/s11_lobby_test.dart` | **team1** | 이 디렉토리에 **template** 만 유지. 실제 활성화 시 `team1-frontend/integration_test/` 로 복제. team1 이 widget key 추가 + login/logout helper wiring |
| `scripts/seed_s11.py` | **team2** | 현재 stub. team2 가 실제 INSERT 구현 |
| `Integration_Test_Plan.md §S-11` | team4 | 시나리오 명세 정본 |

## 실행 계약 (team2/team1 요구사항)

이 스캐폴드가 **실제로 통과**하려면 다음이 선행되어야 한다 (현재 Backlog):

1. **team2 BO**
   - `/api/v1/auth/login` 이 fixtures 의 3 계정 지원 (admin/operator/viewer)
   - `/api/v1/hands` 필터 §5.10.1 구현 완료 (✓ commit `fca4fd8` 기준 부분 완료)
   - `/hands/:id/players` Viewer 마스킹 (`hole_card_* = '★'`)
   - Operator 미할당 테이블 요청 시 **빈 배열 + 200** (403 아님)
   - `ws://.../ws/lobby?token=` JWT 인증 + Subscribe 프로토콜
   - `seed_s11.py` 대체 구현 (fixtures 를 DB 에 로드)

2. **team1 Lobby**
   - `integration_test/s11_lobby_test.dart` 복제 (본 디렉토리 template 기반)
   - `test_driver/integration_test.dart` 생성 (위 `integration_test_driver.dart` 사본)
   - Hand Browser / Detail 위젯에 `Key('handBrowser.root')`, `Key('handBrowser.row.{hand_id}')`, `Key('handDetail.timeline')`, `Key('filter.eventId/tableId/apply')` 등 자동화 훅 부착
   - 당일 한정 배너에 `'당일 한정'` 텍스트 또는 `Key('banner.todayOnly')`

3. **team4 (본 디렉토리)**
   - Integration_Test_Plan §S-11 본문 유지
   - S-12 이후 시나리오 추가 시 본 스캐폴드 재사용 (`automation/s{N}/`)

## 환경 변수

| 이름 | 기본값 | 용도 |
|------|--------|------|
| `BACKEND_HTTP_URL` | `http://localhost:8000` | Playwright baseURL + seed 대상 |
| `BACKEND_WS_URL` | `ws://localhost:8000/ws/lobby` | Playwright WS endpoint |
| `S11_ADMIN_USER` / `S11_ADMIN_PW` | fixtures 값 | flutter_driver 에만 전달 (dart-define) |
| `S11_OPERATOR_USER` / `S11_OPERATOR_PW` | fixtures 값 | 〃 |
| `S11_VIEWER_USER` / `S11_VIEWER_PW` | fixtures 값 | 〃 |
| `NEW_HAND_TRIGGER_MODE` | `wait` | `wait` = 수동으로 CC 가 핸드 시작하길 8s 대기. 추후 `auto` = 스크립트가 CC mock endpoint 호출 |

## 알려진 한계 (Prototype 범위)

이 자동화는 **기획서 완결 검증용 프로토타입**. 실제 dev team 이 재구현할 때 반드시 보강:

- `seed_s11.py` 가 stub — 실제 DB/API seeder 필요
- `flutter_driver/` 는 `markTestSkipped` 로 skip — widget key + login helper 미구현
- WS 테스트는 "수동 트리거" 기본값 — CI 에서는 Mock CC publisher 필요
- Viewer 마스킹 필드 이름 (`hole_card_1` 등) 은 team2 실제 응답 스키마로 재확인 필요 (fallback 로직 포함)

## 참조

- 시나리오 명세: `../../Integration_Test_Plan.md §S-11`
- API 필터: `../../../2.2 Backend/APIs/Backend_HTTP.md §5.10.1`
- WS 이벤트: `../../../2.2 Backend/APIs/WebSocket_Events.md §3.3.3`
- UI 계약: `../../../2.1 Frontend/Lobby/Hand_History.md`
- Overlay 경계: `../../Overlay/Layer_Boundary.md §1.4`

## Edit History

| 날짜 | 버전 | 변경 |
|------|------|------|
| 2026-04-21 | 0.1 | 최초 작성 — Playwright API/WS + flutter_driver skeleton + runner 양식. decision_owner: team4. notify: team1 (Lobby UI wiring), team2 (seeder INSERT 구현) |
