---
title: Manual Card Input
owner: team4
tier: internal
legacy-id: BS-05-04
last-updated: 2026-04-15
confluence-page-id: 3818816201
confluence-parent-id: 3811901565
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818816201/EBS+Manual+Card+Input
---

# BS-05-04 Command Center — 수동 카드 입력

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 카드 그리드 UI, 홀카드/보드 입력, 취소/되돌리기, RFID 폴백 전환 |
| 2026-04-13 | UI-02 redesign | 합성 카드 선택으로 변경 (4×13 수트×랭크 → 합성 카드 이미지) |
| 2026-04-15 | 구현 계약 보강 | §6.4.1 AT-03 자동 오픈 규칙 (트리거·타이틀·중복·닫기), §6.5 타이머/슬롯 경계 규칙 (재시작·DEALT 후 동작·WRONG_CARD 1초 auto-revert·`requestManualForSlot`) |
| 2026-05-07 | v4 cascade | CC_PRD v4.0 정체성 정합 — **M 키 (Menu/Manual)** 가 Manual Card Input 진입 키로 신설. 6 키 카탈로그의 비상 키. §"v4.0 M 키 진입 흐름" 신설. SSOT: `docs/1. Product/Command_Center.md` v4.0 §Ch.5. |

---

## 개요

CC에서 운영자가 카드를 수동으로 지정하는 UI. RFID Real 모드에서 카드 감지 실패 시 폴백으로 사용되며, Mock 모드에서는 유일한 카드 입력 수단이다. 52장(4수트 × 13랭크) 카드 그리드에서 선택하거나, 키보드 단축키(수트+랭크)로 입력한다.

> 참조: RFID 자동 입력과 수동 폴백의 경계 규칙은 `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: BS-06-00-triggers)))) §3, Mock 모드 이벤트 합성은 §4

---

## v4.0 M 키 진입 흐름 (2026-05-07 신설)

> **트리거**: `docs/1. Product/Command_Center.md` v4.0 cascade. ActionPanel 의 6 키 (N·F·C·B·A·M) 중 **M 키 = Menu / Manual / Miss Deal** 비상 키. Manual Card Input 진입 흐름.

### M 키 활성 phase

| Phase | M 키 동작 | 비고 |
|-------|-----------|------|
| IDLE | (disabled) | 핸드 시작 전 |
| PRE_FLOP / FLOP / TURN / RIVER | **Miss Deal 또는 Manual Card 진입 메뉴** | 카드 슬롯 클릭으로 직접 진입 가능 (M 키 없이) |
| SHOWDOWN / HAND_COMPLETE | (disabled) | 카드 입력 종료 |

### M 키 → Manual Card Input 흐름

```
M 키 누름 (or 카드 슬롯 클릭)
  │
  ▼
+------------------------+
| Menu / Manual          |
|  - Miss Deal           |
|  - Manual Card Entry   |
|    (홀카드 / Board)     |
+------------------------+
  │
  ▼
AT-03 Card Selector 모달 (560×auto)
  - 합성 카드 그리드 (4 행 × 13 열)
  - 사용된 카드 비활성 (opacity 0.3)
  - 선택 → Confirm → CardDetected 합성
