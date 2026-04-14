-- EBS Backend Database Initialization Script
-- Version: 1.0.0
-- Created: 2026-01-30
-- Database: SQLite 3.x
-- Stage: Stage 0 (RFID Connection Validation)

-- ==============================================================================
-- 1. TABLE: cards
-- ==============================================================================

DROP TABLE IF EXISTS cards;

CREATE TABLE cards (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    uid TEXT UNIQUE,                    -- RFID UID (초기값 NULL, 매핑 후 업데이트)
    suit TEXT NOT NULL,                 -- spades, hearts, diamonds, clubs, joker
    rank TEXT NOT NULL,                 -- A, 2, 3, 4, 5, 6, 7, 8, 9, 10, J, Q, K, JOKER
    display TEXT NOT NULL,              -- "A♠", "K♥", "JOKER"
    value INTEGER NOT NULL,             -- 0-14 (Joker=0, Ace=1/14, 2-10, J=11, Q=12, K=13)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_suit CHECK (suit IN ('spades', 'hearts', 'diamonds', 'clubs', 'joker')),
    CONSTRAINT chk_value CHECK (value >= 0 AND value <= 14)
);

-- ==============================================================================
-- 2. INDEXES
-- ==============================================================================

-- RFID UID 기반 빠른 조회 (NULL 제외)
CREATE UNIQUE INDEX idx_cards_uid ON cards(uid) WHERE uid IS NOT NULL;

-- 무늬+숫자 복합 조회
CREATE INDEX idx_cards_suit_rank ON cards(suit, rank);

-- 값 기반 정렬 쿼리
CREATE INDEX idx_cards_value ON cards(value);

-- ==============================================================================
-- 3. INITIAL DATA: 54-Card Poker Deck
-- ==============================================================================

-- Spades (스페이드) - 13 cards
INSERT INTO cards (suit, rank, display, value) VALUES
('spades', 'A', 'A♠', 14),
('spades', '2', '2♠', 2),
('spades', '3', '3♠', 3),
('spades', '4', '4♠', 4),
('spades', '5', '5♠', 5),
('spades', '6', '6♠', 6),
('spades', '7', '7♠', 7),
('spades', '8', '8♠', 8),
('spades', '9', '9♠', 9),
('spades', '10', '10♠', 10),
('spades', 'J', 'J♠', 11),
('spades', 'Q', 'Q♠', 12),
('spades', 'K', 'K♠', 13);

-- Hearts (하트) - 13 cards
INSERT INTO cards (suit, rank, display, value) VALUES
('hearts', 'A', 'A♥', 14),
('hearts', '2', '2♥', 2),
('hearts', '3', '3♥', 3),
('hearts', '4', '4♥', 4),
('hearts', '5', '5♥', 5),
('hearts', '6', '6♥', 6),
('hearts', '7', '7♥', 7),
('hearts', '8', '8♥', 8),
('hearts', '9', '9♥', 9),
('hearts', '10', '10♥', 10),
('hearts', 'J', 'J♥', 11),
('hearts', 'Q', 'Q♥', 12),
('hearts', 'K', 'K♥', 13);

-- Diamonds (다이아몬드) - 13 cards
INSERT INTO cards (suit, rank, display, value) VALUES
('diamonds', 'A', 'A♦', 14),
('diamonds', '2', '2♦', 2),
('diamonds', '3', '3♦', 3),
('diamonds', '4', '4♦', 4),
('diamonds', '5', '5♦', 5),
('diamonds', '6', '6♦', 6),
('diamonds', '7', '7♦', 7),
('diamonds', '8', '8♦', 8),
('diamonds', '9', '9♦', 9),
('diamonds', '10', '10♦', 10),
('diamonds', 'J', 'J♦', 11),
('diamonds', 'Q', 'Q♦', 12),
('diamonds', 'K', 'K♦', 13);

