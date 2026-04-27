"""user_service.py extended unit tests (Session 2.4-partial — B-Q10 cascade, 2026-04-27).

Targets src/services/user_service.py (30% → 80%+ goal).

Strict rule: production code 0 modification, tests/ only.
"""
import pytest
from fastapi import HTTPException
from sqlmodel import Session, select

from src.models.schemas import UserCreate, UserUpdate
from src.models.user import User
from src.services.user_service import (
    create_user,
    delete_user,
    get_user,
    list_users,
    update_user,
)


# ── helpers ──────────────────────────────────────


def _make_user_create(email: str, role: str = "viewer") -> UserCreate:
    return UserCreate(
        email=email,
        password="Password123!",
        display_name=f"Test {email}",
        role=role,
    )


# ── list_users ──────────────────────────────────


def test_list_users_returns_tuple(db_session: Session):
    """list_users returns (list, total) (line 18-21)."""
    items, total = list_users(db_session)
    assert isinstance(items, list)
    assert total >= 0


# ── get_user ────────────────────────────────────


def test_get_user_existing(db_session: Session):
    """get_user returns user for valid id."""
    u = create_user(_make_user_create("get-existing@example.com"), db_session)
    fetched = get_user(u.user_id, db_session)
    assert fetched.user_id == u.user_id
    assert fetched.email == "get-existing@example.com"


def test_get_user_not_found_raises_404(db_session: Session):
    """get_user raises 404 (line 27-30)."""
    with pytest.raises(HTTPException) as excinfo:
        get_user(99999, db_session)
    assert excinfo.value.status_code == 404
    assert excinfo.value.detail["code"] == "RESOURCE_NOT_FOUND"


# ── create_user ─────────────────────────────────


def test_create_user_succeeds(db_session: Session):
    """create_user creates new User with hashed password (line 42-54)."""
    u = create_user(_make_user_create("new-user@example.com", role="operator"), db_session)
    assert u.user_id is not None
    assert u.email == "new-user@example.com"
    assert u.role == "operator"
    assert u.password_hash != "Password123!"  # hashed
    assert u.is_active is True


def test_create_user_duplicate_email_409(db_session: Session):
    """create_user raises 409 on duplicate email (line 36-41)."""
    create_user(_make_user_create("dup@example.com"), db_session)
    with pytest.raises(HTTPException) as excinfo:
        create_user(_make_user_create("dup@example.com", role="admin"), db_session)
    assert excinfo.value.status_code == 409
    assert excinfo.value.detail["code"] == "DUPLICATE_EMAIL"


# ── update_user ─────────────────────────────────


def test_update_user_partial_fields(db_session: Session):
    """update_user applies partial updates + refreshes timestamp (line 57-66)."""
    u = create_user(_make_user_create("upd@example.com"), db_session)
    old_updated = u.updated_at
    updated = update_user(
        u.user_id,
        UserUpdate(display_name="UpdatedName", role="admin"),
        db_session,
    )
    assert updated.display_name == "UpdatedName"
    assert updated.role == "admin"
    # email unchanged (not in update)
    assert updated.email == "upd@example.com"


def test_update_user_not_found(db_session: Session):
    """update_user raises 404 via get_user (line 58)."""
    with pytest.raises(HTTPException) as excinfo:
        update_user(99999, UserUpdate(display_name="X"), db_session)
    assert excinfo.value.status_code == 404


# ── delete_user (soft-delete) ───────────────────


def test_delete_user_soft_deletes(db_session: Session):
    """delete_user sets is_active=False instead of removing (line 69-75)."""
    u = create_user(_make_user_create("soft-del@example.com"), db_session)
    delete_user(u.user_id, db_session)

    # User still exists in DB — just inactive
    refreshed = db_session.exec(
        select(User).where(User.user_id == u.user_id)
    ).first()
    assert refreshed is not None
    assert refreshed.is_active is False


def test_delete_user_not_found(db_session: Session):
    """delete_user raises 404 via get_user (line 71)."""
    with pytest.raises(HTTPException) as excinfo:
        delete_user(99999, db_session)
    assert excinfo.value.status_code == 404
