"""Database engine & session dependency."""
from collections.abc import Generator

from passlib.hash import bcrypt
from sqlmodel import Session, SQLModel, create_engine, select

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
    """Create all tables from SQLModel metadata + seed admin account."""
    SQLModel.metadata.create_all(get_engine())
    _seed_admin()


def _seed_admin() -> None:
    """Ensure default admin account exists (idempotent)."""
    from src.models.user import User

    with Session(get_engine()) as db:
        existing = db.exec(select(User).where(User.email == "admin@ebs.local")).first()
        if existing is None:
            admin = User(
                email="admin@ebs.local",
                password_hash=bcrypt.hash("admin123"),
                display_name="System Admin",
                role="admin",
                is_active=True,
            )
            db.add(admin)
            db.commit()


def get_db() -> Generator[Session, None, None]:
    """FastAPI Depends — yields a DB session per request."""
    with Session(get_engine()) as session:
        yield session
