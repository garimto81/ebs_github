"""ChipCountSnapshot model — Cycle 20 Wave 2 (issue #435).

SSOT contract: docs/2. Development/2.2 Backend/APIs/WSOP_LIVE_Chip_Count_Sync.md §9
WS event: docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md §4.2.11
State machine: docs/2. Development/2.5 Shared/Chip_Count_State.md

WSOP LIVE webhook 이 break 중 딜러 입력 chip count 를 push 할 때 BO 가 commit 하는
immutable append 테이블. 한 webhook = 1 snapshot_id = N rows (좌석별).
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import CheckConstraint
from sqlmodel import Field, SQLModel


def utcnow() -> str:
    return datetime.now(timezone.utc).isoformat()


class ChipCountSnapshot(SQLModel, table=True):
    """Per-seat row from a WSOP LIVE break-time chip count webhook.

    Idempotency: ``snapshot_id`` is the webhook-level UUID v4 — multiple rows
    share the same snapshot_id (one per seat). Spec §9 keeps the row immutable;
    corrections go to a separate ``chip_count_corrections`` table (out of scope).
    """

    __tablename__ = "chip_count_snapshots"

    id: Optional[int] = Field(default=None, primary_key=True)
    snapshot_id: str = Field(nullable=False, index=True)
    table_id: int = Field(foreign_key="tables.table_id")
    seat_number: int = Field(nullable=False)
    player_id: Optional[int] = Field(default=None)
    chip_count: int = Field(nullable=False)
    break_id: int = Field(nullable=False)
    source: str = Field(default="wsop-live-webhook")
    # ISO-8601 UTC strings (matches Table/Player convention; SQLite-friendly).
    recorded_at: str = Field(nullable=False)
    received_at: str = Field(default_factory=utcnow)
    signature_ok: bool = Field(default=True)
    # Raw webhook body (JSON-encoded string) — preserved for dispute / re-verify.
    raw_payload: str = Field(default="{}")

    __table_args__ = (
        CheckConstraint(
            "chip_count >= 0",
            name="ck_chip_count_snapshots_nonneg",
        ),
        CheckConstraint(
            "seat_number >= 1 AND seat_number <= 10",
            name="ck_chip_count_snapshots_seat_range",
        ),
    )
