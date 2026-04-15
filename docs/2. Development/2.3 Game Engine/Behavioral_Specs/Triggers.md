---
title: Triggers
owner: team3
tier: internal
legacy-id: BS-06-00-triggers
last-updated: 2026-04-15
---

# BS-06-00 Triggers — CC/RFID/Engine 트리거 경계 정의

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 4소스 이벤트 분류, Mock 합성 규칙, 충돌 해결, 순서 보장 |
| 2026-04-13 | 설명 보강 + WSOP LIVE 매핑 | 모든 이벤트 친절한 설명 추가, 시팅 트리거 6개 추가, SeatFSM/TableFSM 매트릭스, WSOP LIVE 매핑 |
| 2026-04-13 | Clock 트리거 추가 | §2.4 BO: ClockStarted/Paused/Resumed + §2.5 Auto Blind-Up 로직. BS-06-02-clock.md 흡수·삭제 |
| 2026-04-14 | CCR-050 | §2.5 Clock 트리거에 `ClockRestarted`/`clock_detail_changed`/`clock_reload_requested`/`stack_adjusted`/`tournament_status_changed` 5종 추가. WSOP LIVE SignalR Hub 정렬 (SSOT Page 1651343762, 3728441546, 1793328277) |

---

## 개요

이 문서는 **어떤 이벤트가 누구에 의해 발동되는가**를 모든 경우의 수에 대해 정의한다. EBS의 4가지 이벤트 소스(CC, RFID, Engine, BO) 사이의 경계가 모호한 상황을 명시적으로 해결하며, Mock 모드에서 RFID 이벤트를 어떻게 합성하는지 규칙을 제공한다.

> **참조**: 용어·상태·FSM 정의는 `BS-00-definitions.md`, Enum 값 상세는 `BS-06-00-REF-game-engine-spec.md`, 핸드 라이프사이클 FSM은 `BS-06-01-holdem-lifecycle.md`

---

## 정의

**트리거**는 시스템 상태를 변경하는 입력 이벤트다. 모든 트리거는 반드시 하나의 발동 소스에 귀속된다.

---

## 1. 4소스 정의

> 참조: BS-00 §4 트리거 3소스 + BO 소스

| 소스 | 주체 | 처리 시간 | 신뢰도 | 채널 |
|------|------|---------|--------|------|
| **CC** | 운영자 (수동) | 즉시 (<50ms) | 낮음 (인간 오류 가능) | CC Flutter → Game Engine |
| **RFID** | 시스템 (자동) | 변동 (50~150ms) | 높음 (하드웨어) | RFID HAL → CC → Game Engine |
| **Engine** | 시스템 (자동) | 결정론적 (<10ms) | 최고 (규칙 기반) | Game Engine 내부 |
| **BO** | 시스템 (자동) | 변동 (100~500ms) | 높음 | BO WebSocket → CC/Lobby |

---

## 2. 이벤트 분류표 — 전체 카탈로그

### 2.1 CC 소스 이벤트 (운영자 수동)

운영자가 CC에서 버튼/키보드/터치로 발동하는 이벤트.

| 이벤트 | 트리거 조건 | 대상 FSM | 설명 |
|--------|-----------|---------|------|
| `StartHand` | IDLE 상태 + precondition 충족 | HandFSM | NEW HAND 버튼 |
| `Deal` | SETUP_HAND 상태 | HandFSM | 홀카드 딜 시작 |
| `Fold` | action_on == 해당 플레이어 | HandFSM | 카드 포기 |
| `Check` | biggest_bet_amt == 해당 플레이어 베팅액 | HandFSM | 패스 |
| `Bet` | biggest_bet_amt == 0 (첫 베팅) | HandFSM | 금액 입력 후 확인 |
| `Call` | biggest_bet_amt > 해당 플레이어 베팅액 | HandFSM | 콜 (동일 금액 맞추기) |
| `Raise` | biggest_bet_amt > 0 (기존 베팅 존재) | HandFSM | 추가 베팅 |
| `AllIn` | 스택 전부 베팅 | HandFSM | 올인 |
| `Undo` | hand_in_progress == true | HandFSM | 이전 이벤트 되돌리기 (최대 5단계) |
| `ManualNextHand` | HAND_COMPLETE 상태 | HandFSM | 다음 핸드로 이동 |
| `ManualCardInput` | 카드 입력 모드 활성 | — | 수동으로 카드 지정 (suit+rank) |
| `SeatAssign` | Table SETUP/LIVE | SeatFSM | 플레이어 좌석 배치 |
| `SeatVacate` | Seat OCCUPIED | SeatFSM | 플레이어 좌석 해제 |
| `SeatMove` | 두 Seat 간 이동 | SeatFSM | 플레이어 좌석 이동 |
| `PauseTable` | Table LIVE | TableFSM | 테이블 일시 중단 |
| `ResumeTable` | Table PAUSED | TableFSM | 테이블 재개 |
| `CloseTable` | Table LIVE/PAUSED | TableFSM | 테이블 종료 |
| `SetBombPot` | IDLE 상태 | HandFSM | Bomb Pot 모드 설정 (PRE_FLOP 스킵) |
| `SetRunItTimes` | SHOWDOWN 진입 전 올인 시 | HandFSM | Run It Multiple 횟수 설정 |
| `ConfirmChop` | HAND_COMPLETE 진입 전 | HandFSM | 칩 합의 분배 확인 |
| `RegisterDeck` | Deck UNREGISTERED | DeckFSM | 덱 등록 시작 (RFID 스캔 또는 Mock 자동) |
| `SeatReserve` | Table SETUP/LIVE, Seat EMPTY | SeatFSM | 좌석 예약 (배치 제외) |
| `SeatRelease` | Seat RESERVED | SeatFSM | 좌석 예약 해제 |
| `PlayerEliminate` | Seat OCCUPIED/PLAYING | SeatFSM | 플레이어 탈락 처리 (Bust 요청) |
| `UpdateChips` | hand_in_progress == false, Seat PLAYING | — | 칩 수량 수동 변경 |

#### 1. StartHand (핸드 시작: 새로운 판 시작)
**조건** (IDLE 상태 + precondition 충족): 현재 테이블이 대기 상태(IDLE)이고, 최소 2명의 플레이어가 착석해 있으며, 덱이 등록된 상태여야 합니다.

**설명**: 운영자가 'NEW HAND' 버튼을 눌러 새로운 판을 시작하는 액션입니다. 이 버튼을 누르면 딜러 위치가 이동하고, 블라인드가 자동으로 수집되는 준비 단계(SETUP_HAND)로 넘어갑니다.

#### 2. Deal (딜: 홀카드 배분 시작)
**조건** (SETUP_HAND 상태): 블라인드 수집이 완료되어 SETUP_HAND 상태여야 합니다.