-- Clubs (클럽) - 13 cards
INSERT INTO cards (suit, rank, display, value) VALUES
('clubs', 'A', 'A♣', 14),
('clubs', '2', '2♣', 2),
('clubs', '3', '3♣', 3),
('clubs', '4', '4♣', 4),
('clubs', '5', '5♣', 5),
('clubs', '6', '6♣', 6),
('clubs', '7', '7♣', 7),
('clubs', '8', '8♣', 8),
('clubs', '9', '9♣', 9),
('clubs', '10', '10♣', 10),
('clubs', 'J', 'J♣', 11),
('clubs', 'Q', 'Q♣', 12),
('clubs', 'K', 'K♣', 13);

-- Jokers (조커) - 2 cards
INSERT INTO cards (suit, rank, display, value) VALUES
('joker', 'JOKER', 'JOKER', 0),
('joker', 'JOKER', 'JOKER', 0);

-- ==============================================================================
-- 4. VERIFICATION QUERIES
-- ==============================================================================

-- Total card count (should be 54)
-- SELECT COUNT(*) AS total_cards FROM cards;

-- Cards per suit
-- SELECT suit, COUNT(*) AS count FROM cards GROUP BY suit ORDER BY suit;

-- Cards without UID mapping
-- SELECT COUNT(*) AS unmapped_cards FROM cards WHERE uid IS NULL;

-- Sample cards from each suit
-- SELECT id, suit, rank, display, value FROM cards WHERE suit IN ('spades', 'hearts', 'diamonds', 'clubs', 'joker') ORDER BY suit, value LIMIT 20;

-- ==============================================================================
-- 5. MAINTENANCE NOTES
-- ==============================================================================

-- Backup command (run from terminal):
-- sqlite3 server/db/cards.db ".backup server/db/cards-backup-$(date +%Y%m%d).db"

-- CSV export (for auditing):
-- sqlite3 server/db/cards.db ".mode csv" ".output cards.csv" "SELECT * FROM cards;"

-- Update UID mapping example:
-- UPDATE cards SET uid = '04:A2:B3:C4:D5:E6:F7', updated_at = CURRENT_TIMESTAMP WHERE suit = 'spades' AND rank = 'A';

-- ==============================================================================
-- 6. TABLE: idempotency_keys (CCR-003, DATA-04 §5.1)
-- ==============================================================================
-- 재시도 안전성 보장용 요청/응답 캐시. 24h TTL 후 cron 으로 정리.

DROP TABLE IF EXISTS idempotency_keys;

CREATE TABLE idempotency_keys (
    key TEXT PRIMARY KEY,                    -- 클라이언트 UUIDv4/ULID
    user_id TEXT NOT NULL,                   -- 사용자별 범위 제한
    method TEXT NOT NULL,                    -- POST/PUT/PATCH/DELETE
    path TEXT NOT NULL,                      -- 요청 경로 (query string 제외)
    request_hash TEXT NOT NULL,              -- 바디 SHA-256 hex
    status_code INTEGER NOT NULL,            -- 최초 응답 상태
    response_body TEXT,                      -- 최초 응답 바디 (JSON)
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    expires_at TEXT NOT NULL,                -- created_at + 24h

    CONSTRAINT chk_idem_method CHECK (method IN ('POST', 'PUT', 'PATCH', 'DELETE'))
);

CREATE UNIQUE INDEX idx_idem_user_key ON idempotency_keys(user_id, key);
CREATE INDEX idx_idem_expires ON idempotency_keys(expires_at);

-- ==============================================================================
-- 7. TABLE: audit_events (CCR-001, DATA-04 §5.2)
-- ==============================================================================
-- 모든 상태 변경을 append-only로 기록하는 이벤트 스토어.
-- seq 는 테이블별 단조증가이며 WebSocket envelope의 seq(CCR-015)와 1:1 매핑.
-- 복구·리플레이·Undo의 SSOT.
-- append-only: UPDATE/DELETE 는 애플리케이션 계층(EventRepository) + 통합 테스트로 강제.
--              Phase 3+ PostgreSQL 전환 시 DB 레벨 trigger 로 강화.

