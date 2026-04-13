from fastapi import WebSocket
import json


class ConnectionManager:
    """WebSocket connection manager with room-based routing."""

    def __init__(self):
        self.rooms: dict[str, list[WebSocket]] = {}
        self.client_rooms: dict[int, list[str]] = {}

    async def connect(self, websocket: WebSocket, room: str):
        await websocket.accept()
        if room not in self.rooms:
            self.rooms[room] = []
        self.rooms[room].append(websocket)
        ws_id = id(websocket)
        if ws_id not in self.client_rooms:
            self.client_rooms[ws_id] = []
        self.client_rooms[ws_id].append(room)

    def subscribe(self, websocket: WebSocket, room: str):
        if room not in self.rooms:
            self.rooms[room] = []
        if websocket not in self.rooms[room]:
            self.rooms[room].append(websocket)
            ws_id = id(websocket)
            if ws_id not in self.client_rooms:
                self.client_rooms[ws_id] = []
            self.client_rooms[ws_id].append(room)

    def unsubscribe(self, websocket: WebSocket, room: str):
        if room in self.rooms:
            self.rooms[room] = [ws for ws in self.rooms[room] if ws != websocket]
            if not self.rooms[room]:
                del self.rooms[room]

    def disconnect(self, websocket: WebSocket, room: str):
        self.unsubscribe(websocket, room)
        ws_id = id(websocket)
        if ws_id in self.client_rooms:
            self.client_rooms[ws_id] = [
                r for r in self.client_rooms[ws_id] if r != room
            ]

    def disconnect_all(self, websocket: WebSocket):
        ws_id = id(websocket)
        rooms = self.client_rooms.pop(ws_id, [])
        for room in rooms:
            if room in self.rooms:
                self.rooms[room] = [
                    ws for ws in self.rooms[room] if ws != websocket
                ]
                if not self.rooms[room]:
                    del self.rooms[room]

    async def broadcast(self, room: str, message: dict):
        if room in self.rooms:
            data = json.dumps(message)
            dead: list[WebSocket] = []
            for ws in self.rooms[room]:
                try:
                    await ws.send_text(data)
                except Exception:
                    dead.append(ws)
            for ws in dead:
                self.unsubscribe(ws, room)

    async def send_personal(self, websocket: WebSocket, message: dict):
        await websocket.send_text(json.dumps(message))


manager = ConnectionManager()
