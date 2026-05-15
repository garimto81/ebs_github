---
title: ER Diagram
owner: team2
tier: internal
legacy-id: DATA-01
last-updated: 2026-04-15
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "DATA-01 ER 다이어그램 완결"
confluence-page-id: 3818619331
confluence-parent-id: 3811770578
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818619331/EBS+ER+Diagram
mirror: none
---
# DATA-01 ER 다이어그램

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 3-앱 아키텍처 BO DB ER 다이어그램 초판 |

---

## 개요

EBS Back Office DB의 엔티티 관계를 정의한다. 3개 도메인(대회 계층, 게임 도메인, Admin 도메인)으로 분할하여 가독성을 확보한다.

> 참조: Game Engine 내부 데이터(GameState, Player, Card, Pot)는 BS-06-00-REF Ch.2에 정의. 이 문서는 BO 영구 저장 엔티티만 다룬다.

---

## Overview ER (전체 도메인)

```mermaid
erDiagram
    Competition ||--o{ Series : "1:N"
    Series ||--o{ Event : "1:N"
    Event ||--o{ Flight : "1:N"
    Event ||--o{ BlindStructureLevel : "1:N"
    Flight ||--o{ Table : "1:N"
    Table ||--o{ Seat : "1:N (max 10)"
    Table ||--o{ Hand : "1:N"
    Table ||--o{ Deck : "0:N"
    Seat ||--o| Player : "0:1"
    Hand ||--o{ HandPlayer : "1:N"
    Hand ||--o{ HandAction : "1:N"
    User ||--o{ UserSession : "1:N"
    User ||--o{ AuditLog : "1:N"
```

---

## Detail ER 1: 대회 계층 (Competition ~ Seat)

대회 계층은 WSOP LIVE 데이터 구조를 그대로 따른다.

```mermaid
erDiagram
    Competition {
        int competition_id PK
        string name
        int competition_type
        int competition_tag
    }

    Series {
        int series_id PK
        int competition_id FK
        string series_name
        int year
        date begin_at
        date end_at
        string time_zone
        string country_code
        string source
    }

    Event {
        int event_id PK
        int series_id FK
        int event_no
        string event_name
        int game_type
        int bet_structure
        int game_mode
        int table_size
        int starting_chip
        int blind_structure_id
        string status
        string source
    }

    Flight {
        int event_flight_id PK
        int event_id FK
        string display_name
        datetime start_time
        int entries
        int players_left
        string status
        string source
    }

    Table {
        int table_id PK
        int event_flight_id FK
        int table_no
        string name
        string type
        string status
        int rfid_reader_id
        bool deck_registered
        int delay_seconds
        string source
    }

    Seat {
        int seat_id PK
        int table_id FK
        int seat_no
        int player_id FK
        string status
        int chip_count
    }

    Player {
        int player_id PK
        string wsop_id
        string first_name
        string last_name
        string nationality
        string country_code
        string source
    }

    Competition ||--o{ Series : "has"
    Series ||--o{ Event : "has"
    Event ||--o{ Flight : "has"
    Flight ||--o{ Table : "has"
    Table ||--o{ Seat : "has (0-10)"
    Seat }o--o| Player : "occupied by"
```

---

## Detail ER 2: 게임 도메인 (Hand, Action, Deck)

Hand 데이터는 Command Center에서 생성되어 BO DB에 기록된다.

```mermaid
erDiagram
    Table {
        int table_id PK
        string name
        string status
    }

    Hand {
        int hand_id PK
        int table_id FK
        int hand_number
        int game_type
        int bet_structure
        int dealer_seat
        string board_cards
        int pot_total
        string side_pots
        int current_street
        datetime started_at
        int duration_sec
    }

    HandPlayer {
        int id PK
        int hand_id FK
        int seat_no
        int player_id FK
        string hole_cards
        string final_action
        bool is_winner
        int pnl
        string hand_rank
        float win_probability
    }

    HandAction {
        int id PK
        int hand_id FK
        int seat_no
        string action_type
        int action_amount
        string street
        int action_order
    }

    Deck {
        int deck_id PK
        int table_id FK
        string label
        string status
        int registered_count
        datetime registered_at
    }

    DeckCard {
        int id PK
        int deck_id FK
        int suit
        int rank
        string rfid_uid
        string display
    }

    Table ||--o{ Hand : "has"
    Table ||--o{ Deck : "has (0-N)"
    Hand ||--o{ HandPlayer : "has (2-10)"
    Hand ||--o{ HandAction : "has (1-N)"
    Deck ||--o{ DeckCard : "has (0-52)"
    HandPlayer }o--o| Player : "refs"
```

---

## Detail ER 3: Admin 도메인 (User, Session, Config, AuditLog)

```mermaid
erDiagram
    User {
        int user_id PK
        string email
        string display_name
        string role
        bool is_active
        datetime last_login_at
    }

    UserSession {
        int id PK
        int user_id FK
        int last_series_id
        int last_event_id
        int last_flight_id
        int last_table_id
        string last_screen
        datetime updated_at
    }

    AuditLog {
        int id PK
        int user_id FK
        string entity_type
        int entity_id
        string action
        string detail
        datetime created_at
    }

    Config {
        int id PK
        string key
        string value
        string category
        datetime updated_at
    }

    BlindStructure {
        int blind_structure_id PK
        string name
    }

    BlindStructureLevel {
        int id PK
        int blind_structure_id FK
        int level_no
        int small_blind
        int big_blind
        int ante
        int duration_minutes
        int detail_type
    }

    Skin {
        int skin_id PK
        string name
        string description
        string theme_data
        bool is_default
    }

    OutputPreset {
        int preset_id PK
        string name
        string output_type
        int width
        int height
        int security_delay_sec
        bool chroma_key
    }

    User ||--o{ UserSession : "has"
    User ||--o{ AuditLog : "authored"
    BlindStructure ||--o{ BlindStructureLevel : "has (1-N)"
```

---

## 엔티티 수량 요약

| 도메인 | 엔티티 | 개수 |
|--------|--------|:----:|
| 대회 계층 | Competition, Series, Event, Flight, Table, Seat, Player | 7 |
| 게임 | Hand, HandPlayer, HandAction, Deck, DeckCard | 5 |
| Admin | User, UserSession, AuditLog, Config, BlindStructure, BlindStructureLevel, Skin, OutputPreset | 8 |
| **합계** | | **20** |
