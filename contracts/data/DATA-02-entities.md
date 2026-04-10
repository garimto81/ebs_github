# DATA-02 엔티티 필드 정의

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | BO 고유 엔티티 20종 필드 정의 초판 |

---

## 개요

EBS Back Office DB의 모든 엔티티 필드를 정의한다. Game Engine 내부 데이터(GameState, Player, Card, Pot, Blinds, GameTypeData, PlayerStats)는 BS-06-00-REF Ch.2에 정의되어 있으므로 중복 기술하지 않는다.

> 참조: BS-06-00-REF Ch.2 — GameState(22필드), Player(11필드), Card(4필드), Pot(2필드), Blinds(5필드), GameTypeData(61필드), PlayerStats(11필드)

---

## 1. 대회 계층 엔티티

### 1.1 Competition

최상위 대회 브랜드. WSOP, WSOPC, APL 등.

| 필드 | 타입 | 설명 | 제약조건 | 기본값 |
|------|------|------|----------|--------|
| competition_id | INTEGER | PK | AUTO INCREMENT | — |
| name | TEXT | 대회명 | NOT NULL | — |
| competition_type | INTEGER | 대회 유형 enum (0-4) | NOT NULL | 0 (WSOP) |
| competition_tag | INTEGER | 대회 태그 enum (0-3) | NOT NULL | 0 (None) |
| created_at | DATETIME | 생성 시각 | NOT NULL | now() |
| updated_at | DATETIME | 수정 시각 | NOT NULL | now() |

> 참조: competition_type, competition_tag enum — BS-06-00-REF 1.2.7, 1.2.8

### 1.2 Series

대회 시리즈 (연간). WSOP LIVE API 또는 수동 생성.

| 필드 | 타입 | 설명 | 제약조건 | 기본값 |
|------|------|------|----------|--------|
| series_id | INTEGER | PK | AUTO INCREMENT | — |
| competition_id | INTEGER | FK → Competition | NOT NULL | — |
| series_name | TEXT | 시리즈명 | NOT NULL | — |
| year | INTEGER | 연도 | NOT NULL | — |
| begin_at | DATE | 시작일 | NOT NULL | — |
| end_at | DATE | 종료일 | NOT NULL | — |
| image_url | TEXT | 대표 이미지 URL | — | NULL |
| time_zone | TEXT | 시간대 | NOT NULL | 'UTC' |
| currency | TEXT | 통화 | — | 'USD' |
| country_code | TEXT | 국가 코드 (ISO 3166) | — | NULL |
| is_completed | BOOLEAN | 완료 여부 | NOT NULL | false |
| is_displayed | BOOLEAN | 목록 표시 여부 | NOT NULL | true |
| is_demo | BOOLEAN | 데모/테스트 여부 | NOT NULL | false |
| source | TEXT | 데이터 소스 | NOT NULL | 'manual' |
| synced_at | DATETIME | API 동기화 시각 | — | NULL |
| created_at | DATETIME | 생성 시각 | NOT NULL | now() |
| updated_at | DATETIME | 수정 시각 | NOT NULL | now() |

### 1.3 Event

개별 토너먼트/이벤트. WSOP LIVE API 또는 수동 생성.

