"""chip_count_snapshots — Cycle 20 Wave 2 (issue #435).

Revision ID: 0011_chip_count_snapshots
Revises: 0010_brand_packs
Create Date: 2026-05-13

SSOT: docs/2. Development/2.2 Backend/APIs/WSOP_LIVE_Chip_Count_Sync.md §9.
Immutable append table — one row per (snapshot_id, seat).
"""
from __future__ import annotations

from typing import Sequence, Union

import sqlalchemy as sa
import sqlmodel
from alembic import op

revision: str = "0011_chip_count_snapshots"
down_revision: Union[str, None] = "0010_brand_packs"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "chip_count_snapshots",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column(
            "snapshot_id",
            sqlmodel.sql.sqltypes.AutoString(),
            nullable=False,
        ),
        sa.Column("table_id", sa.Integer(), nullable=False),
        sa.Column("seat_number", sa.Integer(), nullable=False),
        sa.Column("player_id", sa.Integer(), nullable=True),
        sa.Column("chip_count", sa.Integer(), nullable=False),
        sa.Column("break_id", sa.Integer(), nullable=False),
        sa.Column(
            "source",
            sqlmodel.sql.sqltypes.AutoString(),
            nullable=False,
            server_default="wsop-live-webhook",
        ),
        sa.Column(
            "recorded_at",
            sqlmodel.sql.sqltypes.AutoString(),
            nullable=False,
        ),
        sa.Column(
            "received_at",
            sqlmodel.sql.sqltypes.AutoString(),
            nullable=False,
        ),
        sa.Column(
            "signature_ok",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("1"),
        ),
        sa.Column(
            "raw_payload",
            sqlmodel.sql.sqltypes.AutoString(),
            nullable=False,
            server_default="{}",
        ),
        sa.ForeignKeyConstraint(["table_id"], ["tables.table_id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.CheckConstraint(
            "chip_count >= 0",
            name="ck_chip_count_snapshots_nonneg",
        ),
        sa.CheckConstraint(
            "seat_number >= 1 AND seat_number <= 10",
            name="ck_chip_count_snapshots_seat_range",
        ),
    )
    op.create_index(
        "ix_chip_count_snapshots_snapshot_id",
        "chip_count_snapshots",
        ["snapshot_id"],
        unique=False,
    )
    op.create_index(
        "ix_chip_count_snapshots_table_break",
        "chip_count_snapshots",
        ["table_id", "break_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(
        "ix_chip_count_snapshots_table_break",
        table_name="chip_count_snapshots",
    )
    op.drop_index(
        "ix_chip_count_snapshots_snapshot_id",
        table_name="chip_count_snapshots",
    )
    op.drop_table("chip_count_snapshots")
