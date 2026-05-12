---
title: NOTIFY-S10-W — Back_Office_PRD 통합용 백엔드 동기 자료 (2026-05-12)
owner: S7
tier: internal
last-updated: 2026-05-12
audience: S10-W
related:
  - ../Back_Office/Overview.md
  - ../Back_Office/Sync_Protocol.md
  - ../Database/Schema.md
  - ../../../1. Product/Back_Office.md
---

# NOTIFY-S10-W — Back_Office_PRD 통합용 백엔드 동기 자료

**발신**: S7 Backend (Cycle 8 / 2026-05-12)
**수신**: S10-W (Gap Writing Stream — Back_Office.md 재작성 진행 중)
**목적**: S10-W 가 `docs/1. Product/Back_Office.md` 에 반영해야 할 백엔드 측 사실 3가지 (DB schema 정합·WSOP LIVE Confirm-triggered pull 패턴·PokerGFX 패턴 매핑) 1-page 요약.

---

## 1. 한 줄 요약 (TL;DR)

| 항목 | 상태 | S10-W 가 PRD 에 반영해야 할 것 |
|------|:----:|-------------------------------|
| **DB schema 정합** | 27 테이블 init.sql + Schema.md 1:1 정합 | `sync_cursors` 테이블만 신설 권고 (현재 Redis-only) |
| **WSOP LIVE pull 트리거** | 폴링 + manual-trigger (즉시 UPSERT) 만 존재 | Confirm-triggered (preview→confirm 2단계) 패턴 추가 |
| **PokerGFX 패턴** | hand_results 정규화 결여, num_boards/run_it/blind_level 결여 | PokerGFX 5-테이블 대비 EBS 4-테이블의 의도된 차이를 PRD 에 명시 |

---

## 2. DB Schema audit 결과 (Task #1)

### 2.1 정합 상태 — 정합 (PASS)

| 영역 | init.sql | Schema.md (DATA-04) | SQLModel | 정합 |
|------|:--------:|:-------------------:|:--------:|:----:|
| 대회 계층 (competitions/series/events/event_flights) | ✓ | ✓ | ✓ | PASS |
| 테이블/좌석/플레이어 (tables/table_seats/players) | ✓ | ✓ | ✓ | PASS |
| 핸드 (hands/hand_players/hand_actions) | ✓ | ✓ | ✓ | PASS |
| RFID (cards/decks/deck_cards) | ✓ | ✓ | △ (decks Phase 1 in-memory) | PASS |
| Admin (users/user_sessions/audit_logs) | ✓ | ✓ | ✓ | PASS |
| Settings (configs/settings_kv) | ✓ | ✓ | ✓ | PASS |
| 출력 (skins/output_presets) | ✓ | ✓ | ✓ | PASS |
| 운영 (blind_structures/payout_structures + levels) | ✓ | ✓ | ✓ | PASS |
| 멱등성/이벤트 소싱 (idempotency_keys/audit_events) | ✓ | ✓ | △ (audit_event.py only) | PASS |
| Waiting (waiting_list) | ✓ | ✓ | ❌ (init.sql DDL) | PASS — 의도된 분리 |
| **동기화 cursor (sync_cursors)** | ❌ | ❌ | ❌ | **GAP** |

### 2.2 Tournament Clock — 정합 (별도 테이블 불필요)

> 사용자 요청 "Tournament Clock 상태" 는 별도 테이블이 아니라 `event_flights.{status, play_level, remain_time}` 로 흡수됨. `clock_service.py` 가 이 세 컬럼을 IDLE→running→paused FSM 으로 다룸. **별도 `tournament_clocks` 테이블 신설 권고하지 않음** (정규화 손해 + Foundation Ch.5 §B.4 DB SSOT 원칙에서 event_flights 가 이미 단일 권위).

### 2.3 Player Stack snapshot — 분산 저장 (의도됨)

> PokerGFX `poker_players.cumulative_winnings` 패턴 (세션 누적) 미채택. EBS 는 핸드 단위 `hand_players.{start_stack, end_stack, pnl}` + 현재 칩카운트 `table_seats.chip_count` 의 2-축 저장. **누적 stack 변화 그래프** 가 필요해질 경우 (BS-06 Hand History/Stats 요구) `hand_players` 시퀀스 합산으로 view 도출 가능 — 별도 snapshot 테이블 불필요.

