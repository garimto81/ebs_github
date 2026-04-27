"""Session 2.7 — Final: skin_service + undo_service extended tests (B-Q10 cascade).

Targets:
- skin_service.py 75% → 95%+ (CRUD + activate + get_active)
- undo_service.py 32% → 80%+ (undo flow with various inverse_payload types)

Strict rule: production code 0 modification, tests/ only.
"""
import json

import pytest
from fastapi import HTTPException
from sqlmodel import Session, select

from src.models.audit_event import AuditEvent
from src.models.audit_log import AuditLog
from src.models.schemas import SkinCreate, SkinUpdate
from src.models.skin import Skin
from src.repositories.event_repository import event_repository
from src.services.skin_service import (
    activate_skin,
    create_skin,
    delete_skin,
    get_active_skin,
    get_skin,
    list_skins,
    update_skin,
)
from src.services.undo_service import UndoNotAllowedError, UndoService


# ── skin_service ────────────────────────────────


def test_list_skins_returns_tuple(db_session: Session):
    items, total = list_skins(db_session)
    assert isinstance(items, list)
    assert total >= 0


def test_get_skin_existing(db_session: Session):
    s = create_skin(SkinCreate(name="GetSkin", description="d"), db_session)
    fetched = get_skin(s.skin_id, db_session)
    assert fetched.skin_id == s.skin_id


def test_get_skin_not_found_404(db_session: Session):
    with pytest.raises(HTTPException) as excinfo:
        get_skin(99999, db_session)
    assert excinfo.value.status_code == 404


def test_create_skin_succeeds(db_session: Session):
    s = create_skin(SkinCreate(name="CreateSkin"), db_session)
    assert s.skin_id is not None
    assert s.name == "CreateSkin"


def test_create_skin_duplicate_name_409(db_session: Session):
    create_skin(SkinCreate(name="DupSkin"), db_session)
    with pytest.raises(HTTPException) as excinfo:
        create_skin(SkinCreate(name="DupSkin"), db_session)
    assert excinfo.value.status_code == 409
    assert excinfo.value.detail["code"] == "DUPLICATE"


def test_update_skin_partial(db_session: Session):
    s = create_skin(SkinCreate(name="UpdSkin"), db_session)
    updated = update_skin(
        s.skin_id, SkinUpdate(description="new desc"), db_session
    )
    assert updated.description == "new desc"


def test_update_skin_not_found(db_session: Session):
    with pytest.raises(HTTPException) as excinfo:
        update_skin(99999, SkinUpdate(name="X"), db_session)
    assert excinfo.value.status_code == 404


def test_delete_skin_succeeds(db_session: Session):
    s = create_skin(SkinCreate(name="DelSkin"), db_session)
    sid = s.skin_id
    delete_skin(sid, db_session)
    with pytest.raises(HTTPException):
        get_skin(sid, db_session)


def test_delete_skin_default_raises_409(db_session: Session):
    """Cannot delete a skin marked is_default (line 60-64)."""
    s = create_skin(SkinCreate(name="DefaultSkin"), db_session)
    activate_skin(s.skin_id, db_session)  # marks as default
    with pytest.raises(HTTPException) as excinfo:
        delete_skin(s.skin_id, db_session)
    assert excinfo.value.status_code == 409
    assert excinfo.value.detail["code"] == "CANNOT_DELETE_DEFAULT"


def test_activate_skin_unsets_other_defaults(db_session: Session):
    """activate_skin sets target as default + unsets others (line 71-83)."""
    s1 = create_skin(SkinCreate(name="Active1"), db_session)
    s2 = create_skin(SkinCreate(name="Active2"), db_session)
    activate_skin(s1.skin_id, db_session)
    activated = activate_skin(s2.skin_id, db_session)
    assert activated.is_default is True

    # s1 should no longer be default
    s1_fresh = db_session.exec(
        select(Skin).where(Skin.skin_id == s1.skin_id)
    ).first()
    assert s1_fresh.is_default is False


