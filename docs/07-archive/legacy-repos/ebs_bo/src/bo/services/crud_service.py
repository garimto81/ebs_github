from typing import Any, Type, TypeVar

from fastapi import HTTPException
from sqlmodel import Session, SQLModel, func, select

from bo.schemas.common import ApiResponse, PaginationMeta

M = TypeVar("M", bound=SQLModel)


def get_list(
    session: Session,
    model: Type[M],
    *,
    page: int = 1,
    limit: int = 20,
    filters: dict[str, Any] | None = None,
    pk_field: str = "id",
) -> ApiResponse:
    """Generic list with pagination and optional filters."""
    stmt = select(model)
    count_stmt = select(func.count()).select_from(model)

    if filters:
        for field, value in filters.items():
            if value is not None and hasattr(model, field):
                stmt = stmt.where(getattr(model, field) == value)
                count_stmt = count_stmt.where(getattr(model, field) == value)

    total = session.exec(count_stmt).one()
    offset = (page - 1) * limit
    results = session.exec(stmt.offset(offset).limit(limit)).all()

    return ApiResponse(
        data=results,
        meta=PaginationMeta(page=page, limit=limit, total=total),
    )


def get_by_id(
    session: Session,
    model: Type[M],
    item_id: int,
    pk_field: str = "id",
) -> M:
    """Get single item by PK. Raises 404 if not found."""
    for field in [pk_field, f"{model.__tablename__[:-1]}_id", "id"]:
        if hasattr(model, field):
            stmt = select(model).where(getattr(model, field) == item_id)
            item = session.exec(stmt).first()
            if item:
                return item
    raise HTTPException(
        status_code=404, detail=f"{model.__name__} with id {item_id} not found"
    )


def create_item(session: Session, model: Type[M], data: dict) -> M:
    """Create a new item."""
    item = model(**data)
    session.add(item)
    session.commit()
    session.refresh(item)
    return item


def update_item(
    session: Session,
    model: Type[M],
    item_id: int,
    data: dict,
    pk_field: str = "id",
) -> M:
    """Update an existing item. Raises 404 if not found."""
    item = get_by_id(session, model, item_id, pk_field)
    for key, value in data.items():
        if hasattr(item, key) and value is not None:
            setattr(item, key, value)
    session.add(item)
    session.commit()
    session.refresh(item)
    return item


def delete_item(
    session: Session,
    model: Type[M],
    item_id: int,
    pk_field: str = "id",
) -> dict:
    """Delete an item. Raises 404 if not found."""
    item = get_by_id(session, model, item_id, pk_field)
    session.delete(item)
    session.commit()
    return {"deleted": True, "id": item_id}