### 2.4 신규 권고 — `sync_cursors` 테이블 (Gap 해소)

**근거**: Sync_Protocol.md §7.1 에 `sync_cursor:{entity}` (Redis) 또는 `sync_cursors` (DB) 양자 옵션으로 명시되어 있으나 init.sql / Schema.md 에 DB 형태 정의 부재. Foundation Ch.5 §B.4 "DB = SSOT" 원칙 + Redis 미배포 환경 (단일 PC 운영) 대응 위해 DB 정본 권고.

```sql
-- 신규 테이블 권고
CREATE TABLE sync_cursors (
    entity TEXT PRIMARY KEY,              -- 'series' | 'event' | 'event_flight' | 'player' | 'seat'
    cursor TEXT NOT NULL,                 -- ISO 8601 (단조증가 강제)
    last_correlation_id TEXT,             -- CB OPEN 구간 묶음 ID
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);
CREATE INDEX idx_sync_cursors_updated ON sync_cursors(updated_at);
```

**S10-W 가 Back_Office.md 에 추가**:
- §3.9 WSOP LIVE 동기화 끝에 "단조증가 cursor 영속화 — DB SSOT (Redis 옵션은 운영 환경 한정)" 1줄 추가.

---

## 3. WSOP LIVE Confirm-triggered pull 패턴 설계 (Task #2)

### 3.1 현재 상태 — 2가지 pull 모드만 존재

| 모드 | 트리거 | 시퀀스 | 사용자 진입점 |
|------|--------|--------|-------------|
| **자동 폴링** | APScheduler (15-60s 주기) | fetch → UPSERT (즉시 commit) | 없음 (백그라운드) |
| **수동 trigger** | `POST /api/v1/sync/wsop-live` (Admin) | fetch → UPSERT (즉시 commit) | Admin 클릭 |

**한계**: 둘 다 **preview 단계 없음**. WSOP LIVE 에서 큰 변경(예: Event 30개 신규)을 pull 할 때 Admin 이 변경 내용을 확인할 기회 없이 DB 가 즉시 갱신됨. Lobby Settings "WSOP Sync" 탭의 Admin 확인 단계(BS-03)와 모순.

### 3.2 신규 패턴 — Confirm-triggered pull (2-stage)

```
   [Admin]                  [BO]                       [DB]
     |                       |                          |
     |--- 1) preview 요청 -->|                          |
     |                       |--- fetch from WSOP --->  |
     |                       |--- diff 계산 ---|        |
     |                       |    (DB write 없음)       |
     |<-- diff_id + diff[] --|                          |
     |                       |                          |
     | (사용자가 변경 확인)   |                          |
     |                       |                          |
     |--- 2) confirm 요청 -->|                          |
     |    (diff_id + Idem-Key)|--- UPSERT ---->         |
     |                       |--- audit_event append -> |
     |<-- 결과 (count) ------|                          |
     |                       |                          |
     | (또는 abort)          |                          |
     |--- 3) abort --------->|                          |
     |                       |--- diff_id 폐기 -|       |
```

### 3.3 신규 endpoint 3종

| 메서드 | 경로 | 권한 | 동작 |
|:------:|------|:----:|------|
| POST | `/api/v1/sync/wsop-live/preview` | Admin | WSOP LIVE fetch + diff 계산, DB write 없음. `diff_id` (UUID, TTL 10분) + entities[] 반환 |
| POST | `/api/v1/sync/wsop-live/confirm` | Admin | `diff_id` + `Idempotency-Key` 헤더 받아 UPSERT 실행. 24h 멱등 |
| DELETE | `/api/v1/sync/wsop-live/preview/{diff_id}` | Admin | 사용 안 한 diff 폐기 |

**기존 endpoint 유지**:
- `POST /api/v1/sync/wsop-live` (manual immediate) — backward compat, deprecation warning 헤더 추가
- 자동 폴링은 그대로 (Admin 확인 불필요한 incremental delta 만 pull)

