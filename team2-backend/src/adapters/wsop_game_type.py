"""WSOP LIVE ↔ EBS GameType enum adapter.

Schema.md §events.game_type "WSOP LIVE 정렬 (game_type)" 서브섹션 참조.

WSOP LIVE EventGameType (9종, Confluence 1960411325):
  0=Holdem, 1=Omaha, 2=Stud, 3=Razz, 4=Lowball,
  5=HORSE, 6=DealerChoice, 7=Mixed, 8=Badugi

EBS game_type (22종, seed/README.md §2):
  0=NLHE, 1=LHE, 2=Short Deck, 3=Pineapple,
  4=PLO, 5=Omaha Hi-Lo, 6=5-Card PLO, 7=5-Card PLO Hi-Lo,
  8=Big O, 9=6-Card PLO, 10=Sviten, 11=Courchevel,
  12=NL 2-7 Single Draw, 13=2-7 Triple, 14=A-5 Triple,
  15=Badugi, 16=Badacey, 17=Badeucey, 18=5-Card Draw,
  19=7-Card Stud, 20=Stud Hi-Lo, 21=Razz

HORSE/Mixed/DealerChoice 는 단일 정수로 표현 불가 →
  (game_type, game_mode, allowed_games) 3필드 조합이 SSOT.
"""

from __future__ import annotations

# WSOP LIVE → EBS 기본값 매핑 (1:N 매핑의 기본값)
WSOP_TO_EBS_DEFAULT: dict[int, int] = {
    0: 0,   # Holdem        → NLHE
    1: 4,   # Omaha         → PLO
    2: 19,  # Stud          → 7-Card Stud
    3: 21,  # Razz          → Razz
    4: 12,  # Lowball       → NL 2-7 Single Draw
    8: 15,  # Badugi        → Badugi
}

# EBS → WSOP LIVE 역인덱스 (N:1 손실 없음)
EBS_TO_WSOP: dict[int, int] = {
    # Holdem family (0~3)
    0: 0, 1: 0, 2: 0, 3: 0,
    # Omaha family (4~11)
    4: 1, 5: 1, 6: 1, 7: 1, 8: 1, 9: 1, 10: 1, 11: 1,
    # Lowball / Draw family (12~14, 18)
    12: 4, 13: 4, 14: 4, 18: 4,
    # Badugi family (15~17)
    15: 8, 16: 8, 17: 8,
    # Stud family (19~20)
    19: 2, 20: 2,
    # Razz
    21: 3,
}

# game_mode 조합으로 표현되는 WSOP LIVE 값
# (game_type 단독으로는 매핑 불가)
WSOP_MODE_MAP: dict[int, str] = {
    5: "fixed_rotation",   # HORSE
    6: "dealers_choice",   # DealerChoice
    7: "fixed_rotation",   # Mixed
}


def map_to_ebs(wsop_game_type: int, event_game_mode: str | None = None) -> tuple[int, str]:
    """WSOP LIVE GameType → (EBS game_type, EBS game_mode).

    Args:
        wsop_game_type: WSOP LIVE EventGameType enum (0-8)
        event_game_mode: 기존 EBS game_mode (Mix 게임 보존용)

    Returns:
        (ebs_game_type, ebs_game_mode)

    Raises:
        ValueError: 알 수 없는 wsop_game_type
    """
    if wsop_game_type in WSOP_TO_EBS_DEFAULT:
        return WSOP_TO_EBS_DEFAULT[wsop_game_type], event_game_mode or "single"
    if wsop_game_type in WSOP_MODE_MAP:
        # HORSE/Mixed/DealerChoice: 기본 game_type 은 NLHE, game_mode 가 실제 정보
        return 0, WSOP_MODE_MAP[wsop_game_type]
    raise ValueError(f"Unknown WSOP LIVE GameType: {wsop_game_type}")


def map_to_wsop(ebs_game_type: int, ebs_game_mode: str | None = None) -> int:
    """EBS game_type → WSOP LIVE GameType.

    Args:
        ebs_game_type: EBS game_type enum (0-21)
        ebs_game_mode: EBS game_mode (single/fixed_rotation/dealers_choice)

    Returns:
        WSOP LIVE EventGameType enum (0-8)

    Raises:
        ValueError: 알 수 없는 ebs_game_type
    """
    if ebs_game_mode == "dealers_choice":
        return 6  # DealerChoice
    if ebs_game_mode == "fixed_rotation":
        # HORSE vs Mixed 는 allowed_games 로 구분. 기본 HORSE.
        return 5
    if ebs_game_type in EBS_TO_WSOP:
        return EBS_TO_WSOP[ebs_game_type]
    raise ValueError(f"Unknown EBS game_type: {ebs_game_type}")
