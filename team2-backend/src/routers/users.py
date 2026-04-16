"""Users router — API-01 §5.11."""
from fastapi import APIRouter, Depends, Query
from sqlmodel import Session

from src.app.database import get_db
from src.middleware.rbac import require_role
from src.models.schemas import (
    ApiResponse,
    UserCreate,
    UserResponse,
    UserUpdate,
)
from src.models.user import User
from src.services.user_service import (
    create_user,
    delete_user,
    get_user,
    list_users,
    update_user,
)

router = APIRouter(prefix="/api/v1", tags=["users"])


@router.get("/users")
def api_list_users(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    items, total = list_users(db, skip, limit)
    return ApiResponse(
        data=[UserResponse.model_validate(u, from_attributes=True) for u in items],
        meta={"skip": skip, "limit": limit, "total": total},
    )


@router.post("/users", status_code=201)
def api_create_user(
    body: UserCreate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    u = create_user(body, db)
    return ApiResponse(data=UserResponse.model_validate(u, from_attributes=True))


@router.get("/users/{user_id}")
def api_get_user(
    user_id: int,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    u = get_user(user_id, db)
    return ApiResponse(data=UserResponse.model_validate(u, from_attributes=True))


@router.put("/users/{user_id}")
def api_update_user(
    user_id: int,
    body: UserUpdate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    u = update_user(user_id, body, db)
    return ApiResponse(data=UserResponse.model_validate(u, from_attributes=True))


@router.delete("/users/{user_id}")
def api_delete_user(
    user_id: int,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    delete_user(user_id, db)
    return ApiResponse(data={"deleted": True})
