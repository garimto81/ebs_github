---
title: Hand Lifecycle
owner: team4
tier: internal
legacy-id: BS-05-01
last-updated: 2026-04-15
confluence-page-id: 3832807673
confluence-parent-id: 3811901565
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3832807673/Lifecycle
---

# BS-05-01 Command Center — 핸드 라이프사이클 (운영자 관점)

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 운영자 UI 관점 핸드 진행, HandFSM 상태별 CC 화면, 유저 스토리 24개 |
| 2026-05-07 | v4 cascade | CC_PRD v4.0 정체성 정합 — §"5-Act 시퀀스 (UI 추상화)" 신설. HandFSM 9-state 를 5 Act (IDLE → PreFlop → Flop/Turn/River → Showdown → Settlement) 로 묶어 UI level 에서 운영자 인지 부담 절감. 6 키 활성 phase 매핑 동시 명시. SSOT: `docs/1. Product/Command_Center.md` v4.0 §Ch.6. |

---

## 개요

이 문서는 BS-06-01-holdem-lifecycle.md에서 정의한 HandFSM을 **운영자가 CC에서 경험하는 UI 관점**으로 재기술한다. 각 상태에서 어떤 버튼이 활성화되고, 어떤 정보가 표시되며, 운영자가 무엇을 해야 하는지를 명시한다.

> 참조: HandFSM 상태 전이 규칙은 `Holdem/Lifecycle.md` (legacy-id: BS-06-01), 베팅 액션 규칙은 `Holdem/Betting.md` (legacy-id: BS-06-02)

---

## 정의

**핸드 라이프사이클 (운영자 관점)**: CC에서 운영자가 NEW HAND 버튼을 눌러 시작하고, 결과 확인 후 다음 핸드를 시작할 때까지의 전체 UI 흐름. Game Engine 내부 로직이 아닌 **화면에 보이는 것과 운영자의 행동**에 집중한다.

---

## 5-Act 시퀀스 (UI 추상화, 2026-05-07 신설 / 2026-05-08 명칭 통합)

