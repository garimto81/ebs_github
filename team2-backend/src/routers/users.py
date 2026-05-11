"""Users router — API-01 §5.11."""
from datetime import datetime, timezone

from fastapi import APIRouter, Body, Depends, HTTPException, Query, Request
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
from src.services.auth_service import force_logout_user
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


@router.post("/users/{user_id}/force-logout")
async def api_force_logout(
    user_id: int,
    request: Request,
    body: dict | None = Body(default=None),
    actor: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """IMPL-009 / API-05 §13.3 — admin 강제 로그아웃.

    실제 동작 (V9.5 P7 minimal viable 흡수, 2026-05-11 Cycle 3 #236 완결):
      1. target user 존재 검증 (404 if missing)
      2. self force-logout 차단 (403 if actor == target)
      3. `auth_service.force_logout_user`:
         - 모든 device 의 user_sessions.access/refresh jti blacklist 등록
         - user_sessions 행 전체 삭제
         - audit_events 삽입 (table_id="_global", event_type=force_logout)
      4. WebSocket: `ConnectionManager.disconnect_user(user_id, payload, code=4003)`
         - cc + lobby 양 채널 강제 종료
         - close code 4003 (custom application code)
         - 끊긴 cc 연결만큼 cc_session_count broadcast
      5. target.updated_at bump (downstream cache invalidation 신호)

    Returns 200 OK + `{ data: { forced_logout, target_user_id, deleted_sessions,
    blacklisted_jtis, disconnected_ws, audit_event_id } }`. spec §13.3 의 204 는
    `Backend_HTTP_Status` 정합 별도 cascade — 본 PR 은 ApiResponse 일관성을
    위해 200 + body 유지.
    """
    target = get_user(user_id, db)
    if actor.user_id == target.user_id:
        raise HTTPException(
            status_code=403,
            detail={
                "code": "FORCE_LOGOUT_SELF_DENIED",
                "message": "Admin cannot force-logout self",
            },
        )

    reason = (body or {}).get("reason") if isinstance(body, dict) else None
    result = force_logout_user(
        target_user_id=user_id,
        actor_user_id=actor.user_id,
        db=db,
        reason=reason,
    )

    # WebSocket disconnect — manager 가 app.state 에 부착됨. Test 환경에서
    # ws_manager 미부착이면 graceful skip (0 disconnected). publish_force_logout
    # 이 payload 구성 + disconnect_user(close_code=4003) 단일 호출로 처리.
    ws_manager = getattr(request.app.state, "ws_manager", None)
    disconnected = 0
    if ws_manager is not None:
        from src.websocket.publishers import publish_force_logout
        try:
            disconnected = await publish_force_logout(
                ws_manager,
                target_user_id=str(user_id),
                actor_user_id=str(actor.user_id),
                reason=reason,
            )
        except Exception:
            # WS layer 실패가 DB-level revoke 결과를 무효화하면 안 됨.
            disconnected = 0

    # updated_at bump — frontend cache 무효화 신호.
    target.updated_at = datetime.now(timezone.utc).isoformat()
    db.add(target)
    db.commit()

    return ApiResponse(data={
        "forced_logout": True,
        "target_user_id": user_id,
        "deleted_sessions": result["deleted_sessions"],
        "blacklisted_jtis": result["blacklisted_jtis"],
        "disconnected_ws": disconnected,
        "audit_event_id": result["audit_event_id"],
    })


@router.delete("/users/{user_id}")
def api_delete_user(
    user_id: int,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    delete_user(user_id, db)
    return ApiResponse(data={"deleted": True})
