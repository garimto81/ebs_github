from pydantic import BaseModel


class HandRead(BaseModel):
    hand_id: int
    table_id: int
    hand_number: int
    game_type: int
    bet_structure: int
    dealer_seat: int
    board_cards: str
    pot_total: int
    current_street: str | None
    started_at: str
    ended_at: str | None
    duration_sec: int
    created_at: str


class HandPlayerRead(BaseModel):
    id: int
    hand_id: int
    seat_no: int
    player_id: int | None
    player_name: str
    hole_cards: str
    start_stack: int
    end_stack: int
    final_action: str | None
    is_winner: bool
    pnl: int


class HandActionRead(BaseModel):
    id: int
    hand_id: int
    seat_no: int
    action_type: str
    action_amount: int
    pot_after: int | None
    street: str
    action_order: int
    action_time: str | None
