"""Sync router — WSOP LIVE integration endpoints."""
from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlmodel import Session

from src.app.config import settings as app_settings
from src.app.database import get_db
from src.middleware.rbac import get_current_user, require_role
from src.models.user import User

router = APIRouter(prefix="/api/v1/sync", tags=["sync"])


def _get_sync_service(request: Request):
    """Extract WsopSyncService from app.state."""
    return request.app.state.wsop_sync


# SG-008-b6/b7 — env guard for mock seed/reset (B 일괄 권고 채택 2026-04-27)
# auth_profile 이 dev/staging 일 때만 허용. prod/live 에서는 403 (운영 자산 보호).
_ENV_GUARD_ALLOWED = ("dev", "staging")


def _require_dev_or_staging(user: User = Depends(require_role("admin"))) -> User:
    """env guard — only allow in dev/staging, reject in prod/live (SG-008-b6/b7)."""
    if app_settings.auth_profile not in _ENV_GUARD_ALLOWED:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="ENV_GUARD_PROD_FORBIDDEN",
        )
    return user


@router.get("/status")
async def sync_status(
    user: User = Depends(get_current_user),
    sync_service=Depends(_get_sync_service),
):
    """Return sync status. SG-008-b8: Public + Admin detail bifurcation.

    All authenticated users see base sync status. Admin role receives
    additional `scope` marker for client-side detail rendering.
    """
    base = await sync_service.get_sync_status()
    return {
        "data": base,
        "scope": "admin" if user.role == "admin" else "public",
    }


@router.get("/wsop-live/status")
async def sync_wsop_live_status(
    _user: User = Depends(get_current_user),
    sync_service=Depends(_get_sync_service),
):
    """SSOT Backend_HTTP.md L966 — canonical WSOP LIVE sync status."""
    return {"data": await sync_service.get_sync_status()}


@router.post("/wsop-live")
async def sync_wsop_live_trigger(
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
    sync_service=Depends(_get_sync_service),
):
    """SSOT Backend_HTTP.md L965 — canonical WSOP LIVE sync trigger."""
    result = await sync_service.poll_series(db)
    return {
        "data": {
            "source": result.source,
            "created": result.created,
            "updated": result.updated,
            "skipped": result.skipped,
            "errors": result.errors,
        }
    }


@router.get("/conflicts")
async def sync_conflicts(
    _user: User = Depends(require_role("admin")),
    sync_service=Depends(_get_sync_service),
):
    """SSOT Backend_HTTP.md L967 — sync conflict report.

    Phase 1 returns empty conflicts list; real conflict detection lands with
    the wsop-live conflict registry (Backlog B-066).
    """
    return {"data": {"conflicts": []}}


@router.post("/trigger/{source}")
async def trigger_sync(
    source: str,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
    sync_service=Depends(_get_sync_service),
):
    """Deprecated — prefer POST /sync/wsop-live."""
    if source == "wsop_live":
        result = await sync_service.poll_series(db)
        return {
            "data": {
                "source": result.source,
                "created": result.created,
                "updated": result.updated,
                "skipped": result.skipped,
                "errors": result.errors,
            }
        }
    raise HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail=f"Unknown source: {source}",
    )


@router.post("/mock/seed")
async def seed_mock(
    _user: User = Depends(_require_dev_or_staging),
    db: Session = Depends(get_db),
    sync_service=Depends(_get_sync_service),
):
    """Seed mock data — SG-008-b6: dev/staging only (env guard).

    Mock data: Competition 1, Series 3, Events 30, Flights 60, Players 100.
    Admin only + env guard. prod/live → 403 ENV_GUARD_PROD_FORBIDDEN.
    """
    counts = await sync_service.seed_mock_data(db)
    return {"data": counts}


@router.delete("/mock/reset")
async def reset_mock(
    _user: User = Depends(_require_dev_or_staging),
    db: Session = Depends(get_db),
    sync_service=Depends(_get_sync_service),
):
    """Reset mock/api-sourced data — SG-008-b7: dev/staging only (env guard).

    Admin only + env guard. prod/live → 403 ENV_GUARD_PROD_FORBIDDEN.
    """
    result = await sync_service.reset_mock_data(db)
    return {"data": result}
