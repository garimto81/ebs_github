---
title: Dependency Injection
owner: team2
tier: internal
legacy-id: IMPL-05
last-updated: 2026-04-15
confluence-page-id: 3818685011
confluence-parent-id: 3811770578
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818685011/EBS+Dependency+Injection
---

# IMPL-05 Dependency Injection — Real/Mock HAL 교체 + 테스트 패턴

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | Riverpod DI 전략, RFID HAL 교체, BO URL 주입, 테스트 Mock 패턴 |
| 2026-04-10 | BO 신뢰성 DI 추가 | Redis client, distributed lock provider, idempotency store, circuit breaker registry, audit event repository (IMPL-10 §3~§7 정합) |
| 2026-04-10 | CCR-001/003/006/010 반영 | contracts 반영 완료 — `get_idempotency_store`, `get_audit_repo`, `get_saga_orchestrator` DI + AUTH_PROFILE/JWT_ACCESS_TTL_S 환경변수 확정. 독립 영역(Redis, distributed_lock, circuit_breaker, wsop_live_client)과 통합 (중간 "의존 축소" 단계는 git log 참조) |

---

## 개요

이 문서는 EBS의 **의존성 주입(Dependency Injection)** 전략을 정의한다. CC(Flutter)는 Riverpod Provider 오버라이드로 Real/Mock 구현체를 교체하고, BO(Python)는 FastAPI Depends로 서비스를 주입한다.

> 참조: API-03 §7 DI 교체 메커니즘, BS-00 §9 Mock 모드 정의, IMPL-03 Provider 트리

---

## 1. DI 원칙

### 1.1 핵심 규칙

| 규칙 | 설명 |
|------|------|
| 인터페이스 참조만 | 앱 코드는 추상 인터페이스만 참조. 구현체 직접 import 금지 |
| 구성(Composition) 루트 | 앱 시작점(main.dart, main.py)에서만 구현체를 결정 |
| 테스트 격리 | 모든 외부 의존성은 테스트에서 Mock으로 교체 가능해야 함 |
| 런타임 교체 | RFID 모드는 런타임에 변경 가능 (현재 핸드 종료 후 적용) |

### 1.2 DI 방식 비교

| 앱 | DI 메커니즘 | 이유 |
|----|-----------|------|
| CC (Flutter) | Riverpod Provider Override | Flutter 공식 상태 관리. 위젯 트리 통합 |
| BO (Python) | FastAPI Depends | 프레임워크 내장. 요청별 의존성 주입 |
| Engine (Dart) | 생성자 주입 | 프레임워크 없는 순수 Dart. 단순 생성자 주입 |

---

## 2. CC — Riverpod DI

### 2.1 RFID HAL 교체

RFID HAL은 EBS DI의 핵심 사례다. `IRfidReader` 추상 인터페이스를 통해 Real HAL(ST25R3911B)과 Mock HAL을 교체한다.

| Provider | 역할 | 의존 대상 |
|----------|------|----------|
| `rfidModeProvider` | RFID 모드 (real/mock) 결정 | BO Config |
| `rfidReaderProvider` | IRfidReader 인스턴스 생성 | rfidModeProvider |
| `rfidEventsProvider` | 이벤트 스트림 제공 | rfidReaderProvider |

**교체 흐름:**

```
BO Config (rfid_mode: "mock")
    │
    ▼
rfidModeProvider → RfidReaderMode.mock
    │
    ▼
rfidReaderProvider → MockRfidReader()
    │
    ▼
rfidEventsProvider → Stream<RfidEvent>
    │
    ▼
Application (구현체 무관하게 이벤트 소비)
```

> 참조: API-03 §7 Provider 정의 코드

### 2.2 BO URL 주입

| Provider | 역할 | 소스 |
|----------|------|------|
| `boUrlProvider` | BO 서버 URL | 환경 변수 `BO_URL` 또는 기본값 `http://localhost:8000` |
| `apiClientProvider` | REST API 클라이언트 인스턴스 | boUrlProvider |
| `wsClientProvider` | WebSocket 클라이언트 인스턴스 | boUrlProvider + authStateProvider |

### 2.3 Auth 토큰 주입

