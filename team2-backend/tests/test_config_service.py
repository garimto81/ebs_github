"""Tests for src/services/config_service.py (G-A3 + Gap-Final-2)."""
from __future__ import annotations

from unittest.mock import AsyncMock

import pytest
from sqlmodel import Session, SQLModel, create_engine

from src.models.competition import Event, EventFlight, Series
from src.models.config import Config
from src.models.table import Table
from src.services.config_service import (
    hint_for_key,
    invalidate_all,
    invalidate_config,
    resolve_config,
    upsert_config,
)


@pytest.fixture()
def session():
    engine = create_engine("sqlite:///:memory:")
    SQLModel.metadata.create_all(engine)
    with Session(engine) as s:
        yield s
    invalidate_all()


@pytest.fixture()
def sample_hierarchy(session: Session):
    """series → event → flight → table 1 세트 시드."""
    from src.models.competition import Competition

    comp = Competition(name="WSOP", competition_type=0, competition_tag=1)
    session.add(comp)
    session.commit()
    session.refresh(comp)

    series = Series(
        competition_id=comp.competition_id,
        series_name="2026 WSOP",
        year=2026,
        begin_at="2026-05-27",
        end_at="2026-07-16",
    )
    session.add(series)
    session.commit()
    session.refresh(series)

    event = Event(
        series_id=series.series_id,
        event_no=1,
        event_name="Main Event",
    )
    session.add(event)
    session.commit()
    session.refresh(event)

    flight = EventFlight(
        event_id=event.event_id,
        display_name="Day 1A",
    )
    session.add(flight)
    session.commit()
    session.refresh(flight)

    table = Table(
        event_flight_id=flight.event_flight_id,
        table_no=1,
        name="Feature Table",
        type="feature",
    )
    session.add(table)
    session.commit()
    session.refresh(table)

    return {
        "series_id": series.series_id,
        "event_id": event.event_id,
        "flight_id": flight.event_flight_id,
        "table_id": table.table_id,
    }


class TestResolveConfig:
    @pytest.mark.asyncio
    async def test_global_fallback_when_nothing_set(self, session):
        result = resolve_config(session, "unknown_key", default="fallback")
        assert result == "fallback"

    @pytest.mark.asyncio
    async def test_global_scope_hit(self, session):
        await upsert_config(session, "log_level", "INFO", scope="global")
        invalidate_all()
        assert resolve_config(session, "log_level") == "INFO"

    @pytest.mark.asyncio
    async def test_table_overrides_global(self, session, sample_hierarchy):
        tid = sample_hierarchy["table_id"]
        await upsert_config(session, "overlay.skin_id", "1", scope="global")
        await upsert_config(session, "overlay.skin_id", "42", scope="table", scope_id=tid)
        invalidate_all()
        assert resolve_config(session, "overlay.skin_id", table_id=tid) == "42"

    @pytest.mark.asyncio
    async def test_event_overrides_series_and_global(self, session, sample_hierarchy):
        sid = sample_hierarchy["series_id"]
        eid = sample_hierarchy["event_id"]
        await upsert_config(session, "display_mode", "default", scope="global")
        await upsert_config(session, "display_mode", "series_val", scope="series", scope_id=sid)
        await upsert_config(session, "display_mode", "event_val", scope="event", scope_id=eid)
        invalidate_all()
        assert resolve_config(session, "display_mode", event_id=eid, series_id=sid) == "event_val"

    @pytest.mark.asyncio
    async def test_series_fallback_when_event_missing(self, session, sample_hierarchy):
        sid = sample_hierarchy["series_id"]
        eid = sample_hierarchy["event_id"]
        await upsert_config(session, "currency", "USD", scope="global")
        await upsert_config(session, "currency", "EUR", scope="series", scope_id=sid)
        invalidate_all()
        assert resolve_config(session, "currency", event_id=eid, series_id=sid) == "EUR"

    @pytest.mark.asyncio
    async def test_scope_id_backresolve_from_table_id(self, session, sample_hierarchy):
        tid = sample_hierarchy["table_id"]
        sid = sample_hierarchy["series_id"]
        await upsert_config(session, "currency", "GBP", scope="series", scope_id=sid)
        invalidate_all()
        assert resolve_config(session, "currency", table_id=tid) == "GBP"

    @pytest.mark.asyncio
    async def test_cache_returns_same_value_twice(self, session):
        await upsert_config(session, "cached_key", "v1", scope="global")
        invalidate_all()
        assert resolve_config(session, "cached_key") == "v1"
        row = session.exec(
            __import__("sqlmodel").select(Config).where(Config.key == "cached_key")
        ).first()
        row.value = "v2"
        session.add(row)
        session.commit()
        assert resolve_config(session, "cached_key") == "v1"
        invalidate_config("cached_key", "global")
        assert resolve_config(session, "cached_key") == "v2"

    @pytest.mark.asyncio
    async def test_use_cache_false_bypasses_cache(self, session):
        await upsert_config(session, "key_x", "first", scope="global")
        invalidate_all()
        resolve_config(session, "key_x")
        row = session.exec(
            __import__("sqlmodel").select(Config).where(Config.key == "key_x")
        ).first()
        row.value = "second"
        session.add(row)
        session.commit()
        assert resolve_config(session, "key_x", use_cache=False) == "second"


