"""Series / Event / Flight CRUD service."""
from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlmodel import Session, select

from src.models.competition import Competition, Event, EventFlight, Series
from src.models.schemas import (
    EventCreate,
    FlightCreate,
    SeriesCreate,
    SeriesUpdate,
)


def _utcnow() -> str:
    return datetime.now(timezone.utc).isoformat()


# ── Competition (helper — seed or auto-create) ──────


def get_or_create_default_competition(db: Session) -> Competition:
    """Ensure a default competition exists; return it."""
    comp = db.exec(select(Competition)).first()
    if comp is None:
        comp = Competition(name="Default Competition")
        db.add(comp)
        db.commit()
        db.refresh(comp)
    return comp


# ── Series CRUD ─────────────────────────────────────


def create_series(data: SeriesCreate, db: Session) -> Series:
    # Validate competition FK
    comp = db.exec(
        select(Competition).where(Competition.competition_id == data.competition_id)
    ).first()
    if comp is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "RESOURCE_NOT_FOUND", "message": f"Competition {data.competition_id} not found"},
        )
    s = Series(**data.model_dump())
    db.add(s)
    db.commit()
    db.refresh(s)
    return s


def list_series(db: Session, skip: int = 0, limit: int = 20) -> tuple[list[Series], int]:
    total = len(db.exec(select(Series)).all())
    items = db.exec(select(Series).offset(skip).limit(limit)).all()
    return items, total


def get_series(series_id: int, db: Session) -> Series:
    s = db.exec(select(Series).where(Series.series_id == series_id)).first()
    if s is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "RESOURCE_NOT_FOUND", "message": f"Series {series_id} not found"},
        )
    return s


def update_series(series_id: int, data: SeriesUpdate, db: Session) -> Series:
    s = get_series(series_id, db)
    updates = data.model_dump(exclude_unset=True)
    for k, v in updates.items():
        setattr(s, k, v)
    s.updated_at = _utcnow()
    db.add(s)
    db.commit()
    db.refresh(s)
    return s


def delete_series(series_id: int, db: Session) -> None:
    s = get_series(series_id, db)
    # Check for child events
    children = db.exec(select(Event).where(Event.series_id == series_id)).all()
    if children:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"code": "HAS_CHILDREN", "message": f"Series {series_id} has {len(children)} event(s)"},
        )
    db.delete(s)
    db.commit()


# ── Event CRUD ──────────────────────────────────────


def create_event(data: EventCreate, db: Session) -> Event:
    # Validate series FK
    _ = get_series(data.series_id, db)
    e = Event(**data.model_dump())
    db.add(e)
    db.commit()
    db.refresh(e)
    return e


def list_events_by_series(series_id: int, db: Session, skip: int = 0, limit: int = 20) -> tuple[list[Event], int]:
    _ = get_series(series_id, db)
    stmt = select(Event).where(Event.series_id == series_id)
    total = len(db.exec(stmt).all())
    items = db.exec(stmt.offset(skip).limit(limit)).all()
    return items, total


def get_event(event_id: int, db: Session) -> Event:
    e = db.exec(select(Event).where(Event.event_id == event_id)).first()
    if e is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "RESOURCE_NOT_FOUND", "message": f"Event {event_id} not found"},
        )
    return e


# ── Flight CRUD ─────────────────────────────────────


def create_flight(data: FlightCreate, db: Session) -> EventFlight:
    # Validate event FK
    _ = get_event(data.event_id, db)
    f = EventFlight(**data.model_dump())
    db.add(f)
    db.commit()
    db.refresh(f)
    return f


def list_flights_by_event(event_id: int, db: Session, skip: int = 0, limit: int = 20) -> tuple[list[EventFlight], int]:
    _ = get_event(event_id, db)
    stmt = select(EventFlight).where(EventFlight.event_id == event_id)
    total = len(db.exec(stmt).all())
    items = db.exec(stmt.offset(skip).limit(limit)).all()
    return items, total


def get_flight(flight_id: int, db: Session) -> EventFlight:
    f = db.exec(select(EventFlight).where(EventFlight.event_flight_id == flight_id)).first()
    if f is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "RESOURCE_NOT_FOUND", "message": f"Flight {flight_id} not found"},
        )
    return f
