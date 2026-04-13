from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from bo.db.engine import get_session
from bo.db.models import Table, User
from bo.db.models.rfid_reader import RfidReader
from bo.middleware.auth import get_current_user
from bo.middleware.rbac import require_role
from bo.schemas.common import ApiResponse
from bo.services.audit_service import record_audit

router = APIRouter(prefix="/rfid-readers", tags=["RFID Readers"])


@router.get("", response_model=ApiResponse[list])
def list_readers(
    _: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    readers = session.exec(select(RfidReader)).all()
    return ApiResponse(data=readers)


@router.get("/{reader_id}", response_model=ApiResponse)
def get_reader(
    reader_id: int,
    _: User = Depends(get_current_user),
    session: Session = Depends(get_session),
):
    reader = session.get(RfidReader, reader_id)
    if not reader:
        raise HTTPException(404, "RFID 리더를 찾을 수 없습니다")
    return ApiResponse(data=reader)


@router.post("", response_model=ApiResponse, status_code=201)
def create_reader(
    body: dict,
    current_user: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    serial = body.get("serial_number")
    if not serial:
        raise HTTPException(422, "serial_number is required")
    existing = session.exec(
        select(RfidReader).where(RfidReader.serial_number == serial)
    ).first()
    if existing:
        raise HTTPException(409, "이미 등록된 리더입니다")
    reader = RfidReader(
        serial_number=serial,
        alias=body.get("alias"),
        firmware_version=body.get("firmware_version"),
    )
    session.add(reader)
    session.commit()
    session.refresh(reader)
    record_audit(session, user_id=current_user.user_id, action="rfid_reader.create", entity_type="rfid_reader", entity_id=reader.reader_id)
    return ApiResponse(data=reader)


@router.put("/{reader_id}", response_model=ApiResponse)
def update_reader(
    reader_id: int,
    body: dict,
    current_user: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    reader = session.get(RfidReader, reader_id)
    if not reader:
        raise HTTPException(404, "RFID 리더를 찾을 수 없습니다")

    # Table assignment validation
    new_table_id = body.get("table_id")
    if new_table_id is not None:
        table = session.get(Table, new_table_id)
        if not table:
            raise HTTPException(404, "테이블을 찾을 수 없습니다")
        if table.type != "feature":
            raise HTTPException(400, "Feature Table만 RFID 리더 할당 가능")
        # 1:1: unassign any reader already on that table
        old_reader = session.exec(
            select(RfidReader).where(RfidReader.table_id == new_table_id, RfidReader.reader_id != reader_id)
        ).first()
        if old_reader:
            old_reader.table_id = None
            session.add(old_reader)

    for key in ("alias", "table_id", "firmware_version"):
        if key in body:
            setattr(reader, key, body[key])
    session.add(reader)
    session.commit()
    session.refresh(reader)
    record_audit(session, user_id=current_user.user_id, action="rfid_reader.update", entity_type="rfid_reader", entity_id=reader_id)
    return ApiResponse(data=reader)


@router.delete("/{reader_id}", response_model=ApiResponse[dict])
def delete_reader(
    reader_id: int,
    current_user: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    reader = session.get(RfidReader, reader_id)
    if not reader:
        raise HTTPException(404, "RFID 리더를 찾을 수 없습니다")
    if reader.table_id is not None:
        raise HTTPException(400, "할당 해제 후 삭제 가능")
    session.delete(reader)
    session.commit()
    record_audit(session, user_id=current_user.user_id, action="rfid_reader.delete", entity_type="rfid_reader", entity_id=reader_id)
    return ApiResponse(data={"reader_id": reader_id, "deleted": True})


@router.put("/{reader_id}/mode", response_model=ApiResponse)
def toggle_reader_mode(
    reader_id: int,
    body: dict,
    current_user: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    reader = session.get(RfidReader, reader_id)
    if not reader:
        raise HTTPException(404, "RFID 리더를 찾을 수 없습니다")
    if reader.table_id:
        table = session.get(Table, reader.table_id)
        if table and table.status == "live":
            raise HTTPException(403, "핸드 종료 후 전환 가능")
    new_mode = body.get("mode")
    if new_mode not in ("real", "mock"):
        raise HTTPException(422, "mode must be 'real' or 'mock'")
    reader.mode = new_mode
    session.add(reader)
    session.commit()
    session.refresh(reader)
    record_audit(session, user_id=current_user.user_id, action="rfid_reader.mode_change", entity_type="rfid_reader", entity_id=reader_id, detail=f"mode={new_mode}")
    return ApiResponse(data=reader)
