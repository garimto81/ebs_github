---
title: Spec Gaps
owner: team2
tier: internal
last-updated: 2026-04-15
---

# Team 2 Backend — Spec Gap Log

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 신규 작성 | WSOP LIVE Confluence mirror 대조 결과, NFR/신뢰성 Gap 12건 등재 |
| 2026-04-10 | CCR 승격·반영 완료 | CCR-001/003/006/010/015 모두 Conductor 승격 + contracts 실제 수정 완료. GAP-BO-001/002/004/008/012 RESOLVED 처리 |
| 2026-04-10 | 독립 Gap 5건 RESOLVED | GAP-BO-003/005/006/009/010 모두 IMPL-10 해당 섹션에 구현 가이드 반영 완료. IN_PROGRESS → RESOLVED 전환 |

## 개요

`qa/spec-gap.md`는 team2-backend의 **기획 공백** 기록부다. 구현 중 임의 판단이 필요하거나, 상위 계약(`contracts/`)이 누락되어 CCR이 필요한 경우 여기에 먼저 등재한다.

**형식**: `GAP-BO-{NNN}: 제목 / 관찰 / 참조 / 구현 가능성 / 액션 / 임시 구현(있으면) / 상태`

**구현 가능성 라벨**:
- `가능` — team2 내부 결정으로 즉시 구현 가능 (specs/ 보강만 필요)
- `불가(CCR)` — `contracts/` 변경 필요 → CCR 드래프트 경유
- `미결` — 기획/product 오너 확정 필요

**상태 라벨**: `OPEN` / `IN_PROGRESS` / `RESOLVED`

---

## GAP-BO-001: Idempotency-Key 헤더 표준 부재

- **관찰**: `contracts/api/API-01~06` 어디에도 멱등성 키 헤더 정의 없음. 방송 중 네트워크 재시도/운영자 더블클릭 시 seat draw/chip 출납 중복 적용 위험.
- **참조**:
  - WSOP `Chip Master.md` (2-phase confirmation: Requested→Approved/Rejected)
  - WSOP `Waiting API.md` (seat draw 재시도 케이스)
- **구현 가능성**: ~~불가(CCR)~~ → **가능 (CCR-003 contracts 반영 완료)**
- **액션**: ~~CCR-DRAFT 제출~~ → **완료**. 승격본 `docs/05-plans/CCR-003-모든-mutation-api에-idempotency-key-헤더-표준-도입.md`. 정본은 `contracts/api/API-01 §공통 요청 헤더 Idempotency-Key`, `contracts/data/DATA-04 §5.1`
- **상태**: **RESOLVED (2026-04-10)** — IMPL-10 §3.1, IMPL-06 §4.4, IMPL-05 DI 에 구현 가이드 반영됨

---

## GAP-BO-002: 리밸런싱 saga 응답 스키마 부재

- **관찰**: `contracts/api/API-01` `/tables/rebalance` 는 단순 200/400만 정의. 부분 실패 시 어떤 단계가 성공/롤백됐는지 운영자가 확인 불가.
- **참조**:
  - WSOP `Tables API.md` 리밸런싱 다단계 흐름
  - BO-03 §4 "부분 롤백" 복구 시나리오 (본 작업에서 신설)
- **구현 가능성**: ~~불가(CCR)~~ → **가능 (CCR-010 contracts 반영 완료)**
- **액션**: ~~CCR-DRAFT 제출~~ → **완료**. 승격본 `docs/05-plans/CCR-010-tablesrebalance-응답에-saga-구조-추가.md`. 정본은 `contracts/api/API-01 §POST /tables/rebalance` (saga_id/steps[]/200/207/500)
- **상태**: **RESOLVED (2026-04-10)** — IMPL-10 §3.4, BO-03 §4.4, IMPL-05 `get_saga_orchestrator` DI 에 구현 가이드 반영됨

---

## GAP-BO-003: 분산락 TTL·fencing 정책 미정

