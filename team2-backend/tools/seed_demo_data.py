#!/usr/bin/env python3
"""Seed rich demo data for E2E + Lobby UX showcase.

기획서 정렬:
  - docs/2. Development/2.1 Frontend/Lobby/References/EBS_Lobby_Design.html (R8 신설, 2026-05-03)
    의 SERIES 8개 / EVENTS 다양 status / 다층 drill-down 패턴 반영.
  - status enum: running | announced | registering | completed | created.

기존 seed_admin.py 보완 — admin 만 생성하던 baseline 에 demo competition tree 추가.

사용:
  python tools/seed_demo_data.py                         # 기본 시드
  python tools/seed_demo_data.py --reset                 # 기존 demo 삭제 후 재시드
  docker exec ebs-bo python tools/seed_demo_data.py      # 컨테이너 내부

idempotent: Competition.name='E2E_Demo' 키로 검증, 중복 생성 차단.

관련:
  - SG-008-b11 v1.3 (Lobby → CC E2E)
  - Workflow_Conductor_Autonomous SOP
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

TEAM2_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TEAM2_ROOT))

from sqlmodel import Session, create_engine, delete, select  # noqa: E402
from src.app.config import settings  # noqa: E402
from src.models.competition import Competition, Event, EventFlight, Series  # noqa: E402
from src.models.table import Player, Table, TableSeat  # noqa: E402

# ── Demo data (Lobby Reference Design 정렬) ─────────────────────────────────

DEMO_TAG = "E2E_Demo"

SERIES_SEED = [
    # 2026 active
    {"id_hint": "wps26", "year": 2026, "name": "World Poker Series 2026",
     "country": "US", "currency": "USD",
     "begin": "2026-05-27", "end": "2026-07-16", "completed": False},
    {"id_hint": "wpse26", "year": 2026, "name": "World Poker Series Europe 2026",
     "country": "FR", "currency": "EUR",
     "begin": "2026-09-15", "end": "2026-10-05", "completed": False},
    {"id_hint": "circ-syd", "year": 2026, "name": "Circuit — Sydney",
     "country": "AU", "currency": "AUD",
     "begin": "2026-04-01", "end": "2026-04-12", "completed": False},
    {"id_hint": "circ-bra", "year": 2026, "name": "Circuit — São Paulo",
     "country": "BR", "currency": "BRL",
     "begin": "2026-03-10", "end": "2026-03-20", "completed": True},
    # 2025 history (for "Hide completed" filter UX)
    {"id_hint": "wps25", "year": 2025, "name": "World Poker Series 2025",
     "country": "US", "currency": "USD",
     "begin": "2025-05-28", "end": "2025-07-17", "completed": True},
    {"id_hint": "wpse25", "year": 2025, "name": "World Poker Series Europe 2025",
     "country": "CZ", "currency": "EUR",
     "begin": "2025-10-01", "end": "2025-10-22", "completed": True},
    {"id_hint": "circ-ind", "year": 2025, "name": "Circuit — Indiana",
     "country": "US", "currency": "USD",
     "begin": "2025-01-05", "end": "2025-01-16", "completed": True},
    {"id_hint": "circ-atl", "year": 2025, "name": "Circuit — Atlantic City",
     "country": "US", "currency": "USD",
     "begin": "2025-02-10", "end": "2025-02-20", "completed": True},
]

# Events for "World Poker Series Europe 2026" (wpse26 — 14 events 시나리오)
EVENTS_SEED_FOR_WPSE26 = [
    {"no": 1, "name": "The Opener Mystery Bounty", "buy_in": 1100, "display_buy_in": "€1,100",
     "game_type": 0, "bet_structure": 0, "status": "running"},
    {"no": 2, "name": "PLO / PLO8 / Big O", "buy_in": 600, "display_buy_in": "€600",
     "game_type": 1, "bet_structure": 1, "status": "registering"},
    {"no": 3, "name": "Deepstack NLH", "buy_in": 550, "display_buy_in": "€550",
     "game_type": 0, "bet_structure": 0, "status": "completed"},
    {"no": 4, "name": "Pot-Limit Omaha Championship", "buy_in": 2200, "display_buy_in": "€2,200",
     "game_type": 1, "bet_structure": 1, "status": "running"},
    {"no": 5, "name": "Europe Main Event", "buy_in": 5300, "display_buy_in": "€5,300",
     "game_type": 0, "bet_structure": 0, "status": "running"},
    {"no": 6, "name": "Mixed Games Championship", "buy_in": 3000, "display_buy_in": "€3,000",
     "game_type": 5, "bet_structure": 0, "status": "announced"},
    {"no": 7, "name": "Short Deck Spectacular", "buy_in": 1500, "display_buy_in": "€1,500",
     "game_type": 4, "bet_structure": 0, "status": "registering"},
    {"no": 8, "name": "Stud Hi-Lo 8 or Better", "buy_in": 800, "display_buy_in": "€800",
     "game_type": 2, "bet_structure": 0, "status": "announced"},
    {"no": 9, "name": "Razz Championship", "buy_in": 1200, "display_buy_in": "€1,200",
     "game_type": 3, "bet_structure": 0, "status": "announced"},
    {"no": 10, "name": "Heads-Up NLH", "buy_in": 2500, "display_buy_in": "€2,500",
     "game_type": 0, "bet_structure": 0, "status": "completed"},
]

# Events for "World Poker Series 2026" (wps26 — 95 events 의 일부 sample)
EVENTS_SEED_FOR_WPS26 = [
    {"no": 1, "name": "Casino Employees No-Limit Hold'em", "buy_in": 500, "display_buy_in": "$500",
     "game_type": 0, "bet_structure": 0, "status": "running"},
    {"no": 2, "name": "Mystery Millions", "buy_in": 1500, "display_buy_in": "$1,500",
     "game_type": 0, "bet_structure": 0, "status": "running"},
    {"no": 3, "name": "Dealers Choice", "buy_in": 1500, "display_buy_in": "$1,500",
     "game_type": 5, "bet_structure": 0, "status": "registering"},
    {"no": 4, "name": "Main Event 2026", "buy_in": 10000, "display_buy_in": "$10,000",
     "game_type": 0, "bet_structure": 0, "status": "announced"},
]

# Flights for top events (2~3 day1 flights + day2 + final)
FLIGHTS_PER_EVENT = ["Day 1A", "Day 1B", "Day 1C", "Day 2", "Final Day"]

# ── 5-level hierarchy completion (2026-05-12 S7 cycle-8) ──
# cascade:bo-hierarchy-ready
#
# 문제: Lobby에서 어떤 event를 선택해도 동일 flight mock이 노출됨.
# 원인: wpse26 event #5 + wps26 event #4만 flight 보유. 나머지는 0개 →
#       frontend mock fallback이 동일 데이터를 표시.
# 해소: 모든 active event에 최소 1개 flight + per-event 고유 display_name +
#       table에 player seat 시드 → 5-level hierarchy 실데이터 연결.

# Per-event 최소 flight 보장 (active events 한정 — running/registering/announced)
ACTIVE_FLIGHT_STATUSES = {"running", "registering", "announced"}
DEFAULT_FLIGHTS_PER_ACTIVE_EVENT = 2  # Day 1A + Day 1B 최소 보장

# Player master pool — 다양한 국가 + 이름 (table seat에 attach)
PLAYERS_SEED = [
    ("Daniel", "Negreanu", "Canadian", "CA"),
    ("Phil", "Ivey", "American", "US"),
    ("Doyle", "Brunson", "American", "US"),
    ("Phil", "Hellmuth", "American", "US"),
    ("Erik", "Seidel", "American", "US"),
    ("Vanessa", "Selbst", "American", "US"),
    ("Fedor", "Holz", "German", "DE"),
    ("Stephen", "Chidwick", "British", "GB"),
    ("Bryn", "Kenney", "American", "US"),
    ("Justin", "Bonomo", "American", "US"),
    ("Jason", "Koon", "American", "US"),
    ("Dan", "Smith", "American", "US"),
    ("David", "Peters", "American", "US"),
    ("Mikita", "Badziakouski", "Belarusian", "BY"),
    ("Sam", "Greenwood", "Canadian", "CA"),
    ("Steffen", "Sontheimer", "German", "DE"),
    ("Adrian", "Mateos", "Spanish", "ES"),
    ("Manig", "Loeser", "German", "DE"),
    ("Patrik", "Antonius", "Finnish", "FI"),
    ("Tom", "Dwan", "American", "US"),
    ("Antonio", "Esfandiari", "American", "US"),
    ("Liv", "Boeree", "British", "GB"),
    ("Maria", "Ho", "American", "US"),
    ("Jennifer", "Tilly", "American", "US"),
    ("Gus", "Hansen", "Danish", "DK"),
    ("Viktor", "Blom", "Swedish", "SE"),
    ("Alec", "Torelli", "American", "US"),
]


def _ensure_competition(db: Session) -> Competition:
    """Idempotent — return existing or create new."""
    comp = db.exec(select(Competition).where(Competition.name == DEMO_TAG)).first()
    if comp:
        return comp
    comp = Competition(name=DEMO_TAG)
    db.add(comp)
    db.commit()
    db.refresh(comp)
    return comp


def _seed_series(db: Session, comp: Competition) -> dict[str, Series]:
    """Create 8 series. Return id_hint → Series map."""
    by_hint: dict[str, Series] = {}
    for spec in SERIES_SEED:
        existing = db.exec(
            select(Series).where(
                Series.competition_id == comp.competition_id,
                Series.series_name == spec["name"],
                Series.year == spec["year"],
            )
        ).first()
        if existing:
            by_hint[spec["id_hint"]] = existing
            continue
        s = Series(
            competition_id=comp.competition_id,
            series_name=spec["name"],
            year=spec["year"],
            begin_at=spec["begin"] + "T00:00:00Z",
            end_at=spec["end"] + "T23:59:59Z",
            country_code=spec["country"],
            currency=spec["currency"],
            is_completed=spec["completed"],
            is_displayed=True,
            is_demo=True,
        )
        db.add(s)
        db.commit()
        db.refresh(s)
        by_hint[spec["id_hint"]] = s
    return by_hint


def _seed_events(db: Session, series: Series, specs: list[dict]) -> list[Event]:
    """Create events under a series (idempotent by event_no)."""
    out = []
    for spec in specs:
        existing = db.exec(
            select(Event).where(
                Event.series_id == series.series_id,
                Event.event_no == spec["no"],
            )
        ).first()
        if existing:
            out.append(existing)
            continue
        e = Event(
            series_id=series.series_id,
            event_no=spec["no"],
            event_name=spec["name"],
            buy_in=spec["buy_in"],
            display_buy_in=spec["display_buy_in"],
            game_type=spec["game_type"],
            bet_structure=spec["bet_structure"],
            game_mode="single",
            status=spec["status"],
            source="manual",
        )
        db.add(e)
        db.commit()
        db.refresh(e)
        out.append(e)
    return out


def _seed_flights(db: Session, event: Event, count: int = 3) -> list[EventFlight]:
    """Create flights for an event (Day 1A/B/C + Day2 + Final)."""
    out = []
    for i, name in enumerate(FLIGHTS_PER_EVENT[:count]):
        existing = db.exec(
            select(EventFlight).where(
                EventFlight.event_id == event.event_id,
                EventFlight.display_name == name,
            )
        ).first()
        if existing:
            out.append(existing)
            continue
        f = EventFlight(
            event_id=event.event_id,
            display_name=name,
        )
        db.add(f)
        db.commit()
        db.refresh(f)
        out.append(f)
    return out


def _seed_tables(db: Session, flight: EventFlight, count: int = 5) -> list[Table]:
    """Create tables under a flight (Table 1..N)."""
    out = []
    for i in range(1, count + 1):
        existing = db.exec(
            select(Table).where(
                Table.event_flight_id == flight.event_flight_id,
                Table.table_no == i,
            )
        ).first()
        if existing:
            out.append(existing)
            continue
        t = Table(
            event_flight_id=flight.event_flight_id,
            table_no=i,
            name=f"Table {i}",
            type="general",
            status="setup",
            max_players=9,
        )
        db.add(t)
        db.commit()
        db.refresh(t)
        out.append(t)
    return out


def _seed_default_flights_for_active_events(
    db: Session, events: list[Event], default_count: int = DEFAULT_FLIGHTS_PER_ACTIVE_EVENT,
) -> int:
    """모든 active event에 최소 N개 flight 보장.

    cascade:bo-hierarchy-ready 해소: Lobby에서 어떤 event 선택해도 자기만의
    flight 가 노출되도록 보장. event_name 일부를 display_name 에 포함하여
    event 간 식별성 확보 (단순 "Day 1A" 가 아니라 "E#1 Day 1A").
    """
    created = 0
    for event in events:
        if event.status not in ACTIVE_FLIGHT_STATUSES:
            continue
        # 이미 flight 가 있으면 skip (top events 는 별도 시드 사용)
        existing_count = len(db.exec(
            select(EventFlight).where(EventFlight.event_id == event.event_id)
        ).all())
        if existing_count >= default_count:
            continue

        prefix = f"E#{event.event_no}"
        for name in FLIGHTS_PER_EVENT[: default_count - existing_count]:
            display = f"{prefix} {name}"
            existing = db.exec(
                select(EventFlight).where(
                    EventFlight.event_id == event.event_id,
                    EventFlight.display_name == display,
                )
            ).first()
            if existing:
                continue
            f = EventFlight(
                event_id=event.event_id,
                display_name=display,
                status="created" if event.status == "announced" else event.status,
                play_level=1 if event.status == "running" else 0,
            )
            db.add(f)
            db.commit()
            db.refresh(f)
            created += 1
    return created


def _seed_players(db: Session) -> list[Player]:
    """Demo player master pool (idempotent on first_name + last_name)."""
    out: list[Player] = []
    for (first, last, nationality, cc) in PLAYERS_SEED:
        existing = db.exec(
            select(Player).where(
                Player.first_name == first,
                Player.last_name == last,
            )
        ).first()
        if existing:
            out.append(existing)
            continue
        p = Player(
            first_name=first,
            last_name=last,
            nationality=nationality,
            country_code=cc,
            is_demo=True,
            source="manual",
        )
        db.add(p)
        db.commit()
        db.refresh(p)
        out.append(p)
    return out


def _fill_table_with_players(
    db: Session, table: Table, players: list[Player], fill_count: int = 9,
) -> int:
    """Attach players to empty seats of a table.

    Idempotent: skips seats that are already non-empty. Returns how many seats
    were newly filled. fill_count caps at min(9, len(players)).
    """
    fill_count = min(fill_count, 9, len(players))
    filled = 0
    for seat_no in range(fill_count):
        seat = db.exec(
            select(TableSeat).where(
                TableSeat.table_id == table.table_id,
                TableSeat.seat_no == seat_no,
            )
        ).first()
        if seat is None:
            # Auto-create seats if missing (older tables predate create_table seats)
            seat = TableSeat(
                table_id=table.table_id, seat_no=seat_no, status="empty",
            )
            db.add(seat)
            db.commit()
            db.refresh(seat)
        if seat.status != "empty":
            continue

        player = players[seat_no % len(players)]
        seat.player_id = player.player_id
        seat.player_name = f"{player.first_name} {player.last_name}"
        seat.nationality = player.nationality
        seat.country_code = player.country_code
        seat.chip_count = 50000 + (seat_no * 5000)
        seat.status = "playing" if table.status == "running" else "new"
        db.add(seat)
        db.commit()
        filled += 1
    return filled


def _reset_demo(db: Session) -> None:
    """Hard delete all demo competitions and cascading rows.
    Used only with --reset flag.
    """
    comp = db.exec(select(Competition).where(Competition.name == DEMO_TAG)).first()
    if not comp:
        return
    series_ids = [s.series_id for s in db.exec(
        select(Series).where(Series.competition_id == comp.competition_id)
    ).all()]
    if series_ids:
        event_ids = [e.event_id for e in db.exec(
            select(Event).where(Event.series_id.in_(series_ids))
        ).all()]
        flight_ids = [f.event_flight_id for f in db.exec(
            select(EventFlight).where(EventFlight.event_id.in_(event_ids))
        ).all()] if event_ids else []
        if flight_ids:
            table_ids = [t.table_id for t in db.exec(
                select(Table).where(Table.event_flight_id.in_(flight_ids))
            ).all()]
            if table_ids:
                db.exec(delete(TableSeat).where(TableSeat.table_id.in_(table_ids)))
                db.exec(delete(Table).where(Table.table_id.in_(table_ids)))
            db.exec(delete(EventFlight).where(EventFlight.event_id.in_(event_ids)))
        if event_ids:
            db.exec(delete(Event).where(Event.series_id.in_(series_ids)))
        db.exec(delete(Series).where(Series.competition_id == comp.competition_id))
    db.exec(delete(Competition).where(Competition.competition_id == comp.competition_id))
    # Demo players (is_demo=True) — keep separate cleanup
    db.exec(delete(Player).where(Player.is_demo))  # type: ignore[arg-type]
    db.commit()


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--reset", action="store_true",
                    help="기존 demo 삭제 후 재시드")
    ap.add_argument("--database-url", default=None,
                    help="settings.database_url 기본")
    args = ap.parse_args(argv)

    db_url = args.database_url or settings.database_url
    print(f"DB: {db_url.split('@')[-1] if '@' in db_url else db_url}")
    engine = create_engine(db_url)

    with Session(engine) as db:
        if args.reset:
            print("Resetting existing demo data...")
            _reset_demo(db)
            print("  OK reset")

        # 1. Competition
        comp = _ensure_competition(db)
        print(f"  Competition: {comp.name} (id={comp.competition_id})")

        # 2. Series (8)
        by_hint = _seed_series(db, comp)
        print(f"  Series: {len(by_hint)} ({', '.join(by_hint.keys())})")

        # 3. Events for top 2 active series
        events_wpse26 = _seed_events(db, by_hint["wpse26"], EVENTS_SEED_FOR_WPSE26)
        events_wps26 = _seed_events(db, by_hint["wps26"], EVENTS_SEED_FOR_WPS26)
        print(f"  Events: wpse26={len(events_wpse26)}, wps26={len(events_wps26)}")

        # 4. Flights for "Europe Main Event" (event #5 in wpse26) + "Main Event 2026" (#4 in wps26)
        wpse26_main = next((e for e in events_wpse26 if e.event_no == 5), None)
        wps26_main = next((e for e in events_wps26 if e.event_no == 4), None)
        flights_total = 0
        if wpse26_main:
            f = _seed_flights(db, wpse26_main, count=5)
            flights_total += len(f)
        if wps26_main:
            f = _seed_flights(db, wps26_main, count=3)
            flights_total += len(f)
        print(f"  Flights: {flights_total}")

        # 5. Tables for "Europe Main Event Day 2" (heaviest)
        day2_flight = None
        if wpse26_main:
            day2_flight = db.exec(
                select(EventFlight).where(
                    EventFlight.event_id == wpse26_main.event_id,
                    EventFlight.display_name == "Day 2",
                )
            ).first()
            if day2_flight:
                tables = _seed_tables(db, day2_flight, count=10)
                print(f"  Tables: Day 2 → {len(tables)}")

        # 6. ▼ 5-level hierarchy completion (cascade:bo-hierarchy-ready, 2026-05-12)
        #    각 active event 에 최소 default flight 보장 → frontend mock fallback 해소.
        active_events = list(events_wpse26) + list(events_wps26)
        default_flights = _seed_default_flights_for_active_events(db, active_events)
        print(f"  Default flights (per active event): +{default_flights}")

        # 7. Player master pool (27 players, idempotent)
        players = _seed_players(db)
        print(f"  Players (master): {len(players)}")

        # 8. Fill Day 2 tables with players (실 데이터 가시화)
        seats_filled = 0
        if day2_flight:
            day2_tables = db.exec(
                select(Table).where(Table.event_flight_id == day2_flight.event_flight_id)
            ).all()
            # 처음 3 table 만 채움 (전체 채우면 lobby 가 무거움)
            for tbl in day2_tables[:3]:
                seats_filled += _fill_table_with_players(db, tbl, players, fill_count=9)
        print(f"  Seats filled (Day 2 first 3 tables): {seats_filled}")

    print()
    print("✓ Demo seed complete.")
    print("  Login: admin@ebs.local / admin123")
    print("  Endpoint: GET /api/v1/series → 8 series")
    print("  5-level: Series → Event → Flight → Table → Players (bo-hierarchy-ready)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