```

### M 키 + RFID Mock/Real 모드 매트릭스

| RFID 모드 | M 키 의도 | 실행 흐름 |
|-----------|-----------|----------|
| **Real (정상)** | Miss Deal (재시도) | Engine 에 MissDeal 이벤트, 카드 폐기 |
| **Real (감지 실패)** | Manual Fallback | AT-03 Card Selector → 운영자 수동 입력 |
| **Mock** | Manual Entry (유일 수단) | AT-03 Card Selector → CardDetected 합성 |

### 자매 문서 정합

- `Action_Buttons.md §"v4.0 6 키 매핑"` — M 키 정의 SSOT
- `Keyboard_Shortcuts.md §"v4.0 6 키 단축키 표준"` — M 키 단축키
- `RFID_Cards/Manual_Fallback.md` — RFID 실패 시 M 키 폴백

---

## 정의

| 용어 | 정의 |
|------|------|
| **수동 카드 입력** | RFID 없이 운영자가 CC UI에서 직접 카드를 지정하는 행위 |
| **카드 그리드** | 4×13 배열의 52장 카드 선택 패널 |
| **Mock HAL** | RFID 하드웨어 없이 동일 이벤트 스트림을 생성하는 소프트웨어 에뮬레이터 |
| **CardDetected 합성** | 수동 입력을 RFID CardDetected 이벤트로 변환하여 Game Engine에 전달 |

---

## 트리거

| 트리거 | 발동 주체 | 설명 |
|--------|----------|------|
| `ManualCardInput` | 운영자 (CC) | 카드 그리드에서 카드 선택 |
| 키보드 수트+랭크 | 운영자 (CC) | 단축키로 카드 지정 (예: `s` + `A` = Ace of Spades) |

> 수동 입력된 카드는 MockRfidReader.injectCard()를 통해 CardDetected 이벤트로 합성된다. Game Engine은 Real/Mock 카드를 구분하지 않는다.

---

## 전제조건

| 조건 | 설명 |
|------|------|
| 카드 입력 모드 활성 | 홀카드 딜 단계 또는 보드 카드 입력 단계 |
| HandFSM ∈ {SETUP_HAND, PRE_FLOP, FLOP, TURN, RIVER} | 카드가 필요한 상태 |
| RFID 미감지 또는 Mock 모드 | Real 모드 자동 감지 성공 시 수동 입력 불필요 |

---

## 1. 카드 그리드 UI

### 합성 카드 선택 (변경)

> **기존**: 4행(수트) × 13열(랭크)로 수트와 랭크를 분리하여 교차점 탭.
> **변경**: 각 셀이 "A♠", "K♥" 같은 **합성 카드** 이미지/텍스트. 즉시 시각 식별 가능.

| 항목 | 값 |
|------|---|
| 셀 크기 | 60 × 72 px (터치 최적화, 기존 48×56에서 확대) |
| 선택 방식 | 1탭 선택, 파란 테두리 하이라이트 |
| 사용된 카드 | opacity 0.3 + ✕ 표시 |
| 1회 선택 | 1장만. 여러 장 필요 시 반복 진입 |
| Confirm | 선택 확정 → CardDetected 이벤트 합성 |
| Cancel | 선택 취소 → 메인 복귀 |

### 1.2 카드 상태별 시각 처리

| 상태 | 시각 | 클릭 가능 |
|------|------|:--------:|
| **사용 가능** | 합성 카드 이미지 (수트+랭크 조합) | ✅ |
| **이미 사용됨** | opacity 0.3 + ✕ 표시 | ❌ |
| **현재 선택 중** | 파란 테두리 하이라이트 | ✅ (클릭 시 선택 해제) |
| **이번 슬롯 후보** | 노란 테두리 | ✅ |

### 1.3 중복 방지

한 핸드 내에서 동일 카드는 1회만 사용 가능:

- 이미 홀카드로 배분된 카드 → 그리드에서 비활성
- 이미 보드에 놓인 카드 → 그리드에서 비활성
- 중복 선택 시도 → "이미 사용된 카드입니다" 경고

---

## 2. 홀카드 입력

### 2.1 입력 흐름

| 단계 | 운영자 액션 | CC 반응 |
|:----:|------------|---------|
| 1 | 좌석 클릭 (또는 Tab으로 좌석 이동) | 해당 좌석의 카드 슬롯 활성화 |
| 2 | 카드 그리드에서 1번째 카드 선택 | 슬롯 1에 카드 표시 |
| 3 | 2번째 카드 선택 | 슬롯 2에 카드 표시 |
| 4 | 자동으로 다음 좌석 이동 (또는 Tab) | 다음 활성 좌석의 카드 슬롯 활성화 |
| 5 | 전체 플레이어 홀카드 완료 | Engine이 HoleCardsDealt 발행 → PRE_FLOP 전이 |

### 2.2 좌석 순서

딜러 좌측부터 시계 방향으로 자동 순환:
- SB → BB → UTG → ... → BTN (딜러)

### 2.3 키보드 입력

수트 키 + 랭크 키 조합으로 빠른 입력:

| 키 | 수트/랭크 |
|:--:|---------|
| s | ♠ Spades |
| h | ♥ Hearts |
| d | ♦ Diamonds |
| c | ♣ Clubs |
| 2~9 | 해당 숫자 |
| T | 10 |
| J | Jack |
| Q | Queen |
| K | King |
| A | Ace |

**입력 예시**: `sA` = Ace of Spades, `hT` = Ten of Hearts

> 참조: 키보드 단축키 전체 맵은 `Keyboard_Shortcuts.md` (legacy-id: BS-05-06)

---

## 3. 보드 카드 입력

### 3.1 입력 흐름

| 스트리트 | 입력 카드 수 | 운영자 액션 |
|---------|:----------:|------------|
| **Flop** | 3장 | 테이블 중앙 보드 영역 클릭 → 카드 3장 순서대로 선택 |
| **Turn** | 1장 | 4번째 슬롯 클릭 → 카드 1장 선택 |
| **River** | 1장 | 5번째 슬롯 클릭 → 카드 1장 선택 |

### 3.2 보드 슬롯 상태

| 슬롯 | PRE_FLOP | FLOP | TURN | RIVER |
|:----:|:--------:|:----:|:----:|:-----:|
| 1~3 | 점선 (비어있음) | 카드 표시 | 카드 표시 | 카드 표시 |
| 4 | 점선 | 점선 | 카드 표시 | 카드 표시 |
| 5 | 점선 | 점선 | 점선 | 카드 표시 |

### 3.3 자동 스트리트 전이

보드 카드가 올바른 수만큼 입력되면 Engine이 자동으로 스트리트를 전이한다:
- Flop 3장 완료 → FLOP 상태 진입
- Turn 1장 완료 → TURN 상태 진입
- River 1장 완료 → RIVER 상태 진입

---

## 4. 입력 취소/되돌리기

### 4.1 개별 카드 취소

| 동작 | 방법 | 결과 |
|------|------|------|
| 마지막 입력 카드 취소 | Backspace 키 | 마지막 카드 제거, 그리드에서 다시 사용 가능 |
| 특정 카드 취소 | 이미 입력된 카드 슬롯 클릭 | 해당 카드 제거 |
| 전체 취소 | Esc 키 | 카드 그리드 닫기, 입력 전 상태로 복귀 |

### 4.2 보드 카드 취소

| 스트리트 | 취소 가능 | 조건 |
|---------|:--------:|------|
| Flop (3장) | ✅ | 아직 베팅 라운드 시작 전 |
| Turn (1장) | ✅ | 아직 베팅 라운드 시작 전 |
| River (1장) | ✅ | 아직 베팅 라운드 시작 전 |
| 베팅 시작 후 | ❌ | UNDO로만 가능 (BS-05-05 참조) |

### 4.3 홀카드 재입력

| 동작 | 방법 |
|------|------|
| 특정 좌석 카드 재입력 | 해당 좌석 카드 슬롯 클릭 → 기존 카드 제거 → 새 카드 선택 |
| 전체 재딜 | MISS DEAL → 새 핸드 |

---

## 5. RFID 자동 입력과의 전환

### 5.1 Real 모드 폴백

| 단계 | 조건 | CC 반응 |
|:----:|------|---------|
| 1 | RFID CardDetected 대기 중 | 카드 슬롯 노란 펄스 (감지 대기) |
| 2 | 일정 시간 미감지 (5초) | "수동 입력 가능" 안내 + 카드 그리드 버튼 표시 |
| 3 | 운영자가 카드 그리드 열기 | 수동 입력 모드 전환 |
| 4 | 수동 입력 완료 후 RFID 감지 | **RFID 우선** — 수동 입력 무시, RFID 결과 사용 |

### 5.2 혼합 입력

Real 모드에서 부분적 RFID 실패 시:

| 시나리오 | 처리 |
|---------|------|
| 홀카드 2장 중 1장만 RFID 감지 | 나머지 1장 수동 입력 허용 |
| Flop 3장 중 2장만 RFID 감지 | 나머지 1장 수동 입력 허용 |
| RFID + 수동 동시 감지 (동일 카드) | RFID 우선, 수동 무시 |
| RFID + 수동 동시 감지 (다른 카드) | RFID 우선, CARD_CONFLICT 경고 |

> 참조: CC vs RFID 동시 발생 상세는 `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: BS-06-00-triggers)))) §3

