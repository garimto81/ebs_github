"""EBS Back Office — FastAPI Application."""
import uuid
from contextlib import asynccontextmanager
from datetime import datetime, timezone

from fastapi import Depends, FastAPI, Query, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy import text as sa_text
from sqlmodel import Session

from src.app.config import settings
from src.app.database import get_db, init_db
from src.middleware.idempotency import IdempotencyMiddleware
from src.observability.circuit_breaker import CircuitBreaker
from src.observability.distributed_lock import DistributedLock
from src.repositories.event_repository import event_repository
from src.routers.audit import router as audit_router
from src.routers.auth import router as auth_router
from src.routers.blind_structures import router as blind_structures_router
from src.routers.brand_packs import router as brand_packs_router
from src.routers.competitions import router as competitions_router
from src.routers.configs import router as configs_router
from src.routers.decks import router as decks_router
from src.routers.hands import router as hands_router
from src.routers.payout_structures import router as payout_structures_router
from src.routers.players import router as players_router
from src.routers.replay import router as replay_router
from src.routers.reports import router as reports_router
from src.routers.series import router as series_router
from src.routers.settings_kv import router as settings_kv_router
from src.routers.skins import router as skins_router
from src.routers.sync import router as sync_router
from src.routers.tables import router as tables_router
from src.routers.users import router as users_router
from src.routers.wsop_live import router as wsop_live_router
from src.services.undo_service import UndoService
from src.services.wsop_sync_service import WsopSyncService
from src.websocket.cc_handler import handle_cc_message
from src.websocket.lobby_handler import handle_lobby_message
from src.websocket.manager import ConnectionManager


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup / Shutdown."""
    init_db()
    app.state.ws_manager = ConnectionManager()
    app.state.lock = DistributedLock()
    app.state.circuit_breaker = CircuitBreaker()
    app.state.wsop_sync = WsopSyncService(app.state.circuit_breaker)
    app.state.undo_service = UndoService(event_repository)
    yield
    # TODO: cleanup


app = FastAPI(
    title="EBS Back Office",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(IdempotencyMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router, prefix="/api/v1")  # 2026-05-06: frontend `/api/v1/auth/login` 정합
app.include_router(series_router)
app.include_router(tables_router)
app.include_router(players_router)
app.include_router(replay_router)
app.include_router(sync_router)
app.include_router(audit_router)
app.include_router(users_router)
app.include_router(configs_router)
app.include_router(competitions_router)
app.include_router(hands_router)
app.include_router(blind_structures_router)
app.include_router(brand_packs_router)
app.include_router(skins_router)
app.include_router(payout_structures_router)
app.include_router(reports_router)
app.include_router(decks_router)  # SG-006 in-memory deck router
app.include_router(settings_kv_router)  # SG-003 Settings 6탭 skeleton (501)
from src.routers.event_flights import router as event_flights_router  # noqa: E402

app.include_router(event_flights_router)  # Phase 3.B (2026-05-06) — Lobby TopBar cluster levels
app.include_router(wsop_live_router)  # Cycle 20 Wave 2 — WSOP LIVE chip count webhook (#435)


@app.get("/health")
async def health(db: Session = Depends(get_db)):
    try:
        db.execute(sa_text("SELECT 1"))
        return {"status": "ok", "db": "connected"}
    except Exception:
        return JSONResponse(status_code=503, content={"status": "degraded", "db": "disconnected"})


@app.websocket("/ws/cc")
async def ws_cc_endpoint(
    websocket: WebSocket,
    token: str = Query(default=""),
    table_id: str = Query(default=""),
):
    """CC WebSocket endpoint — game data ingest."""
    manager: ConnectionManager = app.state.ws_manager

    try:
        user_info = await manager.connect(
            websocket, token, "cc", table_id=table_id,
        )
    except ValueError:
        await websocket.close(code=4001, reason="Authentication failed")
        return

    # Broadcast OperatorConnected to lobby
    now = datetime.now(timezone.utc).isoformat()
    await manager.broadcast("lobby", table_id, {
        "type": "OperatorConnected",
        "table_id": table_id,
        "payload": {
            "table_id": table_id,
            "operatorId": user_info["user_id"],
            "username": user_info["email"],
        },
        "timestamp": now,
        "server_time": now,
        "source_id": "bo",
        "message_id": str(uuid.uuid4()),
    })

    try:
        while True:
            data = await websocket.receive_text()

            # Get a DB session for this message
            db_gen = get_db()
            db: Session = next(db_gen)
            try:
                ack = await handle_cc_message(
                    data, table_id, user_info, db, manager,
                )
                if ack:
                    await manager.send_personal(websocket, ack)
            finally:
                try:
                    next(db_gen)
                except StopIteration:
                    pass

    except WebSocketDisconnect:
        pass
    finally:
        user_info = await manager.disconnect(websocket, "cc")

        # Broadcast OperatorDisconnected
        if user_info:
            now = datetime.now(timezone.utc).isoformat()
            await manager.broadcast("lobby", user_info.get("table_id", ""), {
                "type": "OperatorDisconnected",
                "table_id": user_info.get("table_id", ""),
                "payload": {
                    "table_id": user_info.get("table_id", ""),
                    "operatorId": user_info["user_id"],
                    "reason": "disconnected",
                },
                "timestamp": now,
                "server_time": now,
                "source_id": "bo",
                "message_id": str(uuid.uuid4()),
            })


@app.websocket("/ws/lobby")
async def ws_lobby_endpoint(
    websocket: WebSocket,
    token: str = Query(default=""),
):
    """Lobby WebSocket endpoint — monitoring subscription."""
    manager: ConnectionManager = app.state.ws_manager

    try:
        user_info = await manager.connect(websocket, token, "lobby")
    except ValueError:
        await websocket.close(code=4001, reason="Authentication failed")
        return

    try:
        while True:
            data = await websocket.receive_text()
            ack = await handle_lobby_message(data, websocket, user_info, manager)
            if ack:
                await manager.send_personal(websocket, ack)
    except WebSocketDisconnect:
        pass
    finally:
        await manager.disconnect(websocket, "lobby")
