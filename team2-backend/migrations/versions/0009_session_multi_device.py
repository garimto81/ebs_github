"""user_sessions 복합 PK — BS-01 §A-25 다중 세션 지원 (M1 Item 3).

Revision ID: 0009_session_multi_device
Revises: 0008_hands_filter_indexes
Create Date: 2026-04-28

BS-01 §동시 세션·대회 비밀번호:
  - "최대 동시 세션 2개 (1 Lobby + 1 CC). 초과 시 이전 세션 무효화"

기존 user_sessions.user_id UNIQUE 제약은 1 user 당 1 row 강제 → 정책 위반.
device_id 컬럼 추가 + UNIQUE(user_id, device_id) 로 device-level 격리.

Backward compat:
  - device_id DEFAULT 'default' → 기존 행 backfill + 신규 호출 호환
  - create_session(user, db) (device_id 미명시) → device_id="default" 사용 → 기존 동작
  - 신규 multi-session: create_session(user, db, device_id="lobby"|"cc") → 분리

SQLite 의 ALTER TABLE DROP CONSTRAINT 미지원 → batch_alter_table 로 재생성.
"""
from __future__ import annotations

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op


revision: str = "0009_session_multi_device"
down_revision: Union[str, None] = "0008_hands_filter_indexes"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # batch_alter_table — SQLite 호환 테이블 재생성. 기존 UNIQUE(user_id) 자동 제거.
    with op.batch_alter_table("user_sessions") as batch_op:
        batch_op.add_column(
            sa.Column(
                "device_id",
                sa.Text(),
                nullable=False,
                server_default="default",
            )
        )
        batch_op.create_unique_constraint(
            "uq_user_sessions_user_device",
            ["user_id", "device_id"],
        )
    # batch_alter_table 가 user_id 의 기존 UNIQUE 제약을 함께 제거 (테이블 재생성 효과)


def downgrade() -> None:
    with op.batch_alter_table("user_sessions") as batch_op:
        batch_op.drop_constraint("uq_user_sessions_user_device", type_="unique")
        batch_op.drop_column("device_id")
        batch_op.create_unique_constraint(
            "uq_user_sessions_user_id_legacy",
            ["user_id"],
        )
