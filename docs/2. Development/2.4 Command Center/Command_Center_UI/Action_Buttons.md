---
title: Action Buttons
owner: team4
tier: internal
legacy-id: BS-05-02
last-updated: 2026-04-15
confluence-page-id: 3818586873
confluence-parent-id: 3811901565
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818586873/EBS+Action+Buttons
---

# BS-05-02 Command Center — 액션 버튼 명세

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 8개 액션 버튼 완전 명세, HandFSM×버튼 매트릭스, 베팅 구조별 금액 범위 |
| 2026-04-13 | UI-02 redesign | Quick Preset/슬라이더 제거, 키패드 전용 입력, 자동 ALL-IN 전환 제거, 금액 검증 변경 |
| 2026-05-07 | v4 cascade | CC_PRD v4.0 정체성 정합 — 8 분리 버튼을 **6 키 동적 매핑** (N·F·C·B·A·M) 으로 통합. §"v4.0 6 키 매핑 (SSOT)" 신설. 구 §1~§8 8 버튼 명세는 archive (각 버튼이 6 키의 어느 phase 슬롯에 매핑되는지는 §"v4.0 6 키 매핑" 표에 명시). |

---

## 개요

CC 하단에 배치된 8개 액션 버튼은 운영자가 게임을 진행하는 핵심 입력 수단이다. 각 버튼의 활성/비활성은 현재 HandFSM 상태, action_on 플레이어, biggest_bet_amt, player.stack 등 게임 상태 변수에 의해 결정론적으로 결정된다.

> 참조: 베팅 액션의 유효성 규칙·금액 계산·상태 변경은 BS-06-02-holdem-betting.md에서 정의한다. 이 문서는 **CC UI에서 버튼이 어떻게 보이고 동작하는가**에 집중한다.

---

## 정의

**액션 버튼**: CC 하단 액션 패널에 배치된 8개 버튼. 운영자가 클릭하거나 단축키로 입력하면 Game Engine에 해당 이벤트를 전송한다.

**동적 전환**: 게임 상태에 따라 버튼 라벨·활성 여부·표시 금액이 자동으로 변경된다. 예: biggest_bet_amt == 0이면 CHECK/BET 표시, > 0이면 CALL/RAISE 표시.

---

## v4.0 6 키 매핑 (SSOT, 2026-05-07 신설)

> **트리거**: `docs/1. Product/Command_Center.md` v4.0 cascade. ActionPanel 의 8 분리 버튼 (v1.x) 시대가 끝나고 **6 키 (5 게임 + 1 비상)** 의 시대가 시작된다. 같은 키, phase 에 따라 의미가 자동 전환 (Phase-aware).

### 6 키 카탈로그

| 키 | 명칭 | IDLE | PRE_FLOP / FLOP / TURN / RIVER | SHOWDOWN / HAND_COMPLETE | 분류 |
|:--:|------|:----:|:------------------------------:|:------------------------:|:----:|
| **N** | Next / Finish | START HAND | (disabled — "HAND IN PROGRESS") | FINISH HAND | lifecycle |
| **F** | Fold | (disabled) | FOLD | (disabled) | 게임 액션 |
| **C** | Call / Check | (disabled) | CHECK *or* CALL (auto-switch) | (disabled) | 게임 액션 |
| **B** | Bet / Raise | (disabled) | BET *or* RAISE (auto-switch) | (disabled) | 게임 액션 |
| **A** | All-in | (disabled) | ALL-IN | (disabled) | 게임 액션 |
| **M** | Menu / Manual (Miss Deal) | (disabled) | Miss Deal | (disabled) | 비상 |

### 자동 전환 룰 (C/B 키)

```
biggestBet == playerBet  →  CHECK   (콜할 게 없음, C 키)
biggestBet >  playerBet  →  CALL    (맞춰야 함, C 키)
biggestBet == 0          →  BET     (첫 베팅, B 키)
biggestBet >  0          →  RAISE   (이미 베팅 있음, B 키)
```

### 8 버튼 (v1.x) → 6 키 (v4.0) 매핑

