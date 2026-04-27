"""Session 2.4b — hand/clock/competition services extended tests (B-Q10 cascade).

Targets:
- hand_service.py 27% → 70%+ (filters / get / hand_players / hand_actions)
- clock_service.py 38% → 80%+ (state transitions: get/start/pause/resume/adjust/restart)
- competition_service.py 30% → 80%+ (CRUD)

Strict rule: production code 0 modification, tests/ only.
"""
import pytest
from fastapi import HTTPException
from sqlmodel import Session, select

from src.models.competition import Competition, EventFlight
from src.models.hand import Hand, HandAction, HandPlayer
from src.models.schemas import (
    CompetitionCreate,
    CompetitionUpdate,
    EventCreate,
    FlightCreate,
    SeriesCreate,
)
from src.services.clock_service import (
    adjust_clock,
    get_clock_state,
    pause_clock,
    restart_level,
    resume_clock,
    start_clock,
)
from src.services.competition_service import (
    create_competition,
    delete_competition,
    get_competition,
    list_competitions,
    update_competition,
)
from src.services.hand_service import (
    get_hand,
    get_hand_actions,
    get_hand_players,
    list_hands,
)
from src.services.series_service import (
    create_event,
    create_flight,
    create_series,
)


# ── helpers ──────────────────────────────────────


def _setup_flight(db: Session, prefix: str = "S24"):
    """Build Competition → Series → Event → Flight chain."""
    comp = Competition(name=f"{prefix}-Comp")
    db.add(comp)
    db.commit()
    db.refresh(comp)
    series = create_series(
        SeriesCreate(
            competition_id=comp.competition_id,
            series_name=f"{prefix}-Series",
            year=2026,
            begin_at="2026-04-27T00:00:00Z",
            end_at="2026-05-27T00:00:00Z",
        ),
        db,
    )
    event = create_event(
        EventCreate(series_id=series.series_id, event_no=1, event_name=f"{prefix}-Ev"),
        db,
    )
    flight = create_flight(
        FlightCreate(event_id=event.event_id, display_name=f"{prefix}-Fl"),
        db,
    )
    return flight.event_flight_id


# ── hand_service ────────────────────────────────
#
# B-Q19 발견 (Session 2.4b, 2026-04-27): list_hands 의 line 99-101 에서
#   total = db.exec(count_stmt).one()
#   if isinstance(total, tuple):
#       total = total[0]
#   ...
#   return list(items), int(total)
# → SQLAlchemy 2.x 에서는 .one() 이 Row 객체 반환 (tuple 이 아님).
#   `int(Row)` TypeError. 단순 `int(total[0])` 로 수정 필요.
# Type A 구현 실수. Strict 룰 (production code 0 수정) 준수 위해 list_hands 테스트 보류.
# B-Q19 신규 backlog 등재 — surgical edit 별도 turn.


def test_get_hand_not_found_404(db_session: Session):
    """get_hand raises 404 (line 111-115)."""
    with pytest.raises(HTTPException) as excinfo:
        get_hand(99999, db_session)
    assert excinfo.value.status_code == 404


def test_get_hand_players_via_404(db_session: Session):
    """get_hand_players raises 404 if hand doesn't exist (line 123)."""
    with pytest.raises(HTTPException) as excinfo:
        get_hand_players(99999, db_session)
    assert excinfo.value.status_code == 404


def test_get_hand_actions_via_404(db_session: Session):
    """get_hand_actions raises 404 if hand doesn't exist (line 135)."""
    with pytest.raises(HTTPException) as excinfo:
        get_hand_actions(99999, db_session)
    assert excinfo.value.status_code == 404


# ── clock_service ───────────────────────────────


def test_get_clock_state_returns_dict(db_session: Session):
    """get_clock_state returns flight state dict (line 16-23)."""
    flight_id = _setup_flight(db_session, prefix="GC")
    state = get_clock_state(flight_id, db_session)
    assert state["event_flight_id"] == flight_id
    assert "status" in state
    assert "play_level" in state


def test_start_clock_invalid_state_400(db_session: Session):
    """start_clock raises 400 from non-(created/paused) status (line 28-32)."""
    flight_id = _setup_flight(db_session, prefix="SC")
    # Manually set status to 'completed' (not in allowed set)
    f = db_session.exec(
        select(EventFlight).where(EventFlight.event_flight_id == flight_id)
    ).first()
    f.status = "completed"
    db_session.add(f)
    db_session.commit()

    with pytest.raises(HTTPException) as excinfo:
        start_clock(flight_id, db_session)
    assert excinfo.value.status_code == 400
    assert excinfo.value.detail["code"] == "INVALID_STATE"


def test_start_clock_succeeds_from_created(db_session: Session):
    """start_clock transitions created → running (line 33-38)."""
    flight_id = _setup_flight(db_session, prefix="SC2")
    state = start_clock(flight_id, db_session)
    assert state["status"] == "running"


