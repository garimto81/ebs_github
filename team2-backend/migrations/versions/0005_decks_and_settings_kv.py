"""SG-004 + SG-006 + SG-003: decks, deck_cards, settings_kv 테이블 신규.

Revision ID: 0005_decks_settings_kv
Revises: 0004_player_move_status
Create Date: 2026-04-20

관련 기획:
  - SG-006 RFID 52 카드 codemap (decks + deck_cards)
  - SG-003 Settings 6탭 스키마 (settings_kv)

team2 session TODO markers:
  [TODO-T2-001] pytest 로 migration upgrade/downgrade 테스트 추가
  [TODO-T2-002] seed 데이터로 Demo deck 생성 (SG-002 Demo Mode 연계)
  [TODO-T2-003] settings_kv 에 scope_id cascade 정책 결정 (soft/hard delete)
"""
from __future__ import annotations

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op


revision: str = "0005_decks_settings_kv"
down_revision: Union[str, None] = "0004_player_move_status"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ------------------------------------------------------------------
    # SG-006: decks + deck_cards
    # ------------------------------------------------------------------
    op.create_table(
        "decks",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("name", sa.String(length=50), nullable=False, unique=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),
        sa.Column(
            "status",
            sa.String(length=20),
            nullable=False,
            server_default="active",
        ),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.CheckConstraint(
            "status IN ('active','retired','damaged','registering','partial')",
            name="ck_decks_status",
        ),
    )
    op.create_index("ix_decks_status", "decks", ["status"])

    op.create_table(
        "deck_cards",
        sa.Column("deck_id", sa.String(length=36), nullable=False),
        sa.Column("card_code", sa.String(length=3), nullable=False),
        sa.Column("rfid_uid", sa.String(length=32), nullable=False),
        sa.Column(
            "registered_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),
        sa.Column("registered_by", sa.String(length=36), nullable=True),
        sa.PrimaryKeyConstraint("deck_id", "card_code"),
        sa.ForeignKeyConstraint(
            ["deck_id"], ["decks.id"], ondelete="CASCADE"
        ),
        sa.UniqueConstraint("rfid_uid", name="uq_deck_cards_rfid_uid"),
    )
    op.create_index(
        "ix_deck_cards_rfid_uid", "deck_cards", ["rfid_uid"], unique=True
    )

    # ------------------------------------------------------------------
    # SG-003: settings_kv
    # ------------------------------------------------------------------
    op.create_table(
        "settings_kv",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("scope_level", sa.String(length=10), nullable=False),
        sa.Column("scope_id", sa.String(length=36), nullable=True),
        sa.Column("tab", sa.String(length=20), nullable=False),
        sa.Column("key", sa.String(length=100), nullable=False),
        sa.Column("value", sa.Text(), nullable=False),  # JSON string (SQLite/Postgres compatible)
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),
        sa.Column("updated_by", sa.String(length=36), nullable=True),
        sa.CheckConstraint(
            "scope_level IN ('global','series','event','table','user')",
            name="ck_settings_kv_scope_level",
        ),
        sa.CheckConstraint(
            "tab IN ('outputs','gfx','display','rules','stats','preferences')",
            name="ck_settings_kv_tab",
        ),
        sa.UniqueConstraint(
            "scope_level",
            "scope_id",
            "tab",
            "key",
            name="uq_settings_kv_scope_tab_key",
        ),
    )
    op.create_index(
        "ix_settings_kv_scope", "settings_kv", ["scope_level", "scope_id"]
    )
    op.create_index("ix_settings_kv_tab", "settings_kv", ["tab"])


def downgrade() -> None:
    op.drop_index("ix_settings_kv_tab", table_name="settings_kv")
    op.drop_index("ix_settings_kv_scope", table_name="settings_kv")
    op.drop_table("settings_kv")

    op.drop_index("ix_deck_cards_rfid_uid", table_name="deck_cards")
    op.drop_table("deck_cards")

    op.drop_index("ix_decks_status", table_name="decks")
    op.drop_table("decks")
