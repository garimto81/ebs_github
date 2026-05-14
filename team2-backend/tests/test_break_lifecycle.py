"""break_lifecycle 서비스 테스트 — SG-042 PR-A Area 2.

SSOT: docs/2. Development/2.2 Backend/Back_Office/Overview.md §3.9.1
Contract: docs/2. Development/2.2 Backend/APIs/WSOP_LIVE_Chip_Count_Sync.md

break_lifecycle.py:
- is_table_chip_count_complete(table_id, break_id, db) → bool
  : 해당 break_id 에 대해 table 의 모든 활성 seat 이 chip count 를 제출했는지 확인
- trigger_break_complete_if_ready(table_id, break_id, db) → bool
  : 완료 시 WS break_table_chip_count_complete 이벤트 트리거 (WS manager 없으면 dry-run)
"""
from __future__ import annotations

import uuid
from datetime import datetime, timezone

import pytest
from sqlmodel import Session

from src.models.chip_count_snapshot import ChipCountSnapshot
from src.services.break_lifecycle import (
    BreakCompleteResult,
    is_table_chip_count_complete,
    trigger_break_complete_if_ready,
)


# ── 헬퍼 ─────────────────────────────────────────────────────────────────────


def _utcnow() -> str:
    return datetime.now(timezone.utc).isoformat()


def _seed_table_with_seats(db: Session, seat_count: int = 3) -> tuple[int, list[int]]:
    """table + TableSeat rows 생성 → (table_id, [seat_numbers]) 반환."""
    from src.models.competition import Competition, Event, EventFlight, Series
    from src.models.table import Table, TableSeat

    comp = Competition(name="BreakLC Comp")
    db.add(comp)
    db.commit()
    db.refresh(comp)

    series = Series(
        competition_id=comp.competition_id,
        series_name="BLC-S",
        year=2026,
        begin_at="2026-05-01",
        end_at="2026-05-30",
    )
    db.add(series)
    db.commit()
    db.refresh(series)

    event = Event(series_id=series.series_id, event_no=1, event_name="BLC-E", buy_in=100)
    db.add(event)
    db.commit()
    db.refresh(event)

    flight = EventFlight(event_id=event.event_id, display_name="Flight BLC")
    db.add(flight)
    db.commit()
    db.refresh(flight)

    table = Table(event_flight_id=flight.event_flight_id, table_no=1, name="T-BLC")
    db.add(table)
    db.commit()
    db.refresh(table)

    seat_numbers = []
    for i in range(1, seat_count + 1):
        seat = TableSeat(
            table_id=table.table_id,
            seat_no=i,
            status="playing",
        )
        db.add(seat)
        seat_numbers.append(i)
    db.commit()
    return table.table_id, seat_numbers


def _add_snapshot(db: Session, table_id: int, break_id: int, seat_number: int,
                  chip_count: int = 10000, player_id: int | None = None) -> None:
    snap_id = str(uuid.uuid4())
    row = ChipCountSnapshot(
        snapshot_id=snap_id,
        table_id=table_id,
        seat_number=seat_number,
        player_id=player_id,
        chip_count=chip_count,
        break_id=break_id,
        source="test",
        recorded_at=_utcnow(),
        received_at=_utcnow(),
        signature_ok=True,
        raw_payload="{}",
    )
    db.add(row)
    db.commit()


# ── is_table_chip_count_complete ──────────────────────────────────────────────


