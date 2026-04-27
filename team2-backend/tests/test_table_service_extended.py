"""table_service.py extended unit tests (Session 2.3b — B-Q10 cascade, 2026-04-27).

Targets missing branches in src/services/table_service.py (65% → 80% goal):
- list_tables / list_all_tables (404 invalid flight, filter)
- get_table 404 / update_table / delete_table cascade
- create_table (10 auto seats / invalid flight)
- launch_cc (returns token / 404)
- rebalance_tables (dry_run / empty)
- assign_seat (occupied / player not found)
- update_seat_status (invalid transition / clear on empty)
- vacate_seat (clears player data)

Strict rule: production code 0 modification, tests/ only.
"""
import pytest
from fastapi import HTTPException
from sqlmodel import Session, select

from src.models.competition import Competition
from src.models.schemas import (
    EventCreate,
    FlightCreate,
    SeriesCreate,
    TableCreate,
    TableUpdate,
)
from src.models.table import Player, Table, TableSeat
from src.models.user import User
from src.security.password import hash_password
from src.services.series_service import (
    create_event,
    create_flight,
    create_series,
)
from src.services.table_service import (
    assign_seat,
    create_table,
    delete_table,
    get_table,
    get_table_seats,
    launch_cc,
    list_all_tables,
    list_tables,
    rebalance_tables,
    update_seat_status,
    update_table,
    vacate_seat,
)


# ── helpers ──────────────────────────────────────


def _setup_flight(db: Session, prefix: str = "TS"):
    """Create Competition → Series → Event → Flight chain. Returns flight_id."""
    comp = Competition(name=f"{prefix}-Comp")
    db.add(comp)
    db.commit()
    db.refresh(comp)

    series = create_series(
        SeriesCreate(
            competition_id=comp.competition_id,
            series_name=f"{prefix}-Series",
            year=2026,
            begin_at="2026-04-27T00:00:00Z",
            end_at="2026-05-27T00:00:00Z",
        ),
        db,
    )
    event = create_event(
        EventCreate(series_id=series.series_id, event_no=1, event_name=f"{prefix}-Ev"),
        db,
    )
    flight = create_flight(
        FlightCreate(event_id=event.event_id, display_name=f"{prefix}-Fl"),
        db,
    )
    return flight.event_flight_id


def _make_table(db: Session, flight_id: int, table_no: int = 1, name: str = "T1") -> Table:
    return create_table(
        flight_id, TableCreate(table_no=table_no, name=name), db
    )


def _make_player(db: Session, first: str = "John", last: str = "Doe") -> Player:
    p = Player(first_name=first, last_name=last)
    db.add(p)
    db.commit()
    db.refresh(p)
    return p


