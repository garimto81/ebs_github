"""Lobby WebSocket handler — subscription management + BO→Lobby event push."""
import json
import logging
import uuid
from datetime import datetime, timezone

from fastapi import WebSocket

logger = logging.getLogger(__name__)


async def handle_lobby_message(
    message_text: str,
    websocket: WebSocket,
    user_info: dict,
    manager,
) -> dict | None:
    """Process a single Lobby client message.

    Lobby clients send subscription/filter commands.
    Returns ack dict or None.
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

    msg_type = msg.get("type", "")
    now = datetime.now(timezone.utc).isoformat()

    if msg_type == "Subscribe":
        # Set subscription filters
        filters = {
            "table_ids": msg.get("payload", {}).get("table_ids"),
            "event_types": msg.get("payload", {}).get("event_types"),
        }
        manager.set_subscription(websocket, filters)

        return {
            "type": "Ack",
            "payload": {
                "original_message_id": msg.get("message_id", ""),
                "status": "ok",
                "subscribed": True,
            },
            "timestamp": now,
            "source_id": "bo",
            "message_id": str(uuid.uuid4()),
        }

    elif msg_type == "Unsubscribe":
        manager.set_subscription(websocket, {})
        return {
            "type": "Ack",
            "payload": {
                "original_message_id": msg.get("message_id", ""),
                "status": "ok",
                "subscribed": False,
            },
            "timestamp": now,
            "source_id": "bo",
            "message_id": str(uuid.uuid4()),
        }

    # Unknown message type — just ack
    return {
        "type": "Ack",
        "payload": {
            "original_message_id": msg.get("message_id", ""),
            "status": "ok",
        },
        "timestamp": now,
        "source_id": "bo",
        "message_id": str(uuid.uuid4()),
    }


async def broadcast_event_flight_summary(manager, payload: dict) -> int:
    """Broadcast an event_flight_summary to all Lobby subscribers.

    Called periodically (30s) or on significant events (hand end, elimination).
    """
    now = datetime.now(timezone.utc).isoformat()
    event = {
        "type": "event_flight_summary",
        "table_id": "*",
        "payload": payload,
        "timestamp": now,
        "server_time": now,
        "source_id": "bo",
        "message_id": str(uuid.uuid4()),
    }
    return await manager.broadcast("lobby", "*", event)


async def broadcast_clock_tick(manager, payload: dict) -> int:
    """Broadcast a clock_tick to all Lobby subscribers."""
    now = datetime.now(timezone.utc).isoformat()
    event = {
        "type": "clock_tick",
        "table_id": "*",
        "payload": payload,
        "timestamp": now,
        "server_time": now,
        "source_id": "bo",
        "message_id": str(uuid.uuid4()),
    }
    return await manager.broadcast("lobby", "*", event)


async def broadcast_clock_level_changed(manager, payload: dict) -> int:
    """Broadcast a clock_level_changed to all Lobby subscribers."""
    now = datetime.now(timezone.utc).isoformat()
    event = {
        "type": "clock_level_changed",
        "table_id": "*",
        "payload": payload,
        "timestamp": now,
        "server_time": now,
        "source_id": "bo",
        "message_id": str(uuid.uuid4()),
    }
    return await manager.broadcast("lobby", "*", event)
