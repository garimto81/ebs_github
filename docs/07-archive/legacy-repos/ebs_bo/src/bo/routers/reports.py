from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session

from bo.db.engine import get_session
from bo.db.models import User
from bo.middleware.rbac import require_role
from bo.schemas.common import ApiResponse
from bo.schemas.report import ReportData
from bo.services import report_service

router = APIRouter(prefix="/reports", tags=["Reports"])

VALID_TYPES = {"hands-summary", "player-stats", "table-activity", "session-log"}


@router.get("/{report_type}", response_model=ApiResponse[ReportData])
def get_report(
    report_type: str,
    table_id: int | None = None,
    event_id: int | None = None,
    player_id: int | None = None,
    flight_id: int | None = None,
    user_id: int | None = None,
    from_date: str | None = None,
    to_date: str | None = None,
    _: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    if report_type not in VALID_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid report type. Valid: {', '.join(sorted(VALID_TYPES))}",
        )

    if report_type == "hands-summary":
        result = report_service.hands_summary(session, table_id=table_id, event_id=event_id)
    elif report_type == "player-stats":
        result = report_service.player_stats(session, player_id=player_id, event_id=event_id)
    elif report_type == "table-activity":
        result = report_service.table_activity(session, flight_id=flight_id, from_dt=from_date, to_dt=to_date)
    elif report_type == "session-log":
        result = report_service.session_log(session, user_id=user_id, from_dt=from_date, to_dt=to_date)
    else:
        result = {"report_type": report_type, "generated_at": "", "data": []}

    return ApiResponse(
        data=ReportData(
            report_type=result["report_type"],
            generated_at=result["generated_at"],
            data=result["data"],
        )
    )
