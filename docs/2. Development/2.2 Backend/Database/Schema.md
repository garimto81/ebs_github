---
title: Schema
owner: team2
tier: internal
legacy-id: DATA-04
last-updated: 2026-04-15
---

# DATA-04 DB Schema

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | SQLAlchemy/SQLModel 스타일 스키마 초판 (Phase 1 SQLite 호환) |
| 2026-04-10 | CCR-001 | `idempotency_keys`, `audit_events` 테이블 신설 (멱등성 + 이벤트 소싱 SSOT) |
| 2026-04-13 | CCR promote 반영 | event_type 카탈로그 35값 공식 정의 (§5.2 부속), SeatStatus enum 6값 (§table_seats), waiting_list 테이블 신설 (§5.3) |
| 2026-04-14 | Confluence 출처 명시 | WSOP LIVE 준거 구간의 원본 Confluence 페이지 링크 추가 |
| 2026-04-14 | CCR-047 | `series` 테이블에 `competition_type`/`competition_tag` 컬럼 + CHECK 제약 추가, `event_flights.status` 를 `int` enum (0,1,2,4,5,6) 로 전환. `competitions` 테이블은 Phase 1 호환용으로 유지 (deprecated 주석). SSOT: Confluence Page 1960411325 (Enum) / 1599537917 (Tournament) |
| 2026-04-14 | CCR-053 | `users` 테이블에 `is_suspended`/`is_locked`/`failed_login_count`/`last_failed_at` 컬럼 추가 + 상태 인덱스. WSOP LIVE Staff 패턴 (SSOT Page 1597768061) |
| 2026-04-15 | G1 재분류 | §table_seats SeatStatus 의 "WSOP LIVE E/N/P/M/B/R 준거" 주장을 **관측 기반 justified divergence** 로 재분류. WSOP LIVE 공개 문서에 `EventFlightSeat.Status` enum 값 정의 불발견. 6값 CHECK 자체는 유지 (DB 영속 SSOT) |
| 2026-04-15 | G2 추가 | §events.game_type 뒤에 "WSOP LIVE 정렬 (game_type)" 서브섹션 신설. 22종(EBS) ↔ 9종(WSOP LIVE) divergence justified + adapter 계약 명시 |
| 2026-04-15 | G7 추가 | §players 뒤에 "WSOP LIVE 대비 미채택 필드" 서브섹션 신설. email/birth/join_type 제외 근거 명문화 (§1.2 매트릭스 KYC/Registration 제거와 일관) |
| 2026-04-15 | G3 확장 | `blind_structure_levels.detail_type` enum 을 3값(0=Blind/1=Break/2=DinnerBreak) → **5값(+ 3=HalfBlind, 4=HalfBreak)** 으로 확장. CHECK 제약 명시. WSOP LIVE `BlindDetailType` (Confluence 1960411325) 와 1:1 정렬. DDL/migration 은 team2-backend/src/db/init.sql 및 Alembic revision 로 후속 반영 |

---

## 참조 Confluence 원본 (WSOP LIVE)

DATA-04 는 **EBS 고유 BO 운영 스키마** 이며, 일부 개념은 WSOP LIVE Confluence 원본을 준거한다. 아래 표는 "WSOP LIVE 준거" 라고 인라인 명시된 구간과 그 출처를 매핑한다.

| DATA-04 섹션 | 차용 개념 | Confluence 페이지 | Page ID | URL |
|-------------|-----------|------------------|---------|-----|
| §table_seats SeatStatus enum | EBS 내부 6값 (justified divergence) | Action History *(근거 불발견)* | `1679556614` | https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/1679556614 |
| §5.2 event_type 카탈로그 | EventFlightActionType 35값 | Action History | `1679556614` | https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/1679556614 |
| §5.3 waiting_list 테이블 | WaitingPlayerInfo / FlightRoomsInfo 구조 | Waiting API | `2418737362` | https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/2418737362 |
| (참고) ERD 전체 컨텍스트 | Fatima ERD | WSOP+ Database 설명(2023.04.17) | `1652949021` | https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/1652949021 |

로컬 미러 경로: `C:/claude/wsoplive/docs/confluence-mirror/WSOP Live 홈/2. Development/`

---

## 개요

EBS Back Office DB의 물리 스키마를 SQLAlchemy/SQLModel 스타일로 정의한다. Phase 1은 SQLite, Phase 3+는 PostgreSQL을 대상으로 한다.

> 본 문서는 3-앱 아키텍처 BO 운영 스키마의 단일 SSOT다. GFX 추출 스키마(L0→L1)는 별도 PRD가 없으며, Engine 내부 모델은 `team3-engine/specs/engine-spec/` 참조.

### Phase 1 SQLite 호환 규칙

- JSON 필드 대신 TEXT + 직렬화 (`json.dumps` / `json.loads`)
- ARRAY 대신 TEXT (쉼표 구분 또는 JSON 직렬화)
- ENUM 대신 TEXT + CHECK 제약 또는 INTEGER
- TIMESTAMPTZ 대신 TEXT (ISO 8601 문자열)

---

## 1. 대회 계층 테이블

