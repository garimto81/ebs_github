from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session

from bo.db.engine import get_session
from bo.db.models import EventFlight, User
from bo.middleware.auth import get_current_user
from bo.middleware.rbac import require_role
from bo.schemas.common import ApiResponse
from bo.schemas.flight import FlightCreate, FlightRead, FlightUpdate
from bo.services.crud_service import create_item, delete_item, get_by_id, get_list, update_item

router = APIRouter(prefix="/flights", tags=["Flights"])


@router.get("", response_model=ApiResponse[list[FlightRead]])
def list_flights(
    page: int = 1,
    limit: int = 20,
    event_id: int | None = None,
    _: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    filters = {"event_id": event_id} if event_id else None
    return get_list(session, EventFlight, page=page, limit=limit, filters=filters)


@router.get("/{flight_id}", response_model=ApiResponse[FlightRead])
def get_flight(
    flight_id: int,
    _: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    item = get_by_id(session, EventFlight, flight_id, pk_field="event_flight_id")
    return ApiResponse(data=item)


@router.post("", response_model=ApiResponse[FlightRead], status_code=201)
def create_flight(
    body: FlightCreate,
    _: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    item = create_item(session, EventFlight, body.model_dump())
    return ApiResponse(data=item)


@router.put("/{flight_id}", response_model=ApiResponse[FlightRead])
def update_flight(
    flight_id: int,
    body: FlightUpdate,
    _: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    item = update_item(
        session, EventFlight, flight_id,
        body.model_dump(exclude_unset=True), pk_field="event_flight_id",
    )
    return ApiResponse(data=item)


@router.delete("/{flight_id}", response_model=ApiResponse[dict])
def delete_flight(
    flight_id: int,
    _: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    # BO-03 F-3: Cannot delete Flight while in "running" status
    flight = session.get(EventFlight, flight_id)
    if flight and flight.status == "running":
        raise HTTPException(status_code=409, detail="진행 중인 Flight는 삭제할 수 없습니다")
    result = delete_item(session, EventFlight, flight_id, pk_field="event_flight_id")
    return ApiResponse(data=result)
