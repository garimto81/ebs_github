"""CC WebSocket handler — receives game events, stores in audit_events, forwards to Lobby."""
import json
import logging
import uuid
from datetime import datetime, timezone

from sqlmodel import Session

from src.repositories.event_repository import event_repository

logger = logging.getLogger(__name__)


# ── SSOT §9-11: Write* command validation ─────────────────────

_VALID_POKER_ACTIONS: frozenset[str] = frozenset({
    "fold", "check", "call", "bet", "raise", "all_in",
})

# Commands → (required payload fields, ack/rejected type names)
_WRITE_COMMANDS: dict[str, tuple[list[str], str, str]] = {
    "WriteGameInfo": (
        ["game_type", "bet_structure", "small_blind", "big_blind"],
        "GameInfoAck",
        "GameInfoRejected",
    ),
    "WriteDeal": (
        ["hand_number"],
        "DealAck",
        "DealRejected",
    ),
    "WriteAction": (
        ["hand_number", "seat_no", "action"],
        "ActionAck",
        "ActionRejected",
    ),
}


def _build_envelope(type_: str, payload: dict, message_id: str, now_iso: str) -> dict:
    return {
        "type": type_,
        "payload": payload,
        "timestamp": now_iso,
        "server_time": now_iso,
        "source_id": "bo",
        "message_id": str(uuid.uuid4()),
        "original_message_id": message_id,
    }


def _validate_write_command(
    command_type: str, payload: dict,
) -> tuple[bool, str | None]:
    """Return (is_valid, reason_if_invalid)."""
    required, _, _ = _WRITE_COMMANDS[command_type]
    missing = [k for k in required if k not in payload]
    if missing:
        return False, f"missing_required_fields: {missing}"
    # Domain checks
    if command_type == "WriteAction":
        action = payload.get("action")
        if action not in _VALID_POKER_ACTIONS:
            return False, f"invalid_action: {action!r}"
    return True, None


async def handle_cc_message(
    message_text: str,
    table_id: str,
    user_info: dict,
    db: Session,
    manager,
) -> dict | None:
    """Process a single CC→BO message.

    Returns the ack dict to send back, or None on parse error.
    """
    try:
        msg = json.loads(message_text)
    except json.JSONDecodeError:
        return {
            "type": "Error",
            "payload": {"code": "invalid_json", "message": "malformed JSON"},
            "source_id": "bo",
            "message_id": str(uuid.uuid4()),
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "server_time": datetime.now(timezone.utc).isoformat(),
        }

    event_type = msg.get("type", "unknown")
    payload = msg.get("payload", {})
    message_id = msg.get("message_id", str(uuid.uuid4()))
    idempotency_key = msg.get("idempotency_key")
    correlation_id = msg.get("correlation_id")
    causation_id = msg.get("causation_id")

    now_iso = datetime.now(timezone.utc).isoformat()

    # ── Explicit Write commands (SSOT §9-11) ─────────────
    if event_type in _WRITE_COMMANDS:
        required, ack_type, rejected_type = _WRITE_COMMANDS[event_type]
        ok, reason = _validate_write_command(event_type, payload)
        if not ok:
            return _build_envelope(
                rejected_type,
                {"original_message_id": message_id, "reason": reason},
                message_id,
                now_iso,
            )
        # Valid — append to audit_events and forward to lobby
        audit_event = event_repository.append(
            table_id=table_id,
            event_type=event_type.lower(),
            payload=payload,
            correlation_id=correlation_id,
            causation_id=causation_id,
            idempotency_key=idempotency_key,
            actor_user_id=user_info.get("user_id"),
            db=db,
        )
        lobby_event = {
            "type": event_type,
            "table_id": table_id,
            "seq": audit_event.seq,
            "payload": payload,
            "timestamp": msg.get("timestamp", now_iso),
            "server_time": now_iso,
            "source_id": msg.get("source_id", f"cc-table-{table_id}"),
            "message_id": message_id,
        }
        await manager.broadcast("lobby", table_id, lobby_event)
        return _build_envelope(
            ack_type,
            {
                "original_message_id": message_id,
                "status": "ok",
                "seq": audit_event.seq,
            },
            message_id,
            now_iso,
        )

    # Map PascalCase event types to snake_case for audit_events
    event_type_map = {
        "HandStarted": "hand_started",
        "HandEnded": "hand_ended",
        "ActionPerformed": "action_performed",
        "CardDetected": "card_detected",
        "GameChanged": "game_changed",
        "RfidStatusChanged": "rfid_status_changed",
        "OutputStatusChanged": "output_status_changed",
    }
    db_event_type = event_type_map.get(event_type, event_type.lower())

    # Append to audit_events
    audit_event = event_repository.append(
        table_id=table_id,
        event_type=db_event_type,
        payload=payload,
        correlation_id=correlation_id,
        causation_id=causation_id,
        idempotency_key=idempotency_key,
        actor_user_id=user_info.get("user_id"),
        db=db,
    )

    now = datetime.now(timezone.utc).isoformat()

    # Build envelope for Lobby forwarding
    lobby_event = {
        "type": event_type,
        "table_id": table_id,
        "seq": audit_event.seq,
        "payload": payload if isinstance(payload, dict) else json.loads(payload),
        "timestamp": msg.get("timestamp", now),
        "server_time": now,
        "source_id": msg.get("source_id", f"cc-table-{table_id}"),
        "message_id": message_id,
    }

    # Forward to Lobby channel
    await manager.broadcast("lobby", table_id, lobby_event)

    # Ack back to CC
    ack = {
        "type": "Ack",
        "payload": {
            "original_message_id": message_id,
            "status": "ok",
            "seq": audit_event.seq,
        },
        "timestamp": now,
        "source_id": "bo",
        "message_id": str(uuid.uuid4()),
    }
    return ack