DROP TABLE IF EXISTS audit_events;

CREATE TABLE audit_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,    -- BIGSERIAL 매핑
    table_id TEXT NOT NULL,                  -- 테이블 식별자. 글로벌 이벤트는 '*'
    seq INTEGER NOT NULL,                    -- 테이블별 단조증가 (BIGINT 매핑)
    event_type TEXT NOT NULL,                -- seat_assigned, hand_started, rebalance_step, ...
    actor_user_id TEXT,                      -- 주체 (system 이벤트는 NULL)
    correlation_id TEXT,                     -- 분산 트레이싱 ID
    causation_id TEXT,                       -- 직전 원인 이벤트의 id (event sourcing 체인)
    idempotency_key TEXT,                    -- Idempotency-Key 헤더 동반 시 기록
    payload TEXT NOT NULL,                   -- 이벤트 본문 (JSON, JSONB 매핑)
    inverse_payload TEXT,                    -- Undo/Revive용 역방향 이벤트 본문 (JSON)
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

-- (table_id, seq) UNIQUE — seq 중복 방지
CREATE UNIQUE INDEX idx_audit_events_table_seq ON audit_events(table_id, seq DESC);

-- idempotency_key UNIQUE (NOT NULL인 경우만) — 방어적 중복 차단
CREATE UNIQUE INDEX idx_audit_events_idem ON audit_events(idempotency_key) WHERE idempotency_key IS NOT NULL;

-- correlation_id 분산 트레이싱 조회
CREATE INDEX idx_audit_events_corr ON audit_events(correlation_id);

-- event_type 종류별 조회
CREATE INDEX idx_audit_events_type_time ON audit_events(event_type, created_at);

-- ==============================================================================
-- 8. CORE ENTITIES — DATA-04 §1 대회 계층 (2026-04-13 전면 동기화)
-- ==============================================================================

DROP TABLE IF EXISTS blind_structure_levels;
DROP TABLE IF EXISTS blind_structures;
DROP TABLE IF EXISTS competitions;
DROP TABLE IF EXISTS series;
DROP TABLE IF EXISTS events;
DROP TABLE IF EXISTS event_flights;

