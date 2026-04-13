import pytest
from fastapi.testclient import TestClient
from sqlalchemy.pool import StaticPool
from sqlmodel import Session, SQLModel, create_engine

from bo.db.engine import get_session
from bo.main import create_app


@pytest.fixture(name="engine")
def engine_fixture():
    import bo.db.models  # noqa: F401 — ensure all SQLModel tables are registered
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    SQLModel.metadata.create_all(engine)
    yield engine
    SQLModel.metadata.drop_all(engine)


@pytest.fixture(name="session")
def session_fixture(engine):
    with Session(engine) as session:
        yield session


@pytest.fixture(name="client")
def client_fixture(session):
    app = create_app()

    def get_session_override():
        yield session

    app.dependency_overrides[get_session] = get_session_override
    with TestClient(app) as client:
        yield client


@pytest.fixture(name="admin_user")
def admin_user_fixture(session):
    from bo.db.models import User
    from bo.services.auth_service import hash_password

    user = User(
        email="admin@test.local",
        password_hash=hash_password("test1234!"),
        display_name="Test Admin",
        role="admin",
    )
    session.add(user)
    session.commit()
    session.refresh(user)
    return user


@pytest.fixture(name="admin_token")
def admin_token_fixture(admin_user):
    from bo.services.auth_service import create_access_token

    return create_access_token(admin_user)


@pytest.fixture(name="auth_headers")
def auth_headers_fixture(admin_token):
    return {"Authorization": f"Bearer {admin_token}"}


@pytest.fixture(name="operator_user")
def operator_user_fixture(session):
    from bo.db.models import User
    from bo.services.auth_service import hash_password

    user = User(
        email="op@test.local",
        password_hash=hash_password("test1234!"),
        display_name="Test Op",
        role="operator",
    )
    session.add(user)
    session.commit()
    session.refresh(user)
    return user


@pytest.fixture(name="viewer_user")
def viewer_user_fixture(session):
    from bo.db.models import User
    from bo.services.auth_service import hash_password

    user = User(
        email="view@test.local",
        password_hash=hash_password("test1234!"),
        display_name="Test Viewer",
        role="viewer",
    )
    session.add(user)
    session.commit()
    session.refresh(user)
    return user


@pytest.fixture(name="viewer_headers")
def viewer_headers_fixture(viewer_user):
    from bo.services.auth_service import create_access_token

    return {"Authorization": f"Bearer {create_access_token(viewer_user)}"}


@pytest.fixture(name="operator_headers")
def operator_headers_fixture(operator_user):
    from bo.services.auth_service import create_access_token

    return {"Authorization": f"Bearer {create_access_token(operator_user)}"}


@pytest.fixture(name="hierarchy")
def hierarchy_fixture(session, admin_user):
    """Create a full hierarchy: competition -> series -> event -> flight -> table -> seats + player."""
    from bo.db.models import (
        Competition, Series, Event, EventFlight, Table, TableSeat, Player,
    )

    comp = Competition(name="WSOP 2026")
    session.add(comp)
    session.commit()
    session.refresh(comp)

    series = Series(
        competition_id=comp.competition_id,
        series_name="Main Series",
        year=2026,
        begin_at="2026-06-01T00:00:00Z",
        end_at="2026-07-15T00:00:00Z",
    )
    session.add(series)
    session.commit()
    session.refresh(series)

    event = Event(
        series_id=series.series_id,
        event_no=1,
        event_name="Event #1 NLH",
        game_type=1,
        buy_in=10000,
    )
    session.add(event)
    session.commit()
    session.refresh(event)

    flight = EventFlight(
        event_id=event.event_id,
        display_name="Day 1A",
    )
    session.add(flight)
    session.commit()
    session.refresh(flight)

    table = Table(
        event_flight_id=flight.event_flight_id,
        table_no=1,
        name="Table 1",
        game_type=1,
    )
    session.add(table)
    session.commit()
    session.refresh(table)

    player = Player(
        first_name="Phil",
        last_name="Ivey",
        wsop_id="WS-001",
    )
    session.add(player)
    session.commit()
    session.refresh(player)

    # Create seats
    seats = []
    for i in range(1, 10):
        seat = TableSeat(
            table_id=table.table_id,
            seat_no=i,
            status="vacant",
        )
        session.add(seat)
    session.commit()

    # Assign player to seat 1
    seat1 = session.exec(
        __import__("sqlmodel").select(TableSeat).where(
            TableSeat.table_id == table.table_id,
            TableSeat.seat_no == 1,
        )
    ).first()
    seat1.player_id = player.player_id
    seat1.player_name = "Phil Ivey"
    seat1.status = "occupied"
    session.add(seat1)
    session.commit()
    session.refresh(seat1)

    return {
        "competition": comp,
        "series": series,
        "event": event,
        "flight": flight,
        "table": table,
        "player": player,
        "admin_user": admin_user,
    }
