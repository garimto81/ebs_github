"""Tables & Seats router — API-01 §5.7~5.8."""
from fastapi import APIRouter, Depends, Query
from sqlmodel import Session

from src.app.database import get_db
from src.middleware.rbac import get_current_user, require_role
from src.models.schemas import (
    ApiResponse,
    PlayerResponse,
    RebalanceRequest,
    SeatResponse,
    SeatUpdate,
    TableCreate,
    TableResponse,
    TableUpdate,
)
from src.models.user import User
from src.services.table_service import (
    assign_seat,
    create_table,
    delete_table,
    get_table,
    get_table_seats,
    launch_cc,
    list_all_tables,
    list_players_by_table,
    list_tables,
    rebalance_tables,
    update_seat_status,
    update_table,
)

# SG-008-b11 결정 (2026-04-20): deep-link 전환 후 endpoint 삭제.
# SG-008-b11 v1.2 (2026-05-03): Web 배포 variant — 동일 endpoint 복원.
#   Phase 1 Korea soft-launch 는 Docker Web (lobby-web :3000 + cc-web :3001) — browser
#   에서 OS deep-link 작동 불가. Endpoint 가 ① cc_url (browser navigate) ② deep_link
#   (desktop) ③ ws_url ④ launch_token (5min JWT) ⑤ cc_instance_id 모두 반환하여
#   client 가 환경에 맞는 launcher 선택. SSOT: docs/2. Development/2.2 Backend/APIs/
#   Backend_HTTP.md §16, SG-008-b11 v1.2.

router = APIRouter(prefix="/api/v1", tags=["tables"])


# ── Tables (static paths first) ────────────────────


