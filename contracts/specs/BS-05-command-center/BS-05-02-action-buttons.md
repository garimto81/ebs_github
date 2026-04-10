# BS-05-02 Command Center — 액션 버튼 명세

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 8개 액션 버튼 완전 명세, HandFSM×버튼 매트릭스, 베팅 구조별 금액 범위 |

---

## 개요

CC 하단에 배치된 8개 액션 버튼은 운영자가 게임을 진행하는 핵심 입력 수단이다. 각 버튼의 활성/비활성은 현재 HandFSM 상태, action_on 플레이어, biggest_bet_amt, player.stack 등 게임 상태 변수에 의해 결정론적으로 결정된다.

> 참조: 베팅 액션의 유효성 규칙·금액 계산·상태 변경은 BS-06-02-holdem-betting.md에서 정의한다. 이 문서는 **CC UI에서 버튼이 어떻게 보이고 동작하는가**에 집중한다.

---

## 정의

**액션 버튼**: CC 하단 액션 패널에 배치된 8개 버튼. 운영자가 클릭하거나 단축키로 입력하면 Game Engine에 해당 이벤트를 전송한다.

**동적 전환**: 게임 상태에 따라 버튼 라벨·활성 여부·표시 금액이 자동으로 변경된다. 예: biggest_bet_amt == 0이면 CHECK/BET 표시, > 0이면 CALL/RAISE 표시.

---

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

> **CCR-024**: NEW HAND 버튼 클릭 시 CC는 `WriteGameInfo` WebSocket 프로토콜을 BO에 발행한다. 24 필드(`dealer_seat`, `sb_seat`, `bb_seat`, `blind_structure_id`, `active_seats`, `dead_button_mode` 등) 전체 스키마와 검증 규칙은 **`API-05-websocket-events.md §9 WriteGameInfo`** 참조.

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
| **금액 입력** | **필요** — 숫자 입력 패드 슬라이드업 |
| **확인 다이얼로그** | Enter 키로 금액 확정 |
| **이벤트** | `Bet(amount)` |
| **결과** | biggest_bet_amt = amount, 팟 갱신, action_on → 다음 |

### 금액 범위 (베팅 구조별)

> 참조: 금액 계산 상세는 BS-06-02-holdem-betting.md §3. BET

| 베팅 구조 | 최소 | 최대 |
|----------|------|------|
| **NL** | big_blind | player.stack |
| **PL** | big_blind | pot + 2 × big_blind |
| **FL** | low_limit (PRE_FLOP/FLOP), high_limit (TURN/RIVER) | 고정값 (선택 불가) |

### Quick Bet 프리셋

| 프리셋 | 계산 |
|--------|------|
| MIN | big_blind (최소 베팅) |
| 1/2 POT | pot / 2 |
| POT | pot |
| ALL-IN | player.stack |

### 금액 검증

| 입력값 | CC 반응 |
|--------|---------|
| amount < min | "최소 베팅액은 X칩입니다" 경고, 재입력 |
| amount > max | "최대 베팅액은 X칩입니다" 경고, 재입력 |
| amount == 0 | "0 베팅 불가" 경고, 재입력 |
| amount > stack | 자동 ALL-IN으로 전환 |

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

> 참조: Short Call 상세는 BS-06-02-holdem-betting.md §4. CALL

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
| **금액 입력** | **필요** — 숫자 입력 패드 슬라이드업 (최소~최대 범위 표시) |
| **확인 다이얼로그** | Enter 키로 금액 확정 |
| **버튼 라벨** | "RAISE TO" |
| **이벤트** | `Raise(amount)` |
| **결과** | biggest_bet_amt 갱신, 다른 플레이어 재액션 필요 |

### 금액 범위 (베팅 구조별)

> 참조: 금액 계산 상세는 BS-06-02-holdem-betting.md §5. RAISE

| 베팅 구조 | 최소 (min_raise_total) | 최대 |
|----------|----------------------|------|
| **NL** | biggest_bet_amt + max(BB, last_raise_increment) | player.stack + player.current_bet |
| **PL** | biggest_bet_amt + call_amount | pot + call_amount + biggest_bet_amt + call_amount |
| **FL** | 고정값 (low_limit 또는 high_limit) | 고정값 (선택 불가) |

### Quick Raise 프리셋

| 프리셋 | 계산 |
|--------|------|
| MIN RAISE | min_raise_total |
| 1/2 POT | pot / 2 + call_amount |
| POT | pot + call_amount |
| ALL-IN | player.stack + player.current_bet |

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

> 참조: 각 구조별 정확한 금액 계산식은 BS-06-02-holdem-betting.md

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
| **UNDO** | Ctrl+Z | 마지막 이벤트 되돌리기 (최대 5단계) |
| **HIDE GFX** | — | 방송 오버레이 숨김/표시 토글 |
| **TAG HAND** | — | 현재 핸드에 태그 추가 |
| **ADJUST STACK** | — | 특정 플레이어 칩 수동 조정 |

> 참조: UNDO 상세는 BS-05-05-undo-recovery.md

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
| BS-06-02-holdem-betting | 베팅 액션 유효성·금액 계산 (이 문서의 근거) |
| BS-06-00-triggers | CC 이벤트 21종의 UI 트리거 조건 |
| BS-07-overlay | 액션 입력 시 Overlay 반영 |
