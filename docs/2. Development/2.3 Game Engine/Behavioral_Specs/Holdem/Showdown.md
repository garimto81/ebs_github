---
title: Showdown
owner: team3
tier: internal
legacy-id: BS-06-07
last-updated: 2026-04-15
---

# BS-06-07: Hold'em 쇼다운

> **존재 이유**: 쇼다운·hand protection 룰 — BS-06-00-REF §7·Rule 71에서 링크되는 심층 사양.

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-06 | 신규 작성 | Showdown 카드 공개 순서, Muck 규칙, Venue vs Broadcast Canvas 차이 |
| 2026-04-07 | 구조 → 번호 변경 | BS-06-08 → BS-06-09로 재배치 |
| 2026-04-06 | 구조 → Hold'em 전용 | Hold'em 전용으로 변환, BS-06-07로 재배치, Run It Twice 흡수 |
| 2026-04-10 | WSOP P1/P2 규정 반영 | §핸드 보호 & 복구 신설 — Tabled Hand 보호 (Rule 71), Folded Hand 복구 (Rule 110), Muck 카드 재판정 (Rule 109). ManagerRuling 이벤트 참조. CCR-DRAFT-team3-20260410-wsop-conformance P1-8/P2-10 반영 |

---

> **이 문서에서 사용하는 용어**
>
> | 용어 | 설명 |
> |------|------|
> | 홀카드(hole card) | 각 플레이어에게 비공개로 나눠주는 카드 |
> | Muck | 패를 공개하지 않고 버리는 것 |
> | RFID | 무선 주파수로 카드를 자동 인식하는 기술 |
> | CC | Command Center, 운영자가 게임을 제어하는 화면 |
> | Pseudocode | 실제 프로그래밍 언어가 아닌 참고용 가상 코드 |

## 개요

**쇼다운**은 마지막 베팅이 끝나고 모든 활동 중인 플레이어가 자신의 홀카드를 공개하는 단계이다. 공개 순서(Last Aggressor(마지막으로 베팅/레이즈한 플레이어) first), Muck 권리(패배자 카드 비공개 선택), 그리고 **Venue Canvas(현장 관중용 화면 — 카드를 보여주지 않아 공정성 유지) vs Broadcast Canvas(방송 시청자용 화면 — 카드를 보여주어 흥미 유발)의 차이**(신뢰성 vs 시각화)를 정의하는 것이 중요하다. 이 문서는 48개 카드 공개 조합과 각 Canvas별 동작을 명시하여, 운영자와 개발팀이 **올바른 공개 프로토콜을 따를 수 있도록** 한다.

---

## 정의

**카드 공개**는 SHOWDOWN 또는 ALL_IN_RUNOUT 단계에서 플레이어의 홀카드를 가시화하는 프로세스이다.

- **Last Aggressor**: 마지막 베팅/레이즈를 한 플레이어 (공개 우선권)
- **Muck**: 패배자가 카드를 비공개 상태로 유지할 권리
- **Venue Canvas**: 신뢰성 중심 (홀카드 절대 미공개)
- **Broadcast Canvas**: 시각화 중심 (항상 홀카드 표시, 이전 상태 유지)

**핵심 원칙**:
- 공개 순서: last aggressor first, then clockwise
- Muck 권리는 showdown에서만 적용 (all-in 경우 강제 공개)
- Venue와 Broadcast는 홀카드 가시성이 반대

---

## 트리거

### 트리거 소스

| 소스 | 발동 주체 | 처리 시간 | 신뢰도 | 예시 |
|------|---------|---------|--------|------|
| **SHOWDOWN 도달** | 게임 엔진 (자동) | 결정론적 | 최고 | RIVER 베팅 완료 → 2+ 플레이어 남음 |
| **ALL_IN_RUNOUT** | 게임 엔진 (자동) | 결정론적 | 최고 | FLOP/TURN 모두 올인 → 보드 자동 완성 |
| **카드 공개 설정** | Settings 메뉴 | <100ms | 높음 | card_reveal_type, show_type, fold_hide_type 설정 |

