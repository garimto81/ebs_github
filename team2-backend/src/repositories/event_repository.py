"""Append-only audit event repository — DATA-04 §5.2 + CCR-015."""
import json
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import text
from sqlalchemy.exc import IntegrityError
from sqlmodel import Session

from src.models.audit_event import AuditEvent


@dataclass
class FetchResult:
    """Result from fetch_since — events + pagination metadata."""
    events: list[AuditEvent]
    last_seq: int
    has_more: bool


class AuditEventRepository:
    """Append-only event store. No update() or delete() methods — by design."""

    def append(
        self,
        table_id: str,
        event_type: str,
        payload: dict | str,
        *,
        inverse_payload: dict | str | None = None,
        correlation_id: Optional[str] = None,
        causation_id: Optional[str] = None,
        idempotency_key: Optional[str] = None,
        actor_user_id: Optional[str] = None,
        db: Session,
    ) -> AuditEvent:
        """Append a single event. seq is computed with retry on UNIQUE conflict."""
        # Serialize dicts to JSON strings
        if isinstance(payload, dict):
            payload = json.dumps(payload)
        if isinstance(inverse_payload, dict):
            inverse_payload = json.dumps(inverse_payload)

        for attempt in range(3):
            try:
                # Compute next seq within transaction
                result = db.execute(
                    text(
                        "SELECT COALESCE(MAX(seq), 0) + 1 FROM audit_events "
                        "WHERE table_id = :tid"
                    ),
                    {"tid": table_id},
                )
                next_seq = result.scalar()

                now = datetime.now(timezone.utc).isoformat()

                event = AuditEvent(
                    table_id=table_id,
                    seq=next_seq,
                    event_type=event_type,
                    actor_user_id=actor_user_id,
                    correlation_id=correlation_id,
                    causation_id=causation_id,
                    idempotency_key=idempotency_key,
                    payload=payload,
                    inverse_payload=inverse_payload,
                    created_at=now,
                )
                db.add(event)
                db.commit()
                db.refresh(event)
                return event
            except IntegrityError:
                db.rollback()
                if attempt == 2:
                    raise
                continue
        # Unreachable, but satisfies type checker
        raise RuntimeError("Failed to append event after retries")

    def fetch_since(
        self,
        table_id: str,
        since_seq: int,
        limit: int = 500,
        *,
        db: Session,
    ) -> FetchResult:
        """Fetch events with seq > since_seq, ordered by seq ASC."""
        limit = min(limit, 2000)

        result = db.execute(
            text(
                "SELECT * FROM audit_events "
                "WHERE table_id = :tid AND seq > :since "
                "ORDER BY seq ASC "
                "LIMIT :lim"
            ),
            {"tid": table_id, "since": since_seq, "lim": limit + 1},
        )
        rows = result.fetchall()

        has_more = len(rows) > limit
        if has_more:
            rows = rows[:limit]

        events = []
        for row in rows:
            # Map row to AuditEvent — row is a Row object with column access
            evt = AuditEvent(
                id=row.id,
                table_id=row.table_id,
                seq=row.seq,
                event_type=row.event_type,
                actor_user_id=row.actor_user_id,
                correlation_id=row.correlation_id,
                causation_id=row.causation_id,
                idempotency_key=row.idempotency_key,
                payload=row.payload,
                inverse_payload=row.inverse_payload,
                created_at=row.created_at,
            )
            events.append(evt)

        last_seq = events[-1].seq if events else since_seq

        return FetchResult(events=events, last_seq=last_seq, has_more=has_more)

    @staticmethod
    def get_can_undo(event: AuditEvent) -> bool:
        """Phase 1 simplified: inverse_payload exists → can undo."""
        return event.inverse_payload is not None


# Module-level singleton
event_repository = AuditEventRepository()
