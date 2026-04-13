import pytest
from sqlmodel import Session, SQLModel, create_engine
from sqlalchemy.pool import StaticPool

from bo.db.models import Hand, HandPlayer, HandAction
from bo.services.hand_ws_service import (
    handle_hand_started,
    handle_hand_action,
    handle_hand_completed,
)


@pytest.fixture(autouse=True)
def setup_engine(monkeypatch):
    """Override the engine used by hand_ws_service."""
    import bo.db.models  # noqa: F401 — ensure all SQLModel tables are registered

    test_engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    SQLModel.metadata.create_all(test_engine)
    monkeypatch.setattr("bo.services.hand_ws_service.engine", test_engine)
    yield test_engine


def test_hand_started(setup_engine):
    hand_id = handle_hand_started(
        1,
        {
            "hand_number": 1,
            "game_type": 0,
            "dealer_seat": 3,
            "started_at": "2026-04-09T10:00:00Z",
            "players": [
                {"seat_no": 0, "player_name": "Alice", "stack": 50000},
                {"seat_no": 1, "player_name": "Bob", "stack": 50000},
            ],
        },
    )
    assert hand_id is not None

    with Session(setup_engine) as s:
        hand = s.get(Hand, hand_id)
        assert hand.hand_number == 1
        assert hand.table_id == 1
        players = s.query(HandPlayer).filter_by(hand_id=hand_id).all()
        assert len(players) == 2


def test_hand_action(setup_engine):
    hand_id = handle_hand_started(
        1, {"hand_number": 2, "started_at": "2026-04-09T10:00:00Z"}
    )
    handle_hand_action(
        {
            "hand_id": hand_id,
            "seat_no": 0,
            "action_type": "raise",
            "amount": 200,
            "street": "preflop",
            "action_order": 1,
        }
    )

    with Session(setup_engine) as s:
        actions = s.query(HandAction).filter_by(hand_id=hand_id).all()
        assert len(actions) == 1
        assert actions[0].action_type == "raise"


def test_hand_completed(setup_engine):
    hand_id = handle_hand_started(
        1,
        {
            "hand_number": 3,
            "started_at": "2026-04-09T10:00:00Z",
            "players": [
                {"seat_no": 0, "player_name": "Alice", "stack": 50000},
            ],
        },
    )
    handle_hand_completed(
        {
            "hand_id": hand_id,
            "pot_total": 500,
            "board_cards": '["As","Kh","Qd","Jc","Ts"]',
            "duration_sec": 45,
            "results": [
                {
                    "seat_no": 0,
                    "end_stack": 50500,
                    "is_winner": True,
                    "pnl": 500,
                    "hand_rank": "Straight",
                },
            ],
        }
    )

    with Session(setup_engine) as s:
        hand = s.get(Hand, hand_id)
        assert hand.pot_total == 500
        assert hand.duration_sec == 45
        players = s.query(HandPlayer).filter_by(hand_id=hand_id).all()
        assert players[0].is_winner is True
        assert players[0].pnl == 500
