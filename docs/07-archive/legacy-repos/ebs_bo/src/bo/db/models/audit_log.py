from sqlmodel import SQLModel, Field

from .base import utcnow


class AuditLog(SQLModel, table=True):
    __tablename__ = "audit_logs"
    id: int | None = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="users.user_id")
    entity_type: str = Field(nullable=False)
    entity_id: int | None = None
    action: str = Field(nullable=False)
    detail: str | None = None
    ip_address: str | None = None
    created_at: str = Field(default_factory=utcnow)
