import pytest
from fastapi import HTTPException

from bo.db.models import Competition
from bo.services.crud_service import (
    create_item,
    delete_item,
    get_by_id,
    get_list,
    update_item,
)


def test_create_item(session):
    item = create_item(
        session, Competition, {"name": "WSOP 2026", "competition_type": 1}
    )
    assert item.competition_id is not None
    assert item.name == "WSOP 2026"
    assert item.competition_type == 1


def test_get_list_paginated(session):
    for i in range(5):
        create_item(session, Competition, {"name": f"Comp {i}"})

    result = get_list(session, Competition, page=1, limit=3)
    assert result.meta is not None
    assert result.meta.total == 5
    assert result.meta.page == 1
    assert result.meta.limit == 3
    assert len(result.data) == 3


def test_get_list_with_filter(session):
    create_item(session, Competition, {"name": "Type A", "competition_type": 1})
    create_item(session, Competition, {"name": "Type B", "competition_type": 2})
    create_item(session, Competition, {"name": "Type A2", "competition_type": 1})

    result = get_list(
        session, Competition, filters={"competition_type": 1}
    )
    assert result.meta.total == 2
    assert len(result.data) == 2


def test_get_by_id(session):
    item = create_item(session, Competition, {"name": "Find Me"})
    found = get_by_id(session, Competition, item.competition_id)
    assert found.name == "Find Me"


def test_get_by_id_not_found(session):
    with pytest.raises(HTTPException) as exc_info:
        get_by_id(session, Competition, 99999)
    assert exc_info.value.status_code == 404


def test_update_item(session):
    item = create_item(session, Competition, {"name": "Original"})
    updated = update_item(
        session, Competition, item.competition_id, {"name": "Updated"}
    )
    assert updated.name == "Updated"
    assert updated.competition_id == item.competition_id


def test_delete_item(session):
    item = create_item(session, Competition, {"name": "Delete Me"})
    result = delete_item(session, Competition, item.competition_id)
    assert result["deleted"] is True

    with pytest.raises(HTTPException) as exc_info:
        get_by_id(session, Competition, item.competition_id)
    assert exc_info.value.status_code == 404