- **관찰**: IMPL-10 §4.1에서 `lock:table:{id}` Redis SET NX EX 10s + fencing token을 채택했으나, 정확한 TTL/fencing 생성 규칙·장애 시나리오별 동작은 team2 내부 구현 결정 사항.
- **참조**:
  - WSOP `Tables API.md` 동시성 보호 패턴
  - Redlock / fencing token 원칙 (Martin Kleppmann)
- **구현 가능성**: 가능 (team2 내부)
- **액션**: 완료
  1. ✅ IMPL-05 §4.1에 `get_distributed_lock()` DI 추가 (`RedisDistributedLock(redis)` / `InMemoryLock`)
  2. ✅ IMPL-10 §4.1 에 자원별 락 키·TTL 매트릭스, 재시도 3회(10/50/200ms 백오프), lease 연장, fencing token 규칙 반영
  3. IMPL-05 §6.2 `LOCK_DEFAULT_TTL_S=10` 환경변수 등록
- **상태**: **RESOLVED (2026-04-10)** — IMPL-10 §4.1 + IMPL-05 `get_distributed_lock` DI에 반영. 단위 테스트는 Phase 1 구현 시 추가.

---

## GAP-BO-004: WebSocket 이벤트 순번(seq) 및 replay 엔드포인트 부재

- **관찰**: `contracts/api/API-05` 는 이벤트 envelope에 순번을 갖지 않음. WebSocket 재연결 후 놓친 이벤트를 복구할 수단 없음.
- **참조**:
  - WSOP+ Architecture (SignalR + MSK 이벤트 스트림)
  - `Action History.md` EventFlightHistory 기반 조회
- **구현 가능성**: ~~불가(CCR)~~ → **가능 (CCR-015 contracts 반영 완료)**
- **액션**: ~~CCR-DRAFT 제출~~ → **완료**. 승격본 `docs/05-plans/CCR-015-websocket-이벤트에-단조증가-seq-필드-replay-엔드포인트-추가.md`. 정본은 `contracts/api/API-05 §envelope` (`seq`/`server_time`) + `contracts/api/API-01 §replay` (`GET /tables/{id}/events?since={seq}`)
- **상태**: **RESOLVED (2026-04-10)** — IMPL-10 §4.2, IMPL-07 §2.3, BO-03 §4.1 에 구현 가이드 반영됨

---

## GAP-BO-005: Redis 캐시 TTL 및 Pub/Sub 무효화 전략 미정

- **관찰**: IMPL-10 §5에서 Redis 3계층 캐시(table/player/tournament)를 채택했으나, TTL 수치·무효화 이벤트 채널 이름·멀티 워커 전파 규칙이 구체화 안 됨.
- **참조**: WSOP+ Architecture (Redis Cache — Player/Staff/Tournament 분리)
- **구현 가능성**: 가능 (team2 내부)
- **액션**: 완료
  1. ✅ IMPL-10 §5.1 캐시 키 체계 표 — `table:{id}` 5min, `table:list:{event_flight_id}` 2min, `player:{id}` 10min, `tournament:{id}` 30min, `blinds:{event_flight_id}` 1h, `config:global` 1h
  2. ✅ IMPL-10 §5.2 Write-Through + Invalidate-on-Write 규칙 + Pub/Sub 채널 `cache:invalidate:{entity}` 표준
  3. ✅ IMPL-10 §5.3 캐시 실패 격리 (CB OPEN → DB 직접 조회)
  4. ✅ IMPL-05 `get_redis()` DI 등록
- **상태**: **RESOLVED (2026-04-10)** — IMPL-10 §5 전체 + IMPL-05 `get_redis` DI 에 반영.

---

## GAP-BO-006: 서버 시계 동기화 요건 미정