| v1.x 8 버튼 | v4.0 6 키 | 매핑 근거 |
|------------|-----------|----------|
| NEW HAND | **N** (IDLE) | 핸드 시작 = N |
| DEAL | (폐기) | createSession 시점에 auto HandStart + holecards (Engine §2.1) — DEAL 별도 호출 skip |
| FOLD | **F** | 1:1 매핑 |
| CHECK | **C** (biggestBet == playerBet) | C 키 자동 분기 |
| CALL | **C** (biggestBet > playerBet) | C 키 자동 분기 |
| BET | **B** (biggestBet == 0) | B 키 자동 분기 |
| RAISE | **B** (biggestBet > 0) | B 키 자동 분기 (R 키 폐기) |
| ALL-IN | **A** | 1:1 매핑 |
| (신규) | **M** | Miss Deal / Manual 진입 (Menu) |
| FINISH HAND | **N** (HAND_COMPLETE) | N 키 lifecycle 두 번째 슬롯 |
| UNDO | **Ctrl+Z** | 별도 (6 키 외) |

### Numpad (BET/RAISE 입력) — B 키 활성 시 슬라이드 업

`B` 키를 누르면 화면 하단에 슬라이드 업. 0 / 000 / `<-` 인접 (천 단위 빠른 입력). 상세: `UI.md §화면 4` (archive — layout 만 참조).

### 6 키의 가치

> ★ *같은 키 = 같은 손가락 위치 = 다른 의미*. 손가락은 알파벳을 외우지 않고 *위치* 를 외운다.

### 자매 문서 정합

- `Keyboard_Shortcuts.md` — 6 키 단축키 표준 (이 §과 동기 필수)
- `Hand_Lifecycle.md` — 5-Act ↔ 6 키 활성 phase 매핑
- `Manual_Card_Input.md` — M 키 (Manual) 진입

---

## [archive — v1.x] 트리거 + §1~§8 8 버튼 명세

> ⚠️ **Archive (v1.x)**: 본 §트리거 ~ §8 까지는 v1.x 8 분리 버튼 명세이며, v4.0 §"v4.0 6 키 매핑" 으로 *override* 됨. 활성/비활성 로직 (HandFSM × 버튼 매트릭스, 금액 검증, biggest_bet_amt 분기) 은 v4.0 6 키의 *각 키별 phase 슬롯* 으로 흡수됨. 인용 시 6 키 매핑 표를 우선.

## 트리거

모든 버튼은 운영자(CC) 수동 입력으로만 트리거된다.

| 입력 방식 | 설명 |
|----------|------|
| 마우스 클릭 | 버튼 직접 클릭 |
| 키보드 단축키 | N, D, F, C, B, R, A 키 |
| 터치 (v2.0+) | 터치스크린 입력 (추후) |

---

## 1. NEW HAND 버튼

### 활성 조건

| 조건 | 설명 |
|------|------|
| HandFSM == IDLE | 핸드 미진행 상태 |
| pl_dealer != -1 | 딜러 위치 할당됨 |
| num_active_players >= 2 | 활성 플레이어 2인 이상 |
| 블라인드 설정 완료 | SB/BB 금액 정의됨 |

### 비활성 조건

- HandFSM != IDLE (핸드 진행 중)
- 활성 플레이어 < 2
- 딜러 미할당

### UI 동작

| 항목 | 값 |
|------|-----|
| **단축키** | N |
| **금액 입력** | 불필요 |
| **확인 다이얼로그** | 없음 |
| **서버 명령** | `WriteGameInfo` (API-05 §9) — 24 필드 핸드 초기화 프로토콜 |
| **서버 응답** | `GameInfoAck { hand_id, ready_for_deal }` 수신 후 DEAL 버튼 활성화 |
| **이벤트** | `StartHand` |
| **결과** | IDLE → SETUP_HAND 전이 |

> **CCR-024**: NEW HAND 버튼 클릭 시 CC는 `WriteGameInfo` WebSocket 프로토콜을 BO에 발행한다. 24 필드(`dealer_seat`, `sb_seat`, `bb_seat`, `blind_structure_id`, `active_seats`, `dead_button_mode` 등) 전체 스키마와 검증 규칙은 **`WebSocket_Events.md §9 WriteGameInfo` (legacy-id: API-05)** 참조.

### 특수: Bomb Pot 모드

NEW HAND 전 Bomb Pot 모드가 설정되어 있으면:
- 전원 bomb_pot_amount 자동 수납
- SETUP_HAND → FLOP 직행 (PRE_FLOP 스킵)
- 버튼 라벨: "NEW HAND (BOMB)" 표시

---

