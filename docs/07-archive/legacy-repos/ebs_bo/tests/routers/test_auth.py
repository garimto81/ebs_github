def test_login_success(client, admin_user):
    resp = client.post("/api/v1/auth/login", json={
        "email": "admin@test.local",
        "password": "test1234!",
    })
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "Bearer"
    assert isinstance(data["expires_in"], int)
    assert "user" in data
    assert data["user"]["email"] == "admin@test.local"


def test_login_wrong_password(client, admin_user):
    resp = client.post("/api/v1/auth/login", json={
        "email": "admin@test.local",
        "password": "wrong_password",
    })
    assert resp.status_code == 401


def test_login_nonexistent_user(client):
    resp = client.post("/api/v1/auth/login", json={
        "email": "nobody@test.local",
        "password": "test1234!",
    })
    assert resp.status_code == 401


def test_refresh_token(client, admin_user):
    login = client.post("/api/v1/auth/login", json={
        "email": "admin@test.local",
        "password": "test1234!",
    })
    refresh_token = login.json()["data"]["refresh_token"]
    resp = client.post("/api/v1/auth/refresh", json={
        "refresh_token": refresh_token,
    })
    assert resp.status_code == 200
    assert "access_token" in resp.json()["data"]


def test_refresh_invalid_token(client):
    resp = client.post("/api/v1/auth/refresh", json={
        "refresh_token": "invalid.token.here",
    })
    assert resp.status_code == 401


def test_get_session(client, auth_headers):
    resp = client.get("/api/v1/auth/session", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert data["user"]["email"] == "admin@test.local"
    assert data["user"]["role"] == "admin"
    assert "session" in data


def test_get_session_unauthorized(client):
    resp = client.get("/api/v1/auth/session")
    assert resp.status_code in (401, 403)


def test_delete_session(client, auth_headers):
    resp = client.delete("/api/v1/auth/session", headers=auth_headers)
    assert resp.status_code == 200


def test_2fa_setup(client, auth_headers, session):
    """Setup 2FA for admin user."""
    resp = client.post("/api/v1/auth/2fa/setup", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert "secret" in data
    assert "qr_uri" in data
    assert "otpauth://totp/" in data["qr_uri"]


def test_2fa_enable(client, auth_headers, admin_user, session):
    """Enable 2FA after setup."""
    import pyotp

    # Setup first
    resp = client.post("/api/v1/auth/2fa/setup", headers=auth_headers)
    secret = resp.json()["data"]["secret"]

    # Enable with valid code
    code = pyotp.TOTP(secret).now()
    resp = client.post(
        "/api/v1/auth/2fa/enable",
        headers=auth_headers,
        json={"totp_code": code},
    )
    assert resp.status_code == 200


def test_2fa_login_flow(client, admin_user, session):
    """Login with 2FA enabled requires temp_token + verify."""
    import pyotp
    from bo.db.models import User
    from bo.services.auth_service import hash_password

    # Create a user with 2FA enabled
    secret = pyotp.random_base32()
    user = User(
        email="2fa@test.local",
        password_hash=hash_password("test1234!"),
        display_name="2FA User",
        role="admin",
        totp_secret=secret,
        totp_enabled=True,
    )
    session.add(user)
    session.commit()

    # Login — should get requires_2fa
    resp = client.post(
        "/api/v1/auth/login",
        json={"email": "2fa@test.local", "password": "test1234!"},
    )
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert data["requires_2fa"] is True
    assert "temp_token" in data

    # Verify 2FA
    code = pyotp.TOTP(secret).now()
    resp = client.post(
        "/api/v1/auth/verify-2fa",
        json={"temp_token": data["temp_token"], "totp_code": code},
    )
    assert resp.status_code == 200
    assert "access_token" in resp.json()["data"]


def test_2fa_verify_wrong_code(client, session):
    """Wrong TOTP code should fail."""
    import pyotp
    from bo.db.models import User
    from bo.services.auth_service import hash_password

    secret = pyotp.random_base32()
    user = User(
        email="2fa2@test.local",
        password_hash=hash_password("test1234!"),
        display_name="2FA User 2",
        role="admin",
        totp_secret=secret,
        totp_enabled=True,
    )
    session.add(user)
    session.commit()

    resp = client.post(
        "/api/v1/auth/login",
        json={"email": "2fa2@test.local", "password": "test1234!"},
    )
    temp_token = resp.json()["data"]["temp_token"]

    resp = client.post(
        "/api/v1/auth/verify-2fa",
        json={"temp_token": temp_token, "totp_code": "000000"},
    )
    assert resp.status_code == 401
