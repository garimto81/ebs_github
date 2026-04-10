# TEST-04: Mock 데이터

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | WSOP LIVE, RFID, Player, Config Mock 데이터 정의 |

---

## 개요

테스트에서 사용하는 모든 Mock 데이터의 구조와 샘플을 정의한다. 실제 외부 서비스(WSOP LIVE API, RFID 하드웨어)를 대체하며, 결정론적 테스트 재현을 보장한다.

> 참조: Mock 모드 — BS-00 §9, RFID HAL — API-03 §6, 시나리오 스크립트 — BS-06-00 §4.3

---

## 1. Mock WSOP LIVE 응답 — JSON Fixtures

### 1.1 Competition

```json
{
  "competition_id": "COMP-001",
  "name": "WSOP",
  "year": 2026,
  "status": "active"
}
```

### 1.2 Series

```json
{
  "series_id": "SER-2026-001",
  "competition_id": "COMP-001",
  "name": "2026 World Series of Poker",
  "start_date": "2026-05-27",
  "end_date": "2026-07-16",
  "venue": "Las Vegas Convention Center",
  "status": "active"
}
```

### 1.3 Event

```json
{
  "event_id": "EVT-001",
  "series_id": "SER-2026-001",
  "event_number": 1,
  "name": "Event #1: $10,000 No-Limit Hold'em",
  "game_type": "NL_HOLDEM",
  "buy_in": 10000,
  "start_date": "2026-05-27",
  "status": "running",
  "total_entries": 1200
}
```

### 1.4 Flight

```json
{
  "flight_id": "FLT-001",
  "event_id": "EVT-001",
  "name": "Day 1A",
  "start_time": "2026-05-27T12:00:00Z",
  "status": "running",
  "tables_count": 120,
  "players_remaining": 800
}
```

### 1.5 Player (단일)

```json
{
  "player_id": "PLR-001",
  "first_name": "John",
  "last_name": "Doe",
  "nationality": "US",
  "city": "Las Vegas",
  "profile_image_url": null,
  "wsop_bracelets": 3,
  "total_earnings": 5000000
}
```

### 1.6 BlindStructure

```json
{
  "structure_id": "BS-NL-001",
  "name": "NL Hold'em Standard",
  "levels": [
    { "level": 1, "sb": 50, "bb": 100, "ante": 0, "duration_min": 60 },
    { "level": 2, "sb": 100, "bb": 200, "ante": 0, "duration_min": 60 },
    { "level": 3, "sb": 150, "bb": 300, "ante": 50, "duration_min": 60 },
    { "level": 4, "sb": 200, "bb": 400, "ante": 50, "duration_min": 60 },
    { "level": 5, "sb": 300, "bb": 600, "ante": 100, "duration_min": 60 }
  ]
}
```

---

## 2. Mock RFID 이벤트 스트림 — YAML 시나리오

### 2.1 Basic: 정상 핸드 (2인 Heads-Up)

```yaml
scenario: "basic-headsup"
description: "2인 Heads-Up, Pre-Flop → Showdown 정상 진행"
game_type: NL_HOLDEM
players:
  - { seat: 0, name: "P0", stack: 10000 }
  - { seat: 1, name: "P1", stack: 10000 }
blind: { sb: 50, bb: 100 }

events:
  - type: DeckRegistered
    delay_ms: 0

  # P0 홀카드
  - type: CardDetected
    delay_ms: 100
    payload: { antenna_id: 0, suit: 0, rank: 12 }  # As
  - type: CardDetected
    delay_ms: 50
    payload: { antenna_id: 0, suit: 1, rank: 12 }  # Ah

  # P1 홀카드
  - type: CardDetected
    delay_ms: 100
    payload: { antenna_id: 2, suit: 0, rank: 11 }  # Ks
  - type: CardDetected
    delay_ms: 50
    payload: { antenna_id: 2, suit: 1, rank: 11 }  # Kh

  # Flop
  - type: CardDetected
    delay_ms: 500
    payload: { antenna_id: 20, suit: 2, rank: 10 }  # Qd
  - type: CardDetected
    delay_ms: 50
    payload: { antenna_id: 21, suit: 3, rank: 5 }   # 7c
  - type: CardDetected
    delay_ms: 50
    payload: { antenna_id: 22, suit: 2, rank: 1 }   # 3d

  # Turn
  - type: CardDetected
    delay_ms: 300
    payload: { antenna_id: 23, suit: 0, rank: 8 }   # Ts

  # River
  - type: CardDetected
    delay_ms: 300
    payload: { antenna_id: 23, suit: 3, rank: 0 }   # 2c
```

### 2.2 Side Pot: 3인 All-In (스택 차이)

