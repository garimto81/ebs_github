from bo.db.models import Hand, HandAction, HandPlayer


def _seed_hand(session, table_id):
    """Create a hand with players and actions for testing."""
    hand = Hand(
        table_id=table_id,
        hand_number=1,
        game_type=1,
        dealer_seat=1,
        pot_total=5000,
        current_street="river",
        started_at="2026-06-01T12:00:00Z",
        ended_at="2026-06-01T12:05:00Z",
        duration_sec=300,
    )
    session.add(hand)
    session.commit()
    session.refresh(hand)

    hp = HandPlayer(
        hand_id=hand.hand_id,
        seat_no=1,
        player_name="Phil Ivey",
        start_stack=50000,
        end_stack=55000,
        is_winner=True,
        vpip=True,
        pfr=True,
    )
    session.add(hp)

    action = HandAction(
        hand_id=hand.hand_id,
        seat_no=1,
        action_type="raise",
        action_amount=1000,
        street="preflop",
        action_order=1,
    )
    session.add(action)
    session.commit()

    return hand


def test_list_hands(client, auth_headers, hierarchy, session):
    _seed_hand(session, hierarchy["table"].table_id)
    resp = client.get("/api/v1/hands", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["meta"]["total"] >= 1


def test_list_hands_filter_table(client, auth_headers, hierarchy, session):
    _seed_hand(session, hierarchy["table"].table_id)
    tid = hierarchy["table"].table_id
    resp = client.get(f"/api/v1/hands?table_id={tid}", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["meta"]["total"] >= 1


def test_get_hand(client, auth_headers, hierarchy, session):
    hand = _seed_hand(session, hierarchy["table"].table_id)
    resp = client.get(f"/api/v1/hands/{hand.hand_id}", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["data"]["pot_total"] == 5000


def test_get_hand_not_found(client, auth_headers):
    resp = client.get("/api/v1/hands/9999", headers=auth_headers)
    assert resp.status_code == 404


def test_get_hand_actions(client, auth_headers, hierarchy, session):
    hand = _seed_hand(session, hierarchy["table"].table_id)
    resp = client.get(f"/api/v1/hands/{hand.hand_id}/actions", headers=auth_headers)
    assert resp.status_code == 200
    assert len(resp.json()["data"]) >= 1


def test_get_hand_players(client, auth_headers, hierarchy, session):
    hand = _seed_hand(session, hierarchy["table"].table_id)
    resp = client.get(f"/api/v1/hands/{hand.hand_id}/players", headers=auth_headers)
    assert resp.status_code == 200
    assert len(resp.json()["data"]) >= 1


def test_unauthorized(client):
    resp = client.get("/api/v1/hands")
    assert resp.status_code in (401, 403)
