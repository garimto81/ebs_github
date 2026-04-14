"""Auth service — login, session, refresh, logout logic."""
from datetime import datetime, timedelta, timezone

from sqlmodel import Session, select

from src.models.user import User, UserSession
from src.security.jwt import (
    create_access_token,
    create_refresh_token,
    decode_token,
    get_access_ttl,
    get_refresh_ttl,
)
from src.security.password import verify_password

_LOCK_DURATION_MIN = 30
_MAX_FAILED_ATTEMPTS = 5


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


def logout(user_id: int, db: Session) -> None:
    """Delete user session (invalidate tokens)."""
    session_row = db.exec(
        select(UserSession).where(UserSession.user_id == user_id)
    ).first()
    if session_row:
        db.delete(session_row)
        db.commit()
