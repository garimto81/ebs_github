# TEST-01: 테스트 계획서

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 테스트 피라미드, 앱별 도구, 커버리지, CI/CD, Mock 전략 |

---

## 개요

EBS 소프트웨어 QA 테스트 전략을 정의한다. 물리 하드웨어(RFID 안테나, ST25R3911B, ESP32)는 테스트 범위에서 제외하며, 모든 RFID 관련 테스트는 `MockRfidReader`를 통한 소프트웨어 에뮬레이션으로 수행한다.

> 참조: Mock 모드 정의 — BS-00 §9, RFID HAL 인터페이스 — API-03

---

## 1. 테스트 피라미드

```
          ┌───────────┐
          │   E2E     │  10%
          │ (Browser) │
          ├───────────┤
          │  Widget / │  20%
          │Integration│
          ├───────────┤
          │           │
          │   Unit    │  70%
          │           │
          └───────────┘
```

| 계층 | 비율 | 목적 | 실행 시간 |
|------|:----:|------|:--------:|
| **Unit** | 70% | 개별 함수/클래스 단위 검증 | <1초/테스트 |
| **Widget/Integration** | 20% | UI 위젯 렌더링 + 서비스 간 연동 | <5초/테스트 |
| **E2E** | 10% | 방송 하루 전체 시나리오 재현 | <60초/시나리오 |

### 계층별 테스트 대상

| 계층 | Game Engine | CC | BO | Lobby |
|------|:-----------:|:--:|:--:|:-----:|
| **Unit** | HandFSM, 베팅 검증, 팟 계산, 핸드 평가, Equity | 위젯 상태 로직 | API endpoint, DB 쿼리 | 컴포넌트 로직 |
| **Widget/Integration** | — | CC UI + MockRfidReader 연동 | API + DB 통합 | 페이지 렌더링 |
| **E2E** | — | CC → BO → Overlay 전체 흐름 | — | Lobby → BO → CC 전체 흐름 |

---

## 2. 앱별 테스트 도구

### 2.1 Game Engine (순수 Dart 패키지)

| 항목 | 값 |
|------|:--|
| **프레임워크** | `dart test` (package:test) |
| **러너** | `dart test --reporter=expanded` |
| **Mocking** | `package:mocktail` |
| **커버리지** | `dart test --coverage` → `lcov` |
| **대상** | HandFSM 상태 전이, 베팅 유효성, 팟 분배, 핸드 평가, Equity 계산 |

### 2.2 Command Center (Flutter 앱)

| 항목 | 값 |
|------|:--|
| **프레임워크** | `flutter test` (Unit + Widget) |
| **Widget 테스트** | `testWidgets()` + `WidgetTester` |
| **Mocking** | `package:mocktail` + `MockRfidReader` |
| **Golden 테스트** | `matchesGoldenFile()` (Overlay 스냅샷) |
| **Integration** | `flutter test integration_test/` |
| **대상** | CC UI 상호작용, RFID Mock 연동, Overlay 렌더링 |

### 2.3 Back Office (Python FastAPI)

| 항목 | 값 |
|------|:--|
| **프레임워크** | `pytest` |
| **HTTP 클라이언트** | `httpx.AsyncClient` (TestClient) |
| **DB** | SQLite in-memory (테스트용) |
| **Mocking** | `unittest.mock` + `pytest-mock` |
| **커버리지** | `pytest --cov=src --cov-report=html` |
| **대상** | REST API, WebSocket, DB CRUD, 인증, 동기화 |

### 2.4 Lobby (웹 앱)

| 항목 | 값 |
|------|:--|
| **Unit/Component** | `vitest` |
| **E2E** | `playwright` |
| **Mocking** | `msw` (Mock Service Worker) — BO API Mock |
| **커버리지** | `vitest --coverage` |
| **대상** | Lobby UI, 테이블 관리, Settings, Auth |

---

## 3. 커버리지 목표

| 앱 | 목표 | 측정 도구 | 비고 |
|----|:----:|----------|------|
| **Game Engine** | ≥90% | `dart test --coverage` | 핵심 비즈니스 로직 — 최고 커버리지 |
| **Back Office** | ≥80% | `pytest --cov` | API + DB 계층 |
| **Command Center** | ≥70% | `flutter test --coverage` | UI 위젯 포함, Golden 테스트 병행 |
| **Lobby** | ≥70% | `vitest --coverage` | 컴포넌트 + 페이지 |

### 커버리지 제외 대상

| 제외 대상 | 이유 |
|----------|------|
| `RealRfidReader` | 물리 하드웨어 의존 — Mock HAL로 대체 |
| UI 애니메이션 코드 | Rive 애니메이션은 시각적 검증 (Golden 테스트) |
| 3rd party 라이브러리 래퍼 | 외부 라이브러리 내부 코드 미포함 |

---

## 4. CI/CD 연동 — GitHub Actions

### 4.1 파이프라인 구조

