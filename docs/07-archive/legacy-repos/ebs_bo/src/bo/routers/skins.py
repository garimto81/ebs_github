from fastapi import APIRouter, Depends
from sqlmodel import Session, select

from bo.db.engine import get_session
from bo.db.models import Skin, User
from bo.middleware.auth import get_current_user
from bo.middleware.rbac import require_role
from bo.schemas.common import ApiResponse
from bo.schemas.skin import SkinCreate, SkinRead, SkinUpdate
from bo.services.crud_service import create_item, delete_item, get_by_id, get_list, update_item

router = APIRouter(prefix="/skins", tags=["Skins"])


@router.get("", response_model=ApiResponse[list[SkinRead]])
def list_skins(
    page: int = 1,
    limit: int = 20,
    _: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    return get_list(session, Skin, page=page, limit=limit)


@router.get("/{skin_id}", response_model=ApiResponse[SkinRead])
def get_skin(
    skin_id: int,
    _: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    item = get_by_id(session, Skin, skin_id, pk_field="skin_id")
    return ApiResponse(data=item)


@router.post("", response_model=ApiResponse[SkinRead], status_code=201)
def create_skin(
    body: SkinCreate,
    _: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    item = create_item(session, Skin, body.model_dump())
    return ApiResponse(data=item)


@router.put("/{skin_id}", response_model=ApiResponse[SkinRead])
def update_skin(
    skin_id: int,
    body: SkinUpdate,
    _: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    item = update_item(
        session, Skin, skin_id,
        body.model_dump(exclude_unset=True), pk_field="skin_id",
    )
    return ApiResponse(data=item)


@router.delete("/{skin_id}", response_model=ApiResponse[dict])
def delete_skin(
    skin_id: int,
    _: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    result = delete_item(session, Skin, skin_id, pk_field="skin_id")
    return ApiResponse(data=result)


@router.post("/{skin_id}/activate", response_model=ApiResponse[SkinRead])
def activate_skin(
    skin_id: int,
    _: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    # Unset all defaults
    all_skins = session.exec(select(Skin).where(Skin.is_default == True)).all()  # noqa: E712
    for s in all_skins:
        s.is_default = False
        session.add(s)

    # Set this one as default
    item = get_by_id(session, Skin, skin_id, pk_field="skin_id")
    item.is_default = True
    session.add(item)
    session.commit()
    session.refresh(item)
    return ApiResponse(data=item)
