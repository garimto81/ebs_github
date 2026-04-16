"""Clock service — tournament timer state per flight."""
from __future__ import annotations

from datetime import datetime, timezone

from fastapi import HTTPException
from sqlmodel import Session

from src.services.series_service import get_flight


def _utcnow() -> str:
    return datetime.now(timezone.utc).isoformat()


def get_clock_state(flight_id: int, db: Session) -> dict:
    f = get_flight(flight_id, db)
    return {
        "event_flight_id": f.event_flight_id,
        "status": f.status,
        "play_level": f.play_level,
        "remain_time": f.remain_time,
    }


def start_clock(flight_id: int, db: Session) -> dict:
    f = get_flight(flight_id, db)
    if f.status not in ("created", "paused"):
        raise HTTPException(
            400,
            detail={"code": "INVALID_STATE", "message": f"Cannot start from '{f.status}'"},
        )
    f.status = "running"
    f.updated_at = _utcnow()
    db.add(f)
    db.commit()
    db.refresh(f)
    return get_clock_state(flight_id, db)


def pause_clock(flight_id: int, db: Session) -> dict:
    f = get_flight(flight_id, db)
    if f.status != "running":
        raise HTTPException(
            400,
            detail={"code": "INVALID_STATE", "message": f"Cannot pause from '{f.status}'"},
        )
    f.status = "paused"
    f.updated_at = _utcnow()
    db.add(f)
    db.commit()
    db.refresh(f)
    return get_clock_state(flight_id, db)


def resume_clock(flight_id: int, db: Session) -> dict:
    f = get_flight(flight_id, db)
    if f.status != "paused":
        raise HTTPException(
            400,
            detail={"code": "INVALID_STATE", "message": f"Cannot resume from '{f.status}'"},
        )
    f.status = "running"
    f.updated_at = _utcnow()
    db.add(f)
    db.commit()
    db.refresh(f)
    return get_clock_state(flight_id, db)


def adjust_clock(flight_id: int, level_diff: int, time_diff: int, db: Session) -> dict:
    f = get_flight(flight_id, db)
    if level_diff:
        f.play_level = max(1, f.play_level + level_diff)
    if time_diff and f.remain_time is not None:
        f.remain_time = max(0, f.remain_time + time_diff)
    f.updated_at = _utcnow()
    db.add(f)
    db.commit()
    db.refresh(f)
    return get_clock_state(flight_id, db)


def restart_level(flight_id: int, db: Session) -> dict:
    f = get_flight(flight_id, db)
    # Reset remain_time — client recalculates from blind structure
    f.remain_time = None
    f.status = "running"
    f.updated_at = _utcnow()
    db.add(f)
    db.commit()
    db.refresh(f)
    return get_clock_state(flight_id, db)
