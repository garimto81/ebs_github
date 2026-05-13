"""Cycle 21 — Hands API contract v1.0.0 tests.

Spec: docs/2. Development/2.2 Backend/APIs/Players_HandHistory_API.md §2.3 + §2.4

Coverage:
  - test_list_hands_default
  - test_list_hands_filter_table_id
  - test_list_hands_filter_player_id
  - test_list_hands_filter_flight_id
  - test_list_hands_showdown_only
  - test_list_hands_cursor_pagination
  - test_hand_detail_404
  - test_hand_detail_with_actions
"""
from __future__ import annotations

from sqlmodel import Session
from src.models.competition import Competition, Event, EventFlight, Series
from src.models.hand import Hand, HandAction, HandPlayer
from src.models.table import Player, Table

# ── Helpers ──────────────────────────────────────────


def _login(client, email="admin@test.com", password="Admin123!") -> str:
    resp = client.post("/api/v1/auth/login", json={"email": email, "password": password})
    return resp.json()["data"]["accessToken"]


def _auth(client, role="admin"):
    emails = {"admin": "admin@test.com", "operator": "operator@test.com", "viewer": "viewer@test.com"}
    passwords = {"admin": "Admin123!", "operator": "Op123!", "viewer": "View123!"}
    return {"Authorization": f"Bearer {_login(client, emails[role], passwords[role])}"}


def _seed_hierarchy(db_session: Session, num_tables: int = 2, hands_per_table: int = 3) -> dict:
    """Competition → Series → Event → EventFlight → Tables → Hands(+winner).

    Returns dict with keys: competition, series, event, flight, tables, players, hands
    """
    comp = Competition(name="Test Comp")
    db_session.add(comp)
    db_session.commit()
    db_session.refresh(comp)

    ser = Series(
        competition_id=comp.competition_id,
        series_name="Test Series",
        year=2026,
        begin_at="2026-05-13",
        end_at="2026-05-14",
    )
    db_session.add(ser)
    db_session.commit()
    db_session.refresh(ser)

    ev = Event(
        series_id=ser.series_id,
        event_no=1,
        event_name="Event 1",
        game_type=0,
        bet_structure=0,
    )
    db_session.add(ev)
    db_session.commit()
    db_session.refresh(ev)

    flight = EventFlight(event_id=ev.event_id, display_name="Day 1A")
    db_session.add(flight)
    db_session.commit()
    db_session.refresh(flight)

    tables: list[Table] = []
    for i in range(num_tables):
        t = Table(
            event_flight_id=flight.event_flight_id,
            table_no=i + 1,
            name=f"Table {i+1}",
            type="general",
            max_players=9,
        )
        db_session.add(t)
        tables.append(t)
    db_session.commit()
    for t in tables:
        db_session.refresh(t)

    players: list[Player] = []
    for i in range(3):
        p = Player(
            first_name=f"P{i}",
            last_name=f"Last{i}",
            source="manual",
        )
        db_session.add(p)
        players.append(p)
    db_session.commit()
    for p in players:
        db_session.refresh(p)

    hands: list[Hand] = []
    hand_no = 0
    for t in tables:
        for h_idx in range(hands_per_table):
            hand_no += 1
            # 일부 hands 는 showdown 까지 (board 5 cards), 일부는 preflop only
            is_showdown = (h_idx % 2 == 0)
            board = '["As","Kh","Qd","Js","10c"]' if is_showdown else "[]"
            h = Hand(
                table_id=t.table_id,
                hand_number=hand_no,
                started_at=f"2026-05-13T1{h_idx}:00:00Z",
                ended_at=f"2026-05-13T1{h_idx}:01:00Z" if is_showdown else None,
                duration_sec=60 if is_showdown else 0,
                board_cards=board,
                pot_total=1000 + h_idx * 100,
            )
            db_session.add(h)
            hands.append(h)
    db_session.commit()
    for h in hands:
        db_session.refresh(h)

    # 각 hand 에 player 0 winner, player 1 loser 추가
    for h in hands:
        db_session.add(HandPlayer(
            hand_id=h.hand_id,
            seat_no=1,
            player_id=players[0].player_id,
            player_name=f"{players[0].first_name} {players[0].last_name}",
            is_winner=1,
            pnl=500,
        ))
        db_session.add(HandPlayer(
            hand_id=h.hand_id,
            seat_no=2,
            player_id=players[1].player_id,
            player_name=f"{players[1].first_name} {players[1].last_name}",
            is_winner=0,
            pnl=-500,
        ))
    db_session.commit()

    return {
        "competition": comp,
        "series": ser,
        "event": ev,
        "flight": flight,
        "tables": tables,
        "players": players,
        "hands": hands,
    }


# ── 1. Default list ──────────────────────────────────


def test_list_hands_default(client, seed_users, db_session):
    _seed_hierarchy(db_session, num_tables=2, hands_per_table=3)
    headers = _auth(client, "admin")

    resp = client.get("/api/v1/hands?limit=10", headers=headers)
    assert resp.status_code == 200
    body = resp.json()
    assert "items" in body and "nextCursor" in body and "hasMore" in body
    assert len(body["items"]) == 6  # 2 tables × 3 hands
    # 정렬: hand_id DESC → 최신 hand_number 가 먼저
    hand_nos = [it["handNumber"] for it in body["items"]]
    assert hand_nos == sorted(hand_nos, reverse=True)
    # winner_player_name derive 확인
    assert all(it["winnerPlayerName"] == "P0 Last0" for it in body["items"])


