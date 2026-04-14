# Seed Data (formerly contracts/data/DATA-06)

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 개발/테스트용 시드 데이터 초판 |

---

## 개요

EBS 개발/테스트 환경에서 사용하는 초기 데이터를 정의한다. `alembic upgrade head` 이후 시드 스크립트를 실행하여 투입한다.

**실행 명령:**

```bash
python -m bo.db.seed
```

---

## 1. 기본 Admin 계정

| 필드 | 값 |
|------|---|
| email | `admin@ebs.local` |
| password_hash | (bcrypt hash of "admin1234!") |
| display_name | `EBS Admin` |
| role | `admin` |
| is_active | true |
| totp_enabled | false |

**추가 테스트 계정:**

| email | display_name | role |
|-------|-------------|------|
| `operator1@ebs.local` | `Operator 1` | operator |
| `operator2@ebs.local` | `Operator 2` | operator |
| `viewer@ebs.local` | `Viewer` | viewer |

> 비밀번호: 모든 테스트 계정은 `test1234!`

---

## 2. 게임 변형 레코드 (22종)

Config 테이블에 게임 enum 매핑을 시드 데이터로 등록한다.

| game enum | 이름 | game_class | cards_per_player |
|:---------:|------|:----------:|:----------------:|
| 0 | No Limit Hold'em | flop (0) | 2 |
| 1 | Limit Hold'em | flop (0) | 2 |
| 2 | Short Deck Hold'em | flop (0) | 2 |
| 3 | Pineapple | flop (0) | 3 |
| 4 | Pot Limit Omaha | flop (0) | 4 |
| 5 | Omaha Hi-Lo | flop (0) | 4 |
| 6 | 5-Card PLO | flop (0) | 5 |
| 7 | 5-Card PLO Hi-Lo | flop (0) | 5 |
| 8 | Big O (5-Card Omaha) | flop (0) | 5 |
| 9 | 6-Card PLO | flop (0) | 6 |
| 10 | Sviten Special | flop (0) | 5 |
| 11 | Courchevel | flop (0) | 5 |
| 12 | NL 2-7 Single Draw | draw (1) | 5 |
| 13 | 2-7 Triple Draw | draw (1) | 5 |
| 14 | A-5 Triple Draw | draw (1) | 5 |
| 15 | Badugi | draw (1) | 4 |
| 16 | Badacey | draw (1) | 5 |
| 17 | Badeucey | draw (1) | 5 |
| 18 | 5-Card Draw | draw (1) | 5 |
| 19 | 7-Card Stud | stud (2) | 7 |
| 20 | 7-Card Stud Hi-Lo | stud (2) | 7 |
| 21 | Razz | stud (2) | 7 |

---

## 3. 샘플 Competition / Series / Event / Flight

### Competition

| competition_id | name | competition_type | competition_tag |
|:-:|------|:-:|:-:|
| 1 | WSOP | 0 | 1 (Bracelets) |
| 2 | WSOPC | 1 | 2 (Circuit) |

### Series

| series_id | competition_id | series_name | year | begin_at | end_at |
|:-:|:-:|------|:-:|------|------|
| 1 | 1 | 2026 WSOP | 2026 | 2026-05-27 | 2026-07-16 |
| 2 | 2 | 2026 WSOPC Seoul | 2026 | 2026-03-15 | 2026-03-25 |

### Event

| event_id | series_id | event_no | event_name | game_type | bet_structure | table_size | starting_chip | game_mode |
|:-:|:-:|:-:|------|:-:|:-:|:-:|:-:|------|
| 1 | 1 | 1 | $10,000 NL Hold'em Main Event | 0 | 0 | 9 | 60000 | single |
| 2 | 1 | 2 | $1,500 HORSE | 0 | 0 | 8 | 25000 | fixed_rotation |
| 3 | 1 | 3 | $10,000 Dealer's Choice | 0 | 0 | 6 | 50000 | dealers_choice |

### Flight

| event_flight_id | event_id | display_name | status |
|:-:|:-:|------|------|
| 1 | 1 | Day 1A | running |
| 2 | 1 | Day 1B | created |
| 3 | 1 | Day 2 | created |
| 4 | 2 | Day 1 | running |

---

## 4. 샘플 Table / Seat / Player

### Table

| table_id | event_flight_id | table_no | name | type | status | max_players |
|:-:|:-:|:-:|------|------|------|:-:|
| 1 | 1 | 1 | Feature Table 1 | feature | live | 9 |
| 2 | 1 | 2 | Table 2 | general | setup | 9 |
| 3 | 4 | 1 | HORSE Feature | feature | live | 8 |

### Player

| player_id | first_name | last_name | nationality | country_code | source |
|:-:|------|------|------|:-:|------|
| 1 | Daniel | Negreanu | Canadian | CA | manual |
| 2 | Phil | Ivey | American | US | manual |
| 3 | Fedor | Holz | German | DE | manual |
| 4 | Justin | Bonomo | American | US | manual |
| 5 | Bryn | Kenney | American | US | manual |
| 6 | Erik | Seidel | American | US | manual |
| 7 | John | Doe | American | US | manual |
| 8 | Jane | Smith | British | GB | manual |
| 9 | Test | Player | Korean | KR | manual |

### Seat (Table 1 - Feature Table, 9석)