def test_pause_clock_invalid_state(db_session: Session):
    """pause_clock raises 400 from non-running status (line 43-47)."""
    flight_id = _setup_flight(db_session, prefix="PC")
    # Default status 'created' — cannot pause
    with pytest.raises(HTTPException) as excinfo:
        pause_clock(flight_id, db_session)
    assert excinfo.value.status_code == 400


def test_pause_clock_succeeds_from_running(db_session: Session):
    """pause_clock transitions running → paused (line 48-53)."""
    flight_id = _setup_flight(db_session, prefix="PC2")
    start_clock(flight_id, db_session)
    state = pause_clock(flight_id, db_session)
    assert state["status"] == "paused"


def test_resume_clock_invalid_state(db_session: Session):
    """resume_clock raises 400 from non-paused (line 58-62)."""
    flight_id = _setup_flight(db_session, prefix="RC")
    # Default status 'created' — cannot resume
    with pytest.raises(HTTPException) as excinfo:
        resume_clock(flight_id, db_session)
    assert excinfo.value.status_code == 400


def test_resume_clock_succeeds_from_paused(db_session: Session):
    """resume_clock transitions paused → running (line 63-68)."""
    flight_id = _setup_flight(db_session, prefix="RC2")
    start_clock(flight_id, db_session)
    pause_clock(flight_id, db_session)
    state = resume_clock(flight_id, db_session)
    assert state["status"] == "running"


def test_adjust_clock_changes_level(db_session: Session):
    """adjust_clock with level_diff updates play_level (line 73-74)."""
    flight_id = _setup_flight(db_session, prefix="AC")
    initial = get_clock_state(flight_id, db_session)
    state = adjust_clock(flight_id, level_diff=2, time_diff=0, db=db_session)
    assert state["play_level"] == initial["play_level"] + 2


def test_adjust_clock_min_level_floor(db_session: Session):
    """adjust_clock floors play_level at 1 (max(1, ...))."""
    flight_id = _setup_flight(db_session, prefix="AC2")
    state = adjust_clock(flight_id, level_diff=-100, time_diff=0, db=db_session)
    assert state["play_level"] == 1  # floored at 1


def test_restart_level_resets_state(db_session: Session):
    """restart_level resets remain_time + sets running (line 84-93)."""
    flight_id = _setup_flight(db_session, prefix="RL")
    state = restart_level(flight_id, db_session)
    assert state["status"] == "running"
    assert state["remain_time"] is None


# ── competition_service ─────────────────────────


def test_list_competitions_returns_tuple(db_session: Session):
    items, total = list_competitions(db_session)
    assert isinstance(items, list)
    assert total >= 0


def test_get_competition_existing(db_session: Session):
    c = create_competition(CompetitionCreate(name="GetC"), db_session)
    fetched = get_competition(c.competition_id, db_session)
    assert fetched.competition_id == c.competition_id


def test_get_competition_not_found_404(db_session: Session):
    with pytest.raises(HTTPException) as excinfo:
        get_competition(99999, db_session)
    assert excinfo.value.status_code == 404


def test_create_competition_succeeds(db_session: Session):
    c = create_competition(
        CompetitionCreate(name="CreateC", competition_type=1, competition_tag=2),
        db_session,
    )
    assert c.competition_id is not None
    assert c.name == "CreateC"


def test_update_competition_partial(db_session: Session):
    c = create_competition(CompetitionCreate(name="OldC"), db_session)
    updated = update_competition(
        c.competition_id, CompetitionUpdate(name="NewC"), db_session
    )
    assert updated.name == "NewC"


def test_update_competition_not_found(db_session: Session):
    with pytest.raises(HTTPException) as excinfo:
        update_competition(99999, CompetitionUpdate(name="X"), db_session)
    assert excinfo.value.status_code == 404


def test_delete_competition_succeeds(db_session: Session):
    c = create_competition(CompetitionCreate(name="DelC"), db_session)
    cid = c.competition_id
    delete_competition(cid, db_session)
    with pytest.raises(HTTPException):
        get_competition(cid, db_session)


def test_delete_competition_with_children_409(db_session: Session):
    """delete_competition raises 409 when child Series exist (line 56-61)."""
    c = create_competition(CompetitionCreate(name="ParentC"), db_session)
    create_series(
        SeriesCreate(
            competition_id=c.competition_id,
            series_name="ChildSeries",
            year=2026,
            begin_at="2026-04-27T00:00:00Z",
            end_at="2026-05-27T00:00:00Z",
        ),
        db_session,
    )
    with pytest.raises(HTTPException) as excinfo:
        delete_competition(c.competition_id, db_session)
    assert excinfo.value.status_code == 409
