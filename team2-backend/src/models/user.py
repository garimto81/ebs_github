"""User & UserSession models — DATA-04 §4 정본."""
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import UniqueConstraint
from sqlmodel import Field, SQLModel


def utcnow() -> str:
    return datetime.now(timezone.utc).isoformat()


class User(SQLModel, table=True):
    __tablename__ = "users"

    user_id: Optional[int] = Field(default=None, primary_key=True)
    email: str = Field(nullable=False, unique=True)
    password_hash: str = Field(nullable=False)
    display_name: str = Field(nullable=False)
    role: str = Field(default="viewer")  # admin|operator|viewer
    is_active: bool = Field(default=True)
    totp_secret: Optional[str] = None
    totp_enabled: bool = Field(default=False)
    last_login_at: Optional[str] = None
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)

    # Login failure tracking (BS-01: 5 consecutive failures → 30min lock)
    failed_login_count: int = Field(default=0)
    locked_until: Optional[str] = None


class UserSession(SQLModel, table=True):
    __tablename__ = "user_sessions"
    # BS-01 §A-25 다중 세션 지원 (M1 Item 3, PR 3, 2026-04-28):
    # 기존 user_id UNIQUE → (user_id, device_id) composite UNIQUE.
    __table_args__ = (
        UniqueConstraint("user_id", "device_id", name="uq_user_sessions_user_device"),
    )

    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="users.user_id")
    device_id: str = Field(default="default")
    last_series_id: Optional[int] = None
    last_event_id: Optional[int] = None
    last_flight_id: Optional[int] = None
    last_table_id: Optional[int] = None
    last_screen: Optional[str] = None
    access_token: Optional[str] = None
    refresh_token: Optional[str] = None
    token_expires_at: Optional[str] = None
    updated_at: str = Field(default_factory=utcnow)
