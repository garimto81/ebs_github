def test_list_players(client, auth_headers):
    resp = client.get("/api/v1/players", headers=auth_headers)
    assert resp.status_code == 200


def test_create_player(client, auth_headers):
    resp = client.post("/api/v1/players", headers=auth_headers, json={
        "first_name": "Daniel",
        "last_name": "Negreanu",
    })
    assert resp.status_code == 201
    assert resp.json()["data"]["first_name"] == "Daniel"


def test_get_player(client, auth_headers, hierarchy):
    pid = hierarchy["player"].player_id
    resp = client.get(f"/api/v1/players/{pid}", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["data"]["last_name"] == "Ivey"


def test_get_player_not_found(client, auth_headers):
    resp = client.get("/api/v1/players/9999", headers=auth_headers)
    assert resp.status_code == 404


def test_update_player(client, auth_headers, hierarchy):
    pid = hierarchy["player"].player_id
    resp = client.put(f"/api/v1/players/{pid}", headers=auth_headers, json={
        "nationality": "US",
    })
    assert resp.status_code == 200


def test_delete_player(client, auth_headers):
    create = client.post("/api/v1/players", headers=auth_headers, json={
        "first_name": "Delete",
        "last_name": "Me",
    })
    pid = create.json()["data"]["player_id"]
    resp = client.delete(f"/api/v1/players/{pid}", headers=auth_headers)
    assert resp.status_code == 200


def test_search_players(client, auth_headers, hierarchy):
    resp = client.get("/api/v1/players/search?q=Ivey", headers=auth_headers)
    assert resp.status_code == 200
    assert len(resp.json()["data"]) >= 1


def test_search_players_no_match(client, auth_headers):
    resp = client.get("/api/v1/players/search?q=zzzzzzzzz", headers=auth_headers)
    assert resp.status_code == 200
    assert len(resp.json()["data"]) == 0


def test_unauthorized(client):
    resp = client.get("/api/v1/players")
    assert resp.status_code in (401, 403)


def test_viewer_cannot_create(client, viewer_headers):
    resp = client.post("/api/v1/players", headers=viewer_headers, json={
        "first_name": "Blocked",
        "last_name": "User",
    })
    assert resp.status_code == 403


def test_operator_can_update(client, operator_headers, hierarchy):
    pid = hierarchy["player"].player_id
    resp = client.put(f"/api/v1/players/{pid}", headers=operator_headers, json={
        "nationality": "CA",
    })
    assert resp.status_code == 200
