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

        role = payload.get("role", "viewer")
        assigned_tables = payload.get("assigned_tables")  # None = unrestricted

        # SSOT §4.3 L573 — Operator is bound to assigned tables.
        # Enforce on /ws/cc (which requires a specific table_id).
        if (
            channel == "cc"
            and role == "operator"
            and assigned_tables is not None
            and table_id not in assigned_tables
        ):
            raise ValueError(
                f"AUTH_TABLE_NOT_ASSIGNED: operator not assigned to table {table_id}"
            )

        user_info = {
            "user_id": payload["sub"],
            "email": payload.get("email", ""),
            "role": role,
            "table_id": table_id,
            "assigned_tables": assigned_tables,
        }

        await websocket.accept()
        self._connections[channel].append((websocket, user_info))
        logger.info(
            "WS connected: channel=%s user=%s table=%s",
            channel, user_info["user_id"], table_id,
        )

        # Phase 3.C (2026-05-06) — broadcast cc session count on cc connect.
        if channel == "cc":
            await self._broadcast_cc_session_count()

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

        # Phase 3.C — broadcast cc session count on cc disconnect.
        if channel == "cc":
            await self._broadcast_cc_session_count()

        return user_info

    async def _broadcast_cc_session_count(self) -> None:
        """Push current cc connection count to all lobby subscribers.

        Lobby clients' `activeCcCountProvider` (frontend) listens for
        `cc_session_count` events and updates the TopBar `cc-pill`.
        """
        count = len(self._connections.get("cc", []))
        await self.broadcast(
            "lobby",
            "*",
            {"type": "cc_session_count", "data": {"count": count}, "seq": 0},
        )

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

    async def disconnect_user(
        self,
        user_id: str,
        payload: dict,
        close_code: int = 4003,
    ) -> int:
        """Force-disconnect every WebSocket bound to `user_id` (IMPL-009, API-05 §13.3).

        대상 user 의 모든 active connection (cc / lobby 양 채널) 에 본 payload 를
        송신한 후 즉시 connection close (custom close code, range 4000-4999 per
        RFC 6455). user_sessions 행 정리는 호출자 (auth_service.force_logout_user)
        가 담당한다.

        Returns: 끊은 connection 수 (debugging / audit 용).
        """
        target = str(user_id)
        message = json.dumps(payload)
        closed = 0
        cc_was_affected = False

        for channel in ("cc", "lobby"):
            kept: list[tuple[WebSocket, dict]] = []
            for ws, info in self._connections.get(channel, []):
                if str(info.get("user_id")) != target:
                    kept.append((ws, info))
                    continue
                try:
                    await ws.send_text(message)
                except Exception:
                    pass  # send 실패해도 close 는 시도
                try:
                    await ws.close(code=close_code)
                except Exception:
                    pass
                self._subscriptions.pop(ws, None)
                closed += 1
                if channel == "cc":
                    cc_was_affected = True
            self._connections[channel] = kept

        # cc 채널 연결이 끊긴 경우 Lobby 의 cc-pill 갱신 (§4.2.10 cc_session_count).
        if cc_was_affected:
            await self._broadcast_cc_session_count()

        return closed
