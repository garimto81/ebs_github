"""Competition CRUD service — API-01 §5.3."""
from __future__ import annotations

from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlmodel import Session, select

from src.models.competition import Competition, Series
from src.models.schemas import CompetitionCreate, CompetitionUpdate


def _utcnow() -> str:
    return datetime.now(timezone.utc).isoformat()


def list_competitions(db: Session, skip: int = 0, limit: int = 20) -> tuple[list[Competition], int]:
    total = len(db.exec(select(Competition)).all())
    items = db.exec(select(Competition).offset(skip).limit(limit)).all()
    return items, total


def get_competition(competition_id: int, db: Session) -> Competition:
    c = db.exec(select(Competition).where(Competition.competition_id == competition_id)).first()
    if c is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "RESOURCE_NOT_FOUND", "message": f"Competition {competition_id} not found"},
        )
    return c


def create_competition(data: CompetitionCreate, db: Session) -> Competition:
    c = Competition(**data.model_dump())
    db.add(c)
    db.commit()
    db.refresh(c)
    return c


def update_competition(competition_id: int, data: CompetitionUpdate, db: Session) -> Competition:
    c = get_competition(competition_id, db)
    updates = data.model_dump(exclude_unset=True)
    for k, v in updates.items():
        setattr(c, k, v)
    c.updated_at = _utcnow()
    db.add(c)
    db.commit()
    db.refresh(c)
    return c


def delete_competition(competition_id: int, db: Session) -> None:
    c = get_competition(competition_id, db)
    # Check for child series
    children = db.exec(select(Series).where(Series.competition_id == competition_id)).all()
    if children:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"code": "HAS_CHILDREN", "message": f"Competition {competition_id} has {len(children)} series"},
        )
    db.delete(c)
    db.commit()
