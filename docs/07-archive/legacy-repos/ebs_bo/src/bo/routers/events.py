from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from bo.db.engine import get_session
from bo.db.models import Event, EventFlight, User
from bo.middleware.auth import get_current_user
from bo.middleware.rbac import require_role
from bo.schemas.common import ApiResponse
from bo.schemas.event import EventCreate, EventRead, EventUpdate
from bo.schemas.flight import FlightRead
from bo.services.audit_service import record_audit
from bo.services.crud_service import create_item, delete_item, get_by_id, get_list, update_item

router = APIRouter(prefix="/events", tags=["Events"])


@router.get("", response_model=ApiResponse[list[EventRead]])
def list_events(
    page: int = 1,
    limit: int = 20,
    series_id: int | None = None,
    _: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    filters = {"series_id": series_id} if series_id else None
    return get_list(session, Event, page=page, limit=limit, filters=filters)


@router.get("/{event_id}", response_model=ApiResponse[EventRead])
def get_event(
    event_id: int,
    _: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    item = get_by_id(session, Event, event_id, pk_field="event_id")
    return ApiResponse(data=item)


@router.post("", response_model=ApiResponse[EventRead], status_code=201)
def create_event(
    body: EventCreate,
    current_user: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    item = create_item(session, Event, body.model_dump())
    record_audit(session, user_id=current_user.user_id, action="event.create", entity_type="event", entity_id=item.event_id)
    return ApiResponse(data=item)


@router.put("/{event_id}", response_model=ApiResponse[EventRead])
def update_event(
    event_id: int,
    body: EventUpdate,
    current_user: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    item = update_item(
        session, Event, event_id,
        body.model_dump(exclude_unset=True), pk_field="event_id",
    )
    record_audit(session, user_id=current_user.user_id, action="event.update", entity_type="event", entity_id=event_id)
    return ApiResponse(data=item)


@router.delete("/{event_id}", response_model=ApiResponse[dict])
def delete_event(
    event_id: int,
    current_user: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    # BO-03 E-5: Cannot delete Event while in "running" status
    event = session.get(Event, event_id)
    if event and event.status == "running":
        raise HTTPException(status_code=409, detail="진행 중인 이벤트는 삭제할 수 없습니다")
    result = delete_item(session, Event, event_id, pk_field="event_id")
    record_audit(session, user_id=current_user.user_id, action="event.delete", entity_type="event", entity_id=event_id)
    return ApiResponse(data=result)


VALID_TRANSITIONS = {
    "created": ["announced"],
    "announced": ["registering"],
    "registering": ["running"],
    "running": ["completed"],
    "completed": [],
}


@router.patch("/{event_id}/status")
def update_event_status(
    event_id: int,
    body: dict,
    current_user: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    event = session.get(Event, event_id)
    if not event:
        raise HTTPException(status_code=404, detail="이벤트를 찾을 수 없습니다")
    old_status = event.status
    new_status = body.get("status")
    if new_status not in VALID_TRANSITIONS.get(event.status, []):
        raise HTTPException(
            status_code=409,
            detail=f"'{event.status}' → '{new_status}' 전환은 허용되지 않습니다",
        )
    event.status = new_status
    session.add(event)
    session.commit()
    session.refresh(event)
    record_audit(session, user_id=current_user.user_id, action="event.status_changed", entity_type="event", entity_id=event_id, detail=f"{old_status} → {new_status}")
    return event


@router.get("/{event_id}/flights", response_model=ApiResponse[list[FlightRead]])
def get_event_flights(
    event_id: int,
    _: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    flights = session.exec(
        select(EventFlight).where(EventFlight.event_id == event_id)
    ).all()
    return ApiResponse(data=flights)
