"""CCR-047 EventFlight status adapter — WSOP INT → EBS text with validation.

Prevents silent corruption when WSOP LIVE sync writes integer status codes
into a TEXT column. Full INT column migration tracked in Backlog B-066.
"""
import pytest

from src.adapters.event_flight_status import (
    EventFlightStatusError,
    INT_TO_TEXT,
    TEXT_TO_INT,
    VALID_INT,
    VALID_TEXT,
    int_to_text,
    normalize,
    text_to_int,
)


def test_ssot_enum_excludes_value_3():
    """WSOP LIVE reserves value 3 — must not appear in valid set."""
    assert 3 not in VALID_INT


def test_canonical_values():
    assert VALID_INT == {0, 1, 2, 4, 5, 6}
    assert VALID_TEXT == {
        "created", "announce", "registering",
        "running", "completed", "canceled",
    }


def test_int_to_text_known_values():
    assert int_to_text(0) == "created"
    assert int_to_text(4) == "running"
    assert int_to_text(6) == "canceled"


def test_int_to_text_rejects_unknown():
    with pytest.raises(EventFlightStatusError):
        int_to_text(3)
    with pytest.raises(EventFlightStatusError):
        int_to_text(99)


def test_text_to_int_roundtrip():
    for code, label in INT_TO_TEXT.items():
        assert text_to_int(label) == code


def test_text_to_int_rejects_typo():
    with pytest.raises(EventFlightStatusError):
        text_to_int("runnin")  # typo
    with pytest.raises(EventFlightStatusError):
        text_to_int("paused")  # Clock substate, not EventFlight state


def test_normalize_accepts_both_forms():
    assert normalize(4) == "running"
    assert normalize("running") == "running"


def test_normalize_rejects_invalid():
    with pytest.raises(EventFlightStatusError):
        normalize("unknown")
    with pytest.raises(EventFlightStatusError):
        normalize(99)


# ── Integration: wsop_sync uses the adapter ────────────


def test_wsop_sync_upsert_event_flights_converts_int_status(db_session):
    """WSOP LIVE sends `status=4` → stored as `"running"` not as the integer."""
    from src.models.competition import Competition, Event, Series
    from src.observability.circuit_breaker import CircuitBreaker
    from src.services.wsop_sync_service import WsopSyncService

    comp = Competition(name="WSOP")
    db_session.add(comp)
    db_session.commit()
    db_session.refresh(comp)
    s = Series(
        competition_id=comp.competition_id,
        series_name="2026 WSOP", year=2026,
        begin_at="2026-05-27", end_at="2026-07-17",
    )
    db_session.add(s)
    db_session.commit()
    db_session.refresh(s)
    e = Event(
        series_id=s.series_id, event_no=1,
        event_name="Main", game_type=0,
    )
    db_session.add(e)
    db_session.commit()
    db_session.refresh(e)

    svc = WsopSyncService(CircuitBreaker())
    result = svc.upsert_event_flights([
        {"event_id": e.event_id, "display_name": "Day 1A", "status": 4},
    ], db_session)

    assert result.created == 1
    assert result.errors == []

    from src.models.competition import EventFlight
    fl = db_session.query(EventFlight).first()
    assert fl.status == "running"


def test_wsop_sync_rejects_invalid_status_int(db_session):
    """WSOP sends status=3 → adapter rejects, recorded as error."""
    from src.models.competition import Competition, Event, Series
    from src.observability.circuit_breaker import CircuitBreaker
    from src.services.wsop_sync_service import WsopSyncService

    comp = Competition(name="WSOP")
    db_session.add(comp)
    db_session.commit()
    db_session.refresh(comp)
    s = Series(
        competition_id=comp.competition_id,
        series_name="2026 WSOP", year=2026,
        begin_at="2026-05-27", end_at="2026-07-17",
    )
    db_session.add(s)
    db_session.commit()
    db_session.refresh(s)
    e = Event(series_id=s.series_id, event_no=1, event_name="Main")
    db_session.add(e)
    db_session.commit()
    db_session.refresh(e)

    svc = WsopSyncService(CircuitBreaker())
    result = svc.upsert_event_flights([
        {"event_id": e.event_id, "display_name": "Bad", "status": 3},
    ], db_session)

    assert result.created == 0
    assert any("3" in err for err in result.errors)
