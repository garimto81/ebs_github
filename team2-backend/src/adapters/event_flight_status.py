"""EventFlight status adapter — CCR-047 / BS-00 §3.6 alignment.

SSOT declares `event_flights.status` as `INT CHECK IN (0,1,2,4,5,6)` but the
current DB column is TEXT. WSOP LIVE sends integers, which previously would
have been written as-is into a TEXT column (silent cast or failure).

This adapter gatekeeps all writes:
- `int_to_text(i)` — WSOP→EBS conversion before UPSERT
- `text_to_int(s)` — for future INT migration + API responses
- `VALID_TEXT` — canonical allowed TEXT values (rejects typos)

Full INT migration is tracked in Backlog B-066 (requires separating Clock FSM
state from EventFlight.status first; see clock_service.py).
"""
from __future__ import annotations


# SSOT BS-00 §3.6 / Backend_HTTP.md L307 — canonical states.
# NOTE: value 3 is intentionally skipped to match WSOP LIVE EventFlightStatus enum.
INT_TO_TEXT: dict[int, str] = {
    0: "created",
    1: "announce",
    2: "registering",
    4: "running",
    5: "completed",
    6: "canceled",
}

TEXT_TO_INT: dict[str, int] = {v: k for k, v in INT_TO_TEXT.items()}

VALID_TEXT: frozenset[str] = frozenset(INT_TO_TEXT.values())
VALID_INT: frozenset[int] = frozenset(INT_TO_TEXT.keys())


class EventFlightStatusError(ValueError):
    """Raised when an EventFlight status value is not in the SSOT enum."""


def int_to_text(value: int) -> str:
    """Convert WSOP LIVE integer → EBS canonical text. Raises on unknown."""
    if value not in INT_TO_TEXT:
        raise EventFlightStatusError(
            f"Unknown EventFlight status int {value!r} "
            f"(valid: {sorted(INT_TO_TEXT)})"
        )
    return INT_TO_TEXT[value]


def text_to_int(value: str) -> int:
    """Convert EBS canonical text → integer. Raises on unknown."""
    if value not in TEXT_TO_INT:
        raise EventFlightStatusError(
            f"Unknown EventFlight status text {value!r} "
            f"(valid: {sorted(TEXT_TO_INT)})"
        )
    return TEXT_TO_INT[value]


def normalize(value: int | str) -> str:
    """Accept either int or text form, return canonical text (for TEXT column)."""
    if isinstance(value, int):
        return int_to_text(value)
    if isinstance(value, str) and value in VALID_TEXT:
        return value
    raise EventFlightStatusError(
        f"Invalid EventFlight status: {value!r}"
    )