| 필드 | 타입 | 설명 | 제약조건 | 기본값 |
|------|------|------|----------|--------|
| event_id | INTEGER | PK | AUTO INCREMENT | — |
| series_id | INTEGER | FK → Series | NOT NULL | — |
| event_no | INTEGER | 이벤트 번호 | NOT NULL | — |
| event_name | TEXT | 이벤트명 | NOT NULL | — |
| buy_in | INTEGER | 바이인 금액 | — | NULL |
| display_buy_in | TEXT | 표시용 바이인 | — | NULL |
| game_type | INTEGER | 게임 종류 enum (0-21) | NOT NULL | 0 |
| bet_structure | INTEGER | 베팅 구조 enum (0-2) | NOT NULL | 0 |
| event_game_type | INTEGER | 이벤트 게임 대분류 (0-8) | NOT NULL | 0 |
| game_mode | TEXT | 'single' / 'fixed_rotation' / 'dealers_choice' | NOT NULL | 'single' |
| allowed_games | TEXT | Mix 모드 허용 게임 (JSON 직렬화) | — | NULL |
| rotation_order | TEXT | Fixed Rotation 순서 (JSON 직렬화) | — | NULL |
| rotation_trigger | TEXT | 전환 조건 (JSON 직렬화) | — | NULL |
| blind_structure_id | INTEGER | FK → BlindStructure | — | NULL |
| starting_chip | INTEGER | 시작 칩 수량 | — | NULL |
| table_size | INTEGER | 테이블당 최대 인원 | NOT NULL | 9 |
| total_entries | INTEGER | 총 참가자 | — | 0 |
| players_left | INTEGER | 남은 참가자 | — | 0 |
| start_time | DATETIME | 시작 일시 | — | NULL |
| status | TEXT | 이벤트 상태 | NOT NULL | 'created' |
| source | TEXT | 데이터 소스 | NOT NULL | 'manual' |
| synced_at | DATETIME | API 동기화 시각 | — | NULL |
| created_at | DATETIME | 생성 시각 | NOT NULL | now() |
| updated_at | DATETIME | 수정 시각 | NOT NULL | now() |

> 참조: game_type enum — BS-06-00-REF 1.1, event_game_type — 1.2.4, status — 1.2.5

### 1.4 Flight

Event의 진행 구간. Day 1A, Day 1B 등.

| 필드 | 타입 | 설명 | 제약조건 | 기본값 |
|------|------|------|----------|--------|
| event_flight_id | INTEGER | PK | AUTO INCREMENT | — |
| event_id | INTEGER | FK → Event | NOT NULL | — |
| display_name | TEXT | 표시명 (Day1A 등) | NOT NULL | — |
| start_time | DATETIME | 시작 시각 | — | NULL |
| is_tbd | BOOLEAN | 시간 미정 | NOT NULL | false |
| entries | INTEGER | 참가자 수 | — | 0 |
| players_left | INTEGER | 남은 참가자 | — | 0 |
| table_count | INTEGER | 테이블 수 | — | 0 |
| status | TEXT | Flight 상태 | NOT NULL | 'created' |
| play_level | INTEGER | 현재 블라인드 레벨 | — | 1 |
| remain_time | INTEGER | 레벨 남은 시간 (초) | — | NULL |
| source | TEXT | 데이터 소스 | NOT NULL | 'manual' |
| synced_at | DATETIME | API 동기화 시각 | — | NULL |
| created_at | DATETIME | 생성 시각 | NOT NULL | now() |
| updated_at | DATETIME | 수정 시각 | NOT NULL | now() |

### 1.5 Table

물리적 포커 테이블. Lobby에서 수동 생성.

| 필드 | 타입 | 설명 | 제약조건 | 기본값 |
|------|------|------|----------|--------|
| table_id | INTEGER | PK | AUTO INCREMENT | — |
| event_flight_id | INTEGER | FK → Flight | NOT NULL | — |
| table_no | INTEGER | 테이블 번호 | NOT NULL | — |
| name | TEXT | 테이블명 | NOT NULL, UNIQUE per flight | — |
| type | TEXT | 'feature' / 'general' | NOT NULL | 'general' |
| status | TEXT | TableFSM 상태 | NOT NULL | 'empty' |
| max_players | INTEGER | 최대 인원 | NOT NULL | 9 |
| game_type | INTEGER | 게임 종류 enum | NOT NULL | 0 |
| small_blind | INTEGER | SB 금액 | — | NULL |
| big_blind | INTEGER | BB 금액 | — | NULL |
| ante_type | INTEGER | 앤티 유형 enum (0-6) | NOT NULL | 0 |
| ante_amount | INTEGER | 앤티 금액 | NOT NULL | 0 |
| rfid_reader_id | INTEGER | 할당된 RFID 리더 ID | — | NULL |
| deck_registered | BOOLEAN | 덱 등록 완료 여부 | NOT NULL | false |
| output_type | TEXT | 출력 유형 (NDI/SDI 등) | — | NULL |
| current_game | INTEGER | 현재 게임 (Mix 모드) | — | NULL |
| delay_seconds | INTEGER | Security Delay (초) | NOT NULL | 0 |
| ring | INTEGER | 테이블 링 번호 | — | NULL |
| is_breaking_table | BOOLEAN | 브레이킹 여부 | NOT NULL | false |
| source | TEXT | 데이터 소스 | NOT NULL | 'manual' |
| created_at | DATETIME | 생성 시각 | NOT NULL | now() |
| updated_at | DATETIME | 수정 시각 | NOT NULL | now() |