| Provider | 역할 | 소스 |
|----------|------|------|
| `authStateProvider` | JWT 토큰 + 사용자 정보 | 로그인 / Secure Storage |
| `authInterceptorProvider` | HTTP 요청에 Bearer 토큰 자동 첨부 | authStateProvider |

### 2.4 전체 Provider 오버라이드 목록

| Provider | 프로덕션 구현체 | 테스트 Mock |
|----------|--------------|-----------|
| `rfidReaderProvider` | `RealRfidReader` 또는 `MockRfidReader` | `MockRfidReader` (항상) |
| `apiClientProvider` | BO REST 클라이언트 | `MockApiClient` |
| `wsClientProvider` | BO WebSocket 클라이언트 | `MockWsClient` |
| `boUrlProvider` | 환경 변수 URL | `http://localhost:8000` |
| `secureStorageProvider` | `FlutterSecureStorage` | `MockSecureStorage` |
| `serialPortProvider` | 실제 Serial 포트 | `MockSerialPort` |

---

## 3. CC — 테스트 Mock 패턴

### 3.1 ProviderScope 오버라이드

```dart
// 위젯 테스트 예시
testWidgets('GamePage shows hand info', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        rfidReaderProvider.overrideWithValue(MockRfidReader()),
        apiClientProvider.overrideWithValue(MockApiClient()),
        wsClientProvider.overrideWithValue(MockWsClient()),
        authStateProvider.overrideWith(
          (ref) => AuthState.authenticated(mockUser),
        ),
      ],
      child: const MaterialApp(home: GamePage(tableId: 1)),
    ),
  );
});
```

### 3.2 Mock 구현 규칙

| 규칙 | 설명 |
|------|------|
| Mock은 인터페이스를 구현한다 | `MockRfidReader implements IRfidReader` |
| Mock 동작은 결정적이다 | 동일 입력 → 동일 출력. 랜덤 요소 없음 |
| Mock에 부작용 없다 | 파일 I/O, 네트워크, 시스템 호출 없음 |
| Mock은 에러 주입을 지원한다 | `injectError()` 메서드로 에러 시나리오 재현 |

### 3.3 테스트별 오버라이드 전략

| 테스트 유형 | 오버라이드 범위 |
|-----------|--------------|
| 유닛 테스트 (Engine) | DI 불필요 — 순수 함수 직접 호출 |
| 위젯 테스트 (CC UI) | RFID + API + WS + Auth 전부 Mock |
| 통합 테스트 (CC) | RFID Mock + 실제 BO (로컬 테스트 서버) |
| E2E 테스트 | RFID Mock + 실제 BO + 실제 Lobby |

---

## 4. BO — FastAPI Depends

### 4.1 서비스 주입

| Depends | 역할 | 프로덕션 | 테스트 | 의존성 |
|---------|------|---------|--------|--------|
| `get_db()` | DB 세션 | SQLite/PostgreSQL 세션 | 인메모리 SQLite | 독립 |
| `get_redis()` | Redis 클라이언트 (pool) | `redis.asyncio.Redis` | `fakeredis` | 독립 |
| `get_current_user()` | JWT → 사용자 객체 | JWT 디코딩 + DB 조회 | Mock 사용자 반환 | 독립 |
| `get_table_service()` | 테이블 비즈니스 로직 | `TableService(db)` | `MockTableService` | 독립 |
| `get_auth_service()` | 인증 비즈니스 로직 | `AuthService(db)` | `MockAuthService` | 독립 |
| `get_distributed_lock()` | 테이블·리밸런싱 분산락 (IMPL-10 §4.1) | `RedisDistributedLock(redis)` | `InMemoryLock` | 독립 |
| `get_circuit_breaker(name)` | 외부 API 호출부 서킷브레이커 (IMPL-10 §3.3) | `CircuitBreakerRegistry.get(name)` | `AlwaysClosedBreaker` | 독립 |
| `get_wsop_live_client()` | WSOP LIVE 폴링 클라이언트 + CB 래핑 | `CircuitBreakerWrapped(WsopLiveClient())` | `MockWsopLiveClient` | 독립 |
| `get_idempotency_store()` | `Idempotency-Key` 캐시 (IMPL-10 §3.1) | `RedisIdempotencyStore(redis, db)` | `InMemoryIdempotencyStore` | CCR-003 활성 — DATA-04 §5.1 |
| `get_audit_repo()` | `audit_events` append-only repository (IMPL-10 §7.1) | `AuditEventRepository(db)` | `InMemoryAuditRepo` | CCR-001 활성 — DATA-04 §5.2 |
| `get_saga_orchestrator()` | Rebalance saga 오케스트레이터 (IMPL-10 §3.4) | `RebalanceSagaOrchestrator(lock, audit_repo, wsop_client, event_bus)` | `MockSagaOrchestrator` | CCR-010 활성 — API-01 `/tables/rebalance` |

