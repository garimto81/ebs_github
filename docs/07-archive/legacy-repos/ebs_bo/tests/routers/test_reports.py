from bo.db.models import Hand, HandAction, HandPlayer


def _seed_report_data(session, table_id):
    hand = Hand(
        table_id=table_id,
        hand_number=1,
        pot_total=3000,
        started_at="2026-06-01T12:00:00Z",
        duration_sec=120,
    )
    session.add(hand)
    session.commit()
    session.refresh(hand)

    hp = HandPlayer(
        hand_id=hand.hand_id,
        seat_no=1,
        player_name="Test Player",
        vpip=True,
        pfr=False,
    )
    session.add(hp)

    action = HandAction(
        hand_id=hand.hand_id,
        seat_no=1,
        action_type="call",
        action_amount=500,
        street="preflop",
        action_order=1,
    )
    session.add(action)
    session.commit()


def test_hands_summary(client, auth_headers, hierarchy, session):
    _seed_report_data(session, hierarchy["table"].table_id)
    resp = client.get("/api/v1/reports/hands-summary", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert data["report_type"] == "hands-summary"
    assert len(data["data"]) >= 1


def test_player_stats(client, auth_headers, hierarchy, session):
    _seed_report_data(session, hierarchy["table"].table_id)
    resp = client.get("/api/v1/reports/player-stats", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert data["report_type"] == "player-stats"


def test_table_activity(client, auth_headers, hierarchy, session):
    _seed_report_data(session, hierarchy["table"].table_id)
    resp = client.get("/api/v1/reports/table-activity", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert data["report_type"] == "table-activity"


def test_session_log(client, auth_headers):
    resp = client.get("/api/v1/reports/session-log", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert data["report_type"] == "session-log"


def test_invalid_report_type(client, auth_headers):
    resp = client.get("/api/v1/reports/invalid-type", headers=auth_headers)
    assert resp.status_code == 400


def test_unauthorized(client):
    resp = client.get("/api/v1/reports/hands-summary")
    assert resp.status_code in (401, 403)


def test_viewer_cannot_access(client, viewer_headers):
    resp = client.get("/api/v1/reports/hands-summary", headers=viewer_headers)
    assert resp.status_code == 403