def _make_user(db: Session, email: str = "table-test@example.com") -> User:
    user = User(
        email=email,
        password_hash=hash_password("Test123!"),
        display_name="Table Test",
        role="admin",
        is_active=True,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


# ── Table CRUD ──────────────────────────────────


def test_create_table_creates_10_seats(db_session: Session):
    """create_table auto-creates 10 seats (line 40-43)."""
    flight_id = _setup_flight(db_session, prefix="C10")
    table = _make_table(db_session, flight_id, table_no=1, name="C10-T")
    seats = get_table_seats(table.table_id, db_session)
    assert len(seats) == 10
    assert all(s.status == "empty" for s in seats)
    assert sorted(s.seat_no for s in seats) == list(range(10))


def test_create_table_invalid_flight_404(db_session: Session):
    """create_table raises 404 when flight doesn't exist (line 29 via get_flight)."""
    with pytest.raises(HTTPException) as excinfo:
        create_table(99999, TableCreate(table_no=1, name="Orphan"), db_session)
    assert excinfo.value.status_code == 404


def test_list_tables_invalid_flight_404(db_session: Session):
    """list_tables raises 404 for invalid flight (line 49 via get_flight)."""
    with pytest.raises(HTTPException) as excinfo:
        list_tables(99999, db_session)
    assert excinfo.value.status_code == 404


def test_list_all_tables_with_flight_filter(db_session: Session):
    """list_all_tables filters by flight_id (line 61-63)."""
    flight_id = _setup_flight(db_session, prefix="LF")
    _make_table(db_session, flight_id, table_no=1, name="F1")
    _make_table(db_session, flight_id, table_no=2, name="F2")
    items, total = list_all_tables(db_session, flight_id=flight_id)
    assert total >= 2
    assert all(t.event_flight_id == flight_id for t in items)


def test_get_table_not_found_404(db_session: Session):
    """get_table raises 404 (line 71-75)."""
    with pytest.raises(HTTPException) as excinfo:
        get_table(99999, db_session)
    assert excinfo.value.status_code == 404


def test_update_table_partial_fields(db_session: Session):
    """update_table patches only provided fields (line 79-88)."""
    flight_id = _setup_flight(db_session, prefix="UT")
    table = _make_table(db_session, flight_id, table_no=1, name="OldName")
    updated = update_table(
        table.table_id, TableUpdate(name="NewName"), db_session
    )
    assert updated.name == "NewName"


def test_delete_table_cascades_seats(db_session: Session):
    """delete_table also deletes its seats (line 92-98)."""
    flight_id = _setup_flight(db_session, prefix="DT")
    table = _make_table(db_session, flight_id, table_no=1, name="DelTest")
    table_id = table.table_id
    delete_table(table_id, db_session)
    # Verify table gone
    with pytest.raises(HTTPException):
        get_table(table_id, db_session)
    # Verify seats gone
    seats = db_session.exec(
        select(TableSeat).where(TableSeat.table_id == table_id)
    ).all()
    assert len(seats) == 0


# ── launch_cc ───────────────────────────────────


def test_launch_cc_returns_token_and_marks_live(db_session: Session):
    """launch_cc updates table status + returns token + ws_url (line 103-123)."""
    flight_id = _setup_flight(db_session, prefix="LC")
    table = _make_table(db_session, flight_id, table_no=1, name="LCT")
    user = _make_user(db_session, email="launch-cc@example.com")
    result = launch_cc(table.table_id, user, db_session)
    assert result["table_id"] == table.table_id
    assert result["status"] == "live"
    assert result["cc_instance_id"]
    assert result["launch_token"]
    assert result["ws_url"].startswith("ws://")
    assert str(table.table_id) in result["ws_url"]


def test_launch_cc_table_not_found(db_session: Session):
    """launch_cc raises 404 via get_table (line 103)."""
    user = _make_user(db_session, email="launch-cc-404@example.com")
    with pytest.raises(HTTPException) as excinfo:
        launch_cc(99999, user, db_session)
    assert excinfo.value.status_code == 404


# ── rebalance_tables ────────────────────────────


def test_rebalance_tables_no_tables_returns_empty(db_session: Session):
    """rebalance_tables returns empty result when no tables exist (line 132-134)."""
    flight_id = _setup_flight(db_session, prefix="RB1")
    result = rebalance_tables(flight_id, "even", 9, dry_run=False, db=db_session)
    assert result["status"] == "completed"
    assert result["moved"] == []
    assert result["tables_closed"] == []


def test_rebalance_tables_dry_run_marks_status(db_session: Session):
    """rebalance_tables dry_run=True returns status='dry_run' (line 144-151)."""
    flight_id = _setup_flight(db_session, prefix="RB2")
    _make_table(db_session, flight_id, table_no=1, name="RB-T1")
    result = rebalance_tables(flight_id, "even", 9, dry_run=True, db=db_session)
    assert result["status"] == "dry_run"
    assert "saga_id" in result
    assert "steps" in result


# ── Seat operations ─────────────────────────────


def test_assign_seat_already_occupied_409(db_session: Session):
    """assign_seat raises 409 when seat is not empty (line 206-210)."""
    flight_id = _setup_flight(db_session, prefix="AO")
    table = _make_table(db_session, flight_id, table_no=1, name="AO-T")
    p1 = _make_player(db_session, first="P1", last="One")
    p2 = _make_player(db_session, first="P2", last="Two")
    # First assign — succeeds
    assign_seat(table.table_id, 0, p1.player_id, db_session, chip_count=1000)
    # Second assign to same seat — 409
    with pytest.raises(HTTPException) as excinfo:
        assign_seat(table.table_id, 0, p2.player_id, db_session)
    assert excinfo.value.status_code == 409
    assert excinfo.value.detail["code"] == "SEAT_OCCUPIED"


def test_assign_seat_player_not_found_404(db_session: Session):
    """assign_seat raises 404 for unknown player (line 213-218)."""
    flight_id = _setup_flight(db_session, prefix="APN")
    table = _make_table(db_session, flight_id, table_no=1, name="APN-T")
    with pytest.raises(HTTPException) as excinfo:
        assign_seat(table.table_id, 0, 99999, db_session)
    assert excinfo.value.status_code == 404


def test_update_seat_status_invalid_transition_400(db_session: Session):
    """update_seat_status raises 400 for invalid transition (line 239-246)."""
    flight_id = _setup_flight(db_session, prefix="UST")
    table = _make_table(db_session, flight_id, table_no=1, name="UST-T")
    # Seat is 'empty' — invalid transition to 'eliminated' (must go through new/seated/etc)
    with pytest.raises(HTTPException) as excinfo:
        update_seat_status(table.table_id, 0, "eliminated", db_session)
    assert excinfo.value.status_code == 400
    assert excinfo.value.detail["code"] == "INVALID_TRANSITION"


def test_vacate_seat_clears_player_data(db_session: Session):
    """vacate_seat sets status=empty + clears player fields (line 265-278)."""
    flight_id = _setup_flight(db_session, prefix="VS")
    table = _make_table(db_session, flight_id, table_no=1, name="VS-T")
    player = _make_player(db_session, first="VP", last="Vac")
    # Assign first
    assign_seat(table.table_id, 0, player.player_id, db_session, chip_count=500)
    # Vacate
    seat = vacate_seat(table.table_id, 0, db_session)
    assert seat.status == "empty"
    assert seat.player_id is None
    assert seat.player_name is None
    assert seat.chip_count == 0
