---
title: WSOP LIVE → BO → Engine Chip Stack Sync — 백엔드 검토 v2
owner: s7
tier: internal
legacy-id: null
audience-target: 백엔드 시니어 + S7/S8 stream owner + 운영팀
last-updated: 2026-05-14
version: 2.0.0
derivative-of: ../../2.2 Backend/Back_Office/Overview.md
if-conflict: derivative-of takes precedence
related-spec:
  - ../APIs/WSOP_LIVE_Chip_Count_Sync.md
  - ../APIs/WebSocket_Events.md
  - ../../2.5 Shared/Chip_Count_State.md
  - ../../../1. Product/Foundation.md
review-scope: S7 (Backend) 권한 — 다른 stream scope 침범 시 권고(advisory)만 기재
---

# WSOP LIVE → BO → EBS Game Engine Chip Stack 업데이트 흐름 검토 v2

| 날짜 | 버전 | 변경 내용 |
|------|------|----------|
| 2026-05-14 | v2.0.0 | 신규 작성. Cycle 20 Wave 1 (#432) 의 webhook contract v1.0.0 + state machine v1.0.0 정합 검토. 12 누락 카테고리 식별 + 초안 텍스트. S7 권한 범위 내, 타 stream 영역은 권고만 기재. |

---

## §1. 검토 목적 + 범위

### 1.1 무엇을 검토했나

본 검토는 EBS 9 카테고리 SSOT (Foundation Ch.2) 중 **#1 플레이어 대시보드의 chipstack 필드** 가 WSOP LIVE (외부 권위) → EBS BO (S7) → EBS Game Engine (S8) 으로 전파되는 데이터 흐름의 완성도를 점검한다. 검토 baseline = Cycle 20 Wave 1 (#432, 2026-05-13) 머지된 contract 3 종.

### 1.2 검토 대상 문서

| 문서 | 역할 | tier | 검토 결과 |
|------|------|:----:|----------|
| `WSOP_LIVE_Chip_Count_Sync.md` v1.0.0 | webhook contract 본체 | contract | 정합성 양호. 운영 가장자리 케이스 8 건 누락 |
| `Chip_Count_State.md` v1.0.0 | 4-state machine + reconcile | contract | 정합성 양호. crash 복구 + race 복원 정책 2 건 누락 |
| `WebSocket_Events.md` §4.2.11 | `chip_count_synced` 이벤트 | contract | replay 정책 명시. audit 매핑 1 건 모호 |
| `Foundation.md` Ch.5 §B.5 | 흐름도 | external | 정합. 변경 없음 |
| `Back_Office/Overview.md` §3.9 | 3-mode pull 정책 | internal | webhook = 별도 push 채널. 3-mode 와의 상호작용 1 건 미명시 |
| `Back_Office/Operations.md` §2.1 | DR 책임 매트릭스 | internal | chip count sync 시나리오 미흡 |
| `Back_Office/Sync_Protocol.md` §7.1 | Circuit Breaker | internal | pull 전용. webhook 측 retry 는 WSOP LIVE 책임 — 정합 |

### 1.3 검토 범위 경계 (Scope Discipline)

본 검토자 (S10-W stream worktree 에서 실행, S7 권한 범위 자문) 는 다음 영역만 수정 권한이 있다:

- ✅ **수정 가능**: `docs/2. Development/2.2 Backend/Back_Office/**` (본 파일 위치)
- ⚠️ **권고만 (advisory)**: `2.2 Backend/APIs/**` (S7 owner), `2.3 Game Engine/**` (S8 owner), `2.5 Shared/**` (conductor owner), Foundation (전사 owner)

PR 분리 권고는 §6 에서 명시.

---

## §2. 흐름 매핑 (As-Is, 2026-05-14 기준)

### 2.1 단계별 ASCII 시퀀스

```
                                          [브레이크 진입]
                                                │
                                                ▼
┌─────────────────┐                     ┌──────────────────┐
│ 딜러            │                     │ WSOP LIVE Staff  │
│ (각 테이블)     │  테이블별 입력      │ App + Backend    │
│                 │ ──────────────────▶ │ (브레이크 식별)  │
└─────────────────┘                     └────────┬─────────┘
                                                 │
                                                 │ 테이블 단위 push
                                                 │ (입력 끝나는 즉시,
                                                 │  묶음 전송 금지)
                                                 ▼
┌──────────────────────────────────────────────────────────────────┐
│ HTTP POST /api/wsop-live/chip-count-snapshot                     │
│ Headers: X-WSOP-Signature, X-WSOP-Timestamp, Idempotency-Key     │
│ Body: { snapshot_id, break_id, table_id, recorded_at, seats[] }  │
└──────────────────────────────────────────────────────────────────┘
                                                 │
                                                 ▼
                                       ┌───────────────────┐
                                       │ EBS BO (S7)       │
                                       │                   │
                                       │ Step 1: HMAC 검증 │
                                       │  - timestamp ±300s│
                                       │  - canonical_str  │
                                       │  - compare_digest │
                                       │                   │
                                       │ Step 2: Idempot.  │
                                       │  - snapshot_id=   │
                                       │    Idempotency-Key│
                                       │  - DB lookup      │
                                       │  - 중복→200       │
                                       │                   │
                                       │ Step 3: Schema    │
                                       │  - chip_count>=0  │
                                       │  - seat_number 1+ │
                                       │                   │
                                       │ Step 4: DB INSERT │
                                       │  chip_count_      │
                                       │  snapshots        │
                                       │  (seat 별 row N개)│
                                       └────────┬──────────┘
                                                │
                                  ┌─────────────┼─────────────┐
                                  │             │             │
                                  ▼             ▼             ▼
                          ┌───────────┐  ┌────────────┐  ┌──────────┐
                          │ 202 응답  │  │ WS publish │  │ Engine   │
                          │ (WSOP에게)│  │ chip_count_│  │ reconcile│
                          │           │  │ synced     │  │ trigger  │
                          └───────────┘  └─────┬──────┘  └─────┬────┘
                                               │               │
                                ┌──────────────┼──────────────┐│
                                │              │              ││
                                ▼              ▼              ▼▼
                          ┌──────────┐  ┌─────────────┐  ┌──────────────┐
                          │ Lobby    │  │ CC          │  │ Engine FSM   │
                          │ (S2):    │  │ (S3):       │  │ (S8):        │
                          │ table    │  │ seat_cell   │  │ ENGINE_AUTO  │
                          │ chip     │  │ .stack 갱신 │  │     ↓        │
                          │ total    │  │             │  │ WSOP_AUTH    │
                          │ 갱신     │  │ Overlay 도  │  │     ↓        │
                          │          │  │ 다음 Output │  │ RECONCILING  │
                          │          │  │ 사이클에    │  │     ↓        │
                          │          │  │ 반영        │  │ drift 측정   │
                          │          │  │             │  │     ↓        │
                          │          │  │             │  │ ENGINE_AUTO  │
                          │          │  │             │  │ (drift_event │
                          │          │  │             │  │  log)        │
                          └──────────┘  └─────────────┘  └──────────────┘
```

### 2.2 상태 머신 요약 (Chip_Count_State.md §1)

```
                       webhook 도착
                       (HMAC pass + DB commit)
                              │
   ┌──────────────┐           ▼            ┌──────────────────────┐
   │ ENGINE_AUTO  │ ─────────────────────▶ │ WSOP_AUTHORITATIVE   │
   │ (default)    │                        │ (truth 채택 직후)    │
   └──────────────┘                        └──────────┬───────────┘
         ▲                                            │
         │                                            │ WS broadcast
         │                                            │ + Engine notify
         │                                            ▼
         │                                  ┌──────────────────┐
         │ silent reconcile                 │ RECONCILING      │
         │ (drift ≤ threshold)              │ (drift 계산)     │
         ├──────────────────────────────────┴──────┬───────────┘
         │                                         │
         │                            drift > threshold
         │                                         │
         │                                         ▼
         │                              ┌────────────────────┐
         │                              │ DRIFT_LOGGED       │
         └──────────────────────────────│ (drift_event 기록) │
                                        └────────────────────┘
```

**전이 트리거 정합성** (검토 결과 ✅): webhook 도착 → HMAC 검증 → DB commit → WS broadcast → Engine in-process reconcile. 4 상태 모두 Engine reconcile 1-pass 안에 evaluate 됨. 별도 polling 없음.

### 2.3 흐름의 권위 (Authority) 분할

| 시간 구간 | 권위 source | 데이터 갱신 트리거 |
|----------|-----------|------------------|
| hand 진행 중 (PREFLOP/FLOP/TURN/RIVER/SHOWDOWN) | Engine 자동 계산 | OutputEvent (베팅/팟 회수) |
| 브레이크 (PAUSED state) | WSOP LIVE webhook | 딜러 입력 완료 → push |
| 핸드 종료 직후 ~ 다음 핸드 시작 전 | Engine (default) | OutputEvent + 가끔 webhook (race) |
| 시스템 재시작 직후 | Engine (default — ENGINE_AUTO 부터) | snapshot 재로드 |

**핵심 원칙** (Chip_Count_State.md §2.1): "WSOP LIVE webhook 이 도착한 시점에는 그 시점 stack 의 권위 = WSOP LIVE. Engine 자동 계산값과 다르면 WSOP LIVE 가 truth."

---

## §3. 강점 (What works well)

### 3.1 contract 자체의 완성도

| 항목 | 평가 | 근거 |
|------|------|------|
| Body schema 명확성 | ✅ 우수 | §3.3 7 필드 모두 타입 + 필수 + 설명 |
| HMAC 절차 표준성 | ✅ 우수 | canonical_string 패턴 = AWS SigV4 / Stripe webhook family. raw bytes 보존 명시 |
| Idempotency 견고성 | ✅ 우수 | header `Idempotency-Key` = body `snapshot_id` 강제. DB UNIQUE 제약 결합. 재시도 안전 |
| 에러 응답 코드 매트릭스 | ✅ 우수 | §5.2 7 종 + retry 가능 여부 명시 |
| Secret rotation 정책 | ✅ 우수 | §6.3 — 24h grace period + 2 secret 동시 수용 |
| DB schema 의 immutability | ✅ 우수 | `chip_count_snapshots` append-only + raw_payload JSONB 보존 |
| drift threshold 의 4-단계 | ✅ 우수 | NORMAL/MINOR/MAJOR/CRITICAL 차등화. operational alert 임계 명확 |
| race 시나리오 분류 | ✅ 양호 | §4.1 A/B/C 3 경우 + deferred queue 5 분 TTL |
| audit trail | ✅ 양호 | 5 저장소 + 90일+ 보존. raw_payload 로 분쟁 재현 가능 |

### 3.2 다른 SSOT 와의 정합

- **Foundation Ch.5 §B.5** 흐름도와 contract 가 100% 일치
- **WebSocket_Events.md §4.2.11** payload 가 webhook body 와 1:1 매핑 (변환 없음 — 추가 필드 `received_at` + `signature_ok` 만)
- **9 카테고리 SSOT #1 chipstack** 의 갱신 channel 4 (DB + Engine + WSOP LIVE push + RFID) 가 contract 와 정합

---

## §4. 누락 + 모호 영역 (12 카테고리)

> **표기 규칙**: 🔴 = 운영 blocker, 🟡 = staging 진입 전 해소 필요, 🟢 = 향후 작업 (Phase 2+).
> **권한 표기**: [S7] = 본 stream 직접 수정 가능, [advisory→S7/S8/conductor] = 권고만.

### 4.1 [advisory→S7] Engine reconcile 채널의 실체 모호 🟡

**현재 표기**: "in-process notification" (Chip_Count_State.md §2.2 step 1) / "Engine notify" (Chip_Count_Sync §10.1 step 4).

**문제**: BO 와 Engine 은 별도 컨테이너 (`ebs-bo` vs `ebs-engine`, Multi-Service Docker — Foundation Ch.5). "in-process" 라는 표현은 사실상 불가능. 실제 채널은 3 후보 중 하나:

- (a) WS 자체 구독: Engine 이 `chip_count_synced` WS 이벤트의 subscriber 로 등록 → BO 의 WS broadcast 가 reconcile trigger
- (b) HTTP RPC: BO 가 commit 후 `POST http://ebs-engine:8000/internal/chip-count-reconcile` 호출
- (c) Message queue (Redis Stream / NATS): BO publish, Engine consume

**권고 (S7 → S8 cross-ref)**: contract 에 "Engine notify channel" 섹션 추가. 3 후보 중 하나 명시. 선호 = (a) WS 구독 — 이미 인프라 존재 + audit_events replay 정합 자동 보장.

### 4.2 [S7] Mock 모드의 webhook 시뮬레이션 부재 🟡

**현재 상태**: `Sync_Protocol.md §1.1` 의 Mock 모드는 **pull** (WSOP LIVE 환경변수 미설정 시) 전용. webhook 은 push 이므로 "Mock 모드 = webhook 미발생" 으로 처리됨.

**문제**: 개발/staging 환경에서 chip count 흐름 e2e 테스트 불가. 다음 도구가 contract 에 명시되지 않음:

- `tools/wsop_webhook_mock.py` — 1 회 mock webhook 송신 (테스트용)
- `tools/wsop_webhook_replay.py` — 과거 raw_payload 재발송 (분쟁 시 재현)

**누락 초안** (본 문서 §5.2 참조 — 본 stream 권한 범위 내 추가).

### 4.3 [advisory→S7] WSOP LIVE player_id ↔ EBS player_id 매핑 🔴

**현재 표기**: contract §3.3 의 `seats[].player_id` = "WSOP LIVE player id". 그러나 EBS DB 의 `players` 테이블은 EBS 내부 player_id 사용.

**문제**: BO 가 webhook body 를 그대로 `chip_count_snapshots` 에 INSERT 하면 player_id 는 WSOP LIVE 값. 그러나 9 카테고리 SSOT #1 의 player 정보는 EBS 내부 id 기준. **join 시 mismatch 발생**.

**Triggers.md** 의 table_mapping 은 table 만 명시. player_mapping 은 미명시.

**권고**: contract §3.3 에 명시:
- (a) `player_id` 는 WSOP LIVE 값으로 보존 (audit) + 추가 컬럼 `ebs_player_id` 를 DB INSERT 시 lookup 으로 채움
- 또는 (b) webhook 송신 측 (WSOP LIVE) 이 EBS player_id 로 변환 후 송신 (mapping table 위치 = WSOP LIVE 측)

선호 = (a). 변환 책임은 EBS 측 (BO) 이 가짐.

### 4.4 [advisory→S7] Schema validation: seat_number max bound 🟡

**현재 표기**: `seat_number` = "1-based. 테이블의 max seat count 이하" (contract §3.3).

**문제**: max seat count 검증 로직 미명시. `tables` 테이블의 `max_seats` 컬럼 join 후 비교? webhook 처리 시 DB lookup overhead = +1 SELECT. 또는 비즈니스 룰 hard cap (9 / 10) ?

**권고**: contract §3.3 에 추가 validation rule:
```
seats[].seat_number: 1 <= seat_number <= tables.max_seats WHERE id = body.table_id
  - 위반 시 400 VALIDATION (field=seats[N].seat_number)
  - DB lookup cache: 5 min TTL (max_seats 는 거의 안 바뀜)
```

### 4.5 [advisory→S7] 빈 좌석 표기 일관성 🟢

**현재 표기**: `player_id=null` 또는 `seats` 배열에서 제외 — 양쪽 모두 수용 (contract §3.3).

**문제**: "양쪽 수용" 은 ambiguity. EBS 내부에서 다음 시나리오 처리 불명확:

- 시나리오 A: WSOP LIVE 가 좌석 1,2,4 만 보냄 (3 = 빈 좌석으로 추정)
- 시나리오 B: WSOP LIVE 가 좌석 1,2,3(player_id=null,chip=0),4 보냄

A 와 B 의 의미는 동일하지만 처리 코드 다름. **권고**: 단일 표기 강제 = 항상 모든 좌석 포함 (빈 좌석 = `player_id=null, chip_count=0`). A 의 경우는 400 VALIDATION 처리.

### 4.6 [advisory→S7] Stale data: hand 시작 후 도착한 webhook 🟡

**현재 표기**: §4.2 (B) "hand 진행 중 → deferred queue 5 분 TTL".

**문제**: 5 분 후 hand 가 계속 진행 중이면 webhook 은 어떻게 되는가? 3 후보:

- (a) drop + alert (truth 손실)
- (b) drift_event CRITICAL 강제 기록 후 적용
- (c) hand FSM 강제 PAUSED 전이 후 적용

**권고**: contract §4.3 에 5 분 TTL 만료 처리 명시 = (b). 이유: chipstack truth 손실은 더 큰 문제. 5 분 = 정상 hand 시간의 95th 이상 — 그 시점이면 hand 자체에 다른 문제 (스톨)가 있을 가능성.

추가: 5 분 TTL 만료 + 적용 = `chip_count_drift_events.level = STALE_FORCED`. 신규 level 추가.

### 4.7 [advisory→S7] recorded_at vs received_at 시계 신뢰 🟡

**현재 표기**: `X-WSOP-Timestamp` 만 ±300s drift 검증 (contract §6.2 step 1).

**문제**: `recorded_at` (body 내) 은 검증 없음. WSOP LIVE 측 시계 오류 시 (예: 2030 년 timestamp, 또는 과거 시점) 그대로 DB 적재. 후속 query (`MAX(recorded_at)`) 가 오염.

**권고**: contract §6.2 step 1.5 추가:
```
body.recorded_at vs X-WSOP-Timestamp 비교
  - |body.recorded_at - X-WSOP-Timestamp| > 600s → 400 RECORDED_AT_DRIFT
  - 600s 임계 = 운영적으로 합리적 (브레이크 입력 ~ push 시간)
```

### 4.8 [S7] break_id 별 push 완료 신호 부재 🟢

**현재 표기**: webhook 은 테이블 단위 push. break 단위 종료 시그널 없음.

**문제**: Lobby UI 에서 "이번 break chip count 모두 도착" 표시가 불가능. 운영자는 N 개 테이블 중 몇 개가 push 됐는지 수동 카운트.

**권고**: 후속 contract 확장 — 2 옵션:

- (a) explicit signal: WSOP LIVE 가 break 종료 시 `POST /api/wsop-live/chip-count-snapshot/complete` 호출 (별도 endpoint)
- (b) implicit: BO 가 `tables WHERE active=true` 카운트 + 같은 `break_id` 의 distinct `table_id` 카운트 매칭 시 자동 broadcast `chip_count_break_complete`

선호 = (b) — WSOP LIVE 측 인터페이스 변경 없음. 본 검토 §5.1 에 초안 추가.

### 4.9 [advisory→S7] Rate limiting / burst capacity 미명시 🟡

**현재 표기**: 없음.

**문제**: 토너먼트 운영 = 동시 16~64 테이블. 브레이크 시 모든 테이블 push 가 ~ 60 초 안에 burst. BO 의 webhook endpoint capacity 미명시. DB INSERT bottleneck?

**권고**: contract §8 (Error Handling + Retry) 옆에 §8.3 추가:
```
Rate limit 정책:
  - per-source (WSOP LIVE): 100 req/sec (충분 = 64 테이블 / 60s = 1 req/s + 100x buffer)
  - per-source 초과 → 429 Too Many Requests + Retry-After: 1s
  - DB INSERT batching: 동일 break_id 의 webhook 을 100ms window 로 묶어 BULK INSERT (latency 영향 미미)
```

### 4.10 [advisory→S7] webhook 출처 IP 화이트리스트 옵션 🟢

**현재 표기**: HMAC 만으로 인증 (contract §6).

**문제**: HMAC 는 강력하지만 secret leak 시 단일 방어. 추가 layer 로 source IP 화이트리스트 적용 시 attack surface 감소.

**권고** (운영 결정): 환경 변수 `WSOP_LIVE_ALLOWED_IPS` (CIDR list) 추가. 미설정 시 disabled (현재 동작 = HMAC only). 설정 시 IP mismatch → 401 SOURCE_IP_FORBIDDEN.

### 4.11 [advisory→S7] audit_events 매핑 모호 🟡

**현재 표기**:
- WebSocket_Events.md §4.2.11: "audit_events 저장 대상 (replay 가능)"
- Chip_Count_Sync §5.1: "audit_events (envelope seq 단조증가)" 7 일+ 보존
- Chip_Count_State §5.1: "WS broadcast" 항목으로 audit_events 매핑

**문제**: audit_events 의 event type 이름이 명시 안 됨. `chip_count_synced` 그대로? 또는 별도 prefix (`wsop:chip_count_synced`)?

**권고**: contract §10 (WS Publish) 옆에 §10.2 추가:
```
audit_events 매핑:
  - event_type: "chip_count_synced"
  - source: "wsop-live-webhook"
  - correlation_id: snapshot_id (UUID)
  - causation_id: (이전 break 의 마지막 snapshot_id, optional)
  - payload: WS broadcast 의 data 와 동일 (raw_payload 별도 chip_count_snapshots 참조)
```

### 4.12 [S7] 권한 매트릭스: GET endpoint 인증 🟡

**현재 표기**: Chip_Count_State.md §1.3 — "`GET /api/tables/:id/chip-count-state` (운영 도구용)". 권한 미명시.

**문제**: 운영 도구는 누구의 도구? Admin / Operator / Viewer 중?

**권고**: contract §11 신규 (또는 본 검토 §5.3 에 BO 차원에서 정의):
```
GET /api/tables/:id/chip-count-state
  권한: Admin (read) / Operator (read, 할당 테이블만)
  Viewer: 403 Forbidden
  응답 schema: { state: ENGINE_AUTO|WSOP_AUTHORITATIVE|RECONCILING|DRIFT_LOGGED,
                last_snapshot_id, last_recorded_at, last_drift_level }
```

---

## §5. 누락 초안 텍스트 (Draft Content)

> 본 §5 의 텍스트는 contract / Operations / Sync_Protocol 갱신 시 그대로 흡수 가능한 draft. 권한 영역 (S7 직접 vs advisory) 표기.

### 5.1 [S7] break_id complete 자동 신호 (§4.8 해소)

> 삽입 위치 안: `WSOP_LIVE_Chip_Count_Sync.md` §10 옆 신규 §10.3, 또는 본 문서 derivative.

**`chip_count_break_complete` 이벤트 (auto-derived)**

BO 가 동일 `break_id` 의 distinct `table_id` 카운트와 `tables WHERE active=true AND broadcast_eligible=true` 의 카운트가 일치하면 자동 broadcast.

조건:
- `SELECT COUNT(DISTINCT table_id) FROM chip_count_snapshots WHERE break_id = $X` ≥ `SELECT COUNT(*) FROM tables WHERE active=true`
- 첫 일치 시점에만 발행 (이후 동일 break_id 추가 push 시 미발행 — idempotent)

Payload:
```json
{
  "type": "chip_count_break_complete",
  "data": {
    "break_id": 1024,
    "table_count": 16,
    "completed_at": "2026-05-13T18:45:30.123Z",
    "drift_summary": { "MINOR": 2, "MAJOR": 1, "CRITICAL": 0 }
  }
}
```

Subscribers: Lobby (배너 표시 — "Break chip count 완료") / Engine (post-break reconcile 종료 신호).

### 5.2 [S7] Mock webhook 도구 (§4.2 해소)

> 삽입 위치 안: `Back_Office/Sync_Protocol.md` §8 (Mock 모드) 옆 신규 §8.4.

**`tools/wsop_webhook_mock.py` — 개발 / staging 도구**

```bash
# 1 회 mock webhook 송신 (현재 시각 + 더미 데이터)
python tools/wsop_webhook_mock.py \
  --host http://localhost:8000 \
  --secret $WSOP_LIVE_WEBHOOK_SECRET \
  --break-id 1024 \
  --table-id 17 \
  --seats "1:901:125000,2:902:87500,4:904:211000"

# raw_payload replay (분쟁 재현)
python tools/wsop_webhook_replay.py \
  --host http://localhost:8000 \
  --secret $WSOP_LIVE_WEBHOOK_SECRET \
  --snapshot-id 8a7e9c4e-5d3b-4f1a-9c2e-7b6a0e8f1d3c \
  --from-db   # chip_count_snapshots.raw_payload 에서 추출
```

도구 구현 책임 = S7. 도구 자체는 production 배포 대상 아님 (`tools/` 디렉토리 = dev only).

### 5.3 [S7] chip-count-state read endpoint 권한 (§4.12 해소)

> 삽입 위치 안: `Back_Office/Overview.md` §3.1 (Auth + RBAC) 표 옆 신규 row, 또는 본 검토 derivative.

```
GET /api/tables/:id/chip-count-state

권한 매트릭스:
  - Admin: ✅ 전 테이블 read
  - Operator: ✅ 할당된 table_id 만 read (mismatch → 403)
  - Viewer: ❌ 403 Forbidden

응답 (200):
{
  "table_id": 17,
  "state": "ENGINE_AUTO",  // or WSOP_AUTHORITATIVE / RECONCILING / DRIFT_LOGGED
  "last_snapshot_id": "8a7e9c4e-...",  // null if no webhook yet
  "last_recorded_at": "2026-05-13T18:32:15Z",
  "last_drift_level": "MINOR",  // null if no drift yet this session
  "deferred_queue_size": 0  // §4.3 of Chip_Count_State.md
}
```

캐싱 = none (in-memory state). DB lookup ≈ 1 SELECT + 1 in-memory read.

### 5.4 [S7] DR 시나리오 F — chip count 손실 (§3.1 audit + 운영 시나리오 보강)

> 삽입 위치 안: `Back_Office/Operations.md` §2.1 책임 매트릭스 옆 신규 row "F".

| 시나리오 | 자동 복구 | 운영자 개입 | 개발팀 개입 |
|----------|:--------:|:----------:|:----------:|
| **F: WSOP LIVE chip count sync 손실** (2026-05-14 신설) | O (부분) | **필수** | 장기 시 |

**F-1 webhook signature 반복 실패** (HMAC mismatch ≥ 5 회/min): secret rotation 진행 중 또는 attack. → 자동 alert + 운영자 secret 확인.
**F-2 webhook 도착 후 Engine reconcile 실패** (RECONCILING state 5 분 stuck): Engine FSM 점검 필요. → 자동 alert + 운영자 수동 trigger (`POST /api/internal/engine-reconcile-retry`).
**F-3 break_id 일부 테이블만 push** (브레이크 종료 후 30 분 이상 누락 테이블 존재): WSOP LIVE 측 송신 누락 또는 EBS 미수신. → 운영자 manual entry UI (별도 추후 작업, Phase 2+).
**F-4 chip_count_snapshots 테이블 손실 (DR 시나리오)**: pg_dump restore. raw_payload JSONB 있으므로 replay 가능. 도구 = §5.2 의 `wsop_webhook_replay.py`.

### 5.5 [S7] WSOP_LIVE pull 3-mode 와 webhook push 의 관계 (§4.1 보강)

> 삽입 위치 안: `Back_Office/Overview.md` §3.9 (3-mode pull) 옆 신규 §3.9.1.

**chip count 는 4 번째 채널 — webhook push**

§3.9 의 3-mode pull (자동 폴링 / Confirm-triggered / Manual immediate) 은 모두 **EBS → WSOP LIVE 방향 pull**. chip count 는 **WSOP LIVE → EBS 방향 push (webhook)**. 채널 자체가 다름.

| 데이터 | 방향 | 채널 | 빈도 |
|-------|------|------|------|
| Series / Event / Flight | EBS ← WSOP LIVE | pull (3-mode) | 15-60s |
| Player profile | EBS ← WSOP LIVE | pull (자동 폴링) | 60s |
| **chip count snapshot** | EBS ← WSOP LIVE | **push (webhook)** | event-driven (브레이크) |
| Seat assignment | EBS ← WSOP LIVE | pull (Confirm-triggered) | manual |

3-mode 정책 (preview→confirm 등) 은 chip count 에 적용 안 됨 — push 는 본질적으로 immediate.

---

## §6. PR 분리 권고

본 검토에서 식별된 12 개 누락 항목을 **권한 영역 + 변경 무게** 기준으로 5 PR 로 분리 권고:

| PR | 영역 | 권한 | 항목 | 우선순위 |
|:--:|------|:----:|------|:--------:|
| **PR-A** | S7 직접 (본 stream) | ✅ | §4.2 Mock 도구 (5.2 초안) + §4.8 break_complete 신호 (5.1 초안) + §4.12 read endpoint 권한 (5.3 초안) + §5.4 DR 시나리오 F + §5.5 3-mode 와의 관계 명시 | 🟢 즉시 |
| **PR-B** | contract (S7 owner) | advisory | §4.1 Engine reconcile 채널 실체 명시 + §4.11 audit_events 매핑 명시 | 🟡 다음 cycle |
| **PR-C** | contract (S7 owner) | advisory | §4.3 player_id 매핑 + §4.4 seat_number max bound validation + §4.5 빈 좌석 표기 단일화 | 🟡 다음 cycle |
| **PR-D** | contract + Engine (S7+S8 cross-ref) | advisory | §4.6 stale 5 분 TTL 만료 처리 (STALE_FORCED level) + §4.7 recorded_at drift 검증 | 🟢 staging 전 |
| **PR-E** | contract + 운영 (S7 owner) | advisory | §4.9 rate limit + §4.10 source IP 화이트리스트 | 🟢 production 전 |

### 6.1 PR-A 의 본 stream 처리 가이드

본 검토자는 S10-W stream worktree 에서 작업 중. PR-A 의 5 항목 모두 `docs/2. Development/2.2 Backend/Back_Office/**` 또는 `docs/2. Development/2.2 Backend/APIs/Sync_Protocol.md` (S7 정본) 영역. S10-W scope 침범. **본 검토는 advisory 만 제공**, 실제 PR-A 작성은 S7 owner 가 직접 처리 권장.

대안: 본 검토 문서 자체가 (a) S10-W 가 cross-cutting gap 으로 식별, (b) S7 이 PR-A 로 정합화 의 2-stage 흐름의 (a) 산출물로 충분. PR-A 단일 PR 로 S7 stream 의 차후 cycle 에서 처리.

### 6.2 우선순위 근거

- 🟢 PR-A: 본 stream 영역. Mock 도구는 e2e 테스트 가속.
- 🟡 PR-B: webhook 흐름의 핵심 모호 (Engine notify 채널). 다음 cycle 필수.
- 🟡 PR-C: player_id mismatch 는 silent corruption 위험.
- 🟢 PR-D: edge case. staging 진입 전 해소.
- 🟢 PR-E: production 운영 전 해소. 토너먼트 burst capacity + 보안 layer.

---

## §7. 검토 결과 요약 (1-page)

```
┌──────────────────────────────────────────────────────────────┐
│ Contract 자체:    매우 양호 (v1.0.0 정합성 100%)             │
│ 흐름 완성도:      양호 (Foundation Ch.5 §B.5 와 1:1 일치)    │
│ 누락 카테고리:    12 건                                      │
│   - 🔴 운영 blocker: 1 건 (§4.3 player_id 매핑)              │
│   - 🟡 staging 전: 7 건                                      │
│   - 🟢 향후:      4 건                                       │
│ PR 분리:          5 개 (PR-A ~ PR-E)                         │
│ 본 stream 권한:   PR-A 직접 / PR-B~E advisory                │
└──────────────────────────────────────────────────────────────┘
```

### 핵심 3 누락 (한 줄)

1. **🔴 player_id 매핑 (§4.3)**: WSOP LIVE player_id ↔ EBS player_id 변환 책임자 미지정 — silent join mismatch 위험
2. **🟡 Engine reconcile 채널 실체 (§4.1)**: "in-process notification" 표현이 멀티 컨테이너 환경에서 실현 불가 — WS 구독 / HTTP RPC / MQ 중 명시 필요
3. **🟡 audit_events 매핑 (§4.11)**: event_type / correlation_id / causation_id 구조 미명시 — replay 자동화 차질

---

## §8. Related Documents

| 문서 | 역할 |
|------|------|
| `WSOP_LIVE_Chip_Count_Sync.md` v1.0.0 | webhook contract 본체 (검토 대상) |
| `Chip_Count_State.md` v1.0.0 | 4-state machine + reconcile (검토 대상) |
| `WebSocket_Events.md` §4.2.11 | `chip_count_synced` event (검토 대상) |
| `Foundation.md` Ch.5 §B.5 | 흐름도 SSOT (변경 없음) |
| `Back_Office/Overview.md` §3.9 | 3-mode pull (별도 채널) |
| `Back_Office/Sync_Protocol.md` §1.1 | OAuth 인증 (별도 channel) |
| `Back_Office/Operations.md` §2.1 | DR 책임 매트릭스 (보강 권고) |
