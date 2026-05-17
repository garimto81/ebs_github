---
title: Game State WS Message Schema — Field-Based Batch (PokerGFX GameInfoResponse pattern)
owner: stream:S7 (Backend)
tier: contract
last-updated: 2026-05-17
version: 1.0.0
mirror: none
confluence-sync: none
derivative-of: ../../../1. Product/Foundation.md (§B.3 Field-based batch sub-section)
related-docs:
  - ../../../1. Product/Foundation.md (§B.3 통신 매트릭스)
  - ../../../1. Product/Command_Center.md (Ch.6.4 L4 Wire Protocol)
  - ./WebSocket_Events.md (기존 WS event SSOT)
  - ../../2.5 Shared/Chip_Count_State.md (chip_count_synced event 정합)
pokergfx-source: pokergfx-reverse-engineering-complete.md (line 1647-1684 — GameInfoResponse 75+ fields + PlayerInfoResponse 20 fields)
---

# Game State WS Message Schema (Field-Based Batch)

> **본 문서의 위치**: Foundation §B.3 의 "Wire format = Field-based batch (PokerGFX GameInfoResponse 75+ fields 패턴 차용)" sub-section 의 정밀 schema 정의.
>
> **mirror: none** — Confluence 업로드 제외.

---

## 1. 패턴 정의

### 1.1 Field-Based Batch 의 의미

```
   State Enum 송신 (전통 패턴)         vs       Field-Based Batch (PokerGFX/EBS)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Server: "state=FLOP"                        Server: { Cards: [...], Pot: 1500,
                                                         BoardCards: "AhKsQd",
   Client: state 인식 → UI 변경                          BettingRound: 2, ... }
                                                
   문제:                                       Client: fields 변경 인식 → 자체 UI 분기
   - 모든 state 미리 정의 필요
   - state 추가 = breaking change                장점:
   - 클라이언트 ↔ 서버 state 동기화 부담         - state enum 없음
                                               - fields 추가 = backward compatible
                                               - 클라이언트 자유롭게 UI 분기
```

### 1.2 PokerGFX 검증

PokerGFX Server v3.2.985.0 의 GameInfoResponse 75+ fields 패턴이 라이브 포커 방송 **88% 커버리지** 로 검증됨. EBS 가 같은 패턴 차용.

---

## 2. GameInfoResponse Schema (75+ Fields, 9 Categories)

### 2.1 카테고리 분류

| 카테고리 | Fields | 용도 |
|---------|--------|------|
| 블라인드 | 8 | SB/BB/Ante/Third blind 정보 |
| 좌석 | 7 | 좌석별 포지션 (Dealer/SB/BB/ActionOn) |
| 베팅 | 6 | 베팅 라운드 + 구조 |
| 게임 | 4 | Game class/type/variant |
| 보드 | 5 | 보드 카드 + 멀티보드 |
| 상태 | 6 | Hand 진행 + 송출 상태 |
| 디스플레이 | 7 | 시청자/운영자 표시 토글 |
| 특수 | 6 | RunItTwice / BombPot / Chop |
| 드로우 | 4 | Stud/Draw 클래스 분기 |

### 2.2 카테고리별 fields 상세

#### Category 1: 블라인드 (8 fields)

```json
{
  "Ante": 100,
  "Small": 200,
  "Big": 400,
  "Third": 800,
  "ButtonBlind": 0,
  "BringIn": 0,
  "BlindLevel": 5,
  "NumBlinds": 2
}
```

#### Category 2: 좌석 (7 fields)

```json
{
  "PlDealer": 3,
  "PlSmall": 4,
  "PlBig": 5,
  "PlThird": 6,
  "ActionOn": 7,
  "NumSeats": 10,
  "NumActivePlayers": 7
}
```

#### Category 3: 베팅 (6 fields)

```json
{
  "BiggestBet": 1200,
  "SmallestChip": 100,
  "BetStructure": "NoLimit",
  "Cap": 0,
  "MinRaiseAmt": 800,
  "PredictiveBet": 2400
}
```

#### Category 4: 게임 (4 fields) ★ Mixed Game 핵심

```json
{
  "GameClass": "flop",
  "GameType": 0,
  "GameVariant": "Hold'em",
  "GameTitle": "WSOP Main Event Day 4"
}
```

> Mixed Game cycle 시 본 4 fields 가 매 핸드 변경. CC/Lobby/Overlay 가 fields 보고 UI 갱신.

#### Category 5: 보드 (5 fields)

```json
{
  "OldBoardCards": "AhKsQd",
  "CardsOnTable": "AhKsQdTc",
  "NumBoards": 1,
  "CardsPerPlayer": 2,
  "ExtraCardsPerPlayer": 0
}
```

#### Category 6: 상태 (6 fields)

```json
{
  "HandInProgress": true,
  "EnhMode": false,
  "GfxEnabled": true,
  "Streaming": true,
  "Recording": true,
  "ProVersion": false
}
```

#### Category 7: 디스플레이 (7 fields)

```json
{
  "ShowPanel": true,
  "StripDisplay": "cumwin",
  "TickerVisible": true,
  "FieldVisible": true,
  "PlayerPicW": 320,
  "PlayerPicH": 240,
  "DelayedFieldVisibility": false
}
```