**설명**: 운영자가 딜을 시작하는 액션입니다. RFID 모드라면 딜러가 카드를 돌릴 때 안테나가 자동 인식하고, Mock 모드라면 운영자가 수동으로 카드를 입력합니다.

#### 3. Fold (폴드: 카드 포기)
**조건** (action_on == 해당 플레이어): 현재 차례인 플레이어만 폴드할 수 있습니다.

**설명**: 플레이어가 카드를 포기하는 액션입니다. 더 이상의 금전적 손실 없이 해당 핸드에서 빠집니다. 남은 플레이어가 1명이면 즉시 핸드가 종료됩니다.

#### 4. Check (체크: 패스)
**조건** (biggest_bet_amt == 해당 플레이어 베팅액): 현재 라운드에서 아직 아무도 베팅하지 않았거나, 본인이 이미 동일한 금액을 넣은 상태여야 합니다.

**설명**: 추가 돈을 내지 않고 다음 사람에게 차례를 넘기는 액션입니다. Pre-flop에서 BB는 아무도 레이즈하지 않았을 때 체크할 수 있습니다.

#### 5. Bet (벳: 첫 베팅)
**조건** (biggest_bet_amt == 0): 해당 베팅 라운드에서 아직 아무도 베팅하지 않은 상태여야 합니다.

**설명**: 해당 라운드의 첫 번째 베팅입니다. 운영자가 금액을 입력하고 확인하면 베팅이 처리됩니다. NL 홀덤에서 최소 베팅은 BB 크기입니다.

#### 6. Call (콜: 동일 금액 맞추기)
**조건** (biggest_bet_amt > 해당 플레이어 베팅액): 다른 플레이어가 이미 베팅한 상태여야 합니다.

**설명**: 가장 높은 베팅과 동일한 금액을 내는 액션입니다. 납부 금액은 엔진이 자동으로 계산합니다 (biggest_bet_amt - 본인 기투입액).

#### 7. Raise (레이즈: 추가 베팅)
**조건** (biggest_bet_amt > 0): 이미 누군가가 베팅한 상태여야 합니다.

**설명**: 기존 베팅 위에 추가 금액을 올리는 액션입니다. NL 홀덤에서 최소 레이즈는 직전 베팅/레이즈 크기 이상이어야 합니다. 레이즈 횟수에 캡은 없습니다(NL 기준).

#### 8. AllIn (올인: 전액 베팅)
**조건** (스택 전부 베팅): 별도 조건 없이, 보유 칩 전부를 베팅합니다.

**설명**: 플레이어의 남은 칩을 전부 투입하는 액션입니다. 금액은 `player.stack`으로 자동 결정됩니다. 올인 시 사이드 팟이 생성될 수 있습니다.

#### 9. Undo (되돌리기: 이전 액션 취소)
**조건** (hand_in_progress == true): 핸드가 진행 중이어야 합니다.

**설명**: 직전에 수행한 이벤트를 되돌리는 액션입니다. 최대 5단계까지 연속 되돌리기가 가능합니다. 운영자가 실수로 잘못된 액션을 입력했을 때 사용합니다.

#### 10. ManualNextHand (다음 핸드: 수동 핸드 전환)
**조건** (HAND_COMPLETE 상태): 현재 핸드가 완료된 상태여야 합니다.

**설명**: 운영자가 다음 핸드로 넘어가는 버튼입니다. 자동 전환 설정이 꺼져 있을 때 사용합니다. 누르면 테이블이 IDLE 상태로 돌아가 새 핸드를 시작할 수 있습니다.

#### 11. ManualCardInput (수동 카드 입력: 카드 직접 지정)
**조건** (카드 입력 모드 활성): 카드 입력을 기다리는 상태여야 합니다.

**설명**: 운영자가 suit(문양)과 rank(숫자)를 직접 지정하여 카드를 입력하는 액션입니다. RFID가 인식하지 못한 카드가 있을 때 폴백으로 사용합니다. Mock 모드에서는 이것이 유일한 카드 입력 방법입니다.

#### 12. SeatAssign (좌석 배치: 플레이어를 테이블에 앉히기)
**조건** (Table SETUP/LIVE): 테이블이 설정 중이거나 운영 중인 상태여야 합니다.

**설명**: 운영자가 특정 플레이어를 좌석에 배치하는 액션입니다. WSOP LIVE와 동일하게 두 가지 방식을 지원합니다:
- **Random**: 빈 좌석 중 랜덤으로 배치 (Auto Seating On 상태)
- **Manual**: 테이블과 좌석 번호를 직접 지정하여 배치

배치된 좌석은 NEW 상태(N)가 되며, 10분 카운트다운 후 PLAYING 상태로 전환됩니다.

> **WSOP LIVE 대응**: Table Management → Player Create (Seat) — Random/Manual 지원

#### 13. SeatVacate (좌석 해제: 플레이어를 테이블에서 빼기)
**조건** (Seat OCCUPIED): 해당 좌석에 플레이어가 앉아 있어야 합니다.

**설명**: 플레이어를 좌석에서 해제하는 액션입니다. 탈락(Bust)이 아닌 단순 이탈(자리 비움, 재배치 등)에 사용합니다. 해제 후 좌석은 EMPTY(E) 상태가 됩니다.

> **WSOP LIVE 대응**: Table Management → Player 삭제 / 수동 해제

#### 14. SeatMove (좌석 이동: 다른 좌석으로 이동)
**조건** (두 Seat 간 이동): 출발 좌석에 플레이어가 있고, 도착 좌석이 비어 있어야 합니다.

**설명**: 플레이어를 현재 좌석에서 다른 좌석(같은 테이블 또는 다른 테이블)으로 이동시키는 액션입니다. 이동된 좌석은 MOVED 상태(M)가 되며, 10분 카운트다운 후 PLAYING 상태로 전환됩니다.

> **WSOP LIVE 대응**: Table Management → Player Move — Random/Manual(시트까지 지정) 지원

#### 15. PauseTable (테이블 일시 중단)
**조건** (Table LIVE): 테이블이 운영 중인 상태여야 합니다.

**설명**: 테이블을 일시 중단하는 액션입니다. 진행 중인 핸드가 있으면 해당 핸드를 완료한 후에 일시중단 상태(PAUSED)로 전환됩니다. 식사 휴식, 대회 일시 중지 등에 사용합니다.

#### 16. ResumeTable (테이블 재개)
**조건** (Table PAUSED): 테이블이 일시 중단 상태여야 합니다.

**설명**: PAUSED 상태의 테이블을 다시 LIVE 상태로 전환하는 액션입니다. 재개 후 운영자가 StartHand를 눌러 새 핸드를 시작할 수 있습니다.

#### 17. CloseTable (테이블 종료)
**조건** (Table LIVE/PAUSED): 테이블이 운영 중이거나 일시 중단 상태여야 합니다.