@router.post("/tables/rebalance")
def api_rebalance(
    body: RebalanceRequest,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    result = rebalance_tables(
        body.event_flight_id, body.strategy, body.target_players_per_table, body.dry_run, db
    )
    return ApiResponse(data=result)


@router.get("/tables")
def api_list_tables_flat(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    flight_id: int | None = Query(None),
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """SSOT Backend_HTTP.md L402 — flat list with optional ?flight_id= filter."""
    items, total = list_all_tables(db, skip, limit, flight_id)
    return ApiResponse(
        data=[TableResponse.model_validate(t, from_attributes=True) for t in items],
        meta={"skip": skip, "limit": limit, "total": total},
    )


@router.post("/tables", status_code=201)
def api_create_table_flat(
    body: TableCreate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """SSOT Backend_HTTP.md L404 — flat POST. `event_flight_id` required in body."""
    from fastapi import HTTPException
    from fastapi import status as fa_status
    if body.event_flight_id is None:
        raise HTTPException(
            status_code=fa_status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"code": "FIELD_REQUIRED", "message": "event_flight_id required for flat POST /tables"},
        )
    t = create_table(body.event_flight_id, body, db)
    return ApiResponse(data=TableResponse.model_validate(t, from_attributes=True))


@router.get("/flights/{flight_id}/tables")
def api_list_tables(
    flight_id: int,
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Deprecated (nested) alias. Prefer GET /tables?flight_id=."""
    items, total = list_tables(flight_id, db, skip, limit)
    return ApiResponse(
        data=[TableResponse.model_validate(t, from_attributes=True) for t in items],
        meta={"skip": skip, "limit": limit, "total": total},
    )


@router.post("/flights/{flight_id}/tables", status_code=201)
def api_create_table(
    flight_id: int,
    body: TableCreate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """Deprecated (nested) alias. Prefer POST /tables with event_flight_id in body."""
    t = create_table(flight_id, body, db)
    return ApiResponse(data=TableResponse.model_validate(t, from_attributes=True))


@router.get("/tables/{table_id}")
def api_get_table(
    table_id: int,
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    t = get_table(table_id, db)
    return ApiResponse(data=TableResponse.model_validate(t, from_attributes=True))


@router.put("/tables/{table_id}")
def api_update_table(
    table_id: int,
    body: TableUpdate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    t = update_table(table_id, body, db)
    return ApiResponse(data=TableResponse.model_validate(t, from_attributes=True))


@router.delete("/tables/{table_id}")
def api_delete_table(
    table_id: int,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    delete_table(table_id, db)
    return ApiResponse(data={"deleted": True})


# SG-008-b11 v1.2 (2026-05-03 Conductor Mode A 자율) — Web 배포 variant 복원.
#   Phase 1 Korea soft-launch (Docker Web) 환경에서 OS deep-link 미작동 → endpoint 복원.
#   Response 가 cc_url (web) + deep_link (desktop) 둘 다 반환하여 client 가 선택.
#   기존 launch_cc() service 그대로 재사용. JWT 5min 짧은 수명 보존.


@router.post("/tables/{table_id}/launch-cc")
def api_launch_cc(
    table_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """SG-008-b11 v1.2 — CC launch (Web + Desktop dual-mode).

    Returns:
      tableId, status, ccInstanceId, launchToken (5min JWT),
      ccUrl (Web — http://cc-web:3001/?...),
      deepLink (Desktop — ebs-cc://table/{id}?...),
      wsUrl (ws://bo:8000/ws/cc?...)

    RBAC: admin / operator(assigned). viewer → 403.
    Idempotency-Key 미들웨어 처리 (별도).
    """
    # RBAC — admin 자율, operator 는 assigned table 만 (TODO: assigned_tables 매핑 추가 시 enforce)
    if user.role == "viewer":
        from fastapi import HTTPException
        from fastapi import status as fa_status

        raise HTTPException(
            status_code=fa_status.HTTP_403_FORBIDDEN,
            detail={"code": "RBAC_DENIED", "message": "viewer cannot launch CC"},
        )

    payload = launch_cc(table_id, user, db)
    # Web variant URL augmentation (SG-008-b11 v1.2).
    # EBS_EXTERNAL_HOST 가 browser-facing host (LAN IP 또는 localhost). CC web 의 외부 포트 = 3001.
    # CC_EXTERNAL_URL 직접 override 가능 (proxy/HTTPS 환경).
    import os

    cc_external = os.environ.get("CC_EXTERNAL_URL")
    if not cc_external:
        external_host = os.environ.get("EBS_EXTERNAL_HOST", "localhost")
        cc_external = f"http://{external_host}:3001"
    cc_external = cc_external.rstrip("/")
    payload["cc_url"] = (
        f"{cc_external}/?table_id={table_id}"
        f"&token={payload['launch_token']}"
        f"&cc_instance_id={payload['cc_instance_id']}"
    )
    payload["deep_link"] = (
        f"ebs-cc://table/{table_id}"
        f"?token={payload['launch_token']}"
        f"&cc_instance_id={payload['cc_instance_id']}"
    )
    return ApiResponse(data=payload)


@router.get("/tables/{table_id}/status")
def api_get_table_status(
    table_id: int,
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """SSOT Backend_HTTP.md L408 — real-time table status."""
    t = get_table(table_id, db)
    seats = get_table_seats(table_id, db)
    occupied = sum(1 for s in seats if s.status != "empty")
    return ApiResponse(data={
        "tableId": t.table_id,
        "status": t.status,
        "occupiedSeats": occupied,
        "maxPlayers": t.max_players,
    })


# ── Players-by-Table (5-level hierarchy completion) ─
# cascade:bo-hierarchy-ready (2026-05-12 S7 cycle-8)
#
# Lobby drill-down: Series → Event → Flight → Table → **Players**.
# Backed by `table_seats` join with `players` master. Returns active +
# busted + moved seats; empty seats are excluded. `seats` endpoint below
# remains the lower-level view (includes empties + seat metadata).


@router.get("/tables/{table_id}/players")
def api_list_players_by_table(
    table_id: int,
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """List players currently seated at a table.

    SSOT: 5-level hierarchy completion (cascade:bo-hierarchy-ready, 2026-05-12).
    Series → Event → Flight → Table → **Players** drill-down for Lobby.
    """
    items, total = list_players_by_table(table_id, db, skip, limit)
    return ApiResponse(
        data=[PlayerResponse.model_validate(p, from_attributes=True) for p in items],
        meta={"skip": skip, "limit": limit, "total": total, "table_id": table_id},
    )


# ── Seats ───────────────────────────────────────────


@router.get("/tables/{table_id}/seats")
def api_get_seats(
    table_id: int,
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    seats = get_table_seats(table_id, db)
    return ApiResponse(
        data=[SeatResponse.model_validate(s, from_attributes=True) for s in seats],
    )


@router.post("/tables/{table_id}/seats", status_code=201)
def api_assign_seat(
    table_id: int,
    body: SeatUpdate,
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """V9.5 P7: assign player to seat (frontend addPlayer).

    body: {seat_no, player_id, chip_count?}
    """
    if body.seat_no is None or body.player_id is None:
        from fastapi import HTTPException, status
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": "MISSING_FIELDS", "message": "seat_no and player_id required"},
        )
    seat = assign_seat(table_id, body.seat_no, body.player_id, db, body.chip_count or 0)
    return ApiResponse(data=SeatResponse.model_validate(seat, from_attributes=True))


@router.delete("/tables/{table_id}/seats/{seat_no}", status_code=200)
def api_vacate_seat(
    table_id: int,
    seat_no: int,
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """V9.5 P7: vacate seat (frontend removePlayer)."""
    from src.services.table_service import vacate_seat
    seat = vacate_seat(table_id, seat_no, db)
    return ApiResponse(data=SeatResponse.model_validate(seat, from_attributes=True))


@router.put("/tables/{table_id}/seats/{seat_no}")
def api_update_seat(
    table_id: int,
    seat_no: int,
    body: SeatUpdate,
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update a seat — assign player, change status, or update chip count.

    Logic:
    - If player_id is provided and seat is empty → assign (empty→new)
    - If status is provided → transition validation
    - If player_id is None and status is "empty" → vacate
    """
    # If assigning a player
    if body.player_id is not None and body.status is None:
        seat = assign_seat(table_id, seat_no, body.player_id, db, body.chip_count or 0)
        return ApiResponse(data=SeatResponse.model_validate(seat, from_attributes=True))

    # If changing status
    if body.status is not None:
        # Special: assigning with explicit status (player_id + status)
        if body.player_id is not None:
            seat = assign_seat(table_id, seat_no, body.player_id, db, body.chip_count or 0)
            # If requested status is not 'new', do a follow-up transition
            if body.status != "new":
                seat = update_seat_status(table_id, seat_no, body.status, db)
            return ApiResponse(data=SeatResponse.model_validate(seat, from_attributes=True))
        else:
            seat = update_seat_status(table_id, seat_no, body.status, db)
            return ApiResponse(data=SeatResponse.model_validate(seat, from_attributes=True))

    # Nothing meaningful to update
    from src.services.table_service import _get_seat
    seat = _get_seat(table_id, seat_no, db)
    return ApiResponse(data=SeatResponse.model_validate(seat, from_attributes=True))
