def test_list_series(client, auth_headers):
    resp = client.get("/api/v1/series", headers=auth_headers)
    assert resp.status_code == 200


def test_create_series(client, auth_headers, hierarchy):
    comp = hierarchy["competition"]
    resp = client.post("/api/v1/series", headers=auth_headers, json={
        "series_name": "Summer Series",
        "competition_id": comp.competition_id,
        "year": 2026,
        "begin_at": "2026-06-01T00:00:00Z",
        "end_at": "2026-07-15T00:00:00Z",
    })
    assert resp.status_code == 201
    assert resp.json()["data"]["series_name"] == "Summer Series"


def test_get_series(client, auth_headers, hierarchy):
    sid = hierarchy["series"].series_id
    resp = client.get(f"/api/v1/series/{sid}", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["data"]["series_name"] == "Main Series"


def test_get_series_not_found(client, auth_headers):
    resp = client.get("/api/v1/series/9999", headers=auth_headers)
    assert resp.status_code == 404


def test_filter_by_competition_id(client, auth_headers, hierarchy):
    cid = hierarchy["competition"].competition_id
    resp = client.get(f"/api/v1/series?competition_id={cid}", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["meta"]["total"] >= 1


def test_update_series(client, auth_headers, hierarchy):
    sid = hierarchy["series"].series_id
    resp = client.put(f"/api/v1/series/{sid}", headers=auth_headers, json={
        "series_name": "Updated Series",
    })
    assert resp.status_code == 200
    assert resp.json()["data"]["series_name"] == "Updated Series"


def test_delete_series(client, auth_headers, hierarchy):
    comp = hierarchy["competition"]
    create = client.post("/api/v1/series", headers=auth_headers, json={
        "series_name": "Delete Me",
        "competition_id": comp.competition_id,
        "year": 2026,
        "begin_at": "2026-01-01T00:00:00Z",
        "end_at": "2026-12-31T00:00:00Z",
    })
    sid = create.json()["data"]["series_id"]
    resp = client.delete(f"/api/v1/series/{sid}", headers=auth_headers)
    assert resp.status_code == 200


def test_unauthorized(client):
    resp = client.get("/api/v1/series")
    assert resp.status_code in (401, 403)


def test_viewer_cannot_create(client, viewer_headers, hierarchy):
    resp = client.post("/api/v1/series", headers=viewer_headers, json={
        "series_name": "Blocked",
        "competition_id": hierarchy["competition"].competition_id,
        "year": 2026,
        "begin_at": "2026-01-01T00:00:00Z",
        "end_at": "2026-12-31T00:00:00Z",
    })
    assert resp.status_code == 403