**설명**: 테이블을 완전히 종료하는 액션입니다. 모든 플레이어를 다른 테이블로 재배치한 후에 닫습니다. 종료 후 CLOSED 상태가 되며 더 이상 핸드를 시작할 수 없습니다.

#### 18. SetBombPot (Bomb Pot 설정)
**조건** (IDLE 상태): 핸드가 시작되기 전이어야 합니다.

**설명**: 다음 핸드를 Bomb Pot 모드로 설정합니다. Bomb Pot에서는 PRE_FLOP 베팅 라운드를 건너뛰고, 모든 플레이어가 동일한 금액(보통 Ante 또는 BB의 N배)을 납부한 후 바로 Flop부터 시작합니다.

#### 19. SetRunItTimes (Run It Multiple 설정)
**조건** (SHOWDOWN 진입 전 올인 시): 올인 상황이 발생하고 아직 보드 카드가 남아 있을 때 사용합니다.

**설명**: 올인 후 남은 보드 카드를 여러 번 돌리는 횟수를 설정합니다 (2회 또는 3회). 예를 들어 "Run It Twice"는 Turn/River를 2세트 돌려 각각의 결과로 팟을 분배합니다.

#### 20. ConfirmChop (Chop 합의 확인)
**조건** (HAND_COMPLETE 진입 전): 핸드가 종료되기 직전이어야 합니다.

**설명**: 남은 플레이어들이 남은 칩을 합의로 나누기로 결정했을 때, 운영자가 그 합의를 확인하는 액션입니다. 주로 토너먼트 파이널 테이블에서 사용됩니다.

#### 21. RegisterDeck (덱 등록: 카드 덱 등록)
**조건** (Deck UNREGISTERED): 덱이 아직 등록되지 않은 상태여야 합니다.

**설명**: 새로운 카드 덱을 시스템에 등록하는 액션입니다. RFID 모드에서는 52장을 한 장씩 스캔하여 UID를 매핑하고, Mock 모드에서는 "자동 등록" 버튼으로 52장 가상 매핑이 즉시 생성됩니다.

#### 22. SeatReserve (좌석 예약: 배치 제외)
**조건** (Table SETUP/LIVE, Seat EMPTY): 빈 좌석이어야 합니다.

**설명**: 특정 좌석을 Auto Seating 배치 대상에서 제외하는 액션입니다. 예약된 좌석은 RESERVED 상태(R)가 되어 자동 배치 알고리즘이 이 좌석을 건너뜁니다. TV 카메라 앵글, VIP 좌석 확보 등의 목적으로 사용합니다.

> **WSOP LIVE 대응**: Table Management → Reserve Seat — 짙은 회색으로 표시

#### 23. SeatRelease (좌석 해제: 예약 해제)
**조건** (Seat RESERVED): 좌석이 RESERVED 상태여야 합니다.

**설명**: RESERVED 상태의 좌석을 다시 EMPTY 상태로 되돌려 Auto Seating 배치 대상에 포함시키는 액션입니다.

> **WSOP LIVE 대응**: Table Management → Release Seat

#### 24. PlayerEliminate (플레이어 탈락: Bust 처리)
**조건** (Seat OCCUPIED/PLAYING): 플레이어가 착석 중이어야 합니다.

**설명**: 플레이어 탈락 처리를 요청하는 액션입니다. WSOP LIVE와 동일한 2단계 프로세스를 따릅니다:
1. **Table Dealer**가 Bust 요청 → 좌석이 BUSTED 상태(B, 적색)로 전환
2. **FM/TD**가 Confirm → EMPTY 상태(E)로 전환, 플레이어 탈락 확정

2단계 확인이 필요한 이유는 탈락 오처리를 방지하기 위함입니다.

> **WSOP LIVE 대응**: Table Dealer Page → Bust 요청 → Table Management → Confirm Bust

#### 25. UpdateChips (칩 변경: 칩 수량 수동 수정)
**조건** (hand_in_progress == false, Seat PLAYING): 핸드가 진행 중이 아니고, 플레이어가 착석 중이어야 합니다.

**설명**: 운영자가 플레이어의 칩 수량을 수동으로 변경하는 액션입니다. Add(추가) 또는 Remove(제거)로 조작합니다. 칩 수량 오류 수정, 리바이(Re-buy), 애드온(Add-on) 등의 상황에서 사용합니다.

> **WSOP LIVE 대응**: Table Dealer Page / Table Management → Update Chips (Add/Remove)

### 2.2 RFID 소스 이벤트 (시스템 자동)

RFID 리더가 안테나를 통해 카드를 감지/제거할 때 자동 발동하는 이벤트.

| 이벤트 | 트리거 조건 | payload | 설명 |
|--------|-----------|---------|------|
| `CardDetected` | 안테나 위에 카드 배치 | antennaId, cardUid, suit, rank, timestamp | 카드 인식됨 |
| `CardRemoved` | 안테나에서 카드 제거 | antennaId, cardUid, timestamp | 카드 제거됨 |
| `DeckRegistered` | 52장 전수 스캔 완료 | deckId, cardMap[52], timestamp | 덱 등록 완료 |
| `DeckRegistrationProgress` | 스캔 진행 중 | scannedCount, totalCount | 등록 진행률 |
| `AntennaStatusChanged` | 안테나 연결/해제 | antennaId, status, timestamp | 안테나 상태 변경 |
| `ReaderError` | 하드웨어 오류 | errorCode, message, antennaId | RFID 오류 |

#### 1. CardDetected (카드 인식: RFID 안테나가 카드를 감지)
**조건** (안테나 위에 카드 배치): 플레이어 좌석 또는 보드 위치의 안테나 위에 RFID 태그가 부착된 카드가 놓이면 자동 발동합니다.

**설명**: RFID 안테나가 카드를 인식했을 때 발생하는 이벤트입니다. suit(문양), rank(숫자), timestamp가 포함됩니다. 홀카드(플레이어 카드)인지 보드 카드인지는 antennaId로 구분합니다. Game Engine은 이 이벤트를 받아 해당 카드를 게임 상태에 반영합니다.

#### 2. CardRemoved (카드 제거: 안테나에서 카드 사라짐)
**조건** (안테나에서 카드 제거): 이전에 인식된 카드가 안테나 범위를 벗어나면 발동합니다.

**설명**: 카드가 안테나에서 제거되었음을 알려주는 정보성 이벤트입니다. **이 이벤트 자체가 폴드를 의미하지는 않습니다.** 딜러가 카드를 정리하거나 실수로 카드를 움직인 경우에도 발생합니다. 폴드는 반드시 운영자의 Fold 버튼으로만 처리됩니다.

#### 3. DeckRegistered (덱 등록 완료: 52장 스캔 완료)
**조건** (52장 전수 스캔 완료): 등록 모드에서 52장 카드가 모두 스캔되면 발동합니다.

