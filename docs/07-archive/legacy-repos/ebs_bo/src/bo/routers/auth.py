from datetime import datetime, timezone

from fastapi import APIRouter, Cookie, Depends, HTTPException, Request, Response, status
from sqlmodel import Session, select

from bo.db.engine import get_session
from bo.db.models import User, UserSession
from bo.middleware.auth import get_current_user
from bo.config import settings
from bo.middleware.rbac import require_role
from bo.schemas.auth import (
    LoginRequest,
    SessionNavigation,
    SessionResponse,
    SessionUser,
    TokenResponse,
    TokenUser,
    TwoFaDisableRequest,
    TwoFaSetupResponse,
    TwoFaVerifyRequest,
)
from bo.schemas.common import ApiResponse
from bo.services.auth_service import (
    authenticate_user,
    create_access_token,
    create_refresh_token,
    create_session,
    create_temp_token,
    generate_totp_secret,
    get_totp_uri,
    invalidate_user_sessions,
    verify_token,
    verify_totp,
)

router = APIRouter(prefix="/auth", tags=["Auth"])

REFRESH_COOKIE_MAX_AGE = settings.refresh_token_expire_days * 86400


def _set_refresh_cookie(response: Response, token: str) -> None:
    response.set_cookie(
        key="refresh_token",
        value=token,
        httponly=True,
        samesite="strict",
        path="/api/v1/auth",
        max_age=REFRESH_COOKIE_MAX_AGE,
        secure=False,  # Phase 1 dev — HTTPS 전환 시 True
    )


def _clear_refresh_cookie(response: Response) -> None:
    response.delete_cookie(
        key="refresh_token",
        path="/api/v1/auth",
        httponly=True,
        samesite="strict",
    )


@router.post("/login", response_model=ApiResponse[TokenResponse | dict])
def login(body: LoginRequest, response: Response, session: Session = Depends(get_session)):
    user = authenticate_user(session, body.email, body.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    # 2FA required?
    if user.totp_enabled and user.totp_secret:
        temp_token = create_temp_token(user)
        return ApiResponse(data={
            "requires_2fa": True,
            "temp_token": temp_token,
        })

    # Normal login (no 2FA)
    access = create_access_token(user)
    refresh = create_refresh_token(user)
    user.last_login_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    session.add(user)
    session.commit()
    create_session(session, user.user_id)
    token_user = TokenUser(
        user_id=user.user_id,
        email=user.email,
        role=user.role,
        table_ids=[],
    )
    _set_refresh_cookie(response, refresh)
    return ApiResponse(
        data=TokenResponse(
            access_token=access,
            expires_in=settings.access_token_expire_minutes * 60,
            user=token_user,
        )
    )


@router.post("/refresh", response_model=ApiResponse[TokenResponse])
def refresh(
    request: Request,
    response: Response,
    session: Session = Depends(get_session),
):
    refresh_token = request.cookies.get("refresh_token")
    if not refresh_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token not found",
        )
    payload = verify_token(refresh_token)
    if payload is None or payload.get("type") != "refresh":
        _clear_refresh_cookie(response)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
        )
    user_id = int(payload["sub"])
    user = session.exec(select(User).where(User.user_id == user_id)).first()
    if not user or not user.is_active:
        _clear_refresh_cookie(response)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or inactive",
        )
    access = create_access_token(user)
    token_user = TokenUser(
        user_id=user.user_id,
        email=user.email,
        role=user.role,
        table_ids=[],
    )
    return ApiResponse(
        data=TokenResponse(
            access_token=access,
            expires_in=settings.access_token_expire_minutes * 60,
            user=token_user,
        )
    )


@router.get("/session", response_model=ApiResponse[SessionResponse])
def get_session_info(
    current_user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    us = session.exec(
        select(UserSession).where(UserSession.user_id == current_user.user_id)
    ).first()
    user = SessionUser(
        user_id=current_user.user_id,
        email=current_user.email,
        display_name=current_user.display_name,
        role=current_user.role,
        table_ids=[],
    )
    navigation = SessionNavigation(
        last_series_id=us.last_series_id if us else None,
        last_event_id=us.last_event_id if us else None,
        last_flight_id=us.last_flight_id if us else None,
        last_table_id=us.last_table_id if us else None,
    )
    return ApiResponse(
        data=SessionResponse(user=user, session=navigation)
    )


@router.delete("/session", response_model=ApiResponse[dict])
def logout(
    response: Response,
    current_user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    invalidate_user_sessions(session, current_user.user_id)
    _clear_refresh_cookie(response)
    return ApiResponse(data={"message": "Logged out successfully"})


@router.post("/verify-2fa", response_model=ApiResponse[TokenResponse])
def verify_2fa(body: TwoFaVerifyRequest, response: Response, session: Session = Depends(get_session)):
    payload = verify_token(body.temp_token)
    if payload is None or payload.get("type") != "2fa_temp":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired temporary token",
        )

    user_id = int(payload["sub"])
    user = session.exec(select(User).where(User.user_id == user_id)).first()
    if not user or not user.totp_secret:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
        )

    if not verify_totp(user.totp_secret, body.totp_code):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid TOTP code",
        )

    access = create_access_token(user)
    refresh = create_refresh_token(user)
    user.last_login_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    session.add(user)
    session.commit()
    create_session(session, user.user_id)
    token_user = TokenUser(
        user_id=user.user_id,
        email=user.email,
        role=user.role,
        table_ids=[],
    )
    _set_refresh_cookie(response, refresh)
    return ApiResponse(
        data=TokenResponse(
            access_token=access,
            expires_in=settings.access_token_expire_minutes * 60,
            user=token_user,
        )
    )


@router.post("/2fa/setup", response_model=ApiResponse[TwoFaSetupResponse])
def setup_2fa(
    current_user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    if current_user.totp_enabled:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="2FA already enabled",
        )

    secret = generate_totp_secret()
    qr_uri = get_totp_uri(secret, current_user.email)

    # Store secret (not yet enabled — user must verify first)
    current_user.totp_secret = secret
    session.add(current_user)
    session.commit()

    return ApiResponse(data=TwoFaSetupResponse(secret=secret, qr_uri=qr_uri))


@router.post("/2fa/enable", response_model=ApiResponse[dict])
def enable_2fa(
    body: TwoFaDisableRequest,  # reuse — has totp_code field
    current_user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    if not current_user.totp_secret:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Call /2fa/setup first",
        )
    if not verify_totp(current_user.totp_secret, body.totp_code):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid TOTP code",
        )

    current_user.totp_enabled = True
    session.add(current_user)
    session.commit()
    return ApiResponse(data={"message": "2FA enabled successfully"})


@router.post("/2fa/disable", response_model=ApiResponse[dict])
def disable_2fa(
    body: TwoFaDisableRequest,
    current_user: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    if not current_user.totp_enabled:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="2FA not enabled",
        )

    current_user.totp_enabled = False
    current_user.totp_secret = None
    session.add(current_user)
    session.commit()
    return ApiResponse(data={"message": "2FA disabled"})
