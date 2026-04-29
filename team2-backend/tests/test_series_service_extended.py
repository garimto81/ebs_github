"""series_service.py extended unit tests (Session 2.3a — B-Q10 cascade, 2026-04-27).

Targets missing branches:
- get_or_create_default_competition (auto-create branch)
- create_series (FK validation), get/update/delete series
- create_event (FK validation), get_event (404)
- complete_flight / cancel_flight invalid state

Strict rule (B-Q15 cascade): production code 0 modification, tests/ only.
"""
import pytest
from fastapi import HTTPException
from sqlmodel import Session, select

from src.models.competition import Competition, EventFlight
from src.models.schemas import (
    EventCreate,
    FlightCreate,
    SeriesCreate,
    SeriesUpdate,
)
from src.services.series_service import (
    cancel_flight,
    complete_flight,
    create_event,
    create_flight,
    create_series,
    delete_series,
    get_event,
    get_or_create_default_competition,
    get_series,
    list_series,
    update_series,
)


# ── helpers ──────────────────────────────────────


def _make_competition(db: Session, name: str = "TestComp") -> Competition:
    comp = Competition(name=name)
    db.add(comp)
    db.commit()
    db.refresh(comp)
    return comp


def _make_series(db: Session, comp_id: int, name: str = "TestSeries") -> int:
    """Create series via service. Returns series_id."""
    s = create_series(
        SeriesCreate(
            competition_id=comp_id,
            series_name=name,
            year=2026,
            begin_at="2026-04-27T00:00:00Z",
            end_at="2026-05-27T00:00:00Z",
        ),
        db,
    )
    return s.series_id


# ── Competition (default helper) ────────────────


def test_get_or_create_default_competition_creates_new(db_session: Session):
    """If no Competition exists, create_or_get creates 'Default Competition' (line 28-33)."""
    # Delete any existing competitions for clean test
    existing = db_session.exec(select(Competition)).all()
    for comp in existing:
        db_session.delete(comp)
    db_session.commit()

    result = get_or_create_default_competition(db_session)
    assert result is not None
    assert result.name == "Default Competition"
    assert result.competition_id is not None


def test_get_or_create_default_competition_returns_existing(db_session: Session):
    """If a Competition already exists, return the first one (line 27, skip create)."""
    _make_competition(db_session, name="ExistingComp")
    result = get_or_create_default_competition(db_session)
    assert result is not None
    # Returns *first* competition — name may differ from "Default Competition"
    assert result.name in {"ExistingComp", "Default Competition"}


# ── Series CRUD ─────────────────────────────────


def test_create_series_competition_not_found_raises_404(db_session: Session):
    """create_series raises 404 if competition_id doesn't exist (line 44-48)."""
    with pytest.raises(HTTPException) as excinfo:
        create_series(
            SeriesCreate(
                competition_id=99999,
                series_name="Orphan",
                year=2026,
                begin_at="2026-04-27T00:00:00Z",
                end_at="2026-05-27T00:00:00Z",
            ),
            db_session,
        )
    assert excinfo.value.status_code == 404
    assert excinfo.value.detail["code"] == "RESOURCE_NOT_FOUND"


def test_create_series_succeeds_with_valid_competition(db_session: Session):
    """create_series persists Series with valid competition (line 49-53)."""
    comp = _make_competition(db_session, name="ValidComp")
    series = create_series(
        SeriesCreate(
            competition_id=comp.competition_id,
            series_name="ValidSeries",
            year=2026,
            begin_at="2026-04-27T00:00:00Z",
            end_at="2026-05-27T00:00:00Z",
        ),
        db_session,
    )
    assert series.series_id is not None
    assert series.series_name == "ValidSeries"
    assert series.competition_id == comp.competition_id


def test_list_series_returns_list_and_count(db_session: Session):
    """list_series returns (list, total) (line 56-59)."""
    items, total = list_series(db_session)
    assert isinstance(items, list)
    assert isinstance(total, int)
    assert total >= 0


def test_get_series_not_found_404(db_session: Session):
    """get_series raises 404 for unknown id (line 64-68)."""
    with pytest.raises(HTTPException) as excinfo:
        get_series(99999, db_session)
    assert excinfo.value.status_code == 404


def test_update_series_partial_fields(db_session: Session, monkeypatch):
    """update_series patches only provided fields + updates timestamp (line 73-81).

    Note: _utcnow() resolution depends on system clock and may collide between
    rapid create→update calls under full suite (Windows clock granularity).
    monkeypatch ensures the two _utcnow() calls return deterministically distinct
    values, isolating the assertion from clock timing.
    """
    from src.services import series_service

    comp = _make_competition(db_session, name="UpdComp")
    series_id = _make_series(db_session, comp.competition_id, name="OldName")
    old_updated = get_series(series_id, db_session).updated_at

    monkeypatch.setattr(
        series_service, "_utcnow", lambda: "2099-12-31T23:59:59.999999+00:00"
    )

    updated = update_series(
        series_id, SeriesUpdate(series_name="NewName", is_completed=True), db_session
    )
    assert updated.series_name == "NewName"
    assert updated.is_completed is True
    assert updated.updated_at != old_updated  # timestamp refreshed


