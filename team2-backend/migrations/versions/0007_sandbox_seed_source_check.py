"""B-068 Phase A: sandbox seed — competitions id=99 + settings_kv sandbox.enabled + source CHECK 제약.

Revision ID: 0007_sandbox_seed
Revises: 0006_twofa_columns_reserved
Create Date: 2026-04-21

관련 기획:
  - Engineering/Sandbox_Tournament_Generator.md §1.1.1, §4.2, §5
  - B-068 Phase A (Schema / Config seed)
  - APIs/Backend_HTTP.md §1 source enum 'sandbox' 추가

동작:
  1. competitions id=99 'Sandbox Competition' 시드 (없을 때만 삽입)
  2. settings_kv 전역 'sandbox.enabled' = 'false' 시드 (기본 OFF)
  3. series/events/event_flights/tables source CHECK 제약 추가
     (값: 'api', 'manual', 'sandbox', 'wsop')

참고:
  - 0006 은 2FA 컬럼 예약 migration (아직 작성 안 됨). 실제 head 는 0005 _or_ 0006.
    본 migration 은 down_revision 을 env 의 실제 head 에 맞춰 조정 필요.
  - 실제 settings_kv CHECK(tab) 는 6값 고정 (outputs/gfx/display/rules/stats/preferences).
    'sandbox.enabled' 는 tab='preferences', scope_level='global' 로 배치.
"""
from __future__ import annotations

import uuid
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op


revision: str = "0007_sandbox_seed"
down_revision: Union[str, None] = "0005_decks_settings_kv"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


SANDBOX_COMPETITION_ID = 99
SETTINGS_KV_ID = "0007-sandbox-enabled-seed-global"


def upgrade() -> None:
    bind = op.get_bind()

    # 1. competitions id=99 'Sandbox Competition' (idempotent INSERT)
    bind.execute(
        sa.text(
            """
            INSERT INTO competitions (competition_id, name, competition_type, competition_tag)
            SELECT :cid, 'Sandbox Competition', 0, 0
            WHERE NOT EXISTS (
                SELECT 1 FROM competitions WHERE competition_id = :cid
            )
            """
        ),
        {"cid": SANDBOX_COMPETITION_ID},
    )

    # 2. settings_kv 'sandbox.enabled' global seed (기본 'false' = OFF)
    bind.execute(
        sa.text(
            """
            INSERT INTO settings_kv (id, scope_level, scope_id, tab, key, value, updated_by)
            SELECT :id, 'global', NULL, 'preferences', 'sandbox.enabled', 'false', NULL
            WHERE NOT EXISTS (
                SELECT 1 FROM settings_kv
                WHERE scope_level = 'global' AND scope_id IS NULL
                  AND tab = 'preferences' AND key = 'sandbox.enabled'
            )
            """
        ),
        {"id": SETTINGS_KV_ID},
    )

    # 3. source CHECK 제약 추가 — series/events/event_flights/tables
    #    SQLite: batch_alter_table 로 테이블 재생성 (기존 데이터 보존)
    _add_source_check_sqlite("series")
    _add_source_check_sqlite("events")
    _add_source_check_sqlite("event_flights")
    _add_source_check_sqlite("tables")


def downgrade() -> None:
    bind = op.get_bind()

    # source CHECK 제약 제거 (batch_alter_table)
    _drop_source_check_sqlite("tables")
    _drop_source_check_sqlite("event_flights")
    _drop_source_check_sqlite("events")
    _drop_source_check_sqlite("series")

    # seed 제거 (역순)
    bind.execute(
        sa.text("DELETE FROM settings_kv WHERE id = :id"),
        {"id": SETTINGS_KV_ID},
    )
    bind.execute(
        sa.text(
            "DELETE FROM competitions WHERE competition_id = :cid "
            "AND NOT EXISTS (SELECT 1 FROM series WHERE competition_id = :cid)"
        ),
        {"cid": SANDBOX_COMPETITION_ID},
    )


def _add_source_check_sqlite(table_name: str) -> None:
    """SQLite batch_alter_table 로 source CHECK 제약 추가.

    값: 'api' / 'manual' / 'sandbox' / 'wsop'
    """
    constraint_name = f"ck_{table_name}_source"
    with op.batch_alter_table(table_name, recreate="always") as batch_op:
        batch_op.create_check_constraint(
            constraint_name,
            "source IN ('api', 'manual', 'sandbox', 'wsop')",
        )


def _drop_source_check_sqlite(table_name: str) -> None:
    constraint_name = f"ck_{table_name}_source"
    with op.batch_alter_table(table_name, recreate="always") as batch_op:
        batch_op.drop_constraint(constraint_name, type_="check")
