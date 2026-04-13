def test_list_tables(client, auth_headers):
    resp = client.get("/api/v1/tables", headers=auth_headers)
    assert resp.status_code == 200


def test_create_table(client, auth_headers, hierarchy):
    resp = client.post("/api/v1/tables", headers=auth_headers, json={
        "name": "Table 2",
        "event_flight_id": hierarchy["flight"].event_flight_id,
        "table_no": 2,
    })
    assert resp.status_code == 201
    assert resp.json()["data"]["name"] == "Table 2"


def test_get_table(client, auth_headers, hierarchy):
    tid = hierarchy["table"].table_id
    resp = client.get(f"/api/v1/tables/{tid}", headers=auth_headers)
    assert resp.status_code == 200


def test_get_table_not_found(client, auth_headers):
    resp = client.get("/api/v1/tables/9999", headers=auth_headers)
    assert resp.status_code == 404


def test_filter_by_flight_id(client, auth_headers, hierarchy):
    fid = hierarchy["flight"].event_flight_id
    resp = client.get(f"/api/v1/tables?flight_id={fid}", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["meta"]["total"] >= 1


def test_update_table(client, auth_headers, hierarchy):
    tid = hierarchy["table"].table_id
    resp = client.put(f"/api/v1/tables/{tid}", headers=auth_headers, json={
        "name": "Updated Table",
    })
    assert resp.status_code == 200
    assert resp.json()["data"]["name"] == "Updated Table"


def test_delete_table(client, auth_headers, hierarchy):
    create = client.post("/api/v1/tables", headers=auth_headers, json={
        "name": "Delete Me",
        "event_flight_id": hierarchy["flight"].event_flight_id,
        "table_no": 99,
    })
    tid = create.json()["data"]["table_id"]
    resp = client.delete(f"/api/v1/tables/{tid}", headers=auth_headers)
    assert resp.status_code == 200


def test_launch_cc(client, auth_headers, hierarchy):
    tid = hierarchy["table"].table_id
    resp = client.post(f"/api/v1/tables/{tid}/launch-cc", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert data["status"] == "live"
    assert "cc_instance_id" in data


def test_get_table_status(client, auth_headers, hierarchy):
    tid = hierarchy["table"].table_id
    resp = client.get(f"/api/v1/tables/{tid}/status", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert "status" in data
    assert "deck_registered" in data


def test_unauthorized(client):
    resp = client.get("/api/v1/tables")
    assert resp.status_code in (401, 403)


def test_viewer_cannot_create(client, viewer_headers, hierarchy):
    resp = client.post("/api/v1/tables", headers=viewer_headers, json={
        "name": "Blocked",
        "event_flight_id": hierarchy["flight"].event_flight_id,
        "table_no": 50,
    })
    assert resp.status_code == 403
