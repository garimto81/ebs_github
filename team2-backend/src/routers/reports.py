"""SG-007 Reports router — 6 endpoint unified spec.

Endpoints (SG-007 spec):
  GET /api/v1/reports/dashboard           (B-037) — 전체 운영 현황
  GET /api/v1/reports/table-activity      (B-038) — 테이블별 활동 시계열
  GET /api/v1/reports/player-stats        (B-039) — VPIP/PFR/AF/3bet%
  GET /api/v1/reports/hand-distribution   (B-048) — 169 시작패 매트릭스
  GET /api/v1/reports/rfid-health         (B-049) — RFID 리더/카드 상태
  GET /api/v1/reports/operator-activity   (B-050) — 운영자 작업 이력

Legacy (retained for backward compat, to be phased out in SG-007 Phase 2):
  GET /api/v1/reports/{report_type}       — 4-type stub (hands-summary|player-stats|
                                            table-activity|session-log)

Spec: docs/4. Operations/Conductor_Backlog/SG-007-team2-reports-api.md
      docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md §7 Reports

Common query parameters (SG-007 §공통):
  scope (required)       : global | series | event | table
  scope_id (conditional) : required unless scope=global
  from   (required)      : ISO 8601 datetime
  to     (required)      : ISO 8601 datetime
  granularity (required) : minute | hour | day | hand
  format (optional)      : json (default) | csv
  timezone (optional)    : IANA TZ, default Asia/Seoul

RBAC matrix (SG-007 §공통 계약):
  admin    : all 6 endpoints
  operator : table-activity + rfid-health + own operator-activity
  viewer   : dashboard summary + own-related only

team2 session TODO markers:
  [TODO-T2-009] materialized view reports_aggregated + Redis 1h cache
  [TODO-T2-010] RBAC guard per endpoint (see matrix above)
  [TODO-T2-016] CSV streaming response (Accept: text/csv)
  [TODO-T2-017] cursor pagination for time_series / matrix > 5000 rows
"""
from __future__ import annotations

from datetime import datetime
from typing import Any, Literal

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import text
from sqlmodel import Session

from src.app.database import get_db
from src.middleware.rbac import require_role
from src.models.schemas import ApiResponse
from src.models.user import User

router = APIRouter(prefix="/api/v1", tags=["reports"])


# ---------------------------------------------------------------------------
# Shared types
# ---------------------------------------------------------------------------

ScopeLevel = Literal["global", "series", "event", "table"]
Granularity = Literal["minute", "hour", "day", "hand"]
OutputFormat = Literal["json", "csv"]


def _validate_common(
    scope: str,
    scope_id: str | None,
    granularity: str,
    fmt: str,
) -> None:
    if scope not in ("global", "series", "event", "table"):
        raise HTTPException(status_code=400, detail={"code": "INVALID_SCOPE"})
    if scope != "global" and not scope_id:
        raise HTTPException(
            status_code=400,
            detail={"code": "SCOPE_ID_REQUIRED", "message": f"scope={scope} requires scope_id"},
        )
    if granularity not in ("minute", "hour", "day", "hand"):
        raise HTTPException(status_code=400, detail={"code": "INVALID_GRANULARITY"})
    if fmt not in ("json", "csv"):
        raise HTTPException(status_code=400, detail={"code": "INVALID_FORMAT"})


def _envelope(
    report_type: str,
    scope: str,
    scope_id: str | None,
    from_: datetime | str,
    to: datetime | str,
    granularity: str,
    data: Any,
) -> dict:
    """SG-007 §공통 응답 구조."""
    return {
        "report_type": report_type,
        "scope": {"level": scope, "id": scope_id},
        "range": {"from": str(from_), "to": str(to)},
        "granularity": granularity,
        "generated_at": datetime.utcnow().isoformat() + "Z",
        "data": data,
        "pagination": {"cursor": None, "has_more": False},
    }


# ---------------------------------------------------------------------------
# 1. Dashboard (B-037)
# ---------------------------------------------------------------------------


