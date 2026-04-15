"""Tests for src/services/config_service.py (G-A3)."""
from __future__ import annotations

import pytest
from sqlmodel import Session, SQLModel, create_engine

from src.models.competition import Event, EventFlight, Series
from src.models.config import Config
from src.models.table import Table
from src.services.config_service import (
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
    def test_global_fallback_when_nothing_set(self, session):
        result = resolve_config(session, "unknown_key", default="fallback")
        assert result == "fallback"

    def test_global_scope_hit(self, session):
        upsert_config(session, "log_level", "INFO", scope="global")
        invalidate_all()
        assert resolve_config(session, "log_level") == "INFO"

    def test_table_overrides_global(self, session, sample_hierarchy):
        tid = sample_hierarchy["table_id"]
        upsert_config(session, "overlay.skin_id", "1", scope="global")
        upsert_config(session, "overlay.skin_id", "42", scope="table", scope_id=tid)
        invalidate_all()
        assert resolve_config(session, "overlay.skin_id", table_id=tid) == "42"

    def test_event_overrides_series_and_global(self, session, sample_hierarchy):
        sid = sample_hierarchy["series_id"]
        eid = sample_hierarchy["event_id"]
        upsert_config(session, "display_mode", "default", scope="global")
        upsert_config(session, "display_mode", "series_val", scope="series", scope_id=sid)
        upsert_config(session, "display_mode", "event_val", scope="event", scope_id=eid)
        invalidate_all()
        assert resolve_config(session, "display_mode", event_id=eid, series_id=sid) == "event_val"

    def test_series_fallback_when_event_missing(self, session, sample_hierarchy):
        sid = sample_hierarchy["series_id"]
        eid = sample_hierarchy["event_id"]
        upsert_config(session, "currency", "USD", scope="global")
        upsert_config(session, "currency", "EUR", scope="series", scope_id=sid)
        invalidate_all()
        # event 에 값 없으므로 series 까지 fallback
        assert resolve_config(session, "currency", event_id=eid, series_id=sid) == "EUR"

    def test_scope_id_backresolve_from_table_id(self, session, sample_hierarchy):
        """table_id 만 주면 event/series 자동 역참조."""
        tid = sample_hierarchy["table_id"]
        sid = sample_hierarchy["series_id"]
        upsert_config(session, "currency", "GBP", scope="series", scope_id=sid)
        invalidate_all()
        # event_id/series_id 인자 없이 table_id 만
        assert resolve_config(session, "currency", table_id=tid) == "GBP"

    def test_cache_returns_same_value_twice(self, session):
        upsert_config(session, "cached_key", "v1", scope="global")
        invalidate_all()
        assert resolve_config(session, "cached_key") == "v1"
        # 직접 DB 값을 바꿔도 cache hit 이면 v1 유지
        row = session.exec(
            __import__("sqlmodel").select(Config).where(Config.key == "cached_key")
        ).first()
        row.value = "v2"
        session.add(row)
        session.commit()
        assert resolve_config(session, "cached_key") == "v1"  # cache hit
        invalidate_config("cached_key", "global")
        assert resolve_config(session, "cached_key") == "v2"  # fresh

    def test_use_cache_false_bypasses_cache(self, session):
        upsert_config(session, "key_x", "first", scope="global")
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
    def test_insert_new(self, session):
        row, old = upsert_config(session, "new_key", "v1", scope="global")
        assert old is None
        assert row.value == "v1"

    def test_update_existing(self, session):
        upsert_config(session, "k", "v1", scope="global")
        row, old = upsert_config(session, "k", "v2", scope="global")
        assert old == "v1"
        assert row.value == "v2"

    def test_invalid_scope_raises(self, session):
        with pytest.raises(ValueError):
            upsert_config(session, "k", "v", scope="invalid")

    def test_global_with_scope_id_raises(self, session):
        with pytest.raises(ValueError):
            upsert_config(session, "k", "v", scope="global", scope_id=1)

    def test_non_global_without_scope_id_raises(self, session):
        with pytest.raises(ValueError):
            upsert_config(session, "k", "v", scope="table", scope_id=None)
