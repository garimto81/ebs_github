from sqlmodel import SQLModel, Field

from .base import utcnow


class UserSession(SQLModel, table=True):
    __tablename__ = "user_sessions"
    id: int | None = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="users.user_id")
    last_series_id: int | None = None
    last_event_id: int | None = None
    last_flight_id: int | None = None
    last_table_id: int | None = None
    last_screen: str | None = None
    access_token: str | None = None
    token_expires_at: str | None = None
    ip_address: str | None = None
    is_active: bool = Field(default=True)
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)
