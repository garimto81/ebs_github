from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, func, select

from bo.db.engine import get_session
from bo.db.models import User
from bo.middleware.auth import get_current_user
from bo.middleware.rbac import require_role
from bo.schemas.common import ApiResponse
from bo.schemas.user import UserCreate, UserRead, UserUpdate
from bo.services.auth_service import hash_password, invalidate_user_sessions
from bo.services.audit_service import record_audit
from bo.services.crud_service import create_item, delete_item, get_by_id, get_list, update_item

router = APIRouter(prefix="/users", tags=["Users"])


@router.get("", response_model=ApiResponse[list[UserRead]])
def list_users(
    page: int = 1,
    limit: int = 20,
    _: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    return get_list(session, User, page=page, limit=limit)


@router.get("/{user_id}", response_model=ApiResponse[UserRead])
def get_user(
    user_id: int,
    current_user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    if current_user.role != "admin" and current_user.user_id != user_id:
        raise HTTPException(status_code=403, detail="자신의 정보만 조회할 수 있습니다")
    item = get_by_id(session, User, user_id, pk_field="user_id")
    return ApiResponse(data=item)


@router.post("", response_model=ApiResponse[UserRead], status_code=201)
def create_user(
    body: UserCreate,
    current_user: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    data = body.model_dump()
    data["password_hash"] = hash_password(data.pop("password"))
    item = create_item(session, User, data)
    record_audit(session, user_id=current_user.user_id, action="user.create", entity_type="user", entity_id=item.user_id)
    return ApiResponse(data=item)


@router.put("/{user_id}", response_model=ApiResponse[UserRead])
def update_user(
    user_id: int,
    body: UserUpdate,
    current_user: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    existing = get_by_id(session, User, user_id, pk_field="user_id")
    old_role = existing.role
    # BO-02 U-2: Cannot change role away from admin if last admin
    if existing.role == "admin" and body.role and body.role != "admin":
        admin_count = session.exec(
            select(func.count()).select_from(User).where(
                User.role == "admin", User.is_active == True  # noqa: E712
            )
        ).one()
        if admin_count <= 1:
            raise HTTPException(
                status_code=409,
                detail="최소 Admin 1명 보장: 마지막 Admin의 역할을 변경할 수 없습니다",
            )
    # BO-02: Deactivation triggers session cleanup
    if body.is_active is False and existing.is_active is True:
        invalidate_user_sessions(session, user_id)
    item = update_item(
        session, User, user_id, body.model_dump(exclude_unset=True), pk_field="user_id"
    )
    if body.role and body.role != old_role:
        record_audit(session, user_id=current_user.user_id, action="user.role_change", entity_type="user", entity_id=user_id, detail=f"role: {old_role} → {body.role}")
    else:
        record_audit(session, user_id=current_user.user_id, action="user.update", entity_type="user", entity_id=user_id)
    return ApiResponse(data=item)


@router.delete("/{user_id}", response_model=ApiResponse[dict])
def delete_user(
    user_id: int,
    current_user: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    user = get_by_id(session, User, user_id, pk_field="user_id")
    # BO-02 U-3: Cannot delete the last remaining Admin
    if user.role == "admin":
        admin_count = session.exec(
            select(func.count()).select_from(User).where(
                User.role == "admin", User.is_active == True  # noqa: E712
            )
        ).one()
        if admin_count <= 1:
            raise HTTPException(
                status_code=409,
                detail="최소 Admin 1명 보장: 마지막 Admin은 삭제할 수 없습니다",
            )
    # Invalidate all sessions before deletion
    invalidate_user_sessions(session, user_id)
    result = delete_item(session, User, user_id, pk_field="user_id")
    record_audit(session, user_id=current_user.user_id, action="user.delete", entity_type="user", entity_id=user_id)
    return ApiResponse(data=result)
