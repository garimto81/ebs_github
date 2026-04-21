"""Hand History API 필터 인덱스 — Backend_HTTP.md §5.10.1 지원.

Revision ID: 0008_hands_filter_indexes
Revises: 0007_sandbox_seed
Create Date: 2026-04-21

추가 인덱스:
  - idx_hands_table_started : (table_id, started_at DESC) 복합
      — Hand Browser 기본 쿼리 (table + 시간 정렬)
  - idx_hands_started_at    : 이미 idx_hands_started 존재 (기존), 추가 없음
  - idx_hp_player_hand      : hand_players (player_id, hand_id) 복합
      — player_id 필터 시 hand_id 조인 성능
  - idx_hands_ended_at      : ended_at 기반 조회 (리포트 연계)
  - idx_flights_event_display : event_flights (event_id, display_name)
      — Lobby Hand History `?event_id=&day=` 복합 필터 성능

참고:
  - Backend_HTTP.md §5.10.1 이 `idx_hands_event_table_started (event_id, table_id, started_at)` 를 권고했으나
    hands 테이블에 event_id 컬럼이 없음 (tables 경유 JOIN). 실제 스키마 기준 인덱스로 조정.
  - Backend_HTTP.md 의 `hand_seats` 는 실제 `hand_players` 로 명세 drift. 본 migration 은 실제 테이블명에 인덱스.
"""
from __future__ import annotations

from typing import Sequence, Union

from alembic import op


revision: str = "0008_hands_filter_indexes"
down_revision: Union[str, None] = "0007_sandbox_seed"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # hands: (table_id, started_at DESC) 복합 인덱스
    op.create_index(
        "idx_hands_table_started",
        "hands",
        ["table_id", "started_at"],
        unique=False,
    )

    # hands: ended_at 단독 인덱스 (리포트용)
    op.create_index(
        "idx_hands_ended_at",
        "hands",
        ["ended_at"],
        unique=False,
    )

    # hand_players: (player_id, hand_id) 복합
    op.create_index(
        "idx_hp_player_hand",
        "hand_players",
        ["player_id", "hand_id"],
        unique=False,
    )

    # event_flights: (event_id, display_name) — ?event_id=&day= 복합 필터
    op.create_index(
        "idx_flights_event_display",
        "event_flights",
        ["event_id", "display_name"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("idx_flights_event_display", table_name="event_flights")
    op.drop_index("idx_hp_player_hand", table_name="hand_players")
    op.drop_index("idx_hands_ended_at", table_name="hands")
    op.drop_index("idx_hands_table_started", table_name="hands")