```yaml
scenario: "side-pot-three-players"
description: "3인 All-In, 스택 차이로 Side Pot 2개 생성"
game_type: NL_HOLDEM
players:
  - { seat: 0, name: "P0", stack: 1000 }
  - { seat: 1, name: "P1", stack: 3000 }
  - { seat: 2, name: "P2", stack: 5000 }
blind: { sb: 50, bb: 100 }

events:
  - type: DeckRegistered
    delay_ms: 0

  # P0 홀카드
  - type: CardDetected
    delay_ms: 100
    payload: { antenna_id: 0, suit: 0, rank: 12 }  # As
  - type: CardDetected
    delay_ms: 50
    payload: { antenna_id: 0, suit: 2, rank: 12 }  # Ad

  # P1 홀카드
  - type: CardDetected
    delay_ms: 100
    payload: { antenna_id: 2, suit: 1, rank: 11 }  # Kh
  - type: CardDetected
    delay_ms: 50
    payload: { antenna_id: 2, suit: 0, rank: 11 }  # Ks

  # P2 홀카드
  - type: CardDetected
    delay_ms: 100
    payload: { antenna_id: 4, suit: 1, rank: 10 }  # Qh
  - type: CardDetected
    delay_ms: 50
    payload: { antenna_id: 4, suit: 2, rank: 10 }  # Qd

  # Board 5장 (All-In Runout)
  - type: CardDetected
    delay_ms: 500
    payload: { antenna_id: 20, suit: 3, rank: 5 }   # 7c
  - type: CardDetected
    delay_ms: 50
    payload: { antenna_id: 21, suit: 2, rank: 3 }   # 5d
  - type: CardDetected
    delay_ms: 50
    payload: { antenna_id: 22, suit: 1, rank: 1 }   # 3h
  - type: CardDetected
    delay_ms: 300
    payload: { antenna_id: 23, suit: 0, rank: 7 }   # 9s
  - type: CardDetected
    delay_ms: 300
    payload: { antenna_id: 23, suit: 3, rank: 0 }   # 2c
```

### 2.3 All-In at Flop: 2인 All-In + Run It Twice

```yaml
scenario: "all-in-run-it-twice"
description: "2인 Flop All-In, Run It Twice 진행"
game_type: NL_HOLDEM
players:
  - { seat: 0, name: "P0", stack: 5000 }
  - { seat: 1, name: "P1", stack: 5000 }
blind: { sb: 50, bb: 100 }
run_it_times: 2

events:
  - type: DeckRegistered
    delay_ms: 0

  # P0 홀카드
  - type: CardDetected
    delay_ms: 100
    payload: { antenna_id: 0, suit: 0, rank: 12 }  # As
  - type: CardDetected
    delay_ms: 50
    payload: { antenna_id: 0, suit: 1, rank: 12 }  # Ah

  # P1 홀카드
  - type: CardDetected
    delay_ms: 100
    payload: { antenna_id: 2, suit: 0, rank: 11 }  # Ks
  - type: CardDetected
    delay_ms: 50
    payload: { antenna_id: 2, suit: 1, rank: 11 }  # Kh

  # Flop
  - type: CardDetected
    delay_ms: 500
    payload: { antenna_id: 20, suit: 2, rank: 11 }  # Kd
  - type: CardDetected
    delay_ms: 50
    payload: { antenna_id: 21, suit: 3, rank: 5 }   # 7c
  - type: CardDetected
    delay_ms: 50
    payload: { antenna_id: 22, suit: 2, rank: 1 }   # 3d

  # Run 1: Turn + River
  - type: CardDetected
    delay_ms: 300
    payload: { antenna_id: 23, suit: 0, rank: 0 }   # 2s
  - type: CardDetected
    delay_ms: 300
    payload: { antenna_id: 23, suit: 3, rank: 4 }   # 6c

  # Run 2: Turn + River
  - type: CardDetected
    delay_ms: 300
    payload: { antenna_id: 23, suit: 0, rank: 10 }  # Qs
  - type: CardDetected
    delay_ms: 300
    payload: { antenna_id: 23, suit: 1, rank: 8 }   # Th
```

---

## 3. Mock Player DB — 10명 샘플

| player_id | first_name | last_name | nationality | stack | wsop_bracelets |
|-----------|-----------|-----------|:-----------:|:-----:|:--------------:|
| PLR-001 | John | Doe | US | 10000 | 3 |
| PLR-002 | Jane | Smith | UK | 10000 | 1 |
| PLR-003 | Hiroshi | Tanaka | JP | 10000 | 0 |
| PLR-004 | Maria | Garcia | ES | 10000 | 2 |
| PLR-005 | Wei | Chen | CN | 10000 | 0 |
| PLR-006 | Pierre | Dubois | FR | 10000 | 1 |
| PLR-007 | Alex | Mueller | DE | 10000 | 0 |
| PLR-008 | Seo-Yun | Kim | KR | 10000 | 0 |
| PLR-009 | Lucas | Silva | BR | 10000 | 1 |
| PLR-010 | Emma | Johnson | CA | 10000 | 4 |