## 2. DEAL 버튼

### 활성 조건

| 조건 | 설명 |
|------|------|
| HandFSM == SETUP_HAND | 핸드 준비 상태 |
| 블라인드 수거 완료 | Engine이 BlindsPosted 이벤트 발행 후 |

### 비활성 조건

- HandFSM != SETUP_HAND
- 블라인드 미수거

### UI 동작

| 항목 | 값 |
|------|-----|
| **단축키** | D |
| **금액 입력** | 불필요 |
| **확인 다이얼로그** | 없음 |
| **이벤트** | `Deal` |
| **결과** | 홀카드 딜 시작 → RFID 감지 대기 → 완료 시 PRE_FLOP 전이 |

---

## 3. FOLD 버튼

### 활성 조건

| 조건 | 설명 |
|------|------|
| HandFSM ∈ {PRE_FLOP, FLOP, TURN, RIVER} | 베팅 라운드 중 |
| action_on == 현재 선택 플레이어 | 해당 플레이어 차례 |
| player.status == active | 활성 상태 |

### 비활성 조건

- 핸드 미진행 또는 SHOWDOWN/HAND_COMPLETE
- action_on이 아닌 플레이어
- player.status == folded / allin / sitting_out

### UI 동작

| 항목 | 값 |
|------|-----|
| **단축키** | F |
| **금액 입력** | 불필요 |
| **확인 다이얼로그** | 없음 (즉시 처리) |
| **이벤트** | `Fold` |
| **결과** | 좌석 반투명(folded), action_on → 다음 플레이어 |

### 특수 케이스

| 케이스 | CC 반응 |
|--------|---------|
| 1명 남고 전원 폴드 | → HAND_COMPLETE 즉시 전이, 남은 1인에 팟 지급 |
| Sitting Out 플레이어 | 시스템 자동 폴드 (운영자 FOLD 불필요) |

---

## 4. CHECK 버튼

### 활성 조건

| 조건 | 설명 |
|------|------|
| HandFSM ∈ {PRE_FLOP, FLOP, TURN, RIVER} | 베팅 라운드 중 |
| biggest_bet_amt == player.current_bet | 미결 베팅 없음 (동일 금액) |
| action_on == 현재 플레이어 | 해당 플레이어 차례 |
| player.status == active | 활성 상태 |

### 비활성 조건

- biggest_bet_amt > player.current_bet (베팅이 있음 → CALL 필요)
- 핸드 미진행 / SHOWDOWN / HAND_COMPLETE
- action_on 아닌 플레이어

### UI 동작

| 항목 | 값 |
|------|-----|
| **단축키** | C (biggest_bet_amt == player.current_bet일 때) |
| **금액 입력** | 불필요 |
| **확인 다이얼로그** | 없음 |
| **이벤트** | `Check` |
| **결과** | action_on → 다음 플레이어. 전원 체크 시 베팅 라운드 완료 |

### 특수: BB Check Option

- PRE_FLOP에서 biggest_bet_amt == BB이고 action_on == BB_index일 때
- BB 플레이어는 CHECK 가능 (레이즈 없이 PRE_FLOP 종료)
- 누군가 레이즈하면 BB에게 다시 액션 턴 부여

---

## 5. BET 버튼

### 활성 조건

| 조건 | 설명 |
|------|------|
| HandFSM ∈ {PRE_FLOP, FLOP, TURN, RIVER} | 베팅 라운드 중 |
| biggest_bet_amt == 0 | 현재 스트리트 첫 베팅 |
| action_on == 현재 플레이어 | 해당 플레이어 차례 |
| player.status == active | 활성 상태 |
| player.stack > 0 | 칩 보유 |

### 비활성 조건

- biggest_bet_amt > 0 (이미 베팅 있음 → RAISE 사용)
- player.stack == 0
- 핸드 미진행

### UI 동작

| 항목 | 값 |
|------|-----|
| **단축키** | B |
| **금액 입력** | **필요** — 숫자 키패드 슬라이드업 |
| **확인 다이얼로그** | Enter 키 또는 BET 버튼으로 금액 확정 |
| **이벤트** | `Bet(amount)` |
| **결과** | biggest_bet_amt = amount, 팟 갱신, action_on → 다음 |

### 금액 범위 (베팅 구조별)

> 참조: 금액 계산 상세는 `Holdem/Betting.md` (legacy-id: BS-06-02) §3. BET