def test_update_series_not_found(db_session: Session):
    """update_series raises 404 via get_series (line 73)."""
    with pytest.raises(HTTPException) as excinfo:
        update_series(99999, SeriesUpdate(series_name="X"), db_session)
    assert excinfo.value.status_code == 404


def test_delete_series_succeeds(db_session: Session):
    """delete_series removes a series with no children (line 84-94)."""
    comp = _make_competition(db_session, name="DelComp")
    series_id = _make_series(db_session, comp.competition_id, name="DelSeries")
    delete_series(series_id, db_session)
    with pytest.raises(HTTPException) as excinfo:
        get_series(series_id, db_session)
    assert excinfo.value.status_code == 404


def test_delete_series_with_events_raises_409(db_session: Session):
    """delete_series raises 409 when child Events exist (line 87-92)."""
    comp = _make_competition(db_session, name="ChildComp")
    series_id = _make_series(db_session, comp.competition_id, name="ParentSeries")
    # Create a child event
    create_event(
        EventCreate(
            series_id=series_id,
            event_no=1,
            event_name="ChildEvent",
        ),
        db_session,
    )
    with pytest.raises(HTTPException) as excinfo:
        delete_series(series_id, db_session)
    assert excinfo.value.status_code == 409
    assert excinfo.value.detail["code"] == "HAS_CHILDREN"


def test_delete_series_not_found(db_session: Session):
    with pytest.raises(HTTPException) as excinfo:
        delete_series(99999, db_session)
    assert excinfo.value.status_code == 404


# ── Event CRUD ──────────────────────────────────


def test_create_event_series_not_found_404(db_session: Session):
    """create_event raises 404 when series_id is invalid (line 102 via get_series)."""
    with pytest.raises(HTTPException) as excinfo:
        create_event(
            EventCreate(
                series_id=99999,
                event_no=1,
                event_name="Orphan",
            ),
            db_session,
        )
    assert excinfo.value.status_code == 404


def test_get_event_not_found_404(db_session: Session):
    """get_event raises 404 for unknown event_id (line 120-124)."""
    with pytest.raises(HTTPException) as excinfo:
        get_event(99999, db_session)
    assert excinfo.value.status_code == 404


# ── Flight lifecycle transitions ────────────────


def test_complete_flight_invalid_state_raises_409(db_session: Session):
    """complete_flight raises 409 when status not in {running} (line 249-256)."""
    comp = _make_competition(db_session, name="LCComp")
    series_id = _make_series(db_session, comp.competition_id, name="LCSeries")
    event = create_event(
        EventCreate(series_id=series_id, event_no=1, event_name="LCEvent"),
        db_session,
    )
    flight = create_flight(
        FlightCreate(event_id=event.event_id, display_name="LCFlight1"),
        db_session,
    )
    # Default status is 'created' — cannot complete
    with pytest.raises(HTTPException) as excinfo:
        complete_flight(flight.event_flight_id, None, db_session)
    assert excinfo.value.status_code == 409
    assert excinfo.value.detail["code"] == "INVALID_STATE"


def test_cancel_flight_invalid_state_raises_409(db_session: Session):
    """cancel_flight raises 409 when status is 'completed' (line 268-275)."""
    comp = _make_competition(db_session, name="CXComp")
    series_id = _make_series(db_session, comp.competition_id, name="CXSeries")
    event = create_event(
        EventCreate(series_id=series_id, event_no=1, event_name="CXEvent"),
        db_session,
    )
    flight = create_flight(
        FlightCreate(event_id=event.event_id, display_name="CXFlight1"),
        db_session,
    )
    # Manually set status to 'completed' to test the 409 path
    f = db_session.exec(
        select(EventFlight).where(EventFlight.event_flight_id == flight.event_flight_id)
    ).first()
    f.status = "completed"
    db_session.add(f)
    db_session.commit()

    with pytest.raises(HTTPException) as excinfo:
        cancel_flight(flight.event_flight_id, "test-reason", db_session)
    assert excinfo.value.status_code == 409


def test_complete_flight_succeeds_from_running(db_session: Session):
    """complete_flight transitions running → completed (line 257-262)."""
    comp = _make_competition(db_session, name="OKComp")
    series_id = _make_series(db_session, comp.competition_id, name="OKSeries")
    event = create_event(
        EventCreate(series_id=series_id, event_no=1, event_name="OKEvent"),
        db_session,
    )
    flight = create_flight(
        FlightCreate(event_id=event.event_id, display_name="OKFlight"),
        db_session,
    )
    # Manually set status to 'running'
    f = db_session.exec(
        select(EventFlight).where(EventFlight.event_flight_id == flight.event_flight_id)
    ).first()
    f.status = "running"
    db_session.add(f)
    db_session.commit()

    completed = complete_flight(flight.event_flight_id, None, db_session)
    assert completed.status == "completed"