### 3.4 polling vs Confirm-triggered 차이 — 무엇을 언제 쓰나

| 시나리오 | 모드 | 이유 |
|----------|------|------|
| Series/Event 신규 추가 (대규모) | **Confirm-triggered** | Admin 이 변경 범위 확인 필요 (BS-03 §매칭 UI) |
| 플레이어 칩카운트 incremental 동기화 | **자동 폴링** | 변경량 작고 빈번. preview 부담 |
| 첫 운영 시 초기 import | **Confirm-triggered (initial)** | 전체 데이터 import — Admin 결정 필요 |
| 장애 복구 후 재개 | **자동 폴링 + Fallback Queue** | Sync_Protocol §7.1 의 기존 cursor-based delta |

### 3.5 S10-W 가 Back_Office.md 에 반영해야 할 것

§3.9 "WSOP LIVE 동기화" 를 아래 구조로 보강:

```
3.9.1 자동 폴링 (incremental)   — 기존 유지
3.9.2 Confirm-triggered pull   — Admin 변경 검토 후 commit (신규 패턴)
3.9.3 Fallback Queue + cursor  — 장애 복구 (Sync_Protocol §7.1 참조)
```

**1줄 정책**: "대규모/구조적 변경은 preview→confirm. 소규모/incremental 은 자동."

---

## 4. PokerGFX 패턴 vs EBS 매핑 (Task #3)

### 4.1 PokerGFX 5-테이블 schema (정본: `automation_ae/tasks/prds/0002-prd-pokergfx-db-schema.md`)

```
poker_sessions  (gfx_session_id BIGINT UNIQUE, event_title, payouts JSON)
   └─ poker_hands       (session_id FK, hand_num, game_variant/class/bet_structure,
       │                 num_boards, run_it_num_times, button_seat, sb/bb seat+amount,
       │                 ante_type, blind_level, community_cards JSON)
       ├─ poker_players  (hand_id FK, seat_num, name, start/end_stack, cumulative_winnings,
       │                  hole_cards JSON, sitting_out, elimination_rank,
       │                  vpip/pfr/af/wtsd_percent, master_record_id FK)
       │   └─ hand_results (player_id FK 1:1, rank_value 1-7462, rank_category ENUM 10단계,
       │                    is_premium, is_winner, won_amount)
       └─ poker_events   (hand_id FK, event_order, event_type ENUM 12값, bet_amount,
                          pot_amount, board_cards JSON, board_num, cards_drawn)
```

### 4.2 EBS 대응 매핑 + 의도된 차이

| PokerGFX | EBS 대응 | 매핑 상태 | 의도된 차이 / Gap |
|----------|---------|:--------:|------------------|
| `poker_sessions` | `event_flights` | ≈ 대응 | gfx_session_id → wsop_id 패턴. payouts → `payout_structures` 분리 (정규화 강화) |
| `poker_hands` | `hands` | ≈ 대응 | **결여**: `num_boards`/`run_it_num_times` (Run It Twice), `button_seat`, `sb_seat`/`sb_amount`/`bb_seat`/`bb_amount` (현재 `tables` 에만 있음), `blind_level` |
| `poker_players` | `hand_players` | ≈ 대응 | **결여**: `cumulative_winnings`/`sitting_out`/`elimination_rank`/`master_record_id`. 통계 4종 (vpip/pfr/af/wtsd) 은 `hand_players.{vpip,pfr}` 만 (af/wtsd 없음) |
| `poker_events` | `hand_actions` | 1:1 대응 | **결여**: `cards_drawn` (Draw 게임), `board_num` (Run It 분기). event_type 14종 (PokerGFX 12종) |
| `hand_results` | `hand_players.{hand_rank, win_probability, is_winner, pnl}` | △ 분산 | **결여**: `rank_value` (1-7462 정량값, phevaluator 출력). EBS 는 정규화 없이 hand_players 에 흡수 |

### 4.3 결론 — 추가 작업 권고 (S10-W 결정 필요)