| 베팅 구조 | 최소 | 최대 |
|----------|------|------|
| **NL** | big_blind | player.stack |
| **PL** | big_blind | pot + 2 × big_blind |
| **FL** | low_limit (PRE_FLOP/FLOP), high_limit (TURN/RIVER) | 고정값 (선택 불가) |

> **Quick Preset은 제거되었다** (UI-02 2026-04-13). 금액 입력은 숫자 키패드(0-9 + C + ← + 000)만 사용한다.

> **슬라이더는 제거되었다** (UI-02 2026-04-13). 금액은 키패드로만 입력한다.

### 금액 입력 키패드

| 키 | 동작 |
|----|------|
| 0~9 | 숫자 입력 |
| C | 전체 초기화 |
| ← | 마지막 1자리 삭제 |
| 000 | 천 단위 빠른 입력 — 현재 값 뒤에 '000' 3자리 append. 예: '2' → '2,000', '15' → '15,000', 빈값 → '000' |
| Enter / BET 버튼 | 금액 확정 |

하드웨어 USB 숫자 키패드 입력 시 Amount Field에 직접 반영.

### 금액 검증 (변경)

| 입력값 | 반응 |
|--------|------|
| < min_bet | 경고 "최소 {min_bet}" + 재입력 |
| > max_bet 또는 > player.stack | **에러: "입력 실수. ALL-IN 버튼을 사용하세요"** → 재입력 |
| == 0 | 경고 "0 베팅 불가" |

> `> player.stack` 자동 ALL-IN 전환은 **제거**. ALL-IN은 전용 버튼으로만 가능.
> ALL-IN 버튼은 BET/RAISE 입력 패널 상단에 별도 배치.

---

## 6. CALL 버튼

### 활성 조건

| 조건 | 설명 |
|------|------|
| HandFSM ∈ {PRE_FLOP, FLOP, TURN, RIVER} | 베팅 라운드 중 |
| biggest_bet_amt > player.current_bet | 미결 베팅 존재 |
| action_on == 현재 플레이어 | 해당 플레이어 차례 |
| player.status == active | 활성 상태 |

### 비활성 조건

- biggest_bet_amt == player.current_bet (미결 베팅 없음 → CHECK)
- biggest_bet_amt == 0 (아무도 베팅 안 함)
- 핸드 미진행

### UI 동작

| 항목 | 값 |
|------|-----|
| **단축키** | C (biggest_bet_amt > player.current_bet일 때) |
| **금액 입력** | 불필요 (자동 계산: biggest_bet_amt - player.current_bet) |
| **확인 다이얼로그** | 없음 (즉시 처리) |
| **버튼 라벨** | "CALL {call_amount}" — 금액 표시 |
| **이벤트** | `Call` |
| **결과** | 해당 금액 스택에서 차감, 팟 갱신 |

### 특수: Short Call

| 조건 | CC 반응 |
|------|---------|
| call_amount > player.stack | 스택 전부 납부 → 자동 ALL-IN 처리, 사이드 팟 생성 |
| 버튼 라벨 | "CALL {stack} (ALL-IN)" 표시 |

> 참조: Short Call 상세는 `Holdem/Betting.md` (legacy-id: BS-06-02) §4. CALL

---

## 7. RAISE 버튼

### 활성 조건

| 조건 | 설명 |
|------|------|
| HandFSM ∈ {PRE_FLOP, FLOP, TURN, RIVER} | 베팅 라운드 중 |
| biggest_bet_amt > 0 | 기존 베팅 존재 |
| action_on == 현재 플레이어 | 해당 플레이어 차례 |
| player.status == active | 활성 상태 |
| player.stack > call_amount | 콜 이상의 칩 보유 |
| (FL만) num_raises < cap 또는 heads-up | FL 레이즈 상한 미도달 |

### 비활성 조건

- biggest_bet_amt == 0 (첫 베팅 → BET 사용)
- player.stack <= call_amount (콜만 가능, 레이즈 불가 → ALL-IN)
- (FL) raise cap 도달 + 3인 이상

### UI 동작

