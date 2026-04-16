"""Reports router — API-01 §reports."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlmodel import Session

from src.app.database import get_db
from src.middleware.rbac import require_role
from src.models.schemas import ApiResponse
from src.models.user import User

router = APIRouter(prefix="/api/v1", tags=["reports"])

VALID_REPORT_TYPES = {"hands-summary", "player-stats", "table-activity", "session-log"}


@router.get("/reports/{report_type}")
def api_get_report(
    report_type: str,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    if report_type not in VALID_REPORT_TYPES:
        raise HTTPException(
            status_code=400,
            detail={
                "code": "INVALID_REPORT_TYPE",
                "message": f"Valid types: {', '.join(sorted(VALID_REPORT_TYPES))}",
            },
        )

    if report_type == "hands-summary":
        result = db.execute(
            text(
                "SELECT COUNT(*) as total_hands, "
                "COALESCE(SUM(pot_total),0) as total_pot, "
                "COALESCE(AVG(duration_sec),0) as avg_duration "
                "FROM hands"
            )
        ).first()
        data = (
            {"total_hands": result[0], "total_pot": result[1], "avg_duration_sec": round(result[2], 1)}
            if result
            else {}
        )
    elif report_type == "player-stats":
        result = db.execute(text("SELECT COUNT(*) as total_players FROM players")).first()
        data = {"total_players": result[0]} if result else {}
    elif report_type == "table-activity":
        result = db.execute(
            text(
                "SELECT COUNT(*) as total_tables, "
                "SUM(CASE WHEN status='live' THEN 1 ELSE 0 END) as active_tables "
                "FROM tables"
            )
        ).first()
        data = {"total_tables": result[0], "active_tables": result[1] or 0} if result else {}
    elif report_type == "session-log":
        result = db.execute(text("SELECT COUNT(*) as total_sessions FROM user_sessions")).first()
        data = {"total_sessions": result[0]} if result else {}
    else:
        data = {}

    return ApiResponse(data={"report_type": report_type, **data})