### 1.6 Seat

테이블 내 좌석. 최대 10석 (0-9).

| 필드 | 타입 | 설명 | 제약조건 | 기본값 |
|------|------|------|----------|--------|
| seat_id | INTEGER | PK | AUTO INCREMENT | — |
| table_id | INTEGER | FK → Table | NOT NULL | — |
| seat_no | INTEGER | 좌석 번호 (0-9) | NOT NULL, CHECK(0-9) | — |
| player_id | INTEGER | FK → Player | — | NULL |
| wsop_id | TEXT | WSOP LIVE 선수 ID | — | NULL |
| player_name | TEXT | 표시용 이름 | — | NULL |
| nationality | TEXT | 국적 | — | NULL |
| country_code | TEXT | 국가 코드 | — | NULL |
| chip_count | INTEGER | 현재 칩 수량 | NOT NULL | 0 |
| profile_image | TEXT | 프로필 사진 URL | — | NULL |
| status | TEXT | SeatFSM 상태 | NOT NULL | 'vacant' |
| player_move_status | TEXT | 이동 상태 | — | NULL |
| created_at | DATETIME | 생성 시각 | NOT NULL | now() |
| updated_at | DATETIME | 수정 시각 | NOT NULL | now() |

> UNIQUE: (table_id, seat_no) — 같은 테이블에서 같은 좌석 번호 중복 불가

### 1.7 Player

선수 마스터 데이터. WSOP LIVE API 캐시 또는 수동 등록.

| 필드 | 타입 | 설명 | 제약조건 | 기본값 |
|------|------|------|----------|--------|
| player_id | INTEGER | PK | AUTO INCREMENT | — |
| wsop_id | TEXT | WSOP LIVE 고유 ID | UNIQUE | NULL |
| first_name | TEXT | 이름 | NOT NULL | — |
| last_name | TEXT | 성 | NOT NULL | — |
| nationality | TEXT | 국적 | — | NULL |
| country_code | TEXT | 국가 코드 | — | NULL |
| profile_image | TEXT | 프로필 사진 URL | — | NULL |
| player_status | TEXT | 상태 (active/inactive) | NOT NULL | 'active' |
| is_demo | BOOLEAN | 데모 플레이어 여부 | NOT NULL | false |
| source | TEXT | 데이터 소스 | NOT NULL | 'manual' |
| synced_at | DATETIME | API 동기화 시각 | — | NULL |
| created_at | DATETIME | 생성 시각 | NOT NULL | now() |
| updated_at | DATETIME | 수정 시각 | NOT NULL | now() |

---

## 2. 게임 도메인 엔티티

### 2.1 Hand

Command Center에서 기록되는 포커 1판(핸드).

