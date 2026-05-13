---
title: Chip Count State (Engine vs WSOP LIVE Reconcile)
owner: conductor
tier: contract
last-updated: 2026-05-13
version: 1.0.0
audience-target: Engine 개발자 (S8) + Backend 개발자 (S7) + 운영팀
related-spec:
  - ../2.1 Frontend/Lobby/Overview.md
  - ../2.2 Backend/Back_Office/Overview.md
  - ../2.3 Game Engine/Rules/Multi_Hand_v03.md
  - ../2.4 Command Center/Command_Center_UI/Overview.md
---

# Chip Count State Machine — Engine vs WSOP LIVE Reconcile

| 날짜 | 버전 | 변경 내용 |
|------|------|-----------|
| 2026-05-13 | v1.0.0 | 최초 작성 (Cycle 20 Wave 1, issue #432). 4 state machine + reconcile 규칙 + drift threshold + audit trail. |

---

## §1 State Machine

### 1.1 상태 정의

EBS 내부에서 한 테이블의 chip count 는 항상 4 상태 중 하나에 있다.

| State | 권위 (authority) | 발동 조건 | 특징 |
|---|---|---|---|
| `ENGINE_AUTO` | Engine | hand 진행 중 (default) | Engine 이 베팅/팟 회수 기반으로 자동 계산. WSOP LIVE 입력 없음. |
| `WSOP_AUTHORITATIVE` | WSOP LIVE webhook | webhook 도착 직후 (수ms) | webhook 의 chip_count = truth. Engine 의 자동 계산보다 우선. |
| `RECONCILING` | (전이 중) | webhook commit 후 Engine reconcile loop 트리거됨 | Engine 이 자신의 계산값과 webhook truth 간 drift 측정. |
| `DRIFT_LOGGED` | Engine | reconcile 결과 drift > threshold | drift event 기록 후 ENGINE_AUTO 로 복귀. truth 는 webhook 값 채택 완료. |

### 1.2 전이 다이어그램

```
     ┌──────────────────────────────────────────────────────┐
     │                                                       │
     │                                                       │
     │   ┌──────────────────┐                                │
     ▼   │                  │                                │
  ┌──────────────┐          │                                │
  │ ENGINE_AUTO  │ ◀────────┘  drift 없음 (≤ threshold)      │
  │ (default)    │                                           │
  └──────┬───────┘                                           │
         │                                                   │
         │ webhook 도착                                      │
         │ + HMAC 검증 통과                                  │
         │ + DB commit 성공                                  │
         ▼                                                   │
  ┌──────────────────────┐                                   │
  │ WSOP_AUTHORITATIVE   │                                   │
  │ (truth 갱신 완료)    │                                   │
  └──────┬───────────────┘                                   │
         │                                                   │
         │ WS broadcast + Engine notify                      │
         ▼                                                   │
  ┌──────────────┐                                           │
  │ RECONCILING  │                                           │
  │ (drift 측정)  │                                           │
  └──────┬───────┘                                           │
         │                                                   │
         │ drift 계산                                        │
         │                                                   │
         ├──────  drift ≤ threshold  ────────────────────────┘
         │
         │  drift > threshold
         ▼
  ┌──────────────────┐
  │ DRIFT_LOGGED     │ ──→ drift_event 기록 ──→ ENGINE_AUTO 복귀
  │ (이상 감지)      │
  └──────────────────┘
```

### 1.3 상태 보유 위치

- **테이블 단위**: 각 테이블이 독립된 state 보유 (16 테이블 = 16 state machine)
- **메모리 위치**: BO 의 in-process state store (Redis 또는 in-memory). DB 영구 저장 대상 아님 (재시작 시 ENGINE_AUTO 부터 시작)
- **읽기**: `GET /api/tables/:id/chip-count-state` (운영 도구용)

---

## §2 Reconcile 규칙 (D2 결정)

### 2.1 핵심 원칙

> **WSOP LIVE webhook 이 도착한 시점에는, 그 시점 stack 의 권위 source = WSOP LIVE.**
> Engine 의 자동 계산값과 다르면 **WSOP LIVE 가 truth**, Engine 은 자신의 state 를 webhook 값으로 갱신한다.

### 2.2 reconcile 흐름 (Engine 측)

1. BO 가 WS broadcast (`chip_count_synced`) 와 동시에 Engine 에 in-process notification 전송
2. Engine 은 받은 webhook truth 와 자신이 현재 보유한 각 seat 의 chip_count 비교
3. 차이 측정 → §3 threshold 와 비교
4. 차이가 threshold 이내 → 자동 swap, drift 없음 (silent reconcile)
5. 차이가 threshold 초과 → drift_event 기록 + 자동 swap

### 2.3 자동 swap 절차

```
for seat in webhook.seats:
    old_value = engine_state[table_id][seat.seat_number].chip_count
    engine_state[table_id][seat.seat_number].chip_count = seat.chip_count
    
    if abs(seat.chip_count - old_value) > drift_threshold(old_value):
        log_drift_event(
            table_id, seat.seat_number, seat.player_id,
            engine_value=old_value,
            webhook_truth=seat.chip_count,
            recorded_at=webhook.recorded_at,
            break_id=webhook.break_id,
        )
```

### 2.4 swap 후 동작

- swap 즉시 Engine 의 다음 계산 (다음 hand) 부터 webhook truth 를 baseline 으로 사용
- 진행 중인 hand 가 있으면 (break 중 webhook 도착 = 정상 케이스) → hand FSM 의 break 처리 (§4) 와 정합 보장

---

## §3 Drift 감지 + threshold

### 3.1 Threshold 정의

drift = `|webhook_truth - engine_value|`

| 조건 | drift level | 처리 |
|---|---|---|
| drift ≤ max(5% × engine_value, 500) | NORMAL | silent reconcile, drift_event 미기록 |
| drift > max(5% × engine_value, 500) AND drift ≤ 1000 | MINOR | drift_event 기록 (level=MINOR), alert 안 함 |
| drift > 1000 AND drift ≤ 5% × engine_value × 2 | MAJOR | drift_event 기록 (level=MAJOR), 운영 alert (Slack #ebs-ops) |
| drift > 5% × engine_value × 2 OR drift > 10000 | CRITICAL | drift_event 기록 (level=CRITICAL), 운영 alert + Engine FSM 점검 권고 |

### 3.2 drift_event 스키마

```sql
CREATE TABLE chip_count_drift_events (
    id              BIGSERIAL PRIMARY KEY,
    snapshot_id     UUID NOT NULL,                 -- webhook 출처 (chip_count_snapshots 참조)
    table_id        INTEGER NOT NULL,
    seat_number     INTEGER NOT NULL,
    player_id       INTEGER NULL,
    engine_value    BIGINT NOT NULL,                -- Engine 보유 값 (drift 직전)
    webhook_truth   BIGINT NOT NULL,                -- WSOP LIVE 값 (채택)
    drift_amount    BIGINT NOT NULL,                -- abs(diff)
    drift_level     TEXT NOT NULL,                  -- NORMAL / MINOR / MAJOR / CRITICAL (NORMAL 은 기록 안 함)
    break_id        INTEGER NOT NULL,
    recorded_at     TIMESTAMPTZ NOT NULL,           -- webhook recorded_at (딜러 입력 시점)
    detected_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes           TEXT NULL                       -- 운영자 사후 주석
);

CREATE INDEX idx_drift_events_break ON chip_count_drift_events (break_id, drift_level);
CREATE INDEX idx_drift_events_table ON chip_count_drift_events (table_id, detected_at DESC);
```

### 3.3 운영 alert 형식 (MAJOR / CRITICAL)

```
[EBS chip count DRIFT] level=MAJOR table=17 seat=4
  Engine: 158,500 / Webhook truth: 211,000 / drift: 52,500 (33%)
  break_id=1024 snapshot_id=8a7e9c4e... recorded_at=2026-05-13T18:32:15Z
  → Engine 측 액션 추적 점검 필요 (RFID 미인식 액션 / CC 미입력 가능성)
```

---

## §4 Hand FSM 중 break 처리 (race avoidance)

### 4.1 race 시나리오

webhook 도착 시점에 다음 상태가 가능:
- (A) 브레이크 정식 진입 → hand FSM 의 PAUSED 상태 — **정상 케이스**
- (B) 브레이크 직전 / 직후 의 hand 진행 중 — **race**
- (C) 브레이크 동안 hand 시작 시도 — **운영 위반** (브레이크 중 hand 시작 금지)

### 4.2 처리 규칙

| 시나리오 | webhook 처리 |
|---|---|
| (A) PAUSED | 정상 swap. drift 측정. |
| (B) 진행 중 (e.g. PREFLOP / FLOP / TURN / RIVER / SHOWDOWN) | webhook truth 를 deferred queue 에 적재. hand 종료 (HandEnded) 후 swap. 그 동안 broadcast 는 정상 발행 (소비자는 view 만 갱신, Engine 은 hand 종료 후 reconcile). |
| (C) 운영 위반 | hand FSM 이 시작 거부. webhook 은 정상 처리 (state machine 독립). |

### 4.3 deferred queue 정책

- queue 위치: BO in-process (chip count 갱신은 본질적으로 BO 가 owner)
- queue 크기: 테이블별 최대 10 건 (10 webhook 누적 시 alert)
- TTL: 5 분 (hand 가 5 분 안에 종료되지 않으면 운영 alert)

---

## §5 Audit Trail

### 5.1 audit 대상

모든 reconcile 활동은 audit-able:

| 이벤트 | 저장 위치 | 보존 |
|---|---|---|
| webhook 수신 | `chip_count_snapshots` (raw_payload 포함) | 90 일+ |
| HMAC 실패 | application log (signature_ok=false 는 INSERT 안 됨) | 30 일+ |
| drift 감지 | `chip_count_drift_events` | 90 일+ |
| WS broadcast | `audit_events` (envelope seq 단조증가, §WebSocket_Events §2.1) | 7 일+ |
| Engine reconcile 완료 | Engine in-process log (file rotation) | 7 일+ |

### 5.2 분쟁 해결 절차

WSOP LIVE 측 ↔ EBS 측 chip count 불일치 분쟁 발생 시:

1. `chip_count_snapshots.raw_payload` 의 원본 body 추출
2. WSOP LIVE 측 송신 로그와 대조 — `snapshot_id` 키로 매칭
3. EBS 측 `chip_count_drift_events` 확인 — drift_level 별 시간순 정렬
4. Engine 측 hand 로그 (hand 별 베팅 / 팟 회수 detail) 와 cross-reference

---

## §6 Related Documents

| 문서 | 역할 |
|---|---|
| `docs/2. Development/2.2 Backend/APIs/WSOP_LIVE_Chip_Count_Sync.md` | webhook contract 본체 |
| `docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md` §4.2.11 | `chip_count_synced` 이벤트 |
| `docs/1. Product/Foundation.md` Ch.5 §B.5 | 흐름도 |
| `docs/1. Product/Game_Rules/Betting_System.md` | Engine 자동 계산 알고리즘 (베팅/팟 회수) |
| Engine implementation | `team3-engine/src/...` (별도 PR — Cycle 20 Wave 2) |
