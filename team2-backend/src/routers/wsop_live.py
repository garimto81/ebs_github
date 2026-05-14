"""WSOP LIVE webhook router — Cycle 20 Wave 2 (issue #435) + SG-042 PR-A (Area 3).

SSOT contract: docs/2. Development/2.2 Backend/APIs/WSOP_LIVE_Chip_Count_Sync.md
WS event: docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md §4.2.11
State machine: docs/2. Development/2.5 Shared/Chip_Count_State.md
Backend HTTP: docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md §5.17.18

Receives POST /api/wsop-live/chip-count-snapshot push from WSOP LIVE during
tournament breaks. Authenticated via HMAC-SHA256 (out-of-band secret), not
JWT — this endpoint is server-to-server. Idempotency is enforced at the DB
layer per spec §7 to honour the 200/already_processed vs 202/accepted shape.

SG-042 PR-A Area 3 추가:
  GET /api/wsop-live/chip-count-state/{table_id}
  마지막 동기화 상태 (latest snapshot per seat) + total_chips 조회.
  인증: Admin/Operator only (RBAC).
"""
from __future__ import annotations

import hashlib
import hmac
import json
import logging
from datetime import datetime, timezone
from typing import Any, Optional

from fastapi import APIRouter, Depends, Request, Response
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field, ValidationError, field_validator
from sqlmodel import Session, select

from src.app.config import settings as app_settings
from src.app.database import get_engine
from src.middleware.rbac import require_role
from src.models.chip_count_snapshot import ChipCountSnapshot
from src.models.table import Table
from src.models.user import User
from src.websocket.publishers import publish_chip_count_synced

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/wsop-live", tags=["wsop-live-webhook"])

PATH = "/api/wsop-live/chip-count-snapshot"


# ── Pydantic request models ─────────────────────────────────


class _Seat(BaseModel):
    seat_number: int = Field(ge=1, le=10)
    player_id: Optional[int] = None
    chip_count: int = Field(ge=0)


class _Snapshot(BaseModel):
    snapshot_id: str
    break_id: int
    table_id: int
    recorded_at: str
    seats: list[_Seat] = Field(min_length=1, max_length=10)

    @field_validator("snapshot_id")
    @classmethod
    def _uuid_shape(cls, v: str) -> str:
        if len(v) < 32:
            raise ValueError("snapshot_id must be a UUID")
        return v


# ── HMAC + timestamp helpers ────────────────────────────────


def _canonical_string(method: str, path: str, timestamp: str,
                      body_bytes: bytes) -> str:
    body_hash = hashlib.sha256(body_bytes).hexdigest()
    return f"{method}\n{path}\n{timestamp}\n{body_hash}"


def _expected_signature(secret: str, method: str, path: str,
                        timestamp: str, body_bytes: bytes) -> str:
    msg = _canonical_string(method, path, timestamp, body_bytes).encode("utf-8")
    return hmac.new(secret.encode("utf-8"), msg, hashlib.sha256).hexdigest()


def _verify_signature(provided: str, method: str, path: str,
                      timestamp: str, body_bytes: bytes) -> bool:
    """Constant-time compare against the active and previous (rotation) secrets."""
    candidates = [s for s in (
        app_settings.wsop_live_webhook_secret,
        app_settings.wsop_live_webhook_secret_prev,
    ) if s]
    for secret in candidates:
        exp = _expected_signature(secret, method, path, timestamp, body_bytes)
        if hmac.compare_digest(exp, provided):
            return True
    return False


def _timestamp_drift_ok(timestamp: str) -> bool:
    try:
        ts_norm = (
            timestamp.replace("Z", "+00:00") if timestamp.endswith("Z") else timestamp
        )
        sent = datetime.fromisoformat(ts_norm)
    except (ValueError, TypeError):
        return False
    if sent.tzinfo is None:
        sent = sent.replace(tzinfo=timezone.utc)
    now = datetime.now(timezone.utc)
    skew = abs((now - sent).total_seconds())
    return skew <= app_settings.wsop_live_webhook_timestamp_skew_s