**설명**: 새 카드 덱의 등록이 완료되었음을 알리는 이벤트입니다. deckId와 52장의 cardMap(UID ↔ suit/rank 매핑)이 포함됩니다. 이 이벤트 이후에야 해당 덱으로 게임을 시작할 수 있습니다.

#### 4. DeckRegistrationProgress (덱 등록 진행률: 스캔 진행 상태)
**조건** (스캔 진행 중): 덱 등록 중 카드가 스캔될 때마다 발동합니다.

**설명**: 덱 등록의 진행 상황을 알려주는 이벤트입니다. scannedCount/totalCount로 진행률을 표시합니다 (예: 35/52). CC UI에서 프로그레스 바를 업데이트하는 데 사용합니다.

#### 5. AntennaStatusChanged (안테나 상태 변경: 연결/해제)
**조건** (안테나 연결/해제): 안테나가 물리적으로 연결되거나 해제될 때 발동합니다.

**설명**: RFID 안테나의 연결 상태가 바뀌었음을 알리는 이벤트입니다. CC UI에서 각 좌석의 안테나 상태를 아이콘으로 표시하는 데 사용합니다. 안테나 미연결 시 해당 좌석의 카드 인식이 불가능합니다.

#### 6. ReaderError (리더 오류: RFID 하드웨어 오류)
**조건** (하드웨어 오류): RFID 리더에서 오류가 발생하면 자동 발동합니다.

**설명**: RFID 하드웨어에서 오류가 발생했음을 알리는 이벤트입니다. errorCode로 원인을 식별합니다 (통신 실패, 전원 문제, 펌웨어 오류 등). CC UI에 경고를 표시하고, 심각한 경우 운영자에게 Mock 모드 전환을 제안합니다.

> **RFID 이벤트는 `IRfidReader.events` 스트림을 통해 전달된다.** 상세: `API-03-rfid-hal-interface.md`

### 2.3 Engine 소스 이벤트 (시스템 자동)

Game Engine이 규칙에 따라 자동 발생시키는 이벤트. 외부 입력 없이 내부 상태 전이.

| 이벤트 | 트리거 조건 | 설명 |
|--------|-----------|------|
| `BlindsPosted` | SETUP_HAND 진입 + 블라인드 대상 확정 | SB/BB/Ante 자동 수집 |
| `HoleCardsDealt` | 모든 플레이어 홀카드 배분 완료 | → PRE_FLOP 전이 |
| `BettingRoundComplete` | 현재 라운드 모든 액션 완료 (동일 베팅액) | → 다음 Street 전이 |
| `AllFolded` | 1명 제외 전원 폴드 | → HAND_COMPLETE 직행 |
| `AllInRunout` | 올인 + 남은 베팅 불가 | 남은 보드 자동 공개 |
| `ShowdownStarted` | 최종 라운드 완료 + 2+ 플레이어 | 핸드 평가 시작 |
| `WinnerDetermined` | 핸드 평가 완료 | 우승자 + 팟 분배 계산 |
| `HandCompleted` | 팟 분배 + 통계 업데이트 완료 | → HAND_COMPLETE 전이 |
| `EquityUpdated` | 카드 상태 변경 (홀카드/보드 변경) | Monte Carlo/LUT 승률 재계산 |
| `SidePotCreated` | 올인 발생 시 초과분 분리 | 사이드 팟 생성 |
| `StatisticsUpdated` | 핸드 종료 시 | VPIP/PfR/WTSD/Agr 등 업데이트 |
| `MisdealDetected` | 카드 불일치 감지 | → IDLE 복귀, 스택 복원 |

#### 1. BlindsPosted (블라인드 수집: SB/BB/Ante 자동 수집)
**조건** (SETUP_HAND 진입 + 블라인드 대상 확정): 핸드가 시작되어 딜러 버튼 위치가 결정되면 자동 발동합니다.

**설명**: 핸드 시작 시 Small Blind, Big Blind, Ante를 해당 포지션의 플레이어로부터 자동으로 수집하는 이벤트입니다. 포지션은 딜러 버튼 기준으로 결정되며, 운영자가 개입할 필요가 없습니다.

#### 2. HoleCardsDealt (홀카드 배분 완료: 모든 플레이어에게 카드 배분)
**조건** (모든 플레이어 홀카드 배분 완료): 참여 중인 모든 플레이어에게 홀카드가 배분되면 발동합니다.

**설명**: 모든 플레이어에게 홀카드(2장)가 배분되었음을 알리는 이벤트입니다. 이 이벤트 이후 PRE_FLOP 베팅 라운드가 시작됩니다. RFID 모드에서는 모든 안테나가 카드를 인식해야 이 이벤트가 발생합니다.

#### 3. BettingRoundComplete (베팅 라운드 완료: 동일 베팅액 도달)
**조건** (현재 라운드 모든 액션 완료): 모든 활성 플레이어가 동일한 베팅액에 도달하면 발동합니다.

**설명**: 현재 베팅 라운드가 완료되었음을 알리는 이벤트입니다. 다음 Street(Flop→Turn→River)로 전환되며, 보드 카드를 공개할 차례가 됩니다.

#### 4. AllFolded (전원 폴드: 1명 제외 모두 포기)
**조건** (1명 제외 전원 폴드): 마지막 한 명을 제외한 모든 플레이어가 폴드하면 발동합니다.

**설명**: 1명만 남았으므로 해당 플레이어가 자동으로 팟을 획득합니다. 보드 카드를 더 공개할 필요 없이 즉시 HAND_COMPLETE로 전환됩니다.

#### 5. AllInRunout (올인 런아웃: 추가 베팅 불가 상태)
**조건** (올인 + 남은 베팅 불가): 모든 활성 플레이어가 올인하여 더 이상 베팅 액션이 불가능하면 발동합니다.

**설명**: 남은 보드 카드를 자동으로 공개하는 이벤트입니다. 모든 플레이어가 올인이므로 추가 의사 결정이 필요 없고, 남은 카드(Turn, River 등)를 순차 공개한 후 Showdown으로 진행합니다.

#### 6. ShowdownStarted (쇼다운 시작: 핸드 평가 시작)
**조건** (최종 라운드 완료 + 2명 이상 플레이어): River 베팅까지 완료되고 2명 이상이 남아 있으면 발동합니다.

**설명**: 남은 플레이어들의 핸드(카드 조합)를 비교하여 승자를 결정하는 단계가 시작되었음을 알리는 이벤트입니다.

#### 7. WinnerDetermined (승자 확정: 팟 분배 계산 완료)
**조건** (핸드 평가 완료): 핸드 랭킹 비교가 완료되면 발동합니다.

**설명**: 핸드 평가가 끝나고 승자가 확정된 이벤트입니다. 메인 팟과 사이드 팟의 분배 금액이 계산됩니다. 동률(Split Pot)인 경우 팟을 균등 분배합니다.

