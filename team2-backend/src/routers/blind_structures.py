"""BlindStructures router — template CRUD + flight assignment."""
from __future__ import annotations

from fastapi import APIRouter, Depends, Query
from sqlmodel import Session

from src.app.database import get_db
from src.middleware.rbac import get_current_user, require_role
from src.models.schemas import (
    ApiResponse,
    BlindStructureApply,
    BlindStructureCreate,
    BlindStructureLevelResponse,
    BlindStructureResponse,
    BlindStructureUpdate,
)
from src.models.user import User
from src.services.blind_structure_service import (
    apply_blind_structure,
    create_blind_structure,
    delete_blind_structure,
    get_blind_structure,
    get_blind_structure_levels,
    get_flight_blind_structure,
    list_blind_structures,
    update_blind_structure,
)

router = APIRouter(prefix="/api/v1", tags=["blind-structures"])


# ── BlindStructure CRUD ────────────────────────────


@router.get("/blind-structures")
def api_list_blind_structures(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    items, total = list_blind_structures(db, skip, limit)
    result = []
    for bs in items:
        levels = get_blind_structure_levels(bs.blind_structure_id, db)
        result.append(
            BlindStructureResponse(
                blind_structure_id=bs.blind_structure_id,
                name=bs.name,
                levels=[BlindStructureLevelResponse.model_validate(lv, from_attributes=True) for lv in levels],
                created_at=bs.created_at,
                updated_at=bs.updated_at,
            )
        )
    return ApiResponse(
        data=result,
        meta={"skip": skip, "limit": limit, "total": total},
    )


@router.get("/blind-structures/{bs_id}")
def api_get_blind_structure(
    bs_id: int,
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    bs = get_blind_structure(bs_id, db)
    levels = get_blind_structure_levels(bs_id, db)
    return ApiResponse(
        data=BlindStructureResponse(
            blind_structure_id=bs.blind_structure_id,
            name=bs.name,
            levels=[BlindStructureLevelResponse.model_validate(lv, from_attributes=True) for lv in levels],
            created_at=bs.created_at,
            updated_at=bs.updated_at,
        )
    )


@router.post("/blind-structures", status_code=201)
def api_create_blind_structure(
    body: BlindStructureCreate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    bs = create_blind_structure(body, db)
    levels = get_blind_structure_levels(bs.blind_structure_id, db)
    return ApiResponse(
        data=BlindStructureResponse(
            blind_structure_id=bs.blind_structure_id,
            name=bs.name,
            levels=[BlindStructureLevelResponse.model_validate(lv, from_attributes=True) for lv in levels],
            created_at=bs.created_at,
            updated_at=bs.updated_at,
        )
    )


@router.put("/blind-structures/{bs_id}")
def api_update_blind_structure(
    bs_id: int,
    body: BlindStructureUpdate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    bs = update_blind_structure(bs_id, body, db)
    levels = get_blind_structure_levels(bs_id, db)
    return ApiResponse(
        data=BlindStructureResponse(
            blind_structure_id=bs.blind_structure_id,
            name=bs.name,
            levels=[BlindStructureLevelResponse.model_validate(lv, from_attributes=True) for lv in levels],
            created_at=bs.created_at,
            updated_at=bs.updated_at,
        )
    )


@router.delete("/blind-structures/{bs_id}", status_code=200)
def api_delete_blind_structure(
    bs_id: int,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    delete_blind_structure(bs_id, db)
    return ApiResponse(data={"deleted": True})


# ── Flight ↔ BlindStructure ───────────────────────


@router.get("/flights/{flight_id}/blind-structure")
def api_get_flight_blind_structure(
    flight_id: int,
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    bs = get_flight_blind_structure(flight_id, db)
    levels = get_blind_structure_levels(bs.blind_structure_id, db)
    return ApiResponse(
        data=BlindStructureResponse(
            blind_structure_id=bs.blind_structure_id,
            name=bs.name,
            levels=[BlindStructureLevelResponse.model_validate(lv, from_attributes=True) for lv in levels],
            created_at=bs.created_at,
            updated_at=bs.updated_at,
        )
    )


@router.put("/flights/{flight_id}/blind-structure")
def api_apply_blind_structure(
    flight_id: int,
    body: BlindStructureApply,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    apply_blind_structure(flight_id, body.blind_structure_id, db)
    # Return the applied structure
    bs = get_blind_structure(body.blind_structure_id, db)
    levels = get_blind_structure_levels(bs.blind_structure_id, db)
    return ApiResponse(
        data=BlindStructureResponse(
            blind_structure_id=bs.blind_structure_id,
            name=bs.name,
            levels=[BlindStructureLevelResponse.model_validate(lv, from_attributes=True) for lv in levels],
            created_at=bs.created_at,
            updated_at=bs.updated_at,
        )
    )