def _error(code: int, payload: dict) -> JSONResponse:
    return JSONResponse(status_code=code, content=payload)


# ── Endpoint ────────────────────────────────────────────────


@router.post("/chip-count-snapshot")
async def chip_count_snapshot(request: Request) -> Response:
    """Receive WSOP LIVE break-time chip count snapshot."""
    timestamp = request.headers.get("X-WSOP-Timestamp", "")
    signature = request.headers.get("X-WSOP-Signature", "")
    idem_key = request.headers.get("Idempotency-Key", "")

    body_bytes = await request.body()

    # 1. timestamp drift (replay protection)
    if not timestamp or not _timestamp_drift_ok(timestamp):
        return _error(401, {
            "error": "TIMESTAMP_DRIFT",
            "received": timestamp,
            "now": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        })

    # 2. HMAC verify
    secret_configured = bool(
        app_settings.wsop_live_webhook_secret
        or app_settings.wsop_live_webhook_secret_prev
    )
    if not secret_configured:
        logger.error("WSOP_LIVE_WEBHOOK_SECRET not configured")
        return _error(401, {"error": "SIGNATURE_INVALID"})
    if not signature or not _verify_signature(
        signature, "POST", PATH, timestamp, body_bytes,
    ):
        return _error(401, {"error": "SIGNATURE_INVALID"})

    # 3. parse + schema validate
    try:
        body_obj = json.loads(body_bytes.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError):
        return _error(400, {
            "error": "VALIDATION",
            "message": "body is not valid JSON",
        })

    try:
        snap = _Snapshot.model_validate(body_obj)
    except ValidationError as exc:
        errs = exc.errors()
        first = errs[0] if errs else {}
        loc = ".".join(str(p) for p in first.get("loc", []))
        return _error(400, {
            "error": "VALIDATION",
            "field": loc,
            "message": first.get("msg", "schema violation"),
        })

    # 4. Idempotency-Key vs body.snapshot_id
    if not idem_key or idem_key != snap.snapshot_id:
        return _error(409, {"error": "IDEMPOTENCY_MISMATCH"})

    # 5/6. DB existence check + INSERT + broadcast.
    engine = get_engine()
    received_at = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")

    with Session(engine) as db:
        existing = db.exec(
            select(ChipCountSnapshot)
            .where(ChipCountSnapshot.snapshot_id == snap.snapshot_id)
            .limit(1)
        ).first()
        if existing is not None:
            return JSONResponse(
                status_code=200,
                content={
                    "status": "already_processed",
                    "snapshot_id": snap.snapshot_id,
                    "received_at": existing.received_at,
                    "ws_event_dispatched": False,
                },
            )

        # FK guard — unknown table_id → 422 (spec §5.2)
        tbl = db.exec(
            select(Table).where(Table.table_id == snap.table_id).limit(1)
        ).first()
        if tbl is None:
            return _error(422, {
                "error": "TABLE_UNKNOWN",
                "table_id": snap.table_id,
            })

        raw_payload = body_bytes.decode("utf-8", errors="replace")
        seat_dicts: list[dict[str, Any]] = []
        for seat in snap.seats:
            row = ChipCountSnapshot(
                snapshot_id=snap.snapshot_id,
                table_id=snap.table_id,
                seat_number=seat.seat_number,
                player_id=seat.player_id,
                chip_count=seat.chip_count,
                break_id=snap.break_id,
                source="wsop-live-webhook",
                recorded_at=snap.recorded_at,
                received_at=received_at,
                signature_ok=True,
                raw_payload=raw_payload,
            )
            db.add(row)
            seat_dicts.append({
                "seat_number": seat.seat_number,
                "player_id": seat.player_id,
                "chip_count": seat.chip_count,
            })
        db.commit()

    # WS broadcast (after DB commit per spec §10.1)
    ws_dispatched = False
    try:
        manager = request.app.state.ws_manager
        await publish_chip_count_synced(
            manager=manager,
            table_id=snap.table_id,
            snapshot_id=snap.snapshot_id,
            break_id=snap.break_id,
            seats=seat_dicts,
            recorded_at=snap.recorded_at,
            received_at=received_at,
            signature_ok=True,
        )
        ws_dispatched = True
    except Exception as exc:  # noqa: BLE001
        logger.warning(
            "chip_count_synced broadcast failed (snapshot_id=%s): %s",
            snap.snapshot_id, exc,
        )

    return JSONResponse(
        status_code=202,
        content={
            "status": "accepted",
            "snapshot_id": snap.snapshot_id,
            "received_at": received_at,
            "ws_event_dispatched": ws_dispatched,
        },
    )