#### Category 8: 특수 (6 fields) ★ RUN_IT_TWICE 핵심

```json
{
  "RunItTimes": 2,
  "RunItTimesRemaining": 1,
  "BombPot": 0,
  "SevenDeuce": 0,
  "CanChop": true,
  "IsChopped": false
}
```

> RUN_IT_TWICE 분기 = `RunItTimes > 1` 시 활성. CC Ch.6 의 10-state 의 RUN_IT_TWICE 가 본 fields 로 표현.

#### Category 9: 드로우 (4 fields) ★ Draw FSM 핵심

```json
{
  "DrawCompleted": 1,
  "DrawingPlayer": 5,
  "StudDrawInProgress": true,
  "AnteType": "std_ante"
}
```

> Draw FSM = state 가 아닌 fields 분기 (Command_Center Ch.6.3 참조).

---

## 3. PlayerInfoResponse Schema (20 fields)

좌석별 (0-9) 개별 송출. 매 좌석 변경 시.

```json
{
  "Player": 3,
  "Name": "Daniel Negreanu",
  "LongName": "Daniel Negreanu",
  "HasCards": true,
  "Folded": false,
  "AllIn": false,
  "SitOut": false,
  "Bet": 800,
  "DeadBet": 100,
  "Stack": 156400,
  "NitGame": 0,
  "HasPic": true,
  "Country": "CA",
  "Vpip": 32,
  "Pfr": 24,
  "Agr": 1.8,
  "Wtsd": 28,
  "CumWin": 245000
}
```

> ★ **5 통계 (VPIP/PFR/AGR/Wtsd/CumWin)** = Lobby.md Ch.7 통계 5종 cascade. Ticker 시스템 (RIVE_Standards Ch.23) 에도 노출.

---

## 4. Engine → BO → Client 송출 흐름

```
   Engine 상태 변경
        │
        ▼
   Engine: GameInfoResponse 생성 (75+ fields)
        │
        ▼  REST POST
   BO: state 저장 + WS broadcast
        │
        ▼  WS push (다중 client)
   ┌─────────┬─────────┬─────────┐
   ▼         ▼         ▼         ▼
   CC      Lobby    Overlay   (기타)
   │         │         │
   ▼         ▼         ▼
   fields 비교 → 자체 UI 갱신
   (state enum 인식 X)
```

### 4.1 송출 빈도

- **GameInfoResponse**: 매 state 변경 시 (HAND_START / BETTING_ROUND_END / SHOWDOWN 등)
- **PlayerInfoResponse**: 매 좌석 변경 시 (BET / FOLD / ALL_IN 등)
- **Backward compatibility**: 기존 REST API 와 양립 (CC → Engine REST POST 유지)

### 4.2 Delta sync 권고 (대역폭 최적화)

PokerGFX 정본 (line 2531) 의 패턴 차용:
> "마스터가 변경된 데이터만 전송하여 대역폭을 절약. `_lastGameStateUpdate` 타임스탬프로 변경 추적"

EBS 적용:
- Engine = 변경 fields 만 송출 (`changed_fields` array)
- Client = 변경 fields 만 받아 UI 갱신
- timestamp 기반 정합 검증

---

## 5. 메시지 envelope

```json
{
  "event": "game_state_updated",
  "timestamp": "2026-05-17T14:32:18.123Z",
  "table_id": "FT-W3-001",
  "hand_number": 247,
  "changed_categories": ["betting", "seats", "drawing"],
  "data": {
    // (위 카테고리별 fields)
  }
}
```

---

## 6. CC / Lobby / Overlay 별 활용 패턴

### 6.1 CC (Command Center)

- **수신**: GameInfoResponse + PlayerInfoResponse (좌석별)
- **활용**: fields 보고 ActionPanel / PlayerColumn / StatusBar UI 갱신
- **State**: 자체 보유 안 함 (Command_Center Ch.6.5 L5 Stateless Display)

### 6.2 Lobby

- **수신**: PlayerInfoResponse (Players 화면) + GameInfoResponse (Tables grid)
- **활용**: Wtsd/CumWin Ticker + Chip count + KPI strip

### 6.3 Overlay (Rive)

- **수신**: GameInfoResponse + PlayerInfoResponse
- **활용**: Rive Variable 채우기 (RIVE_Standards.md 5 작가 중 Engine + EBS DB)

---

## 7. PokerGFX 정본 인용 위치

`C:/claude/ebs-archive-backup/07-archive/legacy-repos/ebs_reverse/docs/02-design/pokergfx-reverse-engineering-complete.md`:

| line | 내용 |
|------|------|
| 1574-1645 | net_conn 113+ commands 카테고리화 |
| **1647-1662** | **GameInfoResponse 75+ fields 9 카테고리** ★ |
| **1663-1684** | **PlayerInfoResponse 20 fields (Wtsd/CumWin 포함)** ★ |
| 1686-1707 | IClientNetworkListener 16 콜백 |
| 2531 | Delta sync 패턴 (변경 fields 만 송출) |

---

## 8. 변경 이력

| 날짜 | 버전 | 변경 |
|------|------|------|
| 2026-05-17 | 1.0.0 | 본 doc 신규 작성 (Foundation §B.3 + CC Ch.6.4 cascade) |