- **관찰**: 다중 BO 인스턴스가 좌석 할당 timestamp로 ordering하면 clock skew 위험. NTP 운영 기준이 명시되지 않음.
- **참조**: WSOP+ Architecture (모든 데이터 AWS California 단일 리전 — 시계 문제 최소화)
- **구현 가능성**: 가능 (team2 내부 + DevOps)
- **액션**: 완료
  1. ✅ IMPL-10 §4.3 — chrony/NTP 설치, offset < 100ms 유지, 드리프트 시 경보
  2. ✅ IMPL-10 §4.3 — 벽시계 사용 금지 규칙 (`datetime.now()` 금지, DB `created_at` monotonic 우선)
  3. ✅ 모든 API 응답에 `server_time` 필드 포함 (WebSocket envelope는 CCR-015로 `ts`/`server_time` 병기)
  4. DevOps NTP 모니터링 runbook은 Phase 1 운영 시작 시 추가 (별도 이슈)
- **상태**: **RESOLVED (2026-04-10)** — IMPL-10 §4.3 에 반영. DevOps runbook은 기획서 범위 밖.

---

## GAP-BO-007: 타임아웃 기본값 카탈로그 부재 (Late Reg, Call Limit, Waiting Room)

- **관찰**: 현재 BO-02 동기화 프로토콜과 IMPL-10에 타임아웃 기본값이 흩어져 있음. WSOP는 `LateRegDay/LateRegLevel/LateRegDuration`, `CallLimit`, Waiting Room TTL을 각각 관리.
- **참조**:
  - WSOP `Tournament.md` (LateRegDuration)
  - WSOP `Waiting API.md` (Call Limit)
- **구현 가능성**: 미결 — 기획 보강 요청 (product 오너 확정 필요)
- **액션**:
  1. IMPL-10 §6에 타임아웃 카탈로그 임시 기본값 명시 (출처: WSOP 평균값)
  2. Product 오너에게 EBS 운영 기준 확정 요청 (backlog.md 항목 등록)
  3. 확정 시 IMPL-10 §6 갱신 + Phase 1 CCR 불필요 (team2 내부)
- **상태**: OPEN — 기획 보강 대기

---

## GAP-BO-008: audit_events 스키마 및 Undo/Revive inverse 이벤트 부재

- **관찰**: `contracts/data/DATA-04`에 이벤트 스토어 테이블 없음. Undo/Revive 시 2-way consistency 보장 불가, 핸드 리플레이/좌석 이력 복구 불가.
- **참조**:
  - WSOP DB `EventFlightSeatHistory` (모든 좌석 변경 이력)
  - WSOP `Action History.md` Undo/Revive 기능
- **구현 가능성**: ~~불가(CCR)~~ → **가능 (CCR-001 contracts 반영 완료)**
- **액션**: ~~CCR-DRAFT 제출~~ → **완료**. 승격본 `docs/05-plans/CCR-001-data-04에-idempotencykeys-auditevents-테이블-신설.md`. 정본은 `contracts/data/DATA-04 §5.2 audit_events` (스키마, 제약, 인덱스, SQLAlchemy 모델, append-only 강제 방법 포함)
- **상태**: **RESOLVED (2026-04-10)** — IMPL-10 §7.1/§7.2, BO-03 §1.2/§4, IMPL-05 `get_audit_repo` DI, IMPL-07 §4.1 3-way 구분에 반영됨

---

## GAP-BO-009: WSOP LIVE 폴링 서킷브레이커 임계값 미정