#### 8. HandCompleted (핸드 완료: 팟 분배 + 통계 업데이트 완료)
**조건** (팟 분배 + 통계 업데이트 완료): 팟이 분배되고 통계가 갱신되면 발동합니다.

**설명**: 핸드가 완전히 종료되었음을 알리는 이벤트입니다. HAND_COMPLETE 상태로 전환되며, 운영자가 ManualNextHand를 누르거나 자동 전환 설정에 따라 다음 핸드로 넘어갑니다.

#### 9. EquityUpdated (승률 갱신: 실시간 승률 재계산)
**조건** (카드 상태 변경): 홀카드가 인식되거나 보드 카드가 추가될 때마다 발동합니다.

**설명**: Monte Carlo 시뮬레이션 또는 LUT(Look-Up Table)를 사용하여 각 플레이어의 실시간 승률을 재계산하는 이벤트입니다. 오버레이 그래픽에서 승률 바를 업데이트하는 데 사용합니다.

#### 10. SidePotCreated (사이드 팟 생성: 올인 초과분 분리)
**조건** (올인 발생 시 초과분 분리): 올인 플레이어의 스택보다 많은 금액이 베팅되면 발동합니다.

**설명**: 올인한 플레이어의 스택 한도를 초과하는 베팅이 있을 때, 초과분을 별도의 사이드 팟으로 분리하는 이벤트입니다. 올인 플레이어는 메인 팟에만 참여하고, 나머지 플레이어는 사이드 팟에서 추가 경쟁합니다.

#### 11. StatisticsUpdated (통계 갱신: 플레이어 통계 업데이트)
**조건** (핸드 종료 시): 핸드가 완료될 때마다 발동합니다.

**설명**: 각 플레이어의 통계를 갱신하는 이벤트입니다. VPIP(자발적 팟 참여율), PfR(Pre-flop Raise율), WTSD(Showdown 진행률), Agr(공격성 지표) 등이 업데이트됩니다. 오버레이 그래픽과 관리자 모니터링에 사용합니다.

#### 12. MisdealDetected (미스딜 감지: 카드 오류 감지)
**조건** (카드 불일치 감지): 중복 카드, 카드 수 부족, 덱에 없는 카드 등이 감지되면 발동합니다.

**설명**: 카드 배분 과정에서 오류가 발견되었을 때 발생하는 이벤트입니다. 즉시 핸드를 무효화하고, IDLE 상태로 복귀하며, 모든 플레이어의 스택을 핸드 시작 전 상태로 복원합니다.

### 2.4 BO 소스 이벤트 (시스템 자동)

Back Office에서 데이터 변경 시 WebSocket을 통해 Lobby/CC에 통지하는 이벤트.

| 이벤트 | 트리거 조건 | 수신 대상 | 설명 |
|--------|-----------|----------|------|
| `ConfigChanged` | Admin이 Settings 변경 | CC | 출력/오버레이/게임 설정 변경 |
| `PlayerUpdated` | Lobby에서 플레이어 정보 수정 | CC | 이름/프로필 변경 |
| `TableAssigned` | Lobby에서 테이블 설정 변경 | CC | RFID 할당, 덱 상태, 출력 설정 |
| `BlindStructureChanged` | Lobby에서 블라인드 레벨 변경 | CC | 새 레벨 적용 |
| `OperatorConnected` | CC가 BO에 WebSocket 연결 | Lobby | Lobby 모니터링 업데이트 |
| `OperatorDisconnected` | CC WebSocket 끊김 | Lobby | 연결 해제 알림 |
| `HandStarted` | CC에서 핸드 시작 → BO 기록 | Lobby | 모니터링 핸드 번호 갱신 |
| `HandEnded` | CC에서 핸드 종료 → BO 기록 | Lobby | 모니터링 결과 반영 |
| `GameChanged` | CC에서 Mix 게임 종목 변경 → BO 기록 | Lobby | 모니터링 종목 표시 |
| `RfidStatusChanged` | CC에서 RFID 상태 변경 → BO 기록 | Lobby | 테이블 카드 RFID 상태 |
| `OutputStatusChanged` | CC에서 출력 상태 변경 → BO 기록 | Lobby | 테이블 카드 출력 상태 |
| `ActionPerformed` | CC에서 액션 수행 → BO 기록 | Lobby (Admin) | 실시간 액션 모니터링 |
| `BreakTable` | Lobby에서 테이블 깨기 | CC | 테이블 해체 → 플레이어 재배치 |
| `BalanceTable` | 테이블 간 인원 차이 ≥ 3 | CC | 인원 균등화 (WSOP Rule 67) |

#### 1. ConfigChanged (설정 변경: Admin이 Settings 수정)
**조건** (Admin이 Settings 변경): Back Office에서 Admin이 출력/오버레이/게임 설정을 변경하면 발동합니다.

**설명**: CC에 설정 변경을 통지하는 이벤트입니다. CC는 이 이벤트를 받으면 로컬 캐시를 갱신합니다. 핸드 진행 중에 수신되면 현재 핸드 종료 후 적용합니다.

#### 2. PlayerUpdated (플레이어 정보 변경: 이름/프로필 수정)
**조건** (Lobby에서 플레이어 정보 수정): 운영자가 Lobby에서 플레이어 이름, 국적 등을 수정하면 발동합니다.

**설명**: 플레이어 정보 변경을 CC에 통지하는 이벤트입니다. CC는 오버레이 그래픽에 표시되는 플레이어 정보를 즉시 업데이트합니다.

#### 3. TableAssigned (테이블 설정 변경: 테이블 할당 정보 수정)
**조건** (Lobby에서 테이블 설정 변경): RFID 할당, 덱 상태, 출력 설정 등이 변경되면 발동합니다.

**설명**: 테이블의 하드웨어/소프트웨어 설정이 변경되었음을 CC에 통지하는 이벤트입니다. RFID 리더 할당, 덱 교체, 출력 대상 변경 등이 포함됩니다.

#### 4. BlindStructureChanged (블라인드 구조 변경: 블라인드 레벨 변경)
**조건** (Lobby에서 블라인드 레벨 변경): 토너먼트 진행에 따라 블라인드 레벨이 변경되면 발동합니다.

**설명**: 새로운 블라인드 레벨을 CC에 통지하는 이벤트입니다. CC는 다음 핸드부터 새로운 SB/BB/Ante 값을 적용합니다.

#### 5. OperatorConnected (운영자 연결: CC가 BO에 접속)
**조건** (CC가 BO에 WebSocket 연결): CC 앱이 시작되어 BO 서버에 WebSocket을 연결하면 발동합니다.

**설명**: Lobby 모니터링 화면에서 해당 테이블의 CC가 온라인임을 표시하기 위한 이벤트입니다.