```python
# competitions
# [DEPRECATED Phase 2, CCR-047] WSOP LIVE 는 Competition 을 별도 테이블로 두지 않고 Series 의
# competition_type / competition_tag enum 컬럼으로 관리 (SSOT: Confluence Page 1599537917).
# Phase 1 데이터 호환을 위해 본 테이블은 유지하되 신규 로직은 series.* 사용. Phase 2 sprint 1 drop.
class Competition(SQLModel, table=True):
    __tablename__ = "competitions"

    competition_id: int = Field(primary_key=True)
    name: str = Field(nullable=False)
    competition_type: int = Field(default=0)  # enum 0-4
    competition_tag: int = Field(default=0)   # enum 0-3
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)


# series
# CCR-047: competition_type / competition_tag enum 컬럼 추가 (WSOP LIVE 정본 계층).
#   SSOT: Confluence Page 1960411325 (CompetitionType/CompetitionTag enum).
class Series(SQLModel, table=True):
    __tablename__ = "series"

    series_id: int = Field(primary_key=True)
    # Phase 1 호환: Phase 2 에서 drop. 신규 로직은 competition_type/tag 사용.
    competition_id: int = Field(foreign_key="competitions.competition_id")
    competition_type: int = Field(default=0)  # WSOP LIVE CompetitionType: WSOP(0)/WSOPC(1)/APL(2)/APT(3)/WSOPP(4)
    competition_tag: int = Field(default=0)   # WSOP LIVE CompetitionTag: None(0)/Bracelets(1)/Circuit(2)/SuperCircuit(3)
    series_name: str = Field(nullable=False)
    year: int = Field(nullable=False)
    begin_at: str = Field(nullable=False)       # DATE ISO
    end_at: str = Field(nullable=False)         # DATE ISO
    image_url: str | None = None
    time_zone: str = Field(default="UTC")
    currency: str = Field(default="USD")
    country_code: str | None = None
    is_completed: bool = Field(default=False)
    is_displayed: bool = Field(default=True)
    is_demo: bool = Field(default=False)
    source: str = Field(default="manual")       # 'manual' | 'api'
    synced_at: str | None = None
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)

    # CCR-047: competition_type ∈ [0..4], competition_tag ∈ [0..3] + 복합 인덱스
    __table_args__ = (
        CheckConstraint("competition_type BETWEEN 0 AND 4", name="ck_series_competition_type"),
        CheckConstraint("competition_tag BETWEEN 0 AND 3", name="ck_series_competition_tag"),
        Index("idx_series_competition", "competition_type", "competition_tag"),
    )


# events
class Event(SQLModel, table=True):
    __tablename__ = "events"

    event_id: int = Field(primary_key=True)
    series_id: int = Field(foreign_key="series.series_id")
    event_no: int = Field(nullable=False)
    event_name: str = Field(nullable=False)
    buy_in: int | None = None
    display_buy_in: str | None = None
    game_type: int = Field(default=0)           # enum 0-21
    bet_structure: int = Field(default=0)       # enum 0-2
    event_game_type: int = Field(default=0)     # enum 0-8
    game_mode: str = Field(default="single")    # single|fixed_rotation|dealers_choice
    allowed_games: str | None = None            # TEXT (JSON serialized)
    rotation_order: str | None = None           # TEXT (JSON serialized)
    rotation_trigger: str | None = None         # TEXT (JSON serialized)
    blind_structure_id: int | None = Field(
        default=None,
        foreign_key="blind_structures.blind_structure_id"
    )
    starting_chip: int | None = None
    table_size: int = Field(default=9)
    total_entries: int = Field(default=0)
    players_left: int = Field(default=0)
    start_time: str | None = None               # DATETIME ISO
    status: str = Field(default="created")      # EventFSM
    source: str = Field(default="manual")
    synced_at: str | None = None
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)


# event_flights
class EventFlight(SQLModel, table=True):
    __tablename__ = "event_flights"

    event_flight_id: int = Field(primary_key=True)
    event_id: int = Field(foreign_key="events.event_id")
    display_name: str = Field(nullable=False)
    start_time: str | None = None
    is_tbd: bool = Field(default=False)
    entries: int = Field(default=0)
    players_left: int = Field(default=0)
    table_count: int = Field(default=0)
    # EventFlightStatus enum (BS-00 §3.6, WSOP LIVE Confluence Page 1960411325 준거). 값 3 은 reserved.
    status: int = Field(default=0)
    play_level: int = Field(default=1)
    remain_time: int | None = None
    source: str = Field(default="manual")
    synced_at: str | None = None
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)

    # CCR-047: EventFlightStatus 6값 CHECK + 인덱스
    __table_args__ = (
        CheckConstraint("status IN (0, 1, 2, 4, 5, 6)", name="ck_event_flights_status"),
        Index("idx_event_flights_status", "status"),
    )
```

---

## 2. 테이블/좌석/플레이어

```python
# tables
class Table(SQLModel, table=True):
    __tablename__ = "tables"

    table_id: int = Field(primary_key=True)
    event_flight_id: int = Field(
        foreign_key="event_flights.event_flight_id"
    )
    table_no: int = Field(nullable=False)
    name: str = Field(nullable=False)
    type: str = Field(default="general")        # 'feature' | 'general'
    status: str = Field(default="empty")        # TableFSM
    max_players: int = Field(default=9)
    game_type: int = Field(default=0)
    small_blind: int | None = None
    big_blind: int | None = None
    ante_type: int = Field(default=0)
    ante_amount: int = Field(default=0)
    rfid_reader_id: int | None = None
    deck_registered: bool = Field(default=False)
    output_type: str | None = None
    current_game: int | None = None
    delay_seconds: int = Field(default=0)
    ring: int | None = None
    is_breaking_table: bool = Field(default=False)
    source: str = Field(default="manual")
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)

    __table_args__ = (
        UniqueConstraint("event_flight_id", "name"),
    )


# table_seats
class TableSeat(SQLModel, table=True):
    __tablename__ = "table_seats"

    seat_id: int = Field(primary_key=True)
    table_id: int = Field(foreign_key="tables.table_id")
    seat_no: int = Field(nullable=False)        # 0-9
    player_id: int | None = Field(
        default=None, foreign_key="players.player_id"
    )
    wsop_id: str | None = None
    player_name: str | None = None
    nationality: str | None = None
    country_code: str | None = None
    chip_count: int = Field(default=0)
    profile_image: str | None = None
    status: str = Field(default="empty")        # SeatStatus enum (아래 참조)
    player_move_status: str | None = None
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)

    __table_args__ = (
        UniqueConstraint("table_id", "seat_no"),
        CheckConstraint("seat_no >= 0 AND seat_no <= 9"),
    )
```

