"""Tests for seed data script."""

from sqlmodel import Session, SQLModel, create_engine, select

from bo.db.models import (
    BlindStructure,
    BlindStructureLevel,
    Competition,
    Config,
    Event,
    EventFlight,
    OutputPreset,
    Player,
    Series,
    Skin,
    Table,
    TableSeat,
    User,
)
from bo.db.seed import seed


def test_seed_inserts_all_records():
    """Run seed against in-memory DB and verify record counts."""
    engine = create_engine("sqlite://", connect_args={"check_same_thread": False})
    SQLModel.metadata.create_all(engine)

    with Session(engine) as session:
        counts = seed(session)

    assert counts["User"] == 4
    assert counts["Competition"] == 2
    assert counts["Series"] == 2
    assert counts["Event"] == 3
    assert counts["EventFlight"] == 4
    assert counts["Table"] == 3
    assert counts["Player"] == 9
    assert counts["TableSeat"] == 10
    assert counts["BlindStructure"] == 1
    assert counts["BlindStructureLevel"] == 12
    assert counts["Config"] == 69
    assert counts["Skin"] == 3
    assert counts["OutputPreset"] == 4

    # Verify actual DB counts
    with Session(engine) as session:
        assert len(session.exec(select(User)).all()) == 4
        assert len(session.exec(select(Competition)).all()) == 2
        assert len(session.exec(select(Series)).all()) == 2
        assert len(session.exec(select(Event)).all()) == 3
        assert len(session.exec(select(EventFlight)).all()) == 4
        assert len(session.exec(select(Table)).all()) == 3
        assert len(session.exec(select(Player)).all()) == 9
        assert len(session.exec(select(TableSeat)).all()) == 10
        assert len(session.exec(select(BlindStructure)).all()) == 1
        assert len(session.exec(select(BlindStructureLevel)).all()) == 12
        assert len(session.exec(select(Config)).all()) == 69
        assert len(session.exec(select(Skin)).all()) == 3
        assert len(session.exec(select(OutputPreset)).all()) == 4


def test_seed_idempotent():
    """Running seed twice should not duplicate data."""
    engine = create_engine("sqlite://", connect_args={"check_same_thread": False})
    SQLModel.metadata.create_all(engine)

    with Session(engine) as session:
        counts1 = seed(session)
    assert counts1["User"] == 4

    with Session(engine) as session:
        counts2 = seed(session)
    assert counts2 == {}

    with Session(engine) as session:
        assert len(session.exec(select(User)).all()) == 4