**등록 위치**: `src/di/providers.py` — 싱글턴 또는 request-scope 생명주기로 분리.
**초기화 순서**: Redis → DB → CircuitBreakerRegistry → `AuditEventRepository` → `IdempotencyStore` → 상위 서비스. FastAPI `lifespan` 이벤트로 구성.

### 4.2 DB 세션 관리

```python
# 프로덕션: SQLite 또는 PostgreSQL
async def get_db():
    async with async_session() as session:
        yield session

# 테스트: 인메모리 SQLite
@pytest.fixture
def db_session():
    engine = create_engine("sqlite:///:memory:")
    SQLModel.metadata.create_all(engine)
    with Session(engine) as session:
        yield session
```

### 4.3 RBAC 가드 주입

```python
# 역할 확인 Depends
def require_role(*roles: str):
    async def checker(user = Depends(get_current_user)):
        if user.role not in roles:
            raise HTTPException(403, "Permission denied")
        return user
    return checker

# 사용 예
@router.put("/configs/{key}")
async def update_config(
    key: str,
    value: str,
    user = Depends(require_role("admin")),
    db = Depends(get_db),
):
    ...
```

---

## 5. Engine — 생성자 주입

### 5.1 순수 함수 패턴

Game Engine은 프레임워크 없는 순수 Dart 패키지다. DI 컨테이너 대신 **생성자 주입**과 **순수 함수**를 사용한다.

| 패턴 | 설명 |
|------|------|
| `apply(GameState, Event) → GameState` | 순수 함수. 외부 의존성 없음 |
| `HandFSM(rules: GameRules)` | 생성자로 규칙 주입 |
| `HandEvaluator()` | 상태 없는 유틸리티. 주입 불필요 |

### 5.2 게임 규칙 교체

```dart
// Hold'em 규칙
final engine = GameEngine(rules: HoldemRules());

// Omaha 규칙
final engine = GameEngine(rules: OmahaRules());

// 테스트: 커스텀 규칙
final engine = GameEngine(rules: MockRules(maxPlayers: 2));
```

---

## 6. 환경 변수 주입

### 6.1 CC 환경 변수

| 변수 | 기본값 | 설명 | 주입 위치 |
|------|--------|------|----------|
| `BO_URL` | `http://localhost:8000` | Back Office 서버 URL | boUrlProvider |
| `RFID_MODE` | `mock` | RFID 모드 (real/mock) | rfidModeProvider 초기값 |

> 참조: IMPL-09 §4 환경 변수 전체 목록

### 6.2 BO 환경 변수

| 변수 | 기본값 | 설명 | 주입 위치 |
|------|--------|------|----------|
**연결·인증**

| 변수 | 기본값 | 설명 | 주입 위치 |
|------|--------|------|----------|
| `DATABASE_URL` | `sqlite:///ebs.db` | DB 연결 문자열 | database.py |
| `REDIS_URL` | `redis://localhost:6379/0` | Redis 연결 URL | `get_redis()` |
| `JWT_SECRET` | 없음 (필수) | JWT 서명 키 | security.py |
| `JWT_ALGORITHM` | Phase 1 `HS256` / Phase 3+ `RS256` | JWT 알고리즘 | security.py |
| `AUTH_PROFILE` | `dev` | 인증 프로파일 — `dev\|staging\|prod\|live` (BS-01 §5, CCR-006) | security.py |
| `JWT_ACCESS_TTL_S` | 프로파일별 자동 (dev 3600 / staging·prod 7200 / live 43200) | Access Token TTL 초 | security.py |
| `JWT_REFRESH_TTL_S` | `604800` (7d) | Refresh Token TTL 초 | security.py |

