"""AuditEvent & IdempotencyKey models — DATA-04 §5.1~5.2."""
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import UniqueConstraint
from sqlmodel import Field, SQLModel


def utcnow() -> str:
    return datetime.now(timezone.utc).isoformat()


class IdempotencyKey(SQLModel, table=True):
    __tablename__ = "idempotency_keys"

    key: str = Field(primary_key=True, max_length=128)
    user_id: str = Field(nullable=False, max_length=64)
    method: str = Field(nullable=False, max_length=16)
    path: str = Field(nullable=False, max_length=255)
    request_hash: str = Field(nullable=False, max_length=64)
    status_code: int = Field(nullable=False)
    response_body: Optional[str] = None
    created_at: str = Field(default_factory=utcnow)
    expires_at: str = Field(nullable=False)

    __table_args__ = (
        UniqueConstraint("user_id", "key"),
    )


class AuditEvent(SQLModel, table=True):
    __tablename__ = "audit_events"

    id: Optional[int] = Field(default=None, primary_key=True)
    table_id: str = Field(nullable=False, max_length=64)
    seq: int = Field(nullable=False)
    event_type: str = Field(nullable=False, max_length=64)
    actor_user_id: Optional[str] = None
    correlation_id: Optional[str] = None
    causation_id: Optional[str] = None
    idempotency_key: Optional[str] = None
    payload: str = Field(nullable=False)           # TEXT (JSON)
    inverse_payload: Optional[str] = None          # TEXT (JSON), Undo/Revive
    created_at: str = Field(default_factory=utcnow)

    __table_args__ = (
        UniqueConstraint("table_id", "seq"),
    )
