---
title: Triggers & Event Pipeline — Domain Master
owner: team3
tier: contract
legacy-ids:
  - BS-06-00-triggers   # Triggers.md (CC/RFID/Engine/BO 트리거 경계 정의)
  - BS-06-09            # Event_Catalog.md (Input/Internal/Output 이벤트 카탈로그)
  - BS-06-04            # Holdem/Coalescence.md (RFID burst 병합 알고리즘)
  - BS-06-12            # Card_Pipeline_Overview.md (Turn-based deal + Atomic flop)
last-updated: 2026-04-27
related:
  - "Behavioral_Specs/Lifecycle_and_State_Machine.md"  # Lifecycle 도메인 마스터 (Phase 1)
  - "../2.5 Shared/BS_Overview.md"                       # GameState / 트리거 소스 SSOT
  - "../2.4 Command Center/APIs/RFID_HAL.md"            # RFID 입력 SSOT
  - "APIs/Overlay_Output_Events.md"                      # OutputEvent 카탈로그 §6.0
---

# Triggers & Event Pipeline — Domain Master

> **존재 이유**: 게임 엔진의 모든 이벤트 파이프라인 (외부 입력 트리거 + 내부 자동 전이 + 외부 출력) 과 그 충돌 해결 (coalescence) 을 단일 SSOT 로 통합한다. 본 문서는 BS-06-00-triggers (트리거 경계) + BS-06-09 (이벤트 카탈로그) + BS-06-04 (RFID coalescence) + BS-06-12 (카드 파이프라인) 4개 문서를 zero information loss 로 병합한다. 상태 전이 자체는 Lifecycle 도메인 마스터가 권위 — 본 문서는 그 전이를 일으키는 **트리거 + 이벤트 + 충돌 해결** 만 담는다.

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-06 | BS-06-04 신규 | 트리거 정의 총괄 + 우선순위 + coalescence 알고리즘 |
| 2026-04-06 | BS-06-04 v2.0 보강 | 경계 조건, 상태별 활성 매트릭스, 유저 스토리 33건, 시나리오 매트릭스, 구현 가이드 확장 |
| 2026-04-08 | BS-06-08 신규 | 4 트리거 소스 (CC/RFID/Engine/BO), 이벤트 분류, Mock 합성 규칙 |
| 2026-04-08 | BS-06-09 신규 | Input/Internal/Output 3계층 이벤트 정의, payload 스키마, 유효 상태 매트릭스 |
| 2026-04-09 | BS-06-09 IE-02 보강 | Call/AllIn amount 외부 무시 + 엔진 내부 재계산 |
| 2026-04-10 | BS-06-09 WSOP P1/P2 | IE-10/11/12/13, IT-DealCommunityRecovery, OE-HandTabled/HandRetrieved/MuckRetrieved/FlopRecovered/DeckIntegrityWarning |
| 2026-04-13 | BS-06-08 설명 보강 | 모든 이벤트 친절한 설명, 시팅 트리거 6개, SeatFSM/TableFSM 매트릭스, WSOP LIVE 매핑 |
| 2026-04-13 | BS-06-08 Clock 트리거 | §2.4 BO ClockStarted/Paused/Resumed + §2.5 Auto Blind-Up 로직 |
| 2026-04-13 | BS-06-09 GAP-B 보강 | OE-05 legalActions payload, Output Accumulation 순서, OE-19 display_to_players |
| 2026-04-14 | BS-06-08 CCR-050 | §2.5 Clock 5종 추가 (ClockRestarted, clock_detail_changed, clock_reload_requested, stack_adjusted, tournament_status_changed) — WSOP LIVE SignalR Hub 정렬 |
| 2026-04-27 | BS-06-12 신규 (PR #4) | Turn-based hole release + 3-card atomic flop SSOT |
| 2026-04-27 | BS-06-12 압축 (PR #5) | verbose → quickref Trigger Matrix (T1~T11) |
| 2026-04-27 | 도메인 통합 (본 문서) | BS-06-00-triggers + BS-06-09 + BS-06-04 + BS-06-12 (verbose) 를 lossless 병합. legacy-ids 보존. Lifecycle 도메인 마스터 cross-ref. **Chunk-by-chunk commit 으로 작성** (sibling worktree retry after 2026-04-27 subdir conflict) |

---

## 1. Overview & Definitions

### 1.1 도메인 정의

본 도메인은 4 가지 직교 관심사를 통합한다:

1. **트리거 소스 분류** (BS-06-00-triggers): "어떤 이벤트가 누구에 의해 발동되는가" — 4 입력 소스 (CC / RFID / Engine / BO) 의 경계 정의
2. **이벤트 카탈로그** (BS-06-09): 트리거가 야기하는 Input / Internal / Output 3계층 이벤트의 payload 스키마
3. **충돌 해결** (BS-06-04 Coalescence): 동시 트리거 발생 시 우선순위 + 시간 윈도우 + 폐기/큐잉 규칙
4. **카드 파이프라인** (BS-06-12): RFID/CC → buffer → engine → OutputEvent 의 turn-based 분배 + atomic flop 감지

상태 전이 자체는 Lifecycle 도메인 마스터의 권위. 본 도메인은 **트리거 + 이벤트 + 충돌 해결** 만 담는다.

### 1.2 4 트리거 소스 (통합 정의 — BS-06-00-triggers §1 + BS-06-04 §우선순위 통합)

| 소스 | 발동 주체 | 처리 시간 | 신뢰도 | 채널 |
|------|---------|---------|--------|------|
| **CC** | 운영자 (수동) | 즉시 (<50ms) | 낮음 (인간 오류 가능) | CC Flutter → Game Engine |
| **RFID** | 시스템 (자동) | 변동 (50~150ms) | 높음 (하드웨어) | RFID HAL → CC → Game Engine |
| **Engine** | 시스템 (자동) | 결정론적 (<10ms) | 최고 (규칙 기반) | Game Engine 내부 |
| **BO** | 시스템 (자동) | 변동 (100~500ms) | 높음 | BO WebSocket → CC/Lobby |

> Coalescence (BS-06-04) 의 우선순위 계층은 §3.13 의 Rule 2 참조. 기본 RFID > CC > Engine, 단 `state_applied`/`runout_in_progress` 예외.

### 1.3 이벤트 3계층 분류 (BS-06-09 §개요)

```
┌─────────────────────────────────────────────┐
│             Input Events                     │
│  CC 버튼 / RFID 감지 → 엔진에 전달          │
│  (sealed class GameEvent의 직계 멤버)        │
└──────────────────┬──────────────────────────┘
                   ↓ reduce(state, event)
┌─────────────────────────────────────────────┐
│           Internal Transitions               │
│  reducer 내부에서 조건 충족 시 자동 수행      │
│  (외부에서 dispatch하지 않음)                 │
└──────────────────┬──────────────────────────┘
                   ↓ 상태 변경 완료
┌─────────────────────────────────────────────┐
│            Output Events                     │
│  엔진 → UI/오버레이/통계 모듈에 알림         │
│  (ReduceResult.outputs 리스트)               │
└─────────────────────────────────────────────┘
```

- **Input Event**: `game_event.dart` sealed class 의 직계 멤버. `reduce(HandState, GameEvent) → ReduceResult` 의 두 번째 인자.
- **Internal Transition**: 외부에서 dispatch 하지 않음. reducer 내부에서 조건 충족 시 연쇄 수행.
- **Output Event**: `ReduceResult.outputs: List<OutputEvent>` 로 반환. UI 가 구독하여 화면 갱신, 애니메이션, 사운드를 트리거.

### 1.4 카드 파이프라인 정의 (BS-06-12)

EBS Game Engine 의 "카드 파이프라인" 은 **외부 입력 (RFID/CC) → Engine 상태 변경 → OutputEvent 발행** 의 3-stage 파이프라인이다. 두 가지 핵심 규칙:

| # | 규칙 | OutputEvent |
|---|------|-------------|
| 1 | **턴 기반 홀카드 호출**: 모든 좌석이 SETUP_HAND 에서 buffer 에 채워지지만, 각 좌석의 `ACTION_TURN` 도래 시점에만 그 좌석 카드만 release | `SeatHoleCardCalled(seat, cards)` (좌석당 1회) |
| 2 | **Atomic 3-card flop**: 1·2장 인식 시 `BoardState.FLOP_PARTIAL` PENDING (외부 미발행). 정확히 3장 충족 시점에만 1회 atomic 발행 | `FlopRevealed(c1,c2,c3)` |

**원칙**:
- 카드 호출은 **트리거 기반 (turn 또는 condition)** 이며, 시간 (timer) 으로 발행하지 않는다.
- 부분 감지 (partial detection) 는 에러가 아니다. **PENDING 상태의 정상 흐름** 이다.
- 3장 충족 (또는 timeout) 까지 외부에 어떤 보드 카드 OutputEvent 도 발행하지 않는다 (atomic flop guarantee).

### 1.5 트리거 Coalescence 정의 (BS-06-04 §정의)

**트리거 Coalescence — 병합**: 복수의 이벤트 소스가 동일 시간 창 ±100ms 내에 발생했을 때, 우선순위 규칙에 따라 하나의 유효한 상태 전이로 통합하는 프로세스. 나머지 이벤트는 **큐잉** (나중에 처리) 하거나 **폐기** (무시) 한다.

**핵심 목표**: 운영자 UI 응답성을 해치지 않으면서도 RFID 감지 데이터의 신뢰도를 최우선으로 유지한다.

**적용 범위**: 핸드 진행 중, `hand_in_progress == true` 인 복수 트리거 이벤트. 단일 트리거 또는 `IDLE` 상태는 coalescence 적용 불필요.

> **WSOP LIVE 미정의 — 독립 설계**: Coalescence 개념과 ±100ms/200ms 윈도우는 WSOP LIVE Confluence 에 대응 규정 없음. RFID 하드웨어 (12 안테나 burst 특성) 기인 EBS 고유 구현이며 **정당화된 발산** (justified divergence).

### 1.6 ReduceResult 구조 (BS-06-09 §ReduceResult)

```
ReduceResult {
  state: HandState         // 최종 상태
  outputs: List<OutputEvent>  // UI에 전달할 이벤트 목록
}
```

하나의 `reduce()` 호출이 여러 Internal Transition 을 연쇄 수행하면, 각 전이마다 해당하는 OutputEvent 가 `outputs` 에 순서대로 추가된다.

예: `reduce(state, PlayerAction(seat:3, action:fold))` → AllFoldDetected 연쇄 시:

1. `OE-02 ActionProcessed(seat:3, fold)`
2. `OE-03 PotUpdated(...)`
3. `OE-05 ActionOnChanged(seat:-1)`
4. `OE-01 StateChanged(RIVER → HAND_COMPLETE)`
5. `OE-06 WinnerDetermined(...)`
6. `OE-09 HandCompleted(...)`

#### Output Accumulation 순서

`reduce()` 는 Input Event 처리 중 발생하는 **모든 OutputEvent 를 순서대로 accumulate** 한다.

- 발행 순서 = Internal Transition 발동 순서 = OutputEvent 배열 인덱스 순서
- 예시: `PlayerAction(seat:3, action:fold)` → `[ActionProcessed, StateChanged, ActionOnChanged]` (이 순서)
- 동일 타입 OutputEvent 가 1회 reduce 에서 복수 발행될 수 있음 (예: `PotUpdated` 연속)
- Consumer (UI) 는 배열 순서대로 처리하면 최종 상태에 도달함

### 1.7 ActionType Enum (BS-06-09 §ActionType)

| 값 | 이름 | BS-06-02 정의 | amount 필수 |
|:--:|------|-------------|:-----------:|
| 0 | fold | 포기 | ❌ |
| 1 | check | 체크 | ❌ |
| 2 | bet | 첫 베팅 | ✓ |
| 3 | call | 콜 | ❌ (자동 계산) |
| 4 | raise | 레이즈 | ✓ |
| 5 | allIn | 올인 | ❌ (자동: player.stack) |

> Call 의 금액은 `biggest_bet_amt - player.current_bet` 로 자동 계산. AllIn 의 금액은 `player.stack` 으로 자동 계산. 외부에서 amount 를 넘기더라도 무시.

### 1.8 용어 사전 (4 문서 통합)

| 용어 | 출처 | 설명 |
|------|------|------|
| **sealed class** | BS-06-09 | 정해진 종류만 존재할 수 있는 프로그래밍 분류 체계 |
| **reducer** | BS-06-09 | 현재 상태와 이벤트를 받아 새로운 상태를 만드는 함수 |
| **dispatch** | BS-06-09 | 이벤트를 처리 함수에 전달하는 것 |
| **payload** | BS-06-09 | 이벤트에 딸려오는 데이터 |
| **cascade** | BS-06-09 | 하나의 이벤트가 연쇄적으로 다른 이벤트를 발생시키는 것 |
| **RFID** | BS-06-04 / BS-06-09 | 무선 주파수로 카드를 자동 인식하는 기술. 카드에 내장된 IC 를 테이블 센서가 읽는다 |
| **CC** | BS-06-04 / BS-06-09 | Command Center, 운영자가 게임을 제어하는 화면 |
| **coalescence** | BS-06-04 | 여러 센서 신호가 동시에 들어올 때 하나로 합치는 처리 규칙 |
| **FSM** | BS-06-04 | 게임 진행 단계를 정의한 상태 흐름도 (Finite State Machine) |
| **debounce** | BS-06-04 | 같은 신호의 반복 입력을 일정 시간 차단 |
| **flush** | BS-06-04 | 버퍼에 쌓인 데이터를 모두 비우기 |
| **no-op** | BS-06-04 | 아무 동작도 하지 않음 |
| **inclusive** | BS-06-04 | 경계값 포함 |
| **Atomic flop** | BS-06-12 | Flop 3장이 시청자/구독자에게 0장→3장 전환으로만 노출되는 보장. 1장/2장 중간 상태 노출 금지 |
| **PENDING** | BS-06-12 | BoardState 가 FLOP_PARTIAL 인 상태. 정상 흐름의 일부이며 에러 아님 |
| **Turn-based release** | BS-06-12 | 홀카드를 buffer 에 보관 후 각 좌석의 ACTION_TURN 진입 시점에 그 좌석 카드만 외부 발행하는 패턴 |
| **dealtSeats** | BS-06-12 | 이번 핸드에서 hole card 가 이미 release 된 좌석 집합. 재호출 가드 |
| **CardRecognitionCount** | BS-06-12 | 현재 핸드의 보드 카드 누적 인식 수. `GameState.board_card_count` 의 alias |
| **state_applied** | BS-06-04 | 서버가 상태 변경 ACK 를 반환한 시점에서 true 가 되는 플래그 |
| **runout_in_progress** | BS-06-04 | 모든 플레이어 올인 → 보드 자동 공개 진행 중 플래그 |
| **MAX_QUEUE_SIZE** | BS-06-04 | coalescence 큐 오버플로우 보호 한계, 32 |

---

## 2. State Machine / Data Flow

### 2.1 Card Pipeline Architecture (BS-06-12 §1.1)

```
                    +---------------------+
   RFID HAL ───────►|  CardIngressBuffer  |
   (CardDetected)   |  (per-antenna queue) |
                    +----------+----------+
                               │
                               ▼
                    +----------+----------+
   CC ManualInput ──►| CardCoalescer       |───┐
   (ManualCardInput) | (deduplicate +      |   │
                     |  500ms debounce)    |   │
                     +----------+----------+   │
                                │              │
                  (Hole vs Board│ classify     │
                   by antennaId)│              │
                ┌───────────────┴───────┐      │
                ▼                       ▼      │
    +---------------------+   +-----------------+
    | TurnSyncDealer      |   | FlopAggregator   |
    | (player-turn gated) |   | (3-card gated)   |
    +----------+----------+   +--------+--------+
               │                       │
               ▼                       ▼
            +--+-----------------------+--+
            |   Engine.HandFSM (reducer)  |
            |   GameState mutation        |
            +-------------+---------------+
                          │
                          ▼ (OutputEvent)
                +---------+---------+
                |  OutputEventBuffer |
                +---------+---------+
                          │
                          ▼
                  Overlay / CC / BO
```

| 컴포넌트 | 책임 | 위치 |
|---------|------|------|
| **CardIngressBuffer** | RFID antenna 별 raw card event 큐. 중복 burst 흡수 | `lib/core/cards/ingress_buffer.dart` |
| **CardCoalescer** | 500ms 윈도우 dedupe + 동일 카드 다중 인식 1회로 합성 (Coalescence.md §2 와 정렬) | `lib/core/cards/coalescer.dart` |
| **TurnSyncDealer** | `action_on` 과 동기화하여 해당 좌석의 홀카드만 release | `lib/core/cards/turn_sync_dealer.dart` |
| **FlopAggregator** | 3장 buffer. 정확히 3장 시 1회 atomic flush. 1~2장 시 PENDING 보존 | `lib/core/cards/flop_aggregator.dart` |
| **HandFSM (reducer)** | 위 컴포넌트로부터 정제된 트리거만 수신 | `lib/core/state/hand_fsm.dart` |
| **OutputEventBuffer** | OutputEvent 21종 발행 (`Overlay_Output_Events.md` §6.0) | `lib/core/output/output_event_buffer.dart` |

> **SSOT 경계**: `CardIngressBuffer` ~ `FlopAggregator` 까지가 본 도메인 소유. `HandFSM` 이후 상태 전이는 Lifecycle 도메인 마스터 권위.

### 2.2 PlayerState (좌석별, derived) (BS-06-12 §1.2.1)

| 값 | 의미 | 카드 호출 가능? |
|----|------|:---------------:|
| `WAITING` | 핸드 시작 전 또는 다른 플레이어 차례 | ❌ |
| `ACTION_TURN` | `action_on == this.seat`. 카드 호출 활성화 | ✅ (이번 턴 1회) |
| `ACTED` | 이번 라운드 액션 완료 (Check/Bet/Call/Raise 등) | ❌ (재호출 금지) |
| `FOLDED` | 폴드 완료. 카드 muck 상태 | ❌ |
| `ALL_IN` | 올인 후 후속 라운드 자동 통과 | ❌ |
| `SITTING_OUT` | 핸드 비참여 | ❌ |

> **유도 관계**: `PlayerState` 는 별도 필드가 아니라 `seat.status` + `action_on` + `seat.bet` + `seat.folded` 로부터 derive 한다 (`BS_Overview.md` §3 GameState). PlayerStatus enum (active/folded/allin/eliminated/sitting_out) 의 권위는 Lifecycle 도메인 마스터 §2.4.

### 2.3 BoardState (테이블당 1개) (BS-06-12 §1.2.2)

```
       NEW_HAND
          │ (StartHand)
          ▼
      AWAITING_FLOP
          │ (CardRecognitionCount = 0)
          │
          │ ◄────── card_recognized (count = 1)
          ▼
      FLOP_PARTIAL
          │ (CardRecognitionCount ∈ {1, 2})
          │
          │ ◄────── card_recognized (count = 3)
          ▼
      FLOP_READY ──► (1회 flush) ──► FLOP_DONE
          │
          │
          ▼
      AWAITING_TURN ──► TURN_DONE ──► AWAITING_RIVER ──► RIVER_DONE
```

| `BoardState` | `CardRecognitionCount` | 외부 발행? | 다음 트리거 |
|--------------|:----------------------:|:----------:|------------|
| `AWAITING_FLOP` | 0 | — | RFID `CardDetected` (board antenna) |
| `FLOP_PARTIAL` | 1, 2 | **❌ (held)** | 추가 `CardDetected` 또는 timeout |
| `FLOP_READY` | 3 | ✅ `FlopRevealed` (1회) | reducer flush 후 `FLOP_DONE` |
| `FLOP_DONE` | 3 | — | betting 완료 시 `AWAITING_TURN` |
| `AWAITING_TURN` | 3 | — | RFID `CardDetected` (4번째) |
| `TURN_DONE` | 4 | ✅ `TurnRevealed` | — |
| `AWAITING_RIVER` | 4 | — | RFID `CardDetected` (5번째) |
| `RIVER_DONE` | 5 | ✅ `RiverRevealed` | showdown 진입 |

### 2.4 핵심 카운터 / 필드 (BS-06-12 §1.2.3)

| 필드 | 타입 | 위치 | 설명 |
|------|------|------|------|
| `CardRecognitionCount` | int (0~5) | `GameState.board_card_count` | 현재 핸드에서 RFID/Manual 로 인식된 보드 카드 누적 수. HAND_COMPLETE 시 0 reset |
| `flop_buffer` | `List<Card>` (max 3) | `FlopAggregator.buffer` | 부분 감지 누적. 3 충족 시 atomic flush |
| `flop_pending_since` | `DateTime?` | `FlopAggregator.pending_since` | 첫 부분 감지 시각 (timeout 계산용) |
| `flop_timeout_sec` | int (default 30) | config | partial → manual fallback escalation 임계 |
| `turn_dealt_seats` | `Set<int>` | `TurnSyncDealer.dealt_seats` | 이번 핸드에서 홀카드 호출이 이미 release 된 좌석 (재호출 방지) |

### 2.5 Coalescence 적용 조건 (BS-06-04 §적용 조건)

#### 전제조건

다음 모든 조건이 참일 때만 coalescence 규칙 적용:

1. `hand_in_progress == true` — 핸드 진행 중
2. 2개 이상의 서로 다른 소스 트리거 발생
3. 시간 윈도우 ±100ms 내에 도착
4. 게임 상태가 유효한 다음 액션 허용

#### 비활성 조건

1. `hand_in_progress == false` — 테이블 IDLE
2. RFID 에러 모드 활성 — 수동 입력 모드 실행 중
3. HAND_COMPLETE 상태 — 모든 새 입력 거부
4. 모달 다이얼로그 활성 — RFID 감지 대기, CC 입력 모두 금지
5. 단일 트리거만 발생 — 충돌 없음, 즉시 처리

### 2.6 상태별 Coalescence 활성 매트릭스 (BS-06-04 §상태별 활성 매트릭스)

| 상태 | 허용 입력 | 예상 RFID | 버퍼 동작 |
|------|---------|----------|----------|
| **IDLE** `coalescence_active` = false | NEW HAND | 없음, 버퍼 저장 | RFID 버퍼 저장, 다음 핸드 시 처리 |
| **SETUP_HAND** `coalescence_active` = true | DEAL | Hole card | 표준 100ms |
| **PRE_FLOP**~**RIVER** `coalescence_active` = true | FOLD, CHECK, BET, RAISE, CALL, ALL-IN | Board card | 표준 100ms — Engine 자동: 베팅 완료 → 다음 스트리트 |
| **SHOWDOWN** `coalescence_active` = true | SHOWDOWN | 없음 | 표준 100ms — Engine 자동: 핸드 평가 → HAND_COMPLETE |
| **HAND_COMPLETE** `coalescence_active` = false | NEW HAND | 없음, 폐기 | RFID 버퍼 flush |

> 이 매트릭스에 없는 조합은 해당 상태에 존재하지 않으므로 이벤트 수신 시 **STATE_CONFLICT** 에러를 발생시킨다.

### 2.7 Mock 모드 이벤트 합성 (BS-06-00-triggers §4)

#### 2.7.1 기본 원칙

Mock HAL (`MockRfidReader`) 은 CC UI 의 수동 입력을 받아 **Real HAL 과 동일한 이벤트 스트림** 을 생성한다.

```
[운영자] → CC 수동 카드 입력 (suit, rank)
    → MockRfidReader.injectCard(suit, rank)
    → Stream<RfidEvent> emit: CardDetected(
        antennaId: 0,           // Mock 고정값
        cardUid: generated,      // "MOCK-{suit}{rank}" 형식
        suit: suit,
        rank: rank,
        timestamp: DateTime.now(),
        confidence: 1.0          // Mock은 항상 100%
      )
    → Game Engine 수신 (Real과 동일 처리)
```

#### 2.7.2 이벤트별 합성 규칙

| Real 이벤트 | Mock 합성 방법 | 차이점 |
|------------|--------------|--------|
| `CardDetected` | CC 수동 카드 선택 → `injectCard()` | antennaId=0, uid="MOCK-XX", confidence=1.0 |
| `CardRemoved` | Mock 에서 미지원 | 테스트 필요 시 `injectRemoval()` API 사용 |
| `DeckRegistered` | "자동 등록" 버튼 → 52장 가상 매핑 즉시 생성 | 스캔 시간 0ms, 진행률 100% 즉시 |
| `DeckRegistrationProgress` | "자동 등록" 시 1회 100% 이벤트 | Real 은 1장씩 52회 이벤트 |
| `AntennaStatusChanged` | Mock 초기화 시 1회 `CONNECTED` | antenna 1개만 가상 존재 |
| `ReaderError` | `injectError(errorCode)` API | 테스트/데모용 에러 주입 |

#### 2.7.3 시나리오 스크립트 재생 (E2E 테스트용)

Mock HAL 은 **YAML 시나리오 파일** 을 로드하여 사전 정의된 이벤트 시퀀스를 재생할 수 있다.

```yaml
# scenarios/holdem-basic.yaml
scenario: "Basic Hold'em Hand"
events:
  - type: DeckRegistered
    delay_ms: 0
  - type: CardDetected
    delay_ms: 100
    payload: { seat: 0, suit: 3, rank: 12 }  # As (플레이어 1 홀카드 1)
  - type: CardDetected
    delay_ms: 100
    payload: { seat: 0, suit: 2, rank: 11 }  # Kh (플레이어 1 홀카드 2)
  # ... 계속
```

> **시나리오 파일 상세**: `docs/testing/TEST-04-mock-data.md`

---

<!-- CHUNK-2: §3 Trigger & Action Matrix (다음 turn 작성) -->

<!-- CHUNK-3: §4 Exceptions + §5 Data Models + Appendix A/B/C (그 다음 turn) -->
