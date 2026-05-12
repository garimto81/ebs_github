---
title: Lifecycle & State Machine — Domain Master
owner: team3
tier: contract
legacy-ids:
  - BS-06-01    # Holdem/Lifecycle.md (Hold'em 핸드 라이프사이클)
  - BS-06-10    # Action_Rotation.md (액션 순환 알고리즘)
  - BS-06-00-REF  # Overview.md (lifecycle 관련 enum/data model 발췌)
last-updated: 2026-05-08
last-synced: 2026-05-08  # Foundation v4.5 §10 정합 (S8 audit 2026-05-08, D1)
related:
  - "Behavioral_Specs/Card_Pipeline_Overview.md"   # BS-06-12 (board card detection authority)
  - "Behavioral_Specs/Triggers.md"                  # `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: BS-06-00-triggers))) (event 트리거 SSOT)
  - "Behavioral_Specs/Holdem/Coalescence.md"        # RFID burst 처리
confluence-page-id: 3819274769
confluence-parent-id: 3811836049
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819274769/EBS+Lifecycle+State+Machine+Domain+Master
---

# Lifecycle & State Machine — Domain Master

> **존재 이유**: Hold'em FSM 상태 전이, 액션 순환 알고리즘, 그리고 이 둘의 기반이 되는 enum / data model 을 단일 SSOT 로 통합한다. 본 문서는 BS-06-01 (Lifecycle) + BS-06-10 (Action_Rotation) + BS-06-00-REF (Overview lifecycle 발췌) 를 zero information loss 로 병합한 결과이며, 보드 카드 감지 로직은 BS-06-12 (Card_Pipeline_Overview.md) 가 권위 — 본 문서 §3.5 매트릭스 3 은 그 결과의 HandFSM 측 시각이다.

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-06 | BS-06-01 신규 | 핸드 라이프사이클 FSM 정의 (3가지 game_class × 9-12 상태 × 20+ 유저 스토리) |
| 2026-04-06 | BS-06-01 Hold'em 전용 변환 | Draw/Stud 계열 제거, Flop CC FSM 만 유지, Bomb Pot 상태 전이 변형 흡수 |
| 2026-04-07 | BS-06-01 doc-critic 적용 | 다이어그램 앞으로 이동, 용어 설명 추가, 영향 요소 축소 |
| 2026-04-08 | BS-06-10 신규 | next_active_player, first_to_act, 라운드 완료 판정 pseudocode 정의 |
| 2026-04-09 | BS-06-10 GAP-GE-001 보강 | "active = SeatStatus.active만 (allIn 제외)" 명시, 1 active + N allIn 분기 추가 |
| 2026-04-10 | BS-06-01 WSOP 규정 반영 | §Bomb Pot 기본값에 Rule 28.3.1 권장값 추가, §Run It Multiple vs Rabbit Hunting 신설 (Rule 81 금지) |
| 2026-04-10 | BS-06-01 WSOP P1 반영 | §Bomb Pot Button Freeze & Opt-Out 신설 (Rule 28.3.2) |
| 2026-04-13 | BS-06-10 GAP-D 보강 | Edge Case TC 3건 추가 (Dead Button, 4인 All-in, Straddle+BB Option) |
| 2026-04-15 | BS-06-01/10 last-updated | (변경 이력 기록) |
| 2026-04-27 | 도메인 통합 (본 문서) | BS-06-01 + BS-06-10 + BS-06-00-REF lifecycle 발췌를 Lossless 병합. legacy-ids 보존. BS-06-12 cross-ref 으로 보드 감지 권위 위임 |
| 2026-05-07 | v3/v4 정체성 cascade Phase B2 | Lobby v3.0.0 + CC_PRD v4.0 정체성 정합 (LLM 전수 의미 판정 — Engine). §3.1 "CC 버튼" → "CC 입력 (6 키 N·F·C·B·A·M)" framing. 8 논리 액션 ↔ 6 키 매핑 명시. CC v4.0 §1.2 "8 분리 버튼 시대 종료" 정합. HandFSM 9-state 는 CC v4.0 5-Act UI 인지 layer 와 별개 (CC_PRD §"5-Act"). | DOC |
| 2026-05-08 | D1 [CRITICAL] HORSE 5종 정합 | §5.13 `mixed_game_sequence` 예시: HORSE=[O8, Razz, Stud, Stud8, NLH, PLO] 6종 → [Hold'em, O8, Razz, Stud, Stud8] 5종 FL. Foundation §10 위반 정정 (NLH/PLO 잘못 포함, Hold'em 누락). (S8 consistency audit 2026-05-08) | DOC |

---

## 1. Overview & Definitions

### 1.1 도메인 정의

게임 엔진의 **핸드 라이프사이클**은 **IDLE 에서 시작하여 HAND_COMPLETE 로 끝나는 유한 상태 머신** 이다. 한 핸드는 다음 시퀀스로 진행된다:

```
IDLE → SETUP_HAND → PRE_FLOP → FLOP → TURN → RIVER → SHOWDOWN → HAND_COMPLETE
```

**핸드 라이프사이클** = 하나의 포커 핸드가 딜 시작(SETUP_HAND) 부터 우승자 결정(HAND_COMPLETE) 까지 거치는 일련의 상태 변화를 추적하는 **프로세스이자 상태 머신**.

**핵심 원칙**:
- 한 핸드는 반드시 IDLE 에서 시작하고 HAND_COMPLETE 에서 끝남.
- 각 상태는 `hand_in_progress`, `action_on`, 보드 카드 수, 최종 베팅 라운드 플래그로 고유하게 정의됨.
- 상태 전이는 반드시 "현재 상태 + 트리거" 조합으로만 발생, 임의 전이 금지.

유한 상태 머신이란 정해진 상태들 사이를 규칙에 따라 이동하는 구조다. 신호등이 빨강→노랑→초록으로 바뀌는 것처럼, Hold'em 핸드는 IDLE → PRE_FLOP → FLOP → TURN → RIVER → SHOWDOWN 순서로 진행된다.

### 1.2 액션 순환 정의

베팅 라운드에서 "다음 플레이어는 누구인가" 와 "라운드는 언제 끝나는가" 를 결정하는 알고리즘이다. 본 문서는 다음 **3 핵심 함수**를 정의한다 (§5 Data Models):

1. `determine_first_to_act(phase, config)` — 스트리트 시작 시 첫 액션 플레이어 결정
2. `next_active_player(current, players)` — 다음 액션 플레이어 결정
3. `is_betting_round_complete(state)` — 현재 라운드 종료 여부 판정

### 1.3 상태 의미

| 상태 | hand_in_progress | 의미 |
|------|:----------------:|------|
| **IDLE** | false | 핸드 진행 중 아님 |
| **SETUP_HAND** | true | 핸드 진행 중 (블라인드 수납 + 카드 딜 단계) |
| **PRE_FLOP / FLOP / TURN / RIVER** | true | 핸드 진행 중 (베팅 라운드별) |
| **SHOWDOWN** | true | 핸드 진행 중 (카드 공개 + 평가) |
| **RUN_IT_MULTIPLE** | true | 핸드 진행 중 (런잇 다중 보드) |
| **HAND_COMPLETE** | false | 핸드 진행 중 아님 (다음 IDLE 까지 임시 안정 상태) |

### 1.4 포지션 정의

좌석 배치에서 딜러 기준 시계방향 순서. 딜러 왼쪽부터 SB, BB, UTG, ...

| 포지션 약어 | 의미 | 딜러 기준 위치 |
|-----------|------|-------------|
| **BTN** | Button (Dealer) | 딜러 자신 |
| **SB** | Small Blind | 딜러 +1 |
| **BB** | Big Blind | 딜러 +2 |
| **UTG** | Under the Gun | 딜러 +3 |
| **HJ** | Hijack | BTN -2 |
| **CO** | Cutoff | BTN -1 |

> 좌석 수에 따라 중간 포지션은 가변. 핵심은 SB / BB / UTG / BTN 의 상대적 위치.

### 1.5 액션 가능 상태

`player.status == active` (not folded, not allIn, not sittingOut, not busted)

### 1.6 용어 사전

| 용어 | 설명 |
|------|------|
| **Straddle** | UTG 플레이어가 자발적으로 BB 의 2배를 미리 내는 추가 블라인드 |
| **Dead Button** | 이전 핸드의 딜러가 자리를 떠나 딜러 좌석이 비어있는 상황 |
| **NL / PL / FL** | No Limit / Pot Limit / Fixed Limit 베팅 구조 |
| **Pseudocode** | 실제 프로그래밍 언어가 아닌 참고용 가상 코드 |
| **런아웃 (Runout)** | 모든 플레이어 올인 후 남은 보드 카드를 자동 공개하는 절차 |
| **Run It Multiple (RIM)** | 올인 상황에서 보드를 여러 번 전개하여 팟을 분할하는 방식 |
| **Dead money** | 폴드한 플레이어가 팟에 남긴 금액 |
| **card_verify_mode** | 카드 검증 모드 |
| **undo_stack** | UNDO 이력 스택 |
| **card_rescan** | 카드 재스캔 필요 플래그 |

---

## 2. State Machine / Data Flow