> **트리거**: `docs/1. Product/Command_Center.md` v4.0 cascade. HandFSM 9-state 의 의미 묶음. 운영자가 12 시간 본방송 동안 한 핸드 = 한 영화 5 막으로 인지하도록 추상화.
>
> **2026-05-08 cascade (#179)**: 운영자 인지 layer (Foundation §3 = Hand Start → Deal → Bet → Showdown → Hand End) 와 9-state 묶음 layer 가 **동일 시퀀스의 두 표현**임을 매핑 표에 명시. Foundation 명칭이 정점 SSOT.

```
Act 1          Act 2          Act 3                Act 4        Act 5
──────────     ──────         ───────────────      ────────     ──────────
Hand Start  →  Deal      →    Bet                → Showdown  →  Hand End
(IDLE)         (PreFlop)      (Flop/Turn/River)    (Showdown)   (Settlement)

매핑 (HandFSM 9-state):
 Act 1 = IDLE
 Act 2 = SETUP_HAND → PRE_FLOP
 Act 3 = FLOP → TURN → RIVER (3 sub-acts)
 Act 4 = SHOWDOWN
 Act 5 = HAND_COMPLETE
```

### Act 별 카탈로그

| Act | 운영자 인지 (Foundation) | 9-state 묶음 | 9-state | StatusBar PHASE | TopStrip ACTING 박스 | PlayerGrid | 6 키 활성 |
|:---:|--------------------------|--------------|---------|----------------|---------------------|-----------|-----------|
| **1** | Hand Start | IDLE | IDLE | "IDLE" | "WAITING — Press START HAND" | 정적 (이름+스택) | **N** (START HAND) |
| **2** | Deal | PreFlop | SETUP_HAND → PRE_FLOP | "PRE_FLOP" | "ACTING — S{n} · {Name}" | 블라인드 → 홀카드 → action_on 펄스 | F·C·B·A·M |
| **3a** | Bet | Flop | FLOP | "FLOP" | "ACTING — S{n} · {Name}" | Community 3 슬롯 채움, 폴드 반투명 | F·C·B·A·M |
| **3b** | Bet | Turn | TURN | "TURN" | "ACTING — S{n} · {Name}" | Community 4 슬롯 | F·C·B·A·M |
| **3c** | Bet | River | RIVER | "RIVER" | "ACTING — S{n} · {Name}" | Community 5 슬롯 | F·C·B·A·M |
| **4** | Showdown | Showdown | SHOWDOWN | "SHOWDOWN" | "SHOWDOWN — Reveal hands" | 승자 강조, 핸드 공개 | (viewing — disabled) |
| **5** | Hand End | Settlement | HAND_COMPLETE | "COMPLETE" | "HAND OVER — Press FINISH HAND" | 팟 분배 애니메이션, 스택 갱신 | **N** (FINISH HAND) |

### 6 키 활성/비활성 정합

| 키 | Act 1 | Act 2~3 | Act 4 | Act 5 |
|:--:|:-----:|:-------:|:-----:|:-----:|
| N | START HAND | (disabled) | (disabled) | FINISH HAND |
| F | (disabled) | FOLD | (disabled) | (disabled) |
| C | (disabled) | CHECK / CALL | (disabled) | (disabled) |
| B | (disabled) | BET / RAISE | (disabled) | (disabled) |
| A | (disabled) | ALL-IN | (disabled) | (disabled) |
| M | (disabled) | Miss Deal | (disabled) | (disabled) |

> **참조**: 6 키 매핑 SSOT 는 `Action_Buttons.md §"v4.0 6 키 매핑"`. UI 4 영역 위계는 `Overview.md §3.0`.

### 자매 문서 정합

- `Action_Buttons.md` — 6 키 의미 카탈로그 + 자동 전환 룰
- `Overview.md §3.0` — 4 영역 위계
- `Overlay/Sequences.md` — 5-Act → Overlay 시퀀스 매핑

---

## 트리거

| 트리거 | 발동 주체 | 설명 |
|--------|----------|------|
| NEW HAND 버튼 / N키 | 운영자 (CC) | 핸드 시작 |
| DEAL 버튼 / D키 | 운영자 (CC) | 홀카드 딜 |
| 액션 버튼 (FOLD/CHECK/BET/CALL/RAISE/ALL-IN) | 운영자 (CC) | 베팅 액션 입력 |
| RFID CardDetected | 시스템 (자동) | 카드 자동 인식 |
| Engine 자동 전이 | 시스템 (자동) | 베팅 완료 → 다음 스트리트, 올인 → 런아웃 |
| ManualNextHand | 운영자 (CC) | HAND_COMPLETE → IDLE 전환 |

---

## 전제조건

CC에서 핸드를 시작하려면 다음이 모두 충족되어야 한다:

| 조건 | 설명 |
|------|------|
| HandFSM == IDLE | 이전 핸드가 완료된 상태 |
| pl_dealer != -1 | 딜러 위치가 할당됨 |
| 활성 플레이어 >= 2 | 최소 2인 착석 |
| 블라인드 설정 완료 | SB/BB 금액 정의됨 |

---

## 1. 상태별 CC 화면 상세

### 1.1 IDLE — 핸드 대기

| 요소 | 상태 |
|------|------|
| **활성 버튼** | NEW HAND |
| **비활성 버튼** | DEAL, FOLD, CHECK, BET, CALL, RAISE, ALL-IN |
| **테이블 영역** | 플레이어 이름 + 스택만 표시. 카드 슬롯 비어있음 |
| **보드** | 비어있음 (5슬롯 점선) |
| **팟** | 0 |
| **상단 바** | Hand # 표시, "IDLE" 상태 텍스트 |

**운영자 행동**: NEW HAND (N키) 클릭하여 핸드 시작.

### 1.2 SETUP_HAND — 핸드 준비

| 요소 | 상태 |
|------|------|
| **활성 버튼** | DEAL |
| **비활성 버튼** | NEW HAND, FOLD, CHECK, BET, CALL, RAISE, ALL-IN |
| **테이블 영역** | 딜러(D), SB, BB 뱃지 표시. 블라인드 자동 수거 애니메이션 |
| **보드** | 비어있음 |
| **팟** | SB + BB (+ Ante 합산) |
| **상단 바** | "SETUP" 상태 |

**자동 처리**: Engine이 블라인드를 자동 수거하고 스택에서 차감한다.
**운영자 행동**: 실물 카드 딜 준비 후 DEAL (D키) 클릭.

### 1.3 PRE_FLOP — 프리플롭 베팅

| 요소 | 상태 |
|------|------|
| **활성 버튼** | FOLD, CHECK, BET, CALL, RAISE, ALL-IN (action_on 플레이어 기준 조건부) |
| **비활성 버튼** | NEW HAND, DEAL |
| **테이블 영역** | 홀카드 슬롯 활성 (RFID 감지 또는 수동 입력 대기). action_on 좌석 펄스 애니메이션 |
| **보드** | 비어있음 (보드 카드 0장) |
| **팟** | 실시간 갱신 |
| **상단 바** | "PRE-FLOP" 상태, action_on 플레이어 이름 표시 |

**카드 입력**: RFID Real 모드면 자동 감지 대기. Mock 모드면 수동 카드 입력 그리드 표시.
**운영자 행동**: action_on 플레이어의 액션을 관찰하고 해당 버튼 클릭 (또는 단축키).

> 참조: 버튼 활성 조건 상세는 `Action_Buttons.md` (legacy-id: BS-05-02), 베팅 금액 규칙은 `Holdem/Betting.md` (legacy-id: BS-06-02)

### 1.4 FLOP — 플롭 베팅

| 요소 | 상태 |
|------|------|
| **활성 버튼** | FOLD, CHECK, BET, CALL, RAISE, ALL-IN (조건부) |
| **테이블 영역** | 폴드 플레이어 반투명. action_on 펄스 |
| **보드** | 3장 표시 (RFID 감지 또는 수동 입력) |
| **팟** | 이전 라운드 + 현재 베팅 합산 |

**보드 카드 입력**: RFID가 3장 감지하면 자동 표시. 미감지 시 수동 입력 폴백.
**운영자 행동**: 보드 카드 확인 후 각 플레이어 액션 입력.

### 1.5 TURN — 턴 베팅

| 요소 | 상태 |
|------|------|
| **보드** | 4장 표시 (Flop 3장 + Turn 1장) |
| 나머지 | FLOP과 동일 |

### 1.6 RIVER — 리버 베팅

| 요소 | 상태 |
|------|------|
| **보드** | 5장 표시 (전체 보드 완성) |
| **상단 바** | "RIVER" + final_betting_round 표시 |
| 나머지 | FLOP과 동일 |

### 1.7 SHOWDOWN — 카드 공개

| 요소 | 상태 |
|------|------|
| **활성 버튼** | 특수: CHOP, RUN IT (2x/3x), MUCK/SHOW |
| **비활성 버튼** | FOLD, CHECK, BET, CALL, RAISE, ALL-IN |
| **테이블 영역** | 남은 플레이어 홀카드 공개, 승자 강조 (하이라이트) |
| **보드** | 5장 + 핸드 랭킹 텍스트 (예: "Full House, Aces full of Kings") |
| **팟** | 최종 팟 금액 |

**Engine 자동 처리**: 핸드 평가 → 승자 결정 → 팟 분배 계산.
**운영자 행동**: 결과 확인. Run It Twice 합의 시 RUN IT 버튼. Chop 합의 시 CHOP 버튼.

### 1.8 RUN_IT_MULTIPLE — 런잇타임

| 요소 | 상태 |
|------|------|
| **테이블 영역** | 추가 보드 표시 영역 생성 (Run 2, Run 3...) |
| **팟** | 런별 분할 표시 |

**Engine 자동 처리**: 추가 보드 딜 → 각 런별 승자 결정.

### 1.9 HAND_COMPLETE — 핸드 완료

| 요소 | 상태 |
|------|------|
| **활성 버튼** | 없음 (3초 대기 후 자동 IDLE 전환, 또는 ManualNextHand) |
| **테이블 영역** | 팟 분배 애니메이션 → 승자 스택 증가 |
| **보드** | 클리어 대기 |
| **상단 바** | Hand # 증가 준비 |

**운영자 행동**: 결과 확인 후 대기. 자동으로 IDLE 전환되거나 수동으로 Next Hand.

---

## 2. 운영자 핵심 루프

운영자가 매 핸드 반복하는 7단계 루프:

| 단계 | 운영자 액션 | CC 반응 |
|:----:|------------|---------|
| 1 | NEW HAND (N키) | IDLE → SETUP_HAND, 블라인드 수거 |
| 2 | DEAL (D키) | 홀카드 딜 시작, RFID 대기 |
| 3 | PRE_FLOP 액션 입력 | 각 플레이어 FOLD/CHECK/BET/CALL/RAISE/ALL-IN |
| 4 | Flop 보드 확인 | 3장 RFID 감지 또는 수동 입력 |
| 5 | FLOP → TURN → RIVER 액션 반복 | 보드 카드 추가, 베팅 라운드 반복 |
| 6 | SHOWDOWN 결과 확인 | 승자 표시, 팟 분배 |
| 7 | IDLE 복귀 | 다음 핸드 대기 |

---

## 3. 특수 상황별 CC 흐름

### 3.1 All Fold (전원 폴드)

| 단계 | 발생 시점 | CC 반응 |
|:----:|----------|---------|
| 1 | 임의 베팅 라운드에서 1명 제외 전원 FOLD | Engine이 AllFolded 이벤트 발행 |
| 2 | — | SHOWDOWN 스킵, 바로 HAND_COMPLETE |
| 3 | — | 남은 1인에게 팟 자동 지급 |

### 3.2 Bomb Pot

| 단계 | 운영자 액션 | CC 반응 |
|:----:|------------|---------|
| 1 | NEW HAND 전 Bomb Pot 모드 설정 | SetBombPot 이벤트 |
| 2 | NEW HAND | 전원 bomb_pot_amount 자동 수납 |
| 3 | — | PRE_FLOP 스킵, FLOP 직행 |
| 4 | 이후 표준 진행 | FLOP → TURN → RIVER → SHOWDOWN |

### 3.3 Run It Twice

| 단계 | 운영자 액션 | CC 반응 |
|:----:|------------|---------|
| 1 | 올인 상황에서 SHOWDOWN 진입 | RUN IT 버튼 활성화 |
| 2 | RUN IT 2x 클릭 | SetRunItTimes(2) 이벤트 |
| 3 | — | 두 번째 보드 영역 생성, 추가 카드 딜 |
| 4 | — | 각 런별 승자 결정, 팟 분할 |

### 3.4 Chop (팟 합의 분배)

| 단계 | 운영자 액션 | CC 반응 |
|:----:|------------|---------|
| 1 | SHOWDOWN에서 플레이어 간 합의 | CHOP 버튼 클릭 |
| 2 | 분배 비율/금액 입력 | ConfirmChop 이벤트 |
| 3 | — | 합의 금액으로 팟 분배, HAND_COMPLETE |

### 3.5 Miss Deal (미스딜)

| 단계 | 운영자 액션 | CC 반응 |
|:----:|------------|---------|
| 1 | 핸드 진행 중 미스딜 인지 | MISS DEAL 버튼 클릭 |
| 2 | 확인 다이얼로그에서 확인 | MisdealDetected 이벤트 |
| 3 | — | 팟 → 원래 스택 복원, IDLE 복귀 |

---

## 유저 스토리

| # | As a | When | Then |
|:-:|------|------|------|
| 1 | 운영자 | CC가 IDLE 상태에서 NEW HAND 클릭 | 블라인드 자동 수거, DEAL 버튼 활성화 |
| 2 | 운영자 | SETUP_HAND에서 DEAL 클릭 | 홀카드 딜 시작, RFID 감지 대기 (또는 수동 입력) |
| 3 | 운영자 | PRE_FLOP에서 UTG 플레이어가 폴드 | FOLD 클릭 → 해당 좌석 반투명, action_on 다음 플레이어로 이동 |
| 4 | 운영자 | PRE_FLOP에서 BB 플레이어 차례, 레이즈 없음 | CHECK 버튼 활성 (BB check option) |
| 5 | 운영자 | PRE_FLOP 베팅 완료 | 자동으로 FLOP 대기, 보드 카드 입력 대기 |
| 6 | 운영자 | FLOP에서 RFID가 3장 감지 | 보드에 3장 자동 표시, 첫 액션 플레이어 펄스 |
| 7 | 운영자 | FLOP에서 RFID 미감지 | 수동 카드 입력 그리드 표시 → 3장 선택 |
| 8 | 운영자 | TURN에서 플레이어가 BET 선언 | BET 클릭 → 금액 입력 → 확인 → 팟 갱신 |
| 9 | 운영자 | RIVER에서 모든 플레이어 체크 | 자동으로 SHOWDOWN 진입 |
| 10 | 운영자 | SHOWDOWN에서 승자 1명 확정 | 승자 좌석 하이라이트, 팟 분배, HAND_COMPLETE |
| 11 | 운영자 | HAND_COMPLETE 후 3초 대기 | 자동 IDLE 전환, 핸드 번호 +1 |
| 12 | 운영자 | PRE_FLOP에서 전원 폴드 (BB 제외) | 바로 HAND_COMPLETE, BB에게 팟 지급 |
| 13 | 운영자 | FLOP에서 2인 올인 | SHOWDOWN 진입, 남은 보드 자동 런아웃 |
| 14 | 운영자 | Bomb Pot 모드 설정 후 NEW HAND | 전원 강제 베팅, PRE_FLOP 스킵, FLOP 직행 |
| 15 | 운영자 | SHOWDOWN에서 Run It Twice 클릭 | 두 번째 보드 영역 생성, 추가 딜 |
| 16 | 운영자 | SHOWDOWN에서 CHOP 합의 | 금액 입력 후 합의 분배 |
| 17 | 운영자 | 핸드 진행 중 MISS DEAL 선언 | 확인 다이얼로그 → 스택 복원 → IDLE |
| 18 | 운영자 | 핸드 진행 중 UNDO 클릭 | 마지막 액션 되돌리기, action_on 복원 |
| 19 | 운영자 | RIVER에서 3인 중 1인 올인 + 나머지 베팅 중 | 사이드 팟 생성 표시, 메인 팟/사이드 팟 분리 |
| 20 | 운영자 | CC 비정상 종료 후 재시작 | 이전 핸드 상태 자동 복원 (Event Sourcing) |
| 21 | 운영자 | SETUP_HAND에서 Straddle 플레이어 있음 | 3번째 블라인드 자동 수거, 액션 순서 변경 |
| 22 | 운영자 | PRE_FLOP에서 스택 부족 플레이어가 콜 | Short call → 자동 올인 처리, 사이드 팟 |
| 23 | 운영자 | HAND_COMPLETE에서 수동 Next Hand 클릭 | 즉시 IDLE 전환 (3초 대기 스킵) |
| 24 | 운영자 | Sitting Out 플레이어가 핸드에 포함된 경우 | 자동 폴드 처리, 해당 좌석 "AWAY" 표시 유지 |

---

## 경우의 수 매트릭스

### Matrix: HandFSM 상태 × 운영자 가능 행동

| HandFSM 상태 | 운영자 가능 행동 | 자동 처리 |
|-------------|----------------|----------|
| **IDLE** | NEW HAND, 좌석 편집, 설정 변경 | — |
| **SETUP_HAND** | DEAL | 블라인드 수거, 딜러 이동 |
| **PRE_FLOP** | FOLD, CHECK, BET, CALL, RAISE, ALL-IN, UNDO | 홀카드 RFID 감지, Equity 계산 |
| **FLOP** | FOLD, CHECK, BET, CALL, RAISE, ALL-IN, UNDO | 보드 카드 RFID 감지, Equity 갱신 |
| **TURN** | FOLD, CHECK, BET, CALL, RAISE, ALL-IN, UNDO | 보드 카드 RFID 감지, Equity 갱신 |
| **RIVER** | FOLD, CHECK, BET, CALL, RAISE, ALL-IN, UNDO | 보드 카드 RFID 감지, Equity 갱신 |
| **SHOWDOWN** | CHOP, RUN IT, MUCK/SHOW | 핸드 평가, 승자 결정, 팟 분배 |
| **RUN_IT_MULTIPLE** | — (자동 진행) | 추가 보드 딜, 런별 승자 결정 |
| **HAND_COMPLETE** | Next Hand (수동), 대기 (자동 전환) | 통계 업데이트, 핸드 기록 저장 |

---

## 비활성 조건

- HandFSM == IDLE이고 전제조건 미충족 시 NEW HAND 버튼 비활성
- Table 상태가 PAUSED일 때 모든 액션 버튼 비활성 (Lobby에서 Resume 필요)
- BO 연결 해제 시 핸드 데이터 BO 미전송 (로컬에서는 계속 진행 가능)

---

## RFID 완료 시 자동 스트리트 전이 (CCR-031, W12 해소)

보드 카드가 RFID로 감지되면 Game Engine은 자동으로 다음 스트리트로 전이한다.

| 현재 HandFSM | RFID 감지 | 자동 전이 |
|--------------|-----------|----------|
| PRE_FLOP | 보드 3장 감지 (플롭) | PRE_FLOP → FLOP |
| FLOP | 보드 4번째 카드 감지 (턴) | FLOP → TURN |
| TURN | 보드 5번째 카드 감지 (리버) | TURN → RIVER |

**예외 — Run It Multiple**:
- `run_it_multiple_allowed == true` + ALL-IN 상황에서는 **자동 전이 안 함**
- 운영자가 명시적으로 `SetRunItMultiple { run_count: 2|3 }` 호출 후 각 run을 순차 진행
- 각 run마다 별도 보드 RFID 감지

**구현 주의**: 자동 전이 로직은 Engine 측에서 처리. CC는 `StreetTransitioned` 이벤트를 수신하고 UI를 갱신만 한다.

---

## 영향 받는 요소

| 영향 대상 | 이 문서와의 관계 |
|----------|----------------|
| BS-05-02 액션 버튼 | 각 상태별 활성/비활성 버튼 조건 상세 |
| BS-05-05 Undo/복구 | UNDO 시 상태 복원 범위 |
| `Holdem/Lifecycle.md` (legacy-id: BS-06-01) | Engine 내부 FSM 전이 규칙 (이 문서의 근거) |
| `Holdem/Betting.md` (legacy-id: BS-06-02) | 베팅 액션 유효성 규칙 (이 문서의 근거) |
| BS-07-overlay | 각 상태별 Overlay 화면 변화 |
