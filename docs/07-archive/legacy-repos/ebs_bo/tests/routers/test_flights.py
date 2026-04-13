def test_list_flights(client, auth_headers):
    resp = client.get("/api/v1/flights", headers=auth_headers)
    assert resp.status_code == 200


def test_create_flight(client, auth_headers, hierarchy):
    resp = client.post("/api/v1/flights", headers=auth_headers, json={
        "display_name": "Day 1B",
        "event_id": hierarchy["event"].event_id,
    })
    assert resp.status_code == 201
    assert resp.json()["data"]["display_name"] == "Day 1B"


def test_get_flight(client, auth_headers, hierarchy):
    fid = hierarchy["flight"].event_flight_id
    resp = client.get(f"/api/v1/flights/{fid}", headers=auth_headers)
    assert resp.status_code == 200


def test_get_flight_not_found(client, auth_headers):
    resp = client.get("/api/v1/flights/9999", headers=auth_headers)
    assert resp.status_code == 404


def test_filter_by_event_id(client, auth_headers, hierarchy):
    eid = hierarchy["event"].event_id
    resp = client.get(f"/api/v1/flights?event_id={eid}", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["meta"]["total"] >= 1


def test_update_flight(client, auth_headers, hierarchy):
    fid = hierarchy["flight"].event_flight_id
    resp = client.put(f"/api/v1/flights/{fid}", headers=auth_headers, json={
        "display_name": "Updated Flight",
    })
    assert resp.status_code == 200
    assert resp.json()["data"]["display_name"] == "Updated Flight"


def test_delete_flight(client, auth_headers, hierarchy):
    create = client.post("/api/v1/flights", headers=auth_headers, json={
        "display_name": "Delete Me",
        "event_id": hierarchy["event"].event_id,
    })
    fid = create.json()["data"]["event_flight_id"]
    resp = client.delete(f"/api/v1/flights/{fid}", headers=auth_headers)
    assert resp.status_code == 200


def test_unauthorized(client):
    resp = client.get("/api/v1/flights")
    assert resp.status_code in (401, 403)


def test_viewer_cannot_create(client, viewer_headers, hierarchy):
    resp = client.post("/api/v1/flights", headers=viewer_headers, json={
        "display_name": "Blocked",
        "event_id": hierarchy["event"].event_id,
    })
    assert resp.status_code == 403
