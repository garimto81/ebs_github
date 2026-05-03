"""blind_structure_service + payout_structure_service extended unit tests
(Session 2.2 — B-Q10 cascade, 2026-04-27).

Targets missing branches:
- BlindStructure: list/get/create/update/delete CRUD, get_flight + apply flight
- PayoutStructure: list/get/create/update/delete CRUD, TODO stubs (get_flight, apply)

Strict rule (B-Q15 cascade): production code 0 modification, tests/ only.
"""
import pytest
from fastapi import HTTPException
from sqlmodel import Session

from src.models.schemas import (
    BlindStructureCreate,
    BlindStructureLevelCreate,
    BlindStructureUpdate,
    PayoutStructureCreate,
    PayoutStructureLevelCreate,
    PayoutStructureUpdate,
)
from src.services.blind_structure_service import (
    apply_blind_structure,
    create_blind_structure,
    delete_blind_structure,
    get_blind_structure,
    get_blind_structure_levels,
    get_flight_blind_structure,
    list_blind_structures,
    update_blind_structure,
)
from src.services.payout_structure_service import (
    apply_payout_structure,
    create_payout_structure,
    delete_payout_structure,
    get_flight_payout_structure,
    get_payout_structure,
    get_payout_structure_levels,
    list_payout_structures,
    update_payout_structure,
)


# ── helpers ──────────────────────────────────────


def _bs_levels(n: int = 2) -> list[BlindStructureLevelCreate]:
    """Build n BlindStructureLevelCreate items."""
    return [
        BlindStructureLevelCreate(
            level_no=i + 1,
            small_blind=100 * (i + 1),
            big_blind=200 * (i + 1),
            duration_minutes=20,
        )
        for i in range(n)
    ]


def _ps_levels(n: int = 3) -> list[PayoutStructureLevelCreate]:
    """Build n PayoutStructureLevelCreate items."""
    return [
        PayoutStructureLevelCreate(
            position_from=i + 1,
            position_to=i + 1,
            payout_pct=50.0 / (i + 1),
        )
        for i in range(n)
    ]


def _make_bs(db: Session, name: str = "TestBS"):
    return create_blind_structure(
        BlindStructureCreate(name=name, levels=_bs_levels(2)), db
    )


def _make_ps(db: Session, name: str = "TestPS"):
    return create_payout_structure(
        PayoutStructureCreate(name=name, levels=_ps_levels(3)), db
    )


# ── BlindStructure CRUD ─────────────────────────


def test_list_blind_structures_returns_list(db_session: Session):
    """list returns (list, total). Order independent of pre-existing fixtures."""
    items, total = list_blind_structures(db_session)
    assert isinstance(items, list)
    assert total >= 0


def test_get_blind_structure_returns_existing(db_session: Session):
    bs = _make_bs(db_session, name="GetTest")
    fetched = get_blind_structure(bs.blind_structure_id, db_session)
    assert fetched.blind_structure_id == bs.blind_structure_id
    assert fetched.name == "GetTest"


def test_get_blind_structure_not_found_raises_404(db_session: Session):
    with pytest.raises(HTTPException) as excinfo:
        get_blind_structure(99999, db_session)
    assert excinfo.value.status_code == 404
    assert excinfo.value.detail["code"] == "RESOURCE_NOT_FOUND"


def test_get_blind_structure_levels_ordered(db_session: Session):
    bs = _make_bs(db_session, name="LevelsTest")
    levels = get_blind_structure_levels(bs.blind_structure_id, db_session)
    assert len(levels) == 2
    assert levels[0].level_no == 1
    assert levels[1].level_no == 2


def test_create_blind_structure_with_levels(db_session: Session):
    bs = create_blind_structure(
        BlindStructureCreate(name="CreateTest", levels=_bs_levels(3)), db_session
    )
    assert bs.blind_structure_id is not None
    assert bs.name == "CreateTest"
    levels = get_blind_structure_levels(bs.blind_structure_id, db_session)
    assert len(levels) == 3