class TestIsTableChipCountComplete:
    """is_table_chip_count_complete(table_id, break_id, db) → bool."""

    def test_no_snapshots_returns_false(self, db_session: Session):
        table_id, _seats = _seed_table_with_seats(db_session, seat_count=3)
        result = is_table_chip_count_complete(table_id, 999, db_session)
        assert result is False

    def test_partial_snapshots_returns_false(self, db_session: Session):
        table_id, seats = _seed_table_with_seats(db_session, seat_count=3)
        break_id = 500
        # seat 1, 2만 제출, seat 3 미제출
        _add_snapshot(db_session, table_id, break_id, seats[0])
        _add_snapshot(db_session, table_id, break_id, seats[1])
        result = is_table_chip_count_complete(table_id, break_id, db_session)
        assert result is False

    def test_all_seats_submitted_returns_true(self, db_session: Session):
        table_id, seats = _seed_table_with_seats(db_session, seat_count=3)
        break_id = 600
        for s in seats:
            _add_snapshot(db_session, table_id, break_id, s)
        result = is_table_chip_count_complete(table_id, break_id, db_session)
        assert result is True

    def test_no_active_seats_returns_false(self, db_session: Session):
        """활성 seat 이 없는 경우 (빈 테이블) — incomplete 처리."""
        from src.models.competition import Competition, Event, EventFlight, Series
        from src.models.table import Table

        comp = Competition(name="Empty Comp")
        db_session.add(comp)
        db_session.commit()
        db_session.refresh(comp)
        series = Series(competition_id=comp.competition_id, series_name="E-S",
                        year=2026, begin_at="2026-05-01", end_at="2026-05-30")
        db_session.add(series)
        db_session.commit()
        db_session.refresh(series)
        event = Event(series_id=series.series_id, event_no=1, event_name="E-E", buy_in=0)
        db_session.add(event)
        db_session.commit()
        db_session.refresh(event)
        flight = EventFlight(event_id=event.event_id, display_name="E-F")
        db_session.add(flight)
        db_session.commit()
        db_session.refresh(flight)
        table = Table(event_flight_id=flight.event_flight_id, table_no=1, name="T-Empty")
        db_session.add(table)
        db_session.commit()
        db_session.refresh(table)

        result = is_table_chip_count_complete(table.table_id, 700, db_session)
        assert result is False

    def test_only_playing_seats_counted(self, db_session: Session):
        """status='empty' seat 은 카운트 대상에서 제외."""
        from src.models.table import TableSeat

        table_id, seats = _seed_table_with_seats(db_session, seat_count=2)
        break_id = 800

        # seat 3 추가 (empty — 제외 대상, seat_no 0-9 범위)
        empty_seat = TableSeat(table_id=table_id, seat_no=9, status="empty")
        db_session.add(empty_seat)
        db_session.commit()

        # playing seat 2개만 제출
        for s in seats:
            _add_snapshot(db_session, table_id, break_id, s)
        # empty seat 에 대한 snapshot 없음

        result = is_table_chip_count_complete(table_id, break_id, db_session)
        assert result is True  # empty seat 무시, playing 2/2 완료


# ── trigger_break_complete_if_ready ──────────────────────────────────────────


class TestTriggerBreakCompleteIfReady:
    """trigger_break_complete_if_ready — incomplete 시 PENDING, complete 시 TRIGGERED."""

    def test_incomplete_returns_pending(self, db_session: Session):
        table_id, seats = _seed_table_with_seats(db_session, seat_count=2)
        break_id = 900
        _add_snapshot(db_session, table_id, break_id, seats[0])
        # seats[1] 미제출

        result = trigger_break_complete_if_ready(table_id, break_id, db_session)
        assert result == BreakCompleteResult.PENDING

    def test_complete_returns_triggered(self, db_session: Session):
        table_id, seats = _seed_table_with_seats(db_session, seat_count=2)
        break_id = 901
        for s in seats:
            _add_snapshot(db_session, table_id, break_id, s)

        result = trigger_break_complete_if_ready(table_id, break_id, db_session)
        assert result == BreakCompleteResult.TRIGGERED

    def test_already_triggered_is_idempotent(self, db_session: Session):
        """두 번 호출 시 ALREADY_TRIGGERED 반환 (중복 신호 방지)."""
        table_id, seats = _seed_table_with_seats(db_session, seat_count=1)
        break_id = 902
        _add_snapshot(db_session, table_id, break_id, seats[0])

        result1 = trigger_break_complete_if_ready(table_id, break_id, db_session)
        result2 = trigger_break_complete_if_ready(table_id, break_id, db_session)
        assert result1 == BreakCompleteResult.TRIGGERED
        assert result2 == BreakCompleteResult.ALREADY_TRIGGERED