### 5.3 Mock 모드

Mock 모드에서는 RFID 대기 없이 즉시 카드 그리드가 활성화된다:

| 항목 | Real 모드 | Mock 모드 |
|------|----------|----------|
| RFID 대기 | 있음 (5초) | 없음 |
| 카드 그리드 초기 상태 | 숨김 (RFID 대기) | 즉시 표시 |
| CardDetected 이벤트 | RFID HAL 발행 | MockRfidReader.injectCard() 합성 |
| 중복 방지 | 동일 | 동일 |

---

## 유저 스토리

| # | As a | When | Then |
|:-:|------|------|------|
| 1 | 운영자 | Mock 모드에서 좌석 클릭 | 카드 그리드 즉시 표시, 2장 선택 |
| 2 | 운영자 | 카드 그리드에서 As 선택 | 슬롯에 Ace of Spades 표시, 그리드에서 As 비활성 |
| 3 | 운영자 | 키보드로 `hK` 입력 | King of Hearts 선택, 슬롯에 표시 |
| 4 | 운영자 | 이미 사용된 카드 클릭 | "이미 사용된 카드입니다" 경고, 무시 |
| 5 | 운영자 | Backspace로 마지막 카드 취소 | 마지막 카드 제거, 그리드에서 다시 사용 가능 |
| 6 | 운영자 | Flop 3장 수동 입력 완료 | FLOP 스트리트 자동 진입, 베팅 시작 |
| 7 | 운영자 | Real 모드에서 RFID 5초 미감지 | "수동 입력 가능" 안내, 카드 그리드 버튼 표시 |
| 8 | 운영자 | 수동 입력 중 RFID가 카드 감지 | RFID 결과 우선 사용, 수동 입력 무시 |
| 9 | 운영자 | 보드 카드 입력 후 베팅 전 Esc | 보드 카드 취소, 재입력 가능 |
| 10 | 운영자 | 전체 플레이어 홀카드 수동 입력 완료 | PRE_FLOP 자동 전이 |

