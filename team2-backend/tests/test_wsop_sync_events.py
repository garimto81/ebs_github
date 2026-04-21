"""WSOP LIVE events sync — map_to_ebs wiring (Sync_Protocol §1.2 enforcement).

Previously the adapter existed but had 0 callers; events UPSERT path was
absent from wsop_sync_service, letting WSOP game_type bypass conversion.
"""
import pytest

from src.adapters.wsop_game_type import map_to_ebs
from src.models.competition import Competition, Event, Series
from src.observability.circuit_breaker import CircuitBreaker
from src.services.wsop_sync_service import WsopSyncService


def _mk_service():
    return WsopSyncService(CircuitBreaker())


def test_map_to_ebs_holdem():
    ebs_type, ebs_mode = map_to_ebs(0)  # WSOP Holdem
    assert ebs_type == 0  # NLHE
    assert ebs_mode == "single"


def test_map_to_ebs_horse():
    ebs_type, ebs_mode = map_to_ebs(5)  # WSOP HORSE
    assert ebs_mode == "fixed_rotation"


@pytest.mark.asyncio
async def test_poll_events_creates_with_mapped_game_type(db_session):
    """poll_events must run payload through map_to_ebs before UPSERT."""
    svc = _mk_service()

    comp = Competition(name="WSOP")
    db_session.add(comp)
    db_session.commit()
    db_session.refresh(comp)
    s = Series(
        competition_id=comp.competition_id,
        series_name="2026 WSOP",
        year=2026,
        begin_at="2026-05-27",
        end_at="2026-07-17",
    )
    db_session.add(s)
    db_session.commit()
    db_session.refresh(s)

    payload = [
        {
            "seriesName": s.series_name,
            "year": s.year,
            "eventNo": 1,
            "eventName": "$10K NL Hold'em",
            "wsopGameType": 0,  # Holdem
            "wsopGameMode": "single",
        },
        {
            "seriesName": s.series_name,
            "year": s.year,
            "eventNo": 2,
            "eventName": "$1,500 HORSE",
            "wsopGameType": 5,  # HORSE
            "wsopGameMode": "fixed_rotation",
        },
    ]

    result = svc.upsert_events(payload, db_session)
    assert result.created == 2

    events = db_session.query(Event).order_by(Event.event_no).all()
    assert len(events) == 2
    assert events[0].game_type == 0  # NLHE
    assert events[0].game_mode == "single"
    assert events[1].game_type == 0  # HORSE → game_type=0, mode="fixed_rotation"
    assert events[1].game_mode == "fixed_rotation"


def test_poll_events_unknown_game_type_captured_as_error(db_session):
    """Unknown WSOP game_type → appended to result.errors, not raised."""
    svc = _mk_service()

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

    payload = [{
        "seriesName": s.series_name, "year": s.year,
        "eventNo": 99, "eventName": "Unknown",
        "wsopGameType": 42,  # invalid
    }]
    result = svc.upsert_events(payload, db_session)
    assert result.created == 0
    assert any("42" in e for e in result.errors)
