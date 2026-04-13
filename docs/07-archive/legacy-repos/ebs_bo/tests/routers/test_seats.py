def test_get_seats(client, auth_headers, hierarchy):
    tid = hierarchy["table"].table_id
    resp = client.get(f"/api/v1/tables/{tid}/seats", headers=auth_headers)
    assert resp.status_code == 200
    assert len(resp.json()["data"]) == 9


def test_update_seat_assign_player(client, auth_headers, hierarchy):
    tid = hierarchy["table"].table_id
    pid = hierarchy["player"].player_id
    resp = client.put(f"/api/v1/tables/{tid}/seats/2", headers=auth_headers, json={
        "player_id": pid,
        "player_name": "Phil Ivey",
        "status": "occupied",
    })
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert data["player_id"] == pid
    assert data["status"] == "occupied"


def test_update_seat_clear(client, auth_headers, hierarchy):
    tid = hierarchy["table"].table_id
    resp = client.put(f"/api/v1/tables/{tid}/seats/1", headers=auth_headers, json={
        "player_id": None,
        "player_name": None,
        "status": "vacant",
    })
    assert resp.status_code == 200
    assert resp.json()["data"]["status"] == "vacant"


def test_update_seat_not_found(client, auth_headers, hierarchy):
    tid = hierarchy["table"].table_id
    resp = client.put(f"/api/v1/tables/{tid}/seats/99", headers=auth_headers, json={
        "status": "vacant",
    })
    assert resp.status_code == 404


def test_unauthorized(client, hierarchy):
    tid = hierarchy["table"].table_id
    resp = client.get(f"/api/v1/tables/{tid}/seats")
    assert resp.status_code in (401, 403)


def test_operator_can_update_seat(client, operator_headers, hierarchy):
    tid = hierarchy["table"].table_id
    resp = client.put(f"/api/v1/tables/{tid}/seats/3", headers=operator_headers, json={
        "status": "reserved",
    })
    assert resp.status_code == 200


def test_viewer_cannot_update_seat(client, viewer_headers, hierarchy):
    tid = hierarchy["table"].table_id
    resp = client.put(f"/api/v1/tables/{tid}/seats/1", headers=viewer_headers, json={
        "status": "vacant",
    })
    assert resp.status_code == 403
