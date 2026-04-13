"""Handles Hand events received via WebSocket from CC."""

from sqlmodel import Session, select

from bo.db.engine import engine
from bo.db.models import Hand, HandPlayer, HandAction
from bo.db.models.base import utcnow


def handle_hand_started(table_id: int, payload: dict) -> int | None:
    """Insert a new Hand record. Returns hand_id."""
    with Session(engine) as session:
        hand = Hand(
            table_id=table_id,
            hand_number=payload.get("hand_number", 0),
            game_type=payload.get("game_type", 0),
            bet_structure=payload.get("bet_structure", 0),
            dealer_seat=payload.get("dealer_seat", -1),
            started_at=payload.get("started_at", utcnow()),
        )
        session.add(hand)
        session.commit()
        session.refresh(hand)

        # Insert players if provided
        players = payload.get("players", [])
        for p in players:
            hp = HandPlayer(
                hand_id=hand.hand_id,
                seat_no=p.get("seat_no", 0),
                player_id=p.get("player_id"),
                player_name=p.get("player_name", "Unknown"),
                start_stack=p.get("stack", 0),
            )
            session.add(hp)
        session.commit()

        return hand.hand_id


def handle_hand_action(payload: dict) -> None:
    """Insert a HandAction record."""
    with Session(engine) as session:
        action = HandAction(
            hand_id=payload.get("hand_id"),
            seat_no=payload.get("seat_no", 0),
            action_type=payload.get("action_type", "unknown"),
            action_amount=payload.get("amount", 0),
            pot_after=payload.get("pot_after"),
            street=payload.get("street", "preflop"),
            action_order=payload.get("action_order", 0),
            board_cards=payload.get("board_cards"),
            action_time=payload.get("action_time"),
        )
        session.add(action)
        session.commit()


def handle_hand_completed(payload: dict) -> None:
    """Update Hand with end data, update HandPlayer results."""
    with Session(engine) as session:
        hand_id = payload.get("hand_id")
        if not hand_id:
            return

        hand = session.get(Hand, hand_id)
        if not hand:
            return

        hand.ended_at = payload.get("ended_at", utcnow())
        hand.pot_total = payload.get("pot_total", 0)
        hand.board_cards = payload.get("board_cards", "[]")
        hand.duration_sec = payload.get("duration_sec", 0)
        hand.current_street = payload.get("current_street")
        session.add(hand)

        # Update player results
        results = payload.get("results", [])
        for r in results:
            hp = session.exec(
                select(HandPlayer).where(
                    HandPlayer.hand_id == hand_id,
                    HandPlayer.seat_no == r.get("seat_no", -1),
                )
            ).first()
            if hp:
                hp.end_stack = r.get("end_stack", hp.start_stack)
                hp.final_action = r.get("final_action")
                hp.is_winner = r.get("is_winner", False)
                hp.pnl = r.get("pnl", 0)
                hp.hand_rank = r.get("hand_rank")
                hp.hole_cards = r.get("hole_cards", "[]")
                hp.vpip = r.get("vpip", False)
                hp.pfr = r.get("pfr", False)
                session.add(hp)

        session.commit()