---

## 전제조건

### 카드 공개 전제조건

| 필드 | 조건 | 설명 |
|------|------|------|
| **game_state** | SHOWDOWN 또는 ALL_IN_RUNOUT | 최종 단계 도달 |
| **num_remaining_players** | 1+ | 최소 1명 이상 (1명 = showdown 미실행, 우승자 결정) |
| **hole_cards[seat]** | 알려짐 | RFID 또는 수동 입력으로 감지됨 |
| **card_reveal_settings** | 정의됨 | card_reveal_type(0-5), show_type(0-3), fold_hide_type(0-1) |

---

## 유저 스토리

| # | As a | When | Then | Canvas | Reveal Type |
|:-:|------|------|------|--------|-----------|
| 1 | Broadcast 시청자 | SHOWDOWN 진입 | 모든 활동 플레이어 홀카드 즉시 표시 (Last aggressor first) | Broadcast | immediate (0) |
| 2 | Venue 관중 | SHOWDOWN 진입 | 홀카드 절대 미표시, 보드와 핸드 평가 결과만 표시 (신뢰성 중심) | Venue | immediate (0) |
| 3 | Broadcast 시청자 | SHOWDOWN에서 패배자가 Muck 권리 행사 | 패배자 카드 그레이아웃 또는 뒷면 유지 | Broadcast | showdown_cash (4) |
| 4 | Venue 관중 | ALL_IN_RUNOUT (강제 공개) | 패배자도 카드 공개 (Muck 권리 없음) | Venue | immediate (0) |
| 5 | Broadcast 시청자 | 액션 플레이어가 변경될 때 | action_on 플레이어만 강조 표시, 다른 홀카드 흐릿해짐 | Broadcast | action_on (1) |
| 6 | Broadcast 시청자 | 각 플레이어 베팅 후 | 카드 공개 타이밍을 베팅 직후로 설정 (액션 순차 강조) | Broadcast | after_bet (2) |
| 7 | Broadcast 시청자 | 첫 카드 공개 후 다음 플레이어 액션 | 부드러운 카드 공개 전환 (현재 카드 유지 → 다음 카드 공개) | Broadcast | action_on_next (3) |
| 8 | Venue 관중 | SHOWDOWN에서 카드 게시 | 우승자 카드만 최종적으로 공개, 패배자는 비공개 (Muck 기본) | Venue | showdown_tourney (5) |
| 9 | Broadcast 시청자 | 패배자 카드 숨김 | 액션 완료 후 패배자 카드 일괄 숨김 (혼란 방지) | Broadcast | delayed (1, fold_hide) |
| 10 | Broadcast 시청자 | Odd chip 분배 | 홀드카드 공개 후 odd chip 수령자 강조 | Broadcast | showdown_cash (4) |
| 11 | Broadcast 시청자 | Run It Twice 1회차 | 1회차 결과 후 카드 유지, 2회차 전개 | Broadcast | immediate (0) |
| 12 | Venue 관중 | 카드 불일치 (WRONG_CARD) | 오류 표시, 이전 상태 유지 (공개 안 함) | Venue | immediate (0) |

---

## 경우의 수 매트릭스

### 매트릭스 1: 48개 카드 공개 조합

