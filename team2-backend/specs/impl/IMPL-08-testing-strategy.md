# IMPL-08 Testing Strategy — 테스트 피라미드

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 테스트 피라미드, 앱별 전략, Mock RFID 시나리오, 커버리지 목표 |
| 2026-04-10 | §4.4 신뢰성/보안 테스트 추가 | IMPL-10 §3~§9 활성 기능(CCR-001/003/006 멱등성·audit_events·Undo·JWT 프로파일·분산락·CB·PII)의 아키텍처 불변 테스트 전략. arq/outbox/saga 테스트는 아키텍처 결정 후 추가 |

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

@pytest.fixture
def fake_redis():
    """fakeredis 기반 Redis mock — 분산락/CB/idempotency 테스트용"""
    import fakeredis.aioredis
    redis = fakeredis.aioredis.FakeRedis()
    yield redis
    await redis.flushall()
```

### 4.4 신뢰성/보안 테스트 (IMPL-10 §3~§9 활성 기능)

본 섹션은 **아키텍처 결정(옵션 1/2)과 무관하게** 필요한 테스트 전략을 정의한다. arq worker, outbox dispatcher, saga orchestrator, 202/polling 엔드포인트 관련 테스트는 team2 아키텍처 결정 확정 후 본 섹션에 추가된다.

#### 4.4.1 Retryable / NonRetryable 분류 (IMPL-06 §2.4)

| 대상 | 테스트 케이스 |
|------|-------------|
| `RetryableError` 상속 클래스 | 5xx, 408, 429 상황에서 자동 재시도 정책 적용 확인 |
| `NonRetryableError` 상속 클래스 | 4xx(401/403/404/409/422) 재시도 미적용 확인 |
| `IdempotentOnlyRetryable` | Idempotency-Key 동반 시에만 재시도 활성화 |
| FastAPI exception handler | Retryable → 5xx + `Retry-After` 헤더, NonRetryable → 4xx 매핑 |

#### 4.4.2 Idempotency-Key 미들웨어 (CCR-003, IMPL-10 §3.1)

| 시나리오 | 기대 결과 |
|---------|----------|
| 최초 요청 + 키 | 정상 처리, 응답 캐싱 (Redis + DB 백업) |
| 동일 키 + 동일 request_hash | 캐시 재생, `Idempotent-Replayed: true` 헤더 |
| 동일 키 + 상이 request_hash | `409 IDEMPOTENCY_KEY_REUSED` |
| 키 누락 + mutation | 정상 처리, 재시도 안전성 미보장 경고 |
| Redis 장애 + DB 백업 hit | DB 백업으로 캐시 재생 (2-tier fallback) |
| TTL 만료 후 동일 키 | 새 요청으로 처리 |

**Fixture**: `fake_redis` + 인메모리 SQLite `idempotency_keys` 테이블. `IdempotencyMiddleware` 를 FastAPI TestClient 에 주입하여 미들웨어 레벨에서 검증.

#### 4.4.3 audit_events append-only 가드 (CCR-001, IMPL-10 §7.1)

| 대상 | 테스트 케이스 |
|------|-------------|
| `EventRepository.append()` | 정상 INSERT + `seq` 단조증가 + `(table_id, seq)` UNIQUE |
| Repository 인터페이스 | `update()` / `delete()` 메서드 **부재** 확인 (AttributeError 기대) |
| 직접 SQL UPDATE 시도 | 통합 테스트에서 raw SQL 로 UPDATE 시도 → 애플리케이션 계층 가드 작동 또는 경고 로그 |
| `dispatched_at` 예외 업데이트 | `dispatcher` 만 이 컬럼 UPDATE 가능, 다른 경로는 금지 |
| Phase 3+ trigger 검증 | PostgreSQL 전환 시 `BEFORE UPDATE OR DELETE` trigger 차단 (마이그레이션 테스트) |

#### 4.4.4 Undo / Inverse 이벤트 역산 (CCR-001, IMPL-10 §7.2)

| 시나리오 | 기대 결과 |
|---------|----------|
| 좌석 이동 이벤트 → Undo | inverse 이벤트가 `audit_events` 에 append (원본 삭제 없음) |
| inverse 이벤트 `causation_id` | 원 이벤트 `id` 와 정확히 일치 |
| `correlation_id` 전파 | 원 이벤트와 동일 값 유지 |
| Undo 후 상태 재계산 | `audit_events` `seq` 순 apply → 원 상태 복원 |
| 이중 기록 | `audit_events` (상태 변경) + `audit_logs` (관리 액션 감사) 둘 다 기록 |
| `undoable: false` 이벤트 | Undo 시도 시 거부 (`UndoNotAllowedError`) |

#### 4.4.5 JWT 환경 프로파일 (CCR-006, IMPL-10 §9.1)

| 프로파일 | 기대 Access TTL | 기대 Refresh TTL |
|---------|----------------|-----------------|
| `dev` | 3600s (1h) | 604800s (7d) |
| `staging` | 7200s (2h) | 604800s (7d) |
| `prod` | 7200s (2h) | 604800s (7d) |
| `live` | 43200s (12h) | 604800s (7d) |

| 테스트 케이스 | 검증 |
|-------------|------|
| 프로파일 전환 | 환경변수 변경 후 `/auth/login` 응답 `expires_in` 확인 |
| 만료 임박 자동 refresh | Access 만료 5분 전 클라이언트가 `/auth/refresh` 호출 → 새 Access 발급, Refresh 유지 |
| Refresh 만료 | 401 + 로그아웃 안내 |
| blacklist 적용 | 관리자 kick 후 30초 내 해당 `jti` 401 반환 |
| WebSocket `token_expiring` | 만료 임박 이벤트 발행 (연결 유지) |

#### 4.4.6 분산락 동시성 (IMPL-10 §4.1)

| 시나리오 | 기대 결과 |
|---------|----------|
| 동일 `lock:table:{id}` 동시 100 acquire | 1개만 성공, 99개 대기 또는 503 |
| fencing token 단조증가 | 연속 acquire 시 token N+1 > N |
| TTL 만료 후 stale 요청 | fencing token 검증으로 stale 거부 |
| lease 연장 | 장기 작업 중 `EXPIRE` 갱신 → TTL 연장 확인 |
| 락 획득 실패 재시도 | 3회(10ms/50ms/200ms) 후 503 LOCK_UNAVAILABLE |
| Redis 장애 | 즉시 503 (fallback 없음, INV-2 의도된 거부) |

**Fixture**: `fake_redis` + `asyncio.gather` 로 병렬 코루틴 100개 생성.

#### 4.4.7 서킷브레이커 상태 전이 (IMPL-10 §3.3)

| 전이 | 조건 | 검증 |
|------|------|------|
| CLOSED → OPEN | 20 req window 중 실패율 ≥ 50% | OPEN 상태 진입 + 후속 요청 즉시 실패 |
| OPEN → HALF_OPEN | 30s 경과 | 1 req 시범 허용 |
| HALF_OPEN → CLOSED | 시범 성공 | 정상 경로 복귀 |
| HALF_OPEN → OPEN | 시범 실패 | OPEN 재진입, 30s 재대기 |
| WSOP LIVE fallback | OPEN 중 요청 → Fallback Queue 로 적재 | BO-02 §7.1 fallback 흐름 확인 |
| 메트릭 노출 | `wsop_live_cb_state` Prometheus gauge 상태 반영 | 모의 장애 주입 후 gauge 값 확인 |

#### 4.4.8 PII 로깅 차단 (IMPL-10 §9.2, 진입 게이트 #16)

| 대상 | 테스트 케이스 |
|------|-------------|
| logging Filter | 이메일/전화/JWT/이름 마스킹 확인 |
| 로그 출력 스캔 | 테스트 중 생성된 `.log` 파일을 정규식 스캔 → PII hit 0건 |
| 마스킹 실패 시 | FN 발견 시 패턴 추가 프로세스 문서화 (IMPL-07 참조) |
| 정적 스캔 | `detect-secrets scan src/` pre-commit hook 작동 확인 |
| PII 정의 | 이름(한글 포함), 이메일, 전화, IP 주소, JWT, 신용카드 번호 |

#### 4.4.9 이벤트 seq 연속성 (CCR-015, IMPL-10 §4.2)

| 시나리오 | 기대 결과 |
|---------|----------|
| 동일 테이블 이벤트 1000건 병렬 append | `seq` 1~1000 전부 존재, gap 0 |
| 여러 테이블 병렬 append | 각 테이블별 독립 시퀀스, 상호 간섭 없음 |
| replay 엔드포인트 | `since=0&limit=500` → 500건, `has_more=true`, `last_seq=500` |
| seq 중복 방지 | `(table_id, seq)` UNIQUE 위반 시 IntegrityError |
| 부팅 후 `MAX(seq)` 복원 | 재시작 시 이어서 단조증가 |

#### 4.4.10 Phase 1 진입 게이트 매핑

IMPL-10 §10 매트릭스의 16개 항목 중 본 섹션(4.4)이 커버하는 항목:

| 게이트 # | 항목 | 본 섹션 |
|----------|------|---------|
| 5 | 멱등성 100% mutation | §4.4.2 |
| 6 | 재시도 정책 | §4.4.1 |
| 7 | 서킷브레이커 전파 | §4.4.7 |
| 8 | 분산락 충돌 0 | §4.4.6 |
| 9 | 이벤트 seq 연속성 | §4.4.9 |
| 11 | audit_events 커버 | §4.4.3 |
| 12 | Undo inverse 성공 | §4.4.4 |
| 14 | JWT 프로파일 일치 | §4.4.5 |
| 16 | PII 로깅 0 | §4.4.8 |

나머지 게이트(#1 p95, #2 RFID E2E, #3 연속운영, #4 MTTR, #10 캐시, #13 DR, #15 인덱스)는 §5 E2E 또는 §8 CI 또는 Phase 1.5 이전 항목으로 다룬다.

> **아키텍처 결정 대기 중 미작성 테스트**: `after_commit` outbox dispatcher 매트릭스 8종, arq worker 재시작 복구, saga orchestrator 6단계 + 보상, 202/polling 계약. 이 테스트들은 C1/C2 아키텍처 결정(옵션 1: outbox+arq vs 옵션 2: BackgroundTasks) 확정 후 본 섹션 §4.4.11 이후에 추가된다.

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
