"""Shared test fixtures for EBS Backend."""
from collections.abc import Generator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.pool import StaticPool
from sqlmodel import Session, SQLModel, create_engine

from src.app.config import Settings
from src.app.database import get_db, set_engine
from src.models.user import User, UserSession  # noqa: F401 — register tables
from src.models.competition import Competition, Series, Event, EventFlight  # noqa: F401
from src.models.table import Table, TableSeat, Player  # noqa: F401
from src.models.audit_event import AuditEvent, IdempotencyKey  # noqa: F401
from src.models.audit_log import AuditLog  # noqa: F401 — register table
from src.security.password import hash_password


# ── Shared in-memory engine (StaticPool = single connection reuse) ──
_test_engine = create_engine(
    "sqlite://",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
set_engine(_test_engine)
SQLModel.metadata.create_all(_test_engine)


@pytest.fixture(autouse=True)
def db_session() -> Generator[Session, None, None]:
    """Per-test DB session + dependency override + cleanup."""
    from src.main import app

    session = Session(_test_engine)

    def _override():
        yield session

    app.dependency_overrides[get_db] = _override

    yield session

    session.close()
    app.dependency_overrides.pop(get_db, None)

    # Clean all rows between tests
    with Session(_test_engine) as cleanup:
        for table in reversed(SQLModel.metadata.sorted_tables):
            cleanup.execute(table.delete())
        cleanup.commit()


# ── FastAPI client ──────────────────────────────
@pytest.fixture
def client() -> Generator[TestClient, None, None]:
    """TestClient — DB dependency is already overridden by db_session."""
    from src.main import app

    with TestClient(app) as c:
        yield c


# ── Seed users ──────────────────────────────────
@pytest.fixture
def seed_users(db_session) -> dict[str, User]:
    """Create admin, operator, viewer test users."""
    users = {}
    for email, password, role, name in [
        ("admin@test.com", "Admin123!", "admin", "Admin User"),
        ("operator@test.com", "Op123!", "operator", "Operator User"),
        ("viewer@test.com", "View123!", "viewer", "Viewer User"),
    ]:
        u = User(
            email=email,
            password_hash=hash_password(password),
            display_name=name,
            role=role,
            is_active=True,
        )
        db_session.add(u)
    db_session.commit()

    from sqlmodel import select
    for u in db_session.exec(select(User)).all():
        users[u.role] = u
    return users


# ── Redis mock ──────────────────────────────────
@pytest.fixture
def fake_redis():
    """fakeredis async instance for lock/idempotency/CB tests."""
    try:
        import fakeredis.aioredis
        return fakeredis.aioredis.FakeRedis()
    except ImportError:
        pytest.skip("fakeredis not installed")


# ── Auth helpers ────────────────────────────────
@pytest.fixture
def test_settings() -> Settings:
    """Test-specific settings override."""
    return Settings(
        database_url="sqlite:///:memory:",
        redis_url="redis://localhost:6379/15",
        jwt_secret="test-secret-do-not-use-in-prod",
        auth_profile="dev",
        log_level="DEBUG",
    )
