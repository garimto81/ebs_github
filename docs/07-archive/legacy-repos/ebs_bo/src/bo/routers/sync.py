from fastapi import APIRouter, Depends

from bo.db.models import User
from bo.middleware.rbac import require_role
from bo.schemas.common import ApiResponse
from bo.schemas.sync import SyncStatusResponse, SyncTriggerResponse
from bo.services import sync_service

router = APIRouter(prefix="/sync", tags=["Sync"])


@router.post("/wsop-live", response_model=ApiResponse[SyncTriggerResponse], status_code=202)
def trigger_sync(
    _: User = Depends(require_role("admin")),
):
    result = sync_service.trigger_sync()
    return ApiResponse(
        data=SyncTriggerResponse(
            status=result["status"],
            message=result["message"],
        )
    )


@router.get("/wsop-live/status", response_model=ApiResponse[SyncStatusResponse])
def get_sync_status(
    _: User = Depends(require_role("admin")),
):
    result = sync_service.get_sync_status()
    return ApiResponse(
        data=SyncStatusResponse(
            status=result["status"],
            last_sync_at=result["last_sync_at"],
            records_synced=result["records_synced"],
        )
    )
