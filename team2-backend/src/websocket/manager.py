"""WebSocket ConnectionManager — API-05 §1 connection architecture."""
import json
import logging
from typing import Optional

from fastapi import WebSocket
from jose import JWTError

from src.security.jwt import decode_token

logger = logging.getLogger(__name__)


class ConnectionManager:
    """Manages WebSocket connections for CC and Lobby channels."""

    def __init__(self):
        # channel -> list of (websocket, user_info) tuples
        self._connections: dict[str, list[tuple[WebSocket, dict]]] = {
            "cc": [],
            "lobby": [],
        }
        # websocket -> subscription filters (for lobby)
        self._subscriptions: dict[WebSocket, dict] = {}

    async def connect(
        self,
        websocket: WebSocket,
        token: str,
        channel: str,
        table_id: Optional[str] = None,
    ) -> dict:
        """Authenticate via JWT and register the connection.

        Returns user_info dict on success.
        Raises ValueError on auth failure.
        """
        try:
            payload = decode_token(token)
            if payload.get("type") != "access":
                raise ValueError("Invalid token type")
        except (JWTError, ValueError, KeyError) as exc:
            raise ValueError(f"Authentication failed: {exc}")

        user_info = {
            "user_id": payload["sub"],
            "email": payload.get("email", ""),
            "role": payload.get("role", "viewer"),
            "table_id": table_id,
        }

        await websocket.accept()
        self._connections[channel].append((websocket, user_info))
        logger.info(
            "WS connected: channel=%s user=%s table=%s",
            channel, user_info["user_id"], table_id,
        )
        return user_info

    async def disconnect(self, websocket: WebSocket, channel: str) -> Optional[dict]:
        """Remove connection. Returns user_info if found, else None."""
        conns = self._connections.get(channel, [])
        user_info = None
        for i, (ws, info) in enumerate(conns):
            if ws is websocket:
                user_info = info
                conns.pop(i)
                break

        self._subscriptions.pop(websocket, None)

        if user_info:
            logger.info(
                "WS disconnected: channel=%s user=%s",
                channel, user_info["user_id"],
            )
        return user_info

    async def broadcast(
        self,
        channel: str,
        table_id: str,
        event_data: dict,
    ) -> int:
        """Send event to all subscribers on a channel. Returns send count."""
        message = json.dumps(event_data)
        sent = 0
        stale: list[tuple[WebSocket, dict]] = []

        for ws, info in self._connections.get(channel, []):
            # Check subscription filter for lobby
            if channel == "lobby":
                subs = self._subscriptions.get(ws)
                if subs:
                    table_filter = subs.get("table_ids")
                    type_filter = subs.get("event_types")
                    if table_filter and table_id not in table_filter and table_id != "*":
                        continue
                    if type_filter and event_data.get("type") not in type_filter:
                        continue

            try:
                await ws.send_text(message)
                sent += 1
            except Exception:
                stale.append((ws, info))

        # Remove stale connections
        if stale:
            stale_ws_ids = {id(ws) for ws, _ in stale}
            self._connections[channel] = [
                (ws, info) for ws, info in self._connections.get(channel, [])
                if id(ws) not in stale_ws_ids
            ]

        return sent

    async def send_personal(self, websocket: WebSocket, data: dict) -> None:
        """Send a message to a specific client."""
        await websocket.send_text(json.dumps(data))

    def set_subscription(self, websocket: WebSocket, filters: dict) -> None:
        """Set subscription filters for a lobby connection."""
        self._subscriptions[websocket] = filters

    def get_connections(self, channel: str) -> list[tuple[WebSocket, dict]]:
        """Get all connections for a channel (read-only view)."""
        return list(self._connections.get(channel, []))