### 2.1 Hold'em FSM 상태 흐름 다이어그램

```
                    ┌─ IDLE ─┐
                    │         │
              (app start or  (StartHand)
               prev complete) │
                    │         ├─→ SETUP_HAND
                    │         │    (blinds posted,
                    │         │     hole cards dealt)
                    │         │    │
                    │         └────┴─→ PRE_FLOP
                    │                (action_on = first_to_act)
                    │                │
                    │        (betting complete
                    │         or all fold)
                    │                │
                    ├─────────────────┤
                    │                 ├─→ FLOP (board=3)
                    │                 │   │
                    │        (betting complete
                    │         or all fold)
                    │                 │
                    ├─────────────────┤
                    │                 ├─→ TURN (board=4)
                    │                 │   │
                    │        (betting complete
                    │         or all fold)
                    │                 │
                    ├─────────────────┤
                    │                 ├─→ RIVER (board=5)
                    │                 │   │ (final_betting_round=true)
                    │                 │   │
                    │        (betting complete
                    │         or all fold)
                    │                 │
                    ├─────────────────┼─→ SHOWDOWN
                    │                 │   (hand eval)
                    │                 │   │
                    │                 │   ├─(run_it_times>0)
                    │                 │   │  └─→ RUN_IT_MULTIPLE
                    │                 │   │      (run[n])
                    │                 │   │      │
                    │                 │   └─────┘
                    │                 │   │
                    │                 │ (winner)
                    │                 │   │
                    └──────────────────────→ HAND_COMPLETE
                                      (payout, stats update)
                                      │
                          (ManualNextHand or
                           overrideButton)
                                      │
                                      └─→ IDLE
```

### 2.2 game_phase Enum (BS-06-00-REF §1.9)

`game_phase` 필드에 저장되는 값. 게임 진행 단계.

| 값 | 이름 | 설명 |
|:--:|------|------|
| 0 | **IDLE** | 대기 |
| 1 | **SETUP_HAND** | 핸드 준비 |
| 2 | **PRE_FLOP** | 프리플롭 베팅 |
| 3 | **FLOP** | 플롭 공개 + 베팅 |
| 4 | **TURN** | 턴 공개 + 베팅 |
| 5 | **RIVER** | 리버 공개 + 베팅 |
| 6 | **SHOWDOWN** | 카드 공개, 승패 결정 |
| 7 | **HAND_COMPLETE** | 핸드 종료 |
| 17 | **RUN_IT_MULTIPLE** | 런잇타임 진행 |

> Draw 게임 페이즈 8~11, Stud 게임 페이즈 12~16 은 Tier 3~4 문서에서 정의한다.

### 2.3 BoardRevealStage Enum (BS-06-00-REF §1.4.5)

보드 공개 진행 단계. Flop games 에서 현재 보드 상태 추적.

| 값 | 이름 | 상태 | board_cards[0] |
|:--:|------|------|:-------:|
| 0 | None | 초기 상태 (카드 없음) | undefined |
| 1 | Flop | 플롭 공개 (3장) | 3 |
| 2 | Turn | 턴 공개 (4장) | 4 |
| 3 | River | 리버 공개 (5장) | 5 |

> **권위 위임**: BS-06-12 §1.2.2 에서 정의한 `BoardState` (AWAITING_FLOP / FLOP_PARTIAL / FLOP_READY / FLOP_DONE / AWAITING_TURN / TURN_DONE / AWAITING_RIVER / RIVER_DONE) 가 detection logic 의 SSOT 이며, 본 enum 은 그 결과의 boardCards 배열 길이 derived view 다.

### 2.4 PlayerStatus Enum (BS-06-00-REF §1.5.2)

플레이어 게임 중 상태.

| 값 | 이름 | 의미 | 전환 조건 |
|:--:|------|------|----------|
| 0 | **active** | 활성, 액션 가능 | 핸드 시작, 폴드 해제 |
| 1 | **folded** | 폴드됨, 해당 핸드 제외 | FOLD 액션 후 |
| 2 | **allin** | 올인, 스택 0, 쇼다운 진행 | BET / CALL 로 스택 전부 소진 |
| 3 | **eliminated** | 탈락, 토너먼트 | 스택 0 + 재입금 불가 |
| 4 | **sitting_out** | 관전, 현재 핸드 불참 | 플레이어 관전 모드 전환 |

### 2.5 game Enum (BS-06-00-REF §1.1)

`game` enum 으로 게임 종류를 식별한다.

| 값 | 이름 | 계열 | 특수 규칙 |
|:--:|------|:--:|----------|
| 0 | holdem | flop | 표준 홀덤 |

> `game` 1~21 은 확장 게임이며 Tier 2~4 문서에서 정의한다. game enum 값 0이 Hold'em 이다.

### 2.6 event_game_type Enum (BS-06-00-REF §1.2.4)

WSOP LIVE 이벤트에서 게임 계열을 지정하는 상위 분류. EBS의 `game` enum (0-21) 이 세부 변형이라면, `event_game_type` 은 이벤트 등록 시 사용하는 대분류다.

| 값 | 이름 | EBS `game` enum 매핑 |
|:--:|------|---------------------|
| 0 | Holdem | 0, 1, 2, 3 |
| 1 | Omaha | 4, 5, 6, 7, 8, 9, 10, 11 |
| 2 | Stud | 19, 20 |
| 3 | Razz | 21 |
| 4 | Lowball | 13, 14, 15 |
| 5 | HORSE | Mixed 순환 |
| 6 | DealerChoice | 임의 선택 |
| 7 | Mixed | 복합 게임 |
| 8 | Badugi | 16, 17, 18 |

### 2.7 GamePhase → Street 매핑 (BS-06-00-REF §7.4)

GameSession 의 `Street` getter 가 `activeHand.phase` 로부터 파생되는 매핑.

| GamePhase | Street | 비고 |
|-----------|--------|------|
| IDLE, SETUP_HAND | null (live 아님) | street getter 미사용 |
| PRE_FLOP | preflop | |
| FLOP | flop | |
| TURN | turn | |
| RIVER | river | |
| SHOWDOWN, RUN_IT_MULTIPLE, HAND_COMPLETE | showdown | UI 축약 |

---

## 3. Trigger & Action Matrix

### 3.1 트리거 소스 (BS-06-01 §트리거)

3가지 입력 장치가 게임 상태를 변경한다:
- **CC 입력** — Command Center, 운영자가 게임을 조작하는 화면. CC v4.0 입력 표면 = **6 키 (N·F·C·B·A·M)** + Phase-aware (`Command_Center.md` v4.0 Ch.5)
- **RFID** — 카드에 내장된 무선 칩을 자동으로 읽는 장치
- **게임 엔진** — 조건 충족 시 자동으로 다음 상태로 전이하는 시스템

| 소스 | 발동 주체 | 처리 시간 | 신뢰도 |
|------|---------|---------|--------|
| **CC 입력** | 운영자 (수동, 6 키 + Phase-aware) | 즉시 (<50ms) | 낮음 |
| **RFID 감지** | 시스템 (자동) | 변동 (50~150ms) | 높음 |
| **게임 엔진 자동** | 게임 엔진 (자동) | 결정론적 | 최고 |

> **CC 입력 — 8 논리 액션 ↔ 6 키 매핑** (CC v4.0 정합, 2026-05-07): 게임 엔진이 인지하는 8 논리 액션 (NEW HAND, DEAL, CHECK, BET, FOLD, CALL, RAISE, ALL-IN) 은 v4.0 운영자 화면에서 **6 키** 로 발사된다. N=NEW HAND, F=FOLD, C=CHECK/CALL (동적), B=BET/RAISE (동적), A=ALL-IN, M=MUCK + Ctrl+Z=UNDO. DEAL 은 RFID 자동 감지에 흡수. 즉 **이전 8 분리 버튼 시대가 끝나고 6 키 시대가 시작** — `Command_Center.md` v4.0 §1.2.
>
> RFID 예시 — 홀카드 감지, 보드 카드 감지, 카드 갱신. 게임 엔진 예시 — 베팅 완료 → 다음 라운드 공개, 올인 → 런아웃, 쇼다운 진행.

### 3.2 상태별 진입 트리거 요약

| 상태 | 진입 트리거 | 발동 조건 |
|------|-----------|---------|
| IDLE | 앱 시작 OR 이전 핸드 HAND_COMPLETE | 초기 상태 또는 cycle |
| SETUP_HAND | SendStartHand() | 모든 precondition 충족 |
| PRE_FLOP | 홀카드 완전 딜 완료 | 게임 엔진 자동 |
| FLOP | 베팅 완료 + Flop 버튼 또는 자동 진행 | 최종 베팅액 동일 |
| TURN | 보드 4번째 카드 감지 | 게임 엔진 감지 |
| RIVER | 보드 5번째 카드 감지 | 게임 엔진 감지 |
| SHOWDOWN | 최종 베팅 라운드 완료 + 2+ 플레이어 | 게임 엔진 자동 진행 |
| RUN_IT_MULTIPLE | run_it_times > 0 (SHOWDOWN 진행 중) | 플레이어 동의 후 게임 엔진 자동 |
| HAND_COMPLETE | 우승자 결정 또는 모든 플레이어 폴드 | 팟 분배 완료 |

