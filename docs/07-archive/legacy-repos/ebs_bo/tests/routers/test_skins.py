def test_list_skins(client, auth_headers):
    resp = client.get("/api/v1/skins", headers=auth_headers)
    assert resp.status_code == 200


def test_create_skin(client, auth_headers):
    resp = client.post("/api/v1/skins", headers=auth_headers, json={
        "name": "Dark Theme",
        "description": "A dark theme",
        "theme_data": '{"bg": "#000"}',
    })
    assert resp.status_code == 201
    assert resp.json()["data"]["name"] == "Dark Theme"


def test_get_skin(client, auth_headers):
    create = client.post("/api/v1/skins", headers=auth_headers, json={
        "name": "Light Theme",
    })
    sid = create.json()["data"]["skin_id"]
    resp = client.get(f"/api/v1/skins/{sid}", headers=auth_headers)
    assert resp.status_code == 200


def test_get_skin_not_found(client, auth_headers):
    resp = client.get("/api/v1/skins/9999", headers=auth_headers)
    assert resp.status_code == 404


def test_update_skin(client, auth_headers):
    create = client.post("/api/v1/skins", headers=auth_headers, json={
        "name": "Update Me",
    })
    sid = create.json()["data"]["skin_id"]
    resp = client.put(f"/api/v1/skins/{sid}", headers=auth_headers, json={
        "name": "Updated Skin",
    })
    assert resp.status_code == 200
    assert resp.json()["data"]["name"] == "Updated Skin"


def test_delete_skin(client, auth_headers):
    create = client.post("/api/v1/skins", headers=auth_headers, json={
        "name": "Delete Me",
    })
    sid = create.json()["data"]["skin_id"]
    resp = client.delete(f"/api/v1/skins/{sid}", headers=auth_headers)
    assert resp.status_code == 200


def test_activate_skin(client, auth_headers):
    c1 = client.post("/api/v1/skins", headers=auth_headers, json={
        "name": "Skin A",
        "is_default": True,
    })
    c2 = client.post("/api/v1/skins", headers=auth_headers, json={
        "name": "Skin B",
    })
    sid_b = c2.json()["data"]["skin_id"]

    resp = client.post(f"/api/v1/skins/{sid_b}/activate", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["data"]["is_default"] is True


def test_unauthorized(client):
    resp = client.get("/api/v1/skins")
    assert resp.status_code in (401, 403)


def test_viewer_cannot_create(client, viewer_headers):
    resp = client.post("/api/v1/skins", headers=viewer_headers, json={
        "name": "Blocked",
    })
    assert resp.status_code == 403
