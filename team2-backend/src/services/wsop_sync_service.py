"""WSOP LIVE Sync Service — API-02 polling + UPSERT + CB wrapping."""
import json
import random
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Optional

from sqlmodel import Session, select

from src.models.competition import Competition, Series, Event, EventFlight
from src.models.table import Player
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
        """Seed demo data: 1 Competition, 3 Series, 10 Events/series, 2 Flights/event, 100 Players."""
        now = _utcnow()

        # Competition
        comp = Competition(name="WSOP 2026", competition_type=0, competition_tag=0)
        db.add(comp)
        db.flush()

        series_count = 0
        event_count = 0
        flight_count = 0

        for si in range(3):
            series = Series(
                competition_id=comp.competition_id,
                series_name=f"WSOP Series {si + 1}",
                year=2026,
                begin_at=f"2026-0{5 + si}-01",
                end_at=f"2026-0{5 + si}-30",
                source="api",
                synced_at=now,
            )
            db.add(series)
            db.flush()
            series_count += 1

            for ei in range(10):
                event = Event(
                    series_id=series.series_id,
                    event_no=ei + 1,
                    event_name=f"Event #{si * 10 + ei + 1} NL Holdem",
                    buy_in=(ei + 1) * 1000,
                    game_type=0,
                    bet_structure=0,
                    source="api",
                    synced_at=now,
                )
                db.add(event)
                db.flush()
                event_count += 1

                for fi in range(2):
                    flight = EventFlight(
                        event_id=event.event_id,
                        display_name=f"Day 1{'A' if fi == 0 else 'B'}",
                        source="api",
                        synced_at=now,
                    )
                    db.add(flight)
                    flight_count += 1

        # Players
        first_names = ["Phil", "Daniel", "Doyle", "Phil", "Johnny", "Chris",
                       "Erik", "Bryn", "Jason", "Justin"]
        last_names = ["Hellmuth", "Negreanu", "Brunson", "Ivey", "Chan",
                      "Moneymaker", "Seidel", "Kenney", "Koon", "Bonomo"]

        player_count = 0
        for pi in range(100):
            fn = first_names[pi % len(first_names)]
            ln = last_names[pi % len(last_names)]
            player = Player(
                wsop_id=f"WSOP-{pi + 1:04d}",
                first_name=fn,
                last_name=f"{ln}_{pi + 1}",
                nationality="US",
                country_code="US",
                source="api",
                synced_at=now,
            )
            db.add(player)
            player_count += 1

        db.commit()

        return {
            "competitions": 1,
            "series": series_count,
            "events": event_count,
            "flights": flight_count,
            "players": player_count,
        }

    async def reset_mock_data(self, db: Session) -> dict:
        """Delete all api-sourced data."""
        # Delete in reverse FK order
        from sqlalchemy import text
        counts = {}
        for tbl in ["event_flights", "events", "series", "competitions", "players"]:
            if tbl == "players":
                result = db.execute(text(f"DELETE FROM {tbl} WHERE source='api'"))
            elif tbl == "competitions":
                result = db.execute(text(f"DELETE FROM {tbl}"))
            else:
                result = db.execute(text(f"DELETE FROM {tbl} WHERE source='api'"))
            counts[tbl] = result.rowcount
        db.commit()
        return {"deleted": counts}
