"""Auth router — API-06 endpoints."""
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Response, status
from pydantic import BaseModel  # kept for IDE resolution of internal helpers
from sqlmodel import Session

from src.models.base import EbsBaseModel

from src.app.config import settings
from src.app.database import get_db
from src.middleware.rbac import get_current_user, require_role
from src.models.user import User
from src.security.jwt import (
    create_2fa_temp_token,
    decode_token,
    get_refresh_ttl,
)


# ── Refresh cookie helper (CCR-048 live delivery) ──


REFRESH_COOKIE_NAME = "refresh_token"
REFRESH_COOKIE_PATH = "/auth/refresh"


def _set_refresh_cookie(response: Response, refresh_token: str) -> None:
    """Emit HttpOnly Secure SameSite=Strict refresh cookie for `live` profile.

    SSOT Auth_and_Session.md §2 + BS-01 — without this, `delivery="cookie"`
    silently dropped the token (the cookie header was never set).
    """
    response.set_cookie(
        key=REFRESH_COOKIE_NAME,
        value=refresh_token,
        max_age=get_refresh_ttl(),
        path=REFRESH_COOKIE_PATH,
        secure=True,
        httponly=True,
        samesite="strict",
    )
from src.services.auth_service import (
    authenticate,
    create_password_reset,
    create_session,
    get_user_session,
    google_oauth_login,
    refresh_session,
    reset_password,
)
from src.services.auth_service import (
    disable_2fa as svc_disable_2fa,
)
from src.services.auth_service import (
    logout as svc_logout,
)
from src.services.auth_service import (
    setup_2fa as svc_setup_2fa,
)
from src.services.auth_service import (
    verify_2fa as svc_verify_2fa,
)

router = APIRouter(prefix="/auth", tags=["auth"])


# ── Request / Response schemas ────────────────────


class LoginRequest(EbsBaseModel):
    email: str
    password: str


class RefreshRequest(EbsBaseModel):
    refresh_token: str


class UserResponse(EbsBaseModel):
    user_id: int
    email: str
    role: str
    table_ids: list[int] = []


class LoginData(EbsBaseModel):
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


class LoginResponse(EbsBaseModel):
    data: LoginData
    error: Optional[str] = None


class RefreshData(EbsBaseModel):
    access_token: str
    expires_in: int
    expires_at: str
    auth_profile: str


class TwoFaLoginData(EbsBaseModel):
    requires_2fa: bool = True
    temp_token: str


class TwoFaLoginResponse(EbsBaseModel):
    data: TwoFaLoginData
    error: Optional[str] = None


class Verify2faRequest(EbsBaseModel):
    temp_token: str
    totp_code: str


class Setup2faResponse(EbsBaseModel):
    secret: str
    provisioning_uri: str


class Disable2faRequest(EbsBaseModel):
    user_id: int


class SessionInfoResponse(EbsBaseModel):
    user: UserResponse
    session: dict


class MeResponse(EbsBaseModel):
    user_id: int
    email: str
    display_name: str
    role: str


# ── Endpoints ─────────────────────────────────────


@router.post("/login")
def login(body: LoginRequest, response: Response, db: Session = Depends(get_db)):
    # Check if account is locked (return 403 before authenticate for clarity)
    from sqlmodel import select as sel

    from src.models.user import User as UserModel
    existing = db.exec(sel(UserModel).where(UserModel.email == body.email)).first()
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

    # 2FA gate: if enabled, return temp token instead of real session
    if user.totp_enabled:
        temp_token = create_2fa_temp_token(user.user_id)
        return TwoFaLoginResponse(
            data=TwoFaLoginData(requires_2fa=True, temp_token=temp_token),
            error=None,
        )

    access_token, refresh_token, expires_in, expires_at = create_session(user, db)

    delivery = "cookie" if settings.auth_profile == "live" else "body"
    if delivery == "cookie":
        _set_refresh_cookie(response, refresh_token)

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


