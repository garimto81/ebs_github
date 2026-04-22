---
title: Non Functional Requirements
owner: team2
tier: internal
legacy-id: IMPL-10
last-updated: 2026-04-15
---

# IMPL-10 NFR — 비기능 요구사항 (신뢰성·일관성·복구 포함)

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | 성능, 가용성, 확장성 요구사항 |
| 2026-04-10 | 전면 재작성 | WSOP LIVE Confluence 대조 결과 반영. §3 신뢰성 프로토콜, §4 동시성·순서, §5 캐시 일관성, §6 타임아웃, §7 감사·복구, §8 확장성, §9 보안·규정, §10 측정 매트릭스 신설 |
| 2026-04-10 | CCR-001/003/006/010/015 반영 | contracts 정식 반영 완료. team2 문서는 구현 가이드(미들웨어 위치, DI 이름, 메트릭 명명, 운영 판단)만 유지. 헤더·필드·테이블 정의는 contracts가 SSOT. 독립 영역(재시도, 서킷브레이커, 분산락, 시계, 캐시, 타임아웃, 확장성)은 본 문서에서 상세 유지 (중간 "의존 축소" 단계는 git log 참조) |

---

## 개요

EBS 3-앱 아키텍처(Lobby / CC / BO)의 **비기능 요구사항**(Non-Functional Requirements)을 정의한다. 본 문서는 단순 수치 나열이 아니라 **"측정 방법 / 수용 기준 / 롤백 트리거"** 세 축으로 구조화되어 있어, Phase 1 진입 전 Phase 게이트 판단에 사용한다.

