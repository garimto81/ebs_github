"""PayoutStructures router — template CRUD."""
from __future__ import annotations

from fastapi import APIRouter, Depends, Query
from sqlmodel import Session

from src.app.database import get_db
from src.middleware.rbac import get_current_user, require_role
from src.models.schemas import (
    ApiResponse,
    PayoutStructureCreate,
    PayoutStructureLevelResponse,
    PayoutStructureResponse,
    PayoutStructureUpdate,
)
from src.models.user import User
from src.services.payout_structure_service import (
    create_payout_structure,
    delete_payout_structure,
    get_payout_structure,
    get_payout_structure_levels,
    list_payout_structures,
    update_payout_structure,
)

router = APIRouter(prefix="/api/v1", tags=["payout-structures"])


# ── PayoutStructure CRUD ─────────────────────────────


@router.get("/payout-structures")
def api_list_payout_structures(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    items, total = list_payout_structures(db, skip, limit)
    result = []
    for ps in items:
        levels = get_payout_structure_levels(ps.payout_structure_id, db)
        result.append(
            PayoutStructureResponse(
                payout_structure_id=ps.payout_structure_id,
                name=ps.name,
                levels=[PayoutStructureLevelResponse.model_validate(lv, from_attributes=True) for lv in levels],
                created_at=ps.created_at,
                updated_at=ps.updated_at,
            )
        )
    return ApiResponse(
        data=result,
        meta={"skip": skip, "limit": limit, "total": total},
    )


@router.get("/payout-structures/{ps_id}")
def api_get_payout_structure(
    ps_id: int,
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    ps = get_payout_structure(ps_id, db)
    levels = get_payout_structure_levels(ps_id, db)
    return ApiResponse(
        data=PayoutStructureResponse(
            payout_structure_id=ps.payout_structure_id,
            name=ps.name,
            levels=[PayoutStructureLevelResponse.model_validate(lv, from_attributes=True) for lv in levels],
            created_at=ps.created_at,
            updated_at=ps.updated_at,
        )
    )


@router.post("/payout-structures", status_code=201)
def api_create_payout_structure(
    body: PayoutStructureCreate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    ps = create_payout_structure(body, db)
    levels = get_payout_structure_levels(ps.payout_structure_id, db)
    return ApiResponse(
        data=PayoutStructureResponse(
            payout_structure_id=ps.payout_structure_id,
            name=ps.name,
            levels=[PayoutStructureLevelResponse.model_validate(lv, from_attributes=True) for lv in levels],
            created_at=ps.created_at,
            updated_at=ps.updated_at,
        )
    )


@router.put("/payout-structures/{ps_id}")
def api_update_payout_structure(
    ps_id: int,
    body: PayoutStructureUpdate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    ps = update_payout_structure(ps_id, body, db)
    levels = get_payout_structure_levels(ps_id, db)
    return ApiResponse(
        data=PayoutStructureResponse(
            payout_structure_id=ps.payout_structure_id,
            name=ps.name,
            levels=[PayoutStructureLevelResponse.model_validate(lv, from_attributes=True) for lv in levels],
            created_at=ps.created_at,
            updated_at=ps.updated_at,
        )
    )


@router.delete("/payout-structures/{ps_id}", status_code=200)
def api_delete_payout_structure(
    ps_id: int,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    delete_payout_structure(ps_id, db)
    return ApiResponse(data={"deleted": True})