| 항목 | 값 |
|------|-----|
| **단축키** | R |
| **금액 입력** | **필요** — 숫자 키패드 슬라이드업 (최소~최대 범위 표시) |
| **확인 다이얼로그** | Enter 키 또는 RAISE 버튼으로 금액 확정 |
| **버튼 라벨** | "RAISE TO" |
| **이벤트** | `Raise(amount)` |
| **결과** | biggest_bet_amt 갱신, 다른 플레이어 재액션 필요 |

### 금액 범위 (베팅 구조별)

> 참조: 금액 계산 상세는 `Holdem/Betting.md` (legacy-id: BS-06-02) §5. RAISE

| 베팅 구조 | 최소 (min_raise_total) | 최대 |
|----------|----------------------|------|
| **NL** | biggest_bet_amt + max(BB, last_raise_increment) | player.stack + player.current_bet |
| **PL** | biggest_bet_amt + call_amount | pot + call_amount + biggest_bet_amt + call_amount |
| **FL** | 고정값 (low_limit 또는 high_limit) | 고정값 (선택 불가) |

> **Quick Raise 프리셋은 제거되었다** (UI-02 2026-04-13). 금액은 숫자 키패드로만 입력한다. 키패드 구성은 §5 BET 참조.

### FL 레이즈 제한

| 조건 | CC 반응 |
|------|---------|
| num_raises >= 4 (cap) + 3인 이상 | RAISE 버튼 비활성, "Cap reached" 표시 |
| Heads-up (2인) | cap 무시, RAISE 계속 활성 |

---

## 8. ALL-IN 버튼

### 활성 조건

| 조건 | 설명 |
|------|------|
| HandFSM ∈ {PRE_FLOP, FLOP, TURN, RIVER} | 베팅 라운드 중 |
| action_on == 현재 플레이어 | 해당 플레이어 차례 |
| player.status == active | 활성 상태 |
| player.stack > 0 | 칩 보유 |

### 비활성 조건

- 핸드 미진행
- player.stack == 0 (이미 올인)
- action_on 아닌 플레이어

### UI 동작

| 항목 | 값 |
|------|-----|
| **단축키** | A |
| **금액 입력** | 불필요 (자동: player.stack 전부) |
| **확인 다이얼로그** | 없음 (즉시 처리) |
| **버튼 라벨** | "ALL-IN {stack}" — 금액 표시 |
| **이벤트** | `AllIn` |
| **결과** | player.status → allin, 스택 → 0, 사이드 팟 생성 가능 |

### 특수 케이스

| 케이스 | CC 반응 |
|--------|---------|
| 올인 금액 < biggest_bet_amt (soft all-in) | 사이드 팟 즉시 생성, Short Call과 동일 처리 |
| 전원 올인 | 남은 보드 자동 딜 (런아웃), SHOWDOWN 직행 |
| 마지막 활성 플레이어 올인 | betting_round_complete, 런아웃 자동 진행 |

---

## 경우의 수 매트릭스

### Matrix 1: HandFSM 상태 × 8버튼 활성/비활성

| HandFSM 상태 | NEW HAND | DEAL | FOLD | CHECK | BET | CALL | RAISE | ALL-IN |
|:-----------:|:--------:|:----:|:----:|:-----:|:---:|:----:|:-----:|:------:|
| **IDLE** | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **SETUP_HAND** | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **PRE_FLOP** | ❌ | ❌ | ✅ | 조건 | 조건 | 조건 | 조건 | ✅ |
| **FLOP** | ❌ | ❌ | ✅ | 조건 | 조건 | 조건 | 조건 | ✅ |
| **TURN** | ❌ | ❌ | ✅ | 조건 | 조건 | 조건 | 조건 | ✅ |
| **RIVER** | ❌ | ❌ | ✅ | 조건 | 조건 | 조건 | 조건 | ✅ |
| **SHOWDOWN** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **RUN_IT_MULTIPLE** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **HAND_COMPLETE** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

> "조건" = biggest_bet_amt, player.current_bet, player.stack, FL raise cap에 따라 결정

### Matrix 2: 베팅 라운드 중 CHECK/BET vs CALL/RAISE 전환

| biggest_bet_amt | player.current_bet | CHECK | BET | CALL | RAISE |
|:--------------:|:-----------------:|:-----:|:---:|:----:|:-----:|
| 0 | 0 | ✅ | ✅ | ❌ | ❌ |
| > 0 | == biggest_bet_amt | ✅ | ❌ | ❌ | ✅ |
| > 0 | < biggest_bet_amt | ❌ | ❌ | ✅ | ✅ |
| == BB (PRE_FLOP) | == BB (BB player) | ✅ (BB option) | ❌ | ❌ | ✅ |