#### 6. OperatorDisconnected (운영자 연결 해제: CC WebSocket 끊김)
**조건** (CC WebSocket 끊김): CC의 WebSocket 연결이 끊기면 발동합니다.

**설명**: Lobby 모니터링 화면에서 해당 테이블의 CC가 오프라인임을 표시하기 위한 이벤트입니다. 네트워크 문제, CC 앱 종료 등의 원인이 있을 수 있습니다.

#### 7. HandStarted (핸드 시작 통지: CC에서 핸드 시작 → BO 기록)
**조건** (CC에서 핸드 시작): CC에서 StartHand가 실행되면 BO에 기록되고, Lobby로 통지됩니다.

**설명**: Lobby 모니터링 화면에서 해당 테이블의 핸드 번호를 갱신하기 위한 이벤트입니다.

#### 8. HandEnded (핸드 종료 통지: CC에서 핸드 종료 → BO 기록)
**조건** (CC에서 핸드 종료): CC에서 핸드가 완료되면 BO에 결과가 기록되고, Lobby로 통지됩니다.

**설명**: Lobby 모니터링 화면에서 핸드 결과(승자, 팟 크기)를 반영하기 위한 이벤트입니다.

#### 9. GameChanged (게임 종목 변경: Mix 게임 종목 전환)
**조건** (CC에서 Mix 게임 종목 변경): Mix 게임 모드에서 종목이 바뀌면 BO에 기록됩니다.

**설명**: Lobby 모니터링 화면에서 해당 테이블의 현재 게임 종목을 표시하기 위한 이벤트입니다. 예: HORSE 모드에서 Hold'em → Omaha 전환.

#### 10. RfidStatusChanged (RFID 상태 변경: 하드웨어 상태 통지)
**조건** (CC에서 RFID 상태 변경): RFID 리더의 연결/해제/오류 상태가 바뀌면 BO에 기록됩니다.

**설명**: Lobby 모니터링 화면에서 테이블별 RFID 하드웨어 상태를 표시하기 위한 이벤트입니다.

#### 11. OutputStatusChanged (출력 상태 변경: 오버레이 출력 상태 통지)
**조건** (CC에서 출력 상태 변경): 오버레이 출력의 활성/비활성 상태가 바뀌면 BO에 기록됩니다.

**설명**: Lobby 모니터링 화면에서 테이블별 그래픽 출력 상태를 표시하기 위한 이벤트입니다.

#### 12. ActionPerformed (액션 수행 통지: 실시간 액션 모니터링)
**조건** (CC에서 액션 수행): CC에서 게임 액션(Fold, Bet, Raise 등)이 수행될 때마다 BO에 기록됩니다.

**설명**: Admin용 Lobby 모니터링에서 테이블의 실시간 액션 로그를 표시하기 위한 이벤트입니다. 일반 운영자에게는 노출되지 않으며, Admin 권한에서만 볼 수 있습니다.

#### 13. BreakTable (테이블 해체: 플레이어 재배치)
**조건** (Lobby에서 테이블 깨기): FM/TD가 Lobby에서 특정 테이블의 Break를 실행하면 발동합니다.

**설명**: 테이블을 해체하고 소속 플레이어들을 다른 테이블로 재배치하는 이벤트입니다. 토너먼트 진행에 따라 테이블 수를 줄일 때 사용합니다. CC는 이 이벤트를 받으면 테이블을 EMPTY 상태로 전환하고, 모든 좌석을 비웁니다.

> **WSOP LIVE 대응**: Table Management → Break Table — Breaking Order(해체 우선순위)에 따라 실행

#### 14. BalanceTable (테이블 밸런싱: 인원 균등화)
**조건** (테이블 간 인원 차이 ≥ 3): 테이블 간 플레이어 수 차이가 3명 이상일 때 발동합니다.

**설명**: 테이블 간 플레이어 수를 균등화하는 이벤트입니다. WSOP Rule 67에 따라 인원이 많은 테이블에서 적은 테이블로 플레이어를 이동합니다. CC는 이 이벤트를 받으면 해당 좌석의 SeatMove를 처리합니다.

> **WSOP LIVE 대응**: Table Management → Balance Table — 자동 또는 수동 실행

### 2.5 BO Clock 트리거 — Tournament Clock 관리

> **소유**: Backend(Team 2). Game Engine(Team 3)은 Clock과 무관 — 시간 대신 `BlindStructureChanged` 명령을 수신.
> **ClockFSM 상태 정의**: BS-00-definitions §3.7

| 트리거 | 발동 주체 | 수신 대상 | 설명 |
|--------|---------|---------|------|
| `ClockStarted` | Admin/Operator (Lobby) | `lobby_monitor` + `cc_event` | 토너먼트 타이머 시작 → ClockFSM: STOPPED → RUNNING |
| `ClockRestarted` | Admin/Operator | `lobby_monitor` + `cc_event` | 현재 레벨 duration 처음부터 재시작 (CCR-050) |
| `ClockPaused` | Operator/Admin (CC) | `lobby_monitor` + `cc_event` | TD 수동 정지 → ClockFSM: RUNNING → PAUSED |
| `ClockResumed` | Operator/Admin (CC) | `lobby_monitor` + `cc_event` | TD 재개 → ClockFSM: PAUSED → RUNNING |
| `clock_tick` | BO 내부 타이머 | `lobby_monitor` + `cc_event` | 매 1초 자동 발행. 클라이언트 카운트다운용 |
| `clock_level_changed` | BO 내부 타이머 | `lobby_monitor` + `cc_event` | 레벨 전환·Break 진입/종료 시 발행 |
| `clock_detail_changed` | Admin/Operator | `lobby_monitor` + `cc_event` | 테마/공지/이벤트명/그룹명 변경 시 발행 (WSOP LIVE `ClockDetail` 대응, CCR-050) |
| `clock_reload_requested` | Admin/Operator | `lobby_monitor` + `cc_event` | 대시보드 강제 리로드 신호 (WSOP LIVE `ClockReloadPage` 대응, CCR-050) |
| `stack_adjusted` | Admin | `lobby_monitor` + `cc_event` | 평균 스택 강제 조정 시 발행 (CCR-050) |
| `tournament_status_changed` | Admin | `lobby_monitor` + `cc_event` | EventFlightStatus 전이 (Created/Announce/Registering/Running/Completed/Canceled) 시 발행 (WSOP LIVE `TournamentStatus` 대응, CCR-050) |
| `BlindStructureChanged` | BO (Auto Blind-Up 결과) | `cc_event` | Blind 레벨 전환 시 CC에 새 SB/BB/Ante 전달 |

#### Auto Blind-Up 로직 (BO 내부)

