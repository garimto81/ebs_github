def test_list_competitions(client, auth_headers):
    resp = client.get("/api/v1/competitions", headers=auth_headers)
    assert resp.status_code == 200
    assert "data" in resp.json()


def test_create_competition(client, auth_headers):
    resp = client.post("/api/v1/competitions", headers=auth_headers, json={
        "name": "WSOP 2026",
        "competition_type": 1,
    })
    assert resp.status_code == 201
    assert resp.json()["data"]["name"] == "WSOP 2026"


def test_get_competition(client, auth_headers):
    create = client.post("/api/v1/competitions", headers=auth_headers, json={
        "name": "Test Comp",
    })
    cid = create.json()["data"]["competition_id"]
    resp = client.get(f"/api/v1/competitions/{cid}", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["data"]["name"] == "Test Comp"


def test_get_competition_not_found(client, auth_headers):
    resp = client.get("/api/v1/competitions/9999", headers=auth_headers)
    assert resp.status_code == 404


def test_update_competition(client, auth_headers):
    create = client.post("/api/v1/competitions", headers=auth_headers, json={
        "name": "Old Name",
    })
    cid = create.json()["data"]["competition_id"]
    resp = client.put(f"/api/v1/competitions/{cid}", headers=auth_headers, json={
        "name": "New Name",
    })
    assert resp.status_code == 200
    assert resp.json()["data"]["name"] == "New Name"


def test_delete_competition(client, auth_headers):
    create = client.post("/api/v1/competitions", headers=auth_headers, json={
        "name": "Delete Me",
    })
    cid = create.json()["data"]["competition_id"]
    resp = client.delete(f"/api/v1/competitions/{cid}", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["data"]["deleted"] is True


def test_unauthorized(client):
    resp = client.get("/api/v1/competitions")
    assert resp.status_code in (401, 403)


def test_viewer_can_read(client, viewer_headers):
    resp = client.get("/api/v1/competitions", headers=viewer_headers)
    assert resp.status_code == 200


def test_viewer_cannot_create(client, viewer_headers):
    resp = client.post("/api/v1/competitions", headers=viewer_headers, json={
        "name": "Blocked",
    })
    assert resp.status_code == 403
