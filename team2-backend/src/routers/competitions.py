"""Competitions router — API-01 §5.3."""
from fastapi import APIRouter, Depends, Query
from sqlmodel import Session

from src.app.database import get_db
from src.middleware.rbac import get_current_user, require_role
from src.models.schemas import (
    ApiResponse,
    CompetitionCreate,
    CompetitionResponse,
    CompetitionUpdate,
)
from src.models.user import User
from src.services.competition_service import (
    create_competition,
    delete_competition,
    get_competition,
    list_competitions,
    update_competition,
)

router = APIRouter(prefix="/api/v1", tags=["competitions"])


@router.get("/competitions")
def api_list_competitions(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    items, total = list_competitions(db, skip, limit)
    return ApiResponse(
        data=[CompetitionResponse.model_validate(c, from_attributes=True) for c in items],
        meta={"skip": skip, "limit": limit, "total": total},
    )


@router.post("/competitions", status_code=201)
def api_create_competition(
    body: CompetitionCreate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    c = create_competition(body, db)
    return ApiResponse(data=CompetitionResponse.model_validate(c, from_attributes=True))


@router.get("/competitions/{competition_id}")
def api_get_competition(
    competition_id: int,
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    c = get_competition(competition_id, db)
    return ApiResponse(data=CompetitionResponse.model_validate(c, from_attributes=True))


@router.put("/competitions/{competition_id}")
def api_update_competition(
    competition_id: int,
    body: CompetitionUpdate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    c = update_competition(competition_id, body, db)
    return ApiResponse(data=CompetitionResponse.model_validate(c, from_attributes=True))


@router.delete("/competitions/{competition_id}")
def api_delete_competition(
    competition_id: int,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    delete_competition(competition_id, db)
    return ApiResponse(data={"deleted": True})
