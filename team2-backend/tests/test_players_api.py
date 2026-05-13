"""Cycle 21 — Players API contract v1.0.0 tests.

Spec: docs/2. Development/2.2 Backend/APIs/Players_HandHistory_API.md §2.1 + §2.2

Coverage:
  - test_list_players_pagination_cursor
  - test_list_players_filter_nationality
  - test_list_players_search_by_name
  - test_player_detail_404
  - test_player_detail_success
  - test_player_detail_include_stats
  - test_cursor_pagination_stable
  - test_invalid_cursor_400
"""
from __future__ import annotations

from sqlmodel import Session
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


def _seed_players(db_session: Session, count: int = 10) -> list[Player]:
    out: list[Player] = []
    for i in range(count):
        p = Player(
            first_name=f"First{i:02d}",
            last_name=f"Last{i:02d}",
            country_code="USA" if i % 2 == 0 else "CAN",
            player_status="active" if i < 7 else "eliminated",
            source="manual",
            wsop_id=f"WSOP-{1000+i}",
        )
        db_session.add(p)
        out.append(p)
    db_session.commit()
    for p in out:
        db_session.refresh(p)
    return out


# ── 1. Cursor pagination ─────────────────────────────


def test_list_players_pagination_cursor(client, seed_users, db_session):
    """limit=3 로 페이지 분할 + next_cursor 로 이어가기 → 총 10 명 모두 회수."""
    _seed_players(db_session, count=10)
    headers = _auth(client, "admin")

    page1 = client.get("/api/v1/players?limit=3", headers=headers).json()
    assert len(page1["items"]) == 3
    assert page1["hasMore"] is True
    assert page1["nextCursor"] is not None

    page2 = client.get(
        f"/api/v1/players?limit=3&cursor={page1['nextCursor']}", headers=headers
    ).json()
    assert len(page2["items"]) == 3
    assert page2["hasMore"] is True
    # 페이지 간 중복 없음
    assert {i["playerId"] for i in page1["items"]} & {i["playerId"] for i in page2["items"]} == set()

    page3 = client.get(
        f"/api/v1/players?limit=5&cursor={page2['nextCursor']}", headers=headers
    ).json()
    assert len(page3["items"]) == 4
    assert page3["hasMore"] is False
    assert page3["nextCursor"] is None


# ── 2. Filter by nationality ─────────────────────────


def test_list_players_filter_nationality(client, seed_users, db_session):
    _seed_players(db_session, count=10)
    headers = _auth(client, "admin")

    resp = client.get("/api/v1/players?nationality=USA&limit=100", headers=headers).json()
    assert all(it["countryCode"] == "USA" for it in resp["items"])
    assert len(resp["items"]) == 5  # i=0,2,4,6,8


# ── 3. Search by name ────────────────────────────────


def test_list_players_search_by_name(client, seed_users, db_session):
    _seed_players(db_session, count=10)
    headers = _auth(client, "admin")

    # first_name ILIKE
    resp = client.get("/api/v1/players?search=First03", headers=headers).json()
    assert len(resp["items"]) == 1
    assert resp["items"][0]["firstName"] == "First03"

    # wsop_id ILIKE
    resp = client.get("/api/v1/players?search=WSOP-1007", headers=headers).json()
    assert len(resp["items"]) == 1
    assert resp["items"][0]["wsopId"] == "WSOP-1007"


# ── 4. Filter by player_status ──────────────────────


def test_list_players_filter_status(client, seed_users, db_session):
    _seed_players(db_session, count=10)
    headers = _auth(client, "admin")

    resp = client.get("/api/v1/players?player_status=eliminated", headers=headers).json()
    assert len(resp["items"]) == 3  # i=7,8,9
    assert all(it["playerStatus"] == "eliminated" for it in resp["items"])


# ── 5. Detail — 404 ──────────────────────────────────


def test_player_detail_404(client, seed_users):
    headers = _auth(client, "admin")
    resp = client.get("/api/v1/players/99999", headers=headers)
    assert resp.status_code == 404
    assert resp.json()["detail"]["code"] == "RESOURCE_NOT_FOUND"


