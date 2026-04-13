"""Tests for all 20 SQLModel models."""

import pytest
from sqlalchemy.exc import IntegrityError
from sqlmodel import Session

from bo.db.models import (
    AuditLog,
    BlindStructure,
    BlindStructureLevel,
    Competition,
    Config,
    Deck,
    DeckCard,
    Event,
    EventFlight,
    Hand,
    HandAction,
    HandPlayer,
    OutputPreset,
    Player,
    Series,
    Skin,
    Table,
    TableSeat,
    User,
    UserSession,
)


# ---------------------------------------------------------------------------
# Helper factories
# ---------------------------------------------------------------------------

def _make_user(session: Session, email: str = "test@ebs.local") -> User:
    u = User(email=email, password_hash="hash", display_name="Test")
    session.add(u)
    session.flush()
    return u


def _make_competition(session: Session, name: str = "WSOP") -> Competition:
    c = Competition(name=name)
    session.add(c)
    session.flush()
    return c


def _make_series(session: Session, comp_id: int) -> Series:
    s = Series(
        competition_id=comp_id,
        series_name="2026 WSOP",
        year=2026,
        begin_at="2026-05-27",
        end_at="2026-07-17",
    )
    session.add(s)
    session.flush()
    return s


def _make_event(session: Session, series_id: int) -> Event:
    e = Event(series_id=series_id, event_no=1, event_name="Main Event")
    session.add(e)
    session.flush()
    return e


def _make_flight(session: Session, event_id: int) -> EventFlight:
    f = EventFlight(event_id=event_id, display_name="Day 1A")
    session.add(f)
    session.flush()
    return f


def _make_table(session: Session, flight_id: int, name: str = "Table 1") -> Table:
    t = Table(event_flight_id=flight_id, table_no=1, name=name)
    session.add(t)
    session.flush()
    return t


def _make_player(session: Session, first: str = "John", last: str = "Doe") -> Player:
    p = Player(first_name=first, last_name=last, is_demo=True)
    session.add(p)
    session.flush()
    return p


def _make_hand(session: Session, table_id: int, hand_number: int = 1) -> Hand:
    h = Hand(
        table_id=table_id,
        hand_number=hand_number,
        started_at="2026-01-01T00:00:00Z",
    )
    session.add(h)
    session.flush()
    return h


def _chain(session: Session):
    """Create a full Competition->Series->Event->Flight->Table chain."""
    comp = _make_competition(session)
    series = _make_series(session, comp.competition_id)
    event = _make_event(session, series.series_id)
    flight = _make_flight(session, event.event_id)
    table = _make_table(session, flight.event_flight_id)
    return comp, series, event, flight, table


# ---------------------------------------------------------------------------
# 1. User
# ---------------------------------------------------------------------------

class TestUser:
    def test_create(self, session: Session):
        u = _make_user(session)
        session.commit()
        assert u.user_id is not None
        assert u.role == "viewer"

    def test_unique_email(self, session: Session):
        _make_user(session, "dup@ebs.local")
        session.commit()
        session.add(User(email="dup@ebs.local", password_hash="h", display_name="D"))
        with pytest.raises(IntegrityError):
            session.flush()


# ---------------------------------------------------------------------------
# 2. Competition
# ---------------------------------------------------------------------------

class TestCompetition:
    def test_create(self, session: Session):
        c = _make_competition(session)
        session.commit()
        assert c.competition_id is not None
        assert c.competition_type == 0


# ---------------------------------------------------------------------------
# 3. Series (FK -> Competition)
# ---------------------------------------------------------------------------

class TestSeries:
    def test_create(self, session: Session):
        comp = _make_competition(session)
        s = _make_series(session, comp.competition_id)
        session.commit()
        assert s.series_id is not None
        assert s.competition_id == comp.competition_id


# ---------------------------------------------------------------------------
# 4. Event (FK -> Series)
# ---------------------------------------------------------------------------

class TestEvent:
    def test_create(self, session: Session):
        comp = _make_competition(session)
        series = _make_series(session, comp.competition_id)
        e = _make_event(session, series.series_id)
        session.commit()
        assert e.event_id is not None
        assert e.series_id == series.series_id


# ---------------------------------------------------------------------------
# 5. EventFlight (FK -> Event)
# ---------------------------------------------------------------------------

class TestEventFlight:
    def test_create(self, session: Session):
        comp = _make_competition(session)
        series = _make_series(session, comp.competition_id)
        event = _make_event(session, series.series_id)
        f = _make_flight(session, event.event_id)
        session.commit()
        assert f.event_flight_id is not None


# ---------------------------------------------------------------------------
# 6. Table (FK -> EventFlight, unique name per flight)
# ---------------------------------------------------------------------------