**타임아웃 카탈로그** (IMPL-10 §6 정본과 일치)

| 변수 | 기본값 | 설명 | 주입 위치 |
|------|--------|------|----------|
| `HTTP_TIMEOUT_MS` | `30000` (30s) | HTTP 요청 타임아웃 (client → BO) | FastAPI 미들웨어 / httpx client |
| `WSOP_POLL_TIMEOUT_MS` | `10000` (10s) | BO → WSOP LIVE 폴링 타임아웃 | `get_wsop_live_client()` |
| `DB_QUERY_TIMEOUT_MS` | `5000` (5s) | DB 쿼리 타임아웃 | SQLAlchemy engine options |
| `REDIS_TIMEOUT_MS` | `500` | Redis 명령 타임아웃 | `get_redis()` socket_timeout |
| `WS_PING_INTERVAL_MS` | `30000` | WebSocket idle ping 주기 | websocket manager |
| `WS_PONG_TIMEOUT_MS` | `60000` | WebSocket pong 대기 타임아웃 | websocket manager |
| `SAGA_TIMEOUT_MS` | `60000` | Saga 전체 타임아웃 | saga orchestrator (아키텍처 결정 후 arq job_timeout 로 이전 가능) |

**WSOP LIVE 동기화**

| 변수 | 기본값 | 설명 | 주입 위치 |
|------|--------|------|----------|
| `WSOP_LIVE_BASE_URL` | 없음 | WSOP LIVE API base | `get_wsop_live_client()` |
| `WSOP_POLL_INTERVAL_S` | `5` | 폴링 간격 | sync worker |

**서킷브레이커 · 분산락 · 멱등성**

| 변수 | 기본값 | 설명 | 주입 위치 |
|------|--------|------|----------|
| `CB_FAILURE_RATIO` | `0.5` | 서킷브레이커 실패율 임계 | CircuitBreakerRegistry |
| `CB_WINDOW_SIZE` | `20` | 서킷브레이커 윈도우 | CircuitBreakerRegistry |
| `CB_OPEN_DURATION_S` | `30` | OPEN 지속 시간 | CircuitBreakerRegistry |
| `LOCK_DEFAULT_TTL_S` | `10` | 분산락 기본 TTL | `get_distributed_lock()` |
| `IDEMPOTENCY_TTL_S` | `86400` (24h) | idempotency_keys TTL (DATA-04 §5.1) | `get_idempotency_store()` |

> `ACCESS_TOKEN_EXPIRE_MINUTES` / `REFRESH_TOKEN_EXPIRE_DAYS` 는 `AUTH_PROFILE` + `JWT_ACCESS_TTL_S` / `JWT_REFRESH_TTL_S` 로 대체되었다 (CCR-006 활성).
>
> **IMPL-09 docker-compose 와 정합 필수**: 위 타임아웃 7종 + WSOP 2종 + CB 3종 + Lock/Idem 2종은 docker-compose `environment:` 섹션에 **동일 변수명**으로 선언되어야 한다. 불일치 시 uvicorn 기동 후 런타임 검증 실패 (app startup 시 `settings.validate()` 강제).

---

## 7. DI 안티패턴 (금지)

| 안티패턴 | 위험 | 올바른 방식 |
|---------|------|-----------|
| 싱글톤 직접 접근 | 테스트 격리 불가, 전역 상태 오염 | Riverpod Provider 또는 Depends |
| 구현체 직접 import | 교체 불가, 결합도 증가 | 추상 인터페이스만 import |
| 환경 변수 직접 읽기 (코드 중간) | 테스트 시 환경 변수 조작 필요 | Provider로 감싸서 오버라이드 |
| 서비스 로케이터 패턴 | 암묵적 의존성, 런타임 에러 | 명시적 생성자/Provider 주입 |
| 조건부 import (`if (kDebugMode)`) | Mock이 프로덕션에 누출 | DI로 외부에서 결정 |