#### SeatStatus enum (2026-04-15, EBS 내부 justified divergence)

EBS DB 영속 SSOT 는 아래 **6값 CHECK 제약**이다. 위 "WSOP LIVE 준거" 표기는 관측 기반이며 원문 enum 근거 불발견(자세히는 `State_Machines.md §3`). 외부 sync 대상 아님.

| 값 | 설명 | EBS 내부 shorthand |
|------|------|----------|
| `empty` | 빈 좌석 | E |
| `new` | 새로 배치됨 (sit-in 대기, WAITING 포함) | N (+ W) |
| `playing` | 핸드 참여 중 | (PLAYING) |
| `moved` | 이동됨 (재배치 대기) | M |
| `busted` | 탈락 요청됨 (확인 대기) | B |
| `reserved` | 예약/선점 (OCCUPIED/HOLD 포함) | R (+ O + H) |

Phase 1 SQLite: `CHECK(status IN ('empty','new','playing','moved','busted','reserved'))`.
Phase 3+ PostgreSQL: `CREATE TYPE seat_status AS ENUM(...)`.

> FSM 의 9코드(E/N/M/B/O/R/W/H/PLAYING)는 상태 전이 표현용이며, DB 저장 시 위 6값으로 매핑된다. 매핑 규칙: `State_Machines.md §3` 표 참조.

```python
# players
class Player(SQLModel, table=True):
    __tablename__ = "players"

    player_id: int = Field(primary_key=True)
    wsop_id: str | None = Field(default=None, unique=True)
    first_name: str = Field(nullable=False)
    last_name: str = Field(nullable=False)
    nationality: str | None = None
    country_code: str | None = None
    profile_image: str | None = None
    player_status: str = Field(default="active")
    is_demo: bool = Field(default=False)
    source: str = Field(default="manual")
    synced_at: str | None = None
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)
```

#### game_type enum (2026-04-15, WSOP LIVE 정렬 — Justified Divergence)

**Divergence 유형**: Justified (RFID/rule engine 요구로 EBS 세분화)

EBS `events.game_type` 는 22종(0–21), WSOP LIVE `EventGameType` 은 9종(0–8). **값 의미가 완전히 상이**하므로 sync 경계에서 adapter 를 통한 변환이 필수다. 원시 값을 그대로 저장하면 silent corruption 발생 (예: WSOP `3=Razz` 를 EBS 에 그대로 저장하면 EBS `3=Pineapple` 로 해석됨).

| WSOP LIVE (9종 운영 분류) | EBS (22종 rule 세분화) |
|---|---|
| `0 Holdem` | `0 NLHE` / `1 LHE` / `2 Short Deck` |
| `1 Omaha` | `4 PLO` / `5 Omaha Hi-Lo` / `6~11 PLO 변형` |
| `2 Stud` | `19 7-Card Stud` / `20 Stud Hi-Lo` |
| `3 Razz` | `21 Razz` |
| `4 Lowball` | `12 NL 2-7 Single Draw` / `13 2-7 Triple` / `14 A-5 Triple` |
| `5 HORSE` | `events.game_mode='fixed_rotation'` + `allowed_games` JSON 조합 |
| `6 DealerChoice` | `events.game_mode='dealers_choice'` + `allowed_games` JSON |
| `7 Mixed` | `events.game_mode='fixed_rotation'` + 커스텀 `rotation_order` |
| `8 Badugi` | `15 Badugi` / `16 Badacey` / `17 Badeucey` |

**Adapter 계약** (`team2-backend/src/adapters/wsop_game_type.py`, 구현 대상):
- `map_to_ebs(wsop_game_type: int, event_game_mode: str | None) -> int`: WSOP → EBS 기본값 매핑 (1:N 은 기본값 선택 — NLHE=0 / PLO=4 / 7-Card Stud=19 / Razz=21 / Badugi=15)
- `map_to_wsop(ebs_game_type: int) -> int`: EBS → WSOP 역인덱스 (N:1 손실 없음)
- HORSE/Mixed/DealerChoice 는 `game_type` 단일 정수로 표현 불가 → `game_type + game_mode + allowed_games` 3필드 조합이 SSOT

**sync 경계 원칙**: `wsop_sync_service` 가 WSOP LIVE API 응답을 `events` 테이블에 UPSERT 하기 전 `map_to_ebs()` 를 반드시 호출. Mock 데이터에도 동일 적용해 회귀 방지 (enum parity 테스트: `team2-backend/tests/test_wsop_enum_parity.py`).

**Why justified**: EBS 는 RFID 기반 rule engine 이 게임 변형(카드 수·핸드 평가·hi-lo 분할·short-deck A-5 low 등)을 정확히 구분해야 하므로 22종 세분화가 불가피. WSOP LIVE 는 운영 분류 단위로 충분한 9종을 사용. 둘은 "같은 개념의 다른 수준" 이며 adapter 로만 정합.

> 구현 참조: `team2-backend/seed/README.md §2 게임 변형 레코드 (22종)` / WSOP LIVE Confluence Page `1960411325` Enum §EventGameType