# ── 2. Filter by table_id ───────────────────────────


def test_list_hands_filter_table_id(client, seed_users, db_session):
    seed = _seed_hierarchy(db_session, num_tables=2, hands_per_table=3)
    headers = _auth(client, "admin")
    t1 = seed["tables"][0]

    resp = client.get(f"/api/v1/hands?table_id={t1.table_id}", headers=headers).json()
    assert len(resp["items"]) == 3
    assert all(it["tableId"] == t1.table_id for it in resp["items"])


# ── 3. Filter by player_id ──────────────────────────


def test_list_hands_filter_player_id(client, seed_users, db_session):
    seed = _seed_hierarchy(db_session, num_tables=2, hands_per_table=3)
    headers = _auth(client, "admin")
    p0 = seed["players"][0]

    # p0 는 모든 hand 의 winner → 6 hands 모두 회수
    resp = client.get(f"/api/v1/hands?player_id={p0.player_id}", headers=headers).json()
    assert len(resp["items"]) == 6

    # p2 는 어떤 hand 에도 미참여 → 0
    p2 = seed["players"][2]
    resp = client.get(f"/api/v1/hands?player_id={p2.player_id}", headers=headers).json()
    assert len(resp["items"]) == 0


# ── 4. Filter by flight_id ──────────────────────────


def test_list_hands_filter_flight_id(client, seed_users, db_session):
    seed = _seed_hierarchy(db_session, num_tables=2, hands_per_table=3)
    headers = _auth(client, "admin")

    resp = client.get(
        f"/api/v1/hands?flight_id={seed['flight'].event_flight_id}", headers=headers
    ).json()
    assert len(resp["items"]) == 6  # 모두 같은 flight

    # 존재하지 않는 flight_id
    resp = client.get("/api/v1/hands?flight_id=99999", headers=headers).json()
    assert len(resp["items"]) == 0


# ── 5. showdown_only filter ─────────────────────────


def test_list_hands_showdown_only(client, seed_users, db_session):
    _seed_hierarchy(db_session, num_tables=2, hands_per_table=3)
    headers = _auth(client, "admin")

    # hands_per_table=3 중 h_idx=0,2 만 showdown (h_idx % 2 == 0). 2 tables × 2 = 4 showdown hands
    resp = client.get("/api/v1/hands?showdown_only=true&limit=20", headers=headers).json()
    assert len(resp["items"]) == 4
    assert all(it["endedAt"] is not None for it in resp["items"])


# ── 6. Cursor pagination ────────────────────────────


def test_list_hands_cursor_pagination(client, seed_users, db_session):
    _seed_hierarchy(db_session, num_tables=2, hands_per_table=3)  # 6 hands
    headers = _auth(client, "admin")

    page1 = client.get("/api/v1/hands?limit=2", headers=headers).json()
    assert len(page1["items"]) == 2
    assert page1["hasMore"] is True
    cursor = page1["nextCursor"]

    page2 = client.get(f"/api/v1/hands?limit=2&cursor={cursor}", headers=headers).json()
    assert len(page2["items"]) == 2
    # 중복 없음
    assert (
        {it["handId"] for it in page1["items"]}
        & {it["handId"] for it in page2["items"]}
        == set()
    )

    page3 = client.get(
        f"/api/v1/hands?limit=10&cursor={page2['nextCursor']}", headers=headers
    ).json()
    assert len(page3["items"]) == 2
    assert page3["hasMore"] is False
    assert page3["nextCursor"] is None


# ── 7. Detail — 404 ──────────────────────────────────


def test_hand_detail_404(client, seed_users):
    headers = _auth(client, "admin")
    resp = client.get("/api/v1/hands/99999", headers=headers)
    assert resp.status_code == 404
    assert resp.json()["detail"]["code"] == "RESOURCE_NOT_FOUND"


# ── 8. Detail — nested players + actions ────────────


def test_hand_detail_with_actions(client, seed_users, db_session):
    seed = _seed_hierarchy(db_session, num_tables=1, hands_per_table=1)
    h = seed["hands"][0]
    headers = _auth(client, "admin")

    # actions 시드
    db_session.add(HandAction(
        hand_id=h.hand_id, seat_no=1, action_type="raise", action_amount=200,
        street="preflop", action_order=1,
    ))
    db_session.add(HandAction(
        hand_id=h.hand_id, seat_no=2, action_type="call", action_amount=200,
        street="preflop", action_order=2,
    ))
    db_session.commit()

    resp = client.get(f"/api/v1/hands/{h.hand_id}", headers=headers)
    assert resp.status_code == 200
    body = resp.json()
    assert body["handId"] == h.hand_id
    assert body["tableId"] == h.table_id
    assert len(body["handPlayers"]) == 2
    assert body["handPlayers"][0]["seatNo"] == 1
    assert body["handPlayers"][0]["isWinner"] is True
    assert len(body["handActions"]) == 2
    assert body["handActions"][0]["actionType"] == "raise"
    assert body["handActions"][1]["actionType"] == "call"


# ── 9. Invalid cursor → 400 ──────────────────────────


def test_hands_invalid_cursor_400(client, seed_users, db_session):
    _seed_hierarchy(db_session, num_tables=1, hands_per_table=1)
    headers = _auth(client, "admin")

    resp = client.get("/api/v1/hands?cursor=not-valid-base64!!!", headers=headers)
    assert resp.status_code == 400
    assert resp.json()["detail"]["code"] == "INVALID_CURSOR"