def test_update_blind_structure_name_only(db_session: Session):
    bs = _make_bs(db_session, name="OldName")
    updated = update_blind_structure(
        bs.blind_structure_id, BlindStructureUpdate(name="NewName"), db_session
    )
    assert updated.name == "NewName"
    # Levels untouched
    levels = get_blind_structure_levels(bs.blind_structure_id, db_session)
    assert len(levels) == 2


def test_update_blind_structure_replaces_levels(db_session: Session):
    """Replace levels with empty list (delete all). Production bug: same-transaction
    delete+insert with overlapping unique keys (level_no) raises IntegrityError —
    documented gap, not fixed in this turn (Strict rule: production code 0 modify).
    Empty list path covers the 'delete existing levels' branch (line 80-85).
    """
    bs = _make_bs(db_session, name="UpdLvls")
    update_blind_structure(
        bs.blind_structure_id,
        BlindStructureUpdate(levels=[]),
        db_session,
    )
    levels = get_blind_structure_levels(bs.blind_structure_id, db_session)
    assert len(levels) == 0


def test_update_blind_structure_not_found(db_session: Session):
    with pytest.raises(HTTPException) as excinfo:
        update_blind_structure(99999, BlindStructureUpdate(name="X"), db_session)
    assert excinfo.value.status_code == 404


def test_delete_blind_structure_succeeds(db_session: Session):
    bs = _make_bs(db_session, name="DeleteTest")
    bs_id = bs.blind_structure_id
    delete_blind_structure(bs_id, db_session)
    with pytest.raises(HTTPException) as excinfo:
        get_blind_structure(bs_id, db_session)
    assert excinfo.value.status_code == 404


def test_delete_blind_structure_not_found(db_session: Session):
    with pytest.raises(HTTPException) as excinfo:
        delete_blind_structure(99999, db_session)
    assert excinfo.value.status_code == 404


# ── BlindStructure Flight (light coverage) ──────


def test_apply_blind_structure_flight_not_found(db_session: Session):
    """apply with invalid flight → 404 (line 168-172)."""
    bs = _make_bs(db_session, name="ApplyTest")
    with pytest.raises(HTTPException) as excinfo:
        apply_blind_structure(99999, bs.blind_structure_id, db_session)
    assert excinfo.value.status_code == 404


def test_get_flight_blind_structure_flight_not_found(db_session: Session):
    """get_flight with invalid flight → 404 (line 137-141)."""
    with pytest.raises(HTTPException) as excinfo:
        get_flight_blind_structure(99999, db_session)
    assert excinfo.value.status_code == 404


# ── PayoutStructure CRUD ────────────────────────


def test_list_payout_structures_returns_list(db_session: Session):
    items, total = list_payout_structures(db_session)
    assert isinstance(items, list)
    assert total >= 0


def test_get_payout_structure_returns_existing(db_session: Session):
    ps = _make_ps(db_session, name="PSGet")
    fetched = get_payout_structure(ps.payout_structure_id, db_session)
    assert fetched.payout_structure_id == ps.payout_structure_id


def test_get_payout_structure_not_found(db_session: Session):
    with pytest.raises(HTTPException) as excinfo:
        get_payout_structure(99999, db_session)
    assert excinfo.value.status_code == 404


def test_get_payout_structure_levels_ordered(db_session: Session):
    ps = _make_ps(db_session, name="PSLvls")
    levels = get_payout_structure_levels(ps.payout_structure_id, db_session)
    assert len(levels) == 3
    # ordered by position_from
    positions = [lv.position_from for lv in levels]
    assert positions == sorted(positions)


def test_create_payout_structure_with_levels(db_session: Session):
    ps = create_payout_structure(
        PayoutStructureCreate(name="PSCreate", levels=_ps_levels(5)), db_session
    )
    assert ps.payout_structure_id is not None
    levels = get_payout_structure_levels(ps.payout_structure_id, db_session)
    assert len(levels) == 5