| 필드 | 타입 | 설명 | 제약조건 | 기본값 |
|------|------|------|----------|--------|
| hand_id | INTEGER | PK | AUTO INCREMENT | — |
| table_id | INTEGER | FK → Table | NOT NULL | — |
| hand_number | INTEGER | 핸드 순번 | NOT NULL | — |
| game_type | INTEGER | 게임 종류 enum | NOT NULL | 0 |
| bet_structure | INTEGER | 베팅 구조 enum | NOT NULL | 0 |
| dealer_seat | INTEGER | 딜러 좌석 (0-9) | — | -1 |
| board_cards | TEXT | 보드 카드 (JSON 직렬화) | — | '[]' |
| pot_total | INTEGER | 최종 팟 총액 | — | 0 |
| side_pots | TEXT | 사이드 팟 (JSON 직렬화) | — | '[]' |
| current_street | TEXT | 종료 시 street | — | NULL |
| started_at | DATETIME | 시작 시각 | NOT NULL | — |
| ended_at | DATETIME | 종료 시각 | — | NULL |
| duration_sec | INTEGER | 소요 시간 (초) | — | 0 |
| created_at | DATETIME | 생성 시각 | NOT NULL | now() |

> UNIQUE: (table_id, hand_number) — 같은 테이블에서 같은 핸드 번호 중복 불가

### 2.2 HandPlayer

핸드별 플레이어 스냅샷.

| 필드 | 타입 | 설명 | 제약조건 | 기본값 |
|------|------|------|----------|--------|
| id | INTEGER | PK | AUTO INCREMENT | — |
| hand_id | INTEGER | FK → Hand (CASCADE) | NOT NULL | — |
| seat_no | INTEGER | 좌석 번호 (0-9) | NOT NULL | — |
| player_id | INTEGER | FK → Player | — | NULL |
| player_name | TEXT | 해당 핸드 시 이름 | NOT NULL | — |
| hole_cards | TEXT | 홀카드 (JSON 직렬화) | — | '[]' |
| start_stack | INTEGER | 시작 칩 | — | 0 |
| end_stack | INTEGER | 종료 칩 | — | 0 |
| final_action | TEXT | 최종 액션 | — | NULL |
| is_winner | BOOLEAN | 승자 여부 | NOT NULL | false |
| pnl | INTEGER | 손익 (+ / -) | — | 0 |
| hand_rank | TEXT | 핸드 랭크명 | — | NULL |
| win_probability | REAL | 승률 (0.0-1.0) | — | NULL |
| vpip | BOOLEAN | 이 핸드 VPIP 여부 | NOT NULL | false |
| pfr | BOOLEAN | 이 핸드 PFR 여부 | NOT NULL | false |
| created_at | DATETIME | 생성 시각 | NOT NULL | now() |

> UNIQUE: (hand_id, seat_no) — 같은 핸드에서 같은 좌석 중복 불가

### 2.3 HandAction

핸드 내 개별 액션.

| 필드 | 타입 | 설명 | 제약조건 | 기본값 |
|------|------|------|----------|--------|
| id | INTEGER | PK | AUTO INCREMENT | — |
| hand_id | INTEGER | FK → Hand (CASCADE) | NOT NULL | — |
| seat_no | INTEGER | 행동 좌석 (0=보드) | NOT NULL | 0 |
| action_type | TEXT | 액션 유형 (14종) | NOT NULL | — |
| action_amount | INTEGER | 베팅 금액 | — | 0 |
| pot_after | INTEGER | 액션 후 팟 | — | NULL |
| street | TEXT | 스트릿 (preflop/flop/turn/river) | NOT NULL | — |
| action_order | INTEGER | 순번 | NOT NULL | — |
| board_cards | TEXT | 보드 카드 (BOARD_CARD 시) | — | NULL |
| action_time | DATETIME | 액션 시각 | — | NULL |
| created_at | DATETIME | 생성 시각 | NOT NULL | now() |

> UNIQUE: (hand_id, action_order) — 같은 핸드에서 같은 순번 중복 불가

### 2.4 Deck

RFID 카드 덱. 52장 카드 세트.

| 필드 | 타입 | 설명 | 제약조건 | 기본값 |
|------|------|------|----------|--------|
| deck_id | INTEGER | PK | AUTO INCREMENT | — |
| table_id | INTEGER | FK → Table | — | NULL |
| label | TEXT | 덱 라벨 (예: "Deck A") | NOT NULL | — |
| status | TEXT | DeckFSM 상태 | NOT NULL | 'unregistered' |
| registered_count | INTEGER | 등록된 카드 수 (0-52) | NOT NULL | 0 |
| registered_at | DATETIME | 등록 완료 시각 | — | NULL |
| created_at | DATETIME | 생성 시각 | NOT NULL | now() |
| updated_at | DATETIME | 수정 시각 | NOT NULL | now() |

