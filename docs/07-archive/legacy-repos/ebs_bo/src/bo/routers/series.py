from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from bo.db.engine import get_session
from bo.db.models import Event, Series, User
from bo.middleware.auth import get_current_user
from bo.middleware.rbac import require_role
from bo.schemas.common import ApiResponse
from bo.schemas.series import SeriesCreate, SeriesRead, SeriesUpdate
from bo.services.audit_service import record_audit
from bo.services.crud_service import create_item, delete_item, get_by_id, get_list, update_item

router = APIRouter(prefix="/series", tags=["Series"])


@router.get("", response_model=ApiResponse[list[SeriesRead]])
def list_series(
    page: int = 1,
    limit: int = 20,
    competition_id: int | None = None,
    _: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    filters = {"competition_id": competition_id} if competition_id else None
    return get_list(session, Series, page=page, limit=limit, filters=filters)


@router.get("/{series_id}", response_model=ApiResponse[SeriesRead])
def get_series(
    series_id: int,
    _: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    item = get_by_id(session, Series, series_id, pk_field="series_id")
    return ApiResponse(data=item)


@router.post("", response_model=ApiResponse[SeriesRead], status_code=201)
def create_series(
    body: SeriesCreate,
    current_user: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    item = create_item(session, Series, body.model_dump())
    record_audit(session, user_id=current_user.user_id, action="series.create", entity_type="series", entity_id=item.series_id)
    return ApiResponse(data=item)


@router.put("/{series_id}", response_model=ApiResponse[SeriesRead])
def update_series(
    series_id: int,
    body: SeriesUpdate,
    current_user: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    item = update_item(
        session, Series, series_id,
        body.model_dump(exclude_unset=True), pk_field="series_id",
    )
    record_audit(session, user_id=current_user.user_id, action="series.update", entity_type="series", entity_id=series_id)
    return ApiResponse(data=item)


@router.delete("/{series_id}", response_model=ApiResponse[dict])
def delete_series(
    series_id: int,
    current_user: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    # BO-03 S-3: Cannot delete Series if non-completed child Events exist
    events = session.exec(select(Event).where(Event.series_id == series_id)).all()
    non_completed = [e for e in events if e.status != "completed"]
    if non_completed:
        raise HTTPException(
            status_code=409,
            detail="하위 이벤트가 존재합니다. 모든 이벤트가 Completed 상태여야 삭제 가능합니다.",
        )
    result = delete_item(session, Series, series_id, pk_field="series_id")
    record_audit(session, user_id=current_user.user_id, action="series.delete", entity_type="series", entity_id=series_id)
    return ApiResponse(data=result)