| seat_id | table_id | seat_no | player_id | player_name | chip_count | status |
|:-:|:-:|:-:|:-:|------|:-:|------|
| 1 | 1 | 0 | 1 | D. Negreanu | 85000 | occupied |
| 2 | 1 | 1 | 2 | P. Ivey | 120000 | occupied |
| 3 | 1 | 2 | 3 | F. Holz | 45000 | occupied |
| 4 | 1 | 3 | 4 | J. Bonomo | 92000 | occupied |
| 5 | 1 | 4 | 5 | B. Kenney | 78000 | occupied |
| 6 | 1 | 5 | 6 | E. Seidel | 55000 | occupied |
| 7 | 1 | 6 | NULL | — | 0 | vacant |
| 8 | 1 | 7 | NULL | — | 0 | vacant |
| 9 | 1 | 8 | NULL | — | 0 | vacant |

---

## 5. 샘플 BlindStructure (WSOP 표준)

### Structure: $10K Main Event

| blind_structure_id | name |
|:-:|------|
| 1 | $10K Main Event Structure |

### Levels

| level_no | small_blind | big_blind | ante | duration_minutes | detail_type |
|:-:|:-:|:-:|:-:|:-:|:-:|
| 1 | 100 | 200 | 200 | 120 | 0 (Blind) |
| 2 | 200 | 300 | 300 | 120 | 0 |
| 3 | 200 | 400 | 400 | 120 | 0 |
| 4 | 300 | 600 | 600 | 120 | 0 |
| — | — | — | — | 15 | 1 (Break) |
| 5 | 400 | 800 | 800 | 120 | 0 |
| 6 | 500 | 1000 | 1000 | 120 | 0 |
| 7 | 600 | 1200 | 1200 | 120 | 0 |
| 8 | 800 | 1600 | 1600 | 120 | 0 |
| — | — | — | — | 60 | 2 (DinnerBreak) |
| 9 | 1000 | 2000 | 2000 | 120 | 0 |
| 10 | 1200 | 2500 | 2500 | 120 | 0 |
| 11 | 1500 | 3000 | 3000 | 120 | 0 |
| 12 | 2000 | 4000 | 4000 | 120 | 0 |

> 참조: WSOP 2026 Production Plan — 실제 블라인드 구조는 이벤트마다 다름. 이 시드는 개발 기준.

---

## 6. Mock RFID 덱 데이터

### Deck

| deck_id | table_id | label | status | registered_count |
|:-:|:-:|------|------|:-:|
| 1 | 1 | Deck A (Mock) | mock | 52 |
| 2 | 1 | Deck B (Mock) | mock | 52 |

### DeckCard (Deck 1 - 52장)

수트별 13장씩, 총 52장. Mock 모드에서 자동 생성.

| suit | 이름 | rank 범위 | 예시 UID | 예시 display |
|:----:|------|:---------:|----------|:----------:|
| 0 | Club | 0-12 | `MOCK_C_00` ~ `MOCK_C_12` | 2c ~ Ac |
| 1 | Diamond | 0-12 | `MOCK_D_00` ~ `MOCK_D_12` | 2d ~ Ad |
| 2 | Heart | 0-12 | `MOCK_H_00` ~ `MOCK_H_12` | 2h ~ Ah |
| 3 | Spade | 0-12 | `MOCK_S_00` ~ `MOCK_S_12` | 2s ~ As |

**Mock UID 생성 규칙:**

```
MOCK_{suit_initial}_{rank:02d}
```

예: `MOCK_C_00` = 2 of Clubs, `MOCK_S_12` = Ace of Spades

> 참조: Mock 모드 정의 — BS-00 Definitions 9

---

## 7. 기본 Config

| key | value | category | description |
|-----|-------|----------|-------------|
| rfid_mode | mock | rfid | RFID 모드 (mock / real) |
| rfid_scan_interval_ms | 100 | rfid | RFID 스캔 간격 (ms) |
| log_level | info | system | 로그 레벨 (debug/info/warn/error) |
| session_timeout_min | 480 | system | 세션 타임아웃 (분, 기본 8시간) |
| default_table_size | 9 | system | 기본 테이블 크기 |
| default_game_type | 0 | system | 기본 게임 종류 (Hold'em) |
| overlay_resolution | 1920x1080 | output | 기본 오버레이 해상도 |
| security_delay_default | 0 | output | 기본 Security Delay (초) |
| auto_save_interval_sec | 30 | system | 자동 저장 간격 (초) |
| backup_retention_days | 365 | system | 백업 보존 기간 (일) |

---

## 8. 기본 Skin / OutputPreset

### Skin

| skin_id | name | is_default | description |
|:-:|------|:-:|------|
| 1 | WSOP Classic | true | WSOP 2026 기본 스킨 |
| 2 | WSOP Dark | false | WSOP 다크 테마 |
| 3 | Minimal | false | 최소 UI 테스트용 |

### OutputPreset

| preset_id | name | output_type | width | height | framerate | security_delay_sec | is_default |
|:-:|------|------|:-:|:-:|:-:|:-:|:-:|
| 1 | 1080p NDI | ndi | 1920 | 1080 | 60 | 0 | true |
| 2 | 4K NDI | ndi | 3840 | 2160 | 60 | 0 | false |
| 3 | 1080p HDMI + Delay | hdmi | 1920 | 1080 | 60 | 30 | false |
| 4 | 1080p Chroma | ndi | 1920 | 1080 | 60 | 0 | false |