### 2.5 DeckCard

덱 내 개별 카드. RFID UID 매핑.

| 필드 | 타입 | 설명 | 제약조건 | 기본값 |
|------|------|------|----------|--------|
| id | INTEGER | PK | AUTO INCREMENT | — |
| deck_id | INTEGER | FK → Deck (CASCADE) | NOT NULL | — |
| suit | INTEGER | 수트 (0-3) | NOT NULL | — |
| rank | INTEGER | 랭크 (0-12) | NOT NULL | — |
| rfid_uid | TEXT | RFID 태그 UID (16자 hex) | — | NULL |
| display | TEXT | 표시 문자 (As, Kh 등) | NOT NULL | — |
| created_at | DATETIME | 생성 시각 | NOT NULL | now() |

> UNIQUE: (deck_id, suit, rank) — 같은 덱에 같은 카드 중복 불가

---

## 3. Admin 도메인 엔티티

### 3.1 User

EBS 사용자 (Admin, Operator, Viewer).

| 필드 | 타입 | 설명 | 제약조건 | 기본값 |
|------|------|------|----------|--------|
| user_id | INTEGER | PK | AUTO INCREMENT | — |
| email | TEXT | 이메일 | NOT NULL, UNIQUE | — |
| password_hash | TEXT | 비밀번호 해시 | NOT NULL | — |
| display_name | TEXT | 표시 이름 | NOT NULL | — |
| role | TEXT | 역할 (admin/operator/viewer) | NOT NULL | 'viewer' |
| is_active | BOOLEAN | 활성 여부 | NOT NULL | true |
| totp_secret | TEXT | 2FA TOTP 비밀키 | — | NULL |
| totp_enabled | BOOLEAN | 2FA 활성화 여부 | NOT NULL | false |
| last_login_at | DATETIME | 마지막 로그인 시각 | — | NULL |
| created_at | DATETIME | 생성 시각 | NOT NULL | now() |
| updated_at | DATETIME | 수정 시각 | NOT NULL | now() |

### 3.2 UserSession

사용자 세션 상태 보존. 재접속 시 이전 경로 복원.

| 필드 | 타입 | 설명 | 제약조건 | 기본값 |
|------|------|------|----------|--------|
| id | INTEGER | PK | AUTO INCREMENT | — |
| user_id | INTEGER | FK → User (CASCADE) | NOT NULL, UNIQUE | — |
| last_series_id | INTEGER | 마지막 Series | — | NULL |
| last_event_id | INTEGER | 마지막 Event | — | NULL |
| last_flight_id | INTEGER | 마지막 Flight | — | NULL |
| last_table_id | INTEGER | 마지막 Table | — | NULL |
| last_screen | TEXT | 마지막 화면 | — | NULL |
| access_token | TEXT | JWT 토큰 | — | NULL |
| token_expires_at | DATETIME | 토큰 만료 시각 | — | NULL |
| updated_at | DATETIME | 수정 시각 | NOT NULL | now() |

### 3.3 AuditLog

감사 로그. 모든 중요 작업 이력.

| 필드 | 타입 | 설명 | 제약조건 | 기본값 |
|------|------|------|----------|--------|
| id | INTEGER | PK | AUTO INCREMENT | — |
| user_id | INTEGER | FK → User | NOT NULL | — |
| entity_type | TEXT | 대상 엔티티 종류 | NOT NULL | — |
| entity_id | INTEGER | 대상 엔티티 ID | — | NULL |
| action | TEXT | 수행 작업 (create/update/delete/login/logout) | NOT NULL | — |
| detail | TEXT | 변경 상세 (JSON 직렬화) | — | NULL |
| ip_address | TEXT | 클라이언트 IP | — | NULL |
| created_at | DATETIME | 발생 시각 | NOT NULL | now() |

