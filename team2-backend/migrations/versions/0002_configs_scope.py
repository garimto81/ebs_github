"""G4-C: configs table scope/scope_id 컬럼 추가

Revision ID: 0002_configs_scope
Revises: 437c961ee28c
Create Date: 2026-04-15

WSOP LIVE Series/Event/Table 단위 정렬. Schema.md §configs + Overview.md §3.6 참조.
"""
from __future__ import annotations

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "0002_configs_scope"
down_revision: Union[str, None] = "437c961ee28c"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # SQLite 은 ALTER ADD CHECK 를 직접 지원하지 않음 → batch mode 로 재생성
    with op.batch_alter_table("configs", recreate="always") as batch:
        batch.add_column(sa.Column("scope", sa.String(), nullable=False, server_default="global"))
        batch.add_column(sa.Column("scope_id", sa.Integer(), nullable=True))
        batch.drop_constraint("configs_key_key", type_="unique")
        batch.create_unique_constraint("uq_configs_key_scope", ["key", "scope", "scope_id"])
        batch.create_check_constraint(
            "ck_configs_scope",
            "scope IN ('global','series','event','table')",
        )
        batch.create_check_constraint(
            "ck_configs_scope_id",
            "(scope = 'global' AND scope_id IS NULL) OR (scope != 'global' AND scope_id IS NOT NULL)",
        )
    op.create_index("idx_configs_lookup", "configs", ["key", "scope", "scope_id"])


def downgrade() -> None:
    op.drop_index("idx_configs_lookup", table_name="configs")
    with op.batch_alter_table("configs", recreate="always") as batch:
        batch.drop_constraint("ck_configs_scope_id", type_="check")
        batch.drop_constraint("ck_configs_scope", type_="check")
        batch.drop_constraint("uq_configs_key_scope", type_="unique")
        batch.create_unique_constraint("configs_key_key", ["key"])
        batch.drop_column("scope_id")
        batch.drop_column("scope")
