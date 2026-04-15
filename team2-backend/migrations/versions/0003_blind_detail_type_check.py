"""G3: blind_structure_levels.detail_type CHECK 5값 (HalfBlind/HalfBreak 추가)

Revision ID: 0003_blind_detail_type
Revises: 0002_configs_scope
Create Date: 2026-04-15

WSOP LIVE BlindDetailType Confluence 1960411325 와 1:1 정렬.
"""
from __future__ import annotations

from typing import Sequence, Union

from alembic import op


revision: str = "0003_blind_detail_type"
down_revision: Union[str, None] = "0002_configs_scope"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table("blind_structure_levels", recreate="always") as batch:
        batch.create_check_constraint(
            "ck_blind_detail_type",
            "detail_type IN (0, 1, 2, 3, 4)",
        )


def downgrade() -> None:
    with op.batch_alter_table("blind_structure_levels", recreate="always") as batch:
        batch.drop_constraint("ck_blind_detail_type", type_="check")
