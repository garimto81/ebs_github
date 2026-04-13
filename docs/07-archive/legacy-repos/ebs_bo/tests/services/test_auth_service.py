import pytest
from bo.db.models import User
from bo.services.auth_service import (
    authenticate_user,
    create_access_token,
    create_refresh_token,
    hash_password,
    verify_password,
    verify_token,
)


def test_hash_and_verify_password():
    plain = "secure-pass-123!"
    hashed = hash_password(plain)
    assert hashed != plain
    assert verify_password(plain, hashed) is True
    assert verify_password("wrong-pass", hashed) is False


def test_create_access_token_returns_jwt(admin_user):
    token = create_access_token(admin_user)
    assert isinstance(token, str)
    assert len(token) > 20


def test_verify_access_token(admin_user):
    token = create_access_token(admin_user)
    payload = verify_token(token)
    assert payload is not None
    assert payload["sub"] == str(admin_user.user_id)
    assert payload["email"] == admin_user.email
    assert payload["role"] == admin_user.role
    assert payload["type"] == "access"
    assert "iat" in payload


def test_create_refresh_token_type(admin_user):
    token = create_refresh_token(admin_user)
    payload = verify_token(token)
    assert payload is not None
    assert payload["type"] == "refresh"
    assert "email" not in payload  # refresh tokens are minimal
    assert "iat" in payload


def test_verify_token_returns_none_for_invalid():
    result = verify_token("not.a.valid.jwt")
    assert result is None


def test_authenticate_user_success(session):
    password = "test1234!"
    user = User(
        email="auth@test.local",
        password_hash=hash_password(password),
        display_name="Auth Tester",
        role="admin",
    )
    session.add(user)
    session.commit()

    result = authenticate_user(session, "auth@test.local", password)
    assert result is not None
    assert result.email == "auth@test.local"


def test_authenticate_user_wrong_password(session):
    user = User(
        email="wrong@test.local",
        password_hash=hash_password("correct-pass"),
        display_name="Wrong Pass",
        role="viewer",
    )
    session.add(user)
    session.commit()

    result = authenticate_user(session, "wrong@test.local", "incorrect-pass")
    assert result is None


def test_authenticate_user_inactive(session):
    user = User(
        email="inactive@test.local",
        password_hash=hash_password("test1234!"),
        display_name="Inactive",
        role="admin",
        is_active=False,
    )
    session.add(user)
    session.commit()

    result = authenticate_user(session, "inactive@test.local", "test1234!")
    assert result is None
