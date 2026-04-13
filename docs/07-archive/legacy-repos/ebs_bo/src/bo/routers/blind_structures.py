from fastapi import APIRouter, Depends
from sqlmodel import Session, select

from bo.db.engine import get_session
from bo.db.models import BlindStructure, BlindStructureLevel, User
from bo.middleware.auth import get_current_user
from bo.middleware.rbac import require_role
from bo.schemas.blind_structure import (
    BlindLevelRead,
    BlindStructureCreate,
    BlindStructureRead,
    BlindStructureUpdate,
)
from bo.schemas.common import ApiResponse
from bo.services.crud_service import delete_item, get_by_id, get_list

router = APIRouter(prefix="/blind-structures", tags=["Blind Structures"])


def _sync_levels(session: Session, bs_id: int, levels_data: list) -> None:
    """Replace all levels for a blind structure."""
    existing = session.exec(
        select(BlindStructureLevel).where(
            BlindStructureLevel.blind_structure_id == bs_id
        )
    ).all()
    for lvl in existing:
        session.delete(lvl)
    session.flush()  # flush deletes before inserting new levels with same keys

    for lvl_data in levels_data:
        lvl = BlindStructureLevel(
            blind_structure_id=bs_id,
            **lvl_data.model_dump(),
        )
        session.add(lvl)


@router.get("", response_model=ApiResponse[list[BlindStructureRead]])
def list_blind_structures(
    page: int = 1,
    limit: int = 20,
    _: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    return get_list(session, BlindStructure, page=page, limit=limit)


@router.get("/{bs_id}", response_model=ApiResponse[dict])
def get_blind_structure(
    bs_id: int,
    _: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    item = get_by_id(session, BlindStructure, bs_id, pk_field="blind_structure_id")
    levels = session.exec(
        select(BlindStructureLevel)
        .where(BlindStructureLevel.blind_structure_id == bs_id)
        .order_by(BlindStructureLevel.level_no)
    ).all()
    data = {
        "blind_structure_id": item.blind_structure_id,
        "name": item.name,
        "created_at": item.created_at,
        "updated_at": item.updated_at,
        "levels": [
            BlindLevelRead(
                id=l.id,
                level_no=l.level_no,
                small_blind=l.small_blind,
                big_blind=l.big_blind,
                ante=l.ante,
                duration_minutes=l.duration_minutes,
            ).model_dump()
            for l in levels
        ],
    }
    return ApiResponse(data=data)


@router.post("", response_model=ApiResponse[BlindStructureRead], status_code=201)
def create_blind_structure(
    body: BlindStructureCreate,
    _: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    bs = BlindStructure(name=body.name)
    session.add(bs)
    session.commit()
    session.refresh(bs)

    if body.levels:
        _sync_levels(session, bs.blind_structure_id, body.levels)
        session.commit()

    return ApiResponse(data=bs)


@router.put("/{bs_id}", response_model=ApiResponse[BlindStructureRead])
def update_blind_structure(
    bs_id: int,
    body: BlindStructureUpdate,
    _: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    item = get_by_id(session, BlindStructure, bs_id, pk_field="blind_structure_id")
    if body.name is not None:
        item.name = body.name
    session.add(item)

    if body.levels is not None:
        _sync_levels(session, bs_id, body.levels)

    session.commit()
    session.refresh(item)
    return ApiResponse(data=item)


@router.delete("/{bs_id}", response_model=ApiResponse[dict])
def delete_blind_structure(
    bs_id: int,
    _: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    # Delete levels first
    levels = session.exec(
        select(BlindStructureLevel).where(
            BlindStructureLevel.blind_structure_id == bs_id
        )
    ).all()
    for lvl in levels:
        session.delete(lvl)

    result = delete_item(session, BlindStructure, bs_id, pk_field="blind_structure_id")
    return ApiResponse(data=result)
