# IMPL-08 Testing Strategy — 테스트 피라미드

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 테스트 피라미드, 앱별 전략, Mock RFID 시나리오, 커버리지 목표 |

---

## 개요

이 문서는 EBS의 **테스트 전략**을 정의한다. Game Engine, CC, BO, Lobby 각각의 테스트 도구와 계층을 기술하고, Mock RFID 시나리오 테스트를 포함한다.

> 참조: API-03 §8 테스트 케이스, IMPL-05 의존성 주입, BS-00 §9 Mock 모드

---

## 1. 테스트 피라미드

### 1.1 계층 구조

```
        /  E2E  \           ← 소수, 느림, 높은 신뢰도
       /─────────\
      / Integration\        ← 중간, 컴포넌트 간 연동
     /─────────────\
    /   Unit Tests   \      ← 대량, 빠름, 핵심 로직
   /─────────────────\
```

### 1.2 계층별 비율 목표

| 계층 | 비율 | 실행 시간 | 대상 |
|------|:----:|:--------:|------|
| **Unit** | 70% | < 30초 | 함수, 클래스, Provider, 순수 로직 |
| **Integration** | 20% | < 5분 | API ↔ DB, CC ↔ BO, WebSocket |
| **E2E** | 10% | < 15분 | 전체 시나리오 (로그인 → 핸드 완료) |

---

## 2. Game Engine — dart test

### 2.1 테스트 분류

| 유형 | 도구 | 대상 | 예시 |
|------|------|------|------|
| 유닛 테스트 | `dart test` | 순수 함수, FSM 전이 | `apply(state, FoldEvent) → state.players[0].folded == true` |
| 시나리오 테스트 | `dart test` + YAML | 전체 핸드 시퀀스 | `holdem-basic.yaml` 로드 → 이벤트 순차 적용 → 최종 상태 검증 |
| 속성 테스트 | `dart test` | 불변 조건 검증 | "모든 핸드 종료 시 팟 합 == 초기 스택 합" |

### 2.2 테스트 범위

| 대상 | 검증 내용 | 우선순위 |
|------|----------|:--------:|
| `apply()` 함수 | 모든 이벤트 타입별 상태 전이 정확성 | 최고 |
| HandFSM | IDLE→...→HAND_COMPLETE 모든 경로 | 최고 |
| Hand Evaluator | 52C5 = 2,598,960 조합 중 대표 케이스 | 높음 |
| Equity Calculator | 알려진 시나리오 정확도 검증 | 높음 |
| 22종 게임 규칙 | 게임별 고유 규칙 (예: Omaha 4장 홀카드) | Phase 의존 |
| Pot Calculator | 메인팟 + 사이드팟 (올인 시나리오) | 최고 |

### 2.3 YAML 시나리오 테스트

```yaml
# test/scenarios/holdem_heads_up_allin.yaml
scenario: "Heads-up All-in Pre-Flop"
game: holdem
bet_structure: no_limit
players:
  - seat: 0, stack: 1000, cards: [As, Kd]
  - seat: 1, stack: 1000, cards: [Qh, Jc]
events:
  - type: HandStarted
  - type: BlindPosted, seat: 0, amount: 50   # SB
  - type: BlindPosted, seat: 1, amount: 100  # BB
  - type: ActionPerformed, seat: 0, action: raise, amount: 1000  # All-in
  - type: ActionPerformed, seat: 1, action: call, amount: 900
board: [9s, 6h, 3d, 2c, Ts]
expected:
  winner: [0]          # Ace-high wins
  pot_total: 2000
  final_phase: HAND_COMPLETE
```

---

## 3. Command Center (CC) — Flutter test

### 3.1 테스트 분류

| 유형 | 도구 | 대상 | DI 오버라이드 |
|------|------|------|-------------|
| 유닛 테스트 | `flutter test` | Provider 로직, 서비스 클래스 | 전체 Mock |
| 위젯 테스트 | `flutter test` | 개별 위젯 렌더링/인터랙션 | 전체 Mock |
| 통합 테스트 | `flutter test integration_test/` | 화면 전환, 다중 Provider 연동 | RFID Mock + 실제 BO (선택) |

### 3.2 위젯 테스트 전략

| 위젯 | 검증 내용 |
|------|----------|
| `ActionPanel` | 버튼 활성/비활성, 올바른 액션 전송 |
| `SeatGrid` | 좌석 10개 렌더링, 플레이어 정보 표시 |
| `HandInfoBar` | 핸드 번호, Street, 팟 금액 표시 |
| `RfidStatusWidget` | 연결/에러/Mock 상태 표시 |
| `DeckRegistrationPage` | 52장 진행률, 완료/실패 상태 |

### 3.3 Mock Provider 설정

```dart
// test/helpers/test_providers.dart
final testOverrides = [
  rfidReaderProvider.overrideWithValue(MockRfidReader()),
  apiClientProvider.overrideWithValue(MockApiClient()),
  wsClientProvider.overrideWithValue(MockWsClient()),
  authStateProvider.overrideWith(
    (ref) => AuthState.authenticated(testAdmin),
  ),
  currentTableProvider.overrideWith(
    (ref) => TableState(table: testTable),
  ),
];
```

---

## 4. Back Office (BO) — pytest

### 4.1 테스트 분류

| 유형 | 도구 | 대상 |
|------|------|------|
| API 테스트 | `pytest` + `httpx.AsyncClient` | REST 엔드포인트 |
| DB 테스트 | `pytest` + 인메모리 SQLite | ORM 쿼리, 마이그레이션 |
| WebSocket 테스트 | `pytest` + `websockets` | 이벤트 송수신, 구독 필터 |
| 서비스 테스트 | `pytest` | 비즈니스 로직 유닛 테스트 |

