"""Auth service — login, session, refresh, logout logic."""
from datetime import datetime, timedelta, timezone

from sqlmodel import Session, select

from src.models.user import User, UserSession
from src.security.jwt import (
    create_access_token,
    create_refresh_token,
    decode_token,
    get_access_ttl,
)
from src.security.password import verify_password

_LOCK_DURATION_MIN = 30  # TODO[D+1]: BS-01 §자동 잠금 정책 = "Admin 수동 해제" (permanent). 본 timed lock 은 D+1 IMPL 에서 is_locked boolean + Admin unlock 경로로 refactor.
_MAX_FAILED_ATTEMPTS = 10  # CCR-048 / BS-01 §자동 잠금 정책 SSOT (was 5). M1 D+0 drift 해소.


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


def authenticate(email: str, password: str, db: Session) -> User | None:
    """Verify credentials. Returns User on success, None on failure.

    Handles failed-login counter & account locking (BS-01).
    """
    user = db.exec(select(User).where(User.email == email)).first()
    if user is None:
        return None

    if not user.is_active:
        return None

    # Check lock
    if user.locked_until:
        lock_time = datetime.fromisoformat(user.locked_until)
        if _utcnow() < lock_time:
            return None  # still locked — caller distinguishes via locked_until field
        # Lock expired — reset
        user.failed_login_count = 0
        user.locked_until = None

    if not verify_password(password, user.password_hash):
        user.failed_login_count += 1
        if user.failed_login_count >= _MAX_FAILED_ATTEMPTS:
            user.locked_until = (_utcnow() + timedelta(minutes=_LOCK_DURATION_MIN)).isoformat()
        db.add(user)
        db.commit()
        return None

    # Success — reset counters
    user.failed_login_count = 0
    user.locked_until = None
    user.last_login_at = _utcnow().isoformat()
    db.add(user)
    db.commit()
    return user


def create_session(
    user: User, db: Session
) -> tuple[str, str, int, str]:
    """Create JWT pair + persist session.

    Returns (access_token, refresh_token, expires_in, expires_at_iso).
    """
    access_token = create_access_token(user.user_id, user.email, user.role)
    refresh_token = create_refresh_token(user.user_id)
    expires_in = get_access_ttl()
    expires_at = (_utcnow() + timedelta(seconds=expires_in)).isoformat() + "Z"

    # Upsert user_sessions
    session_row = db.exec(
        select(UserSession).where(UserSession.user_id == user.user_id)
    ).first()
    if session_row is None:
        session_row = UserSession(user_id=user.user_id)
    session_row.access_token = access_token
    session_row.refresh_token = refresh_token
    session_row.token_expires_at = expires_at
    session_row.updated_at = _utcnow().isoformat()
    db.add(session_row)
    db.commit()

    return access_token, refresh_token, expires_in, expires_at


def refresh_session(
    refresh_token: str, db: Session
) -> tuple[str, int, str] | None:
    """Validate refresh token & issue new access token.

    Returns (new_access_token, expires_in, expires_at_iso) or None on failure.
    """
    try:
        payload = decode_token(refresh_token)
    except Exception:
        return None

    if payload.get("type") != "refresh":
        return None

    user_id = int(payload["sub"])

    # Verify session still exists and refresh_token matches
    session_row = db.exec(
        select(UserSession).where(UserSession.user_id == user_id)
    ).first()
    if session_row is None or session_row.refresh_token != refresh_token:
        return None

    user = db.exec(select(User).where(User.user_id == user_id)).first()
    if user is None or not user.is_active:
        return None

    new_access = create_access_token(user.user_id, user.email, user.role)
    expires_in = get_access_ttl()
    expires_at = (_utcnow() + timedelta(seconds=expires_in)).isoformat() + "Z"

    session_row.access_token = new_access
    session_row.token_expires_at = expires_at
    session_row.updated_at = _utcnow().isoformat()
    db.add(session_row)
    db.commit()

    return new_access, expires_in, expires_at


