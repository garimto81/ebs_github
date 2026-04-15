"""Gap-Final-3: Alembic migration 실 DB 적용 후 CHECK 제약 동작 검증.

init.sql + migration 0002~0004 가 실제로 CHECK 제약을 DB 에 정착시키는지
SQLite in-file 기반으로 검증.
"""
from __future__ import annotations

import os
import tempfile

import pytest
from sqlalchemy import create_engine, text
from sqlalchemy.exc import IntegrityError


@pytest.fixture()
def init_sql_path() -> str:
    """레포 내 init.sql 경로."""
    here = os.path.dirname(__file__)
    return os.path.abspath(os.path.join(here, "..", "src", "db", "init.sql"))


@pytest.fixture()
def init_db(init_sql_path: str):
    """init.sql 로 초기화된 임시 SQLite 파일 engine."""
    fd, db_path = tempfile.mkstemp(suffix=".db")
    os.close(fd)
    engine = create_engine(f"sqlite:///{db_path}")
    with open(init_sql_path, encoding="utf-8") as f:
        sql = f.read()
    with engine.begin() as conn:
        # sqlite 는 여러 문장을 한 번에 실행 안 하므로 세미콜론으로 split
        for stmt in _split_sql(sql):
            if stmt.strip():
                conn.execute(text(stmt))
    yield engine
    engine.dispose()
    os.unlink(db_path)


def _split_sql(sql: str) -> list[str]:
    """단순 세미콜론 split (문자열/괄호 내부 세미콜론 없다고 가정)."""
    out: list[str] = []
    buf: list[str] = []
    in_trigger = False
    for line in sql.splitlines():
        stripped = line.strip().upper()
        if stripped.startswith("CREATE TRIGGER"):
            in_trigger = True
        buf.append(line)
        if line.rstrip().endswith(";") and not in_trigger:
            out.append("\n".join(buf))
            buf = []
        if in_trigger and stripped.startswith("END"):
            in_trigger = False
            out.append("\n".join(buf))
            buf = []
    if buf:
        out.append("\n".join(buf))
    return out


class TestBlindDetailTypeCheck:
    """G3 (HalfBlind/HalfBreak 추가) + CHECK 제약 DB 반영."""

    def _insert_structure(self, engine) -> int:
        with engine.begin() as conn:
            conn.execute(text("INSERT INTO blind_structures (name) VALUES ('Default')"))
            bsid = conn.execute(text("SELECT blind_structure_id FROM blind_structures")).scalar()
        return bsid

    def test_detail_type_0_to_4_allowed(self, init_db):
        bsid = self._insert_structure(init_db)
        for dt in (0, 1, 2, 3, 4):
            with init_db.begin() as conn:
                conn.execute(text(
                    "INSERT INTO blind_structure_levels "
                    "(blind_structure_id, level_no, small_blind, big_blind, "
                    " duration_minutes, detail_type) VALUES (:b, :ln, 100, 200, 60, :dt)"
                ), {"b": bsid, "ln": dt + 1, "dt": dt})

    def test_detail_type_5_rejected(self, init_db):
        bsid = self._insert_structure(init_db)
        with pytest.raises(IntegrityError):
            with init_db.begin() as conn:
                conn.execute(text(
                    "INSERT INTO blind_structure_levels "
                    "(blind_structure_id, level_no, small_blind, big_blind, "
                    " duration_minutes, detail_type) VALUES (:b, 1, 100, 200, 60, 5)"
                ), {"b": bsid})


class TestConfigsScopeCheck:
    """G4-C CHECK 제약 2개 동작."""

    def test_scope_invalid_rejected(self, init_db):
        with pytest.raises(IntegrityError):
            with init_db.begin() as conn:
                conn.execute(text(
                    "INSERT INTO configs (key, value, scope, scope_id) "
                    "VALUES ('k', 'v', 'invalid', NULL)"
                ))

    def test_global_must_have_null_scope_id(self, init_db):
        with pytest.raises(IntegrityError):
            with init_db.begin() as conn:
                conn.execute(text(
                    "INSERT INTO configs (key, value, scope, scope_id) "
                    "VALUES ('k', 'v', 'global', 5)"
                ))

    def test_non_global_must_have_scope_id(self, init_db):
        with pytest.raises(IntegrityError):
            with init_db.begin() as conn:
                conn.execute(text(
                    "INSERT INTO configs (key, value, scope, scope_id) "
                    "VALUES ('k', 'v', 'table', NULL)"
                ))

    def test_uniqueness_key_scope_scope_id(self, init_db):
        """SQLite UNIQUE 는 NULL distinct — scope_id 명시값으로 테스트."""
        with init_db.begin() as conn:
            conn.execute(text(
                "INSERT INTO configs (key, value, scope, scope_id, category) "
                "VALUES ('k', 'v1', 'table', 42, 'system')"
            ))
        with pytest.raises(IntegrityError):
            with init_db.begin() as conn:
                conn.execute(text(
                    "INSERT INTO configs (key, value, scope, scope_id, category) "
                    "VALUES ('k', 'v2', 'table', 42, 'system')"
                ))


class TestPlayerMoveStatusCheck:
    """Gap-Final-1a CHECK 제약 동작."""

    def _prepare_seat_fixture(self, engine):
        with engine.begin() as conn:
            conn.execute(text(
                "INSERT INTO competitions (name, competition_type, competition_tag) "
                "VALUES ('WSOP', 0, 1)"
            ))
            cid = conn.execute(text("SELECT competition_id FROM competitions")).scalar()
            conn.execute(text(
                "INSERT INTO series (competition_id, series_name, year, begin_at, end_at) "
                "VALUES (:cid, 'S', 2026, '2026-01-01', '2026-12-31')"
            ), {"cid": cid})
            sid = conn.execute(text("SELECT series_id FROM series")).scalar()
            conn.execute(text(
                "INSERT INTO events (series_id, event_no, event_name) "
                "VALUES (:s, 1, 'E')"
            ), {"s": sid})
            eid = conn.execute(text("SELECT event_id FROM events")).scalar()
            conn.execute(text(
                "INSERT INTO event_flights (event_id, display_name) VALUES (:e, 'D1')"
            ), {"e": eid})
            fid = conn.execute(text("SELECT event_flight_id FROM event_flights")).scalar()
            conn.execute(text(
                "INSERT INTO tables (event_flight_id, table_no, name) "
                "VALUES (:f, 1, 'T1')"
            ), {"f": fid})
            tid = conn.execute(text("SELECT table_id FROM tables")).scalar()
        return tid

    def test_valid_values_allowed(self, init_db):
        tid = self._prepare_seat_fixture(init_db)
        for i, val in enumerate([None, "none", "new", "move"]):
            with init_db.begin() as conn:
                conn.execute(text(
                    "INSERT INTO table_seats "
                    "(table_id, seat_no, status, player_move_status) "
                    "VALUES (:t, :s, 'empty', :pms)"
                ), {"t": tid, "s": i, "pms": val})

    def test_invalid_value_rejected(self, init_db):
        tid = self._prepare_seat_fixture(init_db)
        with pytest.raises(IntegrityError):
            with init_db.begin() as conn:
                conn.execute(text(
                    "INSERT INTO table_seats "
                    "(table_id, seat_no, status, player_move_status) "
                    "VALUES (:t, 0, 'empty', 'teleport')"
                ), {"t": tid})
