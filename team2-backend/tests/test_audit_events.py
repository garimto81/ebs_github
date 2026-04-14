"""Gate 3-6 ~ 3-8, 3-13, 3-14: audit_events append-only + seq + can_undo."""
import json

import pytest
from sqlalchemy import text
from sqlmodel import Session

from src.models.audit_event import AuditEvent
from src.repositories.event_repository import AuditEventRepository, event_repository


# ── Gate 3-6: audit_events UPDATE attempt → repository has no update method ──

def test_repository_has_no_update_method():
    """AuditEventRepository must NOT expose update()."""
    assert not hasattr(AuditEventRepository, "update"), (
        "append-only violated: update() method found"
    )


# ── Gate 3-7: audit_events DELETE attempt → repository has no delete method ──

def test_repository_has_no_delete_method():
    """AuditEventRepository must NOT expose delete()."""
    assert not hasattr(AuditEventRepository, "delete"), (
        "append-only violated: delete() method found"
    )


# ── Gate 3-8: seq continuity — 10 events same table → seq 1..10 ──

def test_seq_continuity(db_session: Session):
    """10 appends to the same table produce seq 1..10 with no gaps."""
    table_id = "tbl-seq-test"
    seqs = []

    for i in range(10):
        evt = event_repository.append(
            table_id=table_id,
            event_type="hand_started",
            payload={"hand_number": i + 1},
            db=db_session,
        )
        seqs.append(evt.seq)

    assert seqs == list(range(1, 11)), f"Expected 1..10, got {seqs}"


def test_seq_independent_per_table(db_session: Session):
    """Different tables have independent seq counters."""
    for tid in ["tbl-a", "tbl-b"]:
        for i in range(3):
            event_repository.append(
                table_id=tid,
                event_type="hand_started",
                payload={"n": i},
                db=db_session,
            )

    # Both tables should have seq 1, 2, 3
    result_a = db_session.execute(
        text("SELECT seq FROM audit_events WHERE table_id='tbl-a' ORDER BY seq")
    )
    result_b = db_session.execute(
        text("SELECT seq FROM audit_events WHERE table_id='tbl-b' ORDER BY seq")
    )
    assert [r[0] for r in result_a] == [1, 2, 3]
    assert [r[0] for r in result_b] == [1, 2, 3]


# ── Gate 3-13: can_undo → true when inverse_payload exists ──

def test_can_undo_true_with_inverse_payload(db_session: Session):
    """can_undo is True when inverse_payload is not None."""
    evt = event_repository.append(
        table_id="tbl-undo",
        event_type="seat_assigned",
        payload={"seat": 3, "player_id": "p-1"},
        inverse_payload={"seat": 3, "player_id": None},
        db=db_session,
    )
    assert event_repository.get_can_undo(evt) is True


# ── Gate 3-14: can_undo → false when inverse_payload is None ──

def test_can_undo_false_without_inverse_payload(db_session: Session):
    """can_undo is False when inverse_payload is None."""
    evt = event_repository.append(
        table_id="tbl-no-undo",
        event_type="hand_started",
        payload={"hand_number": 1},
        db=db_session,
    )
    assert event_repository.get_can_undo(evt) is False


# ── Additional: payload stored as JSON string ──

def test_payload_serialization(db_session: Session):
    """Dict payload is serialized to JSON string in DB."""
    payload_dict = {"key": "value", "nested": {"a": 1}}
    evt = event_repository.append(
        table_id="tbl-json",
        event_type="config_changed",
        payload=payload_dict,
        db=db_session,
    )
    assert isinstance(evt.payload, str)
    assert json.loads(evt.payload) == payload_dict


def test_fetch_since_basic(db_session: Session):
    """fetch_since returns events after the given seq."""
    table_id = "tbl-fetch"
    for i in range(5):
        event_repository.append(
            table_id=table_id,
            event_type="hand_started",
            payload={"n": i},
            db=db_session,
        )

    result = event_repository.fetch_since(table_id, since_seq=2, limit=10, db=db_session)
    assert len(result.events) == 3  # seq 3, 4, 5
    assert result.events[0].seq == 3
    assert result.last_seq == 5
    assert result.has_more is False
