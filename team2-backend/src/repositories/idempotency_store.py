"""Idempotency key persistence — Phase 1: SQLite/SQLModel."""
from datetime import datetime, timezone, timedelta

from sqlmodel import Session, select

from src.app.config import settings
from src.models.audit_event import IdempotencyKey


class IdempotencyStore:
    """CRUD for idempotency_keys table."""

    @staticmethod
    def get_or_none(user_id: str, key: str, db: Session) -> IdempotencyKey | None:
        """Lookup by (user_id, key). Returns None if not found."""
        stmt = select(IdempotencyKey).where(
            IdempotencyKey.user_id == user_id,
            IdempotencyKey.key == key,
        )
        return db.exec(stmt).first()

    @staticmethod
    def save(
        user_id: str,
        key: str,
        method: str,
        path: str,
        request_hash: str,
        status_code: int,
        response_body: str | None,
        db: Session,
    ) -> IdempotencyKey:
        """Persist a new idempotency record."""
        now = datetime.now(timezone.utc)
        expires = now + timedelta(seconds=settings.idempotency_ttl_s)
        record = IdempotencyKey(
            key=key,
            user_id=user_id,
            method=method,
            path=path,
            request_hash=request_hash,
            status_code=status_code,
            response_body=response_body,
            created_at=now.isoformat(),
            expires_at=expires.isoformat(),
        )
        db.add(record)
        db.commit()
        db.refresh(record)
        return record

    @staticmethod
    def cleanup_expired(db: Session) -> int:
        """Delete rows where expires_at < now(). Returns count deleted."""
        now = datetime.now(timezone.utc).isoformat()
        stmt = select(IdempotencyKey).where(IdempotencyKey.expires_at < now)
        expired = db.exec(stmt).all()
        count = len(expired)
        for row in expired:
            db.delete(row)
        if count:
            db.commit()
        return count
