from fastapi import APIRouter, Depends
from sqlmodel import Session

from bo.db.engine import get_session
from bo.db.models import Competition, User
from bo.middleware.auth import get_current_user
from bo.middleware.rbac import require_role
from bo.schemas.common import ApiResponse
from bo.schemas.competition import CompetitionCreate, CompetitionRead, CompetitionUpdate
from bo.services.crud_service import create_item, delete_item, get_by_id, get_list, update_item

router = APIRouter(prefix="/competitions", tags=["Competitions"])


@router.get("", response_model=ApiResponse[list[CompetitionRead]])
def list_competitions(
    page: int = 1,
    limit: int = 20,
    _: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    return get_list(session, Competition, page=page, limit=limit)


@router.get("/{competition_id}", response_model=ApiResponse[CompetitionRead])
def get_competition(
    competition_id: int,
    _: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    item = get_by_id(session, Competition, competition_id, pk_field="competition_id")
    return ApiResponse(data=item)


@router.post("", response_model=ApiResponse[CompetitionRead], status_code=201)
def create_competition(
    body: CompetitionCreate,
    _: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    item = create_item(session, Competition, body.model_dump())
    return ApiResponse(data=item)


@router.put("/{competition_id}", response_model=ApiResponse[CompetitionRead])
def update_competition(
    competition_id: int,
    body: CompetitionUpdate,
    _: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    item = update_item(
        session, Competition, competition_id,
        body.model_dump(exclude_unset=True), pk_field="competition_id",
    )
    return ApiResponse(data=item)


@router.delete("/{competition_id}", response_model=ApiResponse[dict])
def delete_competition(
    competition_id: int,
    _: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    result = delete_item(session, Competition, competition_id, pk_field="competition_id")
    return ApiResponse(data=result)
