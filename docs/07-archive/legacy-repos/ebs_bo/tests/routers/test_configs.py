from bo.db.models import Config


def _seed_config(session):
    c1 = Config(key="theme_color", value="#FF0000", category="display")
    c2 = Config(key="font_size", value="14", category="display")
    session.add(c1)
    session.add(c2)
    session.commit()


def test_get_config_section(client, auth_headers, session):
    _seed_config(session)
    resp = client.get("/api/v1/configs/display", headers=auth_headers)
    assert resp.status_code == 200
    assert len(resp.json()["data"]) >= 2


def test_get_config_empty_section(client, auth_headers):
    resp = client.get("/api/v1/configs/nonexistent", headers=auth_headers)
    assert resp.status_code == 200
    assert len(resp.json()["data"]) == 0


def test_update_config_section(client, auth_headers, session):
    _seed_config(session)
    resp = client.put("/api/v1/configs/display", headers=auth_headers, json={
        "values": {"theme_color": "#00FF00", "new_key": "new_value"},
    })
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert len(data) >= 2


def test_update_config_creates_new(client, auth_headers):
    resp = client.put("/api/v1/configs/new_section", headers=auth_headers, json={
        "values": {"key1": "val1"},
    })
    assert resp.status_code == 200
    assert len(resp.json()["data"]) == 1


def test_unauthorized(client):
    resp = client.get("/api/v1/configs/display")
    assert resp.status_code in (401, 403)


def test_viewer_cannot_access(client, viewer_headers):
    resp = client.get("/api/v1/configs/display", headers=viewer_headers)
    assert resp.status_code == 403
