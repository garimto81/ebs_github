def test_list_users_admin(client, auth_headers, admin_user):
    resp = client.get("/api/v1/users", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["meta"]["total"] >= 1


def test_list_users_forbidden(client, viewer_headers):
    resp = client.get("/api/v1/users", headers=viewer_headers)
    assert resp.status_code == 403


def test_create_user(client, auth_headers):
    resp = client.post("/api/v1/users", headers=auth_headers, json={
        "email": "new@test.local",
        "password": "newpass123!",
        "display_name": "New User",
        "role": "viewer",
    })
    assert resp.status_code == 201
    data = resp.json()["data"]
    assert data["email"] == "new@test.local"
    assert data["role"] == "viewer"


def test_create_user_duplicate_email(client, auth_headers, admin_user):
    import pytest
    from sqlalchemy.exc import IntegrityError
    with pytest.raises(IntegrityError):
        client.post("/api/v1/users", headers=auth_headers, json={
            "email": "admin@test.local",
            "password": "dup_pass!",
            "display_name": "Duplicate",
        })


def test_get_user(client, auth_headers, admin_user):
    resp = client.get(f"/api/v1/users/{admin_user.user_id}", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["data"]["email"] == "admin@test.local"


def test_get_user_not_found(client, auth_headers):
    resp = client.get("/api/v1/users/9999", headers=auth_headers)
    assert resp.status_code == 404


def test_update_user(client, auth_headers, admin_user):
    resp = client.put(f"/api/v1/users/{admin_user.user_id}", headers=auth_headers, json={
        "display_name": "Updated Admin",
    })
    assert resp.status_code == 200
    assert resp.json()["data"]["display_name"] == "Updated Admin"


def test_delete_user(client, auth_headers):
    # Create then delete
    create = client.post("/api/v1/users", headers=auth_headers, json={
        "email": "delete_me@test.local",
        "password": "pass123!",
        "display_name": "Delete Me",
    })
    uid = create.json()["data"]["user_id"]
    resp = client.delete(f"/api/v1/users/{uid}", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["data"]["deleted"] is True


def test_unauthorized(client):
    resp = client.get("/api/v1/users")
    assert resp.status_code in (401, 403)
