from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from bo.config import settings
from bo.db.engine import create_db_and_tables


@asynccontextmanager
async def lifespan(app: FastAPI):
    create_db_and_tables()
    from sqlmodel import Session as SqlSession
    from bo.db.engine import engine
    from bo.db.seed import seed
    with SqlSession(engine) as s:
        seed(s)
    yield


def create_app() -> FastAPI:
    app = FastAPI(
        title="EBS Back Office API",
        version="0.1.0",
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins.split(","),
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    from bo.middleware.rbac import ViewerReadOnlyMiddleware
    app.add_middleware(ViewerReadOnlyMiddleware)

    from bo.routers import (
        auth, users, competitions, series, events, flights,
        tables, seats, players, hands, configs, skins,
        blind_structures, audit_logs, reports, sync,
        rfid_readers, decks,
    )

    for router_module in [
        auth, users, competitions, series, events, flights,
        tables, seats, players, hands, configs, skins,
        blind_structures, audit_logs, reports, sync,
        rfid_readers, decks,
    ]:
        app.include_router(router_module.router, prefix="/api/v1")

    from bo.websocket.handlers import router as ws_router
    app.include_router(ws_router)

    @app.get("/health")
    async def health():
        return {"status": "ok"}

    return app


app = create_app()

if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "bo.main:app", host=settings.bo_host, port=settings.bo_port, reload=True
    )