class TestUpsertConfig:
    @pytest.mark.asyncio
    async def test_insert_new(self, session):
        row, old = await upsert_config(session, "new_key", "v1", scope="global")
        assert old is None
        assert row.value == "v1"

    @pytest.mark.asyncio
    async def test_update_existing(self, session):
        await upsert_config(session, "k", "v1", scope="global")
        row, old = await upsert_config(session, "k", "v2", scope="global")
        assert old == "v1"
        assert row.value == "v2"

    @pytest.mark.asyncio
    async def test_invalid_scope_raises(self, session):
        with pytest.raises(ValueError):
            await upsert_config(session, "k", "v", scope="invalid")

    @pytest.mark.asyncio
    async def test_global_with_scope_id_raises(self, session):
        with pytest.raises(ValueError):
            await upsert_config(session, "k", "v", scope="global", scope_id=1)

    @pytest.mark.asyncio
    async def test_non_global_without_scope_id_raises(self, session):
        with pytest.raises(ValueError):
            await upsert_config(session, "k", "v", scope="table", scope_id=None)


class TestConfigChangedBroadcast:
    """Gap-Final-2: upsert_config 가 ws_manager 에 ConfigChanged 를 publish."""

    @pytest.mark.asyncio
    async def test_broadcast_called_when_ws_manager_given(self, session):
        ws = AsyncMock()
        row, _ = await upsert_config(
            session, "overlay.skin_id", "1", scope="global",
            actor_user_id=42, ws_manager=ws,
        )
        # lobby broadcast + cc broadcast
        assert ws.broadcast.await_count == 2
        lobby_call = ws.broadcast.await_args_list[0]
        assert lobby_call.args[0] == "lobby"
        assert lobby_call.args[1] == "*"
        event = lobby_call.args[2]
        assert event["type"] == "ConfigChanged"
        assert event["payload"]["config_key"] == "overlay.skin_id"
        assert event["payload"]["new_value"] == "1"
        assert event["payload"]["old_value"] is None
        assert event["payload"]["actor_user_id"] == 42

    @pytest.mark.asyncio
    async def test_broadcast_skipped_when_no_ws_manager(self, session):
        row, _ = await upsert_config(session, "x", "1", scope="global")
        assert row.value == "1"

    @pytest.mark.asyncio
    async def test_table_scope_targets_cc_channel_table_id(self, session, sample_hierarchy):
        ws = AsyncMock()
        tid = sample_hierarchy["table_id"]
        await upsert_config(
            session, "overlay.skin_id", "99",
            scope="table", scope_id=tid, ws_manager=ws,
        )
        # cc 브로드캐스트가 table_id 로 매칭
        cc_call = ws.broadcast.await_args_list[1]
        assert cc_call.args[0] == "cc"
        assert cc_call.args[1] == str(tid)

    @pytest.mark.asyncio
    async def test_cc_broadcast_failure_is_tolerated(self, session):
        """cc 채널 없는 배포(Lobby-Only)에서도 동작."""
        ws = AsyncMock()
        ws.broadcast.side_effect = [None, Exception("no cc channel")]
        row, _ = await upsert_config(
            session, "x", "1", scope="global", ws_manager=ws,
        )
        assert row.value == "1"
        assert ws.broadcast.await_count == 2


class TestHintForKey:
    def test_game_prefix_next_hand(self):
        assert hint_for_key("game.max_players") == "next_hand"

    def test_rule_prefix_next_hand(self):
        assert hint_for_key("rule.ante_mode") == "next_hand"

    def test_blind_prefix_next_hand(self):
        assert hint_for_key("blind.duration_minutes") == "next_hand"

    def test_overlay_force_reload_manual(self):
        assert hint_for_key("overlay.force_reload") == "manual"

    def test_ops_maintenance_manual(self):
        assert hint_for_key("ops.maintenance") == "manual"

    def test_default_immediate(self):
        assert hint_for_key("log_level") == "immediate"