### Matrix 3: 베팅 구조 × 액션 × 금액 범위

| 구조 | FOLD | CHECK | BET 범위 | CALL | RAISE 범위 | ALL-IN |
|:----:|:----:|:-----:|---------|:----:|-----------|:------:|
| **NL** | N/A | N/A | [BB, stack] | 자동 | [min_raise, stack] | stack |
| **PL** | N/A | N/A | [BB, pot+2×BB] | 자동 | [min_raise, pot계산] | stack |
| **FL** | N/A | N/A | 고정값 | 자동 | 고정값 (cap 적용) | stack |

> 참조: 각 구조별 정확한 금액 계산식은 `Holdem/Betting.md` (legacy-id: BS-06-02)

### Matrix 4: 특수 상황별 버튼 동작 변화

| 특수 상황 | 영향 버튼 | 변화 |
|---------|----------|------|
| **Bomb Pot** | NEW HAND | 라벨 "NEW HAND (BOMB)", PRE_FLOP 스킵 |
| **All Fold** | — | 자동 HAND_COMPLETE, 버튼 전환 불필요 |
| **전원 All-In** | 전체 | 모든 액션 버튼 비활성, 자동 런아웃 |
| **FL Cap 도달** | RAISE | 비활성 + "Cap reached" 표시 |
| **Heads-up** | RAISE | FL Cap 무시, 계속 활성 |
| **Short Stack** | BET/RAISE | 최소액 > stack이면 ALL-IN만 활성 |
| **BB Check Option** | CHECK | PRE_FLOP BB에게 체크 허용 |
| **Straddle** | — | 액션 순서 변경 (SB→BB→STR→UTG→...) |

---

## 특수 버튼 (SHOWDOWN 전용)

SHOWDOWN 상태에서는 기본 8버튼 대신 특수 버튼이 표시된다:

| 버튼 | 활성 조건 | 동작 |
|------|----------|------|
| **CHOP** | SHOWDOWN + 2인 이상 남음 | 합의 분배 금액 입력 다이얼로그 |
| **RUN IT 2x** | SHOWDOWN + 올인 상태 | 두 번째 보드 런아웃 |
| **RUN IT 3x** | SHOWDOWN + 올인 상태 + 합의 | 세 번째 보드 런아웃 |
| **MUCK** | SHOWDOWN + 카드 미공개 | 해당 플레이어 카드 비공개 처리 |
| **SHOW** | SHOWDOWN | 해당 플레이어 카드 공개 |
| **MISS DEAL** | 핸드 진행 중 아무 때나 | 확인 다이얼로그 후 핸드 무효화 |

---

## 보조 버튼 (항상 표시)

| 버튼 | 단축키 | 동작 |
|------|:------:|------|
| **UNDO** | Ctrl+Z | 마지막 이벤트 되돌리기 (무제한, 현재 핸드 내) |
| **HIDE GFX** | — | 방송 오버레이 숨김/표시 토글 |
| **TAG HAND** | — | 현재 핸드에 태그 추가 |
| **ADJUST STACK** | — | 특정 플레이어 칩 수동 조정 |

> 참조: UNDO 상세는 `Undo_Recovery.md` (legacy-id: BS-05-05)

---

## 비활성 조건

- Table 상태가 PAUSED/CLOSED일 때 전체 액션 버튼 비활성
- BO 연결 해제 시에도 로컬 Game Engine으로 버튼 동작 유지 (BO 미전송)
- action_on == -1 (액션 대상 없음)일 때 FOLD/CHECK/BET/CALL/RAISE/ALL-IN 비활성

---

## 영향 받는 요소

| 영향 대상 | 이 문서와의 관계 |
|----------|----------------|
| BS-05-01 핸드 라이프사이클 | 각 상태에서 활성 버튼 목록 |
| BS-05-06 키보드 단축키 | 각 버튼의 단축키 매핑 |
| `Holdem/Betting.md` (legacy-id: BS-06-02) | 베팅 액션 유효성·금액 계산 (이 문서의 근거) |
| `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: BS-06-00-triggers))) | CC 이벤트 21종의 UI 트리거 조건 |
| BS-07-overlay | 액션 입력 시 Overlay 반영 |