---

## 비활성 조건

- HandFSM == IDLE / HAND_COMPLETE일 때 카드 입력 불가
- HandFSM == SHOWDOWN일 때 카드 입력 불가 (이미 모든 카드 확정)
- Real 모드 + RFID 정상 동작 시 수동 입력 그리드 숨김 (폴백 시에만 표시)

---

## 영향 받는 요소

| 영향 대상 | 이 문서와의 관계 |
|----------|----------------|
| BS-05-01 핸드 라이프사이클 | 카드 입력 완료 시 스트리트 전이 |
| BS-05-05 Undo/복구 | 카드 입력 Undo 범위 |
| BS-05-06 키보드 단축키 | 수트+랭크 단축키 매핑 |

---

## 6. 카드 슬롯 5상태 FSM (CCR-032, W10 해소)

### 6.1 FSM 다이어그램

```
EMPTY ──RFID 신호──▶ DETECTING ──매핑 성공(≤5s)──▶ DEALT
  │                        │
  │                        ├──매핑 실패(>5s)──▶ FALLBACK → AT-03 자동 진입
  │                        │
  │                        └──중복 UID──▶ WRONG_CARD (#DD0000)
  │
  └──운영자 클릭──▶ AT-03 수동 진입
```

### 6.2 상태별 시각 규격

| 상태 | 시각 | 색상 코드 | 애니메이션 |
|------|------|----------|----------|
| EMPTY | 점선 테두리 빈 슬롯 | — | 없음 |
| DETECTING | 노란 펄스 애니메이션 | `#FFD600` | `detect-pulse 0.6s infinite alternate` |
| DEALT | 카드 이미지 표시 | — | 0.2s fade-in |
| FALLBACK | AT-03 모달 자동 열림 | — | 모달 slide-up 0.3s |
| WRONG_CARD | 빨간 테두리 + 경고 아이콘 | `#DD0000` | 0.4s shake |

### 6.3 RFID 5초 대기 의미 (W10 해소)

> 5초는 **카드 슬롯당 독립 측정**한다. 슬롯이 DETECTING 상태로 진입한 시점부터 5초 경과 시 FALLBACK으로 전이한다.

**예시**: Seat 1 홀카드가 1번째 슬롯은 즉시 감지(DEALT), 2번째 슬롯은 미감지 상태라면:
- Seat 1 1번째: 즉시 DEALT
- Seat 1 2번째: DETECTING 진입 후 5초 대기 → FALLBACK (AT-03 자동 진입)
- Seat 2 홀카드: 독립 타이머로 동작 (Seat 1 타이머에 영향받지 않음)