### 3.3 매트릭스 1: Hold'em 상태 상세 (BS-06-01 §매트릭스 1)

| 상태 | hand_in_progress | action_on | board_cards 수 | final_betting_round |
|------|:--------:|:-----:|:--------:|:--------:|
| **IDLE** | false | -1 | 0 | false |
| **SETUP_HAND** | true | -1 | 0 | false |
| **PRE_FLOP** | true | first_to_act | 0 | false |
| **FLOP** | true | first_to_act | 3 | false |
| **TURN** | true | first_to_act | 4 | false |
| **RIVER** | true | first_to_act | 5 | **true** |
| **SHOWDOWN** | true | -1 | 5 | true |
| **RUN_IT_MULTIPLE** | true | -1 | varies | true |
| **HAND_COMPLETE** | false | -1 | varies | true |

### 3.4 매트릭스 2: 상태별 Entry/Exit 조건 (BS-06-01 §매트릭스 2)

| 상태 | Entry 조건 | Exit 조건 | 다음 상태(들) |
|------|-----------|-----------|-------------|
| **IDLE** | 앱 시작 또는 HAND_COMPLETE | StartHand() called | SETUP_HAND |
| **SETUP_HAND** | SendStartHand() 응답 | blinds posted + hole cards dealt | PRE_FLOP |
| **PRE_FLOP** | hole cards dealt | 베팅 완료 또는 all fold | FLOP 또는 HAND_COMPLETE 또는 SHOWDOWN |
| **FLOP** | 베팅 완료 후 3번째 board card detected | 베팅 완료 또는 all fold | TURN 또는 HAND_COMPLETE 또는 SHOWDOWN |
| **TURN** | 4번째 board card detected | 베팅 완료 또는 all fold | RIVER 또는 HAND_COMPLETE 또는 SHOWDOWN |
| **RIVER** | 5번째 board card detected | 베팅 완료 또는 all fold | SHOWDOWN 또는 HAND_COMPLETE |
| **SHOWDOWN** | 최종 베팅 완료 + 2+ players | 우승자 결정 또는 run_it 선택 | HAND_COMPLETE 또는 RUN_IT_MULTIPLE |
| **RUN_IT_MULTIPLE** | run_it_times > 0 (SHOWDOWN 중) | 남은 런 = 0 | HAND_COMPLETE |
| **HAND_COMPLETE** | 우승자 결정 또는 모두 폴드 | ManualNextHand() 또는 overrideButton=true | IDLE |

### 3.5 매트릭스 3: 보드 카드 수 기반 상태 전이 (BS-06-01 §매트릭스 3)

> **SSOT**: 보드 카드 감지 로직은 `Behavioral_Specs/Card_Pipeline_Overview.md` (BS-06-12) §3 권위. 본 매트릭스는 그 결과의 HandFSM 측 시각이다. 충돌 시 BS-06-12 우선.

| 현재 상태 | board_cards 감지 | BoardState | 가능한 전이 | 조건 |
|---------|:--------:|------------|-----------|------|
| PRE_FLOP (0장) | 0장 감지 | AWAITING_FLOP | 변화 없음 | 정상 (카드 미감지) |
| PRE_FLOP (0장) | 1장 감지 | FLOP_PARTIAL | **변화 없음 (PENDING, 외부 미발행)** | 부분 감지 — 추가 카드 대기 (BS-06-12 §3.5) |
| PRE_FLOP (0장) | 2장 감지 | FLOP_PARTIAL | **변화 없음 (PENDING, 외부 미발행)** | 부분 감지 — 추가 카드 대기 (BS-06-12 §3.5) |
| PRE_FLOP (0장) | 3장 감지 | FLOP_READY → FLOP_DONE | → FLOP (atomic) | 정상 Flop 카드 감지. `FlopRevealed` 1회 발행 |
| FLOP_PARTIAL (count<3) | timeout (default 30s) | FLOP_PARTIAL (유지) | 변화 없음 | `FlopPartialAlert` (운영자 배지). 미스딜 또는 수동 입력 대기 |
| FLOP (3장) | +1장 감지 | TURN_DONE | → TURN | 정상 Turn 카드 감지 (atomic 1장) |
| TURN (4장) | +1장 감지 | RIVER_DONE | → RIVER | 정상 River 카드 감지 (atomic 1장) |
| RIVER (5장) | no change | RIVER_DONE | 변화 없음 | 정상 (카드 완성) |

### 3.6 매트릭스 4: 특수 상황별 상태 전이 오버라이드 (BS-06-01 §매트릭스 4)

| 특수 상황 | 조건 | 정상 경로 | 오버라이드 경로 |
|---------|------|---------|-------------|
| **All Fold** | 1명 남음 | 다음 라운드 → SHOWDOWN | → HAND_COMPLETE (즉시) |
| **All-in + board 불완성** | all-in at FLOP, board<5 | → TURN/RIVER | → SHOWDOWN (runout 자동) |
| **Bomb Pot** | bomb_pot > 0, state=SETUP | SETUP→PRE_FLOP | SETUP→FLOP 직행 (PRE_FLOP 스킵) |
| **Run It Twice** | run_it_times=2, SHOWDOWN | → HAND_COMPLETE | → RUN_IT_MULTIPLE → HAND_COMPLETE |
| **Miss Deal** | 카드 불일치 감지 | (current) | → IDLE (blinds/stacks 복구) |
| **UNDO (5단계)** | undo_depth <= 5 | (current) | 이전 상태 복원 |
| **Player Sit Out** | player.status='sitting_out' | (normal action) | 자동 폴드, action_on 다음 |

### 3.7 매트릭스 5: first_to_act 결정 (BS-06-10 §매트릭스 1)

| phase | num_players | straddle | 결과 |
|:-----:|:-----------:|:--------:|------|
| PRE_FLOP | 2 (heads-up) | ❌ | Dealer(SB) |
| PRE_FLOP | 2 (heads-up) | ✓ | Straddle 다음 |
| PRE_FLOP | 3~10 | ❌ | BB 다음 (UTG) |
| PRE_FLOP | 3~10 | ✓ | Straddle 다음 |
| FLOP / TURN / RIVER | 2 (heads-up) | — | BB |
| FLOP / TURN / RIVER | 3~10 | — | SB (또는 SB 이후 첫 active) |
| SHOWDOWN | any | — | -1 (액션 없음) |

### 3.8 매트릭스 6: 라운드 완료 조건 (BS-06-10 §매트릭스 2)

| active 수 | biggest_bet | all_acted | 판정 |
|:---------:|:----------:|:---------:|------|
| 0 | any | — | ✓ complete (→ SHOWDOWN) |
| 1 | any | — | ✓ complete (→ HAND_COMPLETE) |
| 2+ | X | false | ❌ not complete |
| 2+ | X | true, 전원 current_bet == X | ✓ complete |
| 2+ | X | true, 일부 current_bet < X | ❌ not complete |

### 3.9 매트릭스 7: Mix Type 별 Rotation 규칙 (BS-06-00-REF §1.2.4)

**원칙**: Mixed 토너먼트 (HORSE, 8-Game, Mixed Omaha 등) 에서 게임 전환은 **레벨 종료 시** 에만 발생하며, 전환 핸드 동안 button 은 freeze 된다. WSOP LIVE Confluence "New Blind Type: Mixed Omaha" 문서 + Rule 287-288 (Stud 테이블 균형 포함) 근거.

| Mix Type | Rotation 단위 | Button 이동 | Bet Structure 전환 | 참조 규정 |
|----------|--------------|:----------:|-------------------|----------|
| HORSE | 레벨 종료 시 전환 | **전환 핸드 freeze** | Limit 유지 (BB stud 포함) | Rule 287-288 |
| 8-Game | 레벨 종료 시 전환 | **전환 핸드 freeze** | 게임별 상이 (NL, PL, FL 혼합) | Rule 287-288 |
| Mixed Omaha (NEW) | 레벨 종료 시 전환 | **전환 핸드 freeze** | PLO ↔ Limit 교대 | New Blind Type: Mixed Omaha |
| Dealer's Choice | 매 핸드 딜러 선택 | 평소대로 이동 | 게임별 상이 | WSOP 별도 규정 |
| PPC (Player Pick) | 매 핸드 플레이어 선택 | 평소대로 이동 | 게임별 상이 | 비표준 |

### 3.10 next_active_player 스킵 조건 (BS-06-10 §알고리즘 2)

| player.status | 스킵 여부 | 이유 |
|:---:|:---:|------|
| **active** | ❌ (액션 대상) | 액션 가능 |
| **folded** | ✓ (스킵) | 이미 포기 |
| **allIn** | ✓ (스킵) | 추가 액션 불가 |
| **sittingOut** | ✓ (스킵) | 자리 비움, 자동 폴드 처리 |
| **busted** | ✓ (스킵) | 토너먼트 탈락 |

### 3.11 라운드 완료 경계 케이스 (BS-06-10 §경계 케이스)