| card_reveal_type (0-5) | show_type (0-3) | fold_hide_type (0-1) | 설명 | Canvas | 유효성 |
|:--------:|:--------:|:--------:|------|--------|--------|
| 0 (immediate) | 0 (immediate) | 0 (immediate) | 즉시 모든 카드 즉시 공개, 폴드 카드 즉시 숨김 | Broadcast | ✅ |
| 0 (immediate) | 0 (immediate) | 1 (delayed) | 모든 카드 즉시 공개, 폴드 카드 액션 완료 후 숨김 | Broadcast | ✅ |
| 0 (immediate) | 1 (action_on) | 0 (immediate) | action_on 카드 강조, 다른 카드는 보조, 폴드 즉시 숨김 | Broadcast | ✅ |
| 0 (immediate) | 1 (action_on) | 1 (delayed) | action_on 카드 강조, 폴드 지연 숨김 | Broadcast | ✅ |
| 0 (immediate) | 2 (after_bet) | 0 (immediate) | 베팅 후 카드 공개, 폴드 즉시 숨김 | Broadcast | ✅ |
| 0 (immediate) | 2 (after_bet) | 1 (delayed) | 베팅 후 카드 공개, 폴드 지연 숨김 | Broadcast | ✅ |
| 0 (immediate) | 3 (action_on_next) | 0 (immediate) | 부드러운 전환, 다음 플레이어 액션 시 카드 변경, 폴드 즉시 숨김 | Broadcast | ✅ |
| 0 (immediate) | 3 (action_on_next) | 1 (delayed) | 부드러운 전환, 폴드 지연 숨김 | Broadcast | ✅ |
| 1 (after_action) | 0-3 | 0-1 | (not used in SHOWDOWN, PRE_FLOP용) | — | ❌ |
| 2 (end_of_hand) | 0-3 | 0-1 | 핸드 완료 후 카드 공개 (가장 보수적) | Venue | ✅ |
| 3 (never) | 0-3 | 0-1 | 절대 공개 안 함 (히든 게임) | Venue | ✅ |
| 4 (showdown_cash) | 0-3 | 0-1 | SHOWDOWN 시만 공개 (캐시 게임) | Broadcast | ✅ |
| 5 (showdown_tourney) | 0-3 | 0-1 | SHOWDOWN 시만 공개 (토너먼트, Muck 적용) | Venue | ✅ |
| **합계** | — | — | **48개** | — | **~32개** |

> **주의**: 모든 48개 조합이 유효한 것은 아니다. 게임 타입과 Canvas에 따라 실질적으로 사용되는 조합은 20-30개.

### 매트릭스 2: Canvas별 홀카드 가시성

| Canvas | card_reveal_type | 시청자 관점 | 신뢰성 | 시각성 |
|--------|:--------:|---------|:-----:|:-----:|
| **Broadcast** | 0-4 (except 2, 3) | 홀카드 **표시됨** | 낮음 (카드 노출, 스포일) | 높음 (흥미로움) |
| **Venue** | 2, 3, 5 (또는 0 ALL_IN_RUNOUT) | 홀카드 **미표시** (showdown_tourney는 Muck 적용) | 높음 (공정성) | 낮음 (실시간 판정만) |

### 매트릭스 3: Muck 규칙 적용

| 상황 | Canvas | Muck 권리 | 카드 공개 | 설명 |
|------|--------|:------:|---------|------|
| **SHOWDOWN (자발 폴드 없음)** | Broadcast | ✅ YES | Optional (플레이어 선택) | 패배자가 카드 비공개 가능 |
| **SHOWDOWN (자발 폴드 없음)** | Venue | ✅ YES | Optional (Muck 기본) | 모든 패배자는 default로 Muck |
| **ALL_IN_RUNOUT** | Broadcast | ❌ NO | Forced | 모든 액티브 플레이어 강제 공개 |
| **ALL_IN_RUNOUT** | Venue | ❌ NO | Forced | 투명성 위해 강제 공개 |
| **강제 공개 요청** | Both | ❌ NO | Forced | 운영자가 "Show" 지시 → 강제 공개 |

### 매트릭스 4: WRONG_CARD 처리

| Canvas | RFID 감지 카드 | 예상 카드 | 시스템 반응 | Broadcast | Venue |
|--------|:--------:|:-------:|---------|---------|------|
| **Broadcast** | 7♠ | A♠ | Mismatch 경고 | 경고 표시, 이전 상태 유지 (카드 변경 안 함) | — |
| **Venue** | 7♠ | A♠ | Mismatch 경고 | — | 에러 표시, 이전 상태 유지 |
| **Both** | 7♠ | A♠ | 사용자 확인 필요 | 수동 입력 선택지 제시 또는 UNDO | UNDO 권장 |

