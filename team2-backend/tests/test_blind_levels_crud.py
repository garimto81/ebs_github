"""V9.5 Phase 3 — blind_structure_levels CRUD service tests.

PR #86 에서 추가한 4 service 함수 검증:
- get_blind_structure_level
- create_blind_structure_level
- update_blind_structure_level
- delete_blind_structure_level

기존 tests/test_structure_services_extended.py 와 동일 pattern (DB session fixture).
"""
import pytest
from fastapi import HTTPException
from sqlmodel import Session

from src.models.schemas import (
    BlindStructureCreate,
    BlindStructureLevelCreate,
    BlindStructureLevelUpdate,
)
from src.services.blind_structure_service import (
    create_blind_structure,
    create_blind_structure_level,
    delete_blind_structure_level,
    get_blind_structure_level,
    get_blind_structure_levels,
    update_blind_structure_level,
)


# ── Fixtures ──────────────────────────────────────────


@pytest.fixture
def sample_bs(db_session: Session):
    """단일 level 1개를 가진 BlindStructure."""
    bs_data = BlindStructureCreate(
        name="Test Structure",
        levels=[
            BlindStructureLevelCreate(
                level_no=1,
                small_blind=100,
                big_blind=200,
                ante=0,
                duration_minutes=15,
            )
        ],
    )
    return create_blind_structure(bs_data, db_session)


# ── get_blind_structure_level ─────────────────────────


def test_get_blind_structure_level_returns_existing(db_session: Session, sample_bs):
    """존재하는 level 조회."""
    levels = get_blind_structure_levels(sample_bs.blind_structure_id, db_session)
    assert len(levels) == 1
    level = get_blind_structure_level(levels[0].id, db_session)
    assert level.level_no == 1
    assert level.small_blind == 100


def test_get_blind_structure_level_404_when_missing(db_session: Session):
    """존재하지 않는 level → 404."""
    with pytest.raises(HTTPException) as exc:
        get_blind_structure_level(99999, db_session)
    assert exc.value.status_code == 404


# ── create_blind_structure_level ──────────────────────


def test_create_blind_structure_level_appends(db_session: Session, sample_bs):
    """새 level 추가 시 기존 level 보존."""
    new_data = BlindStructureLevelCreate(
        level_no=2,
        small_blind=200,
        big_blind=400,
        ante=50,
        duration_minutes=20,
    )
    created = create_blind_structure_level(
        sample_bs.blind_structure_id, new_data, db_session
    )
    assert created.level_no == 2
    assert created.small_blind == 200

    # 기존 level 보존 확인
    all_levels = get_blind_structure_levels(sample_bs.blind_structure_id, db_session)
    assert len(all_levels) == 2


def test_create_blind_structure_level_404_when_parent_missing(db_session: Session):
    """존재하지 않는 BS → 404."""
    new_data = BlindStructureLevelCreate(
        level_no=1, small_blind=100, big_blind=200, ante=0, duration_minutes=15
    )
    with pytest.raises(HTTPException) as exc:
        create_blind_structure_level(99999, new_data, db_session)
    assert exc.value.status_code == 404


# ── update_blind_structure_level ──────────────────────


def test_update_blind_structure_level_partial(db_session: Session, sample_bs):
    """partial update: 일부 필드만 변경."""
    levels = get_blind_structure_levels(sample_bs.blind_structure_id, db_session)
    level_id = levels[0].id

    update_data = BlindStructureLevelUpdate(small_blind=500, big_blind=1000)
    updated = update_blind_structure_level(level_id, update_data, db_session)

    assert updated.small_blind == 500
    assert updated.big_blind == 1000
    assert updated.ante == 0  # 미변경 필드 보존
    assert updated.level_no == 1


def test_update_blind_structure_level_404_when_missing(db_session: Session):
    """존재하지 않는 level update → 404."""
    update_data = BlindStructureLevelUpdate(small_blind=999)
    with pytest.raises(HTTPException) as exc:
        update_blind_structure_level(99999, update_data, db_session)
    assert exc.value.status_code == 404


# ── delete_blind_structure_level ──────────────────────


def test_delete_blind_structure_level_removes(db_session: Session, sample_bs):
    """level 삭제 후 list 에서 제거 확인."""
    levels = get_blind_structure_levels(sample_bs.blind_structure_id, db_session)
    level_id = levels[0].id

    delete_blind_structure_level(level_id, db_session)

    remaining = get_blind_structure_levels(sample_bs.blind_structure_id, db_session)
    assert len(remaining) == 0


def test_delete_blind_structure_level_404_when_missing(db_session: Session):
    """존재하지 않는 level delete → 404."""
    with pytest.raises(HTTPException) as exc:
        delete_blind_structure_level(99999, db_session)
    assert exc.value.status_code == 404
