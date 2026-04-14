"""Auth router — API-06 endpoints."""
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlmodel import Session

from src.app.config import settings
from src.app.database import get_db
from src.middleware.rbac import get_current_user
from src.models.user import User
from src.security.jwt import get_access_ttl, get_refresh_ttl
from src.services.auth_service import (
    authenticate,
    create_session,
    logout as svc_logout,
    refresh_session,
)

router = APIRouter(prefix="/auth", tags=["auth"])


# ── Request / Response schemas ────────────────────


class LoginRequest(BaseModel):
    email: str
    password: str


class RefreshRequest(BaseModel):
    refresh_token: str


class UserResponse(BaseModel):
    user_id: int
    email: str
    role: str
    table_ids: list[int] = []


class LoginData(BaseModel):
    access_token: str
    refresh_token: str
    refresh_token_delivery: str
    token_type: str = "Bearer"
    expires_in: int
    expires_at: str
    refresh_expires_in: int
    auth_profile: str
    user: UserResponse
    requires_2fa: bool = False


class LoginResponse(BaseModel):
    data: LoginData
    error: Optional[str] = None


class RefreshData(BaseModel):
    access_token: str
    expires_in: int
    expires_at: str
    auth_profile: str


class MeResponse(BaseModel):
    user_id: int
    email: str
    display_name: str
    role: str


# ── Endpoints ─────────────────────────────────────


@router.post("/login")
def login(body: LoginRequest, db: Session = Depends(get_db)):
    # Check if account is locked (return 403 before authenticate for clarity)
    from sqlmodel import select as sel
    from src.models.user import User as U
    existing = db.exec(sel(U).where(U.email == body.email)).first()
    if existing and existing.locked_until:
        from datetime import datetime, timezone
        lock_time = datetime.fromisoformat(existing.locked_until)
        if datetime.now(timezone.utc) < lock_time:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="AUTH_ACCOUNT_LOCKED",
            )

    if existing and not existing.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="AUTH_ACCOUNT_DISABLED",
        )

    user = authenticate(body.email, body.password, db)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="AUTH_INVALID_CREDENTIALS",
        )

    access_token, refresh_token, expires_in, expires_at = create_session(user, db)

    delivery = "cookie" if settings.auth_profile == "live" else "body"

    return LoginResponse(
        data=LoginData(
            access_token=access_token,
            refresh_token=refresh_token if delivery == "body" else "",
            refresh_token_delivery=delivery,
            expires_in=expires_in,
            expires_at=expires_at,
            refresh_expires_in=get_refresh_ttl(),
            auth_profile=settings.auth_profile,
            user=UserResponse(
                user_id=user.user_id,
                email=user.email,
                role=user.role,
            ),
        ),
        error=None,
    )


@router.post("/refresh")
def refresh(body: RefreshRequest, db: Session = Depends(get_db)):
    result = refresh_session(body.refresh_token, db)
    if result is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="AUTH_TOKEN_INVALID",
        )
    new_access, expires_in, expires_at = result
    return RefreshData(
        access_token=new_access,
        expires_in=expires_in,
        expires_at=expires_at,
        auth_profile=settings.auth_profile,
    )


@router.post("/logout")
def logout(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    svc_logout(user.user_id, db)
    return {"message": "Logged out successfully"}


@router.get("/me")
def me(user: User = Depends(get_current_user)):
    return MeResponse(
        user_id=user.user_id,
        email=user.email,
        display_name=user.display_name,
        role=user.role,
    )
