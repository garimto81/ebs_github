"""brand_packs — Cycle 17 BrandPack 신규 테이블 (사용자 표 #6).

Revision ID: 0010_brand_packs
Revises: 0009_session_multi_device
Create Date: 2026-05-13

SSOT: docs/1. Product/RIVE_Standards.md Ch.7 — Brand Pack.
컬러 팔레트 (3) + 폰트 + 로고 (3종) + 그래픽 모티프 JSON.

대회 시작 시 모든 .riv 파일에 동시 주입되어 overlay 시각 정체성을 결정한다.
예: wsop_2026, ept_2026, gg_master.
"""
from __future__ import annotations

from typing import Sequence, Union

import sqlalchemy as sa
import sqlmodel
from alembic import op

revision: str = "0010_brand_packs"
down_revision: Union[str, None] = "0009_session_multi_device"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "brand_packs",
        sa.Column("brand_pack_id", sa.Integer(), nullable=False),
        sa.Column("name", sqlmodel.sql.sqltypes.AutoString(), nullable=False),
        sa.Column("display_name", sqlmodel.sql.sqltypes.AutoString(), nullable=False),
        sa.Column(
            "primary_color",
            sqlmodel.sql.sqltypes.AutoString(length=16),
            nullable=False,
        ),
        sa.Column(
            "secondary_color",
            sqlmodel.sql.sqltypes.AutoString(length=16),
            nullable=False,
        ),
        sa.Column(
            "accent_color",
            sqlmodel.sql.sqltypes.AutoString(length=16),
            nullable=False,
        ),
        sa.Column(
            "font_family",
            sqlmodel.sql.sqltypes.AutoString(length=128),
            nullable=True,
        ),
        sa.Column("logo_primary_url", sqlmodel.sql.sqltypes.AutoString(), nullable=True),
        sa.Column(
            "logo_secondary_url", sqlmodel.sql.sqltypes.AutoString(), nullable=True
        ),
        sa.Column(
            "logo_tertiary_url", sqlmodel.sql.sqltypes.AutoString(), nullable=True
        ),
        sa.Column("motif_data", sqlmodel.sql.sqltypes.AutoString(), nullable=False),
        sa.Column("is_default", sa.Boolean(), nullable=False),
        sa.Column("created_at", sqlmodel.sql.sqltypes.AutoString(), nullable=False),
        sa.Column("updated_at", sqlmodel.sql.sqltypes.AutoString(), nullable=False),
        sa.PrimaryKeyConstraint("brand_pack_id"),
        sa.UniqueConstraint("name"),
    )
    op.create_index(
        "ix_brand_packs_name",
        "brand_packs",
        ["name"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_brand_packs_name", table_name="brand_packs")
    op.drop_table("brand_packs")