@router.get("/reports/dashboard")
def report_dashboard(
    scope: ScopeLevel = Query(...),
    scope_id: str | None = Query(default=None),
    from_: datetime = Query(..., alias="from"),
    to: datetime = Query(...),
    granularity: Granularity = Query(...),
    format: OutputFormat = Query(default="json"),
    timezone: str = Query(default="Asia/Seoul"),
    _user: User = Depends(require_role("admin", "viewer")),  # [TODO-T2-010] viewer sees summary only
    db: Session = Depends(get_db),
):
    """B-037 — 전체 운영 현황 개요.

    Response `data`:
      {
        "tables": {"active": int, "paused": int, "closed_today": int},
        "players": {"seated": int, "sitting_out": int, "registered_total": int},
        "hands": {"in_progress": int, "completed_today": int, "avg_duration_sec": int},
        "rfid_health": {"readers_online": int, "readers_offline": int, "error_rate_1h": float},
        "operators_online": int,
        "wsop_sync": {"last_success_at": str, "conflicts_pending": int}
      }

    [TODO-T2-009] implement via MV reports_aggregated; cache 30s Redis.
    """
    _validate_common(scope, scope_id, granularity, format)
    raise HTTPException(
        status_code=501,
        detail={"code": "NOT_IMPLEMENTED", "spec": "SG-007 §1 Dashboard", "todo": "T2-009"},
    )


# ---------------------------------------------------------------------------
# 2. Table Activity (B-038)
# ---------------------------------------------------------------------------


@router.get("/reports/table-activity")
def report_table_activity(
    scope: ScopeLevel = Query(...),
    scope_id: str | None = Query(default=None),
    from_: datetime = Query(..., alias="from"),
    to: datetime = Query(...),
    granularity: Granularity = Query(...),
    format: OutputFormat = Query(default="json"),
    timezone: str = Query(default="Asia/Seoul"),
    _user: User = Depends(require_role("admin", "operator")),
    db: Session = Depends(get_db),
):
    """B-038 — 테이블별 활동 지표 (시계열).

    Response `data` (list of buckets):
      [
        {
          "bucket": ISO datetime,
          "table_id": str,
          "hands_completed": int,
          "avg_pot": int,
          "vpip_avg": float,
          "time_per_hand_sec": int,
          "flops_seen_pct": float
        }
      ]

    [TODO-T2-009] MV table_activity_hourly.
    [TODO-T2-017] cursor pagination when > 5000 buckets.
    """
    _validate_common(scope, scope_id, granularity, format)
    raise HTTPException(
        status_code=501,
        detail={"code": "NOT_IMPLEMENTED", "spec": "SG-007 §2 Table Activity", "todo": "T2-009"},
    )


# ---------------------------------------------------------------------------
# 3. Player Stats (B-039)
# ---------------------------------------------------------------------------


@router.get("/reports/player-stats")
def report_player_stats(
    player_id: str = Query(...),
    scope: ScopeLevel = Query(...),
    scope_id: str | None = Query(default=None),
    from_: datetime = Query(..., alias="from"),
    to: datetime = Query(...),
    granularity: Granularity = Query(...),
    format: OutputFormat = Query(default="json"),
    timezone: str = Query(default="Asia/Seoul"),
    _user: User = Depends(require_role("admin", "viewer")),
    db: Session = Depends(get_db),
):
    """B-039 — 플레이어 통계 (VPIP/PFR/AF/3bet%).

    Response `data`:
      {
        "player_id": str,
        "metrics": {"vpip":..,"pfr":..,"af":..,"threebet_pct":..,
                    "wtsd":..,"won_at_showdown":..,"total_hands":..,"net_chips":..},
        "by_position": {"button":{...},"sb":{...}, ...},
        "time_series": [...]
      }

    [TODO-T2-009] on-demand aggregation (no MV; Redis 5m cache).
    """
    _validate_common(scope, scope_id, granularity, format)
    raise HTTPException(
        status_code=501,
        detail={"code": "NOT_IMPLEMENTED", "spec": "SG-007 §3 Player Stats", "todo": "T2-009"},
    )


# ---------------------------------------------------------------------------
# 4. Hand Distribution (B-048)
# ---------------------------------------------------------------------------