### 6.4 AT-03 Card Selector 모달 (CCR-028)

AT-01 Main의 카드 슬롯을 탭하거나 FALLBACK 상태로 전이하면 **AT-03 Card Selector 모달**이 열린다.

- **크기**: 560×auto
- **선택 단위**: 1회 진입에 1장만 선택 가능. 여러 장이 필요하면 반복 진입.
- **OK**: 서버에 선택 카드 전송 후 AT-01로 복귀
- **Back / Esc**: 전송 없이 AT-01로 복귀
- **이미 사용된 카드**: 흐리게 표시(opacity 0.4), 선택 불가

**예시**: TURN 상태에서 SEAT1(2장) + SEAT2(2장) + 보드(3장) = 7장이 흐리게 표시되고, 나머지 45장만 선택 가능.

#### 6.4.1 자동 오픈 규칙 (구현 계약)

CC 코드(`at_01_main_screen.dart`) 가 `cardInputProvider` 를 listen 하여 다음 규칙으로 모달을 띄운다.

| 항목 | 규칙 |
|------|------|
| 자동 오픈 트리거 | 어느 슬롯이 `CardSlotStatus.fallback` 으로 **전이하는 최초 순간 1회** 호출 |
| 모달 타이틀 | `"Select Card — Seat {seatNo} Slot {i+1}"` (slot index 는 1-based 표시) |
| 중복 진입 가드 | `_isFallbackModalOpen` 플래그 유지. 모달이 열려 있는 동안 다른 슬롯 fallback 전이는 큐잉 X (먼저 닫힌 후 다시 listen 으로 처리) |
| 진행 중 슬롯 변경 요청 | 운영자가 다른 슬롯을 탭해 새 모달 요청 → 기존 모달 dismiss + 새 모달 open. 다이얼로그 스택 쌓지 않음 |
| `Cancel` / `ESC` 동작 | 슬롯은 FALLBACK 상태 유지(카드 미주입). 운영자가 다시 탭하면 재오픈 |
| 카드 선택 확정 | `cardInputProvider.manualSelect(slotIndex, suit, rank)` 호출 후 모달 dismiss |
| 다음 슬롯 자동 이동 | **하지 않는다**. 운영자가 명시적으로 다음 슬롯을 탭해야 다음 DETECTING / 모달이 시작. 근거: hole card 순서 오류 방지 |

### 6.5 타이머 / 슬롯 경계 규칙 (구현 계약)

`CardInputNotifier` 의 슬롯별 5초 타이머가 다음과 같이 결정적으로 동작한다.

| 사건 | 동작 |
|------|------|
| `startDetecting(index)` 호출 | DETECTING 진입 + 5초 타이머 시작 |
| DETECTING 중 `startDetecting(index)` 재호출 | 기존 타이머 `cancel()` + 새 5초 타이머 시작 |
| 타이머 만료 (>5s, 카드 미감지) | `CardSlotStatus.fallback` 전이 (§6.4.1 자동 오픈 트리거) |
| `cardDetected(index, suit, rank)` 정상 매핑 | 타이머 취소 + DEALT 전이. **다음 슬롯 자동 진행 X** (운영자 탭 대기) |
| `cardDetected` dupe 감지 | `CardSlotStatus.wrongCard` 전이 + 1초 자동 복귀 타이머. 1초 후 직전 상태(DETECTING 또는 EMPTY) 로 복귀하여 재시도 가능 |
| `clearSlot(index)` | 타이머 취소 + EMPTY 전이 |
| `requestManualForSlot(index)` (신규) | RFID 장애 상태에서 호출 시 5초 대기 생략 + **즉시** FALLBACK 전이. §Manual_Fallback §5.5 매핑과 연동 |

> **WRONG_CARD 1초 auto-revert** 는 운영자가 동일 카드 두 번 탭한 경우의 회복 경로. 1초 동안 빨강 shake 노출 → 자동으로 DETECTING 또는 EMPTY 로 복귀해 다음 카드 입력이 자연스럽다.

| `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: BS-06-00-triggers))) | RFID vs CC 카드 입력 경계 규칙 |
| BS-04-rfid (추후) | RFID HAL 인터페이스, Mock HAL 합성 |