def test_get_active_skin_returns_default(db_session: Session):
    """get_active_skin returns the is_default skin (line 87)."""
    s = create_skin(SkinCreate(name="GetActive"), db_session)
    activate_skin(s.skin_id, db_session)
    active = get_active_skin(db_session)
    assert active is not None
    assert active.skin_id == s.skin_id


# ── undo_service ────────────────────────────────


@pytest.fixture
def undo_service():
    return UndoService(event_repository)


def _make_event_with_inverse(
    db: Session,
    table_id: str = "tbl-undo-test",
    event_type: str = "test_event",
    payload: dict = None,
    inverse_payload: dict = None,
) -> AuditEvent:
    """Append a regular event with an inverse_payload."""
    return event_repository.append(
        table_id=table_id,
        event_type=event_type,
        payload=payload or {"key": "original"},
        inverse_payload=inverse_payload or {"key": "inverse"},
        db=db,
    )


def test_undo_event_not_found_404(undo_service, db_session: Session):
    """undo_event raises 404 for unknown event_id (line 33-38)."""
    with pytest.raises(HTTPException) as excinfo:
        undo_service.undo_event(99999, actor_user_id=1, db=db_session)
    assert excinfo.value.status_code == 404


def test_undo_event_no_inverse_raises_undo_not_allowed(undo_service, db_session: Session):
    """undo_event raises UndoNotAllowedError when inverse_payload missing (line 40-41)."""
    evt = event_repository.append(
        table_id="tbl-no-inverse",
        event_type="no_inv",
        payload={"k": "v"},
        # no inverse_payload
        db=db_session,
    )
    with pytest.raises(UndoNotAllowedError) as excinfo:
        undo_service.undo_event(evt.id, actor_user_id=1, db=db_session)
    assert excinfo.value.status_code == 400


def test_undo_event_with_dict_inverse(undo_service, db_session: Session):
    """undo_event with dict inverse_payload appends inverse (line 50-51)."""
    evt = _make_event_with_inverse(
        db_session,
        table_id="tbl-dict-inv",
        payload={"original": True},
        inverse_payload={"undone": True},
    )
    inverse = undo_service.undo_event(evt.id, actor_user_id=42, db=db_session)
    assert inverse is not None
    assert inverse.event_type == "undo_test_event"
    assert inverse.causation_id == str(evt.id)


def test_undo_creates_audit_log_dual_write(undo_service, db_session: Session):
    """undo_event also writes to audit_logs (line 76-86)."""
    evt = _make_event_with_inverse(
        db_session,
        table_id="tbl-audit-log",
        payload={"o": 1},
        inverse_payload={"i": 1},
    )
    undo_service.undo_event(evt.id, actor_user_id=99, db=db_session)

    # Verify audit_log entry created
    logs = db_session.exec(
        select(AuditLog).where(
            AuditLog.entity_type == "audit_event",
            AuditLog.entity_id == evt.id,
            AuditLog.action == "undo",
        )
    ).all()
    assert len(logs) >= 1
    assert logs[0].user_id == 99


def test_undo_event_double_inverse_for_re_undo(undo_service, db_session: Session):
    """undo creates inverse with original payload as inverse_payload (line 64-72)."""
    evt = _make_event_with_inverse(
        db_session,
        table_id="tbl-double-inv",
        payload={"step": 1},
        inverse_payload={"step": 0},
    )
    inverse = undo_service.undo_event(evt.id, actor_user_id=5, db=db_session)
    # The inverse event's inverse_payload should be the original payload
    # (so re-undoing the inverse yields the original).
    assert inverse.inverse_payload is not None
    if isinstance(inverse.inverse_payload, str):
        decoded = json.loads(inverse.inverse_payload)
    else:
        decoded = inverse.inverse_payload
    assert decoded == {"step": 1}
