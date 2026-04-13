from fastapi import APIRouter, Depends
from sqlmodel import Session, func, select

from bo.db.engine import get_session
from bo.db.models import AuditLog, User
from bo.middleware.rbac import require_role
from bo.schemas.audit_log import AuditLogRead
from bo.schemas.common import ApiResponse, PaginationMeta

router = APIRouter(prefix="/audit-logs", tags=["Audit Logs"])


@router.get("", response_model=ApiResponse[list[AuditLogRead]])
def list_audit_logs(
    page: int = 1,
    limit: int = 20,
    entity_type: str | None = None,
    action: str | None = None,
    user_id: int | None = None,
    from_date: str | None = None,
    to_date: str | None = None,
    _: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    stmt = select(AuditLog)
    count_stmt = select(func.count()).select_from(AuditLog)

    if entity_type:
        stmt = stmt.where(AuditLog.entity_type == entity_type)
        count_stmt = count_stmt.where(AuditLog.entity_type == entity_type)
    if action:
        stmt = stmt.where(AuditLog.action == action)
        count_stmt = count_stmt.where(AuditLog.action == action)
    if user_id:
        stmt = stmt.where(AuditLog.user_id == user_id)
        count_stmt = count_stmt.where(AuditLog.user_id == user_id)
    if from_date:
        stmt = stmt.where(AuditLog.created_at >= from_date)
        count_stmt = count_stmt.where(AuditLog.created_at >= from_date)
    if to_date:
        stmt = stmt.where(AuditLog.created_at <= to_date)
        count_stmt = count_stmt.where(AuditLog.created_at <= to_date)

    total = session.exec(count_stmt).one()
    offset = (page - 1) * limit
    results = session.exec(
        stmt.order_by(AuditLog.created_at.desc()).offset(offset).limit(limit)
    ).all()

    return ApiResponse(
        data=results,
        meta=PaginationMeta(page=page, limit=limit, total=total),
    )