**Option A**: EBS hands/hand_players 컬럼 추가 (additive, breaking 없음)
- `hands.num_boards`, `hands.run_it_num_times`, `hands.button_seat`, `hands.sb_seat`, `hands.sb_amount`, `hands.bb_seat`, `hands.bb_amount`, `hands.blind_level`
- `hand_players.cumulative_winnings`, `hand_players.sitting_out`, `hand_players.elimination_rank`
- `hand_actions.cards_drawn`, `hand_actions.board_num`
- 별도 `hand_evaluations` 테이블 신설 (`hand_id` + `player_id` + `rank_value` 1-7462 + `rank_category`)

**Option B**: 현 schema 유지 — EBS 는 RFID + Game Engine 기반이므로 PokerGFX 패턴의 일부 (예: phevaluator rank_value) 는 Engine 책임으로 위임 가능 (engine 응답이 SSOT — `audit_event.py` 의 hand_complete payload 에 포함)

**S7 권고**: **Option B + PRD 에 의도된 차이 명시**. 근거:
1. EBS Core (Foundation Ch.5) 는 Engine 이 게임 상태 SSOT — `rank_value` 정량값은 Engine 응답 payload 에 이미 포함 (`win_probability` 와 동일 경로)
2. `cumulative_winnings` 는 view 도출 가능 (정규화 손해 회피)
3. `num_boards`/`run_it` 등 게임 변형 필드는 v04 deeper-game spec (Cycle 7 #335) 에서 game_rules JSON 으로 흡수 진행 중 — DB column 보다 JSON 유연성 우선

**S10-W 가 Back_Office.md 에 추가**:
§3.5 "핸드 기록" 끝에 "PokerGFX 벤치마크 대비 의도된 차이" 1박스 추가. 자세히는 본 NOTIFY 의 §4.2 표 인용.

---

## 5. S10-W 작업 체크리스트 (압축)

| # | 위치 | 변경 | 출처 |
|:-:|------|------|------|
| 1 | Back_Office.md §3.9 | 자동 폴링 + Confirm-triggered + Fallback 3-mode 표 추가 | 본 NOTIFY §3.5 |
| 2 | Back_Office.md §3.9 끝 | "단조증가 cursor 영속화 — DB SSOT (sync_cursors)" 1줄 | 본 NOTIFY §2.4 |
| 3 | Back_Office.md §3.5 끝 | "PokerGFX 벤치마크 대비 의도된 차이" 박스 (§4.2 표 인용) | 본 NOTIFY §4.3 |
| 4 | (S10-W 판단) | Option A vs B 결정 시 S7 에 회신 (issue comment) | 본 NOTIFY §4.3 |

S7 측에서 추가로 수행할 작업 (병행):
- (a) Schema.md 에 `sync_cursors` 테이블 신설 — S7 publisher 권한
- (b) Sync_Protocol.md 에 Confirm-triggered pull 섹션 추가 — S7 publisher 권한
- (c) `team2-backend/src/routers/sync.py` 에 preview/confirm endpoint 3종 implementation — Cycle 9 백로그 (B-NEW)
- (d) Cycle 9 issue 등록: "B-NEW: WSOP LIVE Confirm-triggered pull 3-endpoint impl"

---

## 6. Broker publish (cascade:backend-prd-sync)

본 NOTIFY 작성 완료 시 publish:

```json
{
  "stream": "S7",
  "event": "cascade:backend-prd-sync",
  "seq": "<broker assigns>",
  "ts": "2026-05-12T...",
  "payload": {
    "notify_path": "docs/2. Development/2.2 Backend/Backlog/NOTIFY-S10-W-backend-sync-2026-05-12.md",
    "target_prd": "docs/1. Product/Back_Office.md",
    "decisions_needed": ["Option A vs B (PokerGFX 매핑)"],
    "decisions_made_by_s7": ["sync_cursors 테이블 신설", "Confirm-triggered 2-stage endpoint 설계", "polling vs Confirm 사용 기준 정의"]
  }
}
```

S10-W subscribe 후 본 NOTIFY 의 §5 체크리스트 작업 진행.

---

## 변경 이력

| 날짜 | 변경 | 작성자 |
|------|------|--------|
| 2026-05-12 | 초안 (Cycle 8 P0 cascade) | S7 |
