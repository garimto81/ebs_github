"""chip_count_state GET endpoint 테스트 — SG-042 PR-A Area 3.

SSOT: docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md §5.17.18
Contract: docs/2. Development/2.2 Backend/APIs/WSOP_LIVE_Chip_Count_Sync.md

GET /api/wsop-live/chip-count-state/{table_id}
- 마지막 동기화 상태 + seat_states + total_chips
- 인증: Admin/Operator only
- 스냅샷 없는 경우 404
"""
from __future__ import annotations

import uuid
from datetime import datetime, timezone

import pytest
from fastapi.testclient import TestClient
from sqlmodel import Session

from src.models.chip_count_snapshot import ChipCountSnapshot


# ── 헬퍼 ─────────────────────────────────────────────────────────────────────


def _utcnow() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def _seed_table(db: Session) -> int:
    """competition/series/event/flight/table 계층 생성 → table_id 반환."""
    from src.models.competition import Competition, Event, EventFlight, Series
    from src.models.table import Table

    comp = Competition(name="ChipState Comp")
    db.add(comp)
    db.commit()
    db.refresh(comp)

    series = Series(
        competition_id=comp.competition_id,
        series_name="CS-Test",
        year=2026,
        begin_at="2026-05-01",
        end_at="2026-05-30",
    )
    db.add(series)
    db.commit()
    db.refresh(series)

    event = Event(
        series_id=series.series_id,
        event_no=1,
        event_name="E-CS",
        buy_in=500,
    )
    db.add(event)
    db.commit()
    db.refresh(event)

    flight = EventFlight(event_id=event.event_id, display_name="Day 1A")
    db.add(flight)
    db.commit()
    db.refresh(flight)

    table = Table(event_flight_id=flight.event_flight_id, table_no=1, name="T-CS")
    db.add(table)
    db.commit()
    db.refresh(table)
    return table.table_id


def _insert_snapshot(
    db: Session,
    table_id: int,
    *,
    break_id: int = 100,
    snapshot_id: str | None = None,
    recorded_at: str | None = None,
    received_at: str | None = None,
    seats: list[tuple[int, int | None, int]] | None = None,  # (seat_no, player_id, chips)
) -> str:
    snap_id = snapshot_id or str(uuid.uuid4())
    rec = recorded_at or _utcnow()
    rcv = received_at or _utcnow()
    raw = "{}"

    for seat_no, player_id, chips in (seats or [(1, None, 10000)]):
        row = ChipCountSnapshot(
            snapshot_id=snap_id,
            table_id=table_id,
            seat_number=seat_no,
            player_id=player_id,
            chip_count=chips,
            break_id=break_id,
            source="test",
            recorded_at=rec,
            received_at=rcv,
            signature_ok=True,
            raw_payload=raw,
        )
        db.add(row)
    db.commit()
    return snap_id


def _get_token(client: TestClient, role: str = "admin") -> str:
    from src.models.user import User
    from src.security.password import hash_password

    email = f"{role}_state@test.com"
    # user seeding은 conftest가 자동 처리하므로 여기서 추가 seed 필요
    # — 간단히 직접 생성
    from src.app.database import get_engine
    from sqlmodel import Session as _Ses

    with _Ses(get_engine()) as s:
        existing = s.exec(
            __import__("sqlmodel").select(User).where(User.email == email)
        ).first()
        if not existing:
            u = User(
                email=email,
                display_name=f"{role.title()} State",
                role=role,
                password_hash=hash_password("Test123!"),
                is_active=True,
            )
            s.add(u)
            s.commit()

    resp = client.post("/api/v1/auth/login", json={"email": email, "password": "Test123!"})
    assert resp.status_code == 200, resp.text
    return resp.json()["data"]["accessToken"]


# ── 테스트 ────────────────────────────────────────────────────────────────────


class TestChipCountStateNotFound:
    """스냅샷 없는 table_id → 404."""

    def test_no_snapshot_returns_404(self, client: TestClient, db_session: Session):
        table_id = _seed_table(db_session)
        token = _get_token(client, "admin")

        resp = client.get(
            f"/api/wsop-live/chip-count-state/{table_id}",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 404
        data = resp.json()
        assert data["error"] == "NO_SNAPSHOT"


class TestChipCountStateSuccess:
    """스냅샷 있는 경우 — 최신 데이터 반환."""

    def test_returns_latest_snapshot(self, client: TestClient, db_session: Session):
        table_id = _seed_table(db_session)
        snap_id = _insert_snapshot(
            db_session,
            table_id,
            break_id=200,
            seats=[(1, 10, 50000), (2, 11, 30000)],
        )
        token = _get_token(client, "admin")

        resp = client.get(
            f"/api/wsop-live/chip-count-state/{table_id}",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["table_id"] == table_id
        assert data["last_snapshot_id"] == snap_id
        assert data["break_id"] == 200
        assert data["total_chips"] == 80000
        seats = {s["seat_number"]: s for s in data["seat_states"]}
        assert seats[1]["chip_count"] == 50000
        assert seats[2]["chip_count"] == 30000

    def test_multiple_snapshots_returns_latest(
        self, client: TestClient, db_session: Session
    ):
        """여러 스냅샷 중 가장 최신 break_id 기준 반환."""
        table_id = _seed_table(db_session)
        # 이전 스냅샷
        _insert_snapshot(
            db_session,
            table_id,
            break_id=100,
            seats=[(1, 10, 20000)],
        )
        # 최신 스냅샷
        new_snap_id = _insert_snapshot(
            db_session,
            table_id,
            break_id=101,
            seats=[(1, 10, 55000)],
        )

        token = _get_token(client, "admin")
        resp = client.get(
            f"/api/wsop-live/chip-count-state/{table_id}",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["last_snapshot_id"] == new_snap_id
        assert data["break_id"] == 101
        assert data["seat_states"][0]["chip_count"] == 55000

    def test_operator_can_access(self, client: TestClient, db_session: Session):
        table_id = _seed_table(db_session)
        _insert_snapshot(db_session, table_id)
        token = _get_token(client, "operator")

        resp = client.get(
            f"/api/wsop-live/chip-count-state/{table_id}",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200


class TestChipCountStateAuth:
    """인증 / RBAC 검사."""

    def test_unauthenticated_returns_401(self, client: TestClient, db_session: Session):
        table_id = _seed_table(db_session)
        _insert_snapshot(db_session, table_id)

        resp = client.get(f"/api/wsop-live/chip-count-state/{table_id}")
        assert resp.status_code == 401

    def test_viewer_cannot_access(self, client: TestClient, db_session: Session):
        table_id = _seed_table(db_session)
        _insert_snapshot(db_session, table_id)
        token = _get_token(client, "viewer")

        resp = client.get(
            f"/api/wsop-live/chip-count-state/{table_id}",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 403


class TestChipCountStateTableNotFound:
    """존재하지 않는 table_id."""

    def test_unknown_table_returns_404(self, client: TestClient, db_session: Session):
        token = _get_token(client, "admin")
        resp = client.get(
            "/api/wsop-live/chip-count-state/99999",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 404