```
[매 1초 BO 타이머]
  └─ time_remaining_sec 감소
       └─ = 0 도달?
            ├─ auto_advance = false → ClockFSM: RUNNING → PAUSED (TD 수동 확인 대기)
            └─ auto_advance = true
                 ├─ blind_detail_type = Break/DinnerBreak/HalfBreak → 휴식 종료 → 다음 Blind/HalfBlind 레벨
                 ├─ blind_detail_type = HalfBlind → 하프 디너 블라인드 종료 → 다음 HalfBreak 또는 Blind
                 └─ blind_detail_type = Blind
                      ├─ 다음: Break → ClockFSM: RUNNING → BREAK
                      ├─ 다음: DinnerBreak → ClockFSM: RUNNING → DINNER_BREAK
                      ├─ 다음: Blind → level++, 새 duration 시작
                      └─ 마지막 레벨 → ClockFSM: RUNNING → STOPPED
```

> **BlindDetailType enum**: BS-00 §3.8 (WSOP LIVE 준거)

레벨 전환 시 BO는 동시에: ① `clock_level_changed` 발행 → ② `BlindStructureChanged` 발행 (순서 보장).

---

## 3. 경계 케이스 — CC vs RFID 동시 발생

### 3.1 카드 인식: RFID 자동 vs CC 수동

| 시나리오 | RFID 감지 | CC 수동 입력 | 우선순위 | 시스템 반응 |
|---------|:--------:|:-----------:|---------|-----------|
| Feature Table, Real 모드 | `CardDetected` | — | **RFID 우선** | 자동 인식된 카드 사용 |
| Feature Table, Real 모드, RFID 실패 | 실패/무응답 | `ManualCardInput` | **CC 폴백** | 수동 입력으로 전환 |
| Feature Table, Mock 모드 | — | `ManualCardInput` | **CC 유일** | 수동 입력 → `CardDetected` 합성 |
| General Table (RFID 없음) | — | `ManualCardInput` | **CC 유일** | 수동 입력만 가능 |
| Real 모드 + 수동 입력 동시 | `CardDetected` | `ManualCardInput` | **RFID 우선** | RFID 결과 사용, 수동 입력 무시 + 경고 로그 |

### 3.2 폴드 인식: CC 버튼 vs RFID 카드 제거

| 시나리오 | 시스템 반응 |
|---------|-----------|
| 운영자가 FOLD 버튼 클릭 | `Fold` 이벤트 즉시 처리. RFID 카드 제거는 무시 |
| RFID가 카드 제거 감지 (폴드 의도?) | **자동 폴드 안 함.** `CardRemoved` 경고 로그만. 운영자 FOLD 버튼 필수 |
| 운영자 FOLD + 동시에 RFID 카드 제거 | `Fold` 이벤트 1회만 처리 (중복 방지) |

> **핵심 원칙**: 카드 제거는 "정보"이지 "액션"이 아니다. 폴드는 반드시 운영자 의도(CC 버튼)로만 실행된다.

### 3.3 보드 카드 공개: RFID vs CC

| 시나리오 | 시스템 반응 |
|---------|-----------|
| RFID가 보드 카드 3장 감지 (Flop) | `CardDetected` × 3 → Engine이 FLOP 전이 허용 |
| 운영자가 수동으로 보드 카드 입력 | `ManualCardInput` × 3 → `CardDetected` 합성 → Engine 동일 처리 |
| RFID가 2장만 감지 (1장 미인식) | 경고 표시 → 운영자가 나머지 1장 수동 입력 → 혼합 가능 |

---

## 4. Mock 모드 이벤트 합성 규칙

### 4.1 기본 원칙

Mock HAL(`MockRfidReader`)은 CC UI의 수동 입력을 받아 **Real HAL과 동일한 이벤트 스트림**을 생성한다.

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

### 4.2 이벤트별 합성 규칙

| Real 이벤트 | Mock 합성 방법 | 차이점 |
|------------|--------------|--------|
| `CardDetected` | CC 수동 카드 선택 → `injectCard()` | antennaId=0, uid="MOCK-XX", confidence=1.0 |
| `CardRemoved` | Mock에서 미지원 | 테스트 필요 시 `injectRemoval()` API 사용 |
| `DeckRegistered` | "자동 등록" 버튼 → 52장 가상 매핑 즉시 생성 | 스캔 시간 0ms, 진행률 100% 즉시 |
| `DeckRegistrationProgress` | "자동 등록" 시 1회 100% 이벤트 | Real은 1장씩 52회 이벤트 |
| `AntennaStatusChanged` | Mock 초기화 시 1회 `CONNECTED` | antenna 1개만 가상 존재 |
| `ReaderError` | `injectError(errorCode)` API | 테스트/데모용 에러 주입 |

### 4.3 시나리오 스크립트 재생 (E2E 테스트용)

Mock HAL은 **YAML 시나리오 파일**을 로드하여 사전 정의된 이벤트 시퀀스를 재생할 수 있다.

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

## 5. 충돌 해결 규칙

### 5.1 동일 이벤트 중복 수신

| 상황 | 해결 |
|------|------|
| 같은 카드 `CardDetected` 2회 수신 | 두 번째 이벤트 무시 + `DUPLICATE_CARD` 경고 로그 |
| `Fold` + `CardRemoved` 동시 | `Fold`만 처리 (§3.2) |
| `Bet(100)` + `Bet(200)` 빠른 연속 | 첫 `Bet` 처리 후 두 번째는 `Raise`로 재해석 또는 거부 |

### 5.2 소스 간 충돌

| 상황 | 우선순위 | 해결 |
|------|---------|------|
| CC + RFID 동시 카드 입력 (같은 카드) | RFID | 수동 입력 무시, RFID 결과 사용 |
| CC + RFID 동시 카드 입력 (다른 카드) | RFID | RFID 카드 사용 + `CARD_CONFLICT` 경고 + 운영자 확인 요청 |
| CC 액션 + BO ConfigChanged 동시 | CC | 게임 진행 액션 우선, Config는 핸드 종료 후 적용 (핸드 중간 설정 변경은 지연) |
| Engine 자동 전이 + CC Undo 동시 | CC | Undo가 Engine 자동 전이를 되돌림 |

---

## 6. 이벤트 순서 보장

### 6.1 선후관계 필수 케이스 (위반 시 에러)

| 선행 이벤트 | 후행 이벤트 | 이유 |
|-----------|-----------|------|
| `StartHand` | `BlindsPosted` | 핸드 시작 전 블라인드 수집 불가 |
| `BlindsPosted` | `HoleCardsDealt` | 블라인드 없이 딜 불가 |
| `HoleCardsDealt` | 첫 `Bet`/`Fold`/`Check` | 카드 없이 액션 불가 |
| `BettingRoundComplete` | 다음 Street 보드 카드 | 베팅 미완료 시 보드 공개 금지 |
| `CardDetected` (홀카드) | `EquityUpdated` | 카드 없이 승률 계산 불가 |
| `DeckRegistered` | 첫 `CardDetected` (게임 중) | 미등록 덱으로 게임 불가 |