---

## 비활성 조건

### 카드 공개 미실행 조건

- `num_remaining_players == 1` → 모두 폴드, 우승자 결정 (showdown 미실행)
- `card_reveal_type == never (3)` → 절대 공개 불가 (히든 게임)
- `game_state != SHOWDOWN && game_state != ALL_IN_RUNOUT` → 아직 showdown 단계 아님
- `RFID 감지 실패 + WRONG_CARD` → 카드 불일치, 공개 대기 (수동 입력 또는 UNDO)

---

## 영향 받는 요소

### 1. Card Reveal 영향

1. **Overlay**: canvas별로 다른 카드 가시성 표시
2. **hand_evaluation.md**: 카드 공개 순서 기반 핸드 평가 시각화
3. **show_type**: action_on 플레이어 강조 표시
4. **fold_hide_type**: 폴드 카드 숨김 타이밍

### 2. Muck 권리 영향

1. **Settings**: showdown_cash vs showdown_tourney 선택
2. **Venue Canvas**: Muck 기본값, 우승자 카드만 최종 공개
3. **Broadcast Canvas**: 모든 카드 표시 (Muck 무시)

### 3. WRONG_CARD 영향

1. **RFID 감지**: 카드 불일치 감지
2. **UNDO**: 이전 상태 복귀
3. **수동 입력**: 카드 수동 입력 그리드 활성화

### 4. Run It Twice 영향

1. **1회차 공개**: 카드 공개 후 유지 또는 리셋
2. **2회차 공개**: 동일 공개 설정 적용
3. **최종 결과**: 각 런별 카드 공개 후 합산

---

## 데이터 모델 (Pseudo-code)

> 아래는 개발자 참고용 코드입니다.

### ShowdownSettings 구조

```python
class ShowdownSettings:
    # Visibility
    card_reveal_type: int  # 0-5
    show_type: int  # 0-3
    fold_hide_type: int  # 0-1
    
    # Muck
    allow_muck: bool  # showdown_tourney=True, broadcast=False
    muck_default: bool  # True=기본 Muck, False=기본 Show
    
    # Canvas
    canvas_type: str  # "venue" or "broadcast"
    
class CardRevealState:
    revealed_seats: set[int]  # 이미 공개한 플레이어 좌석
    last_aggressor_seat: int  # 마지막 베팅 플레이어
    reveal_order: list[int]  # [last_agg, next_clockwise, ...]
    mocked_seats: dict[int, bool]  # {seat: is_mocked}
    revealed_cards: dict[int, list[Card]]  # {seat: [card1, card2]}
```

### HandState 확장

```python
class HandState:
    # ... 기존 필드 ...
    
    # Showdown Reveal 관련
    showdown_settings: ShowdownSettings
    card_reveal_state: CardRevealState
    last_aggressor_seat: int
    all_in_runout: bool  # True=강제 공개
```

---

## 알고리즘: 카드 공개 순서 (Pseudocode)

```
Input: last_aggressor_seat, num_players, card_reveal_type

1. 공개 순서 결정:
   reveal_order = [last_aggressor_seat]
   
   # Clockwise 순서로 추가
   current_seat = (last_aggressor_seat + 1) % num_players
   while current_seat != last_aggressor_seat:
       if is_active(current_seat):
           reveal_order.append(current_seat)
       current_seat = (current_seat + 1) % num_players
   
2. card_reveal_type별 실행:
   if card_reveal_type == 0 (immediate):
       # 모든 카드 즉시 공개
       for seat in reveal_order:
           show_hole_cards(seat)
   
   elif card_reveal_type == 2 (end_of_hand):
       # 핸드 완료 후 공개
       wait_for_hand_complete()
       for seat in reveal_order:
           show_hole_cards(seat)
   
   elif card_reveal_type == 4 (showdown_cash):
       # SHOWDOWN 시만, Muck 적용
       for seat in reveal_order:
           if not is_mocked(seat):
               show_hole_cards(seat)

3. fold_hide_type별 패배자 카드 처리:
   if fold_hide_type == 0 (immediate):
       hide_fold_cards()  # 즉시 숨김
   elif fold_hide_type == 1 (delayed):
       wait_for_action_complete()
       hide_fold_cards()  # 지연 숨김

Output: revealed_cards {seat: [card1, card2]}
```