- **관찰**: BO-02 동기화 프로토콜에 폴링 실패 시 동작이 "재시도" 수준으로만 기술됨. 서킷브레이커 임계값(실패율, 윈도우, 복구 시간)이 없음.
- **참조**: WSOP `APIGW.md` (외부 API 라우팅), 일반적 Hystrix/resilience4j 기본값
- **구현 가능성**: 가능 (team2 내부)
- **액션**: 완료
  1. ✅ IMPL-10 §3.3 — CLOSED/OPEN/HALF_OPEN 상태 전이, 실패율 50%/20 req window/30s OPEN/HALF_OPEN 1 req 시범
  2. ✅ IMPL-10 §3.3 — Fallback `sync:wsop:pending` Redis Stream
  3. ✅ BO-02 §7.1 — 장애 대응 매트릭스(OPEN/HALF_OPEN/CLOSED 복귀) + Fallback Queue cursor 기반 delta 재처리 상세
  4. ✅ IMPL-05 §4.1 `get_circuit_breaker(name)` + `get_wsop_live_client()` DI
  5. ✅ IMPL-05 §6.2 `CB_FAILURE_RATIO=0.5` / `CB_WINDOW_SIZE=20` / `CB_OPEN_DURATION_S=30` 환경변수
- **상태**: **RESOLVED (2026-04-10)** — IMPL-10 §3.3 + BO-02 §7.1 + IMPL-05 DI/환경변수에 전면 반영.

---

## GAP-BO-010: EventFlightSeat.updated_at 대응 인덱스 전략 부재

