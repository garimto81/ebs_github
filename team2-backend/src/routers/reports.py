"""SG-007 Reports router — 6 endpoint unified spec.

Endpoints (SG-007 spec):
  GET /api/v1/reports/dashboard           (B-037) — 전체 운영 현황
  GET /api/v1/reports/table-activity      (B-038) — 테이블별 활동 시계열
  GET /api/v1/reports/player-stats        (B-039) — VPIP/PFR/AF/3bet%
  GET /api/v1/reports/hand-distribution   (B-048) — 169 시작패 매트릭스
  GET /api/v1/reports/rfid-health         (B-049) — RFID 리더/카드 상태
  GET /api/v1/reports/operator-activity   (B-050) — 운영자 작업 이력

Spec: docs/4. Operations/Conductor_Backlog/SG-007-team2-reports-api.md
      docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md §7 Reports

SG-008-b12 결정 (2026-04-20): legacy `/api/v1/reports/{report_type}` 옵션 3 채택
  — Frontend/CC 에서 호출 0 (grep 검증). 삭제 완료. SG-007 6-endpoint 만 유지.

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

2026-04-20: mock-data 실동작 (pre-MV). 실제 DB 연결·MV 쿼리는 [TODO-T2-009] 에서
  replace. Response 형태는 spec 준수 — swap-out 은 data 블록만 교체 가능.

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
from sqlmodel import Session

from src.app.database import get_db
from src.middleware.rbac import require_role
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
        "reportType": report_type,
        "scope": {"level": scope, "id": scope_id},
        "range": {"from": str(from_), "to": str(to)},
        "granularity": granularity,
        "generatedAt": datetime.utcnow().isoformat() + "Z",
        "data": data,
        "pagination": {"cursor": None, "hasMore": False},
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
    _user: User = Depends(require_role("admin", "viewer")),
    db: Session = Depends(get_db),
):
    """B-037 — 전체 운영 현황 개요. mock data pre-MV [TODO-T2-009]."""
    _validate_common(scope, scope_id, granularity, format)
    data = {
        "tables": {"active": 0, "paused": 0, "closedToday": 0},
        "players": {"seated": 0, "sittingOut": 0, "registeredTotal": 0},
        "hands": {"inProgress": 0, "completedToday": 0, "avgDurationSec": 0},
        "rfidHealth": {"readersOnline": 0, "readersOffline": 0, "errorRate1h": 0.0},
        "operatorsOnline": 0,
        "wsopSync": {"lastSuccessAt": None, "conflictsPending": 0},
    }
    return _envelope("dashboard", scope, scope_id, from_, to, granularity, data)


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
    """B-038 — 테이블별 활동 지표 (시계열). mock data pre-MV [TODO-T2-009]."""
    _validate_common(scope, scope_id, granularity, format)
    # mock empty buckets — list form
    data: list[dict] = []
    return _envelope("table-activity", scope, scope_id, from_, to, granularity, data)


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
    """B-039 — 플레이어 통계 (VPIP/PFR/AF/3bet%). mock data pre-aggregation [TODO-T2-009]."""
    _validate_common(scope, scope_id, granularity, format)
    data = {
        "playerId": player_id,
        "metrics": {
            "vpip": 0.0,
            "pfr": 0.0,
            "af": 0.0,
            "threebetPct": 0.0,
            "wtsd": 0.0,
            "wonAtShowdown": 0.0,
            "totalHands": 0,
            "netChips": 0,
        },
        "byPosition": {},
        "timeSeries": [],
    }
    return _envelope("player-stats", scope, scope_id, from_, to, granularity, data)


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
    """B-048 — 169 Holdem 시작패 매트릭스 (AA~72o) × 빈도·승률. mock data [TODO-T2-009]."""
    _validate_common(scope, scope_id, granularity, format)
    data = {
        "matrix": {},
        "totalHands": 0,
        "showdownOnly": showdown_only,
    }
    return _envelope("hand-distribution", scope, scope_id, from_, to, granularity, data)


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
    """B-049 — RFID 리더 헬스 + 카드 상태 + deck 상태. mock data [TODO-T2-009]."""
    _validate_common(scope, scope_id, granularity, format)
    data = {
        "readers": [],
        "cards": {"registered": 0, "missing": 0, "damaged": 0},
        "decks": [],
    }
    return _envelope("rfid-health", scope, scope_id, from_, to, granularity, data)


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
    """B-050 — 운영자 작업 이력. mock data [TODO-T2-009]."""
    _validate_common(scope, scope_id, granularity, format)
    # [TODO-T2-010] enforce operator → user_id == _user.user_id (403 otherwise).
    data = {
        "userId": user_id,
        "sessions": [],
        "actions": {
            "total": 0,
            "byType": {
                "newHand": 0,
                "revealHolecards": 0,
                "undo": 0,
                "settingsChange": 0,
            },
        },
        "auditTrailLink": f"/api/v1/audit-events?user_id={user_id}",
    }
    return _envelope("operator-activity", scope, scope_id, from_, to, granularity, data)


# ---------------------------------------------------------------------------
# SG-008-b12 결정 (2026-04-20): legacy `/api/v1/reports/{report_type}` 옵션 3 삭제
# ---------------------------------------------------------------------------
# Frontend/CC 에서 호출 0 (grep 검증 통과). SG-007 6-endpoint 로 완전 대체.
# 본 엔드포인트는 제거되었다. 재도입 요청 시 SG-008-b12 재오픈.