방송 환경의 특성상 신뢰성(§3), 동시성(§4), 복구(§7)가 특히 중요하다. 이 섹션들은 WSOP LIVE 실제 프로덕션 운영 경험(`C:\claude\wsoplive\docs\confluence-mirror\`)을 참고하여 작성되었다.

> **계약 경계 원칙**: `contracts/api/`, `contracts/data/`, `contracts/specs/` 변경이 필요한 항목의 **정본은 contracts/**. 본 문서는 정본을 중복 기재하지 않고 참조한다. 구현 가이드(미들웨어 위치, DI 이름, 메트릭 명명, Phase 1 SQLite 매핑 등)만 team2 영역에서 확정한다.
>
> **CCR 활성화 완료 (contracts 반영)**:
> - **CCR-001** — `idempotency_keys` / `audit_events` 테이블 → `contracts/data/DATA-04 §5.1, §5.2`
> - **CCR-003** — `Idempotency-Key` 헤더 → `contracts/api/API-01 §공통 요청 헤더`, 409 `IDEMPOTENCY_KEY_REUSED`
> - **CCR-006** — BS-01 JWT AUTH_PROFILE (dev 1h / staging·prod 2h / **live 12h**) → `contracts/specs/BS-01-auth/BS-01-auth.md §5`
> - **CCR-010** — `/tables/rebalance` saga 응답 (`saga_id`, `steps[]`, 200/207/500) → `contracts/api/API-01 §POST /tables/rebalance`
> - **CCR-015** — WebSocket `seq`/`server_time` envelope + `GET /api/v1/tables/{id}/events?since={seq}` → `contracts/api/API-05 §envelope`, `contracts/api/API-01 §replay`

---

## 1. 성능

| 지표 | 초기 목표 | 성숙 목표 | 측정 방법 | 수용 기준 | 롤백 트리거 |
|------|:--------:|:--------:|----------|----------|------------|
| RFID 카드 → 오버레이 표시 | < 200ms | < 100ms | E2E trace_id span (CC → BO → Overlay) | p95 연속 10분 만족 | p95 > 300ms 지속 5분 |
| CC 액션 → 오버레이 반영 | < 150ms | < 80ms | WebSocket 왕복 + 렌더 타임스탬프 | p95 연속 10분 만족 | p95 > 250ms 지속 5분 |
| Lobby 페이지 로드 (LCP) | < 2s | < 1s | Lighthouse CI + 실 사용자 RUM | p75 2s 미만 | p75 > 3s |
| API 응답 시간 (p95) | < 500ms | < 200ms | Prometheus histogram, 5min window, bucket [10, 50, 100, 200, 500, 1000, 2000ms] | p95 목표 + p99 < 2×p95 | p95 > 목표 × 1.5 지속 5분 |
| WebSocket 메시지 처리 | < 50ms | < 20ms | 클라이언트 ingress timestamp 대비 렌더 완료 | p95 연속 10분 만족 | p95 > 목표 × 2 |
| **DB polling snapshot (§5.18)** | < 200ms p95 | < 100ms p95 | HTTP latency. 호출 주기 1-5초 (Foundation §6.4) | p95 만족 + payload size < 100KB | p95 > 500ms 지속 5분 |
| **crash 복구 (snapshot 재로드)** | < 5s | < 2s | 프로세스 재시작 → baseline 복원 완료 wall-clock | 실측 < 목표 | DR 실패 |
| **WebSocket push 지연** | < 100ms | < 50ms | BO DB commit → 소비자 수신 timestamp (Foundation §6.4 SLO) | p95 만족 | p95 > 200ms 지속 5분 |

**측정 도구**: Prometheus + Grafana (서버), Sentry Performance (클라), OpenTelemetry trace_id 분산 추적.

> **Foundation §6.4 매핑** (2026-04-22): WS push <100ms + DB polling 1-5s + crash 복구 < 5s 를 본 표에 통합. 이전 "Phase 1/3" 라벨은 "초기/성숙" 중립 표현으로 교체 (2026-04-20 프로젝트 의도 재정의 반영).

---

## 2. 가용성

| 지표 | 초기 | 성숙 | 측정 방법 | 롤백 트리거 |
|------|------|------|----------|------------|
| **연속 운영 (live 방송)** | ≥ 4h 무중단 | **≥ 16h 무중단** | uptime 모니터, 방송 시작~종료 연속 health check | unplanned downtime > 60s |
| 가동률 (월) | ≥ 99.0% | ≥ 99.5% | (total - downtime) / total | 월 가동률 < 목표 |
| 크래시 복구 (MTTR) | < 30s | < 15s | 프로세스 감시 후 자동 재시작 + 세션 복원 (BS-02) | MTTR > 60s |
| MTBF | ≥ 4h (초기) | ≥ 24h | crash 간격 평균 | MTBF < 목표의 50% |
| Graceful shutdown | — | < 10s | SIGTERM 수신 → 진행 요청 완료 → 새 요청 거부 → 종료 | 강제 kill 발생 |

> **성숙 ≥16h 근거**: WSOP+ Architecture는 단일 AWS California 리전에서 연속 14-16h 방송을 운영한다. EBS는 N PC + 중앙 서버 (Foundation §8.5) 성숙 운영 시 동등 수준의 가용성을 목표로 한다.

**Graceful Shutdown 정의**:
1. SIGTERM 수신
2. 신규 요청 거부 (`/health` 503 반환)
3. 진행 중 요청 완료 대기 (max 10s)
4. WebSocket 연결에 `server_shutdown` 이벤트 발행 후 종료
5. DB connection pool 정리
6. 프로세스 종료

---

## 3. 신뢰성 프로토콜 (신규)

WSOP 운영 경험상 가장 자주 발생하는 사고는 "네트워크 재시도로 인한 중복 처리"와 "외부 API 장애 전파"다. 본 섹션은 이를 방지하는 프로토콜을 정의한다.

### 3.1 멱등성 (Idempotency) — [CCR-003, CCR-001 활성]

**정본**: `contracts/api/API-01 §공통 요청 헤더 Idempotency-Key`, `contracts/data/DATA-04 §5.1 idempotency_keys`. 헤더 동작(동일키+동일바디 재생 / 상이바디 409 / 키 누락 무보장), 저장소 스키마, `IDEMPOTENCY_KEY_REUSED` 응답 코드 모두 계약에 정의되어 있다.

**team2 구현 가이드** (본 문서 범위):

| 항목 | 결정 |
|------|------|
| 구현 계층 | **FastAPI `BaseHTTPMiddleware`** (`src/middleware/idempotency.py`) — 엔드포인트 Depends 가 아닌 HTTP 요청 경계에서 수행 |
| DI 연결 | 미들웨어 `dispatch()` 내부에서 `request.app.state.idempotency_store` 로 접근. DI `get_idempotency_store()` (IMPL-05 §4.1) 는 **라우트 핸들러용 선택적 주입**으로만 제공 (일부 엔드포인트가 수동 검증이 필요할 때) |
| 이원화 근거 | 미들웨어는 모든 mutation 에 일괄 적용(default-on), DI 는 단위/통합 테스트에서 mock 교체가 필요한 경로에 사용. **두 계층이 같은 store 싱글턴을 바라봄** (`lifespan` 에서 1회 생성 후 `app.state` 와 DI container 양쪽에 등록) |
| 저장소 순위 | Redis `idem:{user_id}:{key}` 1차 → DB `idempotency_keys` 백업 |
| request_hash 알고리즘 | SHA-256 of `{method}\n{path}\n{canonical_body}`. body는 JSON 키 정렬 후 직렬화 |
| 캐시 오버헤드 목표 | < 5ms p95 (Redis hit), < 20ms p95 (DB fallback) |
| 청소 cron | 5분 간격 `DELETE FROM idempotency_keys WHERE expires_at < now()` |
| 범위 제외 | `GET`, health check, 메트릭 엔드포인트 |
| 응답 헤더 | 재생 시 `Idempotent-Replayed: true` 추가 |
| 에러 처리 연결 | IMPL-06 §4.4 (RetryableError 와 구분) |

> **경계 원칙**: 미들웨어는 *요청 수준* 검증(409 즉시 반환), DI 주입은 *서비스 수준* 의도적 호출(재처리/검증 우회 등 예외 경로). 두 경로가 충돌하지 않도록 미들웨어가 먼저 실행되며, 미들웨어가 `Idempotent-Replayed: true` 로 응답을 종료하면 라우트 핸들러는 호출되지 않는다.

### 3.2 재시도 및 백오프

| 호출부 | 재시도 횟수 | 백오프 | Jitter | 총 최대 대기 |
|--------|------------|--------|--------|-------------|
| Client → BO (mutation) | 3회 | 100ms, 500ms, 2000ms (exponential) | ±10% | ~2.6s |
| BO → WSOP LIVE 폴링 | 5회 | 200ms, 1s, 3s, 10s, 30s | ±10% | ~44s |
| BO → Redis | 2회 | 50ms, 200ms | 없음 | ~250ms |
| BO → DB (트랜잭션 외) | 2회 | 100ms, 500ms | 없음 | ~600ms |

**원칙**:
- 재시도 대상은 **read-only** 또는 **idempotent mutation**에 한정
- Non-idempotent 요청은 `Idempotency-Key` 동반 시에만 재시도
- `4xx` 는 재시도 금지 (408 Timeout, 429 Too Many Requests 제외)
- `5xx` 는 재시도 허용

### 3.3 서킷브레이커 (Circuit Breaker)

외부 API 호출부(WSOP LIVE, APIGW, OAuth provider)에 Circuit Breaker 적용.

| 상태 | 조건 | 동작 |
|------|------|------|
| CLOSED | 기본 | 정상 통과 |
| OPEN | 20 req window 중 실패율 ≥ 50% | 즉시 실패, fallback 경로 |
| HALF_OPEN | OPEN 후 30s 경과 | 1 req 시범, 성공 시 CLOSED, 실패 시 OPEN 재진입 |

**Fallback 경로**:
- WSOP LIVE 폴링 실패 → `sync:wsop:pending` Redis Stream 에 요청 저장, 회복 시 cursor 기반 replay (상세: BO-02)
- OAuth 실패 → 캐시된 JWT 공개키로 검증 유지 (단기 장애 허용)

**메트릭** (2026-04-15 G-A5 명세화):

| 메트릭 이름 | 타입 | label | 설명 |
|-----------|:----:|-------|------|
| `ebs_cb_state{name}` | Gauge | name=cb 이름 | 0=CLOSED, 1=HALF_OPEN, 2=OPEN |
| `ebs_cb_requests_total{name,outcome}` | Counter | outcome=success\|failure\|short_circuit | 호출 누적 |
| `ebs_cb_state_transitions_total{name,from,to}` | Counter | from/to 상태 | 전이 이벤트 |
| `ebs_cb_failure_ratio{name}` | Gauge | 20 req window 실패율 |

**CB 이름 규약**: 외부 의존성별 고유 이름 — `cb_wsop_live`, `cb_redis`, `cb_db_replica`, `cb_oauth_provider`. 워커 간 동일 이름 공유.

**상태 저장소** (2026-04-15 G-A5):
- **Phase 1 (단일 워커 / docker-compose dev)**: **per-worker in-memory** (`src/observability/circuit_breaker.py` 의 `CircuitBreaker` 인스턴스, `asyncio.Lock` 보호). Redis 불필요.
- **Phase 2+ (멀티 워커 / k8s)**: Redis 공유 상태 — 상태 변경을 Redis pub/sub 로 브로드캐스트해 워커 간 동기화. 키: `cb:state:{name}` (값: CLOSED/HALF_OPEN/OPEN + 마지막 전이 시각).
- **Provider 선택 근거**: `pybreaker` (Python) 는 단일 프로세스 전용 → EBS 자체 구현 유지. `src/observability/circuit_breaker.py` 가 SSOT.

**경보 트리거**:
- CLOSED → OPEN 전이: Sentry ERROR (즉시)
- OPEN → HALF_OPEN 전이: Sentry INFO (30s 경과 후 시범)
- HALF_OPEN → OPEN 재진입: Sentry WARN (복구 실패)

### 3.4 부분 실패 / 보상 트랜잭션 (Saga) — [CCR-010 활성]

**정본**: `contracts/api/API-01 §POST /tables/rebalance`. saga 응답 3가지 상태(`completed`/`compensated`/`compensation_failed`), `saga_id`, `steps[]`, 200/207/500 상태 코드가 계약에 정의되어 있다.

**team2 구현 가이드**:

| 항목 | 결정 |
|------|------|
| 오케스트레이터 구현 | `src/services/saga/rebalance_orchestrator.py`. 각 step을 coroutine으로 정의 |
| saga_id 생성 | `sg-{YYYYMMDD}-{nanoid(8)}` |
| 단계 멱등성 | 각 단계가 자체 Idempotency-Key 사용. 실패 후 재시도 시 중복 실행 방지 |
| 보상 로직 순서 | 역순 역산 (`release_seats` 보상 = `reassign_original_seats`) |
| 타임아웃 | 단계별 10s, 전체 60s (IMPL-10 §6 `SAGA_TIMEOUT_MS`) |
| 분산락 | `lock:rebalance:{event_flight_id}` 30s TTL (§4.1) |
| 이벤트 기록 | 각 단계 진입/완료/실패를 `audit_events` 에 append (§7) |
| 운영자 알림 | `compensation_failed` 시 Sentry 경보 + Lobby 경고 모달 |
| 확장 대상 | `/tournaments/{id}/finalize` (Stage 2+), 결제 연동 (Stage 3+) |

---

## 4. 동시성 및 순서

### 4.1 분산락 (Distributed Lock)

다중 BO 인스턴스 또는 동일 인스턴스의 여러 요청이 같은 자원에 접근할 때 race condition 방지.

| 자원 | 락 키 | TTL | fencing |
|------|------|-----|---------|
| 테이블 상태 변경 | `lock:table:{id}` | 10s | 예 (Redis INCR로 token 발급) |
| 리밸런싱 (다중 테이블) | `lock:rebalance:{event_flight_id}` | 30s | 예 |
| 블라인드 변경 | `lock:blinds:{event_flight_id}` | 5s | 예 |
| 토너먼트 상태 전이 | `lock:tournament:{id}` | 10s | 예 |

**구현**: Redis `SET NX EX` + fencing token. 락 획득 실패 시 3회 재시도 (10ms, 50ms, 200ms 백오프). 장기 작업은 lease 연장 (`EXPIRE` 주기 호출).

**Fencing**: 락이 만료된 후 돌아온 요청이 최신 락 홀더를 덮어쓰는 사고를 방지. 각 요청은 fencing token을 저장소 작업에 동반하고, 저장소는 이전 token보다 작은 값을 거부.

> Gap: **GAP-BO-003** 참조. 본 문서의 수치는 team2 내부 결정.

### 4.2 이벤트 순번 (Event Sequence) — [CCR-015, CCR-001 활성]

**정본**: `contracts/api/API-05 §envelope` 에 `seq`/`server_time` 필드, `contracts/api/API-01 §replay` 에 `GET /api/v1/tables/{table_id}/events?since={seq}&limit=N`, `contracts/data/DATA-04 §5.2` 에 `audit_events.seq` (UNIQUE per `table_id`).

**team2 구현 가이드**:

| 항목 | 결정 |
|------|------|
| seq 생성 | `audit_events` INSERT 시 `SELECT COALESCE(MAX(seq),0)+1 FROM audit_events WHERE table_id=?` 를 단일 트랜잭션으로 수행 |
| 동시성 보장 | 같은 테이블의 이벤트 기록은 `lock:table:{id}` 분산락 하에서만 (§4.1) — UNIQUE 위반 사전 차단 |
| 브로드캐스트 순서 | DB commit 후에만 WebSocket publish. Outbox 패턴 겸용 (`audit_events` 가 outbox 역할) |
| HA failover 시작 | 부팅 시 `MAX(seq)` 읽어 워커 메모리 cache, 이후 INSERT 는 DB가 SSOT |
| 글로벌 이벤트 | `table_id="*"` 로 독립 시퀀스 (ex: 시스템 점검, config 변경) |
| replay 쿼리 페이징 | 기본 `limit=500`, 최대 `2000`. 페이징 끝 `has_more=false` |
| 레이트 리미트 | replay 엔드포인트 `10 req/sec per table per client` |
| 클라 gap handler | IMPL-03 §4.1 참조 (Riverpod StreamProvider에 gap 감지 미들웨어) |

### 4.3 서버 시계 동기화

| 항목 | 정책 |
|------|------|
| NTP | chrony 설치, offset < 100ms 유지, 드리프트 시 경보 |
| 벽시계 사용 금지 | 좌석 할당·이벤트 순서에 `datetime.now()` 사용 금지. 반드시 DB `created_at` (monotonic) 우선 사용 (이벤트 `seq` 기반 정렬은 CCR-015 승인 후) |
| 응답 포함 | 모든 API 응답에 `server_time` 필드 포함 (클라 보정용) |
| WebSocket envelope | `ts`(이벤트 발생 추정) + `server_time`(서버 수신 확정) 병기 |

> Gap: **GAP-BO-006** 참조.

---

## 5. 캐시 일관성

WSOP+ Architecture의 Redis 3계층 캐시(Player/Staff/Tournament)를 참고하여 EBS에 동등 구조 도입.

### 5.1 캐시 키 체계

| 키 | 대상 | TTL (안전망) | 무효화 트리거 |
|----|------|-------------|--------------|
| `table:{id}` | 테이블 상세 | 5min | 테이블 변경 mutation |
| `table:list:{event_flight_id}` | 이벤트별 테이블 목록 | 2min | 테이블 추가/삭제/이동 |
| `player:{id}` | 플레이어 정보 | 10min | 플레이어 프로필 변경 |
| `tournament:{id}` | 토너먼트 상태 | 30min | 토너먼트 상태 전이 |
| `blinds:{event_flight_id}` | 블라인드 구조 | 1h | 블라인드 변경 |
| `config:global` | 글로벌 설정 | 1h | 설정 변경 |

### 5.2 Write-Through + Invalidate-on-Write

1. **Read**: Redis 조회 → miss 시 DB 조회 후 Redis SETEX
2. **Write**: DB UPDATE → 성공 후 Redis DELETE (또는 SETEX 재계산)
3. **Invalidate 전파**: Redis Pub/Sub `cache:invalidate:{entity}` 채널로 모든 워커에 전파
4. **TTL 안전망**: 전파 실패 대비. 누적 최대 지연 = TTL 값

### 5.3 캐시 실패 격리

Redis 장애 시 Circuit Breaker OPEN → DB 직접 조회 (p95 허용 degradation). 앱은 `cache_available=false` 상태 유지, 로그 경보.

> Gap: **GAP-BO-005** 참조.

---

## 6. 타임아웃 정책

방송 운영 중 장기 대기 상태를 자동 정리하기 위한 타임아웃 카탈로그.

| 항목 | 기본값 | 출처 | 환경변수 |
|------|--------|------|---------|
| HTTP 요청 타임아웃 (client→BO) | 30s | 업계 표준 | `HTTP_TIMEOUT_MS=30000` |
| BO → WSOP LIVE 폴링 타임아웃 | 10s | WSOP `Tournament.md` | `WSOP_POLL_TIMEOUT_MS=10000` |
| DB 쿼리 타임아웃 | 5s | — | `DB_QUERY_TIMEOUT_MS=5000` |
| Redis 명령 타임아웃 | 500ms | — | `REDIS_TIMEOUT_MS=500` |
| Late Registration 종료 유예 | 30s | WSOP `LateRegDuration` | `LATE_REG_GRACE_MS=30000` |
| Call Limit (대기자 호출 응답) | 120s | WSOP `Waiting API.md` CallLimit | `CALL_LIMIT_MS=120000` |
| Waiting Room TTL | 30min | WSOP | `WAITING_TTL_MS=1800000` |
| WebSocket idle ping | 30s | — | `WS_PING_INTERVAL_MS=30000` |
| WebSocket pong 타임아웃 | 60s | — | `WS_PONG_TIMEOUT_MS=60000` |
| JWT access 만료 (live 환경) | 12h | WSOP Staff Auth | `JWT_ACCESS_TTL_S=43200` |
| JWT refresh 만료 | 7d | — | `JWT_REFRESH_TTL_S=604800` |
| Distributed lock TTL (일반) | 10s | §4.1 | — |
| Saga 전체 타임아웃 | 60s | — | `SAGA_TIMEOUT_MS=60000` |

> Gap: **GAP-BO-007** 참조. 일부 값은 product 오너 확정 대기(Late Reg 유예, Call Limit).

---

## 7. 감사 및 복구

### 7.1 감사 이벤트 스토어 — [CCR-001 활성]

**정본**: `contracts/data/DATA-04 §5.2 audit_events` (스키마, 제약, 인덱스, 보존 정책, SQLAlchemy 모델 포함).

**team2 구현 가이드**:

| 항목 | 결정 |
|------|------|
| Repository 위치 | `src/repositories/event_repository.py` (`EventRepository`) |
| append 진입점 | 모든 mutation 서비스가 `EventRepository.append(table_id, event_type, payload, ...)` 호출 |
| inverse_payload 생성 | mutation 서비스가 `compute_inverse(current_state, event)` 로 계산 후 함께 append |
| append-only 강제 (Phase 1 SQLite) | `EventRepository` 에 `update()`/`delete()` 메서드 **부재**. 통합 테스트로 검증 |
| append-only 강제 (Phase 3+ PostgreSQL) | DATA-04 §5.2 주석대로 `REVOKE UPDATE, DELETE` + trigger |
| 기록 대상 | 좌석 할당/해제/이동, 블라인드 변경, 토너먼트 상태 전이, 리밸런싱 saga 단계, WSOP LIVE 동기화 분기 복구, Undo/Revive, 관리자 권한 변경 |
| `audit_logs` 와의 구분 | 사람 관리 액션 감사 → `audit_logs` (기존), 상태 변경 이벤트 소싱 → `audit_events` (신규). BO-03 §1.2 참조 |
| batch insert | 단일 요청 내 여러 이벤트는 한 트랜잭션에서 순차 append. Outbox 패턴 겸용 (DB commit 후 WS publish) |

### 7.2 Undo / Revive — [CCR-001 활성]

**정본**: `contracts/data/DATA-04 §5.2` 의 `inverse_payload` 컬럼 정의.

**team2 구현 가이드**:

1. Undo 요청 시 원 이벤트의 `inverse_payload` 를 바탕으로 **새로운 inverse 이벤트** 를 **반드시 `audit_events` 에 append** 한다 (원 이벤트 삭제 금지 — append-only). 이 규칙을 누락하면 Scenario A(CC 크래시 replay, BO-03 §4.1) 복구 시 Undo 가 반영되지 않아 상태 일치율이 깨진다.
2. inverse 이벤트의 `causation_id` 는 원 이벤트의 `id`, `correlation_id` 는 원 이벤트의 것을 그대로 전파 (Undo 체인 추적용).
3. 현재 상태는 `audit_events` 를 `seq` 순으로 apply 한 결과로 재계산 — inverse 이벤트까지 포함해야 올바른 최종 상태가 나온다.
4. **이중 기록 (state vs action)**:
   - `audit_events` ← Undo 의 **상태 변경** 자체 (inverse_payload 기반, event sourcing SSOT)
   - `audit_logs` ← Undo 의 **관리 액션** 기록 (누가/언제/왜 Undo 를 실행했는가, 감사 추적용)
   - 두 테이블은 `correlation_id` 로 묶이며 둘 중 하나만 기록하는 것은 금지.

**Undo 불가 규칙** (WSOP `Action History.md` 의 Revive Eliminated Player 제약 일반화):
- 이벤트 타입별 메타데이터 `undoable: bool` 관리 (`src/domain/events/registry.py`)
- 하위 이벤트가 이미 존재하는 경우 차단 (예: 핸드 완료 후 블라인드 변경 Undo 불가)
- Bounty/Payout 관련 이벤트는 재정 영향이 있어 Undo 금지 (Phase 3+에서 정의)

### 7.3 데이터 손실 복구 절차

> 2026-04-14: BO-03 §4 흡수. DR 시나리오 SSOT.

방송 환경은 완전 가용성을 보장할 수 없다. 부분 장애 발생 시 운영자가 실행할 수 있는 **표준 복구 시나리오**를 정의한다. 모든 시나리오는 `audit_events` 이벤트 스토어(DATA-04 §5.2, §7.1)를 주 복구 소스로 사용한다.

**용어**:
- **Replay**: `audit_events` 를 순차 apply 하여 상태 재구성 (CCR-001)
- **Sync cursor**: WSOP LIVE 마지막 성공 동기화 지점 (`sync_cursor:{entity}`) — BO-02 §7.1
- **Compensating action**: saga 단계 실패 시 역방향 작업 (CCR-010, §3.4)

#### Scenario A: CC 크래시 후 TableState 재구성

**트리거**: Command Center(CC) 프로세스 크래시 또는 네트워크 장기 단절.

**절차**:
1. CC 자동 재시작 (IMPL-06 §4.3 로컬 모드 유지)
2. CC 재기동 시 `GET /api/v1/tables/{id}/events?since=0&limit=500` 호출 — API-01 replay 엔드포인트 (CCR-015)
3. 응답의 `events[]` 를 `seq` 순서로 apply → Riverpod state 재구성
4. 응답의 `has_more=true` 이면 `since={last_seq}` 로 다음 페이지 호출, `has_more=false` 가 나올 때까지 반복
5. 최종 `seq` 를 메모리에 기록하고 WebSocket 재연결
6. 이후 실시간 이벤트는 `seq` 연속성 검증 (§4.2)

**페이징 규칙** (§4.2 및 API-01 replay 계약 준수):

| 항목 | 값 |
|------|----|
| `limit` 기본값 | 500 |
| `limit` 최대값 | 2000 (초과 시 400) |
| 응답 필드 | `events[]`, `last_seq`, `has_more` |
| 레이트 리미트 | 10 req/sec per `(table_id, client)` |
| OOM 방지 | CC 클라이언트는 받은 페이지를 **순차 apply 후 메모리에서 해제**, 전체 버퍼링 금지 |
| 대회 24h 상한 가정 | `audit_events` 최대 ~50만 rows/table → 약 1000 페이지. 클라는 페이지 당 apply 시 50ms 이내 처리 |

**수용 기준**: 10분 내 복구, GameState 일치율 100%, 페이징 중 OOM 0건.

**Edge case**: 복구 중 운영자가 액션 시도 시 IMPL-04 라우트 가드가 임시 잠금 → "복구 중" 모달 + 진행률(`처리 seq / last_seq`) 표시.

#### Scenario B: BO ↔ WSOP LIVE 동기화 분기

**트리거**: WSOP LIVE 폴링 장기 실패 후 재개. BO와 WSOP LIVE 간 토너먼트/플레이어 데이터 분기 발생.

**절차**:
1. BO-02 §7.1 서킷브레이커 HALF_OPEN 전환
2. `sync_cursor:{entity}` 마지막 성공 지점에서 delta 요청 재개
3. 변경분 merge — **BO 우선 규칙**: BO 측에서 수정된 필드는 WSOP LIVE 값보다 우선 (BO-02 §3 충돌 해결 LWW)
4. `audit_events` 에 `wsop_sync_resolved` 이벤트 append (`correlation_id` 로 장애 구간 그룹화)
5. 운영자에게 분기 요약 알림

**수용 기준**: 동기화 cursor 에 기록된 진행 지점만큼 재처리, 중복 0, 누락 0.

**Edge case**: 동일 레코드를 양쪽에서 동시 수정한 경우 → `conflict_detected` 이벤트 + Admin 확인 대기.

#### Scenario C: Redis 캐시 손실

**트리거**: Redis 장애, 재시작, flush. 캐시 계층 전체 소실.

**절차**:
1. Circuit Breaker OPEN → 모든 요청을 DB 직접 조회로 우회
2. p95 응답시간 degrade 허용 (방송 중에도 중단 없이 진행)
3. Redis 복구 후 캐시는 lazy 로딩 (Write-Through 재작동)
4. 일시 중복 응답/stale 가능성을 감수 (TTL 안전망)

**수용 기준**: Redis 전면 장애 중에도 BO API 연속 응답, p95 < 1.5×평상시.

**Edge case**: 분산락(`lock:*`) 소실되지만 fencing token으로 stale 요청 차단. `idempotency_keys` 는 DB 백업(DATA-04 §5.1)에서 재생성. Phase 1 SQLite 환경에서 Redis 미사용 시 본 시나리오 비대상.

#### Scenario D: 부분 롤백 (Saga Compensation Failure)

**트리거**: `POST /tables/rebalance` (API-01, CCR-010) saga 중간 실패 → compensating action 실행 중 또 실패 → 부분 상태 지속.

**절차**:
1. API 응답 `500 Manual intervention required` (`status: "compensation_failed"`) + `audit_cursor: {from_seq, to_seq}` 반환 — 계약 정본 참조
2. 운영자 대시보드에 경고 모달 + `saga_id` 표시
3. Admin이 `audit_events` 조회: `SELECT * FROM audit_events WHERE table_id=? AND seq BETWEEN :from AND :to ORDER BY seq`
4. saga 단계별 `status` 를 확인하여 수동 복구 경로 선택:
   - **재시도 안전**: 동일 `saga_id` + Idempotency-Key 로 재실행 (saga 재개)
   - **수동 정정**: Admin이 구체적 좌석/상태를 수동 수정 → 해당 변경은 `manual_intervention` 이벤트로 `audit_events` 에 기록
5. 복구 완료 후 `manual_intervention_resolved` 이벤트 append

**수용 기준**: 10분 내 Admin 수동 개입으로 일관성 복원. 잔여 부분 상태 0.

**Edge case**: saga 로그 자체가 손상된 경우 → DB 백업에서 해당 테이블만 point-in-time 복원.

> 복구 책임 매트릭스, DR 훈련 일정, 운영자 유저 스토리는 BO-03 §4.5/§4.6/§5 참조.

---

## 8. 확장성

### 8.1 부하 프로파일

| 지표 | 초기 (단일 PC) | 성숙 (N PC + 중앙 서버) | 단위 |
|------|---------------|-----------------------|------|
| 동시 테이블 (CC+Overlay) | 3 | 12 | 테이블 |
| Lobby 동시 사용자 | 5 | 20 | 세션 |
| WebSocket 동시 연결 | 10 | 50 | 연결 |
| 동시 좌석 할당 (피크) | 30 | 120 | ops/s |
| 칩 트랜잭션 (피크) | 10 | 40 | ops/s |
| `audit_events` append | 50 | 200 | rows/s |
| WSOP LIVE 폴링 | 1 | 2 | req/s |

> 배포 모델 정의: Foundation §8.5 단일 PC / N PC + 중앙 서버. "초기" 는 단일 PC 운영 규모, "성숙" 은 N PC 방송 규모.

### 8.2 인덱스 전략

| 테이블 | 인덱스 | 근거 |
|--------|--------|------|
| `table_seats` | `(updated_at)` | WSOP 교훈: full scan 방지 |
| `table_seats` | `(table_id, seat_no)` unique | 좌석 충돌 방지 |
| `hands` | `(table_id, started_at DESC)` | 최근 핸드 조회 |
| `audit_logs` | `(created_at DESC)`, `(user_id, created_at)` | 관리 액션 감사 조회 |
| `audit_events` | `(table_id, seq DESC)` unique | replay 쿼리 최적화 — DATA-04 §5.2 정본 |
| `audit_events` | `(correlation_id)` | 분산 트레이싱 — DATA-04 §5.2 정본 |
| `audit_events` | `(event_type, created_at)` | 이벤트 종류별 조회 — DATA-04 §5.2 정본 |
| `idempotency_keys` | `(user_id, key)` unique, `(expires_at)` | DATA-04 §5.1 정본 |

> Gap: **GAP-BO-010** 참조 (현재 RESOLVED, 본 표에 반영됨).

### 8.3 연결 풀 / 스레드 풀

| 리소스 | Phase 1 | Phase 3 | 공식 |
|--------|---------|---------|------|
| PostgreSQL pool | — | 20 | `(core × 2) + spindle` |
| SQLite (단일 파일) | 1 writer / N reader | N/A | — |
| Redis pool | 10 | 30 | 동시 요청 기반 |
| FastAPI worker | 2 | 4~8 | CPU core 기반 |
| Thread pool (async) | 100 | 200 | I/O bound 기반 |

### 8.4 Batch 처리

- `audit_events` 대량 append 시 단일 트랜잭션 배치 (최대 100 rows 또는 200ms 주기)
- WSOP LIVE 동기화는 delta batch (cursor 기반)
- 통계 집계는 야간 batch
- 로그 집중 전송은 배치 (IMPL-07 §3.3 참조)

---

## 9. 보안 및 규정

### 9.1 인증 · 인가 — [CCR-006 활성]

**정본**: `contracts/specs/BS-01-auth/BS-01-auth.md §5`. 환경 프로파일(dev 1h / staging·prod 2h / **live 12h**), Refresh 7d, WebSocket `token_expiring`/`reauth` 흐름, blacklist 규칙 모두 계약에 정의됨.

**team2 구현 가이드**:

| 항목 | 결정 |
|------|------|
| JWT 라이브러리 | `python-jose[cryptography]` |
| 서명 알고리즘 | Phase 1 `HS256` (단일 시크릿), Phase 3+ `RS256` (키 회전) |
| 환경 플래그 | `AUTH_PROFILE=dev\|staging\|prod\|live` (IMPL-05 §6.2) |
| 토큰 발급 유틸 | `src/security/jwt.py` — 프로파일별 TTL 조회 |
| 실패 시도 제한 | 5회 실패 시 30분 lockout. 저장소 Redis `authfail:{email}:{count}` |
| blacklist 저장소 | Phase 1 DB 테이블, Phase 3+ Redis `blacklist:jti:{jti}` (TTL=Access 잔여) |
| WebSocket 만료 처리 | 만료 직전 `token_expiring` 이벤트 발행, 60s 내 `reauth` 커맨드 미수신 시 연결 종료 |
| Permission bit flags | None(0) / Read(1) / Write(2) / Delete(4) — WSOP Staff Auth 준거 |
| MFA | Phase 3+ (OAuth provider 연동 시) |

### 9.2 데이터 보호

- **전송**: TLS 1.2+ 필수, 내부 통신도 mTLS(Phase 3+)
- **저장**: DB column 암호화 — PII(이름, 이메일, 전화), Refresh Token 해시 저장
- **로깅**: 로그에 PII 금지 (마스킹 필터 미들웨어)
- **감사 로그**: append-only, 보존 1년, 접근은 Admin 역할만

### 9.3 규정 준수 (EBS 범위)

EBS는 WSOP LIVE와 달리 결제/KYC 범위를 제외하므로 PCI DSS/KYC 대상 아님. 다만:
- GDPR 원칙 준수 (PII 최소화, 삭제 요청 대응)
- 방송 중계 저작권 — Overlay 그래픽 자산 관리
- 보안 이벤트 감사 로그 보존 1년

### 9.4 입력 검증 · CSRF · Rate Limiting · CORS (2026-04-15 G-C3)

**Input Validation**:
- 모든 REST 파라미터는 **Pydantic validators** 의무 (max_length/regex/range). raw `request.json()` 직접 파싱 금지.
- 공통 제약:
  - 문자열 기본 max_length: `name` 200 / `description` 2000 / `email` 320 (RFC 5321)
  - email: `EmailStr` 타입 사용
  - datetime: ISO 8601 + timezone 필수 (`datetime` with tzinfo)
  - pagination: `page ≥ 1`, `limit 1~200` (기본 50, CCR-003 정렬)
- **SQL Injection 방어**: SQLModel / SQLAlchemy parametrized query 전수. `text(...)` raw SQL 사용 시 `:param` 바인딩 의무, 문자열 f-string 금지
- **NoSQL Injection**: Redis key 는 `auth.{user_id}.{key}` 처럼 userinput 에 prefix 추가 후 sanitize (whitespace/콜론 escape)

**CSRF**:
- Access Token = Authorization Bearer header (비-쿠키) 경로: **CSRF 비취약** (브라우저가 자동 첨부 안 함). 정책 없음.
- Refresh Token = HttpOnly Cookie 경로 (live 환경, CCR-013): **double-submit token 필수**
  - 쿠키명: `ebs_refresh` (HttpOnly, Secure, SameSite=Strict)
  - 동반 요청: `X-CSRF-Token` 헤더 (값 = 쿠키와 동일한 랜덤 토큰의 별도 저장본)
  - 서버 검증: 헤더 ≠ 쿠키 시 401

**Rate Limiting** (CCR-052 구현 가이드):

| 엔드포인트 카테고리 | 한계 | 기준 | 초과 응답 |
|---------------------|------|------|----------|
| `/auth/login`, `/auth/refresh`, `/auth/password-reset` | 10 req/min | client IP | 429 `AUTH_RATE_LIMITED` + Retry-After |
| `/api/**` 인증 필요 | 100 req/min | user_id | 429 `API_RATE_LIMITED` |
| `/api/**/sync/**` (Admin WSOP sync) | 5 req/min | user_id | 429 |
| WebSocket 메시지 송신 | 50 msg/sec | connection | 1건 drop + WARN log |
| Public (미인증) | 30 req/min | client IP | 429 |

**저장소**: Redis `rate:{bucket}:{id}` (Sliding Window Counter, 1분 TTL). Redis 장애 시 **fail-open** (rate limit 무시, 단 Sentry 경보). IP whitelist: health/metrics 엔드포인트 및 프라이빗 서브넷.

**응답 헤더**:
- `X-RateLimit-Limit`: 버킷 한계
- `X-RateLimit-Remaining`: 남은 할당
- `X-RateLimit-Reset`: 재설정 Unix timestamp
- `Retry-After`: 429 시 초 단위 대기 시간

**CORS allowlist**:
- 환경변수 `CORS_ORIGINS` (JSON array) 로 관리. 와일드카드(`*`) prod/live 금지.
- `Access-Control-Allow-Credentials: true` 는 Cookie refresh 환경(live)에서만
- preflight cache: `Access-Control-Max-Age: 600` (10분)
- 허용 메서드: `GET, POST, PUT, PATCH, DELETE, OPTIONS`
- 허용 헤더: `Authorization, Content-Type, Idempotency-Key, X-CSRF-Token, X-Request-ID`

**Security Headers** (FastAPI middleware 또는 reverse proxy):
- `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `Content-Security-Policy` (prod/live): env `CSP_POLICY` 로 주입
- `Referrer-Policy: strict-origin-when-cross-origin`

**구현 위치**: `src/middleware/security.py` (Phase 1 작성 대상). 미들웨어 순서: rate limit → CORS → CSRF → idempotency → route.

---

## 10. 측정 및 수용 기준 매트릭스

본 섹션은 §1~§9의 모든 수치를 **Phase 1 진입 게이트**로 요약한다. 각 항목이 기준을 충족하지 못하면 Phase 1 시작 불가.

| # | 항목 | 목표 | 측정 방법 | 수용 임계 | 롤백 트리거 | 의존성 |
|---|------|------|----------|----------|------------|--------|
| 1 | API p95 | < 500ms (P1) | Prometheus 5min window | 연속 10min 만족 | × 1.5 지속 5min | 활성 |
| 2 | RFID E2E | < 200ms (P1) | trace_id span | p95 10min 만족 | > 300ms 지속 5min | 활성 |
| 3 | 연속 운영 | ≥ 4h (P1) / ≥ 16h (P3) | uptime 모니터 | unplanned downtime 0 | > 60s | 활성 |
| 4 | MTTR | < 30s (P1) | 프로세스 감시 | 평균 30s 이하 | > 60s | 활성 |
| 5 | 멱등성 | 모든 mutation 지원 | 통합 테스트 | 100% mutation 엔드포인트 | 누락 1건 이상 | 활성 (CCR-003) |
| 6 | 재시도 | 정책 준수 | 카오스 주입 | 재시도 성공 ≥ 95% | 데드락/무한루프 | 활성 |
| 7 | 서킷브레이커 | OPEN 전파 < 100ms | 모의 장애 주입 | 연속 10회 만족 | 전파 지연 > 500ms | 활성 |
| 8 | 분산락 | 충돌 0건 | 동시 요청 100 | race 없음 | race 1건 이상 | 활성 |
| 9 | 이벤트 seq | 연속성 100% | WS→replay 차이 | gap=0 | gap≥1 | 활성 (CCR-015) |
| 10 | 캐시 일관성 | stale 0건 | read-after-write 테스트 | 즉시 반영 | stale > 1s | 활성 |
| 11 | audit_events | 모든 상태 변경 기록 | 통합 테스트 | 100% | 누락 1건 이상 | 활성 (CCR-001) |
| 12 | Undo | inverse 성공 | 단위 테스트 | 100% | 원본 삭제 발생 | 활성 (CCR-001) |
| 13 | RFID 인식률 | ≥ 99.5% (P1) / ≥ 99.9% (P2) | 테스트 세션 52장 스캔 반복 | 연속 3세션 만족 | < 99% 1세션 | 활성 (Foundation Ch.9) |
| 13 | 복구 시나리오 A-D | 성공 | BO-03 §4 드라이런 | 전부 성공 | 1건 이상 실패 | 활성 |
| 14 | JWT 만료 | 프로파일 정책 일치 | 인증 테스트 | 정책 일치 | 차이 발생 | 활성 (CCR-006) |
| 15 | 인덱스 존재 | 8.2 표 100% | 스키마 검증 | 전부 존재 | 1건 이상 누락 | 활성 |
| 16 | 보안 감사 | PII 로깅 0 | 정적 스캔 | 0 hit | 1건 이상 | 활성 |

> "의존성" 열의 `(CCR-NNN)` 주석은 해당 항목이 어느 계약에 근거하는지 표시. 모든 항목이 `활성` 상태이며 Phase 1 진입 게이트 검증 범위에 포함된다.

**Phase 1 진입 게이트**: 16개 항목 모두 ✅ 필요. 하나라도 ❌ 면 Phase 1 킥오프 연기.

---

## 참조

| 문서 | 경로 |
|------|------|
| Phase 1 KPI | `../../../docs/1. Product/Foundation.md` §Phase 1 |
| 테스트 전략 | `IMPL-08-testing-strategy.md` |
| 에러 처리 | `IMPL-06-error-handling.md` |
| 로깅 | `IMPL-07-logging.md` |
| 의존성 주입 | `IMPL-05-dependency-injection.md` |
| 동기화 프로토콜 | `../back-office/BO-02-sync-protocol.md` |
| 운영·감사 | `../back-office/BO-03-operations.md` |
| Spec Gap | `../../qa/spec-gap.md` |
| WSOP LIVE 참조 (mirror) | `C:\claude\wsoplive\docs\confluence-mirror\` — WSOP+ Architecture, Tables API, Waiting API, Tournament, Chip Master, Action History, Staff App Auth, DB 설명 |
| CCR 승격본 (Conductor 자동 승격 완료) | `../../../docs/05-plans/CCR-001`, `CCR-003`, `CCR-006`, `CCR-010`, `CCR-015` |
| CCR 드래프트 (archived) | `../../../docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team2-20260410-*.md` |