```
push / PR
  ├─ [Job 1] Game Engine
  │    ├─ dart test --coverage
  │    └─ coverage check (≥90%)
  ├─ [Job 2] CC (Flutter)
  │    ├─ flutter test --coverage
  │    └─ coverage check (≥70%)
  ├─ [Job 3] BO (Python)
  │    ├─ pytest --cov
  │    └─ coverage check (≥80%)
  ├─ [Job 4] Lobby (Web)
  │    ├─ vitest --coverage
  │    └─ coverage check (≥70%)
  └─ [Job 5] E2E (PR merge 시만)
       └─ playwright (Lobby E2E)
```

### 4.2 트리거 조건

| 이벤트 | Job 1~4 | Job 5 (E2E) |
|--------|:-------:|:-----------:|
| Push to feature branch | 실행 | 미실행 |
| PR to main | 실행 | 실행 |
| Merge to main | 실행 | 실행 |

### 4.3 실패 시 처리

| 조건 | 처리 |
|------|------|
| Unit/Widget 테스트 실패 | PR merge 차단 |
| 커버리지 목표 미달 | PR merge 차단 + 커버리지 리포트 코멘트 |
| E2E 실패 | PR merge 차단 + 스크린샷 아티팩트 저장 |

---

## 5. Mock 전략

### 5.1 RFID — MockRfidReader

| 항목 | 방식 |
|------|------|
| **구현체** | `MockRfidReader` (API-03 §6) |
| **DI 교체** | Riverpod `ProviderScope(overrides: [...])` |
| **이벤트 합성** | `injectCard()`, `injectRemoval()`, `injectError()` |
| **시나리오 재생** | YAML 시나리오 파일 로드 (`loadScenario()`) |
| **결정적 타이밍** | delay_ms 지정, 동일 입력 = 동일 출력 보장 |

> 참조: Mock HAL 테스트 케이스 31개 — API-03 §8

### 5.2 WSOP LIVE — JSON Fixtures

| 항목 | 방식 |
|------|------|
| **데이터 소스** | `test/fixtures/wsop-live/` 디렉토리의 JSON 파일 |
| **내용** | Competition, Series, Event, Flight, Player, BlindStructure |
| **로드 방식** | BO 테스트: 파일 직접 로드 / Lobby 테스트: MSW 응답 Mock |

> 참조: Mock 데이터 상세 — TEST-04-mock-data.md

### 5.3 Back Office — In-Memory DB

| 항목 | 방식 |
|------|------|
| **DB** | SQLite `:memory:` (테스트별 격리) |
| **마이그레이션** | 테스트 시작 시 자동 스키마 생성 |
| **Seed 데이터** | `conftest.py`에서 공통 fixture 로드 |
| **격리** | 각 테스트 함수별 독립 트랜잭션 → rollback |

### 5.4 WebSocket — Mock Event Stream

| 항목 | 방식 |
|------|------|
| **CC 테스트** | `MockWebSocketChannel` — BO 이벤트 에뮬레이션 |
| **Lobby 테스트** | MSW WebSocket handler — BO 이벤트 에뮬레이션 |
| **이벤트 타입** | BS-06-00-triggers.md §2.4 BO 소스 이벤트 전체 |

---

## 6. 테스트 명명 규칙

### 6.1 파일명

| 앱 | 패턴 | 예시 |
|----|------|------|
| Game Engine | `test/{module}_test.dart` | `test/hand_fsm_test.dart` |
| CC | `test/{widget}_test.dart` | `test/action_panel_test.dart` |
| BO | `tests/test_{module}.py` | `tests/test_hand_api.py` |
| Lobby | `__tests__/{component}.test.ts` | `__tests__/TableList.test.ts` |

### 6.2 테스트 이름

```
{상황}_{입력}_{기대결과}
```

예시:
- `preFlopBetting_foldAction_playerStatusFolded`
- `allInWithSidePot_threePlayersAllIn_twoSidePotsCreated`
- `mockRfid_injectCard_cardDetectedEventEmitted`

---

## 7. 테스트 데이터 관리

| 유형 | 저장 위치 | 형식 |
|------|----------|------|
| WSOP LIVE fixtures | `test/fixtures/wsop-live/` | JSON |
| RFID 시나리오 | `test/fixtures/rfid-scenarios/` | YAML |
| Player 샘플 | `test/fixtures/players/` | JSON |
| Settings 프리셋 | `test/fixtures/config/` | JSON |
| Golden 이미지 | `test/goldens/` | PNG |

> 참조: Mock 데이터 상세 — TEST-04-mock-data.md

---

## 비활성 조건

- 물리 RFID 하드웨어 테스트: 항상 비활성 (Mock HAL만 사용)
- E2E 테스트: feature branch push 시 비활성 (PR/merge 시만 실행)
- Golden 테스트 업데이트: `--update-goldens` 플래그로만 허용

---

## 영향 받는 요소

| 요소 | 관계 |
|------|------|
| TEST-02 E2E Scenarios | 이 계획서의 E2E 계층 상세 시나리오 |
| TEST-03 Game Engine Fixtures | 이 계획서의 Unit 계층 테스트 케이스 |
| TEST-04 Mock Data | 이 계획서의 Mock 전략 데이터 상세 |
| TEST-05 QA Checklist | 이 계획서의 수동 검증 보완 |
| API-03 RFID HAL | MockRfidReader 인터페이스 계약 |
| BS-06-00 Triggers | Mock 합성 규칙, 시나리오 스크립트 형식 |
