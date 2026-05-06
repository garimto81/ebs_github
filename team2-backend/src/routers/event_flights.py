"""EventFlights levels router — Phase 3 (2026-05-06).

Provides the data source for the Lobby TopBar's [SHOW · FLIGHT · LEVEL · NEXT]
cluster (4-column fixed) per design SSOT `shell.jsx:43-51`.

Endpoint:
  GET /api/v1/flights/{flight_id}/levels
    → { now, next, after, countdownLabel, countdown }

Data sources:
  · event_flights.play_level         — current level number
  · event_flights.remain_time        — countdown seconds
  · events.blind_structure_id        — flight → blind_structure mapping
  · blind_structure_levels.*         — per-level blinds / ante / duration

Returns `data: null` when the flight has no blind structure assigned. The
frontend `flightLevelsProvider` falls back to em-dash placeholders in that
case (graceful degradation).
"""
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlmodel import Session

from src.app.database import get_db
from src.middleware.rbac import get_current_user
from src.models.user import User

router = APIRouter(prefix="/api/v1", tags=["flights"])


def _to_level_dict(prefix: str, row) -> dict | None:
    if row is None:
        return None
    level_no, sb, bb, ante, dur = row
    role = f"{prefix} · L{level_no}" if prefix else f"L{level_no}"
    return {
        "role": role,
        "blinds": f"{sb:,} / {bb:,}",
        "meta": f"ante {ante:,} · {dur}min",
    }


@router.get("/flights/{flight_id}/levels")
def api_get_flight_levels(
    flight_id: int,
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    flight_row = db.execute(
        text(
            "SELECT play_level, remain_time, event_id "
            "FROM event_flights WHERE event_flight_id = :id"
        ),
        {"id": flight_id},
    ).first()

    if flight_row is None:
        raise HTTPException(status_code=404, detail="Flight not found")

    play_level, remain_seconds, event_id = flight_row
    play_level = play_level or 1
    remain = remain_seconds or 0

    bs_row = db.execute(
        text("SELECT blind_structure_id FROM events WHERE event_id = :eid"),
        {"eid": event_id},
    ).first()

    if not bs_row or not bs_row[0]:
        return {"data": None}

    bs_id = bs_row[0]
    level_rows = db.execute(
        text(
            "SELECT level_no, small_blind, big_blind, ante, duration_minutes "
            "FROM blind_structure_levels "
            "WHERE blind_structure_id = :bs_id "
            "ORDER BY level_no"
        ),
        {"bs_id": bs_id},
    ).all()

    levels_by_no = {row[0]: row for row in level_rows}
    now = levels_by_no.get(play_level)
    next_lv = levels_by_no.get(play_level + 1)
    after = levels_by_no.get(play_level + 2)

    countdown = f"{remain // 60:02d}:{remain % 60:02d}" if remain > 0 else "—"
    countdown_label = f"L{play_level + 1} IN" if next_lv else "—"

    return {
        "data": {
            "now": _to_level_dict("Now", now),
            "next": _to_level_dict("Next", next_lv),
            "after": _to_level_dict("", after),
            "countdownLabel": countdown_label,
            "countdown": countdown,
        }
    }