- **관찰**: WSOP DB 설명에서 `EventFlightSeat.UpdatedAt` 미인덱스 시 좌석 변경 쿼리가 full scan 위험. EBS DATA-04의 좌석 테이블에 동등 패턴 필요.
- **참조**: WSOP+ Database 설명 (EventFlightSeat, JSON BlindJson 파싱 오버헤드)
- **구현 가능성**: 가능 (team2 내부)
- **액션**: 완료
  1. ✅ IMPL-10 §8.2 인덱스 전략 표 — `table_seats(updated_at)`, `table_seats(table_id, seat_no) unique`, `hands(table_id, started_at DESC)`, `audit_logs(created_at DESC)`, `audit_logs(user_id, created_at)`, `audit_events(table_id, seq DESC) unique`, `audit_events(correlation_id)`, `audit_events(event_type, created_at)`, `idempotency_keys(user_id, key) unique`, `idempotency_keys(expires_at)`
  2. ✅ `src/db/init.sql` — `audit_events` / `idempotency_keys` 인덱스 실제 DDL 생성 (CCR-001 반영, 작업 #16)
  3. 실 운영 EXPLAIN 모니터링 runbook은 Phase 1 운영 시작 시 추가 (별도 이슈)
- **상태**: **RESOLVED (2026-04-10)** — IMPL-10 §8.2 + init.sql 반영. `table_seats(updated_at)` 실제 DDL은 GAP-BO-011 전면 동기화 시점에 생성 (core 엔티티 동기화 작업).

---

## GAP-BO-011: `src/db/init.sql` ↔ `contracts/data/DATA-04-db-schema.md` 큰 격차

- **관찰**: **[CRITICAL]** `src/db/init.sql` 현재 상태는 Stage 0 RFID 카드 매핑용 `cards` 테이블 **1개**만 포함(54장 덱 seed data). DATA-04는 competitions/series/events/users/user_sessions/audit_logs/decks/hands/table_seats 등 12개+ 엔티티를 정의. CLAUDE.md L16 "권위 DDL — DATA-04와 일치 필수" 규칙 위반 상태.
- **참조**:
  - `C:\claude\ebs\contracts\data\DATA-04-db-schema.md`
  - `C:\claude\ebs\team2-backend\src\db\init.sql`
  - `C:\claude\ebs\team2-backend\CLAUDE.md:16`
- **구현 가능성**: 미결 (감사) — 격차 해소 방식 결정 필요
- **액션**:
  1. Phase 1 Stage 1 진입 전까지 `src/db/init.sql`을 DATA-04와 완전 동기화 (team2 내부 작업)
  2. 동기화 작업 자체는 CCR 불필요 (init.sql은 구현체)
  3. DATA-04의 최신 엔티티를 기반으로 CREATE TABLE 문 재작성
  4. 추가로 GAP-BO-001(idempotency_keys), GAP-BO-008(audit_events) CCR 승인 후 즉시 반영
  5. 향후 drift 방지를 위해 CI에 `tools/check_schema_drift.py` 추가 제안 (backlog 등록)
- **임시 구현**: 없음 — Stage 0만 동작 중이라 실질 영향은 Stage 1 진입 시점부터
- **상태**: OPEN — Stage 1 진입 전 동기화 필수

---

## GAP-BO-012: JWT 12h 만료 × WebSocket 재연결 interplay 미정

- **관찰**: BS-01은 Access 15분 정책인데, 방송 14-16h 연속 환경에서 분당 refresh 빈도가 과도. 또한 WebSocket이 토큰 만료 시 끊는지/유지하는지 명시 없음.
- **참조**: WSOP Staff App `Auth.md` (expires_in: 43200초 = 12h)
- **구현 가능성**: ~~불가(CCR)~~ → **가능 (CCR-006 contracts 반영 완료)**
- **액션**: ~~CCR-DRAFT 제출~~ → **완료**. 승격본 `docs/05-plans/CCR-006-bs-01에-jwt-accessrefresh-만료-정책-명시.md`. 정본은 `contracts/specs/BS-01-auth/BS-01-auth.md §5` (dev 1h / staging·prod 2h / live 12h, `AUTH_PROFILE` 환경 플래그, WebSocket `token_expiring`/`reauth`, blacklist 저장소)
- **상태**: **RESOLVED (2026-04-10)** — IMPL-10 §9.1, IMPL-05 §6.2 환경변수 (`AUTH_PROFILE`, `JWT_ACCESS_TTL_S`, `JWT_REFRESH_TTL_S`) 반영됨

---

## 요약 표

| ID | 주제 | 구현 가능성 | 상태 |
|----|------|------------|:----:|
| GAP-BO-001 | Idempotency-Key 헤더 표준 | 가능 (CCR-003 반영) | **RESOLVED** |
| GAP-BO-002 | 리밸런싱 saga 응답 스키마 | 가능 (CCR-010 반영) | **RESOLVED** |
| GAP-BO-003 | 분산락 TTL·fencing 정책 | 가능 | **RESOLVED** |
| GAP-BO-004 | WebSocket seq 필드/replay | 가능 (CCR-015 반영) | **RESOLVED** |
| GAP-BO-005 | Redis 캐시 TTL 및 Pub/Sub 무효화 | 가능 | **RESOLVED** |
| GAP-BO-006 | 서버 시계 동기화 (NTP) | 가능 | **RESOLVED** |
| GAP-BO-007 | 타임아웃 기본값 카탈로그 | 미결 | OPEN |
| GAP-BO-008 | audit_events 스키마 + inverse | 가능 (CCR-001 반영) | **RESOLVED** |
| GAP-BO-009 | WSOP LIVE 폴링 서킷브레이커 | 가능 | **RESOLVED** |
| GAP-BO-010 | EventFlightSeat.updated_at 인덱스 | 가능 | **RESOLVED** |
| GAP-BO-011 | init.sql ↔ DATA-04 큰 격차 | 미결(감사) | IN_PROGRESS (audit_events/idempotency_keys 부분 동기화. core 엔티티 전면 동기화는 Stage 1 진입 시점) |
| GAP-BO-012 | JWT 12h × WebSocket 재연결 | 가능 (CCR-006 반영) | **RESOLVED** |

**RESOLVED (2026-04-10)**: 001~006, 008~010, 012 (10건)
- CCR 계약 반영 5건: 001, 002, 004, 008, 012 (CCR-001/003/006/010/015)
- 독립 작업 완료 5건: 003, 005, 006, 009, 010 (IMPL-10/IMPL-05/BO-02 반영)

**IN_PROGRESS**: 011 (init.sql core 엔티티 동기화 — Stage 1 진입 시점의 별개 작업)
**OPEN**: 007 (타임아웃 기본값 product 오너 확정 대기. IMPL-10 §6 에 임시 기본값 존재)
