def test_trigger_sync(client, auth_headers):
    resp = client.post("/api/v1/sync/wsop-live", headers=auth_headers)
    assert resp.status_code == 202
    data = resp.json()["data"]
    assert data["status"] == "accepted"
    assert "message" in data


def test_get_sync_status(client, auth_headers):
    resp = client.get("/api/v1/sync/wsop-live/status", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert data["status"] == "idle"


def test_trigger_sync_unauthorized(client):
    resp = client.post("/api/v1/sync/wsop-live")
    assert resp.status_code in (401, 403)


def test_get_sync_status_unauthorized(client):
    resp = client.get("/api/v1/sync/wsop-live/status")
    assert resp.status_code in (401, 403)


def test_viewer_cannot_trigger_sync(client, viewer_headers):
    resp = client.post("/api/v1/sync/wsop-live", headers=viewer_headers)
    assert resp.status_code == 403


def test_viewer_cannot_view_status(client, viewer_headers):
    resp = client.get("/api/v1/sync/wsop-live/status", headers=viewer_headers)
    assert resp.status_code == 403
