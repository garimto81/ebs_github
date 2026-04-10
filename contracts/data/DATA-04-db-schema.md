# DATA-04 DB Schema

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | SQLAlchemy/SQLModel 스타일 스키마 초판 (Phase 1 SQLite 호환) |
| 2026-04-10 | CCR-001 | `idempotency_keys`, `audit_events` 테이블 신설 (멱등성 + 이벤트 소싱 SSOT) |

---

## 개요

EBS Back Office DB의 물리 스키마를 SQLAlchemy/SQLModel 스타일로 정의한다. Phase 1은 SQLite, Phase 3+는 PostgreSQL을 대상으로 한다.

> 참조: `contracts/data/PRD-EBS_DB_Schema.md` — GFX 데이터 추출 스키마 (L0→L1 구간). 이 문서는 3-앱 아키텍처 BO 운영 스키마이다.

### Phase 1 SQLite 호환 규칙

- JSON 필드 대신 TEXT + 직렬화 (`json.dumps` / `json.loads`)
- ARRAY 대신 TEXT (쉼표 구분 또는 JSON 직렬화)
- ENUM 대신 TEXT + CHECK 제약 또는 INTEGER
- TIMESTAMPTZ 대신 TEXT (ISO 8601 문자열)

---

## 1. 대회 계층 테이블

```python
# competitions
class Competition(SQLModel, table=True):
    __tablename__ = "competitions"

    competition_id: int = Field(primary_key=True)
    name: str = Field(nullable=False)
    competition_type: int = Field(default=0)  # enum 0-4
    competition_tag: int = Field(default=0)   # enum 0-3
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)


# series
class Series(SQLModel, table=True):
    __tablename__ = "series"

    series_id: int = Field(primary_key=True)
    competition_id: int = Field(foreign_key="competitions.competition_id")
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
    status: str = Field(default="created")
    play_level: int = Field(default=1)
    remain_time: int | None = None
    source: str = Field(default="manual")
    synced_at: str | None = None
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)
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
    status: str = Field(default="vacant")       # SeatFSM
    player_move_status: str | None = None
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)

    __table_args__ = (
        UniqueConstraint("table_id", "seat_no"),
        CheckConstraint("seat_no >= 0 AND seat_no <= 9"),
    )


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
class User(SQLModel, table=True):
    __tablename__ = "users"

    user_id: int = Field(primary_key=True)
    email: str = Field(nullable=False, unique=True)
    password_hash: str = Field(nullable=False)
    display_name: str = Field(nullable=False)
    role: str = Field(default="viewer")         # admin|operator|viewer
    is_active: bool = Field(default=True)
    totp_secret: str | None = None
    totp_enabled: bool = Field(default=False)
    last_login_at: str | None = None
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)


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


# blind_structures
class BlindStructure(SQLModel, table=True):
    __tablename__ = "blind_structures"

    blind_structure_id: int = Field(primary_key=True)
    name: str = Field(nullable=False)
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
    detail_type: int = Field(default=0)         # enum 0-4

    __table_args__ = (
        UniqueConstraint("blind_structure_id", "level_no"),
    )


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

> **append-only 강제 방법** (Phase 3+ PostgreSQL): `REVOKE UPDATE, DELETE ON audit_events FROM app_role;` + `BEFORE UPDATE OR DELETE` trigger로 차단.
> **Phase 1 SQLite**: 애플리케이션 계층의 `EventRepository` 가드 + 통합 테스트로 검증.

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