> 보존 기간: 시리즈 종료 후 1년

### 3.4 Config

BO 글로벌 설정. Key-Value 구조.

| 필드 | 타입 | 설명 | 제약조건 | 기본값 |
|------|------|------|----------|--------|
| id | INTEGER | PK | AUTO INCREMENT | — |
| key | TEXT | 설정 키 | NOT NULL, UNIQUE | — |
| value | TEXT | 설정 값 | NOT NULL | — |
| category | TEXT | 분류 (system/rfid/output/display) | NOT NULL | 'system' |
| description | TEXT | 설명 | — | NULL |
| updated_at | DATETIME | 수정 시각 | NOT NULL | now() |

### 3.5 BlindStructure / BlindStructureLevel

블라인드 구조 정의. Event에서 참조.

**BlindStructure:**

| 필드 | 타입 | 설명 | 제약조건 | 기본값 |
|------|------|------|----------|--------|
| blind_structure_id | INTEGER | PK | AUTO INCREMENT | — |
| name | TEXT | 구조명 | NOT NULL | — |
| created_at | DATETIME | 생성 시각 | NOT NULL | now() |
| updated_at | DATETIME | 수정 시각 | NOT NULL | now() |

**BlindStructureLevel:**

| 필드 | 타입 | 설명 | 제약조건 | 기본값 |
|------|------|------|----------|--------|
| id | INTEGER | PK | AUTO INCREMENT | — |
| blind_structure_id | INTEGER | FK → BlindStructure (CASCADE) | NOT NULL | — |
| level_no | INTEGER | 레벨 번호 | NOT NULL | — |
| small_blind | INTEGER | SB | NOT NULL | — |
| big_blind | INTEGER | BB | NOT NULL | — |
| ante | INTEGER | 앤티 | NOT NULL | 0 |
| duration_minutes | INTEGER | 레벨 지속 시간 (분) | NOT NULL | — |
| detail_type | INTEGER | blind_detail_type enum (0-4) | NOT NULL | 0 |
| created_at | DATETIME | 생성 시각 | NOT NULL | now() |

> UNIQUE: (blind_structure_id, level_no)

### 3.6 Skin

오버레이 그래픽 테마.

| 필드 | 타입 | 설명 | 제약조건 | 기본값 |
|------|------|------|----------|--------|
| skin_id | INTEGER | PK | AUTO INCREMENT | — |
| name | TEXT | 스킨명 | NOT NULL, UNIQUE | — |
| description | TEXT | 설명 | — | NULL |
| theme_data | TEXT | 테마 데이터 (JSON 직렬화) | NOT NULL | '{}' |
| is_default | BOOLEAN | 기본 스킨 여부 | NOT NULL | false |
| created_at | DATETIME | 생성 시각 | NOT NULL | now() |
| updated_at | DATETIME | 수정 시각 | NOT NULL | now() |

### 3.7 OutputPreset

NDI/HDMI 출력 설정 프리셋.

| 필드 | 타입 | 설명 | 제약조건 | 기본값 |
|------|------|------|----------|--------|
| preset_id | INTEGER | PK | AUTO INCREMENT | — |
| name | TEXT | 프리셋명 | NOT NULL, UNIQUE | — |
| output_type | TEXT | 출력 유형 (ndi/hdmi/sdi) | NOT NULL | 'ndi' |
| width | INTEGER | 가로 해상도 (px) | NOT NULL | 1920 |
| height | INTEGER | 세로 해상도 (px) | NOT NULL | 1080 |
| framerate | INTEGER | 프레임레이트 | NOT NULL | 60 |
| security_delay_sec | INTEGER | Security Delay (초) | NOT NULL | 0 |
| chroma_key | BOOLEAN | 크로마키 활성화 | NOT NULL | false |
| is_default | BOOLEAN | 기본 프리셋 여부 | NOT NULL | false |
| created_at | DATETIME | 생성 시각 | NOT NULL | now() |
| updated_at | DATETIME | 수정 시각 | NOT NULL | now() |