| 상황 | 판정 | 이유 |
|------|:---:|------|
| PRE_FLOP, BB 만 남음 (나머지 폴드) | `true` → HAND_COMPLETE | active == 1 |
| PRE_FLOP, 리프 없이 BB 체크 | `true` → FLOP 대기 | biggest_bet == BB, BB.current_bet == BB, 순환 완료 |
| 레이즈 발생 후 | `false` | 레이즈 이후 모든 active 가 다시 액션해야 함 |
| 전원 올인 (active == 0) | `true` → SHOWDOWN | 베팅 불가, 보드 자동 공개 |
| 1 active + N allIn, active 미액션 | `false` | active 플레이어에게 call/fold 기회 부여 |
| 1 active + N allIn, active 액션 완료 | `true` | active 가 액션 + 금액 매칭 완료 |
| BB check option 후 레이즈 | `false` | BB 가 체크했어도 누군가 레이즈하면 BB 재액션 필요 |

### 3.12 영향 받는 요소 (BS-06-01 §영향 받는 요소)

| 요소 | 상태 전이 시 영향 |
|------|-----------------|
| CC 버튼 | 상태별 활성 / 비활성 버튼 변경 |
| RFID 감지 | 카드 감지 대상 변경 |
| 오버레이 | 화면 표시 요소 변경 |
| 통계 | 핸드 종료 시 플레이어 통계 업데이트 |
| 팟 관리 | 베팅 라운드별 팟 금액 누적 |
| 게임 저장 | 상태 전이마다 핸드 기록 저장 |

### 3.13 Lifecycle 유저 스토리 (BS-06-01 §유저 스토리)

| # | As a | When | Then |
|:-:|------|------|------|
| 1 | 운영자 | 앱 시작 | 상태 = IDLE, hand_in_progress=false |
| 2 | 운영자 | NEW HAND 버튼 클릭 + precondition 충족 | 상태 = SETUP_HAND, blinds 자동 수납, 카드 딜 시작 |
| 3 | 시스템 | 모든 플레이어 홀카드 딜 완료 | 상태 = PRE_FLOP |
| 4 | 운영자 | PRE_FLOP 에서 CHECK / BET / CALL / RAISE / FOLD 액션 | action_on 다음 플레이어로 순환, biggest_bet_amt 갱신 |
| 5 | 운영자 | PRE_FLOP 베팅 완료 (모든 액션 동일) | 상태 = FLOP, 보드 3장 공개 대기 |
| 6 | 시스템 | RFID 가 보드 카드 3장 감지 또는 운영자가 board_cards 수동 입력 | board_cards 배열 갱신, 오버레이 보드 업데이트 |
| 7 | 운영자 | PRE_FLOP 에서 전원 폴드 (1명 제외) | 상태 = HAND_COMPLETE, 우승자 결정 |
| 8 | 운영자 | FLOP 에서 all-in 발생, 보드 완성 불가능 | 상태 = SHOWDOWN, 남은 보드 자동 런아웃 |
| 9 | 운영자 | RIVER 베팅 완료, 2+ 플레이어 남음 | 상태 = SHOWDOWN, 핸드 평가 시작 |
| 10 | 운영자 | SHOWDOWN 에서 우승자 1명 확정 | 상태 = HAND_COMPLETE, 팟 분배, 통계 업데이트 |
| 11 | 운영자 | SHOWDOWN 에서 run_it_times=2 적용, 첫 런 완료 | 상태 = RUN_IT_MULTIPLE, run_it_times_remaining=1, 두 번째 보드 공개 |
| 12 | 시스템 | RUN_IT_MULTIPLE 에서 남은 런 = 0 | 상태 = HAND_COMPLETE, 전체 런 결과 합산, 팟 분배 |
| 13 | 운영자 | NEW HAND 버튼 + Bomb Pot 설정 | PRE_FLOP 스킵, FLOP 직행 (Bomb Pot 상태 전이 변형, §4.1 참조) |
| 14 | 운영자 | HAND_COMPLETE + manual "Next Hand" 또는 overrideButton=true | 상태 = IDLE, board_cards 리셋, action_on=-1 |
| 15 | 운영자 | 핸드 진행 중 UNDO 버튼 (최대 5단계) | 이전 상태 복원, action_on 복원 |
| 16 | 시스템 | 미스딜 감지 (카드 불일치 또는 운영자 지시) | 상태 = IDLE, pot 복귀, stacks 복구 |

### 3.14 Action Rotation 유저 스토리 (BS-06-10 §유저 스토리)

| # | As a | When | Then |
|:-:|------|------|------|
| 1 | 운영자 | 6인 NL PRE_FLOP 시작 | action_on = Seat 4 (UTG, 딜러+3) |
| 2 | 운영자 | 2인 Heads-up PRE_FLOP | action_on = Dealer(SB), POST_FLOP 에서는 BB |
| 3 | 운영자 | UTG Straddle 적용 시 PRE_FLOP | action_on = Straddle 다음 좌석 |
| 4 | 운영자 | Seat 4 Fold 후 (Seat 5, 6 active) | action_on = Seat 5 (시계방향 다음 active) |
| 5 | 운영자 | Seat 4 Raise 후 | 모든 active 에게 재액션 기회, action_on = Seat 5 |
| 6 | 운영자 | PRE_FLOP 전원 콜, BB 체크 | betting_round_complete = true |
| 7 | 운영자 | Seat 2~6 폴드, Seat 1만 남음 | active == 1, → HAND_COMPLETE |
| 8 | 운영자 | Dead Button (딜러 좌석 빔) | SB / BB 정상 결정, 딜러 좌석 스킵 |
| 9 | 운영자 | BB Raise 후 전원 콜 | BB 에게 돌아오면 라운드 완료 |
| 10 | 운영자 | 전원 올인 (active == 0) | action_on = -1, → SHOWDOWN |

### 3.15 포지션 예시 (BS-06-10 §포지션 예시)

#### 6인 테이블

```
좌석 배치 (시계방향):
  Seat 1 (BTN/Dealer)
  Seat 2 (SB)
  Seat 3 (BB)
  Seat 4 (UTG)    ← PRE_FLOP first_to_act (일반)
  Seat 5 (HJ)
  Seat 6 (CO)

PRE_FLOP 액션 순서: 4 → 5 → 6 → 1 → 2 → 3
POST_FLOP 액션 순서: 2 → 3 → 4 → 5 → 6 → 1
```

#### Heads-up (2인)

```
  Seat 1 (BTN = SB = Dealer)
  Seat 3 (BB)

PRE_FLOP: Seat 1(SB) → Seat 3(BB)
POST_FLOP: Seat 3(BB) → Seat 1(SB)
```

#### Straddle (UTG 플레이어가 자발적으로 BB 의 2배를 미리 내는 추가 블라인드)

```
  Seat 1 (BTN), Seat 2 (SB), Seat 3 (BB)
  Seat 4 (UTG = Straddle, 2×BB 납부)
  Seat 5, Seat 6

PRE_FLOP 액션 순서: 5 → 6 → 1 → 2 → 3 → 4(Last, check option)
POST_FLOP: 일반 규칙 (SB 부터)
```

### 3.16 레이즈 후 액션 재개 예시 (BS-06-10 §레이즈 후 액션 재개)

#### 6인 PRE_FLOP 에서 레이즈

```
초기: action_on = Seat 4 (UTG)
  Seat 4: Raise 100  → acted = {4}, action_on = 5
  Seat 5: Call        → acted = {4,5}, action_on = 6
  Seat 6: Fold        → acted = {4,5,6}, action_on = 1
  Seat 1: Call        → acted = {4,5,6,1}, action_on = 2
  Seat 2: Fold        → acted = {4,5,6,1,2}, action_on = 3
  Seat 3: Call        → acted = {4,5,6,1,2,3}
  → all active players acted → betting_round_complete = true
```

#### BB Check Option 후 레이즈 복귀

```
PRE_FLOP, biggest_bet == BB:
  Seat 4 (UTG): Call    → action_on = 5
  Seat 5: Call           → action_on = 6
  Seat 6: Call           → action_on = 1 (BTN)
  Seat 1: Call           → action_on = 2 (SB)
  Seat 2 (SB): Call      → action_on = 3 (BB)
  Seat 3 (BB): Check     → all_players_acted = true
  → betting_round_complete = true

만약 Seat 3 (BB) 가 Raise:
  Seat 3: Raise 200     → acted = {3}, action_on = 4
  모든 active 플레이어가 다시 액션해야 함
```

---

## 4. Exceptions & Edge Cases

### 4.1 핸드 시작 전제조건 (BS-06-01 §전제조건)

#### StartHand 호출 가능 조건

| 필드 | 조건 | 설명 |
|------|------|------|
| **pl_dealer** | != -1 | 딜러 위치 할당됨 |
| **num_blinds** | 0~3 | 블라인드 타입 정의됨 |
| **num_seats** | 2+ | 최소 2명 이상 플레이어 |
| **current state** | IDLE | 현재 상태가 IDLE |

#### 핸드 진행 중 불변 조건

- `hand_in_progress == true`: 항상 true (SETUP_HAND 부터 HAND_COMPLETE 직전까지)
- `action_on` != -1: 현재 액션 플레이어가 할당됨 (SHOWDOWN, RUN_IT_MULTIPLE 제외)
- `dealer_seat`: 핸드 내 불변 (버튼 이동은 다음 핸드)
- `board_cards` 수: 감소하지 않음

