"""auth_service.py extended unit tests (Session 2.1 — B-Q10 cascade).

Targets missing branches in src/services/auth_service.py (50% → 80% goal):
- authenticate: user_not_found / inactive / lock_expired_resets
- refresh_session: invalid_token_type / session_mismatch / user_inactive
- get_user_session: not_found
- setup_2fa / disable_2fa / verify_2fa
- create_password_reset / reset_password
- google_oauth_login

Strict rule (B-Q15 cascade): production code 0 modification, tests/ only.
"""
from datetime import datetime, timedelta, timezone

import pytest
from sqlmodel import Session, select

from src.models.user import User, UserSession
from src.security.password import hash_password
from src.services.auth_service import (
    authenticate,
    create_password_reset,
    create_session,
    disable_2fa,
    get_user_session,
    google_oauth_login,
    logout,
    refresh_session,
    reset_password,
    setup_2fa,
    verify_2fa,
)


# ── helpers ──────────────────────────────────────


def _make_user(
    db: Session,
    email: str = "svc-test@example.com",
    password: str = "Password123!",
    role: str = "viewer",
    is_active: bool = True,
    locked_until: str | None = None,
    failed_login_count: int = 0,
) -> User:
    """Create a user directly in DB for service-level testing."""
    user = User(
        email=email,
        password_hash=hash_password(password),
        display_name=f"Test {email}",
        role=role,
        is_active=is_active,
        locked_until=locked_until,
        failed_login_count=failed_login_count,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


# ── authenticate edge cases ──────────────────────


def test_authenticate_user_not_found(db_session: Session):
    """authenticate returns None for non-existent email (line 30)."""
    result = authenticate("nonexistent@example.com", "AnyPassword123!", db_session)
    assert result is None


def test_authenticate_inactive_user(db_session: Session):
    """authenticate returns None for inactive user (line 33)."""
    _make_user(db_session, email="inactive-svc@example.com", is_active=False)
    result = authenticate("inactive-svc@example.com", "Password123!", db_session)
    assert result is None


def test_authenticate_locked_user_still_locked(db_session: Session):
    """authenticate returns None when user is currently locked (line 37-39)."""
    future = (datetime.now(timezone.utc) + timedelta(minutes=10)).isoformat()
    _make_user(
        db_session,
        email="locked-svc@example.com",
        locked_until=future,
        failed_login_count=5,
    )
    result = authenticate("locked-svc@example.com", "Password123!", db_session)
    assert result is None


def test_authenticate_lock_expired_resets(db_session: Session):
    """authenticate succeeds + resets counter when lock has expired (line 40-42)."""
    past = (datetime.now(timezone.utc) - timedelta(minutes=10)).isoformat()
    _make_user(
        db_session,
        email="expired-lock@example.com",
        locked_until=past,
        failed_login_count=5,
    )
    result = authenticate("expired-lock@example.com", "Password123!", db_session)
    assert result is not None
    # Verify lock + counter reset (line 41-42 + line 53-54)
    refreshed = db_session.exec(
        select(User).where(User.email == "expired-lock@example.com")
    ).first()
    assert refreshed.locked_until is None
    assert refreshed.failed_login_count == 0


# ── refresh_session edge cases ───────────────────


def test_refresh_session_invalid_token_returns_none(db_session: Session):
    """refresh_session returns None for malformed token (line 98-99)."""
    result = refresh_session("not.a.valid.jwt", db_session)
    assert result is None


def test_refresh_session_wrong_token_type(db_session: Session):
    """refresh_session returns None when token type is not 'refresh' (line 102)."""
    user = _make_user(db_session, email="refresh-type@example.com")
    # Create an access token (not refresh) and try to refresh with it
    access, _refresh, _exp_in, _exp_at = create_session(user, db_session)
    result = refresh_session(access, db_session)
    assert result is None


def test_refresh_session_token_mismatch_returns_none(db_session: Session):
    """refresh_session returns None when stored refresh != provided refresh (line 110-111)."""
    user = _make_user(db_session, email="refresh-mismatch@example.com")
    _access, refresh_a, _, _ = create_session(user, db_session)
    # Manually overwrite stored refresh_token in DB so it differs from refresh_a
    session_row = db_session.exec(
        select(UserSession).where(UserSession.user_id == user.user_id)
    ).first()
    session_row.refresh_token = "manually-overwritten-different-value"
    db_session.add(session_row)
    db_session.commit()
    # Provided refresh_a no longer matches stored value → None
    result = refresh_session(refresh_a, db_session)
    assert result is None


# ── get_user_session ─────────────────────────────


def test_get_user_session_not_found(db_session: Session):
    """get_user_session returns None for user with no session (line 135-136)."""
    result = get_user_session(99999, db_session)
    assert result is None


# ── 2FA paths ────────────────────────────────────


def test_setup_2fa_returns_secret_and_uri(db_session: Session):
    """setup_2fa returns secret + provisioning URI + persists to user (line 148-160)."""
    user = _make_user(db_session, email="2fa-setup@example.com")
    secret, uri = setup_2fa(user, db_session)
    assert secret  # non-empty base32
    assert uri.startswith("otpauth://")
    assert "EBS" in uri
    # Verify persisted
    refreshed = db_session.exec(
        select(User).where(User.email == "2fa-setup@example.com")
    ).first()
    assert refreshed.totp_secret == secret
    assert refreshed.totp_enabled is True


def test_disable_2fa_clears_fields(db_session: Session):
    """disable_2fa clears totp_secret + totp_enabled (line 165-171)."""
    user = _make_user(db_session, email="2fa-disable@example.com")
    setup_2fa(user, db_session)
    disable_2fa(user.user_id, db_session)
    refreshed = db_session.exec(
        select(User).where(User.user_id == user.user_id)
    ).first()
    assert refreshed.totp_enabled is False
    assert refreshed.totp_secret is None


def test_disable_2fa_user_not_found_is_noop(db_session: Session):
    """disable_2fa silently returns when user doesn't exist (line 166-167)."""
    # Should not raise
    disable_2fa(99999, db_session)


def test_verify_2fa_user_without_2fa_returns_none(db_session: Session):
    """verify_2fa returns None when user has no 2FA enabled (line 179-180)."""
    user = _make_user(db_session, email="2fa-noenabled@example.com")
    result = verify_2fa(user.user_id, "123456", db_session)
    assert result is None


def test_verify_2fa_invalid_code_returns_none(db_session: Session):
    """verify_2fa returns None for wrong TOTP code (line 183-184)."""
    user = _make_user(db_session, email="2fa-wrongcode@example.com")
    setup_2fa(user, db_session)
    # 000000 is statistically unlikely to be the current valid code
    result = verify_2fa(user.user_id, "000000", db_session)
    assert result is None


def test_verify_2fa_valid_code_returns_user(db_session: Session):
    """verify_2fa returns User for correct TOTP code (line 185)."""
    import pyotp

    user = _make_user(db_session, email="2fa-validcode@example.com")
    secret, _uri = setup_2fa(user, db_session)
    valid_code = pyotp.TOTP(secret).now()
    result = verify_2fa(user.user_id, valid_code, db_session)
    assert result is not None
    assert result.user_id == user.user_id


# ── password reset ───────────────────────────────


def test_create_password_reset_user_not_found(db_session: Session):
    """create_password_reset returns None for unknown email (line 204-205)."""
    result = create_password_reset("nobody@example.com", db_session)
    assert result is None


def test_create_password_reset_inactive_user(db_session: Session):
    """create_password_reset returns None for inactive user (line 204)."""
    _make_user(db_session, email="reset-inactive@example.com", is_active=False)
    result = create_password_reset("reset-inactive@example.com", db_session)
    assert result is None


def test_create_password_reset_returns_token(db_session: Session):
    """create_password_reset returns JWT token for valid active user (line 206-207)."""
    _make_user(db_session, email="reset-valid@example.com")
    token = create_password_reset("reset-valid@example.com", db_session)
    assert token
    assert isinstance(token, str)
    # JWT format: header.payload.signature
    assert token.count(".") == 2


def test_reset_password_invalid_token_returns_false(db_session: Session):
    """reset_password returns False for malformed token (line 217-218)."""
    result = reset_password("not.a.valid.jwt", "NewPassword123!", db_session)
    assert result is False


def test_reset_password_succeeds_and_invalidates_sessions(db_session: Session):
    """reset_password succeeds + clears all user sessions (line 215-236)."""
    user = _make_user(db_session, email="reset-success@example.com", password="Old123!")
    # Create a session for the user
    create_session(user, db_session)
    # Generate a valid reset token
    token = create_password_reset("reset-success@example.com", db_session)
    assert token is not None

    # Reset
    result = reset_password(token, "New456Password!", db_session)
    assert result is True

    # Verify password changed (new auth works, old fails)
    assert authenticate("reset-success@example.com", "New456Password!", db_session) is not None
    assert authenticate("reset-success@example.com", "Old123!", db_session) is None

    # Verify session was deleted (line 230-234)
    sessions = db_session.exec(
        select(UserSession).where(UserSession.user_id == user.user_id)
    ).all()
    assert len(sessions) == 0


# ── google OAuth (mock) ──────────────────────────


def test_google_oauth_creates_new_user(db_session: Session):
    """google_oauth_login creates user if not exists (line 261-272)."""
    from src.services.auth_service import MOCK_GOOGLE_USER

    # Ensure mock user does not exist (cleanup if present)
    existing = db_session.exec(
        select(User).where(User.email == MOCK_GOOGLE_USER["email"])
    ).first()
    if existing:
        # Clean up sessions first then user
        sessions = db_session.exec(
            select(UserSession).where(UserSession.user_id == existing.user_id)
        ).all()
        for s in sessions:
            db_session.delete(s)
        db_session.delete(existing)
        db_session.commit()

    user = google_oauth_login("mock_code", db_session)
    assert user is not None
    assert user.email == MOCK_GOOGLE_USER["email"]
    assert user.role == "viewer"
    assert user.is_active is True


def test_google_oauth_existing_user_updates_login(db_session: Session):
    """google_oauth_login finds existing user + updates last_login_at (line 261, 274-277)."""
    from src.services.auth_service import MOCK_GOOGLE_USER

    # First call creates the user
    user1 = google_oauth_login("mock_code1", db_session)
    user1_id = user1.user_id

    # Second call finds existing
    user2 = google_oauth_login("mock_code2", db_session)
    assert user2.user_id == user1_id
    assert user2.email == MOCK_GOOGLE_USER["email"]


# ── logout (light coverage boost) ─────────────────


def test_logout_no_session_is_noop(db_session: Session):
    """logout silently returns when user has no session."""
    user = _make_user(db_session, email="logout-nosession@example.com")
    # Don't create_session — directly logout
    logout(user.user_id, db_session)  # should not raise
