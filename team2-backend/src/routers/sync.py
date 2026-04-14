"""Sync router — WSOP LIVE integration endpoints."""
from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlmodel import Session

from src.app.database import get_db
from src.middleware.rbac import get_current_user, require_role
from src.models.user import User

router = APIRouter(prefix="/api/v1/sync", tags=["sync"])


def _get_sync_service(request: Request):
    """Extract WsopSyncService from app.state."""
    return request.app.state.wsop_sync


@router.get("/status")
async def sync_status(
    _user: User = Depends(get_current_user),
    sync_service=Depends(_get_sync_service),
):
    """Return sync status for each source."""
    return {"data": await sync_service.get_sync_status()}


@router.post("/trigger/{source}")
async def trigger_sync(
    source: str,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
    sync_service=Depends(_get_sync_service),
):
    """Manually trigger sync for a source."""
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
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
    sync_service=Depends(_get_sync_service),
):
    """Seed mock data (Competition 1, Series 3, Events 30, Flights 60, Players 100)."""
    counts = await sync_service.seed_mock_data(db)
    return {"data": counts}


@router.delete("/mock/reset")
async def reset_mock(
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
    sync_service=Depends(_get_sync_service),
):
    """Reset all mock/api-sourced data."""
    result = await sync_service.reset_mock_data(db)
    return {"data": result}
