"""Gap-Final-1a: table_seats.player_move_status CHECK 제약 (WSOP LIVE PlayerMoveStatus 정렬)

Revision ID: 0004_player_move_status
Revises: 0003_blind_detail_type
Create Date: 2026-04-15

WSOP LIVE Tables API Confluence page 1653833763 Staff, 1912668498 Player App.
PlayerMoveStatus {0=None, 1=New, 2=Move} 와 1:1 정렬.
"""
from __future__ import annotations

from typing import Sequence, Union

from alembic import op


revision: str = "0004_player_move_status"
down_revision: Union[str, None] = "0003_blind_detail_type"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 기존 row 가 CHECK 에 부합하지 않는 값을 가지면 NULL 로 정리
    op.execute(
        """
        UPDATE table_seats
        SET player_move_status = NULL
        WHERE player_move_status IS NOT NULL
          AND player_move_status NOT IN ('none','new','move')
        """
    )
    with op.batch_alter_table("table_seats", recreate="always") as batch:
        batch.create_check_constraint(
            "ck_table_seats_player_move_status",
            "player_move_status IS NULL "
            "OR player_move_status IN ('none','new','move')",
        )


def downgrade() -> None:
    with op.batch_alter_table("table_seats", recreate="always") as batch:
        batch.drop_constraint("ck_table_seats_player_move_status", type_="check")
