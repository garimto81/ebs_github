"""BlindStructure CRUD service."""
from __future__ import annotations

from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlmodel import Session, select

from src.models.blind_structure import BlindStructure, BlindStructureLevel
from src.models.competition import Event, EventFlight
from src.models.schemas import BlindStructureCreate, BlindStructureUpdate


def _utcnow() -> str:
    return datetime.now(timezone.utc).isoformat()


# ── BlindStructure CRUD ────────────────────────────


def list_blind_structures(
    db: Session, skip: int = 0, limit: int = 20
) -> tuple[list[BlindStructure], int]:
    total = len(db.exec(select(BlindStructure)).all())
    items = db.exec(select(BlindStructure).offset(skip).limit(limit)).all()
    return items, total


def get_blind_structure(bs_id: int, db: Session) -> BlindStructure:
    bs = db.exec(
        select(BlindStructure).where(BlindStructure.blind_structure_id == bs_id)
    ).first()
    if bs is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "RESOURCE_NOT_FOUND", "message": f"BlindStructure {bs_id} not found"},
        )
    return bs


def get_blind_structure_levels(bs_id: int, db: Session) -> list[BlindStructureLevel]:
    return db.exec(
        select(BlindStructureLevel)
        .where(BlindStructureLevel.blind_structure_id == bs_id)
        .order_by(BlindStructureLevel.level_no)
    ).all()


def get_blind_structure_level(level_id: int, db: Session) -> BlindStructureLevel:
    """V9.5 Phase 3: single level lookup."""
    lv = db.exec(
        select(BlindStructureLevel).where(BlindStructureLevel.id == level_id)
    ).first()
    if lv is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "RESOURCE_NOT_FOUND", "message": f"BlindStructureLevel {level_id} not found"},
        )
    return lv


def create_blind_structure_level(
    bs_id: int, data, db: Session
) -> BlindStructureLevel:
    """V9.5 Phase 3: append single level to existing structure."""
    # Validate parent
    _ = get_blind_structure(bs_id, db)
    level = BlindStructureLevel(
        blind_structure_id=bs_id,
        **data.model_dump(),
    )
    db.add(level)
    db.commit()
    db.refresh(level)
    return level


def update_blind_structure_level(
    level_id: int, data, db: Session
) -> BlindStructureLevel:
    """V9.5 Phase 3: update single level fields."""
    lv = get_blind_structure_level(level_id, db)
    payload = data.model_dump(exclude_unset=True)
    for key, value in payload.items():
        setattr(lv, key, value)
    db.add(lv)
    db.commit()
    db.refresh(lv)
    return lv


def delete_blind_structure_level(level_id: int, db: Session) -> None:
    """V9.5 Phase 3: delete single level."""
    lv = get_blind_structure_level(level_id, db)
    db.delete(lv)
    db.commit()


def create_blind_structure(data: BlindStructureCreate, db: Session) -> BlindStructure:
    bs = BlindStructure(name=data.name)
    db.add(bs)
    db.commit()
    db.refresh(bs)

    for lv in data.levels:
        level = BlindStructureLevel(
            blind_structure_id=bs.blind_structure_id,
            **lv.model_dump(),
        )
        db.add(level)
    db.commit()
    db.refresh(bs)
    return bs


def update_blind_structure(
    bs_id: int, data: BlindStructureUpdate, db: Session
) -> BlindStructure:
    bs = get_blind_structure(bs_id, db)

    if data.name is not None:
        bs.name = data.name

    bs.updated_at = _utcnow()
    db.add(bs)

    # Replace levels if provided
    if data.levels is not None:
        # Delete existing levels
        old_levels = db.exec(
            select(BlindStructureLevel)
            .where(BlindStructureLevel.blind_structure_id == bs_id)
        ).all()
        for old in old_levels:
            db.delete(old)

        # Insert new levels
        for lv in data.levels:
            level = BlindStructureLevel(
                blind_structure_id=bs_id,
                **lv.model_dump(),
            )
            db.add(level)

    db.commit()
    db.refresh(bs)
    return bs


def delete_blind_structure(bs_id: int, db: Session) -> None:
    bs = get_blind_structure(bs_id, db)

    # Check if any events reference this structure
    refs = db.exec(
        select(Event).where(Event.blind_structure_id == bs_id)
    ).all()
    if refs:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={
                "code": "HAS_REFERENCES",
                "message": f"BlindStructure {bs_id} is referenced by {len(refs)} event(s)",
            },
        )

    # Delete levels first
    levels = db.exec(
        select(BlindStructureLevel)
        .where(BlindStructureLevel.blind_structure_id == bs_id)
    ).all()
    for lv in levels:
        db.delete(lv)

    db.delete(bs)
    db.commit()


# ── Flight ↔ BlindStructure ───────────────────────


def get_flight_blind_structure(
    flight_id: int, db: Session
) -> BlindStructure:
    flight = db.exec(
        select(EventFlight).where(EventFlight.event_flight_id == flight_id)
    ).first()
    if flight is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "RESOURCE_NOT_FOUND", "message": f"Flight {flight_id} not found"},
        )

    event = db.exec(
        select(Event).where(Event.event_id == flight.event_id)
    ).first()
    if event is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "RESOURCE_NOT_FOUND", "message": f"Event {flight.event_id} not found"},
        )

    if event.blind_structure_id is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "RESOURCE_NOT_FOUND", "message": f"No blind structure assigned to event {event.event_id}"},
        )

    return get_blind_structure(event.blind_structure_id, db)


def apply_blind_structure(
    flight_id: int, bs_id: int, db: Session
) -> Event:
    # Validate flight
    flight = db.exec(
        select(EventFlight).where(EventFlight.event_flight_id == flight_id)
    ).first()
    if flight is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "RESOURCE_NOT_FOUND", "message": f"Flight {flight_id} not found"},
        )

    # Validate blind structure
    _ = get_blind_structure(bs_id, db)

    # Apply to event
    event = db.exec(
        select(Event).where(Event.event_id == flight.event_id)
    ).first()
    if event is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "RESOURCE_NOT_FOUND", "message": f"Event {flight.event_id} not found"},
        )

    event.blind_structure_id = bs_id
    event.updated_at = _utcnow()
    db.add(event)
    db.commit()
    db.refresh(event)
    return event
