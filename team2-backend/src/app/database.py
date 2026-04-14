"""Database engine & session dependency."""
from collections.abc import Generator
from typing import Optional

from sqlmodel import Session, SQLModel, create_engine

from src.app.config import settings

_engine = None


def get_engine():
    """Lazy engine creation."""
    global _engine
    if _engine is None:
        _engine = create_engine(
            settings.database_url,
            connect_args={"check_same_thread": False} if "sqlite" in settings.database_url else {},
            echo=False,
        )
    return _engine


def set_engine(engine) -> None:
    """Override engine (used in tests)."""
    global _engine
    _engine = engine


def init_db() -> None:
    """Create all tables from SQLModel metadata."""
    SQLModel.metadata.create_all(get_engine())


def get_db() -> Generator[Session, None, None]:
    """FastAPI Depends — yields a DB session per request."""
    with Session(get_engine()) as session:
        yield session
