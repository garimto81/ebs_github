import pytest
from fastapi import HTTPException

from bo.db.models import (
    Competition, Series, Event, EventFlight, Table, TableSeat, Player,
)
from bo.services.table_service import apply_transition, validate_transition


def _make_table(session, *, game_type=1, status="empty", table_type="general"):
    """Create minimal hierarchy + table for testing."""
    comp = Competition(name="Test")
    session.add(comp)
    session.commit()
    session.refresh(comp)

    series = Series(
        competition_id=comp.competition_id,
        series_name="S1",
        year=2026,
        begin_at="2026-01-01",
        end_at="2026-12-31",
    )
    session.add(series)
    session.commit()
    session.refresh(series)

    event = Event(series_id=series.series_id, event_no=1, event_name="E1")
    session.add(event)
    session.commit()
    session.refresh(event)

    flight = EventFlight(event_id=event.event_id, display_name="D1")
    session.add(flight)
    session.commit()
    session.refresh(flight)

    table = Table(
        event_flight_id=flight.event_flight_id,
        table_no=1,
        name="T1",
        game_type=game_type,
        status=status,
        type=table_type,
    )
    session.add(table)
    session.commit()
    session.refresh(table)
    return table


def _add_seat(session, table_id, seat_no, *, status="vacant", player_id=None):
    seat = TableSeat(
        table_id=table_id,
        seat_no=seat_no,
        status=status,
        player_id=player_id,
    )
    session.add(seat)
    session.commit()
    session.refresh(seat)
    return seat


def test_empty_to_setup_valid(session):
    table = _make_table(session, game_type=1, status="empty")
    player = Player(first_name="A", last_name="B")
    session.add(player)
    session.commit()
    session.refresh(player)
    _add_seat(session, table.table_id, 1, status="occupied", player_id=player.player_id)

    ok, reason = validate_transition(session, table, "setup")
    assert ok is True


def test_empty_to_setup_no_game_type(session):
    table = _make_table(session, game_type=0, status="empty")
    ok, reason = validate_transition(session, table, "setup")
    assert ok is False
    assert "게임 설정" in reason


def test_empty_to_setup_no_seats(session):
    table = _make_table(session, game_type=1, status="empty")
    ok, reason = validate_transition(session, table, "setup")
    assert ok is False
    assert "플레이어" in reason


def test_invalid_transition(session):
    table = _make_table(session, status="empty")
    ok, reason = validate_transition(session, table, "live")
    assert ok is False


def test_setup_to_live_valid(session):
    table = _make_table(session, game_type=1, status="setup")
    player = Player(first_name="C", last_name="D")
    session.add(player)
    session.commit()
    session.refresh(player)
    _add_seat(session, table.table_id, 1, status="occupied", player_id=player.player_id)

    ok, reason = validate_transition(session, table, "live")
    assert ok is True


def test_setup_to_live_missing_player_id(session):
    table = _make_table(session, game_type=1, status="setup")
    _add_seat(session, table.table_id, 1, status="occupied", player_id=None)

    ok, reason = validate_transition(session, table, "live")
    assert ok is False
    assert "좌석 배치" in reason


def test_feature_table_requires_rfid(session):
    table = _make_table(session, game_type=1, status="setup", table_type="feature")
    player = Player(first_name="E", last_name="F")
    session.add(player)
    session.commit()
    session.refresh(player)
    _add_seat(session, table.table_id, 1, status="occupied", player_id=player.player_id)

    ok, reason = validate_transition(session, table, "live")
    assert ok is False
    assert "RFID" in reason


def test_live_to_paused(session):
    table = _make_table(session, status="live")
    ok, _ = validate_transition(session, table, "paused")
    assert ok is True


def test_paused_to_live(session):
    table = _make_table(session, status="paused")
    ok, _ = validate_transition(session, table, "live")
    assert ok is True


def test_live_to_closed(session):
    table = _make_table(session, status="live")
    ok, _ = validate_transition(session, table, "closed")
    assert ok is True


def test_closed_to_empty(session):
    table = _make_table(session, status="closed")
    ok, _ = validate_transition(session, table, "empty")
    assert ok is True


def test_apply_transition_success(session):
    table = _make_table(session, status="live")
    result = apply_transition(session, table, "paused")
    assert result.status == "paused"


def test_apply_transition_failure(session):
    table = _make_table(session, status="empty")
    with pytest.raises(HTTPException) as exc_info:
        apply_transition(session, table, "closed")
    assert exc_info.value.status_code == 400