#### Player 미채택 필드 (2026-04-15, WSOP LIVE 대비)

WSOP LIVE `Player` 엔티티에는 있으나 EBS 가 **의도적으로 채택하지 않은** 필드와 그 근거.

| WSOP LIVE 필드 | EBS 채택 | 사유 |
|---|:---:|---|
| `WsopId` | ✅ 부분 (`wsop_id`) | 외부 ID 식별용. int → `str` 로 완화 (prefix 변동 대응) |
| `Email` | ❌ | 오버레이 / Lobby 렌더 체인 어디에도 표시 안 함. Back_Office/Overview.md §1.2 매트릭스 #11 (Cashier) / #15 (Wallet) 제거와 일관 |
| `Birth` | ❌ | 연령/생일 표시 미요구. §1.2 매트릭스 #16 (KYC) 제거와 일관 — EBS 는 규정 검증 주체가 아님 |
| `Nationality` | ✅ (`nationality`) | 오버레이 국가명 텍스트 |
| `ImageUrl` → `profile_image` | ✅ | 오버레이 프로필 사진 (Foundation.md §4.2 플레이어 표시 필수) |
| `JoinType` | ❌ | §1.2 매트릭스 #10 (Registration) 제거 — 등록 경로/채널 추적 불필요. Online sit-in 등의 구분은 EBS 오버레이 책임 외 |
| `country_code` (EBS 추가) | — | ISO 2자리 코드. 국기 이미지 매핑용 (WSOP LIVE `Nationality` 텍스트만으로는 국기 렌더 불가) |

**Why**: EBS Core = 실시간 오버레이 렌더. Foundation.md §4.2 의 오버레이 요소 중 플레이어 표시에 쓰이는 필드는 **이름·국기·사진·칩 스택** 4개뿐. `Email`/`Birth`/`JoinType` 은 렌더 체인에 진입하지 않으며, Back_Office/Overview.md §1.2 채택/제거 매트릭스에서 "금융/KYC/Registration = EBS 범위 외" 로 이미 선언되었다. 필드 미채택은 누락이 아니라 **설계 의도**다.

> 구현: `src/models/player.py` (SQLModel 5필드) / WSOP LIVE Confluence Page `1652949021` (Fatima ERD)

---

## 3. 게임 도메인 테이블

```python
# hands
class Hand(SQLModel, table=True):
    __tablename__ = "hands"

    hand_id: int = Field(primary_key=True)
    table_id: int = Field(foreign_key="tables.table_id")
    hand_number: int = Field(nullable=False)
    game_type: int = Field(default=0)
    bet_structure: int = Field(default=0)
    dealer_seat: int = Field(default=-1)
    board_cards: str = Field(default="[]")      # TEXT (JSON)
    pot_total: int = Field(default=0)
    side_pots: str = Field(default="[]")        # TEXT (JSON)
    current_street: str | None = None
    started_at: str = Field(nullable=False)
    ended_at: str | None = None
    duration_sec: int = Field(default=0)
    created_at: str = Field(default_factory=utcnow)

    __table_args__ = (
        UniqueConstraint("table_id", "hand_number"),
    )


# hand_players
class HandPlayer(SQLModel, table=True):
    __tablename__ = "hand_players"

    id: int = Field(primary_key=True)
    hand_id: int = Field(foreign_key="hands.hand_id")
    seat_no: int = Field(nullable=False)
    player_id: int | None = Field(
        default=None, foreign_key="players.player_id"
    )
    player_name: str = Field(nullable=False)
    hole_cards: str = Field(default="[]")       # TEXT (JSON)
    start_stack: int = Field(default=0)
    end_stack: int = Field(default=0)
    final_action: str | None = None
    is_winner: bool = Field(default=False)
    pnl: int = Field(default=0)
    hand_rank: str | None = None
    win_probability: float | None = None
    vpip: bool = Field(default=False)
    pfr: bool = Field(default=False)
    created_at: str = Field(default_factory=utcnow)

    __table_args__ = (
        UniqueConstraint("hand_id", "seat_no"),
    )


# hand_actions
class HandAction(SQLModel, table=True):
    __tablename__ = "hand_actions"

    id: int = Field(primary_key=True)
    hand_id: int = Field(foreign_key="hands.hand_id")
    seat_no: int = Field(default=0)
    action_type: str = Field(nullable=False)    # 14종
    action_amount: int = Field(default=0)
    pot_after: int | None = None
    street: str = Field(nullable=False)
    action_order: int = Field(nullable=False)
    board_cards: str | None = None
    action_time: str | None = None
    created_at: str = Field(default_factory=utcnow)

    __table_args__ = (
        UniqueConstraint("hand_id", "action_order"),
    )


# decks
class Deck(SQLModel, table=True):
    __tablename__ = "decks"

    deck_id: int = Field(primary_key=True)
    table_id: int | None = Field(
        default=None, foreign_key="tables.table_id"
    )
    label: str = Field(nullable=False)
    status: str = Field(default="unregistered") # DeckFSM
    registered_count: int = Field(default=0)
    registered_at: str | None = None
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)


# deck_cards
class DeckCard(SQLModel, table=True):
    __tablename__ = "deck_cards"

    id: int = Field(primary_key=True)
    deck_id: int = Field(foreign_key="decks.deck_id")
    suit: int = Field(nullable=False)           # 0-3
    rank: int = Field(nullable=False)           # 0-12
    rfid_uid: str | None = None                 # 16-char hex
    display: str = Field(nullable=False)        # "As", "Kh"
    created_at: str = Field(default_factory=utcnow)

    __table_args__ = (
        UniqueConstraint("deck_id", "suit", "rank"),
    )
```