---

## 특수 케이스

### 케이스 1: Venue Canvas + Muck

```
Players: A, B, C (C 패배자)
Canvas: Venue (showdown_tourney)
Muck: 기본값 true

→ A (우승자) 카드만 공개
→ B, C 카드 비공개 (Muck 기본값)
```

### 케이스 2: Broadcast Canvas + All-in Runout

```
Players: A, B (all-in FLOP)
Canvas: Broadcast
Board: TURN+RIVER 자동 완성

→ 모든 카드 공개 (ALL_IN_RUNOUT이므로 Muck 무시)
→ 각 카드 타이밍은 show_type 따름 (immediate, action_on, etc.)
```

### 케이스 3: WRONG_CARD + Venue

```
RFID: 7♠ 감지
예상: A♠
Canvas: Venue

→ 경고 표시, 공개 중지
→ 수동 입력 또는 UNDO 선택
→ 재스캔 또는 재입력 후 공개 재진행
```

### 케이스 4: Run It Twice + Broadcast

```
Run 1: 보드 완성 후 카드 공개
Run 2: 보드 리셋 후 재전개

→ Run 1 카드 유지 또는 리셋 (설정)
→ Run 2는 새로운 공개 순서 적용
→ 최종 결과: 각 런별 카드 표시
```

---

## 핸드 보호 & 복구 규정 (WSOP Rules 71, 109, 110)

본 섹션은 WSOP Official Live Action Rules의 Rules 71, 109, 110에 근거하여, 딜러 오류 또는 잘못된 muck 처리로부터 플레이어의 핸드를 보호하고 복구하는 규정을 명시한다.

### Tabled Hand 보호 (Rule 71)

**원칙**: 플레이어가 명시적으로 테이블 위에 카드를 공개한 경우, 딜러 또는 엔진은 해당 핸드를 임의로 kill/muck 처리할 수 없다. 이는 WSOP Rule 71의 "딜러는 테이블 위에 있고 분명히 이기는 패를 죽일 수 없습니다" 조항에 근거한다.

#### Tabled 상태 설정

CC가 `TableHand { seat_index }` 이벤트를 전송하면:

```
state.seats[seat_index].cards_tabled = true
emit OutputEvent.HandTabled { seat_index, cards }
```

**의존 State**: `seat.cards_tabled: bool` 필드가 필요하다 (BS-06-00-REF §2.2 Player 참조).

#### 보호 규칙

이후 엔진이 muck 로직을 수행할 때:

```
for seat in state.seats:
    if seat.cards_tabled:
        # Muck 금지, 카드 정보 보존
        continue
    else:
        apply_muck_logic(seat)
```

#### Winning Hand 자동 수여

Tabled hand 중 명백한 winning hand가 있으면 엔진은 자동으로 pot을 award한다. 딜러/CC의 수동 개입 없이 판정하여 Rule 71 "dealer cannot kill tabled hand" 규정을 보장한다.

---

### Folded Hand 복구 (Rule 110)

**원칙**: 딜러 오류 또는 플레이어에게 제공한 잘못된 정보로 인한 fold는 manager discretion 판정 후 복구 가능하다. 이는 WSOP Rule 110의 "딜러 오류 또는 참가자에게 제공한 잘못된 정보로 인해 접힌 핸드 리트리버블을 규정하기 위해 추가 노력을 기울일 것입니다" 조항에 근거한다.

#### 복구 조건

1. **카드가 완전히 muck에 섞이기 전** (state 추적)
2. **UNDO 5단계 제한 내** (BS-06-01 §예외 처리 UNDO 참조)
3. **ManagerRuling 이벤트로 명시적 승인**