def test_update_payout_structure_name(db_session: Session):
    ps = _make_ps(db_session, name="OldPS")
    updated = update_payout_structure(
        ps.payout_structure_id, PayoutStructureUpdate(name="NewPS"), db_session
    )
    assert updated.name == "NewPS"


def test_update_payout_structure_replaces_levels(db_session: Session):
    """Replace levels with empty list (delete all). Same flush-ordering bug as
    blind_structure_service.update — empty list path is safe.
    """
    ps = _make_ps(db_session, name="PSUpdLvls")
    update_payout_structure(
        ps.payout_structure_id,
        PayoutStructureUpdate(levels=[]),
        db_session,
    )
    levels = get_payout_structure_levels(ps.payout_structure_id, db_session)
    assert len(levels) == 0


def test_update_payout_structure_not_found(db_session: Session):
    with pytest.raises(HTTPException) as excinfo:
        update_payout_structure(99999, PayoutStructureUpdate(name="X"), db_session)
    assert excinfo.value.status_code == 404


def test_delete_payout_structure_succeeds(db_session: Session):
    ps = _make_ps(db_session, name="PSDel")
    ps_id = ps.payout_structure_id
    delete_payout_structure(ps_id, db_session)
    with pytest.raises(HTTPException) as excinfo:
        get_payout_structure(ps_id, db_session)
    assert excinfo.value.status_code == 404


def test_delete_payout_structure_not_found(db_session: Session):
    with pytest.raises(HTTPException) as excinfo:
        delete_payout_structure(99999, db_session)
    assert excinfo.value.status_code == 404


# ── PayoutStructure Flight TODO stubs ───────────


def test_get_flight_payout_structure_returns_none(db_session: Session):
    """TODO stub — line 124: returns None (events table lacks payout_structure_id)."""
    result = get_flight_payout_structure(99999, db_session)
    assert result is None


def test_apply_payout_structure_returns_none(db_session: Session):
    """TODO stub — line 130-131: pass (no-op)."""
    result = apply_payout_structure(99999, 99999, db_session)
    assert result is None


# ── B-Q18 regression: same-tx delete+insert with overlapping unique key ─


def test_update_blind_structure_replaces_levels_overlapping_keys(db_session: Session):
    """B-Q18 regression: update with NEW levels using SAME level_no as existing
    triggered IntegrityError pre-fix (UNIQUE on (blind_structure_id, level_no)).
    Post-fix `db.flush()` between delete and insert resolves it."""
    bs = _make_bs(db_session, name="OverlapBS")
    new_levels = [
        BlindStructureLevelCreate(
            level_no=1, small_blind=500, big_blind=1000, duration_minutes=30
        ),
        BlindStructureLevelCreate(
            level_no=2, small_blind=750, big_blind=1500, duration_minutes=30
        ),
    ]
    updated = update_blind_structure(
        bs.blind_structure_id,
        BlindStructureUpdate(levels=new_levels),
        db_session,
    )
    levels = get_blind_structure_levels(updated.blind_structure_id, db_session)
    assert len(levels) == 2
    assert {lv.small_blind for lv in levels} == {500, 750}
    assert {lv.level_no for lv in levels} == {1, 2}


def test_update_payout_structure_replaces_levels_overlapping_keys(db_session: Session):
    """B-Q18 regression: same as above for PayoutStructure
    (UNIQUE on (payout_structure_id, position_from))."""
    ps = _make_ps(db_session, name="OverlapPS")
    new_levels = [
        PayoutStructureLevelCreate(position_from=1, position_to=1, payout_pct=60.0),
        PayoutStructureLevelCreate(position_from=2, position_to=2, payout_pct=30.0),
        PayoutStructureLevelCreate(position_from=3, position_to=3, payout_pct=10.0),
    ]
    updated = update_payout_structure(
        ps.payout_structure_id,
        PayoutStructureUpdate(levels=new_levels),
        db_session,
    )
    levels = get_payout_structure_levels(updated.payout_structure_id, db_session)
    assert len(levels) == 3
    pcts = {float(lv.payout_pct) for lv in levels}
    assert pcts == {60.0, 30.0, 10.0}