class TestTable:
    def test_create(self, session: Session):
        _, _, _, flight, table = _chain(session)
        session.commit()
        assert table.table_id is not None

    def test_unique_name_per_flight(self, session: Session):
        _, _, _, flight, _ = _chain(session)
        session.commit()
        session.add(Table(
            event_flight_id=flight.event_flight_id,
            table_no=2,
            name="Table 1",  # duplicate name for same flight
        ))
        with pytest.raises(IntegrityError):
            session.flush()


# ---------------------------------------------------------------------------
# 7. TableSeat (FK -> Table, Player; unique table_id+seat_no; CHECK 0-9)
# ---------------------------------------------------------------------------

class TestTableSeat:
    def test_create(self, session: Session):
        _, _, _, _, table = _chain(session)
        player = _make_player(session)
        seat = TableSeat(
            table_id=table.table_id,
            seat_no=0,
            player_id=player.player_id,
            status="occupied",
        )
        session.add(seat)
        session.commit()
        assert seat.seat_id is not None

    def test_unique_table_seat(self, session: Session):
        _, _, _, _, table = _chain(session)
        session.add(TableSeat(table_id=table.table_id, seat_no=0))
        session.flush()
        session.commit()
        session.add(TableSeat(table_id=table.table_id, seat_no=0))
        with pytest.raises(IntegrityError):
            session.flush()

    def test_check_seat_no_range(self, session: Session):
        _, _, _, _, table = _chain(session)
        session.add(TableSeat(table_id=table.table_id, seat_no=10))
        with pytest.raises(IntegrityError):
            session.flush()


# ---------------------------------------------------------------------------
# 8. Player
# ---------------------------------------------------------------------------

class TestPlayer:
    def test_create(self, session: Session):
        p = _make_player(session)
        session.commit()
        assert p.player_id is not None
        assert p.is_demo is True


# ---------------------------------------------------------------------------
# 9-10. BlindStructure + BlindStructureLevel
# ---------------------------------------------------------------------------

class TestBlindStructure:
    def test_create(self, session: Session):
        bs = BlindStructure(name="Standard")
        session.add(bs)
        session.flush()
        session.commit()
        assert bs.blind_structure_id is not None

    def test_level_create(self, session: Session):
        bs = BlindStructure(name="Standard")
        session.add(bs)
        session.flush()
        lvl = BlindStructureLevel(
            blind_structure_id=bs.blind_structure_id,
            level_no=1,
            small_blind=100,
            big_blind=200,
            duration_minutes=60,
        )
        session.add(lvl)
        session.commit()
        assert lvl.id is not None

    def test_unique_level_no(self, session: Session):
        bs = BlindStructure(name="Standard")
        session.add(bs)
        session.flush()
        session.add(BlindStructureLevel(
            blind_structure_id=bs.blind_structure_id,
            level_no=1, small_blind=100, big_blind=200, duration_minutes=60,
        ))
        session.flush()
        session.commit()
        session.add(BlindStructureLevel(
            blind_structure_id=bs.blind_structure_id,
            level_no=1, small_blind=200, big_blind=400, duration_minutes=60,
        ))
        with pytest.raises(IntegrityError):
            session.flush()


# ---------------------------------------------------------------------------
# 11. Config (unique key)
# ---------------------------------------------------------------------------

class TestConfig:
    def test_create(self, session: Session):
        c = Config(key="test_key", value="test_value")
        session.add(c)
        session.commit()
        assert c.id is not None

    def test_unique_key(self, session: Session):
        session.add(Config(key="dup_key", value="v1"))
        session.commit()
        session.add(Config(key="dup_key", value="v2"))
        with pytest.raises(IntegrityError):
            session.flush()


# ---------------------------------------------------------------------------
# 12. Skin (unique name)
# ---------------------------------------------------------------------------

class TestSkin:
    def test_create(self, session: Session):
        s = Skin(name="Default", is_default=True, theme_data='{"primary":"#000"}')
        session.add(s)
        session.commit()
        assert s.skin_id is not None

    def test_unique_name(self, session: Session):
        session.add(Skin(name="Dup"))
        session.commit()
        session.add(Skin(name="Dup"))
        with pytest.raises(IntegrityError):
            session.flush()


# ---------------------------------------------------------------------------
# 13. OutputPreset (unique name)
# ---------------------------------------------------------------------------

class TestOutputPreset:
    def test_create(self, session: Session):
        p = OutputPreset(name="NDI 1080p60")
        session.add(p)
        session.commit()
        assert p.preset_id is not None
        assert p.width == 1920

    def test_unique_name(self, session: Session):
        session.add(OutputPreset(name="Dup"))
        session.commit()
        session.add(OutputPreset(name="Dup"))
        with pytest.raises(IntegrityError):
            session.flush()


# ---------------------------------------------------------------------------
# 14. Deck (FK -> Table)
# ---------------------------------------------------------------------------

