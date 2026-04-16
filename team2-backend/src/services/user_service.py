"""User CRUD service — API-01 §5.11."""
from __future__ import annotations

from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlmodel import Session, select

from src.models.schemas import UserCreate, UserUpdate
from src.models.user import User
from src.security.password import hash_password


def _utcnow() -> str:
    return datetime.now(timezone.utc).isoformat()


def list_users(db: Session, skip: int = 0, limit: int = 20) -> tuple[list[User], int]:
    total = len(db.exec(select(User)).all())
    items = db.exec(select(User).offset(skip).limit(limit)).all()
    return items, total


def get_user(user_id: int, db: Session) -> User:
    u = db.exec(select(User).where(User.user_id == user_id)).first()
    if u is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "RESOURCE_NOT_FOUND", "message": f"User {user_id} not found"},
        )
    return u


def create_user(data: UserCreate, db: Session) -> User:
    # Check duplicate email
    existing = db.exec(select(User).where(User.email == data.email)).first()
    if existing is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"code": "DUPLICATE_EMAIL", "message": f"Email {data.email} already exists"},
        )
    now = _utcnow()
    u = User(
        email=data.email,
        password_hash=hash_password(data.password),
        display_name=data.display_name,
        role=data.role,
        created_at=now,
        updated_at=now,
    )
    db.add(u)
    db.commit()
    db.refresh(u)
    return u


def update_user(user_id: int, data: UserUpdate, db: Session) -> User:
    u = get_user(user_id, db)
    updates = data.model_dump(exclude_unset=True)
    for k, v in updates.items():
        setattr(u, k, v)
    u.updated_at = _utcnow()
    db.add(u)
    db.commit()
    db.refresh(u)
    return u


def delete_user(user_id: int, db: Session) -> None:
    """Soft-delete: set is_active=False."""
    u = get_user(user_id, db)
    u.is_active = False
    u.updated_at = _utcnow()
    db.add(u)
    db.commit()
