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
    """Ensure default admin account exists (idempotent).

    passlib 의 bcrypt wrap-bug self-test 가 bcrypt 4.x 와 호환되지 않으면
    `ValueError: password cannot be longer than 72 bytes` 가 발생한다 (실제
    "admin123" 은 8 byte 이며 메시지는 self-test 부산물). 이 경우 startup
    을 차단하지 않고 hash 시도 자체를 skip 한다 — admin 시드는 dev 편의
    이고 smoke / health probe 에는 의존하지 않는다.
    """
    from src.models.user import User

    try:
        password_hash = bcrypt.hash("admin123")
    except ValueError:
        # passlib + bcrypt 4.x 호환성 문제 — admin seed skip
        return

    with Session(get_engine()) as db:
        existing = db.exec(select(User).where(User.email == "admin@ebs.local")).first()
        if existing is None:
            admin = User(
                email="admin@ebs.local",
                password_hash=password_hash,
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