#### 복구 절차

```
CC → ManagerRuling {
    decision: "retrieve_fold",
    target_seat: N,
    rationale: "dealer error"
}

Engine:
    # 1. UNDO로 마지막 Fold 이벤트 취소
    session.undo()
    # 2. 복구 확인
    assert state.seats[N].status == ACTIVE
    # 3. 감사 로그에 ManagerRuling 기록
    emit OutputEvent.HandRetrieved {
        seat: N,
        manager_rationale: "..."
    }
```

#### 복구 실패 조건

| 조건 | 엔진 응답 |
|------|----------|
| 카드가 이미 muck에 섞임 (다음 핸드 시작) | ERROR: "card already mucked" |
| UNDO 5단계 초과 | ERROR: "undo limit exceeded" |
| Fold 이벤트가 아닌 경우 | ERROR: "not a fold event" |
| target_seat가 fold 상태 아님 | ERROR: "seat not in folded state" |

---

### Muck 카드 재판정 (Rule 109)

**원칙**: 기본적으로 muck에 들어간 카드는 dead로 처리되나, 다음 조건을 모두 충족하는 경우 `ManagerRuling` 이벤트로 재판정(retrieve) 할 수 있다. 이는 WSOP Rule 109의 "muck에 던져진 카드는 죽은 것으로 간주될 수 있습니다. 그러나 명확하게 식별할 수 있는 핸드가 게임에 가장 좋은 경우 관리자의 재량에 따라 실시간으로 검색 및 판정될 수 있습니다" 조항에 근거한다.

#### 복구 조건 (AND)

1. **카드 식별 가능**: Muck 시점 RFID 스캔 로그에 카드 정보가 명확히 남아 있음 (`state.muck_log: List<{seat, cards, timestamp}>` 필드 추가 예정)
2. **Winning Hand**: 해당 핸드가 evaluator 기준 명백한 winning hand
3. **Manager 승인**: Manager/Floor 권한의 CC 사용자가 `ManagerRuling` 이벤트 전송

#### 복구 절차

```
CC → ManagerRuling {
    decision: "muck_retrieve",
    target_seat: N,
    rationale: "tabled winning hand mucked by dealer error"
}

Engine:
    # 1. muck_log에서 N의 카드 조회
    cards = state.muck_log.find(seat=N)
    assert cards is not None

    # 2. 해당 seat의 holeCards 복원
    state.seats[N].holeCards = cards
    state.seats[N].status = ACTIVE  # 또는 SHOWDOWN 상태
    state.seats[N].cards_tabled = true  # Rule 71 보호 활성화

    # 3. Showdown 재평가
    run_showdown_evaluation()

    # 4. 감사 로그
    emit OutputEvent.MuckRetrieved {
        seat: N,
        cards,
        rationale
    }
```

#### 복구 불가 조건

- 카드가 이미 다음 덱으로 섞임 (physical 섞임)
- 2개 이상의 seat에서 동시에 muck retrieve 요청
- Hand가 이미 HAND_COMPLETE 상태 (새 핸드 시작 후)

#### Folded Hand 복구 vs Muck Retrieve 차이

| 구분 | Muck 재판정 (Rule 109) | Folded Hand 복구 (Rule 110) |
|------|----------------------|---------------------------|
| 대상 | 이미 muck에 던진 카드 | 폴드 직후, muck 이전 |
| 조건 | Winning hand + 식별 가능 | 딜러 오류 + UNDO 가능 |
| 절차 | muck_log에서 복원 | Session.undo()로 이벤트 취소 |
| 시점 | Showdown 전후 | Fold 직후 |

---

### ManagerRuling 이벤트 참조

본 §핸드 보호 & 복구 규정은 `ManagerRuling` 신규 이벤트를 통해 트리거된다. 이벤트 스키마 상세는 **BS-06-09 이벤트 카탈로그**에 정의 예정이다.

