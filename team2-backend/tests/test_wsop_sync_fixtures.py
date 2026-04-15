"""Gap-Final-4: WSOP LIVE fixture 기반 adapter 회귀 테스트.

tests/fixtures/wsop_live/ 의 expected schema 로 adapter 변환을
검증해 실 통합 전까지 shape drift 를 방지.
"""
from __future__ import annotations

import json
from pathlib import Path

import pytest

from src.adapters.wsop_game_type import map_to_ebs


FIXTURE_DIR = Path(__file__).parent / "fixtures" / "wsop_live"


def load(name: str) -> dict:
    return json.loads((FIXTURE_DIR / name).read_text(encoding="utf-8"))


class TestSeriesFixture:
    def test_competition_type_range(self):
        for s in load("series_list.json")["series"]:
            assert 0 <= s["competitionType"] <= 4
            assert 0 <= s["competitionTag"] <= 3

    def test_required_fields(self):
        for s in load("series_list.json")["series"]:
            assert {"id", "name", "year", "beginAt", "endAt", "currency"}.issubset(s)


class TestEventsFixture:
    def test_game_type_in_wsop_range(self):
        for e in load("events_list.json")["events"]:
            assert 0 <= e["gameType"] <= 8

    def test_adapter_converts_all_game_types(self):
        for e in load("events_list.json")["events"]:
            ebs_gt, ebs_mode = map_to_ebs(e["gameType"])
            assert 0 <= ebs_gt <= 21
            assert ebs_mode in ("single", "fixed_rotation", "dealers_choice")

    def test_razz_roundtrip(self):
        razz = next(e for e in load("events_list.json")["events"] if e["gameType"] == 3)
        ebs_gt, _ = map_to_ebs(razz["gameType"])
        assert ebs_gt == 21  # EBS Razz
        # silent corruption 검증: WSOP 3=Razz 를 그대로 저장하면 EBS 3=Pineapple (오류)
        assert ebs_gt != razz["gameType"]

    def test_horse_maps_to_fixed_rotation_mode(self):
        horse = next(e for e in load("events_list.json")["events"] if e["gameType"] == 5)
        _, ebs_mode = map_to_ebs(horse["gameType"])
        assert ebs_mode == "fixed_rotation"


class TestSeatPlayerInfoFixture:
    def test_player_move_status_values(self):
        seats = load("seat_player_info.json")["seats"]
        values = {s["playerMoveStatus"] for s in seats}
        assert values == {0, 1, 2}, "fixture 가 3 값 모두 커버해야 함"

    def test_convert_to_ebs_str(self):
        WSOP_TO_STR = {0: "none", 1: "new", 2: "move"}
        for s in load("seat_player_info.json")["seats"]:
            assert WSOP_TO_STR[s["playerMoveStatus"]] in ("none", "new", "move")


class TestBlindStructureFixture:
    def test_all_5_detail_types_covered(self):
        details = load("blind_structure.json")["blindStructure"]["details"]
        types = {d["detailType"] for d in details}
        assert {0, 1, 2, 3, 4}.issubset(types), "5값 모두 fixture 에 포함돼야 함"