---

## 4. Admin 도메인 테이블

```python
# users
# CCR-053: is_suspended / is_locked (WSOP LIVE Staff 패턴, SSOT Page 1597768061).
# CCR-048/052: failed_login_count / last_failed_at (10회 실패 자동 잠금).
class User(SQLModel, table=True):
    __tablename__ = "users"

    user_id: int = Field(primary_key=True)
    email: str = Field(nullable=False, unique=True)
    password_hash: str = Field(nullable=False)
    display_name: str = Field(nullable=False)
    role: str = Field(default="viewer")         # admin|operator|viewer
    is_active: bool = Field(default=True)       # soft delete flag
    is_suspended: bool = Field(default=False)   # Admin 결정 일시 정지
    is_locked: bool = Field(default=False)      # 보안 위반 자동/수동 잠금
    failed_login_count: int = Field(default=0)  # 연속 실패 카운터
    last_failed_at: str | None = None
    totp_secret: str | None = None
    totp_enabled: bool = Field(default=False)
    last_login_at: str | None = None
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)

    # CCR-053: 상태 복합 인덱스 (is_active/is_suspended/is_locked)
    __table_args__ = (
        Index("idx_users_status", "is_active", "is_suspended", "is_locked"),
    )


# user_sessions
class UserSession(SQLModel, table=True):
    __tablename__ = "user_sessions"

    id: int = Field(primary_key=True)
    user_id: int = Field(
        foreign_key="users.user_id", unique=True
    )
    last_series_id: int | None = None
    last_event_id: int | None = None
    last_flight_id: int | None = None
    last_table_id: int | None = None
    last_screen: str | None = None
    access_token: str | None = None
    token_expires_at: str | None = None
    updated_at: str = Field(default_factory=utcnow)


# audit_logs
class AuditLog(SQLModel, table=True):
    __tablename__ = "audit_logs"

    id: int = Field(primary_key=True)
    user_id: int = Field(foreign_key="users.user_id")
    entity_type: str = Field(nullable=False)
    entity_id: int | None = None
    action: str = Field(nullable=False)
    detail: str | None = None                   # TEXT (JSON)
    ip_address: str | None = None
    created_at: str = Field(default_factory=utcnow)


# configs
class Config(SQLModel, table=True):
    __tablename__ = "configs"

    id: int = Field(primary_key=True)
    key: str = Field(nullable=False, unique=True)
    value: str = Field(nullable=False)
    category: str = Field(default="system")
    description: str | None = None
    updated_at: str = Field(default_factory=utcnow)


# blind_structures (CCR-049: Series 템플릿 + EventFlight 적용 분리, WSOP LIVE Page 1603666061 준거)
class BlindStructure(SQLModel, table=True):
    __tablename__ = "blind_structures"

    blind_structure_id: int = Field(primary_key=True)
    series_id: int = Field(foreign_key="series.series_id")              # CCR-049: 템플릿 소유 Series
    name: str = Field(nullable=False)
    blind_type: str = Field(default="no_limit_holdem")                  # CCR-049: no_limit_holdem / pot_limit_omaha / mixed 등
    is_template: bool = Field(default=True)                             # CCR-049: true=템플릿, false=Flight 적용본
    creator_user_id: int | None = Field(default=None, foreign_key="users.user_id")  # CCR-049: 수정 권한 제한
    is_auto_renaming: bool = Field(default=False)                       # CCR-049: 중복 이름 자동 번호 접미사
    details: str = Field(default="[]")                                  # CCR-049: BlindStructureDetail[] (jsonb 직렬화)
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)


# payout_structures (CCR-051: Series 템플릿 + EventFlight 적용. WSOP LIVE Page 1603600679 준거)
class PayoutStructure(SQLModel, table=True):
    __tablename__ = "payout_structures"

    payout_structure_id: int = Field(primary_key=True)
    series_id: int = Field(foreign_key="series.series_id")
    name: str = Field(nullable=False)
    is_template: bool = Field(default=True)                             # true=템플릿, false=Flight 적용본
    creator_user_id: int | None = Field(default=None, foreign_key="users.user_id")
    entries: str = Field(default="[]")                                  # PayoutEntry[] (entry_from/entry_to/ranks[]) JSON 직렬화. 비즈니스 규칙: 각 구간 ranks[].award_percent 합계 = 100.0 (API 검증)
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)


# blind_structure_levels
class BlindStructureLevel(SQLModel, table=True):
    __tablename__ = "blind_structure_levels"

    id: int = Field(primary_key=True)
    blind_structure_id: int = Field(
        foreign_key="blind_structures.blind_structure_id"
    )
    level_no: int = Field(nullable=False)
    small_blind: int = Field(nullable=False)
    big_blind: int = Field(nullable=False)
    ante: int = Field(default=0)
    duration_minutes: int = Field(nullable=False)
    detail_type: int = Field(default=0)         # BlindDetailType 5값 (WSOP LIVE Confluence 1960411325 §BlindDetailType)

    __table_args__ = (
        UniqueConstraint("blind_structure_id", "level_no"),
        CheckConstraint("detail_type IN (0, 1, 2, 3, 4)", name="ck_blind_detail_type"),
    )
```

#### BlindDetailType enum (2026-04-15, WSOP LIVE 1:1 정렬)