@router.get("/session")
def get_session(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Return current session info (§4 Auth_and_Session)."""
    session_data = get_user_session(user.user_id, db)
    return SessionInfoResponse(
        user=UserResponse(
            user_id=user.user_id,
            email=user.email,
            role=user.role,
        ),
        session=session_data or {},
    )


@router.post("/verify-2fa")
def verify_2fa(body: Verify2faRequest, response: Response, db: Session = Depends(get_db)):
    """Verify TOTP code with temp_token from login. Public endpoint."""
    from jose import JWTError

    try:
        payload = decode_token(body.temp_token)
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="AUTH_TOKEN_INVALID",
        )

    if payload.get("type") != "2fa_temp":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="AUTH_TOKEN_INVALID",
        )

    user_id = int(payload["sub"])
    user = svc_verify_2fa(user_id, body.totp_code, db)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="AUTH_2FA_INVALID",
        )

    access_token, refresh_token, expires_in, expires_at = create_session(user, db)
    delivery = "cookie" if settings.auth_profile == "live" else "body"
    if delivery == "cookie":
        _set_refresh_cookie(response, refresh_token)

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


@router.post("/2fa/setup")
def setup_2fa(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Generate TOTP secret and provisioning URI for the current user."""
    secret, uri = svc_setup_2fa(user, db)
    return Setup2faResponse(secret=secret, provisioning_uri=uri)


@router.post("/2fa/disable")
def disable_2fa(
    body: Disable2faRequest,
    user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """Admin-only: disable 2FA for a target user."""
    svc_disable_2fa(body.user_id, db)
    return {"message": "2FA disabled successfully"}


# ── Password Reset schemas ───────────────────────


class PasswordResetSendRequest(EbsBaseModel):
    email: str


class PasswordResetVerifyRequest(EbsBaseModel):
    token: str


class PasswordResetRequest(EbsBaseModel):
    token: str
    new_password: str


# ── Password Reset endpoints (CCR-048) ───────────


@router.post("/password/reset/send")
def password_reset_send(body: PasswordResetSendRequest, db: Session = Depends(get_db)):
    """Request a password reset link. Always returns 200 (enumeration defense)."""
    token = create_password_reset(body.email, db)
    response: dict = {"message": "If the email exists, a reset link has been sent."}
    if token is not None:
        response["dev_token"] = token  # Phase 1: no email, return token for dev
    return response


@router.post("/password/reset/verify")
def password_reset_verify(body: PasswordResetVerifyRequest, db: Session = Depends(get_db)):
    """Verify a password reset token is valid and not expired."""
    from datetime import datetime, timezone

    from jose import JWTError

    try:
        payload = decode_token(body.token)
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": "PASSWORD_RESET_INVALID_TOKEN", "message": "Invalid or malformed token"},
        )

    if payload.get("type") != "password_reset":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": "PASSWORD_RESET_INVALID_TOKEN", "message": "Invalid token type"},
        )

    exp_ts = payload.get("exp", 0)
    expires_at = datetime.fromtimestamp(exp_ts, tz=timezone.utc)

    if datetime.now(timezone.utc) >= expires_at:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": "PASSWORD_RESET_TOKEN_EXPIRED", "message": "Token has expired"},
        )

    return {"valid": True, "expires_at": expires_at.isoformat().replace("+00:00", "Z")}


@router.post("/password/reset")
def password_reset(body: PasswordResetRequest, db: Session = Depends(get_db)):
    """Reset password using a valid reset token."""
    success = reset_password(body.token, body.new_password, db)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": "PASSWORD_RESET_INVALID_TOKEN", "message": "Invalid or expired token"},
        )
    return {"message": "Password reset successfully"}


# ── Google OAuth (Mock) ─────────────────────────


@router.get("/google")
def google_oauth_start():
    """Start Google OAuth flow.

    Mock: redirects directly to callback with a mock code.
    Production: redirects to Google consent page.
    """
    from fastapi.responses import RedirectResponse

    # Mock: skip Google consent, go straight to callback
    return RedirectResponse(
        url="/auth/google/callback?code=mock_auth_code&state=mock",
        status_code=302,
    )


@router.get("/google/callback")
def google_oauth_callback(
    response: Response,
    code: str = "",
    state: str = "",
    db: Session = Depends(get_db),
):
    """Google OAuth callback — exchange code for JWT session.

    Mock: uses mock user. Production: exchanges code with Google.
    """
    if not code:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="AUTH_OAUTH_MISSING_CODE",
        )

    user = google_oauth_login(code, db)
    access_token, refresh_token, expires_in, expires_at = create_session(
        user, db
    )

    delivery = "cookie" if settings.auth_profile == "live" else "body"
    if delivery == "cookie":
        _set_refresh_cookie(response, refresh_token)

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
