"""BrandPacks router (Cycle 17).

GET    /api/v1/brand-packs           list (any authenticated)
GET    /api/v1/brand-packs/active    active brand pack (any authenticated)
GET    /api/v1/brand-packs/{id}      single (any authenticated)
POST   /api/v1/brand-packs           create (admin)
PUT    /api/v1/brand-packs/{id}      update (admin)
POST   /api/v1/brand-packs/{id}/activate  activate as default (admin)
DELETE /api/v1/brand-packs/{id}      delete (admin)
"""
from __future__ import annotations

from fastapi import APIRouter, Depends, Query
from sqlmodel import Session

from src.app.database import get_db
from src.middleware.rbac import get_current_user, require_role
from src.models.schemas import (
    ApiResponse,
    BrandPackCreate,
    BrandPackResponse,
    BrandPackUpdate,
)
from src.models.user import User
from src.services.brand_pack_service import (
    activate_brand_pack,
    create_brand_pack,
    delete_brand_pack,
    get_active_brand_pack,
    get_brand_pack,
    list_brand_packs,
    update_brand_pack,
)

router = APIRouter(prefix="/api/v1", tags=["brand-packs"])


@router.get("/brand-packs")
def api_list_brand_packs(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    items, total = list_brand_packs(db, skip, limit)
    return ApiResponse(
        data=[BrandPackResponse.model_validate(bp, from_attributes=True) for bp in items],
        meta={"skip": skip, "limit": limit, "total": total},
    )


@router.get("/brand-packs/active")
def api_get_active_brand_pack(
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    bp = get_active_brand_pack(db)
    return ApiResponse(
        data=BrandPackResponse.model_validate(bp, from_attributes=True) if bp else None,
    )


@router.get("/brand-packs/{brand_pack_id}")
def api_get_brand_pack(
    brand_pack_id: int,
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    bp = get_brand_pack(brand_pack_id, db)
    return ApiResponse(data=BrandPackResponse.model_validate(bp, from_attributes=True))


@router.post("/brand-packs", status_code=201)
def api_create_brand_pack(
    body: BrandPackCreate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    bp = create_brand_pack(body, db)
    return ApiResponse(data=BrandPackResponse.model_validate(bp, from_attributes=True))


@router.put("/brand-packs/{brand_pack_id}")
def api_update_brand_pack(
    brand_pack_id: int,
    body: BrandPackUpdate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    bp = update_brand_pack(brand_pack_id, body, db)
    return ApiResponse(data=BrandPackResponse.model_validate(bp, from_attributes=True))


@router.post("/brand-packs/{brand_pack_id}/activate")
def api_activate_brand_pack(
    brand_pack_id: int,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    bp = activate_brand_pack(brand_pack_id, db)
    return ApiResponse(data=BrandPackResponse.model_validate(bp, from_attributes=True))


@router.delete("/brand-packs/{brand_pack_id}", status_code=200)
def api_delete_brand_pack(
    brand_pack_id: int,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    delete_brand_pack(brand_pack_id, db)
    return ApiResponse(data={"deleted": True})
