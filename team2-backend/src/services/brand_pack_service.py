"""BrandPack CRUD service (Cycle 17).

Pattern: src/services/skin_service.py 와 동일.
"""
from __future__ import annotations

from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlmodel import Session, select

from src.models.brand_pack import BrandPack
from src.models.schemas import BrandPackCreate, BrandPackUpdate


def _utcnow() -> str:
    return datetime.now(timezone.utc).isoformat()


def list_brand_packs(
    db: Session, skip: int = 0, limit: int = 20
) -> tuple[list[BrandPack], int]:
    total = len(db.exec(select(BrandPack)).all())
    items = db.exec(select(BrandPack).offset(skip).limit(limit)).all()
    return items, total


def get_brand_pack(brand_pack_id: int, db: Session) -> BrandPack:
    bp = db.exec(
        select(BrandPack).where(BrandPack.brand_pack_id == brand_pack_id)
    ).first()
    if bp is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={
                "code": "RESOURCE_NOT_FOUND",
                "message": f"BrandPack {brand_pack_id} not found",
            },
        )
    return bp


def create_brand_pack(data: BrandPackCreate, db: Session) -> BrandPack:
    existing = db.exec(select(BrandPack).where(BrandPack.name == data.name)).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={
                "code": "DUPLICATE",
                "message": f"BrandPack with name '{data.name}' already exists",
            },
        )
    bp = BrandPack(**data.model_dump())
    db.add(bp)
    db.commit()
    db.refresh(bp)
    return bp


def update_brand_pack(
    brand_pack_id: int, data: BrandPackUpdate, db: Session
) -> BrandPack:
    bp = get_brand_pack(brand_pack_id, db)
    updates = data.model_dump(exclude_unset=True)
    for k, v in updates.items():
        setattr(bp, k, v)
    bp.updated_at = _utcnow()
    db.add(bp)
    db.commit()
    db.refresh(bp)
    return bp


def delete_brand_pack(brand_pack_id: int, db: Session) -> None:
    bp = get_brand_pack(brand_pack_id, db)
    if bp.is_default:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={
                "code": "CANNOT_DELETE_DEFAULT",
                "message": "Cannot delete the default brand pack",
            },
        )
    db.delete(bp)
    db.commit()


def activate_brand_pack(brand_pack_id: int, db: Session) -> BrandPack:
    """Set this brand pack as default (and unset all others)."""
    bp = get_brand_pack(brand_pack_id, db)
    all_defaults = db.exec(
        select(BrandPack).where(BrandPack.is_default == True)  # noqa: E712
    ).all()
    for other in all_defaults:
        other.is_default = False
        other.updated_at = _utcnow()
        db.add(other)
    bp.is_default = True
    bp.updated_at = _utcnow()
    db.add(bp)
    db.commit()
    db.refresh(bp)
    return bp


def get_active_brand_pack(db: Session) -> BrandPack | None:
    return db.exec(
        select(BrandPack).where(BrandPack.is_default == True)  # noqa: E712
    ).first()