### 4.2 비활성 조건 (BS-06-01 §비활성 조건)

다음 조건이 참이면 핸드 라이프사이클 FSM 은 **비활성 상태**이며, 상태 전이가 발생하지 않는다:

- `hand_in_progress == false` **AND** `state == IDLE`
- 앱 대기 중 (테이블 선택 이전)
- 이전 핸드 완료 후 운영자가 "Next Hand" 명령 미발생

### 4.3 Bomb Pot 상태 전이 변형 (BS-06-01 §Bomb Pot)

Bomb Pot 이란 모든 플레이어가 동일 금액을 먼저 내고, **PRE_FLOP** 베팅 없이 바로 **FLOP** 부터 시작하는 특수 방식이다. **PRE_FLOP** 베팅 라운드를 **완전히 스킵**하는 특수 상태 전이이다.

#### 4.3.1 활성화 조건

| 필드 | 조건 | 설명 |
|------|------|------|
| **bomb_pot_enabled** | true | Bomb Pot 활성화됨 |
| **bomb_pot_amount** | > 0 | 전원 납부 금액 설정됨 |
| **num_active_players** | 2+ | 최소 2명 이상 |

#### 4.3.2 상태 전이

```
[IDLE]
  ↓ NEW HAND (Bomb Pot 모드)
[SETUP_HAND]
  ├─ 모든 플레이어 bomb_pot_amount 자동 수납
  ├─ PRE_FLOP 스킵
  ↓
[FLOP] ← PRE_FLOP 없이 직행
  ├─ 보드 3장 공개 대기 (RFID 또는 수동)
  ↓ (이후 표준 흐름)
[TURN] → [RIVER] → [SHOWDOWN] → [HAND_COMPLETE]
```

#### 4.3.3 Short Contribution 처리

| 조건 | 처리 |
|------|------|
| 모든 플레이어 stack ≥ bomb_pot_amount | 전원 동일 금액 수납 |
| 일부 플레이어 stack < bomb_pot_amount | 해당 플레이어는 최대 스택만 수납, Dead money 로 팟에 분배 |
| 1명만 남음 | Bomb Pot 불필요, 즉시 HAND_COMPLETE |

#### 4.3.4 Button Freeze & Opt-Out (WSOP Rule 28.3.2)

**원칙**: Bomb pot 핸드 동안 button 은 이동하지 않으며 (freeze), opt-out 을 선택한 플레이어는 위치 에퀴티를 잃지 않는다. 이는 WSOP Official Live Action Rules Rule 28.3.2 의 "버튼은 '폭탄 팟' 핸드에서 진행되지 않으므로 '폭탄 팟' 에 참여하지 않기로 선택한 플레이어는 포지션 에퀴티를 잃지 않습니다" 조항에 근거한다.

##### Opt-Out vs Short Contribution

| 구분 | Opt-out | Short Contribution |
|------|---------|-------------------|
| 조건 | 플레이어 명시적 거부 | stack < bomb_pot_amount |
| Ante 납부 | 하지 않음 | 최대 stack 만 납부 (all-in) |
| 카드 딜 | 받지 않음 | 정상 수령 |
| 핸드 참여 | 완전 제외 | 참여 (all-in 상태) |
| Button 영향 | Freeze 로 equity 보존 | 정상 freeze |

##### 신규 Input Event

CC 가 전송할 수 있는 신규 이벤트 (BS-06-09 이벤트 카탈로그에 추가 필요):

| 이벤트 | payload | 설명 |
|--------|---------|------|
| `BOMB_POT_OPT_OUT` | `{ seat_index }` | Bomb pot 핸드에서 특정 플레이어 opt-out 지정 |

##### Opt-Out 신청 시점

Bomb pot 핸드 시작 전 SETUP_HAND 에서 CC 가 `BOMB_POT_OPT_OUT { seat_index }` 이벤트를 전송한다.

##### 의존 State

`state.bomb_pot_opted_out: Set<int>` 필드가 필요하다 (§5.1 GameState 참조).

#### 4.3.5 기본 금액 (WSOP Rule 28.3.1 참조)

**EBS Engine 기본값**: `2 × BB` (설정 가능, `bomb_pot_amount` 필드로 override)

**WSOP 권장값** (Rule 28.3.1 — 플레이어가 ante 금액 합의에 이르지 못한 경우의 default):

| 게임 스테이크 | WSOP 권장 ante |
|--------------|---------------|
| $1-$2-$5 limit type | $20/player |
| $5-$5 limit type | $25/player |
| 기타 | `2 × BB` (EBS 기본) |

House 는 `bomb_pot_amount` 필드로 임의 값을 설정할 수 있으며, WSOP 토너먼트 운영 시에는 Rule 28.3.1 권장값을 사용한다.

### 4.4 Run It Multiple vs Rabbit Hunting (Rule 81) (BS-06-01 §RIM vs Rabbit)

**원칙**: Rabbit hunting 은 허용되지 않는다 (WSOP Official Live Action Rules Rule 81). Run It Multiple (RIM) 과 명확히 구분하여 엔진이 처리한다.

#### 개념 구분

| 구분 | Run It Multiple (허용) | Rabbit Hunting (금지) |
|------|----------------------|---------------------|
| 조건 | 2명+ 플레이어 all-in, 보드 미완성 | 핸드 종료 후 잔여 카드 노출 요청 |
| 시점 | SHOWDOWN 직전 | HAND_COMPLETE 이후 |
| 합의 | 관련 all-in 플레이어 전원 합의 | 요청자 단독 |
| 결과 | Pot 분배에 영향 (독립 board 2~3회) | Pot 영향 없음 (단순 호기심) |
| WSOP | 허용 (관련 규정 준수 시) | **금지 (Rule 81)** |
| Engine 지원 | ✅ `RunItChoice` 이벤트 | ❌ 요청 거부 |

#### 엔진 응답 정책

- `RunItChoice { times: 2 or 3 }`: 정상 처리 (§4.6 RIM 흐름 참조)
- 외부가 "핸드 종료 후 덱 공개" 의미의 요청을 전송해도 엔진은 수신 후 거부 응답:

```
if event_type == "rabbit_hunt_request":
    emit OutputEvent.Error {
        code: "rabbit_hunt_not_allowed",
        message: "Rabbit hunting is not allowed (WSOP Rule 81)"
    }
    return state  // 상태 변경 없음
```

#### CC UI 구현 권고

- Run It Multiple 옵션은 all-in 상황에서만 활성화한다.
- Rabbit hunting 버튼 / 메뉴는 제공하지 않는다 (Team 4 CC 운영 매뉴얼 준수).
- 딜러의 수동 덱 조회도 운영 매뉴얼상 금지.

### 4.5 Miss Deal (BS-06-01 §예외 처리)

