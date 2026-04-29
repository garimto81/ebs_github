"""Skins router — overlay theme management."""
from fastapi import APIRouter, Depends, Query
from sqlmodel import Session

from src.app.database import get_db
from src.middleware.rbac import get_current_user, require_role
from src.models.schemas import ApiResponse, SkinCreate, SkinResponse, SkinUpdate
from src.models.user import User
from src.services.skin_service import (
    activate_skin,
    create_skin,
    delete_skin,
    get_active_skin,
    get_skin,
    list_skins,
    update_skin,
)

router = APIRouter(prefix="/api/v1", tags=["skins"])


@router.get("/skins")
def api_list_skins(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    items, total = list_skins(db, skip, limit)
    return ApiResponse(
        data=[SkinResponse.model_validate(s, from_attributes=True) for s in items],
        meta={"skip": skip, "limit": limit, "total": total},
    )


@router.get("/skins/active")
def api_get_active_skin(
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    s = get_active_skin(db)
    return ApiResponse(
        data=SkinResponse.model_validate(s, from_attributes=True) if s else None,
    )


@router.get("/skins/{skin_id}")
def api_get_skin(
    skin_id: int,
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    s = get_skin(skin_id, db)
    return ApiResponse(data=SkinResponse.model_validate(s, from_attributes=True))


@router.post("/skins", status_code=201)
def api_create_skin(
    body: SkinCreate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    s = create_skin(body, db)
    return ApiResponse(data=SkinResponse.model_validate(s, from_attributes=True))


@router.put("/skins/{skin_id}")
def api_update_skin(
    skin_id: int,
    body: SkinUpdate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """SSOT Backend_HTTP.md L745 — canonical metadata update."""
    s = update_skin(skin_id, body, db)
    return ApiResponse(data=SkinResponse.model_validate(s, from_attributes=True))


@router.patch("/skins/{skin_id}/metadata")
def api_update_skin_metadata_legacy(
    skin_id: int,
    body: SkinUpdate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """Deprecated alias. Prefer PUT /skins/:id."""
    s = update_skin(skin_id, body, db)
    return ApiResponse(data=SkinResponse.model_validate(s, from_attributes=True))


@router.post("/skins/{skin_id}/activate")
def api_activate_skin(
    skin_id: int,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """SSOT Backend_HTTP.md L749 — POST is canonical method."""
    s = activate_skin(skin_id, db)
    return ApiResponse(data=SkinResponse.model_validate(s, from_attributes=True))


@router.post("/skins/{skin_id}/deactivate")
def api_deactivate_skin(
    skin_id: int,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """V9.5 P7: 해당 skin 의 default 해제."""
    from src.services.skin_service import deactivate_skin
    s = deactivate_skin(skin_id, db)
    return ApiResponse(data=SkinResponse.model_validate(s, from_attributes=True))


@router.put("/skins/{skin_id}/activate")
def api_activate_skin_legacy(
    skin_id: int,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """Deprecated method alias. Prefer POST."""
    s = activate_skin(skin_id, db)
    return ApiResponse(data=SkinResponse.model_validate(s, from_attributes=True))


@router.delete("/skins/{skin_id}")
def api_delete_skin(
    skin_id: int,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    delete_skin(skin_id, db)
    return ApiResponse(data={"deleted": True})
