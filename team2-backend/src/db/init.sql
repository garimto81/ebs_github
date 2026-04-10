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
-- END OF INITIALIZATION SCRIPT
-- ==============================================================================
