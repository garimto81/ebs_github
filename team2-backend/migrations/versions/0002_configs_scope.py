"""G4-C: configs table scope/scope_id 컬럼 추가

Revision ID: 0002_configs_scope
Revises: 437c961ee28c
Create Date: 2026-04-15

WSOP LIVE Series/Event/Table 단위 정렬. Schema.md §configs + Overview.md §3.6 참조.

Workflow (J1 2026-04-20 명확화):
  Fresh DB: `tools/init_db.py` 가 init.sql 로 전체 테이블 생성 + alembic stamp head.
  기존 DB (init.sql 구버전, pre-scope): 이 migration 이 scope/scope_id 추가.
  hybrid 운영 — init.sql = 테이블 권위, alembic = incremental 변경.
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
    # J1: 전제 — init.sql 이 configs 를 pre-scope 구조로 생성했거나,
    #             이미 scope 포함으로 생성한 상태 (idempotent 처리 below).
    from sqlalchemy import inspect
    bind = op.get_bind()
    insp = inspect(bind)
    if "configs" not in insp.get_table_names():
        # Fresh DB 에서 init.sql 미실행 상태. tools/init_db.py 사용 권장.
        # 여기서는 scope 포함으로 직접 create (safety net).
        op.create_table(
            "configs",
            sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
            sa.Column("key", sa.String(length=200), nullable=False),
            sa.Column("value", sa.Text(), nullable=True),
            sa.Column("scope", sa.String(length=20), nullable=False, server_default="global"),
            sa.Column("scope_id", sa.Integer(), nullable=True),
            sa.Column("updated_at", sa.DateTime(timezone=True),
                      server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
            sa.UniqueConstraint("key", "scope", "scope_id", name="uq_configs_key_scope"),
            sa.CheckConstraint(
                "scope IN ('global','series','event','table')", name="ck_configs_scope"),
            sa.CheckConstraint(
                "(scope = 'global' AND scope_id IS NULL) OR "
                "(scope != 'global' AND scope_id IS NOT NULL)",
                name="ck_configs_scope_id"),
        )
        op.create_index("idx_configs_lookup", "configs", ["key", "scope", "scope_id"])
        return

    # 기존 DB (pre-scope): scope/scope_id 추가
    existing_cols = {c["name"] for c in insp.get_columns("configs")}
    if "scope" in existing_cols:
        # 이미 scope 포함 (init.sql 최신 버전) — migration no-op
        # 단 index 가 없을 수 있으니 안전하게 추가
        existing_indexes = {ix["name"] for ix in insp.get_indexes("configs")}
        if "idx_configs_lookup" not in existing_indexes:
            op.create_index("idx_configs_lookup", "configs", ["key", "scope", "scope_id"])
        return

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
