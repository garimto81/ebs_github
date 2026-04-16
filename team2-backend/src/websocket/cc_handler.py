"""CC WebSocket handler — receives game events, stores in audit_events, forwards to Lobby."""
import json
import logging
import uuid
from datetime import datetime, timezone

from sqlmodel import Session

from src.repositories.event_repository import event_repository

logger = logging.getLogger(__name__)


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
            "type": "Ack",
            "payload": {"status": "error", "error_code": "invalid_json"},
            "source_id": "bo",
            "message_id": str(uuid.uuid4()),
        }

    event_type = msg.get("type", "unknown")
    payload = msg.get("payload", {})
    message_id = msg.get("message_id", str(uuid.uuid4()))
    idempotency_key = msg.get("idempotency_key")
    correlation_id = msg.get("correlation_id")
    causation_id = msg.get("causation_id")

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
