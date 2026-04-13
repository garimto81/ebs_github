from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query
from bo.websocket.manager import manager
from bo.websocket.events import (
    WsMessage, SUBSCRIBE, SUBSCRIBE_ACK, UNSUBSCRIBE,
    HAND_STARTED, HAND_ACTION, HAND_COMPLETED,
)
from bo.services.hand_ws_service import (
    handle_hand_started, handle_hand_action, handle_hand_completed,
)

router = APIRouter()


@router.websocket("/ws/cc")
async def cc_endpoint(websocket: WebSocket, table_id: int = Query(...)):
    """Command Center WebSocket — scoped to a single table."""
    room = f"table:{table_id}"
    await manager.connect(websocket, room)
    try:
        while True:
            data = await websocket.receive_json()
            event_type = data.get("type", "unknown")
            payload = data.get("payload", {})

            # Persist hand events to DB
            if event_type == HAND_STARTED:
                hand_id = handle_hand_started(table_id, payload)
                if hand_id:
                    payload["hand_id"] = hand_id
            elif event_type == HAND_ACTION:
                handle_hand_action(payload)
            elif event_type == HAND_COMPLETED:
                handle_hand_completed(payload)

            # Broadcast to all subscribers (CC + Lobby)
            message = WsMessage(
                type=event_type,
                payload=payload,
                source_id=f"cc-table-{table_id}",
            )
            await manager.broadcast(room, message.to_dict())
    except WebSocketDisconnect:
        manager.disconnect(websocket, room)


@router.websocket("/ws/lobby")
async def lobby_endpoint(websocket: WebSocket):
    """Lobby WebSocket — subscribes to multiple tables."""
    room = "lobby"
    await manager.connect(websocket, room)
    try:
        while True:
            data = await websocket.receive_json()
            msg_type = data.get("type", "")

            if msg_type == SUBSCRIBE:
                table_ids = data.get("payload", {}).get("table_ids", [])
                for tid in table_ids:
                    manager.subscribe(websocket, f"table:{tid}")
                ack = WsMessage(
                    type=SUBSCRIBE_ACK,
                    payload={"table_ids": table_ids},
                )
                await manager.send_personal(websocket, ack.to_dict())

            elif msg_type == UNSUBSCRIBE:
                table_ids = data.get("payload", {}).get("table_ids", [])
                for tid in table_ids:
                    manager.unsubscribe(websocket, f"table:{tid}")
    except WebSocketDisconnect:
        manager.disconnect_all(websocket)