| 값 | 이름 | 설명 |
|:--:|------|------|
| `0` | Blind | 정규 블라인드 레벨 (small/big/ante 모두 적용) |
| `1` | Break | 정규 휴식 (클럭 중단, 통상 15~20분) |
| `2` | DinnerBreak | 식사 휴식 (통상 60~75분, 별도 카운트다운 UI) |
| `3` | HalfBlind | 레벨 중간 시점에 블라인드만 인상 (ante 는 직전 값 유지). 예: Big Blind Ante 방식에서 ante 만 고정하고 blind 중간 인상 시 |
| `4` | HalfBreak | 15분 미만 짧은 휴식 (클럭 중단 없음 또는 초단시간). 예: 색상 교환/정리 시간 |

**sync 경계**: WSOP LIVE `BlindStructureDetail.BlindJson` 에 `HalfBlind(3)` 또는 `HalfBreak(4)` 이 포함된 구조를 pull 할 때, 기존 3값 CHECK 제약(0/1/2)에서는 UPSERT 가 실패했다. 이번 확장으로 정합.

**Why**: WSOP LIVE Enum.md (Confluence `1960411325`) 에 공식 정의된 5값 중 3·4를 EBS 에서 미채택했던 것은 명시적 근거 없는 누락이었음 (2026-04-15 critic G3 에서 식별). 정렬 원칙(CLAUDE.md 원칙 1) 상 추가 전용 채택이 기본값.

> 후속 작업: `team2-backend/src/db/init.sql` L? `blind_structure_levels` CHECK 제약 확장 + Alembic revision `add_half_blind_break_to_detail_type` — Task #5.

```python
# skins
class Skin(SQLModel, table=True):
    __tablename__ = "skins"

    skin_id: int = Field(primary_key=True)
    name: str = Field(nullable=False, unique=True)
    description: str | None = None
    theme_data: str = Field(default="{}")       # TEXT (JSON)
    is_default: bool = Field(default=False)
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)


# output_presets
class OutputPreset(SQLModel, table=True):
    __tablename__ = "output_presets"

    preset_id: int = Field(primary_key=True)
    name: str = Field(nullable=False, unique=True)
    output_type: str = Field(default="ndi")
    width: int = Field(default=1920)
    height: int = Field(default=1080)
    framerate: int = Field(default=60)
    security_delay_sec: int = Field(default=0)
    chroma_key: bool = Field(default=False)
    is_default: bool = Field(default=False)
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)
```

---

## 5. 멱등성·이벤트 소싱 테이블 (CCR-001)

> **근거**: CCR-001 — WSOP+ `EventFlightSeatHistory`/Audit 테이블 설계 및 CCR-003(Idempotency-Key)/CCR-015(WebSocket seq) 요구사항을 수용한다.
> **관련 CCR**: CCR-001, CCR-003, CCR-010, CCR-015

### 5.1 `idempotency_keys`

재시도 안전성 보장용 요청/응답 캐시. 24h TTL 후 정리.

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| `key` | VARCHAR(128) | PK | 클라이언트가 생성한 UUIDv4/ULID |
| `user_id` | VARCHAR(64) | NOT NULL | 멱등성 범위를 사용자당으로 좁혀 키 충돌 방지 |
| `method` | VARCHAR(16) | NOT NULL | POST/PUT/PATCH/DELETE |
| `path` | VARCHAR(255) | NOT NULL | 요청 경로 (query string 제외) |
| `request_hash` | CHAR(64) | NOT NULL | 바디 SHA-256 |
| `status_code` | SMALLINT | NOT NULL | 최초 응답 상태 |
| `response_body` | TEXT | NULL | 최초 응답 바디 (JSON) |
| `created_at` | TIMESTAMP | NOT NULL DEFAULT now() | 인입 시각 |
| `expires_at` | TIMESTAMP | NOT NULL | `created_at + 24h` |

**인덱스**:
- `(user_id, key)` UNIQUE
- `expires_at` B-tree (청소용)

**정리 정책**:
- `DELETE FROM idempotency_keys WHERE expires_at < now()` — cron 5분 간격

**Phase 1 SQLite 매핑**: `VARCHAR`/`CHAR` → `TEXT`, `TIMESTAMP` → `TEXT` (ISO 8601), `SMALLINT` → `INTEGER`.

```python
# idempotency_keys
class IdempotencyKey(SQLModel, table=True):
    __tablename__ = "idempotency_keys"

    key: str = Field(primary_key=True, max_length=128)
    user_id: str = Field(nullable=False, max_length=64)
    method: str = Field(nullable=False, max_length=16)
    path: str = Field(nullable=False, max_length=255)
    request_hash: str = Field(nullable=False, max_length=64)   # SHA-256 hex
    status_code: int = Field(nullable=False)
    response_body: str | None = None                           # TEXT (JSON)
    created_at: str = Field(default_factory=utcnow)
    expires_at: str = Field(nullable=False)                    # created_at + 24h

    __table_args__ = (
        UniqueConstraint("user_id", "key"),
    )
```

---

### 5.2 `audit_events`

모든 상태 변경을 append-only로 기록하는 이벤트 스토어. `seq`는 테이블별 단조증가이며 WebSocket envelope의 `seq`(CCR-015)와 1:1 매핑된다. 복구·리플레이·Undo의 SSOT.

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| `id` | BIGSERIAL | PK | 전역 순번 (audit용) |
| `table_id` | VARCHAR(64) | NOT NULL | 테이블 식별자. 테이블 없는 이벤트(global)는 `'*'` |
| `seq` | BIGINT | NOT NULL | 테이블별 단조증가. `(table_id, seq)` UNIQUE |
| `event_type` | VARCHAR(64) | NOT NULL | `seat_assigned`, `hand_started`, `rebalance_step` 등 |
| `actor_user_id` | VARCHAR(64) | NULL | 주체 (system 이벤트는 NULL) |
| `correlation_id` | VARCHAR(64) | NULL | 분산 트레이싱 ID (same across service hops) |
| `causation_id` | VARCHAR(64) | NULL | 직전 원인 이벤트의 id (event sourcing 체인) |
| `idempotency_key` | VARCHAR(128) | NULL | 요청이 `Idempotency-Key` 동반 시 기록 |
| `payload` | JSONB | NOT NULL | 이벤트 본문 (스키마는 `event_type`별) |
| `inverse_payload` | JSONB | NULL | Undo/Revive용 역방향 이벤트 본문 |
| `created_at` | TIMESTAMP | NOT NULL DEFAULT now() | append 시각 |

