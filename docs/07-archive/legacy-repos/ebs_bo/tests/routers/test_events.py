def test_list_events(client, auth_headers):
    resp = client.get("/api/v1/events", headers=auth_headers)
    assert resp.status_code == 200


def test_create_event(client, auth_headers, hierarchy):
    resp = client.post("/api/v1/events", headers=auth_headers, json={
        "event_name": "Event #2",
        "series_id": hierarchy["series"].series_id,
        "event_no": 2,
    })
    assert resp.status_code == 201
    assert resp.json()["data"]["event_name"] == "Event #2"


def test_get_event(client, auth_headers, hierarchy):
    eid = hierarchy["event"].event_id
    resp = client.get(f"/api/v1/events/{eid}", headers=auth_headers)
    assert resp.status_code == 200


def test_get_event_not_found(client, auth_headers):
    resp = client.get("/api/v1/events/9999", headers=auth_headers)
    assert resp.status_code == 404


def test_filter_by_series_id(client, auth_headers, hierarchy):
    sid = hierarchy["series"].series_id
    resp = client.get(f"/api/v1/events?series_id={sid}", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["meta"]["total"] >= 1


def test_update_event(client, auth_headers, hierarchy):
    eid = hierarchy["event"].event_id
    resp = client.put(f"/api/v1/events/{eid}", headers=auth_headers, json={
        "event_name": "Updated Event",
    })
    assert resp.status_code == 200
    assert resp.json()["data"]["event_name"] == "Updated Event"


def test_delete_event(client, auth_headers, hierarchy):
    create = client.post("/api/v1/events", headers=auth_headers, json={
        "event_name": "Delete Me",
        "series_id": hierarchy["series"].series_id,
        "event_no": 99,
    })
    eid = create.json()["data"]["event_id"]
    resp = client.delete(f"/api/v1/events/{eid}", headers=auth_headers)
    assert resp.status_code == 200


def test_get_event_flights(client, auth_headers, hierarchy):
    eid = hierarchy["event"].event_id
    resp = client.get(f"/api/v1/events/{eid}/flights", headers=auth_headers)
    assert resp.status_code == 200
    assert len(resp.json()["data"]) >= 1


def test_unauthorized(client):
    resp = client.get("/api/v1/events")
    assert resp.status_code in (401, 403)


def test_viewer_cannot_create(client, viewer_headers, hierarchy):
    resp = client.post("/api/v1/events", headers=viewer_headers, json={
        "event_name": "Blocked",
        "series_id": hierarchy["series"].series_id,
        "event_no": 100,
    })
    assert resp.status_code == 403
