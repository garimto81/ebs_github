from sqlmodel import SQLModel, Field

from .base import utcnow


class User(SQLModel, table=True):
    __tablename__ = "users"
    user_id: int | None = Field(default=None, primary_key=True)
    email: str = Field(nullable=False, unique=True)
    password_hash: str = Field(nullable=False)
    display_name: str = Field(nullable=False)
    role: str = Field(default="viewer")  # admin|operator|viewer
    is_active: bool = Field(default=True)
    totp_secret: str | None = None
    totp_enabled: bool = Field(default=False)
    last_login_at: str | None = None
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)
