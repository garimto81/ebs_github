---
title: WSOP LIVE → EBS Chip Count Sync (Webhook Contract)
owner: s7
tier: contract
last-updated: 2026-05-13
version: 1.0.0
audience-target: 외부 개발팀 (WSOP LIVE 측 + EBS 측) + 백엔드 시니어
---

# WSOP LIVE → EBS Chip Count Sync — Webhook Contract

| 날짜 | 버전 | 변경 내용 |
|------|------|-----------|
| 2026-05-13 | v1.0.0 | 최초 작성 (Cycle 20 Wave 1, issue #432). WSOP LIVE 브레이크 chip count push → EBS 동기화 contract 정립. |

---

## §1 Context

### 1.1 왜 필요한가

본 contract 가 정의되기 전까지, EBS 의 9 카테고리 SSOT (Foundation Ch.2) 중 #1 플레이어 대시보드의 **chipstack** 필드는 EBS Game Engine 의 자동 계산 (베팅 발생 시 차감 / 팟 회수 시 증가) 으로만 갱신되었다. 이는 hand 가 정상적으로 진행되는 동안은 정확하지만, 다음 시나리오에서 truth 와 drift 가 발생한다.

- **딜러 수동 칩 보충 / 회수** (rake adjustment, color-up, late re-entry 등)
- **다른 EBS 미관측 이벤트** (RFID 미인식 액션, CC 오퍼레이터 미입력)
- **브레이크 중 칩 카운팅** — 모든 테이블의 딜러가 정식으로 각 좌석의 칩을 count 하여 입력하는 권위 절차

브레이크 = 토너먼트 운영상 **WSOP LIVE 가 stack 의 권위 시점 (authority window)** 을 갖는 유일한 시점. 그 시점의 chip count = ground truth. 이후 hand 가 재개되면 다시 Engine 의 자동 계산이 권위를 가짐.

> 사용자 지시 (Cycle 20): "각 테이블 입력 끝날 때마다 push, EBS도 자동 갱신."

### 1.2 책임 분담

| 측 | 책임 |
|---|------|
| WSOP LIVE | 딜러 입력 UI / 브레이크 식별 / 테이블별 push / retry / signature 생성 |
| EBS (BO) | webhook endpoint / HMAC 검증 / Idempotency 보장 / DB commit / WS broadcast / Engine reconcile |
| EBS (Engine) | reconcile 시 drift 감지 + log (`Chip_Count_State.md`) |
| EBS (CC/Overlay/Lobby) | WS subscriber — `chip_count_synced` 이벤트 수신 시 view 갱신 |

### 1.3 SSOT pointers

- 9 카테고리 SSOT: `docs/1. Product/Foundation.md` Ch.2 §1 (플레이어 대시보드 = DB + Engine + WSOP LIVE push + RFID)
- 흐름도: `docs/1. Product/Foundation.md` Ch.5 §B.5
- WS 이벤트 정의: `docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md` §4.2.11
- state machine: `docs/2. Development/2.5 Shared/Chip_Count_State.md`

---

## §2 Sequence Diagram

```
딜러            WSOP LIVE Staff App           WSOP LIVE Backend           EBS BO (S7)           EBS Engine (S8)         CC/Overlay/Lobby
  │                    │                            │                          │                       │                          │
  │  브레이크 시작     │                            │                          │                       │                          │
  │ ───────────────────│                            │                          │                       │                          │
  │                    │                            │                          │                       │                          │
  │  테이블 1 입력 끝  │                            │                          │                       │                          │
  │ ──────────────────>│                            │                          │                       │                          │
  │                    │   table=1 snapshot         │                          │                       │                          │
  │                    │ ──────────────────────────>│                          │                       │                          │
  │                    │                            │  POST /chip-count-       │                       │                          │
  │                    │                            │  snapshot                │                       │                          │
  │                    │                            │ ────────────────────────>│                       │                          │
  │                    │                            │                          │ HMAC 검증             │                          │
  │                    │                            │                          │ Idempotency 검증      │                          │
  │                    │                            │                          │ DB INSERT             │                          │
  │                    │                            │                          │ ──────────────────────│                          │
  │                    │                            │  202 Accepted            │                       │                          │
  │                    │                            │ <────────────────────────│                       │                          │
  │                    │                            │                          │  WS chip_count_synced │                          │
  │                    │                            │                          │ ─────────────────────────────────────────────────>│
  │                    │                            │                          │  reconcile trigger    │                          │
  │                    │                            │                          │ ─────────────────────>│                          │
  │                    │                            │                          │                       │ drift > threshold?       │
  │                    │                            │                          │                       │ → drift_event log        │
  │                    │                            │                          │                       │                          │
  │  테이블 2 입력 끝  │                            │                          │                       │                          │
  │ ──────────────────>│ ... (반복) ...             │                          │                       │                          │
```

> 각 테이블 단위로 즉시 push. 브레이크가 끝날 때 한 번에 묶음 전송하지 않는다 (사용자 지시 — "입력 끝날 때마다 push").

---

## §3 Webhook Specification

### 3.1 Endpoint

```
POST /api/wsop-live/chip-count-snapshot
Host: <ebs-bo-host>
```

### 3.2 Headers

| Header | 필수 | 설명 |
|---|:----:|---|
| `Content-Type` | ✅ | `application/json; charset=utf-8` 고정 |
| `X-WSOP-Signature` | ✅ | HMAC-SHA256 hex digest (§6 절차) |
| `X-WSOP-Timestamp` | ✅ | ISO8601 (UTC). EBS 가 현재 시각과 ±300s 초과 시 401 거부 (replay 차단) |
| `Idempotency-Key` | ✅ | snapshot 단위 UUID v4. body 의 `snapshot_id` 와 동일해야 함. DB unique constraint 와 결합 (§7) |
| `User-Agent` | 권장 | `WSOPLive-ChipCountSync/<version>` 형태 권장 |

### 3.3 Body Schema

```json
{
  "snapshot_id": "uuid",
  "break_id": 0,
  "table_id": 0,
  "recorded_at": "ISO8601",
  "seats": [
    {
      "seat_number": 1,
      "player_id": 0,
      "chip_count": 0
    }
  ]
}
```

| 필드 | 타입 | 필수 | 설명 |
|---|---|:----:|---|
| `snapshot_id` | string (UUID v4) | ✅ | webhook 단위 unique. `Idempotency-Key` header 와 일치 필수 |
| `break_id` | int | ✅ | WSOP LIVE 가 발급하는 브레이크 식별자. 동일 브레이크의 여러 테이블 push 는 동일 `break_id` 공유 |
| `table_id` | int | ✅ | EBS table id. WSOP LIVE 측 table mapping table 에서 변환 후 송신 (`Triggers.md` table_mapping 참조) |
| `recorded_at` | string (ISO8601) | ✅ | **딜러가 입력 완료한 시점**. 권위 시점. UTC 권장 |
| `seats` | array | ✅ | 해당 테이블의 모든 좌석. 빈 좌석은 포함하지 않거나 `player_id=null` 표기 (EBS 는 양쪽 모두 수용) |
| `seats[].seat_number` | int | ✅ | 1-based. 테이블의 max seat count 이하 |
| `seats[].player_id` | int 또는 null | ✅ | WSOP LIVE player id. null 이면 빈 좌석 |
| `seats[].chip_count` | int | ✅ | 0 이상. 단위 = 토너먼트 칩 (currency 아님, color-up 후 표준 단위) |

---

## §4 Request Body Example

```json
{
  "snapshot_id": "8a7e9c4e-5d3b-4f1a-9c2e-7b6a0e8f1d3c",
  "break_id": 1024,
  "table_id": 17,
  "recorded_at": "2026-05-13T18:32:15.000Z",
  "seats": [
    {"seat_number": 1, "player_id": 901, "chip_count": 125000},
    {"seat_number": 2, "player_id": 902, "chip_count": 87500},
    {"seat_number": 3, "player_id": null, "chip_count": 0},
    {"seat_number": 4, "player_id": 904, "chip_count": 211000},
    {"seat_number": 5, "player_id": 905, "chip_count": 64000},
    {"seat_number": 6, "player_id": 906, "chip_count": 150500},
    {"seat_number": 7, "player_id": 907, "chip_count": 92000},
    {"seat_number": 8, "player_id": 908, "chip_count": 175500},
    {"seat_number": 9, "player_id": 909, "chip_count": 0}
  ]
}
```

---

## §5 Response

### 5.1 정상 — 202 Accepted (async)

```json
{
  "status": "accepted",
  "snapshot_id": "8a7e9c4e-5d3b-4f1a-9c2e-7b6a0e8f1d3c",
  "received_at": "2026-05-13T18:32:15.187Z",
  "ws_event_dispatched": true
}
```

| 필드 | 설명 |
|---|---|
| `status` | `"accepted"` (정상) / `"already_processed"` (idempotency hit, §7) |
| `snapshot_id` | echo back (검증용) |
| `received_at` | EBS BO 수신 시점 (audit) |
| `ws_event_dispatched` | `chip_count_synced` WS 이벤트가 broadcast 큐에 enqueue 되었는지 (`true` 면 §10 이벤트가 곧 발행됨) |

### 5.2 에러 응답

| HTTP | 원인 | 본문 예시 | 재시도 |
|:----:|---|---|:----:|
| 400 | malformed body / schema 위반 | `{"error": "VALIDATION", "field": "seats[3].chip_count", "message": "must be >= 0"}` | ❌ (fix-then-retry) |
| 401 | HMAC 검증 실패 | `{"error": "SIGNATURE_INVALID"}` | ❌ |
| 401 | timestamp drift > 300s | `{"error": "TIMESTAMP_DRIFT", "received": "...", "now": "..."}` | ❌ (clock sync first) |
| 409 | Idempotency-Key body snapshot_id 불일치 | `{"error": "IDEMPOTENCY_MISMATCH"}` | ❌ |
| 422 | `table_id` unknown | `{"error": "TABLE_UNKNOWN", "table_id": 17}` | ❌ (mapping fix-then-retry) |
| 500 | EBS BO 내부 오류 | `{"error": "INTERNAL"}` | ✅ exponential backoff (§8) |
| 503 | DB / broker downstream 일시 장애 | `{"error": "UNAVAILABLE", "retry_after_ms": 5000}` | ✅ (Retry-After 준수) |

---

## §6 HMAC Verification 절차

### 6.1 송신 (WSOP LIVE)

```
canonical_string = method + "\n" + path + "\n" + timestamp + "\n" + sha256(body_bytes).hex()
signature = HMAC_SHA256(shared_secret, canonical_string).hex()
```

- `method` = `"POST"` (uppercase 고정)
- `path` = `"/api/wsop-live/chip-count-snapshot"` (query string 미포함)
- `timestamp` = `X-WSOP-Timestamp` header 값 (그대로)
- `body_bytes` = HTTP body 의 raw bytes (parse 전, no whitespace normalization)
- `shared_secret` = 32 bytes 이상 random (out-of-band 발급, 90 일 rotation)
- 결과 hex digest 를 `X-WSOP-Signature` header 로 전송

### 6.2 검증 (EBS BO)

1. `X-WSOP-Timestamp` 와 현재 시각 비교, 차이 > 300s → 401 `TIMESTAMP_DRIFT`
2. body raw bytes 보존 (parse 후가 아닌 raw 읽기)
3. 동일한 `canonical_string` 재구성 + HMAC 계산
4. `hmac.compare_digest` (timing-safe) 로 헤더 값과 비교
5. 불일치 → 401 `SIGNATURE_INVALID`
6. 일치 → §7 Idempotency 검증으로 진행

### 6.3 Secret rotation

- 신규 secret 발급 시 EBS BO 는 **2 개의 active secret** 을 일정 기간(겹침 24 시간 권장) 동시 수용 → grace period 후 old secret 폐기
- secret 저장 위치: EBS 측 환경 변수 `WSOP_LIVE_WEBHOOK_SECRET` + `WSOP_LIVE_WEBHOOK_SECRET_PREV` (rotation 중)

---

## §7 Idempotency 정책

### 7.1 DB unique constraint

`chip_count_snapshots` 테이블의 `snapshot_id` 컬럼에 `UNIQUE` 제약. INSERT 시 중복 발생 시:

```sql
INSERT INTO chip_count_snapshots (snapshot_id, ...) VALUES (...) ON CONFLICT (snapshot_id) DO NOTHING;
```

### 7.2 처리 흐름

1. body 의 `snapshot_id` 와 header `Idempotency-Key` 일치 검증 — 불일치 시 409
2. `chip_count_snapshots` 에 `snapshot_id` 존재 여부 SELECT
3. 존재 → 기존 row 의 `received_at` 으로 200 응답 (`status: "already_processed"`, WS broadcast 재발행 안 함)
4. 미존재 → §6 검증 통과 후 INSERT + WS broadcast

### 7.3 재시도 안전성

WSOP LIVE 측은 5xx / network timeout 시 동일 `snapshot_id` 로 재전송 가능. EBS 측은 idempotent 처리 보장.

> **주의**: WSOP LIVE 측이 새로운 데이터로 재전송하려면 새로운 `snapshot_id` 를 발급해야 한다. 같은 `snapshot_id` 로 다른 body 를 보내도 EBS 는 첫 번째 commit 한 데이터만 truth 로 유지한다 (immutable append 정책 §9).

---

## §8 Error Handling + Retry

### 8.1 WSOP LIVE 측 책임

| 응답 | WSOP LIVE 동작 |
|---|---|
| 2xx | 성공 처리 종료 |
| 4xx (400/401/409/422) | **재시도 안 함**. WSOP LIVE 운영자에게 alert. (data fix 필요) |
| 5xx | exponential backoff (1s → 2s → 4s → 8s → 16s, 최대 5 회). 모든 attempt 실패 시 24h dead-letter queue 보존 |
| network timeout | 5xx 와 동일 |

> EBS 측은 webhook **수신자** 책임만 담당. 재시도 / 큐잉 / dead-letter 는 모두 WSOP LIVE 측 책임.

### 8.2 EBS 측 책임

- 5xx 응답 시 받은 데이터를 일시 저장하지 않음 (idempotency 와 결합되어 다음 재시도에서 정상 처리)
- 단, DB INSERT 까지 성공한 후 WS broadcast 단계에서 실패 시 — DB 는 commit 된 상태 유지 + 별도 reconciliation 작업 (`tools/chip_count_rebroadcast.py` 후속 도구, 본 contract 범위 밖)

---

## §9 DB Schema

### 9.1 chip_count_snapshots 테이블

```sql
CREATE TABLE chip_count_snapshots (
    id              BIGSERIAL PRIMARY KEY,
    snapshot_id     UUID NOT NULL UNIQUE,           -- webhook idempotency key
    table_id        INTEGER NOT NULL REFERENCES tables(id),
    seat_number     INTEGER NOT NULL,               -- 1-based
    player_id       INTEGER NULL,                   -- nullable for empty seat
    chip_count      BIGINT NOT NULL CHECK (chip_count >= 0),
    break_id        INTEGER NOT NULL,
    source          TEXT NOT NULL DEFAULT 'wsop-live-webhook',
    recorded_at     TIMESTAMPTZ NOT NULL,           -- 딜러 입력 시점 (권위)
    received_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),  -- BO 수신
    signature_ok    BOOLEAN NOT NULL DEFAULT TRUE,  -- HMAC 통과 (false 면 INSERT 안 됨, 보존을 위한 audit-only)
    raw_payload     JSONB NOT NULL                  -- 원본 보존 (분쟁 시 재현)
);

CREATE INDEX idx_chip_count_snapshots_table_break ON chip_count_snapshots (table_id, break_id, recorded_at DESC);
CREATE INDEX idx_chip_count_snapshots_received ON chip_count_snapshots (received_at DESC);
```

### 9.2 정책

- **Immutable append**: 한 번 commit 된 row 는 UPDATE 금지. 잘못된 데이터 정정은 별도 `chip_count_corrections` (테이블 추가 시점은 본 contract 범위 밖, 별도 issue)
- **seat 별 row**: snapshot 한 건 = 1 webhook = N rows (각 seat 별). seat_number 별 분리 저장으로 individual query 용이.
- **raw_payload 보존**: 분쟁 또는 signature 재검증 시 원본 body 필요. JSONB 로 indexed-but-queryable.
- **Retention**: 토너먼트 종료 후 90 일 이상 보존. archive 정책은 별도 ops 문서.

### 9.3 Query 패턴 예시

```sql
-- 특정 테이블의 가장 최근 chip count (per seat)
SELECT DISTINCT ON (seat_number) seat_number, player_id, chip_count, recorded_at
FROM chip_count_snapshots
WHERE table_id = $1
ORDER BY seat_number, recorded_at DESC;

-- 특정 break 의 모든 테이블 합계 (필드 현황판 #9 데이터)
SELECT table_id, SUM(chip_count) AS total
FROM chip_count_snapshots
WHERE break_id = $1
  AND (table_id, snapshot_id) IN (
    SELECT table_id, snapshot_id
    FROM chip_count_snapshots
    WHERE break_id = $1
    GROUP BY table_id, snapshot_id
    HAVING MAX(recorded_at)
  )
GROUP BY table_id;
```

---

## §10 WS Publish: `chip_count_synced`

webhook 수신 후 DB commit 성공 시 즉시 broadcast.

- **이벤트명**: `chip_count_synced`
- **정의 위치**: [WebSocket_Events.md §4.2.11](WebSocket_Events.md)
- **Channel**: `lobby` + `cc:{table_id}` + `overlay:{table_id}` 동시
- **Subscribers**: CC / Overlay / Lobby / Engine

### 10.1 BO 발행 시점 (sequence)

```
1. HTTP 200/202 응답 송신 (WSOP LIVE 측에게)
2. DB transaction commit
3. WS broadcast (chip_count_synced)
4. Engine reconcile webhook (in-process, async)
```

> 응답 송신과 WS broadcast 는 동시 수행 가능 (별도 트랜잭션). 단, DB commit 이 먼저 완료된 후에 broadcast 가 enqueue 되어야 audit_events replay 정합 보장.

---

## §11 Related Documents

| 문서 | 역할 |
|---|---|
| `docs/1. Product/Foundation.md` Ch.2 §1 + Ch.5 §B.5 | 9 카테고리 SSOT + 흐름도 |
| `docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md` §4.2.11 | `chip_count_synced` 이벤트 정의 |
| `docs/2. Development/2.5 Shared/Chip_Count_State.md` | state machine (Engine vs WSOP LIVE reconcile) |
| `docs/2. Development/2.2 Backend/APIs/Auth_and_Session.md` | JWT (본 webhook 은 별도 HMAC, JWT 미사용) |
| `docs/2. Development/2.2 Backend/APIs/Triggers.md` | WSOP LIVE table_id ↔ EBS table_id mapping |
