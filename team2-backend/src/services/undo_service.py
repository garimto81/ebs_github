"""Undo Service — IMPL-10 §7.2 Undo/Revive rules."""
import json
from typing import Optional

from fastapi import HTTPException, status
from sqlmodel import Session

from src.models.audit_event import AuditEvent
from src.models.audit_log import AuditLog
from src.repositories.event_repository import AuditEventRepository


class UndoNotAllowedError(HTTPException):
    def __init__(self, detail: str = "UNDO_NOT_ALLOWED"):
        super().__init__(status_code=status.HTTP_400_BAD_REQUEST, detail=detail)


class UndoService:
    """Undo via inverse event append. Never deletes original."""

    def __init__(self, event_repo: AuditEventRepository):
        self.repo = event_repo

    def undo_event(
        self,
        event_id: int,
        actor_user_id: int,
        db: Session,
    ) -> AuditEvent:
        """Undo an event by appending its inverse.

        Dual-write: audit_events (state change) + audit_logs (admin action).
        """
        original = db.get(AuditEvent, event_id)
        if not original:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="EVENT_NOT_FOUND",
            )

        if not original.inverse_payload:
            raise UndoNotAllowedError()

        # Parse inverse payload
        inverse_payload = original.inverse_payload
        if isinstance(inverse_payload, str):
            try:
                inverse_payload_dict = json.loads(inverse_payload)
            except json.JSONDecodeError:
                inverse_payload_dict = inverse_payload
        else:
            inverse_payload_dict = inverse_payload

        # Parse original payload for double-inverse
        original_payload = original.payload
        if isinstance(original_payload, str):
            try:
                original_payload_dict = json.loads(original_payload)
            except json.JSONDecodeError:
                original_payload_dict = original_payload
        else:
            original_payload_dict = original_payload

        # 1. Append inverse event to audit_events
        inverse = self.repo.append(
            table_id=original.table_id,
            event_type=f"undo_{original.event_type}",
            payload=inverse_payload_dict,
            inverse_payload=original_payload_dict,  # double-inverse for re-undo
            correlation_id=original.correlation_id,
            causation_id=str(original.id),
            actor_user_id=str(actor_user_id),
            db=db,
        )

        # 2. Dual-write to audit_logs (admin action record)
        audit_log = AuditLog(
            user_id=actor_user_id,
            entity_type="audit_event",
            entity_id=original.id,
            action="undo",
            detail=json.dumps({
                "original_event_type": original.event_type,
                "inverse_event_id": inverse.id,
            }),
        )
        db.add(audit_log)
        db.commit()

        return inverse
