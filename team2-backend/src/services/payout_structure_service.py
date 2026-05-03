"""PayoutStructure CRUD service."""
from __future__ import annotations

from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlmodel import Session, select

from src.models.payout_structure import PayoutStructure, PayoutStructureLevel
from src.models.schemas import PayoutStructureCreate, PayoutStructureUpdate


def _utcnow() -> str:
    return datetime.now(timezone.utc).isoformat()


# ── PayoutStructure CRUD ─────────────────────────────


def list_payout_structures(
    db: Session, skip: int = 0, limit: int = 20
) -> tuple[list[PayoutStructure], int]:
    total = len(db.exec(select(PayoutStructure)).all())
    items = db.exec(select(PayoutStructure).offset(skip).limit(limit)).all()
    return items, total


def get_payout_structure(ps_id: int, db: Session) -> PayoutStructure:
    ps = db.exec(
        select(PayoutStructure).where(PayoutStructure.payout_structure_id == ps_id)
    ).first()
    if ps is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "RESOURCE_NOT_FOUND", "message": f"PayoutStructure {ps_id} not found"},
        )
    return ps


def get_payout_structure_levels(ps_id: int, db: Session) -> list[PayoutStructureLevel]:
    return db.exec(
        select(PayoutStructureLevel)
        .where(PayoutStructureLevel.payout_structure_id == ps_id)
        .order_by(PayoutStructureLevel.position_from)
    ).all()


def create_payout_structure(data: PayoutStructureCreate, db: Session) -> PayoutStructure:
    ps = PayoutStructure(name=data.name)
    db.add(ps)
    db.commit()
    db.refresh(ps)

    for lv in data.levels:
        level = PayoutStructureLevel(
            payout_structure_id=ps.payout_structure_id,
            **lv.model_dump(),
        )
        db.add(level)
    db.commit()
    db.refresh(ps)
    return ps


def update_payout_structure(
    ps_id: int, data: PayoutStructureUpdate, db: Session
) -> PayoutStructure:
    ps = get_payout_structure(ps_id, db)

    if data.name is not None:
        ps.name = data.name

    ps.updated_at = _utcnow()
    db.add(ps)

    # Replace levels if provided
    if data.levels is not None:
        # Delete existing levels
        old_levels = db.exec(
            select(PayoutStructureLevel)
            .where(PayoutStructureLevel.payout_structure_id == ps_id)
        ).all()
        for old in old_levels:
            db.delete(old)

        # B-Q18 fix: flush deletes before inserts to avoid same-tx UNIQUE
        # constraint collision on (payout_structure_id, position_from).
        db.flush()

        # Insert new levels
        for lv in data.levels:
            level = PayoutStructureLevel(
                payout_structure_id=ps_id,
                **lv.model_dump(),
            )
            db.add(level)

    db.commit()
    db.refresh(ps)
    return ps


def delete_payout_structure(ps_id: int, db: Session) -> None:
    ps = get_payout_structure(ps_id, db)

    # TODO: Check if any events reference this structure once payout_structure_id
    # field is added to events table

    # Delete levels first
    levels = db.exec(
        select(PayoutStructureLevel)
        .where(PayoutStructureLevel.payout_structure_id == ps_id)
    ).all()
    for lv in levels:
        db.delete(lv)

    db.delete(ps)
    db.commit()


# ── Flight ↔ PayoutStructure ────────────────────────


def get_flight_payout_structure(
    flight_id: int, db: Session
) -> PayoutStructure | None:
    # TODO: Implement once payout_structure_id field is added to events table
    return None


def apply_payout_structure(
    flight_id: int, ps_id: int, db: Session
) -> None:
    # TODO: Implement once payout_structure_id field is added to events table
    pass
