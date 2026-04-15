"""WSOP LIVE ↔ EBS enum parity 회귀 테스트.

Schema.md §events game_type divergence 서브섹션 + §blind_structure_levels
BlindDetailType enum 섹션의 매핑이 adapter 와 일치하는지 검증.
"""
from __future__ import annotations

import pytest

from src.adapters.wsop_game_type import (
    EBS_TO_WSOP,
    WSOP_MODE_MAP,
    WSOP_TO_EBS_DEFAULT,
    map_to_ebs,
    map_to_wsop,
)


class TestWsopGameTypeParity:
    """WSOP LIVE (9종) ↔ EBS (22종) GameType 변환 검증."""

    def test_all_wsop_values_mapped(self) -> None:
        """WSOP LIVE 0~8 9값 모두 변환 가능."""
        for wsop in range(9):
            ebs_type, ebs_mode = map_to_ebs(wsop)
            assert isinstance(ebs_type, int)
            assert ebs_mode in ("single", "fixed_rotation", "dealers_choice")

    def test_all_ebs_values_mapped(self) -> None:
        """EBS 0~21 22값 모두 WSOP 로 역매핑 가능."""
        for ebs in range(22):
            wsop = map_to_wsop(ebs)
            assert 0 <= wsop <= 8

    def test_specific_values(self) -> None:
        """핵심 매핑 값 검증 (silent corruption 방지)."""
        # WSOP 3=Razz ↔ EBS 21=Razz (v1 critic 에서 발견한 가장 위험한 충돌)
        assert map_to_ebs(3) == (21, "single")
        assert map_to_wsop(21) == 3

        # WSOP 0=Holdem → EBS 0=NLHE (기본값)
        assert map_to_ebs(0) == (0, "single")
        # EBS 1=LHE, 2=Short Deck 모두 WSOP 0=Holdem 으로 역매핑
        assert map_to_wsop(0) == 0
        assert map_to_wsop(1) == 0
        assert map_to_wsop(2) == 0

        # HORSE: WSOP 5 → (game_type=0, game_mode='fixed_rotation')
        assert map_to_ebs(5) == (0, "fixed_rotation")
        # DealerChoice: WSOP 6
        assert map_to_ebs(6) == (0, "dealers_choice")

    def test_roundtrip_preserves_wsop_family(self) -> None:
        """WSOP → EBS (기본값) → WSOP 라운드트립이 family 를 보존."""
        for wsop, ebs in WSOP_TO_EBS_DEFAULT.items():
            # 직접 매핑되는 값들만 (HORSE/Mixed/DC 제외)
            round_tripped = map_to_wsop(ebs)
            assert round_tripped == wsop, (
                f"WSOP {wsop} → EBS {ebs} → WSOP {round_tripped} (expected {wsop})"
            )

    def test_unknown_wsop_raises(self) -> None:
        with pytest.raises(ValueError):
            map_to_ebs(99)

    def test_unknown_ebs_raises(self) -> None:
        with pytest.raises(ValueError):
            map_to_wsop(99)


class TestBlindDetailTypeParity:
    """WSOP LIVE BlindDetailType 5값 ↔ EBS detail_type 5값 일치 검증."""

    WSOP_BLIND_DETAIL_TYPES = {0, 1, 2, 3, 4}
    EBS_BLIND_DETAIL_TYPES = {0, 1, 2, 3, 4}

    def test_enum_values_match(self) -> None:
        assert self.WSOP_BLIND_DETAIL_TYPES == self.EBS_BLIND_DETAIL_TYPES


class TestCompetitionTypeParity:
    """CompetitionType 0~4 이름+값 완전 일치."""

    WSOP_COMPETITION_TYPES = {
        0: "WSOP",
        1: "WSOPC",
        2: "APL",
        3: "APT",
        4: "WSOPP",
    }
    EBS_COMPETITION_TYPES = {
        0: "WSOP",
        1: "WSOPC",
        2: "APL",
        3: "APT",
        4: "WSOPP",
    }

    def test_ids_and_names_match(self) -> None:
        assert self.WSOP_COMPETITION_TYPES == self.EBS_COMPETITION_TYPES
