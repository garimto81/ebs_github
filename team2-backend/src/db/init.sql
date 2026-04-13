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
-- 8. GAP-BO-011 SYNC NOTE
-- ==============================================================================
-- 본 파일은 권위 DDL = contracts/data/DATA-04-db-schema.md 와 일치해야 한다
-- (team2-backend/CLAUDE.md L16). 현재 상태:
--   - §5.1 idempotency_keys: 2026-04-10 CCR-001 반영 완료 ✓
--   - §5.2 audit_events:     2026-04-10 CCR-001 반영 완료 ✓
--   - §1~§4 core 엔티티 (competitions, series, events, flights, tables,
--     table_seats, hands, hand_players, hand_actions, users, audit_logs):
--     아직 미동기화. Stage 1 진입 전에 전면 동기화 필요. GAP-BO-011 참조.
-- ==============================================================================

-- ==============================================================================
-- END OF INITIALIZATION SCRIPT
-- ==============================================================================