- **감지**: SETUP_HAND 중 홀카드 수 != 2 (Hold'em 기준)
- **처리**:
  1. game_state → IDLE
  2. pot 내 모든 칩 원래 스택으로 복귀
  3. board_cards 리셋
  4. blinds 재포스트 요청 (운영자)

### 4.6 Card Rescan (BS-06-01 §예외 처리)

- **트리거**: RFID 미감지 또는 `card_verify_mode=true`
- **처리**: game_state 유지, `card_rescan=true` 설정, RFID 재감지 대기

### 4.7 UNDO (최대 5단계) (BS-06-01 §예외 처리)

- **트리거**: 운영자 UNDO 버튼
- **처리**: `undo_stack` 에서 이전 (state, action_on, board_cards) 복원

### 4.8 Dead Button 처리 (BS-06-10 §Dead Button)

| 필드 | 조건 | 액션 순서 영향 |
|------|------|-------------|
| `button_dead` | true (이전 딜러 좌석이 빈 경우) | SB = 딜러+1, BB = 딜러+2. 딜러 좌석 자체는 액션에서 제외 |
| `missing_sb` | SB 좌석이 비어있거나 sitting_out | SB 포스팅 생략, BB 만 포스팅. PRE_FLOP first_to_act 변경 없음 |
| `missing_bb` | BB 좌석이 비어있거나 sitting_out | BB 포스팅 생략. biggest_bet_amt = 0 → 전원 CHECK / BET 가능 |

### 4.9 Stud 계열 테이블 균형 (Rule 288 보충, BS-06-00-REF §1.2.4)

Mix 에 Stud 변형이 포함된 경우 table balance 시 high card rule 을 적용한다:

- 대상 플레이어 선정: 모든 seat 에 1장씩 open card 딜 → 가장 높은 카드 플레이어가 이동
- 현재 게임이 Stud 이든 Flop 게임이든 **동일하게 적용** (Rule 288: "스터드 이벤트 또는 스터드 변형이 있는 혼합 이벤트의 테이블 균형을 조정할 때")
- EBS 엔진은 `BalancePlayerSelection` 이벤트를 BO 로부터 수신하여 판정을 수행 (후속 CCR 에서 별도 정의)

### 4.10 Mixed Game Contracts 영향 (BS-06-00-REF §1.2.4)

후속 CCR 필요 항목:

- `SET_GAME_TRANSITION_PENDING` Input Event: Team 2 BO 와 Team 3 Engine 간 계약 필요 → `contracts/api/API-01` Part II 또는 `API-05` 확장
- `GameTransitioned` OutputEvent: Team 4 CC / Overlay 와 Team 3 Engine 간 계약 필요 → `contracts/api/API-04` 확장
- 본 문서는 engine 내부 규정만 명시하고, 외부 계약은 별도 CCR 로 처리한다.

### 4.11 Edge Case 테스트 케이스 (BS-06-10 §Edge Case TC)

#### TC-ROTATION-01: Dead Button 상황

| 항목 | 값 |
|------|-----|
| **사전 조건** | 4인 테이블, Seat 1 (Dealer) 탈락, Dead Button Rule 적용 |
| **입력** | HandStart(dealerSeat=1) — Seat 1 은 빈 자리 |
| **기대 결과** | Button 은 Seat 1 에 유지 (Dead Button), SB = Seat 2, BB = Seat 3, UTG = Seat 0 |
| **판정 기준** | firstToAct(state) == 0 (UTG), state.dealerSeat == 1 |

#### TC-ROTATION-02: 4인 All-in 후 남은 1 Active

| 항목 | 값 |
|------|-----|
| **사전 조건** | 5인 테이블, Seat 0~3 All-in, Seat 4 Active |
| **입력** | PlayerAction(seat=4, action=Call) |
| **기대 결과** | is_betting_round_complete = true (1 active, allIn 존재, acted + bet 매칭) |
| **판정 기준** | BettingRules.isRoundComplete(state) == true |

#### TC-ROTATION-03: Straddle + BB Option 동시 적용

| 항목 | 값 |
|------|-----|
| **사전 조건** | 6인 테이블, Straddle 활성 (Seat 3), 전원 Call |
| **입력** | 전원 Call (Seat 4, 5, 0, 1, 2 순서로) → BB(Seat 2) 에게 Option |
| **기대 결과** | BB 는 Check / Raise 선택 가능, Straddle 이후에도 BB Option 보존 |
| **판정 기준** | actionOn == bb_seat, legalActions 에 Check 포함 |

---

## 5. Data Models (Pseudo-code)

### 5.1 GameState (BS-06-00-REF §2.1)

현재 진행 중인 핸드의 전체 게임 상태를 한 덩어리로 묶은 구조다. 방송 화면에 보이는 모든 정보 — 보드 카드, 팟 금액, 플레이어 칩 — 가 이 구조에서 나온다. 서버는 이 데이터를 `GameInfoResponse` (게임 정보 응답) 메시지로 클라이언트에 전송한다.

| 필드 | 타입 | 설명 | 범위 / 제약 |
|------|------|------|---------|
| hand_number | int | 현재 핸드 번호 | 1+ (누적) |
| game | int | 게임 종류 | 0 = Hold'em |
| game_class | int | 게임 계열 | 0 = flop |
| bet_structure | int | 베팅 구조 | 0-2 (NL/FL/PL) |
| ante_type | int | 앤티 유형 | 0-6 (7가지) |
| game_phase | int | 현재 단계 | 0-17, game_phase enum (§2.2 참조) |
| players | Player[] | 모든 플레이어 | 최대 10명 (seats 0-9) |
| board_cards | Card[] | 보드 카드 | 0-5장 |
| pot | Pot | 메인 팟 | amount >= 0 |
| side_pots | Pot[] | 사이드 팟 | 빈 배열 또는 1+ |
| dealer_seat | int | 딜러 버튼 위치 | 0-9 또는 -1 (미할당) |
| blinds | Blinds | 블라인드 정보 | 구조체 |
| action_on | int | 현재 액션 플레이어 좌석 | 0-9 또는 -1 (없음) |
| hand_in_progress | bool | 핸드 진행 중 | true / false |
| board_reveal_stage | int | 보드 공개 진행도 | 0-3 (None/Flop/Turn/River) |
| event_game_type | int | 이벤트 게임 대분류 | 0-8, event_game_type enum |
| event_flight_status | int | 이벤트 진행 상태 | 0-6, event_flight_status enum |
| competition_type | int | 대회 유형 | 0-4, competition_type enum |
| table_id | int | 테이블 식별자 | 1+ |
| table_no | int | 테이블 표시 번호 | 1+ |
| is_feature_table | bool | 중계 테이블 여부 | true / false |
| prev_hand_bb_seat | int? | 직전 핸드에서 BB 였던 플레이어 seat index. 헤즈업 전환 시 "연속 BB 방지" button 조정용 (WSOP Rule 87, BS-06-03 §Heads-up 전환 참조). HAND_COMPLETE 시 현재 `bbSeat` 를 복사, 신규 핸드 시작 전 유지 | -1 또는 0-9 |
| boxed_card_count | int | 현재 핸드에서 RFID 가 감지한 boxed card (face-up 상태 딜링) 누적 수. 2 이상이면 Rule 88 에 따라 misdeal 트리거 (BS-06-08 매트릭스 5 참조) | 0+, HAND_COMPLETE / MisDeal 시 0 으로 리셋 |
| tournament_heads_up | bool | 전체 토너먼트에 2명만 남은 상태. FL 게임의 raise cap 무시 판정 기준 (WSOP Rule 100.b, BS-06-02 §5.2 참조). BO 가 `SET_TOURNAMENT_HEADS_UP` 이벤트로 설정. Cash game 은 항상 false | true / false, 기본 false |
| bomb_pot_opted_out | Set\<int\> | 현재 bomb pot 핸드에서 opt-out 한 플레이어 seat indexes. Button freeze 로 position equity 보존 (WSOP Rule 28.3.2, §4.3 참조). HAND_COMPLETE 시 clear | 빈 Set 또는 seat indexes |
| mixed_game_sequence | List\<GameDef\> | Mixed 토너먼트의 전체 mix 순서 (예: HORSE=[Hold'em, O8, Razz, Stud, Stud8] 5종 FL — Foundation §10). null 이면 단일 게임 모드. Rule 100.b 및 New Blind Type: Mixed Omaha 참조 | null 또는 1+ 요소 |
| current_game_index | int | `mixed_game_sequence` 에서 현재 게임 인덱스. 전환 시 `(index + 1) % len` 진행. 단일 게임 모드에서는 0 고정 | 0+ |
| game_transition_pending | bool | 다음 핸드에서 게임 전환이 예정된 상태. BO 가 레벨 종료 시 설정. 전환 핸드의 HAND_COMPLETE 에서 button freeze 트리거 (Mixed Omaha New Blind Type 참조) | true / false, 기본 false |

> 예시: Hold'em NL 1/2, 플롭 직후 상태
> `hand_number=47, game=0, game_class=0, bet_structure=0, game_phase=3(FLOP), board_cards=["As","Kh","7d"], board_reveal_stage=1, action_on=3`

### 5.2 Player (BS-06-00-REF §2.2)

게임 테이블의 개별 플레이어 정보. 좌석별 배열로 관리.

| 필드 | 타입 | 설명 | 범위 / 제약 |
|------|------|------|---------|
| name | string | 플레이어 이름 | 최대 30자 |
| seat | int | 좌석 번호 | 0-9 |
| stack | int | 현재 칩 스택 | 0+ (단위: 칩) |
| hole_cards | Card[] | 홀카드 | 2장 |
| status | string | 상태 | "active", "folded", "allin", "eliminated", "sitting_out" |
| position | string | 포지션명 | "SB", "BB", "UTG", "HJ", "CO", "BTN" 등 |
| stats | PlayerStats | 누적 통계 | 구조체 |
| profile_pic | string | 프로필 사진 URL | URI 또는 null |
| reentry_count | int | 재진입 횟수 | 0+ |
| sit_in_status | int | 착석 상태 (대기→순번→착석 3단계) | 0=None, 1=Queueing(대기열), 2=Waiting(순번 대기), 3=Seating(착석 중) |
| join_type | int | 참가 경로 | 0=APP, 1=SPOT, 2=STAFF |
| missed_sb | bool | 최근 lap 에서 SB 포지션을 놓친 상태 (sit out 등). 복귀 시 포스팅 의무 발생 (WSOP Rule 86, BS-06-03 §Missed Blind 참조) | true / false, 기본 false |
| missed_bb | bool | 최근 lap 에서 BB 포지션을 놓친 상태 (sit out 등). 복귀 시 포스팅 의무 발생 (WSOP Rule 86, BS-06-03 §Missed Blind 참조) | true / false, 기본 false |
| cards_tabled | bool | 플레이어가 테이블 위에 카드를 명시적으로 공개한 상태. true 일 때 dealer / engine 의 임의 muck 처리가 금지됨 (WSOP Rule 71, BS-06-07 §7 핸드 보호 참조). HAND_COMPLETE 시 false 로 리셋 | true / false, 기본 false |

### 5.3 GameDef (Mix sequence, BS-06-00-REF §1.2.4)

```
GameDef {
    variant_name: str,      // "O8", "Razz", "Stud", "NLH", "PLO", etc.
    bet_structure: int,     // NL/PL/FL
    hole_card_count: int,   // variant에 따름
    level_hands: int?,      // null이면 레벨당 hand 수 무관 (시간 기반)
}
```

### 5.4 GameSession ↔ HandState 매핑 (BS-06-00-REF §7.4)

기존 `GameSession` 모델과 새 `HandState` 의 통합 지점이다.

```
class GameSession {
  // 기존 필드 (변경 없음)
  final SessionPhase phase;
  final String userName, tableName;
  final List<Player> players;
  final Set<PlayingCard> registeredCards;
  final int handNumber;

  // 신규 필드
  final HandState? activeHand;  // live 상태에서만 non-null

  // street getter 변경: activeHand에서 파생
  Street get street => activeHand?.phase.toStreet() ?? Street.preflop;

  // communityCards getter 변경: activeHand에서 파생
  List<PlayingCard> get communityCards =>
    activeHand?.boardCards ?? const [];
}
```

### 5.5 알고리즘 1: determine_first_to_act (BS-06-10 §알고리즘 1)

스트리트 시작 시 `action_on` 을 결정한다.

```
function determine_first_to_act(phase, dealer_seat, players, blind_config):

  num_active = count(p for p in players if p.status == active)

  // 1. PRE_FLOP: 특수 규칙
  if phase == PRE_FLOP:

    // 1a. Heads-up (2인): Dealer(=SB)가 먼저
    if num_active == 2:
      return dealer_seat  // Dealer = BTN = SB

    // 1b. Straddle 적용: Straddle 다음 좌석
    if blind_config.straddle_enabled:
      straddle_seat = blind_config.straddle_seat
      return next_active_after(straddle_seat, players)

    // 1c. 일반 (3인+): UTG (BB 다음 좌석)
    bb_seat = blind_config.bb_seat
    return next_active_after(bb_seat, players)

  // 2. POST_FLOP (FLOP, TURN, RIVER): SB부터
  else:

    // 2a. Heads-up (2인): BB가 먼저
    if num_active == 2:
      return blind_config.bb_seat

    // 2b. 일반: SB (또는 SB가 폴드/올인이면 그 다음)
    sb_seat = blind_config.sb_seat
    return next_active_from(sb_seat, players)
      // sb_seat 자신이 active면 sb_seat 반환
      // sb_seat이 폴드/올인이면 시계방향 다음 active

  // 3. SHOWDOWN, RUN_IT_MULTIPLE, HAND_COMPLETE:
  //    action_on = -1 (액션 없음)
  return -1
```

### 5.6 알고리즘 2: next_active_player (BS-06-10 §알고리즘 2)

현재 액션 플레이어의 다음 액션 플레이어를 결정한다.

```
function next_active_player(current_seat, players, num_seats):

  // 시계방향으로 순회
  for i in 1..num_seats:
    candidate = (current_seat + i) % num_seats
    // 좌석이 존재하고 액션 가능한 상태인지 확인
    if players[candidate] != null
       && players[candidate].status == active:
      return candidate

  // 한 바퀴 돌아도 active 플레이어 없음 (모두 폴드/올인)
  return -1  // action_on 해제
```

### 5.7 알고리즘 3: is_betting_round_complete (BS-06-10 §알고리즘 3)

현재 베팅 라운드가 종료되었는지 판정한다. `true` 이면 다음 스트리트로 전이한다.

```
function is_betting_round_complete(state):

  // 조건 1: active 플레이어가 1명 이하 → 조건부 종료
  // "active" = SeatStatus.active만 (allIn 제외)
  active_players = [p for p in state.players if p.status == active]
  allin_players = [p for p in state.players if p.status == allIn]

  if len(active_players) == 0:
    return true  // 전원 allIn 또는 fold → 즉시 종료

  if len(active_players) == 1 and len(allin_players) == 0:
    return true  // 1명만 남음 (나머지 전원 fold) → 즉시 종료

  if len(active_players) == 1 and len(allin_players) >= 1:
    // 1명 active + N명 allIn: active 플레이어가 call/fold 기회를 가진 후 종료
    p = active_players[0]
    if p in state.acted_this_round and p.current_bet == state.biggest_bet_amt:
      return true  // 이미 액션 완료 + 금액 매칭
    return false   // 아직 액션 기회 필요

  // 조건 2: 모든 active 플레이어가 동일 금액을 베팅했는가?
  for p in active_players:
    if p.current_bet != state.biggest_bet_amt:
      return false  // 아직 콜하지 않은 플레이어 있음

  // 조건 3: 모든 active 플레이어가 최소 1회 액션했는가?
  // ⚠️ PRE_FLOP BB 체크 옵션 보호:
  //    BB는 블라인드 포스팅으로 current_bet == biggest_bet_amt를 이미 충족(조건 2 pass)하지만,
  //    acted_this_round에 포함되지 않으므로 all_players_acted = false.
  //    이 조건이 BB가 액션 기회를 갖기 전에 라운드가 종료되는 것을 막는다.
  // ⚠️ acted_this_round 초기화 규칙:
  //    각 스트리트(PRE_FLOP 포함) 시작 시 반드시 {} (빈 셋)으로 초기화한다.
  //    블라인드/앤티 포스팅은 "액션"이 아니므로 절대 acted_this_round에 포함하지 않는다.
  if not state.all_players_acted:
    return false

  return true
```

### 5.8 update_all_players_acted (BS-06-10 §all_players_acted 판정)

```
function update_all_players_acted(state, acted_seat):

  // 액션한 좌석을 기록
  state.acted_this_round.add(acted_seat)

  // 레이즈 발생 시: acted 기록 리셋 (레이즈 플레이어만 남김)
  if action_was_raise:
    state.acted_this_round = {acted_seat}
    state.last_raiser = acted_seat

  // 모든 active 플레이어가 acted_this_round에 포함되면 완료
  state.all_players_acted =
    active_players.every(p => state.acted_this_round.contains(p.seat))
```

### 5.9 handle_raise_action_restart (BS-06-10 §레이즈 후 액션 재개)

BS-06-02:316~318 에서 정의된 `first_actor_after_raise` 의 상세 알고리즘.

```
function handle_raise_action_restart(state, raiser_seat):

  // 레이즈 이후 모든 비폴드 비올인 플레이어에게
  // 다시 액션 기회를 부여한다.
  // action_on = 레이즈 플레이어의 다음 active 플레이어
  state.action_on = next_active_player(raiser_seat, state.players)

  // acted_this_round 리셋
  state.acted_this_round = {raiser_seat}

  // 라운드 완료 조건: 레이즈 플레이어에게 다시 턴이
  // 돌아오면 (모든 다른 active가 call/fold 완료) 라운드 종료
```

### 5.10 resolve_dead_button (BS-06-10 §Dead Button)

```
function resolve_dead_button(dealer_seat, players):

  // 딜러 좌석이 비어있으면 button_dead = true
  // 하지만 딜러 좌석 자체는 이동하지 않음 (다음 핸드에서 이동)

  // SB = 딜러 다음 첫 번째 occupied seat (active 불문)
  sb_seat = next_occupied_after(dealer_seat, players)

  // BB = SB 다음 첫 번째 occupied seat
  bb_seat = next_occupied_after(sb_seat, players)

  // first_to_act = BB 다음 active seat (PRE_FLOP)
  return (sb_seat, bb_seat)
```

### 5.11 Bomb Pot Button Freeze (BS-06-01 §Button Freeze)

```
SETUP_HAND 진입 시 (bomb_pot_enabled == true):
    state.frozen_dealer_seat = state.dealer_seat  // 현재 dealer 보존

HAND_COMPLETE 시 (bomb_pot_enabled == true):
    // _endHand() 로직에서 dealer +1 이동 스킵
    state.dealer_seat = state.frozen_dealer_seat  // 동일 유지
    state.bomb_pot_enabled = false  // 다음 핸드부터 평소대로

다음 핸드 SETUP_HAND:
    state.dealer_seat = (state.dealer_seat + 1) % n  // 평소 이동
```

### 5.12 Bomb Pot Opt-Out 처리 (BS-06-01 §Opt-Out)

#### Opt-out 상태 처리

```
state.bomb_pot_opted_out.add(seat_index)
state.seats[seat_index].status = SEATED_OUT  // 임시
// 기존 stack 보존 (ante 납부 안 함)
// 카드 딜링 대상 아님
// 액션 순서에서 제외
```

#### HAND_COMPLETE 시 복귀

```
for idx in state.bomb_pot_opted_out:
    state.seats[idx].status = ACTIVE  // 정상 복귀
state.bomb_pot_opted_out = {}  // clear
```

### 5.13 Mixed Game Transition (BS-06-00-REF §1.2.4)

BO (Backoffice) 가 blind level 종료 이벤트를 전파하면 엔진은 다음과 같이 처리한다:

```
1. 신규 Input Event 수신:
   SET_GAME_TRANSITION_PENDING { table_id }
   → state.game_transition_pending = true

2. 현재 핸드 HAND_COMPLETE 시 (IT-10 ButtonFreezeMixedGame 트리거):
   if state.game_transition_pending:
       state.current_game_index = (state.current_game_index + 1) % len(sequence)
       state.variantName = sequence[current_game_index].variant_name
       state.bet_structure = sequence[current_game_index].bet_structure
       // Button freeze: dealer_seat 유지 (이동 스킵)
       state.game_transition_pending = false
       emit OutputEvent.GameTransitioned {
           from: prev_game,
           to: current_game,
           button_frozen: true
       }
   else:
       state.dealer_seat = (state.dealer_seat + 1) % n  // 평소 이동
```

### 5.14 Hold'em FSM 구현 가이드 (BS-06-01 §구현 가이드)

아래는 위 상태 전이를 프로그래밍 언어로 표현한 참고 코드다.

```
// Pseudocode: Hold'em state transitions
// 이벤트 payload 상세: BS-06-09 이벤트 카탈로그 참조

switch (current_state) {
  case IDLE:
    if (event == StartHand) → next_state = SETUP_HAND
  case SETUP_HAND:
    if (event == dealt_all_hole_cards) → next_state = PRE_FLOP
    if (bomb_pot_enabled) → next_state = FLOP  // PRE_FLOP 스킵
  case PRE_FLOP:
    if (event == betting_complete) → next_state = FLOP
    else if (event == all_fold) → next_state = HAND_COMPLETE
    else if (event == all_in && num_active == 0) → next_state = SHOWDOWN
  case FLOP:
    if (event == betting_complete) → next_state = TURN  // board 4장 대기
    else if (event == all_fold) → next_state = HAND_COMPLETE
    else if (event == all_in && num_active == 0) → next_state = SHOWDOWN
  case TURN:
    if (event == betting_complete) → next_state = RIVER  // board 5장 대기
    else if (event == all_fold) → next_state = HAND_COMPLETE
    else if (event == all_in && num_active == 0) → next_state = SHOWDOWN
  case RIVER:
    if (event == betting_complete) → next_state = SHOWDOWN
    else if (event == all_fold) → next_state = HAND_COMPLETE
  case SHOWDOWN:
    if (run_it_times > 0) → next_state = RUN_IT_MULTIPLE
    else → next_state = HAND_COMPLETE
  case RUN_IT_MULTIPLE:
    if (run_it_times_remaining == 0) → next_state = HAND_COMPLETE
  case HAND_COMPLETE:
    if (event == ManualNextHand) → next_state = IDLE
}
```

### 5.15 엔진 초기화 흐름 (BS-06-00-REF §7.5)

```
1. 사용자가 "Live 진입" 클릭
   ↓
2. GameSessionController.enterLive()
   ├─ GameEngine 인스턴스 생성
   ├─ GameConfig 구성 (bet_structure, blinds, ante)
   └─ players → EnginePlayer 변환
   ↓
3. engine.createInitialState(config, enginePlayers)
   → HandState(phase: IDLE, ...)
   ↓
4. session.copyWith(activeHand: initialState)
   ↓
5. 운영자가 "NEW HAND" 클릭
   → dispatch(StartHand())
   → IDLE → SETUP_HAND → (RFID 대기)
```

---

## 부록 A: legacy-id 섹션 매핑 (추적성 보존)

본 문서가 통합한 원본 문서들의 어느 섹션이 어디로 흡수되었는지 정확한 매핑.

| 원본 문서 (legacy-id) | 원본 섹션 | 본 문서 위치 |
|---------------------|----------|-------------|
| **BS-06-01** Lifecycle.md | 개요 + 상태 흐름 다이어그램 | §1.1 + §2.1 |
| BS-06-01 | 정의 (IDLE / SETUP_HAND / ...) | §1.3 |
| BS-06-01 | 트리거 소스 (3 입력 장치) | §3.1 |
| BS-06-01 | 상태별 진입 트리거 요약 | §3.2 |
| BS-06-01 | 핸드 시작 전제조건 + 진행 중 불변 | §4.1 |
| BS-06-01 | 유저 스토리 16개 | §3.13 |
| BS-06-01 | 매트릭스 1: Hold'em 상태 상세 | §3.3 |
| BS-06-01 | 매트릭스 2: Entry/Exit 조건 | §3.4 |
| BS-06-01 | 매트릭스 3: 보드 카드 수 기반 | §3.5 (BS-06-12 권위 위임) |
| BS-06-01 | 매트릭스 4: 특수 상황 오버라이드 | §3.6 |
| BS-06-01 | Bomb Pot 활성화 + 상태 전이 + Short Contribution | §4.3.1 ~ §4.3.3 |
| BS-06-01 | Bomb Pot Button Freeze (Rule 28.3.2) | §4.3.4 + §5.11 |
| BS-06-01 | Bomb Pot Opt-Out (vs Short Contribution + Input Event) | §4.3.4 + §5.12 |
| BS-06-01 | Bomb Pot 기본 금액 (Rule 28.3.1) | §4.3.5 |
| BS-06-01 | Run It Multiple vs Rabbit Hunting (Rule 81) | §4.4 |
| BS-06-01 | 비활성 조건 | §4.2 |
| BS-06-01 | 영향 받는 요소 | §3.12 |
| BS-06-01 | 구현 가이드 (switch-case pseudo) | §5.14 |
| BS-06-01 | 예외 처리 (Miss Deal / Card Rescan / UNDO) | §4.5, §4.6, §4.7 |
| **BS-06-10** Action_Rotation.md | 용어 (Straddle / Dead Button / NL/PL/FL / Pseudocode) | §1.6 |
| BS-06-10 | 개요 + 핵심 함수 3개 | §1.2 |
| BS-06-10 | 정의 (포지션, 액션 가능 상태) | §1.4 + §1.5 |
| BS-06-10 | 알고리즘 1: determine_first_to_act + 포지션 예시 | §5.5 + §3.15 |
| BS-06-10 | 알고리즘 2: next_active_player + 스킵 조건 | §5.6 + §3.10 |
| BS-06-10 | 알고리즘 3: is_betting_round_complete + 경계 케이스 | §5.7 + §3.11 |
| BS-06-10 | all_players_acted 판정 상세 | §5.8 |
| BS-06-10 | 레이즈 후 액션 재개 (pseudo + 6인 PRE_FLOP + BB Check Option) | §5.9 + §3.16 |
| BS-06-10 | Dead Button 처리 (필드 + resolve pseudo) | §4.8 + §5.10 |
| BS-06-10 | 유저 스토리 10개 | §3.14 |
| BS-06-10 | 매트릭스 1: first_to_act 결정 | §3.7 |
| BS-06-10 | 매트릭스 2: 라운드 완료 조건 | §3.8 |
| BS-06-10 | Edge Case TC: ROTATION-01/02/03 | §4.11 |
| **BS-06-00-REF** Overview.md | §1.1 game enum | §2.5 |
| BS-06-00-REF | §1.2.4 event_game_type enum | §2.6 |
| BS-06-00-REF | Mixed Game Rotation & Button Freeze (HORSE/8-Game/Mixed Omaha/Dealer's Choice/PPC) | §3.9 |
| BS-06-00-REF | Mixed Game State 필드 참조 + GameDef pseudo | §5.3 |
| BS-06-00-REF | Mixed Game 전환 트리거 pseudo | §5.13 |
| BS-06-00-REF | Stud 계열 테이블 균형 (Rule 288 보충) | §4.9 |
| BS-06-00-REF | Mixed Game Contracts 영향 (후속 CCR) | §4.10 |
| BS-06-00-REF | §1.4.5 BoardRevealStage enum | §2.3 |
| BS-06-00-REF | §1.5.2 PlayerStatus enum | §2.4 |
| BS-06-00-REF | §1.9 game_phase enum | §2.2 |
| BS-06-00-REF | §2.1 GameState (28 필드) | §5.1 |
| BS-06-00-REF | §2.2 Player (15 필드) | §5.2 |
| BS-06-00-REF | §7.4 HandState → GameSession 매핑 + GamePhase → Street | §5.4 + §2.7 |
| BS-06-00-REF | §7.5 엔진 초기화 흐름 | §5.15 |
| **BS-06-12** Card_Pipeline_Overview.md | (보드 카드 감지 권위) | §2.3 + §3.5 cross-ref |

---

## 부록 B: 도메인 경계 (out-of-scope)

본 도메인은 **Lifecycle 전이 + 액션 순환** 에 한정된다. 다음 영역은 별도 도메인 마스터에서 다룬다:

| 영역 | 권위 |
|------|------|
| 베팅 액션 (Bet/Call/Raise/All-in 금액 계산) | BS-06-02 (Betting domain — 차후 통합) |
| 블라인드 / 앤티 포스팅 | BS-06-03 (Blinds domain — 차후 통합) |
| 핸드 평가 (HandRank, kicker, side pot 분배) | BS-06-04~07 (Evaluation domain — 차후 통합) |
| 보드 카드 감지 / 홀카드 호출 | **BS-06-12** Card_Pipeline_Overview.md |
| 이벤트 트리거 카탈로그 (CC / RFID / Engine / BO) | `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: BS-06-00-triggers))) Triggers.md |
| RFID burst 처리 (coalescence) | BS-06-08 Coalescence.md |

본 문서는 위 영역의 결과를 **Lifecycle 측 trigger 로 수신**하지만, 그 내부 로직은 권위 문서에 위임한다.