CREATE TABLE blind_structures (
    blind_structure_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE TABLE blind_structure_levels (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    blind_structure_id INTEGER NOT NULL REFERENCES blind_structures(blind_structure_id),
    level_no INTEGER NOT NULL,
    small_blind INTEGER NOT NULL,
    big_blind INTEGER NOT NULL,
    ante INTEGER NOT NULL DEFAULT 0,
    duration_minutes INTEGER NOT NULL,
    detail_type INTEGER NOT NULL DEFAULT 0,
    UNIQUE(blind_structure_id, level_no)
);

CREATE TABLE competitions (
    competition_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    competition_type INTEGER NOT NULL DEFAULT 0,
    competition_tag INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE TABLE series (
    series_id INTEGER PRIMARY KEY AUTOINCREMENT,
    competition_id INTEGER NOT NULL REFERENCES competitions(competition_id) ON DELETE RESTRICT,
    series_name TEXT NOT NULL,
    year INTEGER NOT NULL,
    begin_at TEXT NOT NULL,
    end_at TEXT NOT NULL,
    image_url TEXT,
    time_zone TEXT NOT NULL DEFAULT 'UTC',
    currency TEXT NOT NULL DEFAULT 'USD',
    country_code TEXT,
    is_completed INTEGER NOT NULL DEFAULT 0,
    is_displayed INTEGER NOT NULL DEFAULT 1,
    is_demo INTEGER NOT NULL DEFAULT 0,
    source TEXT NOT NULL DEFAULT 'manual',
    synced_at TEXT,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE TABLE events (
    event_id INTEGER PRIMARY KEY AUTOINCREMENT,
    series_id INTEGER NOT NULL REFERENCES series(series_id) ON DELETE RESTRICT,
    event_no INTEGER NOT NULL,
    event_name TEXT NOT NULL,
    buy_in INTEGER,
    display_buy_in TEXT,
    game_type INTEGER NOT NULL DEFAULT 0,
    bet_structure INTEGER NOT NULL DEFAULT 0,
    event_game_type INTEGER NOT NULL DEFAULT 0,
    game_mode TEXT NOT NULL DEFAULT 'single',
    allowed_games TEXT,
    rotation_order TEXT,
    rotation_trigger TEXT,
    blind_structure_id INTEGER REFERENCES blind_structures(blind_structure_id),
    starting_chip INTEGER,
    table_size INTEGER NOT NULL DEFAULT 9,
    total_entries INTEGER NOT NULL DEFAULT 0,
    players_left INTEGER NOT NULL DEFAULT 0,
    start_time TEXT,
    status TEXT NOT NULL DEFAULT 'created',
    source TEXT NOT NULL DEFAULT 'manual',
    synced_at TEXT,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE TABLE event_flights (
    event_flight_id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_id INTEGER NOT NULL REFERENCES events(event_id) ON DELETE CASCADE,
    display_name TEXT NOT NULL,
    start_time TEXT,
    is_tbd INTEGER NOT NULL DEFAULT 0,
    entries INTEGER NOT NULL DEFAULT 0,
    players_left INTEGER NOT NULL DEFAULT 0,
    table_count INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'created',
    play_level INTEGER NOT NULL DEFAULT 1,
    remain_time INTEGER,
    source TEXT NOT NULL DEFAULT 'manual',
    synced_at TEXT,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE INDEX idx_series_competition ON series(competition_id);
CREATE INDEX idx_events_series ON events(series_id);
CREATE INDEX idx_events_status ON events(status);
CREATE INDEX idx_flights_event ON event_flights(event_id);

-- ==============================================================================
-- 9. CORE ENTITIES — DATA-04 §2 테이블/좌석/플레이어
-- ==============================================================================

DROP TABLE IF EXISTS tables;
DROP TABLE IF EXISTS table_seats;
DROP TABLE IF EXISTS players;

CREATE TABLE tables (
    table_id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_flight_id INTEGER NOT NULL REFERENCES event_flights(event_flight_id) ON DELETE RESTRICT,
    table_no INTEGER NOT NULL,
    name TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'general',
    status TEXT NOT NULL DEFAULT 'empty',
    max_players INTEGER NOT NULL DEFAULT 9,
    game_type INTEGER NOT NULL DEFAULT 0,
    small_blind INTEGER,
    big_blind INTEGER,
    ante_type INTEGER NOT NULL DEFAULT 0,
    ante_amount INTEGER NOT NULL DEFAULT 0,
    rfid_reader_id INTEGER,
    deck_registered INTEGER NOT NULL DEFAULT 0,
    output_type TEXT,
    current_game INTEGER,
    delay_seconds INTEGER NOT NULL DEFAULT 0,
    ring INTEGER,
    is_breaking_table INTEGER NOT NULL DEFAULT 0,
    source TEXT NOT NULL DEFAULT 'manual',
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    UNIQUE(event_flight_id, name)
);

CREATE TABLE players (
    player_id INTEGER PRIMARY KEY AUTOINCREMENT,
    wsop_id TEXT UNIQUE,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    nationality TEXT,
    country_code TEXT,
    profile_image TEXT,
    player_status TEXT NOT NULL DEFAULT 'active',
    is_demo INTEGER NOT NULL DEFAULT 0,
    source TEXT NOT NULL DEFAULT 'manual',
    synced_at TEXT,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE TABLE table_seats (
    seat_id INTEGER PRIMARY KEY AUTOINCREMENT,
    table_id INTEGER NOT NULL REFERENCES tables(table_id) ON DELETE CASCADE,
    seat_no INTEGER NOT NULL,
    player_id INTEGER REFERENCES players(player_id),
    wsop_id TEXT,
    player_name TEXT,
    nationality TEXT,
    country_code TEXT,
    chip_count INTEGER NOT NULL DEFAULT 0,
    profile_image TEXT,
    status TEXT NOT NULL DEFAULT 'empty',
    player_move_status TEXT,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    UNIQUE(table_id, seat_no),
    CHECK(seat_no >= 0 AND seat_no <= 9),
    CHECK(status IN ('empty','new','playing','moved','busted','reserved'))
);

CREATE INDEX idx_tables_flight ON tables(event_flight_id);
CREATE INDEX idx_tables_status ON tables(status);
CREATE INDEX idx_seats_table ON table_seats(table_id);
CREATE INDEX idx_seats_player ON table_seats(player_id);
CREATE INDEX idx_seats_updated ON table_seats(updated_at);

-- ==============================================================================
-- 10. CORE ENTITIES — DATA-04 §3 게임 도메인
-- ==============================================================================

DROP TABLE IF EXISTS hands;
DROP TABLE IF EXISTS hand_players;
DROP TABLE IF EXISTS hand_actions;
DROP TABLE IF EXISTS decks;
DROP TABLE IF EXISTS deck_cards;

CREATE TABLE hands (
    hand_id INTEGER PRIMARY KEY AUTOINCREMENT,
    table_id INTEGER NOT NULL REFERENCES tables(table_id) ON DELETE RESTRICT,
    hand_number INTEGER NOT NULL,
    game_type INTEGER NOT NULL DEFAULT 0,
    bet_structure INTEGER NOT NULL DEFAULT 0,
    dealer_seat INTEGER NOT NULL DEFAULT -1,
    board_cards TEXT NOT NULL DEFAULT '[]',
    pot_total INTEGER NOT NULL DEFAULT 0,
    side_pots TEXT NOT NULL DEFAULT '[]',
    current_street TEXT,
    started_at TEXT NOT NULL,
    ended_at TEXT,
    duration_sec INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    UNIQUE(table_id, hand_number)
);

CREATE TABLE hand_players (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    hand_id INTEGER NOT NULL REFERENCES hands(hand_id),
    seat_no INTEGER NOT NULL,
    player_id INTEGER REFERENCES players(player_id),
    player_name TEXT NOT NULL,
    hole_cards TEXT NOT NULL DEFAULT '[]',
    start_stack INTEGER NOT NULL DEFAULT 0,
    end_stack INTEGER NOT NULL DEFAULT 0,
    final_action TEXT,
    is_winner INTEGER NOT NULL DEFAULT 0,
    pnl INTEGER NOT NULL DEFAULT 0,
    hand_rank TEXT,
    win_probability REAL,
    vpip INTEGER NOT NULL DEFAULT 0,
    pfr INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    UNIQUE(hand_id, seat_no)
);

CREATE TABLE hand_actions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    hand_id INTEGER NOT NULL REFERENCES hands(hand_id),
    seat_no INTEGER NOT NULL DEFAULT 0,
    action_type TEXT NOT NULL,
    action_amount INTEGER NOT NULL DEFAULT 0,
    pot_after INTEGER,
    street TEXT NOT NULL,
    action_order INTEGER NOT NULL,
    board_cards TEXT,
    action_time TEXT,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    UNIQUE(hand_id, action_order)
);

CREATE TABLE decks (
    deck_id INTEGER PRIMARY KEY AUTOINCREMENT,
    table_id INTEGER REFERENCES tables(table_id),
    label TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'unregistered',
    registered_count INTEGER NOT NULL DEFAULT 0,
    registered_at TEXT,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE TABLE deck_cards (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    deck_id INTEGER NOT NULL REFERENCES decks(deck_id),
    suit INTEGER NOT NULL,
    rank INTEGER NOT NULL,
    rfid_uid TEXT,
    display TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    UNIQUE(deck_id, suit, rank)
);

CREATE INDEX idx_hands_table ON hands(table_id);
CREATE INDEX idx_hands_started ON hands(started_at);
CREATE INDEX idx_hp_hand ON hand_players(hand_id);
CREATE INDEX idx_hp_player ON hand_players(player_id);
CREATE INDEX idx_ha_hand ON hand_actions(hand_id);

-- ==============================================================================
-- 11. CORE ENTITIES — DATA-04 §4 Admin 도메인
-- ==============================================================================

DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS user_sessions;
DROP TABLE IF EXISTS audit_logs;
DROP TABLE IF EXISTS configs;
DROP TABLE IF EXISTS skins;
DROP TABLE IF EXISTS output_presets;
DROP TABLE IF EXISTS waiting_list;

CREATE TABLE users (
    user_id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    display_name TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'viewer',
    is_active INTEGER NOT NULL DEFAULT 1,
    totp_secret TEXT,
    totp_enabled INTEGER NOT NULL DEFAULT 0,
    last_login_at TEXT,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE TABLE user_sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL UNIQUE REFERENCES users(user_id),
    last_series_id INTEGER,
    last_event_id INTEGER,
    last_flight_id INTEGER,
    last_table_id INTEGER,
    last_screen TEXT,
    access_token TEXT,
    refresh_token TEXT,
    token_expires_at TEXT,
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE TABLE audit_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(user_id),
    entity_type TEXT NOT NULL,
    entity_id INTEGER,
    action TEXT NOT NULL,
    detail TEXT,
    ip_address TEXT,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE TABLE configs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    key TEXT NOT NULL UNIQUE,
    value TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'system',
    description TEXT,
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE TABLE skins (
    skin_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    theme_data TEXT NOT NULL DEFAULT '{}',
    is_default INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE TABLE output_presets (
    preset_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    output_type TEXT NOT NULL DEFAULT 'ndi',
    width INTEGER NOT NULL DEFAULT 1920,
    height INTEGER NOT NULL DEFAULT 1080,
    framerate INTEGER NOT NULL DEFAULT 60,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE TABLE waiting_list (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_flight_id INTEGER NOT NULL REFERENCES event_flights(event_flight_id),
    player_id INTEGER NOT NULL REFERENCES players(player_id),
    status TEXT NOT NULL DEFAULT 'waiting',
    position INTEGER NOT NULL,
    priority INTEGER NOT NULL DEFAULT 0,
    called_at TEXT,
    seated_at TEXT,
    canceled_at TEXT,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    CHECK(status IN ('waiting','front','calling','ready','seated','canceled','expired')),
    UNIQUE(event_flight_id, player_id)
);

CREATE INDEX idx_audit_user ON audit_logs(user_id);
CREATE INDEX idx_audit_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_time ON audit_logs(created_at);
CREATE INDEX idx_waiting_flight_pos ON waiting_list(event_flight_id, position);
CREATE INDEX idx_waiting_flight_status ON waiting_list(event_flight_id, status);
CREATE INDEX idx_waiting_player ON waiting_list(player_id);

-- ==============================================================================
-- 12. SYNC NOTE (GAP-BO-011 해소)
-- ==============================================================================
-- 본 파일은 권위 DDL = contracts/data/DATA-04-db-schema.md 와 일치해야 한다.
-- (team2-backend/CLAUDE.md L16).
--
-- 동기화 현황 (2026-04-13):
--   §1 대회 계층: competitions, series, events, event_flights ✓
--   §2 테이블/좌석: tables, table_seats (SeatStatus 6값 CHECK), players ✓
--   §3 게임 도메인: hands, hand_players, hand_actions, decks, deck_cards ✓
--   §4 Admin: users, user_sessions, audit_logs, configs, skins, output_presets ✓
--   §4+ blind_structures, blind_structure_levels ✓
--   §5.1 idempotency_keys ✓ (2026-04-10 CCR-001)
--   §5.2 audit_events ✓ (2026-04-10 CCR-001)
--   §5.3 waiting_list ✓ (2026-04-13 CCR-D)
--
-- GAP-BO-011: 전면 동기화 완료. 21개 core + 3개 infra = 24 테이블.
-- ==============================================================================

-- ==============================================================================
-- END OF INITIALIZATION SCRIPT
-- ==============================================================================