**제약**:
- `UNIQUE (table_id, seq)` — seq 중복 방지
- `UNIQUE (idempotency_key) WHERE idempotency_key IS NOT NULL` — 방어적 중복 차단
- **append-only**: UPDATE/DELETE는 DB 레벨에서 차단 (trigger 또는 역할 권한). Undo는 새 inverse 이벤트를 append.

**인덱스**:
- `(table_id, seq DESC)` — replay 쿼리 최적화 (`GET /tables/{id}/events?since=...`)
- `(correlation_id)` — 분산 트레이싱
- `(event_type, created_at)` — 이벤트 종류별 조회

**보존**: 1년 (감사 규정). 이후 cold storage로 아카이브.

**Phase 1 SQLite 매핑**: `JSONB` → `TEXT`(JSON 직렬화), `BIGSERIAL` → `INTEGER PRIMARY KEY AUTOINCREMENT`, `BIGINT` → `INTEGER`, `VARCHAR` → `TEXT`.

```python
# audit_events
class AuditEvent(SQLModel, table=True):
    __tablename__ = "audit_events"

    id: int = Field(primary_key=True)                          # BIGSERIAL
    table_id: str = Field(nullable=False, max_length=64)       # '*' = global
    seq: int = Field(nullable=False)                           # BIGINT, per-table monotonic
    event_type: str = Field(nullable=False, max_length=64)
    actor_user_id: str | None = None
    correlation_id: str | None = None
    causation_id: str | None = None
    idempotency_key: str | None = None
    payload: str = Field(nullable=False)                       # TEXT (JSON)
    inverse_payload: str | None = None                         # TEXT (JSON), Undo/Revive
    created_at: str = Field(default_factory=utcnow)

    __table_args__ = (
        UniqueConstraint("table_id", "seq"),
    )
```

#### event_type 카탈로그 (2026-04-13, WSOP LIVE EventFlightActionType 준거)

| 카테고리 | event_type | 설명 | WSOP 대응 |
|---------|-----------|------|----------|
| **Hand** | `hand_started` | 핸드 시작 | — |
| | `hand_ended` | 핸드 종료 | — |
| | `action_performed` | 플레이어 액션 (fold/call/raise) | — |
| | `card_detected` | RFID 카드 감지 | — |
| | `betting_round_complete` | 베팅 라운드 완료 | — |
| | `all_folded` | 전원 폴드 | — |
| | `all_in_runout` | 올인 런아웃 | — |
| **Seat** | `seat_assigned` | 좌석 배정 | SeatAssigned(21) |
| | `seat_vacated` | 좌석 비움 | — |
| | `seat_moved` | 좌석 이동 | MovePlayer(22) |
| | `seat_reserved` | 좌석 예약 | ReserveSeats(41) |
| | `seat_released` | 좌석 예약 해제 | ReleaseSeats(42) |
| | `player_eliminated_request` | 탈락 요청 | RequestEliminate(111) |
| | `player_eliminated_confirm` | 탈락 확정 | Eliminate(113) |
| | `chips_updated` | 칩 카운트 갱신 | UpdateChips(121) |
| **Table** | `table_created` | 테이블 생성 | AddTables(3) |
| | `table_setup` | 테이블 설정 완료 | — |
| | `table_live` | 테이블 라이브 전환 | — |
| | `table_paused` | 테이블 일시정지 | PauseTables(44) |
| | `table_resumed` | 테이블 재개 | ResumeTables(45) |
| | `table_closed` | 테이블 종료 | BreakTable(33) |
| **Device** | `rfid_status_changed` | RFID 리더 상태 변경 | — |
| | `output_status_changed` | 출력(NDI/HDMI) 상태 변경 | — |
| | `game_changed` | 게임 타입 변경 | — |
| | `config_changed` | 글로벌 설정 변경 | — |
| | `blind_structure_changed` | 블라인드 구조 변경 | ChangeBlinds(401) |
| **Ops** | `operator_connected` | CC 운영자 연결 | — |
| | `operator_disconnected` | CC 운영자 해제 | — |
| | `deck_registered` | 덱 등록 완료 | — |
| | `player_updated` | 플레이어 정보 갱신 | — |
| | `table_assigned` | CC에 테이블 할당 | — |
| **Special** | `bomb_pot_set` | Bomb Pot 설정 | — |
| | `run_it_times_set` | Run It Times 설정 | — |
| | `chop_confirmed` | Chop 합의 | — |
| **Overlay** | `skin_updated` | 스킨/오버레이 변경 | — |

> 카탈로그는 **확장 가능** (add only). 기존 값 삭제/이름변경 금지. WSOP 대응 열은 참조용이며 EBS 구현에 구속력 없음.

> **append-only 강제 방법** (Phase 3+ PostgreSQL): `REVOKE UPDATE, DELETE ON audit_events FROM app_role;` + `BEFORE UPDATE OR DELETE` trigger로 차단.
> **Phase 1 SQLite**: 애플리케이션 계층의 `EventRepository` 가드 + 통합 테스트로 검증.

