"""WSOP LIVE Sync Service — API-02 polling + UPSERT + CB wrapping."""
from dataclasses import dataclass, field
from datetime import datetime, timezone

from sqlmodel import Session, select

from src.adapters.event_flight_status import (
    EventFlightStatusError,
    normalize as normalize_event_flight_status,
)
from src.adapters.wsop_game_type import map_to_ebs
from src.models.competition import Competition, Event, EventFlight, Series
from src.models.config import Config
from src.models.table import Player, Table, TableSeat
from src.observability.circuit_breaker import CircuitBreaker


def _utcnow() -> str:
    return datetime.now(timezone.utc).isoformat()


@dataclass
class SyncResult:
    """Result of a sync operation."""
    source: str
    created: int = 0
    updated: int = 0
    skipped: int = 0
    errors: list[str] = field(default_factory=list)


class WsopSyncService:
    """WSOP LIVE polling + UPSERT. Phase 1: mock data only."""

    def __init__(self, circuit_breaker: CircuitBreaker):
        self.cb = circuit_breaker
        self.sync_cursors: dict[str, str] = {}  # entity -> last_synced_at

    async def poll_series(self, db: Session) -> SyncResult:
        """Poll WSOP LIVE for series data. CB-wrapped."""
        async def _fetch():
            # Phase 1: no real WSOP API — return mock payload
            return self._mock_series_payload()

        data = await self.cb.call(_fetch)
        return self._upsert_series(data, db)

    def _mock_series_payload(self) -> list[dict]:
        """Generate mock WSOP LIVE API response."""
        return [
            {
                "series_name": f"WSOP {2026 + i}",
                "year": 2026 + i,
                "begin_at": f"{2026 + i}-05-27",
                "end_at": f"{2026 + i}-07-17",
                "time_zone": "America/Las_Vegas",
                "currency": "USD",
                "country_code": "US",
            }
            for i in range(3)
        ]

    def _upsert_series(self, data: list[dict], db: Session) -> SyncResult:
        """UPSERT rule: source='api' fields only, protect manual fields."""
        result = SyncResult(source="wsop_live")

        for item in data:
            existing = db.exec(
                select(Series).where(
                    Series.series_name == item["series_name"],
                    Series.year == item["year"],
                )
            ).first()

            if existing:
                # Only update api-sourced fields
                existing.begin_at = item["begin_at"]
                existing.end_at = item["end_at"]
                existing.synced_at = _utcnow()
                existing.updated_at = _utcnow()
                db.add(existing)
                result.updated += 1
            else:
                # Need a competition first
                comp = db.exec(select(Competition)).first()
                if not comp:
                    result.errors.append("No competition found for series insert")
                    continue

                series = Series(
                    competition_id=comp.competition_id,
                    series_name=item["series_name"],
                    year=item["year"],
                    begin_at=item["begin_at"],
                    end_at=item["end_at"],
                    time_zone=item.get("time_zone", "UTC"),
                    currency=item.get("currency", "USD"),
                    country_code=item.get("country_code"),
                    source="api",
                    synced_at=_utcnow(),
                )
                db.add(series)
                result.created += 1

        db.commit()
        self.sync_cursors["series"] = _utcnow()
        return result

    def upsert_events(self, data: list[dict], db: Session) -> SyncResult:
        """UPSERT events with map_to_ebs game_type conversion.

        Sync_Protocol §1.2: WSOP LIVE wsop_game_type → EBS game_type MUST
        flow through `adapters.wsop_game_type.map_to_ebs` before write.
        Previously this adapter had 0 callers; events UPSERT path was absent.
        """
        result = SyncResult(source="wsop_live_events")

        for item in data:
            # Resolve series by (name, year) composite key
            series_row = db.exec(
                select(Series).where(
                    Series.series_name == item["series_name"],
                    Series.year == item["year"],
                )
            ).first()
            if series_row is None:
                result.errors.append(
                    f"Series not found for event {item.get('event_no')}"
                )
                continue

            # MANDATORY: run through adapter before UPSERT
            try:
                ebs_game_type, ebs_game_mode = map_to_ebs(
                    item["wsop_game_type"],
                    item.get("wsop_game_mode"),
                )
            except ValueError as exc:
                result.errors.append(str(exc))
                continue

            existing = db.exec(
                select(Event).where(
                    Event.series_id == series_row.series_id,
                    Event.event_no == item["event_no"],
                )
            ).first()

            if existing:
                existing.event_name = item.get("event_name", existing.event_name)
                existing.game_type = ebs_game_type
                existing.game_mode = ebs_game_mode
                existing.synced_at = _utcnow()
                existing.updated_at = _utcnow()
                db.add(existing)
                result.updated += 1
            else:
                ev = Event(
                    series_id=series_row.series_id,
                    event_no=item["event_no"],
                    event_name=item.get("event_name", "Untitled"),
                    game_type=ebs_game_type,
                    game_mode=ebs_game_mode,
                    bet_structure=0,
                    table_size=item.get("table_size", 9),
                    source="api",
                    synced_at=_utcnow(),
                )
                db.add(ev)
                result.created += 1

        db.commit()
        self.sync_cursors["events"] = _utcnow()
        return result

    async def poll_events(self, db: Session, payload_fn=None) -> SyncResult:
        """CB-wrapped WSOP LIVE events poll. `payload_fn` injectable for tests."""
        async def _fetch():
            return payload_fn() if payload_fn else []
        data = await self.cb.call(_fetch)
        return self.upsert_events(data, db)

    def upsert_event_flights(self, data: list[dict], db: Session) -> SyncResult:
        """UPSERT event_flights with status INT→TEXT adapter (CCR-047).

        `status` in payload may be WSOP LIVE integer (0,1,2,4,5,6). The column
        is TEXT, so we convert via the adapter. Rejects unknown values instead
        of silent cast.
        """
        result = SyncResult(source="wsop_live_event_flights")

        for item in data:
            event_row = db.exec(
                select(Event).where(Event.event_id == item["event_id"])
            ).first()
            if event_row is None:
                result.errors.append(
                    f"Event {item['event_id']} not found for flight"
                )
                continue

            raw_status = item.get("status", 0)
            try:
                status_text = normalize_event_flight_status(raw_status)
            except EventFlightStatusError as exc:
                result.errors.append(str(exc))
                continue

            existing = db.exec(
                select(EventFlight).where(
                    EventFlight.event_id == item["event_id"],
                    EventFlight.display_name == item["display_name"],
                )
            ).first()
            if existing:
                existing.status = status_text
                existing.synced_at = _utcnow()
                existing.updated_at = _utcnow()
                db.add(existing)
                result.updated += 1
            else:
                ef = EventFlight(
                    event_id=item["event_id"],
                    display_name=item["display_name"],
                    status=status_text,
                    source="api",
                    synced_at=_utcnow(),
                )
                db.add(ef)
                result.created += 1

        db.commit()
        self.sync_cursors["event_flights"] = _utcnow()
        return result

    async def get_sync_status(self) -> dict:
        """Return sync status for each entity type."""
        return {
            "sources": {
                "wsop_live": {
                    "status": "connected",
                    "last_synced": self.sync_cursors.get("series"),
                    "cursors": dict(self.sync_cursors),
                }
            }
        }

    async def seed_mock_data(self, db: Session) -> dict:
        """Seed demo data aligned with seed/README.md."""
        from sqlalchemy import text

        now = _utcnow()

        # ── Ensure raw-SQL tables exist (not managed by SQLModel) ──
        db.execute(text(
            "CREATE TABLE IF NOT EXISTS blind_structures ("
            "  blind_structure_id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  name TEXT NOT NULL,"
            "  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),"
            "  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))"
            ")"
        ))
        db.execute(text(
            "CREATE TABLE IF NOT EXISTS blind_structure_levels ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  blind_structure_id INTEGER NOT NULL REFERENCES blind_structures(blind_structure_id),"
            "  level_no INTEGER NOT NULL,"
            "  small_blind INTEGER NOT NULL,"
            "  big_blind INTEGER NOT NULL,"
            "  ante INTEGER NOT NULL DEFAULT 0,"
            "  duration_minutes INTEGER NOT NULL,"
            "  detail_type INTEGER NOT NULL DEFAULT 0"
            "    CHECK (detail_type IN (0,1,2,3,4)),"
            "  UNIQUE(blind_structure_id, level_no)"
            ")"
        ))
        db.execute(text(
            "CREATE TABLE IF NOT EXISTS decks ("
            "  deck_id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  table_id INTEGER REFERENCES tables(table_id),"
            "  label TEXT NOT NULL,"
            "  status TEXT NOT NULL DEFAULT 'unregistered',"
            "  registered_count INTEGER NOT NULL DEFAULT 0,"
            "  registered_at TEXT,"
            "  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),"
            "  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))"
            ")"
        ))
        db.execute(text(
            "CREATE TABLE IF NOT EXISTS deck_cards ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  deck_id INTEGER NOT NULL REFERENCES decks(deck_id),"
            "  suit INTEGER NOT NULL,"
            "  rank INTEGER NOT NULL,"
            "  rfid_uid TEXT,"
            "  display TEXT NOT NULL,"
            "  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),"
            "  UNIQUE(deck_id, suit, rank)"
            ")"
        ))
        db.execute(text(
            "CREATE TABLE IF NOT EXISTS skins ("
            "  skin_id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  name TEXT NOT NULL UNIQUE,"
            "  description TEXT,"
            "  theme_data TEXT NOT NULL DEFAULT '{}',"
            "  is_default INTEGER NOT NULL DEFAULT 0,"
            "  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),"
            "  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))"
            ")"
        ))
        db.execute(text(
            "CREATE TABLE IF NOT EXISTS output_presets ("
            "  preset_id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  name TEXT NOT NULL UNIQUE,"
            "  output_type TEXT NOT NULL DEFAULT 'ndi',"
            "  width INTEGER NOT NULL DEFAULT 1920,"
            "  height INTEGER NOT NULL DEFAULT 1080,"
            "  framerate INTEGER NOT NULL DEFAULT 60,"
            "  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),"
            "  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))"
            ")"
        ))

        # ── Competitions (2) ──
        comp1 = Competition(name="WSOP", competition_type=0, competition_tag=1)
        comp2 = Competition(name="WSOPC", competition_type=1, competition_tag=2)
        db.add(comp1)
        db.add(comp2)
        db.flush()

        # ── Series (2) ──
        s1 = Series(
            competition_id=comp1.competition_id,
            series_name="2026 WSOP", year=2026,
            begin_at="2026-05-27", end_at="2026-07-16",
            source="api", synced_at=now,
        )
        s2 = Series(
            competition_id=comp2.competition_id,
            series_name="2026 WSOPC Seoul", year=2026,
            begin_at="2026-03-15", end_at="2026-03-25",
            source="api", synced_at=now,
        )
        db.add(s1)
        db.add(s2)
        db.flush()

        # ── Events (3) ──
        ev1 = Event(
            series_id=s1.series_id, event_no=1,
            event_name="$10,000 NL Hold'em Main Event",
            game_type=0, bet_structure=0, table_size=9,
            starting_chip=60000, game_mode="single",
            source="api", synced_at=now,
        )
        ev2 = Event(
            series_id=s1.series_id, event_no=2,
            event_name="$1,500 HORSE",
            game_type=0, bet_structure=0, table_size=8,
            starting_chip=25000, game_mode="fixed_rotation",
            source="api", synced_at=now,
        )
        ev3 = Event(
            series_id=s1.series_id, event_no=3,
            event_name="$10,000 Dealer's Choice",
            game_type=0, bet_structure=0, table_size=6,
            starting_chip=50000, game_mode="dealers_choice",
            source="api", synced_at=now,
        )
        db.add(ev1)
        db.add(ev2)
        db.add(ev3)
        db.flush()

        # ── Flights (4) ──
        fl1 = EventFlight(
            event_id=ev1.event_id, display_name="Day 1A",
            status="running", source="api", synced_at=now,
        )
        fl2 = EventFlight(
            event_id=ev1.event_id, display_name="Day 1B",
            status="created", source="api", synced_at=now,
        )
        fl3 = EventFlight(
            event_id=ev1.event_id, display_name="Day 2",
            status="created", source="api", synced_at=now,
        )
        fl4 = EventFlight(
            event_id=ev2.event_id, display_name="Day 1",
            status="running", source="api", synced_at=now,
        )
        db.add(fl1)
        db.add(fl2)
        db.add(fl3)
        db.add(fl4)
        db.flush()

        # ── Players (9) ──
        players_data = [
            ("Daniel", "Negreanu", "Canadian", "CA"),
            ("Phil", "Ivey", "American", "US"),
            ("Fedor", "Holz", "German", "DE"),
            ("Justin", "Bonomo", "American", "US"),
            ("Bryn", "Kenney", "American", "US"),
            ("Erik", "Seidel", "American", "US"),
            ("John", "Doe", "American", "US"),
            ("Jane", "Smith", "British", "GB"),
            ("Test", "Player", "Korean", "KR"),
        ]
        player_objs = []
        for i, (fn, ln, nat, cc) in enumerate(players_data, start=1):
            p = Player(
                first_name=fn, last_name=ln,
                nationality=nat, country_code=cc,
                source="api", synced_at=now,
            )
            db.add(p)
            player_objs.append(p)
        db.flush()

        # ── Tables (3) ──
        t1 = Table(
            event_flight_id=fl1.event_flight_id, table_no=1,
            name="Feature Table 1", type="feature",
            status="live", max_players=9, source="api",
        )
        t2 = Table(
            event_flight_id=fl1.event_flight_id, table_no=2,
            name="Table 2", type="general",
            status="setup", max_players=9, source="api",
        )
        t3 = Table(
            event_flight_id=fl4.event_flight_id, table_no=1,
            name="HORSE Feature", type="feature",
            status="live", max_players=8, source="api",
        )
        db.add(t1)
        db.add(t2)
        db.add(t3)
        db.flush()

        # ── Seats ──
        seat_count = 0

        # Table 1: seats 0-5 occupied, 6-8 empty
        t1_occupied = [
            (0, 0, "D. Negreanu", 85000),
            (1, 1, "P. Ivey", 120000),
            (2, 2, "F. Holz", 45000),
            (3, 3, "J. Bonomo", 92000),
            (4, 4, "B. Kenney", 78000),
            (5, 5, "E. Seidel", 55000),
        ]
        for seat_no, pi, pname, chips in t1_occupied:
            db.add(TableSeat(
                table_id=t1.table_id, seat_no=seat_no,
                player_id=player_objs[pi].player_id,
                player_name=pname, chip_count=chips, status="new",
            ))
            seat_count += 1
        for seat_no in (6, 7, 8):
            db.add(TableSeat(
                table_id=t1.table_id, seat_no=seat_no, status="empty",
            ))
            seat_count += 1

        # Table 2: seats 0-2 occupied (players 7-9), 3-8 empty
        t2_occupied = [
            (0, 6, "J. Doe", 60000),
            (1, 7, "J. Smith", 60000),
            (2, 8, "T. Player", 60000),
        ]
        for seat_no, pi, pname, chips in t2_occupied:
            db.add(TableSeat(
                table_id=t2.table_id, seat_no=seat_no,
                player_id=player_objs[pi].player_id,
                player_name=pname, chip_count=chips, status="new",
            ))
            seat_count += 1
        for seat_no in range(3, 9):
            db.add(TableSeat(
                table_id=t2.table_id, seat_no=seat_no, status="empty",
            ))
            seat_count += 1

        # Table 3: seats 0-5 occupied (players 1-6 again), 6-7 empty (max 8)
        t3_occupied = [
            (0, 0, "D. Negreanu", 25000),
            (1, 1, "P. Ivey", 25000),
            (2, 2, "F. Holz", 25000),
            (3, 3, "J. Bonomo", 25000),
            (4, 4, "B. Kenney", 25000),
            (5, 5, "E. Seidel", 25000),
        ]
        for seat_no, pi, pname, chips in t3_occupied:
            db.add(TableSeat(
                table_id=t3.table_id, seat_no=seat_no,
                player_id=player_objs[pi].player_id,
                player_name=pname, chip_count=chips, status="new",
            ))
            seat_count += 1
        for seat_no in (6, 7):
            db.add(TableSeat(
                table_id=t3.table_id, seat_no=seat_no, status="empty",
            ))
            seat_count += 1

        db.flush()

        # ── BlindStructure + Levels (raw SQL) ──
        db.execute(text(
            "INSERT OR REPLACE INTO blind_structures "
            "(blind_structure_id, name, created_at, updated_at) "
            "VALUES (1, '$10K Main Event Structure', "
            "strftime('%Y-%m-%dT%H:%M:%fZ', 'now'), "
            "strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))"
        ))
        levels = [
            (1, 100, 200, 200, 120, 0),
            (2, 200, 300, 300, 120, 0),
            (3, 200, 400, 400, 120, 0),
            (4, 300, 600, 600, 120, 0),
            (5, 0, 0, 0, 15, 1),
            (6, 400, 800, 800, 120, 0),
            (7, 500, 1000, 1000, 120, 0),
            (8, 600, 1200, 1200, 120, 0),
            (9, 800, 1600, 1600, 120, 0),
            (10, 0, 0, 0, 60, 2),
            (11, 1000, 2000, 2000, 120, 0),
            (12, 1200, 2500, 2500, 120, 0),
            (13, 1500, 3000, 3000, 120, 0),
            (14, 2000, 4000, 4000, 120, 0),
        ]
        for lno, sb, bb, ante, dur, dt in levels:
            db.execute(text(
                "INSERT OR REPLACE INTO blind_structure_levels "
                "(blind_structure_id, level_no, small_blind, big_blind, ante, "
                "duration_minutes, detail_type) "
                "VALUES (:bs_id, :lno, :sb, :bb, :ante, :dur, :dt)"
            ), {"bs_id": 1, "lno": lno, "sb": sb, "bb": bb,
                "ante": ante, "dur": dur, "dt": dt})

        # ── Decks + DeckCards (raw SQL) ──
        db.execute(text(
            "INSERT OR REPLACE INTO decks (deck_id, table_id, label, status, registered_count) "
            "VALUES (1, :tid, 'Deck A (Mock)', 'mock', 52), "
            "       (2, :tid, 'Deck B (Mock)', 'mock', 52)"
        ), {"tid": t1.table_id})

        rank_names = ["2", "3", "4", "5", "6", "7", "8", "9", "10",
                      "J", "Q", "K", "A"]
        suit_initials = ["C", "D", "H", "S"]
        suit_symbols = ["c", "d", "h", "s"]
        for deck_id in (1, 2):
            for suit in range(4):
                for rank in range(13):
                    uid = f"MOCK_{suit_initials[suit]}_{rank:02d}"
                    display = f"{rank_names[rank]}{suit_symbols[suit]}"
                    db.execute(text(
                        "INSERT OR REPLACE INTO deck_cards "
                        "(deck_id, suit, rank, rfid_uid, display) "
                        "VALUES (:did, :suit, :rank, :uid, :display)"
                    ), {"did": deck_id, "suit": suit, "rank": rank,
                        "uid": uid, "display": display})

        # ── Config (10 global entries) ──
        configs = [
            ("rfid_mode", "mock", "rfid", "RFID 모드 (mock / real)"),
            ("rfid_scan_interval_ms", "100", "rfid", "RFID 스캔 간격 (ms)"),
            ("log_level", "info", "system", "로그 레벨 (debug/info/warn/error)"),
            ("session_timeout_min", "480", "system", "세션 타임아웃 (분, 기본 8시간)"),
            ("default_table_size", "9", "system", "기본 테이블 크기"),
            ("default_game_type", "0", "system", "기본 게임 종류 (Hold'em)"),
            ("overlay_resolution", "1920x1080", "output", "기본 오버레이 해상도"),
            ("security_delay_default", "0", "output", "기본 Security Delay (초)"),
            ("auto_save_interval_sec", "30", "system", "자동 저장 간격 (초)"),
            ("backup_retention_days", "365", "system", "백업 보존 기간 (일)"),
        ]
        for key, value, category, description in configs:
            db.add(Config(
                key=key, value=value, scope="global",
                category=category, description=description,
            ))

        # ── Skins (3, raw SQL) ──
        db.execute(text(
            "INSERT OR REPLACE INTO skins "
            "(skin_id, name, is_default, description, "
            "theme_data, created_at, updated_at) VALUES "
            "(1, 'WSOP Classic', 1, 'WSOP 2026 기본 스킨', "
            "'{}', strftime('%Y-%m-%dT%H:%M:%fZ','now'), "
            "strftime('%Y-%m-%dT%H:%M:%fZ','now')), "
            "(2, 'WSOP Dark', 0, 'WSOP 다크 테마', "
            "'{}', strftime('%Y-%m-%dT%H:%M:%fZ','now'), "
            "strftime('%Y-%m-%dT%H:%M:%fZ','now')), "
            "(3, 'Minimal', 0, '최소 UI 테스트용', "
            "'{}', strftime('%Y-%m-%dT%H:%M:%fZ','now'), "
            "strftime('%Y-%m-%dT%H:%M:%fZ','now'))"
        ))

        # ── OutputPresets (4, raw SQL) ──
        db.execute(text(
            "INSERT OR REPLACE INTO output_presets (preset_id, name, output_type, "
            "width, height, framerate) VALUES "
            "(1, '1080p NDI', 'ndi', 1920, 1080, 60), "
            "(2, '4K NDI', 'ndi', 3840, 2160, 60), "
            "(3, '1080p HDMI + Delay', 'hdmi', 1920, 1080, 60), "
            "(4, '1080p Chroma', 'ndi', 1920, 1080, 60)"
        ))

        db.commit()

        return {
            "competitions": 2,
            "series": 2,
            "events": 3,
            "flights": 4,
            "players": 9,
            "tables": 3,
            "seats": seat_count,
            "blind_structures": 1,
            "blind_structure_levels": 14,
            "decks": 2,
            "deck_cards": 104,
            "configs": 10,
            "skins": 3,
            "output_presets": 4,
        }

    async def reset_mock_data(self, db: Session) -> dict:
        """Delete all seeded data."""
        from sqlalchemy import text
        counts = {}

        # Raw SQL tables (no source column) — delete all
        for tbl in [
            "deck_cards", "decks", "table_seats", "tables",
            "blind_structure_levels", "blind_structures",
            "configs", "skins", "output_presets",
        ]:
            result = db.execute(text(f"DELETE FROM {tbl}"))
            counts[tbl] = result.rowcount

        # SQLModel tables with source column — filter by source='api'
        for tbl in ["event_flights", "events", "series", "players"]:
            result = db.execute(text(f"DELETE FROM {tbl} WHERE source='api'"))
            counts[tbl] = result.rowcount

        # Competitions (no source column)
        result = db.execute(text("DELETE FROM competitions"))
        counts["competitions"] = result.rowcount

        db.commit()
        return {"deleted": counts}