# ── 6. Detail — success without stats ───────────────


def test_player_detail_success(client, seed_users, db_session):
    p = _seed_players(db_session, count=1)[0]
    headers = _auth(client, "admin")

    resp = client.get(f"/api/v1/players/{p.player_id}", headers=headers)
    assert resp.status_code == 200
    body = resp.json()
    assert body["playerId"] == p.player_id
    assert body["firstName"] == "First00"
    assert body.get("stats") is None


# ── 7. Detail — include_stats ────────────────────────


def test_player_detail_include_stats(client, seed_users, db_session):
    """player 가 hand 에 참여한 경우 stats 계산."""
    players = _seed_players(db_session, count=2)
    p = players[0]
    headers = _auth(client, "admin")

    # 최소 시드: table + 1 hand + 1 hand_player + 2 actions
    # event_flight_id 는 SQLite test 환경에서 FK 미강제 → raw int 사용
    t = Table(name="T1", table_no=1, type="general", max_players=9, event_flight_id=1)
    db_session.add(t)
    db_session.commit()
    db_session.refresh(t)

    h = Hand(
        table_id=t.table_id,
        hand_number=1,
        started_at="2026-05-13T10:00:00Z",
        ended_at="2026-05-13T10:01:00Z",
        duration_sec=60,
    )
    db_session.add(h)
    db_session.commit()
    db_session.refresh(h)

    hp = HandPlayer(
        hand_id=h.hand_id,
        seat_no=1,
        player_id=p.player_id,
        player_name=f"{p.first_name} {p.last_name}",
        start_stack=10000,
        end_stack=12000,
        is_winner=1,
        pnl=2000,
        vpip=1,
        pfr=1,
    )
    db_session.add(hp)
    db_session.add(
        HandAction(hand_id=h.hand_id, seat_no=1, action_type="raise", action_amount=200,
                   street="preflop", action_order=1)
    )
    db_session.add(
        HandAction(hand_id=h.hand_id, seat_no=1, action_type="call", action_amount=100,
                   street="flop", action_order=2)
    )
    db_session.commit()

    resp = client.get(
        f"/api/v1/players/{p.player_id}?include_stats=true", headers=headers
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["stats"]["totalHands"] == 1
    assert body["stats"]["wins"] == 1
    assert body["stats"]["cumulativePnl"] == 2000
    assert body["stats"]["vpipPct"] == 100.0
    assert body["stats"]["pfrPct"] == 100.0
    assert body["stats"]["agrPct"] == 50.0  # 1 raise / (1 raise + 1 call)


# ── 8. Cursor stability across new inserts ──────────


def test_cursor_pagination_stable(client, seed_users, db_session):
    """페이지 1 회수 후 새 player 추가해도 cursor 가 페이지 2 의 의미를 보존."""
    _seed_players(db_session, count=5)
    headers = _auth(client, "admin")

    page1 = client.get("/api/v1/players?limit=2", headers=headers).json()
    page1_ids = [it["playerId"] for it in page1["items"]]
    cursor = page1["nextCursor"]

    # 새 player 추가 (cursor 위쪽 — 더 큰 player_id)
    new_p = Player(first_name="New", last_name="Player", source="manual", player_status="active")
    db_session.add(new_p)
    db_session.commit()

    # cursor 가 player_id 기반 < cursor 라 새 player 는 page2 에 안 들어가야 함
    page2 = client.get(
        f"/api/v1/players?limit=10&cursor={cursor}", headers=headers
    ).json()
    page2_ids = [it["playerId"] for it in page2["items"]]
    assert set(page1_ids) & set(page2_ids) == set()
    assert new_p.player_id not in page2_ids


# ── 9. Invalid cursor → 400 ──────────────────────────


def test_invalid_cursor_400(client, seed_users, db_session):
    _seed_players(db_session, count=1)
    headers = _auth(client, "admin")

    resp = client.get("/api/v1/players?cursor=not-a-valid-base64!!!", headers=headers)
    assert resp.status_code == 400
    assert resp.json()["detail"]["code"] == "INVALID_CURSOR"