### 6.2 순서 무관 케이스 (병렬 처리 가능)

| 이벤트 A | 이벤트 B | 이유 |
|---------|---------|------|
| `EquityUpdated` | `StatisticsUpdated` | 독립 계산 |
| `OperatorConnected` | `ConfigChanged` | 서로 다른 채널 |
| `PlayerUpdated` (Lobby) | `ActionPerformed` (CC) | 서로 다른 앱 |
| `CardDetected` (Seat 1) | `CardDetected` (Seat 2) | 서로 다른 안테나 |

---

## 7. 트리거와 HandFSM 상태 매핑 요약

| HandFSM 상태 | 허용 CC 트리거 | 허용 RFID 트리거 | 허용 Engine 트리거 |
|-------------|--------------|----------------|-------------------|
| **IDLE** | `StartHand`, `RegisterDeck` | `DeckRegistered`, `AntennaStatusChanged` | — |
| **SETUP_HAND** | `Deal` | `CardDetected` (홀카드) | `BlindsPosted` |
| **PRE_FLOP** | `Fold`, `Check`, `Bet`, `Call`, `Raise`, `AllIn`, `Undo` | — | `BettingRoundComplete`, `AllFolded`, `AllInRunout` |
| **FLOP** | `Fold`, `Check`, `Bet`, `Call`, `Raise`, `AllIn`, `Undo` | `CardDetected` (보드) | `BettingRoundComplete`, `AllFolded`, `AllInRunout` |
| **TURN** | `Fold`, `Check`, `Bet`, `Call`, `Raise`, `AllIn`, `Undo` | `CardDetected` (보드) | `BettingRoundComplete`, `AllFolded`, `AllInRunout` |
| **RIVER** | `Fold`, `Check`, `Bet`, `Call`, `Raise`, `AllIn`, `Undo` | `CardDetected` (보드) | `BettingRoundComplete`, `AllFolded`, `ShowdownStarted` |
| **SHOWDOWN** | `SetRunItTimes`, `ConfirmChop` | — | `WinnerDetermined`, `HandCompleted` |
| **RUN_IT_MULTIPLE** | — | `CardDetected` (추가 보드) | `HandCompleted` |
| **HAND_COMPLETE** | `ManualNextHand` | — | (overrideButton 시 자동 IDLE) |

### SeatFSM 유효 상태 매트릭스

> WSOP LIVE Seat Status 코드 기반 (Table Dealer Page, Table Management)

| 이벤트 \ Seat 상태 | EMPTY (E) | NEW (N) | PLAYING | MOVED (M) | BUSTED (B) | RESERVED (R) | OCCUPIED (O) | WAITING (W) | HOLD (H) |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **SeatAssign** | ✓→NEW | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT |
| **SeatVacate** | REJECT | ✓→EMPTY | ✓→EMPTY | ✓→EMPTY | REJECT | REJECT | REJECT | ✓→EMPTY | REJECT |
| **SeatMove** (출발) | REJECT | REJECT | ✓→EMPTY | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT |
| **SeatMove** (도착) | ✓→MOVED | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT | REJECT |
| **SeatReserve** | ✓→RESERVED | REJECT | REJECT | REJECT | REJECT | IGNORE | REJECT | REJECT | REJECT |
| **SeatRelease** | REJECT | REJECT | REJECT | REJECT | REJECT | ✓→EMPTY | REJECT | REJECT | REJECT |
| **PlayerEliminate** (요청) | REJECT | REJECT | ✓→BUSTED | REJECT | IGNORE | REJECT | REJECT | REJECT | REJECT |
| **PlayerEliminate** (확인) | REJECT | REJECT | REJECT | REJECT | ✓→EMPTY | REJECT | REJECT | REJECT | REJECT |

> **상태 전환 규칙**: NEW(N)과 MOVED(M)는 10분 카운트다운 후 자동으로 PLAYING으로 전환됩니다. 핸드에 참여하면 즉시 PLAYING으로 전환됩니다.
> **WAITING(W)**: 웨이팅 큐에서 Auto Seating으로 배정된 상태. 플레이어 도착 시 PLAYING으로 전환. 황색 표시.
> **HOLD(H)**: Seat Draw in Advance에서 선점된 좌석. Hold 해제 시 EMPTY로 전환. 회색 표시.

### TableFSM 유효 상태 매트릭스

| 이벤트 \ Table 상태 | SETUP | LIVE | PAUSED | CLOSED | EMPTY | RESERVED_TABLE |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|
| **PauseTable** | REJECT | ✓→PAUSED | IGNORE | REJECT | REJECT | REJECT |
| **ResumeTable** | REJECT | REJECT | ✓→LIVE | REJECT | REJECT | REJECT |
| **CloseTable** | ✓→CLOSED | ✓→CLOSED | ✓→CLOSED | IGNORE | REJECT | ✓→CLOSED |
| **BreakTable** | REJECT | ✓→EMPTY | ✓→EMPTY | REJECT | REJECT | REJECT |
| **BalanceTable** | REJECT | ✓ (유지) | REJECT | REJECT | REJECT | REJECT |
| **ReserveTable** | REJECT | ✓→RESERVED_TABLE | REJECT | REJECT | REJECT | IGNORE |
| **ReleaseTable** | REJECT | REJECT | REJECT | REJECT | REJECT | ✓→LIVE |

---

## 비활성 조건

- Table 상태가 EMPTY 또는 CLOSED일 때 모든 게임 트리거 비활성
- RFID 모드가 Mock이고 `MockRfidReader`가 초기화되지 않은 경우 RFID 이벤트 미발생
- BO WebSocket 연결이 끊긴 경우 BO 소스 이벤트 미수신 (CC는 로컬 캐시로 계속 동작)

---

## 영향 받는 요소

| 영향 대상 | 이 문서와의 관계 |
|----------|----------------|
| `BS-04-rfid/` | RFID 이벤트 정의의 행동 명세 버전 |
| `BS-05-command-center/` | CC 이벤트의 UI 트리거 조건 |
| `BS-06-01-holdem-lifecycle.md` | HandFSM 상태 전이의 트리거 소스 |
| `API-03-rfid-hal-interface.md` | RFID HAL 인터페이스의 이벤트 타입 정의 |
| `API-05-websocket-events.md` | BO/CC 간 WebSocket 이벤트 프로토콜 |
| `BO-09-data-sync.md` | BO 소스 이벤트의 동기화 프로토콜 |
| WSOP LIVE Table Management (Confluence page 1615528545) | SeatFSM/Seat Status 코드(E/N/M/B/O/R/W/H)의 SSOT |
| WSOP LIVE Table Dealer Page (Confluence page 1665139092) | Seat Status UI 표현의 참조 |