# ── GET /chip-count-state/{table_id} ────────────────────────────────────────
# SG-042 PR-A Area 3 — DR-F (data retrieval)
# 인증: Admin/Operator only (require_role)
# 마지막 동기화 상태 + seat_states + total_chips 반환.


@router.get("/chip-count-state/{table_id}")
def chip_count_state(
    table_id: int,
    _user: User = Depends(require_role("admin", "operator")),
) -> Response:
    """마지막 WSOP LIVE chip count 동기화 상태 조회.

    Backend HTTP §5.17.18 — GET /api/wsop-live/chip-count-state/{table_id}

    Returns:
        200: 최신 snapshot 기준 seat_states + total_chips.
        404: 테이블이 존재하지 않거나 스냅샷 없음.
    """
    engine = get_engine()
    with Session(engine) as db:
        # 테이블 존재 확인
        tbl = db.exec(
            select(Table).where(Table.table_id == table_id).limit(1)
        ).first()
        if tbl is None:
            return _error(404, {"error": "NO_SNAPSHOT", "table_id": table_id})

        # 가장 최신 break_id 식별 (break_id 최댓값 기준)
        all_snaps: list[ChipCountSnapshot] = db.exec(
            select(ChipCountSnapshot).where(
                ChipCountSnapshot.table_id == table_id,
            ).order_by(ChipCountSnapshot.id.desc())  # type: ignore[attr-defined]
        ).all()

        if not all_snaps:
            return _error(404, {"error": "NO_SNAPSHOT", "table_id": table_id})

        # 가장 최신 break_id 결정
        latest_break_id = max(s.break_id for s in all_snaps)
        latest_snaps = [s for s in all_snaps if s.break_id == latest_break_id]

        # 좌석별 최신 스냅샷 (break_id 동일 → id 내림차순 첫 번째)
        seat_latest: dict[int, ChipCountSnapshot] = {}
        for snap in sorted(latest_snaps, key=lambda s: s.id or 0, reverse=True):
            if snap.seat_number not in seat_latest:
                seat_latest[snap.seat_number] = snap

        # 대표 snapshot_id (break 내 첫 번째 row)
        rep = sorted(latest_snaps, key=lambda s: s.id or 0)[0]
        last_snapshot_id = rep.snapshot_id
        recorded_at = rep.recorded_at
        received_at = rep.received_at

        seat_states = [
            {
                "seat_number": snap.seat_number,
                "player_id": snap.player_id,
                "chip_count": snap.chip_count,
            }
            for snap in sorted(seat_latest.values(), key=lambda s: s.seat_number)
        ]
        total_chips = sum(s["chip_count"] for s in seat_states)

    return JSONResponse(
        status_code=200,
        content={
            "table_id": table_id,
            "last_snapshot_id": last_snapshot_id,
            "break_id": latest_break_id,
            "recorded_at": recorded_at,
            "received_at": received_at,
            "seat_states": seat_states,
            "total_chips": total_chips,
            "drift_threshold_exceeded": None,  # Engine(S8) 제공 예정
        },
    )