class TestDeck:
    def test_create(self, session: Session):
        _, _, _, _, table = _chain(session)
        d = Deck(table_id=table.table_id, label="Deck A")
        session.add(d)
        session.commit()
        assert d.deck_id is not None


# ---------------------------------------------------------------------------
# 15. DeckCard (FK -> Deck, unique deck_id+suit+rank)
# ---------------------------------------------------------------------------

class TestDeckCard:
    def test_create(self, session: Session):
        _, _, _, _, table = _chain(session)
        d = Deck(table_id=table.table_id, label="Deck A")
        session.add(d)
        session.flush()
        dc = DeckCard(deck_id=d.deck_id, suit=0, rank=1, display="As")
        session.add(dc)
        session.commit()
        assert dc.id is not None

    def test_unique_suit_rank(self, session: Session):
        _, _, _, _, table = _chain(session)
        d = Deck(table_id=table.table_id, label="Deck A")
        session.add(d)
        session.flush()
        session.add(DeckCard(deck_id=d.deck_id, suit=0, rank=1, display="As"))
        session.flush()
        session.commit()
        session.add(DeckCard(deck_id=d.deck_id, suit=0, rank=1, display="As2"))
        with pytest.raises(IntegrityError):
            session.flush()


# ---------------------------------------------------------------------------
# 16. Hand (FK -> Table, unique table_id+hand_number)
# ---------------------------------------------------------------------------

class TestHand:
    def test_create(self, session: Session):
        _, _, _, _, table = _chain(session)
        h = _make_hand(session, table.table_id)
        session.commit()
        assert h.hand_id is not None

    def test_unique_hand_number(self, session: Session):
        _, _, _, _, table = _chain(session)
        _make_hand(session, table.table_id, 1)
        session.commit()
        session.add(Hand(
            table_id=table.table_id,
            hand_number=1,
            started_at="2026-01-01T00:00:00Z",
        ))
        with pytest.raises(IntegrityError):
            session.flush()


# ---------------------------------------------------------------------------
# 17. HandPlayer (FK -> Hand, Player; unique hand_id+seat_no)
# ---------------------------------------------------------------------------

class TestHandPlayer:
    def test_create(self, session: Session):
        _, _, _, _, table = _chain(session)
        hand = _make_hand(session, table.table_id)
        hp = HandPlayer(hand_id=hand.hand_id, seat_no=0, player_name="Test")
        session.add(hp)
        session.commit()
        assert hp.id is not None

    def test_unique_hand_seat(self, session: Session):
        _, _, _, _, table = _chain(session)
        hand = _make_hand(session, table.table_id)
        session.add(HandPlayer(hand_id=hand.hand_id, seat_no=0, player_name="A"))
        session.flush()
        session.commit()
        session.add(HandPlayer(hand_id=hand.hand_id, seat_no=0, player_name="B"))
        with pytest.raises(IntegrityError):
            session.flush()


# ---------------------------------------------------------------------------
# 18. HandAction (FK -> Hand; unique hand_id+action_order)
# ---------------------------------------------------------------------------

class TestHandAction:
    def test_create(self, session: Session):
        _, _, _, _, table = _chain(session)
        hand = _make_hand(session, table.table_id)
        ha = HandAction(
            hand_id=hand.hand_id,
            action_type="bet",
            street="preflop",
            action_order=1,
        )
        session.add(ha)
        session.commit()
        assert ha.id is not None

    def test_unique_action_order(self, session: Session):
        _, _, _, _, table = _chain(session)
        hand = _make_hand(session, table.table_id)
        session.add(HandAction(
            hand_id=hand.hand_id,
            action_type="bet", street="preflop", action_order=1,
        ))
        session.flush()
        session.commit()
        session.add(HandAction(
            hand_id=hand.hand_id,
            action_type="call", street="preflop", action_order=1,
        ))
        with pytest.raises(IntegrityError):
            session.flush()


# ---------------------------------------------------------------------------
# 19. UserSession (FK -> User; unique user_id)
# ---------------------------------------------------------------------------

class TestUserSession:
    def test_create(self, session: Session):
        u = _make_user(session)
        us = UserSession(user_id=u.user_id)
        session.add(us)
        session.commit()
        assert us.id is not None

    def test_multiple_sessions_allowed(self, session: Session):
        """BO-02 §5.3: 사용자당 최대 2개 세션 허용 (Lobby + CC)."""
        u = _make_user(session)
        session.add(UserSession(user_id=u.user_id))
        session.commit()
        session.add(UserSession(user_id=u.user_id))
        session.commit()  # Should succeed — multiple sessions allowed


# ---------------------------------------------------------------------------
# 20. AuditLog (FK -> User)
# ---------------------------------------------------------------------------

class TestAuditLog:
    def test_create(self, session: Session):
        u = _make_user(session)
        al = AuditLog(
            user_id=u.user_id,
            entity_type="user",
            action="login",
        )
        session.add(al)
        session.commit()
        assert al.id is not None