def get_user_session(user_id: int, db: Session) -> dict | None:
    """Return current session info for a user."""
    session_row = db.exec(
        select(UserSession).where(UserSession.user_id == user_id)
    ).first()
    if session_row is None:
        return None
    return {
        "last_series_id": session_row.last_series_id,
        "last_event_id": session_row.last_event_id,
        "last_flight_id": session_row.last_flight_id,
        "last_table_id": session_row.last_table_id,
        "last_screen": session_row.last_screen,
    }


def setup_2fa(user: User, db: Session) -> tuple[str, str]:
    """Generate TOTP secret and provisioning URI. Returns (secret, uri)."""
    import pyotp

    secret = pyotp.random_base32()
    user.totp_secret = secret
    user.totp_enabled = True
    db.add(user)
    db.commit()
    db.refresh(user)

    uri = pyotp.totp.TOTP(secret).provisioning_uri(
        name=user.email, issuer_name="EBS"
    )
    return secret, uri


def disable_2fa(user_id: int, db: Session) -> None:
    """Disable 2FA for a user (admin action)."""
    user = db.exec(select(User).where(User.user_id == user_id)).first()
    if user is None:
        return
    user.totp_enabled = False
    user.totp_secret = None
    db.add(user)
    db.commit()


def verify_2fa(user_id: int, totp_code: str, db: Session) -> User | None:
    """Verify TOTP code for a user. Returns User on success, None on failure."""
    import pyotp

    user = db.exec(select(User).where(User.user_id == user_id)).first()
    if user is None or not user.totp_enabled or not user.totp_secret:
        return None

    totp = pyotp.TOTP(user.totp_secret)
    if not totp.verify(totp_code):
        return None
    return user


def logout(user_id: int, db: Session) -> None:
    """Delete user session (invalidate tokens)."""
    session_row = db.exec(
        select(UserSession).where(UserSession.user_id == user_id)
    ).first()
    if session_row:
        db.delete(session_row)
        db.commit()


def create_password_reset(email: str, db: Session) -> str | None:
    """Generate a password-reset token for the given email.

    Returns the JWT token string, or None if user not found / inactive.
    """
    user = db.exec(select(User).where(User.email == email)).first()
    if user is None or not user.is_active:
        return None
    from src.security.jwt import create_password_reset_token
    return create_password_reset_token(user.user_id)


def reset_password(token: str, new_password: str, db: Session) -> bool:
    """Reset a user's password using a valid reset token.

    Returns True on success, False on any validation failure.
    """
    try:
        payload = decode_token(token)
    except Exception:
        return False
    if payload.get("type") != "password_reset":
        return False
    user_id = int(payload["sub"])
    user = db.exec(select(User).where(User.user_id == user_id)).first()
    if user is None:
        return False
    from src.security.password import hash_password
    user.password_hash = hash_password(new_password)
    user.updated_at = _utcnow().isoformat()
    db.add(user)
    # Invalidate all sessions for this user
    sessions = db.exec(
        select(UserSession).where(UserSession.user_id == user_id)
    ).all()
    for s in sessions:
        db.delete(s)
    db.commit()
    return True


# ── Google OAuth Mock ────────────────────────────


MOCK_GOOGLE_USER = {
    "email": "mock-google@ebs.dev",
    "display_name": "Google Mock User",
}


def google_oauth_login(code: str, db: Session) -> User:
    """Mock Google OAuth: find or create user by mock email.

    In production, `code` would be exchanged for a Google access token
    via Google's token endpoint, then used to fetch user info from
    Google's userinfo API. This mock skips both steps.

    To switch to real Google OAuth, set GOOGLE_CLIENT_ID and
    GOOGLE_CLIENT_SECRET environment variables.
    """
    from src.security.password import hash_password

    email = MOCK_GOOGLE_USER["email"]
    user = db.exec(select(User).where(User.email == email)).first()
    if user is None:
        user = User(
            email=email,
            password_hash=hash_password("google-oauth-no-password"),
            display_name=MOCK_GOOGLE_USER["display_name"],
            role="viewer",
            is_active=True,
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    user.last_login_at = _utcnow().isoformat()
    db.add(user)
    db.commit()
    return user
