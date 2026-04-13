def test_list_blind_structures(client, auth_headers):
    resp = client.get("/api/v1/blind-structures", headers=auth_headers)
    assert resp.status_code == 200


def test_create_with_levels(client, auth_headers):
    resp = client.post("/api/v1/blind-structures", headers=auth_headers, json={
        "name": "Standard",
        "levels": [
            {"level_no": 1, "small_blind": 25, "big_blind": 50, "ante": 0, "duration_minutes": 20},
            {"level_no": 2, "small_blind": 50, "big_blind": 100, "ante": 0, "duration_minutes": 20},
        ],
    })
    assert resp.status_code == 201
    assert resp.json()["data"]["name"] == "Standard"


def test_get_with_levels(client, auth_headers):
    create = client.post("/api/v1/blind-structures", headers=auth_headers, json={
        "name": "Turbo",
        "levels": [
            {"level_no": 1, "small_blind": 50, "big_blind": 100, "ante": 10, "duration_minutes": 10},
        ],
    })
    bs_id = create.json()["data"]["blind_structure_id"]
    resp = client.get(f"/api/v1/blind-structures/{bs_id}", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert "levels" in data
    assert len(data["levels"]) == 1


def test_get_not_found(client, auth_headers):
    resp = client.get("/api/v1/blind-structures/9999", headers=auth_headers)
    assert resp.status_code == 404


def test_update_with_levels(client, auth_headers):
    create = client.post("/api/v1/blind-structures", headers=auth_headers, json={
        "name": "Update Me",
        "levels": [
            {"level_no": 1, "small_blind": 25, "big_blind": 50, "ante": 0, "duration_minutes": 20},
        ],
    })
    bs_id = create.json()["data"]["blind_structure_id"]
    resp = client.put(f"/api/v1/blind-structures/{bs_id}", headers=auth_headers, json={
        "name": "Updated BS",
        "levels": [
            {"level_no": 1, "small_blind": 100, "big_blind": 200, "ante": 25, "duration_minutes": 15},
            {"level_no": 2, "small_blind": 200, "big_blind": 400, "ante": 50, "duration_minutes": 15},
        ],
    })
    assert resp.status_code == 200
    assert resp.json()["data"]["name"] == "Updated BS"


def test_delete(client, auth_headers):
    create = client.post("/api/v1/blind-structures", headers=auth_headers, json={
        "name": "Delete Me",
    })
    bs_id = create.json()["data"]["blind_structure_id"]
    resp = client.delete(f"/api/v1/blind-structures/{bs_id}", headers=auth_headers)
    assert resp.status_code == 200


def test_unauthorized(client):
    resp = client.get("/api/v1/blind-structures")
    assert resp.status_code in (401, 403)


def test_viewer_cannot_create(client, viewer_headers):
    resp = client.post("/api/v1/blind-structures", headers=viewer_headers, json={
        "name": "Blocked",
    })
    assert resp.status_code == 403
