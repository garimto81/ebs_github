"""Audit router — audit_logs + audit_events.

SG-008-b10 결정 (2026-04-20): `POST /api/v1/events/{event_id}/undo` 옵션 3 채택 — Phase 1 미지원.
  Undo 는 append-only vs mutable state 설계 철학 결정. Phase 1 에서는 삭제.
  Phase 2+ 재도입 시 SG-008-b10 재오픈 + 옵션 1 (compensating event) 기반 재설계.
"""
import csv
import io
from typing import Optional

from fastapi import APIRouter, Depends, Query
from fastapi.responses import StreamingResponse
from sqlmodel import Session, select

from src.app.database import get_db
from src.middleware.rbac import get_current_user, require_role
from src.models.audit_event import AuditEvent
from src.models.audit_log import AuditLog
from src.models.user import User

router = APIRouter(prefix="/api/v1", tags=["audit"])


# ── Audit Logs (admin actions) ────────────────────────


@router.get("/audit-logs")
def list_audit_logs(
    user_id: Optional[int] = Query(None),
    entity_type: Optional[str] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """List audit_logs with optional filters. Admin only."""
    stmt = select(AuditLog).order_by(AuditLog.created_at.desc())
    count_stmt = select(AuditLog)

    if user_id is not None:
        stmt = stmt.where(AuditLog.user_id == user_id)
        count_stmt = count_stmt.where(AuditLog.user_id == user_id)
    if entity_type is not None:
        stmt = stmt.where(AuditLog.entity_type == entity_type)
        count_stmt = count_stmt.where(AuditLog.entity_type == entity_type)

    total = len(db.exec(count_stmt).all())
    stmt = stmt.offset(skip).limit(limit)
    results = db.exec(stmt).all()

    items = []
    for row in results:
        items.append({
            "id": row.id,
            "user_id": row.user_id,
            "entity_type": row.entity_type,
            "entity_id": row.entity_id,
            "action": row.action,
            "detail": row.detail,
            "ip_address": row.ip_address,
            "created_at": row.created_at,
        })

    return {
        "data": items,
        "meta": {"skip": skip, "limit": limit, "total": total},
    }


@router.get("/audit-logs/download")
def download_audit_logs(
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """Download all audit_logs as CSV."""
    stmt = select(AuditLog).order_by(AuditLog.created_at.desc())
    rows = db.exec(stmt).all()

    def generate():
        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow(["id", "user_id", "entity_type", "entity_id", "action", "detail", "ip_address", "created_at"])
        yield output.getvalue()
        output.seek(0)
        output.truncate(0)

        for row in rows:
            writer.writerow([row.id, row.user_id, row.entity_type, row.entity_id,
                             row.action, row.detail, row.ip_address, row.created_at])
            yield output.getvalue()
            output.seek(0)
            output.truncate(0)

    return StreamingResponse(
        generate(),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=audit_logs.csv"},
    )


# ── Audit Events (game state changes) ────────────────


@router.get("/audit-events")
def list_audit_events(
    table_id: Optional[str] = Query(None),
    correlation_id: Optional[str] = Query(None),
    since: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=2000),
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """List audit_events with optional filters."""
    stmt = select(AuditEvent).where(AuditEvent.seq > since).order_by(AuditEvent.id.asc())

    if table_id is not None:
        stmt = stmt.where(AuditEvent.table_id == table_id)
    if correlation_id is not None:
        stmt = stmt.where(AuditEvent.correlation_id == correlation_id)

    stmt = stmt.limit(limit)
    results = db.exec(stmt).all()

    items = []
    for row in results:
        items.append({
            "id": row.id,
            "table_id": row.table_id,
            "seq": row.seq,
            "event_type": row.event_type,
            "actor_user_id": row.actor_user_id,
            "correlation_id": row.correlation_id,
            "causation_id": row.causation_id,
            "payload": row.payload,
            "inverse_payload": row.inverse_payload,
            "created_at": row.created_at,
        })

    return {
        "data": items,
        "meta": {"since": since, "limit": limit, "count": len(items)},
    }


# ── Undo ──────────────────────────────────────────────
# SG-008-b10 결정 (2026-04-20): 옵션 3 채택 — Phase 1 미지원. 엔드포인트 삭제 완료.
# 서비스 객체 (`app.state.undo_service`) 는 src/main.py 에서 함께 제거하는 것이 원칙이나,
# UndoService 인스턴스 자체는 다른 테스트·내부 컨슈머가 있을 수 있어 유지하고 endpoint 만 제거.
