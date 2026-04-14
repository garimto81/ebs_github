"""AuditLog model — DATA-04 §4 audit_logs."""
from datetime import datetime, timezone
from typing import Optional

from sqlmodel import Field, SQLModel


def utcnow() -> str:
    return datetime.now(timezone.utc).isoformat()


class AuditLog(SQLModel, table=True):
    __tablename__ = "audit_logs"

    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="users.user_id")
    entity_type: str = Field(nullable=False, max_length=64)
    entity_id: Optional[int] = None
    action: str = Field(nullable=False, max_length=64)
    detail: Optional[str] = None  # TEXT (JSON)
    ip_address: Optional[str] = None
    created_at: str = Field(default_factory=utcnow)