@router.get("/reports/hand-distribution")
def report_hand_distribution(
    scope: ScopeLevel = Query(...),
    scope_id: str | None = Query(default=None),
    from_: datetime = Query(..., alias="from"),
    to: datetime = Query(...),
    granularity: Granularity = Query(...),
    format: OutputFormat = Query(default="json"),
    timezone: str = Query(default="Asia/Seoul"),
    showdown_only: bool = Query(default=False),
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """B-048 — 169 Holdem 시작패 매트릭스 (AA~72o) × 빈도·승률.

    Response `data`:
      {
        "matrix": {"AA": {"count": int, "won_pct": float}, ..., "72o": {...}},
        "total_hands": int,
        "showdown_only": bool
      }

    [TODO-T2-009] 1h batch MV hand_distribution_mv.
    """
    _validate_common(scope, scope_id, granularity, format)
    raise HTTPException(
        status_code=501,
        detail={"code": "NOT_IMPLEMENTED", "spec": "SG-007 §4 Hand Distribution", "todo": "T2-009"},
    )


# ---------------------------------------------------------------------------
# 5. RFID Health (B-049)
# ---------------------------------------------------------------------------


@router.get("/reports/rfid-health")
def report_rfid_health(
    scope: ScopeLevel = Query(...),
    scope_id: str | None = Query(default=None),
    from_: datetime = Query(..., alias="from"),
    to: datetime = Query(...),
    granularity: Granularity = Query(...),
    format: OutputFormat = Query(default="json"),
    timezone: str = Query(default="Asia/Seoul"),
    _user: User = Depends(require_role("admin", "operator")),
    db: Session = Depends(get_db),
):
    """B-049 — RFID 리더 헬스 + 카드 상태 + deck 상태.

    Response `data`:
      {
        "readers": [{"reader_id":..,"table_id":..,"status":..,
                     "error_rate_1h":..,"last_error_at":..,"last_error_code":..}],
        "cards": {"registered": int, "missing": int, "damaged": int},
        "decks": [{"deck_id":..,"status":..,"last_verified_at":..}]
      }

    [TODO-T2-009] real-time RFID telemetry + decks joined via SG-006 router.
    """
    _validate_common(scope, scope_id, granularity, format)
    raise HTTPException(
        status_code=501,
        detail={"code": "NOT_IMPLEMENTED", "spec": "SG-007 §5 RFID Health", "todo": "T2-009"},
    )


# ---------------------------------------------------------------------------
# 6. Operator Activity (B-050)
# ---------------------------------------------------------------------------


@router.get("/reports/operator-activity")
def report_operator_activity(
    user_id: str = Query(...),
    scope: ScopeLevel = Query(...),
    scope_id: str | None = Query(default=None),
    from_: datetime = Query(..., alias="from"),
    to: datetime = Query(...),
    granularity: Granularity = Query(...),
    format: OutputFormat = Query(default="json"),
    timezone: str = Query(default="Asia/Seoul"),
    _user: User = Depends(require_role("admin", "operator")),  # operator can only see own
    db: Session = Depends(get_db),
):
    """B-050 — 운영자 작업 이력.

    Response `data`:
      {
        "user_id": str,
        "sessions": [{"login_at":..,"logout_at":..,"duration_sec":..}],
        "actions": {
          "total": int,
          "by_type": {"new_hand":..,"reveal_holecards":..,"undo":..,"settings_change":..}
        },
        "audit_trail_link": "/api/v1/audit?user_id=..."
      }

    [TODO-T2-010] enforce operator → user_id == self.user_id (403 otherwise).
    [TODO-T2-009] join user_sessions + audit_events.
    """
    _validate_common(scope, scope_id, granularity, format)
    raise HTTPException(
        status_code=501,
        detail={"code": "NOT_IMPLEMENTED", "spec": "SG-007 §6 Operator Activity", "todo": "T2-009"},
    )


# ---------------------------------------------------------------------------
# Legacy — /api/v1/reports/{report_type} (SG-007 Phase 2 로 대체 예정)
# ---------------------------------------------------------------------------
# 이 엔드포인트는 기존 테스트/클라이언트 보호용으로 유지. 신규 구현은 위 6개를 사용.

VALID_REPORT_TYPES = {"hands-summary", "player-stats", "table-activity", "session-log"}


@router.get("/reports/{report_type}")
def api_get_report(
    report_type: str,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """Legacy 4-type stub. [TODO-T2-018] deprecate after SG-007 §1-6 rollout."""
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