```json
[
  { "player_id": "PLR-001", "first_name": "John", "last_name": "Doe", "nationality": "US", "city": "Las Vegas", "wsop_bracelets": 3, "total_earnings": 5000000 },
  { "player_id": "PLR-002", "first_name": "Jane", "last_name": "Smith", "nationality": "UK", "city": "London", "wsop_bracelets": 1, "total_earnings": 1200000 },
  { "player_id": "PLR-003", "first_name": "Hiroshi", "last_name": "Tanaka", "nationality": "JP", "city": "Tokyo", "wsop_bracelets": 0, "total_earnings": 300000 },
  { "player_id": "PLR-004", "first_name": "Maria", "last_name": "Garcia", "nationality": "ES", "city": "Madrid", "wsop_bracelets": 2, "total_earnings": 2800000 },
  { "player_id": "PLR-005", "first_name": "Wei", "last_name": "Chen", "nationality": "CN", "city": "Beijing", "wsop_bracelets": 0, "total_earnings": 150000 },
  { "player_id": "PLR-006", "first_name": "Pierre", "last_name": "Dubois", "nationality": "FR", "city": "Paris", "wsop_bracelets": 1, "total_earnings": 900000 },
  { "player_id": "PLR-007", "first_name": "Alex", "last_name": "Mueller", "nationality": "DE", "city": "Berlin", "wsop_bracelets": 0, "total_earnings": 450000 },
  { "player_id": "PLR-008", "first_name": "Seo-Yun", "last_name": "Kim", "nationality": "KR", "city": "Seoul", "wsop_bracelets": 0, "total_earnings": 200000 },
  { "player_id": "PLR-009", "first_name": "Lucas", "last_name": "Silva", "nationality": "BR", "city": "Sao Paulo", "wsop_bracelets": 1, "total_earnings": 750000 },
  { "player_id": "PLR-010", "first_name": "Emma", "last_name": "Johnson", "nationality": "CA", "city": "Toronto", "wsop_bracelets": 4, "total_earnings": 8000000 }
]
```

---

## 4. Mock Config — 기본 Settings 프리셋

### 4.1 Output 프리셋

```json
{
  "output_preset_id": "OUT-DEFAULT",
  "name": "Default 1080p NDI",
  "resolution": { "width": 1920, "height": 1080 },
  "output_type": "NDI",
  "security_delay_sec": 10,
  "chroma_key": false,
  "fps": 60
}
```

### 4.2 Overlay 프리셋

```json
{
  "overlay_preset_id": "OVL-DEFAULT",
  "name": "WSOP Standard",
  "skin_id": "SKIN-WSOP-2026",
  "card_style": "four_color",
  "show_equity": true,
  "show_pot_odds": false,
  "animation_speed_ms": 300
}
```

### 4.3 Game 프리셋

```json
{
  "game_preset_id": "GAME-NL-HOLDEM",
  "name": "NL Hold'em Standard",
  "game_type": "NL_HOLDEM",
  "bet_structure": "NL",
  "blind_structure_id": "BS-NL-001",
  "current_level": 1,
  "ante_type": "none",
  "bomb_pot_enabled": false,
  "straddle_allowed": false,
  "run_it_twice_allowed": true,
  "max_seats": 10
}
```

### 4.4 Statistics 프리셋

```json
{
  "stats_preset_id": "STAT-DEFAULT",
  "name": "Standard Display",
  "show_vpip": true,
  "show_pfr": true,
  "show_wtsd": true,
  "show_aggression": true,
  "show_hands_played": true,
  "show_win_rate": false
}
```

### 4.5 System Config (BO 글로벌)

```json
{
  "config_id": "SYS-DEFAULT",
  "rfid_mode": "mock",
  "log_level": "info",
  "auto_save_interval_sec": 30,
  "websocket_heartbeat_sec": 15,
  "max_undo_depth": 5,
  "hand_history_retention_days": 365
}
```

---

## 비활성 조건

- Real RFID 하드웨어 데이터: 항상 비활성 (Mock 데이터만)
- 외부 WSOP LIVE API 호출: 항상 비활성 (JSON fixture만)

---

## 영향 받는 요소

| 요소 | 관계 |
|------|------|
| TEST-01 Test Plan | Mock 전략의 데이터 상세 |
| TEST-02 E2E Scenarios | 시나리오에서 참조하는 Mock 데이터 |
| TEST-03 Game Engine Fixtures | 테스트 입력값의 데이터 소스 |
| BS-06-00 Triggers §4.3 | YAML 시나리오 형식 정의 |
| API-03 RFID HAL §6.4 | 시나리오 파일 형식 참조 |