---

### 5.3 `waiting_list` (2026-04-13, WSOP LIVE Waiting API 준거)

대기열 관리. 플레이어가 Sit-In 요청 후 좌석 배정까지의 상태를 추적한다.

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| `id` | INTEGER | PK AUTOINCREMENT | 대기열 항목 ID |
| `event_flight_id` | INTEGER | NOT NULL, FK→event_flights | Flight |
| `player_id` | INTEGER | NOT NULL, FK→players | 플레이어 |
| `status` | VARCHAR(16) | NOT NULL DEFAULT 'waiting' | PlayerWaitingStatus |
| `position` | INTEGER | NOT NULL | 대기 순번 (1부터) |
| `priority` | BOOLEAN | NOT NULL DEFAULT false | 우선 배치 여부 |
| `called_at` | TIMESTAMP | NULL | 호출 시각 |
| `seated_at` | TIMESTAMP | NULL | 좌석 배정 시각 |
| `canceled_at` | TIMESTAMP | NULL | 취소/만료 시각 |
| `created_at` | TIMESTAMP | NOT NULL DEFAULT now() | 등록 시각 |

**제약**:
- `CHECK(status IN ('waiting','front','calling','ready','seated','canceled','expired'))`
- `UNIQUE(event_flight_id, player_id)` — 같은 Flight에 중복 대기 방지

**인덱스**:
- `(event_flight_id, position)` — 대기 순서 조회
- `(event_flight_id, status)` — 상태별 필터
- `(player_id)` — 플레이어별 대기 이력

**Phase 1 SQLite 매핑**: 타입 동일 (VARCHAR→TEXT, TIMESTAMP→TEXT, BOOLEAN→INTEGER).

```python
class WaitingListEntry(SQLModel, table=True):
    __tablename__ = "waiting_list"
    
    id: int = Field(primary_key=True)
    event_flight_id: int = Field(nullable=False, foreign_key="event_flights.id")
    player_id: int = Field(nullable=False, foreign_key="players.id")
    status: str = Field(default="waiting", max_length=16)
    position: int = Field(nullable=False)
    priority: bool = Field(default=False)
    called_at: str | None = None
    seated_at: str | None = None
    canceled_at: str | None = None
    created_at: str = Field(default_factory=utcnow)
    
    __table_args__ = (
        CheckConstraint("status IN ('waiting','front','calling','ready','seated','canceled','expired')", name="ck_waiting_status"),
        UniqueConstraint("event_flight_id", "player_id"),
    )
```

---

## 6. 인덱스

| 테이블 | 인덱스 | 컬럼 | 용도 |
|--------|--------|------|------|
| series | idx_series_competition | competition_id | 대회별 시리즈 조회 |
| events | idx_events_series | series_id | 시리즈별 이벤트 조회 |
| events | idx_events_status | status | 상태별 필터링 |
| event_flights | idx_flights_event | event_id | 이벤트별 Flight 조회 |
| tables | idx_tables_flight | event_flight_id | Flight별 테이블 조회 |
| tables | idx_tables_status | status | 상태별 필터링 |
| table_seats | idx_seats_table | table_id | 테이블별 좌석 조회 |
| table_seats | idx_seats_player | player_id | 플레이어별 좌석 조회 |
| hands | idx_hands_table | table_id | 테이블별 핸드 조회 |
| hands | idx_hands_started | started_at | 시간순 조회 |
| hand_players | idx_hp_hand | hand_id | 핸드별 플레이어 |
| hand_players | idx_hp_player | player_id | 플레이어별 핸드 이력 |
| hand_actions | idx_ha_hand | hand_id | 핸드별 액션 조회 |
| audit_logs | idx_audit_user | user_id | 사용자별 감사 로그 |
| audit_logs | idx_audit_entity | entity_type, entity_id | 엔티티별 이력 |
| audit_logs | idx_audit_time | created_at | 시간순 조회 |
| idempotency_keys | idx_idem_user_key | user_id, key (UNIQUE) | 사용자별 멱등키 조회 |
| idempotency_keys | idx_idem_expires | expires_at | 만료 정리 |
| audit_events | idx_audit_events_table_seq | table_id, seq DESC (UNIQUE) | replay 쿼리 |
| audit_events | idx_audit_events_corr | correlation_id | 분산 트레이싱 |
| audit_events | idx_audit_events_type_time | event_type, created_at | 이벤트 종류별 조회 |
| waiting_list | idx_wl_flight_position | event_flight_id, position | 대기 순서 조회 |
| waiting_list | idx_wl_flight_status | event_flight_id, status | 상태별 필터 |
| waiting_list | idx_wl_player | player_id | 플레이어별 대기 이력 |

---

## 7. CASCADE 규칙

| 부모 | 자식 | ON DELETE |
|------|------|----------|
| Competition | Series | RESTRICT |
| Series | Event | RESTRICT |
| Event | EventFlight | CASCADE |
| EventFlight | Table | RESTRICT |
| Table | TableSeat | CASCADE |
| Table | Hand | RESTRICT |
| Table | Deck | SET NULL |
| Hand | HandPlayer | CASCADE |
| Hand | HandAction | CASCADE |
| Deck | DeckCard | CASCADE |
| Player | TableSeat | SET NULL |
| Player | HandPlayer | SET NULL |
| User | UserSession | CASCADE |
| User | AuditLog | RESTRICT |
| BlindStructure | BlindStructureLevel | CASCADE |
| EventFlight | WaitingListEntry | RESTRICT |
| Player | WaitingListEntry | SET NULL |
