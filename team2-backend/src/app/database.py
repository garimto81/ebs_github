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


_DEV_SEED_ADMINS: tuple[tuple[str, str, str], ...] = (
    # (email, password, display_name) — dev/integration-tests seed targets.
    # SECURITY: AUTH_PROFILE != "dev" 환경에서는 seed 하지 않는다 (production 보호).
    ("admin@ebs.local", "admin123", "System Admin"),
    ("admin@ebs.test", "test-password-1234", "Integration Test Admin"),
)


def _seed_admin() -> None:
    """Ensure dev/integration-tests admin accounts exist (idempotent).

    seed 대상은 `_DEV_SEED_ADMINS` 표 참조. 기존 admin@ebs.local 은 backward
    compat 보존, admin@ebs.test (test-password-1234) 는 integration-tests
    scenarios (`_env.http`, `10-auth-login-profile.http`) 및 issue #236 KPI
    (`curl :18001/api/v1/auth/login 200 OK`) 정합용. `AUTH_PROFILE=live`
    환경에서는 settings.auth_profile 검사로 skip 한다 (production 보호).
    """
    from src.models.user import User

    # Production safety: 환경에 따라 seed skip.
    auth_profile = (getattr(settings, "auth_profile", "dev") or "dev").lower()
    if auth_profile == "live":
        return

    with Session(get_engine()) as db:
        for email, password, display_name in _DEV_SEED_ADMINS:
            existing = db.exec(select(User).where(User.email == email)).first()
            if existing is not None:
                continue
            db.add(User(
                email=email,
                password_hash=bcrypt.hash(password),
                display_name=display_name,
                role="admin",
                is_active=True,
            ))
        db.commit()


def get_db() -> Generator[Session, None, None]:
    """FastAPI Depends — yields a DB session per request."""
    with Session(get_engine()) as session:
        yield session
