"""Skin CRUD service."""
from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlmodel import Session, select

from src.models.schemas import SkinCreate, SkinUpdate
from src.models.skin import Skin


def _utcnow() -> str:
    return datetime.now(timezone.utc).isoformat()


def list_skins(db: Session, skip: int = 0, limit: int = 20) -> tuple[list[Skin], int]:
    total = len(db.exec(select(Skin)).all())
    items = db.exec(select(Skin).offset(skip).limit(limit)).all()
    return items, total


def get_skin(skin_id: int, db: Session) -> Skin:
    s = db.exec(select(Skin).where(Skin.skin_id == skin_id)).first()
    if s is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "RESOURCE_NOT_FOUND", "message": f"Skin {skin_id} not found"},
        )
    return s


def create_skin(data: SkinCreate, db: Session) -> Skin:
    # Check unique name
    existing = db.exec(select(Skin).where(Skin.name == data.name)).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"code": "DUPLICATE", "message": f"Skin with name '{data.name}' already exists"},
        )
    s = Skin(**data.model_dump())
    db.add(s)
    db.commit()
    db.refresh(s)
    return s


def update_skin(skin_id: int, data: SkinUpdate, db: Session) -> Skin:
    s = get_skin(skin_id, db)
    updates = data.model_dump(exclude_unset=True)
    for k, v in updates.items():
        setattr(s, k, v)
    s.updated_at = _utcnow()
    db.add(s)
    db.commit()
    db.refresh(s)
    return s


def delete_skin(skin_id: int, db: Session) -> None:
    s = get_skin(skin_id, db)
    if s.is_default:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"code": "CANNOT_DELETE_DEFAULT", "message": "Cannot delete the default skin"},
        )
    db.delete(s)
    db.commit()


def activate_skin(skin_id: int, db: Session) -> Skin:
    s = get_skin(skin_id, db)
    # Unset all other defaults
    all_skins = db.exec(select(Skin).where(Skin.is_default == True)).all()  # noqa: E712
    for other in all_skins:
        other.is_default = False
        other.updated_at = _utcnow()
        db.add(other)
    # Set this one as default
    s.is_default = True
    s.updated_at = _utcnow()
    db.add(s)
    db.commit()
    db.refresh(s)
    return s


def get_active_skin(db: Session) -> Skin | None:
    return db.exec(select(Skin).where(Skin.is_default == True)).first()  # noqa: E712
