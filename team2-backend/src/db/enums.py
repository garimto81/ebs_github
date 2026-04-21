"""FSM enum canonical source — BS_Overview §3 (2026-04-21).

본 모듈은 BS_Overview §3 의 7개 FSM (TableFSM / HandFSM / SeatFSM / PlayerStatus /
DeckFSM / EventFSM / ClockFSM) 의 직렬화 값을 Python enum 으로 선언한다.

직렬화 규약 (BS_Overview §3.1):
  - display label 은 UPPERCASE (문서/UI 용)
  - DB column / REST & WebSocket payload 직렬화 값은 **lowercase**
  - `str(Enum.VALUE)` 은 lowercase wire 값을 반환해야 함

사용:
  from db.enums import TableFSM, SeatFSM
  t.status = TableFSM.LIVE.value   # "live"

`tools/spec_drift_check.py --fsm` 가 본 파일을 scan 하여 BS_Overview §3 과 일치
여부를 검증한다. 신규 상태 추가 시 BS_Overview §3 먼저 보강 후 본 파일을 추가.
"""
from __future__ import annotations

from enum import Enum


class TableFSM(str, Enum):
    """Table 상태 — BS_Overview §3.1. DB: tables.status."""

    EMPTY = "empty"
    SETUP = "setup"
    LIVE = "live"
    PAUSED = "paused"
    CLOSED = "closed"


class HandFSM(str, Enum):
    """Hand 상태 (game_phase) — BS_Overview §3.2 + BS-06-00-REF §1.9."""

    IDLE = "idle"
    SETUP_HAND = "setup_hand"
    PRE_FLOP = "pre_flop"
    FLOP = "flop"
    TURN = "turn"
    RIVER = "river"
    SHOWDOWN = "showdown"
    HAND_COMPLETE = "hand_complete"
    RUN_IT_MULTIPLE = "run_it_multiple"


class SeatFSM(str, Enum):
    """Seat 상태 — BS_Overview §3.3. DB: table_seats.status."""

    EMPTY = "empty"
    NEW = "new"
    PLAYING = "playing"
    MOVED = "moved"
    BUSTED = "busted"
    RESERVED = "reserved"
    OCCUPIED = "occupied"
    WAITING = "waiting"
    HOLD = "hold"


class PlayerStatus(str, Enum):
    """Hand 내 Player 상태 — BS_Overview §3.4 + BS-06-00-REF §1.5.2."""

    ACTIVE = "active"
    FOLDED = "folded"
    ALLIN = "allin"
    ELIMINATED = "eliminated"
    SITTING_OUT = "sitting_out"


class DeckFSM(str, Enum):
    """Deck 상태 — BS_Overview §3.5 + BS-04-01."""

    UNREGISTERED = "unregistered"
    REGISTERING = "registering"
    REGISTERED = "registered"
    PARTIAL = "partial"
    MOCK = "mock"


class EventFSM(str, Enum):
    """Event 진행 상태 — BS_Overview §3.6."""

    CREATED = "created"
    ANNOUNCED = "announced"
    REGISTERING = "registering"
    RUNNING = "running"
    COMPLETED = "completed"
    CANCELED = "canceled"


class ClockFSM(str, Enum):
    """Tournament Clock 상태 — BS_Overview §3.7. 소유: team2 (clock_service)."""

    STOPPED = "stopped"
    RUNNING = "running"
    PAUSED = "paused"
    BREAK = "break"
    DINNER_BREAK = "dinner_break"


__all__ = [
    "TableFSM",
    "HandFSM",
    "SeatFSM",
    "PlayerStatus",
    "DeckFSM",
    "EventFSM",
    "ClockFSM",
]