**Manager 권한**: CC의 RBAC에서 Floor/Manager 이상만 `ManagerRuling` 이벤트 전송 허용 (Team 4 관할).

**감사 추적**: 모든 `ManagerRuling` 이벤트는 EventLog에 영구 기록되어, 후일 감사/분쟁 해결에 활용된다.

---

## Run It Twice — 복수 보드 전개

쇼다운 후 보드가 완성되지 않은 상태에서 2명 이상 all-in인 경우, 합의하에 남은 커뮤니티 카드를 **복수 회 전개**하여 팟을 분할하는 규칙이다.

### 활성화 전제조건

| 필드 | 조건 | 설명 |
|------|------|------|
| **special_rules.can_select_run_it_twice** | true | Run It Twice 선택 가능 |
| **game_state** | SHOWDOWN | SHOWDOWN 상태에서만 가능 |
| **num_allin** | 2+ | 2명 이상 all-in |
| **board_cards.length** | < 5 | 보드가 완성되지 않음 |

### 유저 스토리

| # | As a | When | Then | Edge Case |
|:-:|------|------|------|-----------|
| 1 | 운영자 | FLOP에서 모든 플레이어 all-in, 보드 불완성 | 시스템이 "Run It Twice 선택?" 메시지 표시, `can_select_run_it_twice`=true 확인 | 2명 모두 동의해야 진행 |
| 2 | 운영자 | Run It Twice 동의 후 진행 | `run_it_times`=2, `run_it_times_remaining`=2로 설정, 첫 번째 보드 자동 완성 | `run_it_times_board_cards` 추적: 0=from flop, 3=from turn, 4=from river |
| 3 | 운영자 | 첫 번째 런 완료, 승자 판정 | 팟 50% 해당 플레이어 수령, `run_it_times_remaining`=1로 감소 | 1회차 결과 저장 후 2회차 진행 |
| 4 | 운영자 | 두 번째 런 완료 | 전체 payout 합산: 각 런별 팟 비율로 최종 분배 | Split pot 경우 정확한 분배 계산 |
| 5 | 운영자 | Run It Thrice 선택 가능 | `run_it_times`=3으로 설정, 1회→2회→3회 진행 | 3회 모두 동일 winner인 경우 처리 |

### 경우의 수 매트릭스

| can_run_it_twice | game_state | num_allin | board_cards | run_it_times | 결과 |
|:--------:|:--------:|:--------:|:--------:|:--------:|----------|
| ❌ | SHOWDOWN | 2+ | < 5 | — | Run It Twice 옵션 없음 |
| ✅ | SHOWDOWN | 2+ | 0-4 | 2 | 2회 전개 |
| ✅ | SHOWDOWN | 2+ | 3 | 2 | TURN+RIVER 2회 |
| ✅ | SHOWDOWN | 2+ | 4 | 2 | RIVER 2회 |
| ✅ | SHOWDOWN | 2 | 5 | — | 보드 완성됨, Run It Twice 불가 |
| ✅ | SHOWDOWN | 1 | < 5 | — | 1인만 남음, Run It Twice 불필요 |

### 비활성 조건

- `special_rules.can_select_run_it_twice == false` → 선택 불가능
- 게임 상태가 SHOWDOWN이 아님 → 아직 보드 공개 진행 중
- `num_allin < 2` → 1인 또는 올인 미발생
- `board_cards.length == 5` → 보드 완전히 공개됨, 남은 보드 없음

### 데이터 모델

```python
class RunItTwiceState:
    can_select_run_it_twice: bool = False
    run_it_times: int = 0          # 0=미사용, 2=2회, 3=3회
    run_it_times_remaining: int = 0  # 남은 횟수
    run_it_times_board_cards: list[list[int]] = []  # 각 런별 보드 카드 저장
```

### 카드 공개 처리

- **1회차**: 보드 완성 후 카드 공개, 승자 판정, 팟 1/N 분배
- **2회차**: 보드 리셋 후 재전개, 동일 공개 설정 적용
- **최종 결과**: 각 런별 카드 공개 후 합산