### 4.2 테스트 범위

| 대상 | 검증 내용 | 우선순위 |
|------|----------|:--------:|
| 인증 API | 로그인, 토큰 갱신, 만료, 권한 부족 | 최고 |
| RBAC 미들웨어 | Admin/Operator/Viewer 접근 제어 | 최고 |
| CRUD API | 각 엔티티 생성/조회/수정/삭제 | 높음 |
| WebSocket 허브 | CC 이벤트 수신 → Lobby 포워딩 | 높음 |
| 데이터 동기화 | WSOP LIVE 폴링 → 로컬 캐싱 | 중간 |
| 감사 로그 | 모든 변경 자동 기록 | 높음 |

### 4.3 테스트 Fixture

```python
# tests/conftest.py
@pytest.fixture
def db_session():
    engine = create_engine("sqlite:///:memory:")
    SQLModel.metadata.create_all(engine)
    with Session(engine) as session:
        yield session

@pytest.fixture
def client(db_session):
    app.dependency_overrides[get_db] = lambda: db_session
    with TestClient(app) as c:
        yield c

@pytest.fixture
def admin_token(client):
    # 테스트 Admin 생성 + 로그인 → JWT 반환
    ...
```

---

## 5. E2E 테스트

### 5.1 Lobby 웹 — Playwright

| 시나리오 | 검증 내용 |
|---------|----------|
| 로그인 흐름 | 이메일/비밀번호 입력 → 대시보드 진입 |
| 테이블 관리 | 테이블 생성 → 좌석 배치 → 플레이어 할당 |
| 설정 변경 | Settings 다이얼로그 → 블라인드/스킨/출력 변경 |
| 실시간 모니터링 | CC 핸드 시작 → Lobby 대시보드 갱신 확인 |

### 5.2 CC — Flutter integration_test

| 시나리오 | 검증 내용 |
|---------|----------|
| 로그인 → 테이블 선택 | 인증 + 라우팅 |
| 덱 등록 (Mock) | Mock 자동 등록 → 52장 확인 |
| 핸드 진행 (Mock RFID) | NEW HAND → 카드 → 액션 → HAND_COMPLETE |
| 오프라인 → 재연결 | BO 끊김 → 로컬 모드 → 재연결 → 동기화 |

---

## 6. Mock RFID 시나리오 테스트

### 6.1 사전 정의 시나리오

| 시나리오 | 파일 | 검증 대상 |
|---------|------|----------|
| Hold'em Basic | `holdem-basic.yaml` | 기본 핸드 진행 (2인, 5 Streets) |
| Omaha Hi-Lo | `omaha-hilo.yaml` | 4장 홀카드, Hi-Lo 팟 분배 |
| Multi Side Pot | `multi-sidepot.yaml` | 3인 올인, 사이드팟 정확 계산 |
| RFID Error Recovery | `rfid-error.yaml` | 카드 감지 실패 → 수동 폴백 |
| Deck Incomplete | `deck-incomplete.yaml` | 50장 등록 → partial 상태 처리 |

### 6.2 시나리오 실행 방식

```
1. MockRfidReader.loadScenario("holdem-basic.yaml")
2. 이벤트 순차 발행 (delay_ms 준수)
3. 각 이벤트 후 GameState 검증
4. 최종 상태 vs expected 비교
```

> 참조: API-03 §6.4 시나리오 파일 형식

### 6.3 결정적 타이밍 검증

| 검증 항목 | 방법 |
|----------|------|
| 이벤트 순서 보장 | 동일 시나리오 2회 실행 → 이벤트 순서 동일 |
| 타이밍 재현 | delay_ms 값 기준 ±10ms 이내 |
| 상태 결정성 | 동일 시나리오 → 동일 최종 GameState |

---

## 7. 커버리지 목표

### 7.1 앱별 목표

| 앱 | 라인 커버리지 | 브랜치 커버리지 | Phase 1 최소 |
|----|:----------:|:----------:|:----------:|
| Game Engine | 95% | 90% | 80% |
| BO (API + 서비스) | 85% | 80% | 70% |
| CC (Provider + 서비스) | 80% | 75% | 60% |
| Lobby (웹) | 70% | 65% | 50% |

### 7.2 필수 커버리지 영역 (100% 목표)

| 영역 | 이유 |
|------|------|
| Game Engine `apply()` | 게임 무결성의 핵심 |
| HandFSM 전이 | 잘못된 전이 = 게임 중단 |
| Pot Calculator | 금전적 정확성 필수 |
| Hand Evaluator | 승패 결정 정확성 |
| RBAC 미들웨어 | 보안 필수 |
| JWT 인증/검증 | 보안 필수 |

---

## 8. CI 통합

### 8.1 파이프라인 단계

```
Push / PR
  │
  ├── Lint (ruff check / dart analyze)
  ├── Unit Tests (병렬)
  │     ├── Engine: dart test
  │     ├── CC: flutter test
  │     └── BO: pytest
  │
  ├── Integration Tests
  │     ├── BO API + DB
  │     └── CC + Mock BO
  │
  └── E2E Tests (main 브랜치 머지 시)
        ├── Playwright (Lobby)
        └── Flutter integration_test (CC)
```

### 8.2 실행 규칙

| 트리거 | 실행 범위 |
|--------|---------|
| PR 생성/업데이트 | 변경된 레포의 Unit + Integration |
| main 머지 | 전체 Unit + Integration + E2E |
| 릴리스 태그 | 전체 + 성능 테스트 |

### 8.3 실패 정책

| 테스트 유형 | 실패 시 |
|-----------|--------|
| Unit | PR 머지 차단 |
| Integration | PR 머지 차단 |
| E2E | 경고 + 수동 검토 (flaky 허용) |
