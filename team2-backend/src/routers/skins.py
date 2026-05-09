"""Skins router — overlay theme management."""
from __future__ import annotations

import json
import os
import tempfile
import uuid
from pathlib import Path

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from sqlmodel import Session

from src.app.database import get_db
from src.middleware.rbac import get_current_user, require_role
from src.models.schemas import ApiResponse, SkinCreate, SkinResponse, SkinUpdate
from src.models.user import User
from src.services.skin_service import (
    activate_skin,
    create_skin,
    delete_skin,
    get_active_skin,
    get_skin,
    list_skins,
    update_skin,
)

router = APIRouter(prefix="/api/v1", tags=["skins"])

# 2026-05-10 D8 — Issue #196 resolution.
# Storage root for uploaded .gfskin archives. Override via env in prod.
SKINS_STORAGE_ROOT = Path(os.environ.get("EBS_SKINS_STORAGE", "/app/data/skins"))
MAX_GFSKIN_BYTES = 50 * 1024 * 1024  # SG-004 §1


# 2026-05-10 D8 — SG-004 7-stage validation inlined to avoid host-tools
# coupling inside the container image. Mirrors `tools/validate_gfskin.py`.
_OUTPUT_EVENT_CATALOG = frozenset({
    "holecards_revealed", "holecards_hidden", "community_board_updated",
    "pot_updated", "side_pot_updated", "equity_updated", "outs_updated",
    "action_badge", "player_info_updated", "player_status_updated",
    "position_indicator", "dealer_button_moved", "hand_start", "hand_end",
    "showdown_reveal", "timer_tick", "clock_state_changed",
    "blind_level_changed", "skin_activated", "security_delay_active",
    "error_indicator", "player_folded", "player_allin", "blinds_posted",
    "ante_posted", "winner_announced", "chip_count_updated", "timer_updated",
    "state_changed",
})
_MAX_FILES = 200
_MAX_TOTAL_BYTES = 50 * 1024 * 1024
_CURRENT_EBS_VERSION = "0.1.0"


def _semver_le(a: str, b: str) -> bool:
    try:
        ta = tuple(int(x) for x in a.split("."))
        tb = tuple(int(x) for x in b.split("."))
        return ta <= tb
    except (ValueError, AttributeError):
        return False


def _validate_gfskin_bytes(zip_bytes: bytes) -> dict:
    """SG-004 7-stage validation. Returns parsed manifest on success.

    Raises HTTPException(422/413/400) with canonical SG-004 code on failure.
    """
    import zipfile

    # Stage 0/1 — write to temp + open ZIP.
    with tempfile.NamedTemporaryFile(suffix=".gfskin", delete=False) as tmp:
        tmp.write(zip_bytes)
        tmp_path = Path(tmp.name)
    try:
        try:
            zf = zipfile.ZipFile(tmp_path, "r")
        except zipfile.BadZipFile as e:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail={"code": "GFSKIN_ZIP_INVALID", "stage": 1,
                        "message": f"Not a valid ZIP: {e}"},
            )
        with zf:
            infos = zf.infolist()
            if len(infos) > _MAX_FILES:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail={"code": "GFSKIN_ZIP_TOO_MANY_FILES", "stage": 1,
                            "message": f"{len(infos)} files > {_MAX_FILES}"},
                )
            total = sum(i.file_size for i in infos)
            if total > _MAX_TOTAL_BYTES:
                raise HTTPException(
                    status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                    detail={"code": "GFSKIN_ZIP_TOO_LARGE", "stage": 1,
                            "message": f"uncompressed {total} > {_MAX_TOTAL_BYTES}"},
                )

            names = {i.filename for i in infos}

            # Stage 2 — manifest.json
            if "manifest.json" not in names:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail={"code": "GFSKIN_MANIFEST_MISSING", "stage": 2,
                            "message": "manifest.json not found in archive"},
                )
            try:
                # Accept BOM (utf-8-sig) — common when manifest.json is
                # produced by Windows tooling (e.g. PowerShell Out-File utf8).
                manifest = json.loads(zf.read("manifest.json").decode("utf-8-sig"))
            except Exception as e:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail={"code": "GFSKIN_MANIFEST_INVALID", "stage": 2,
                            "message": f"Failed to parse manifest.json: {e}"},
                )
            for required in ("spec_version", "skin_id", "name", "version",
                             "rive_file", "supported_output_events"):
                if required not in manifest:
                    raise HTTPException(
                        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                        detail={"code": "GFSKIN_MANIFEST_INVALID", "stage": 2,
                                "message": f"manifest missing required field: {required}"},
                    )

            # Stage 3 — rive_file present + magic
            rive_name = manifest.get("rive_file", "overlay.riv")
            if rive_name not in names:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail={"code": "GFSKIN_RIVE_MISSING", "stage": 3,
                            "message": f"{rive_name} not found in archive"},
                )
            rive_bytes = zf.read(rive_name)
            if len(rive_bytes) == 0 or rive_bytes[:4] not in (b"RIVE", b"\x00\x00\x00\x00"):
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail={"code": "GFSKIN_RIVE_BAD_MAGIC", "stage": 3,
                            "message": f"{rive_name} bad magic bytes"},
                )

            # Stage 7 — supported_output_events subset
            events = set(manifest.get("supported_output_events") or [])
            unknown = events - _OUTPUT_EVENT_CATALOG
            if unknown:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail={"code": "GFSKIN_EVENT_UNKNOWN", "stage": 7,
                            "message": f"Unknown OutputEvents: {sorted(unknown)}"},
                )

            # Stage 8 — min_ebs_version
            min_v = manifest.get("min_ebs_version", "0.0.0")
            if not _semver_le(min_v, _CURRENT_EBS_VERSION):
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail={"code": "GFSKIN_VERSION_MISMATCH", "stage": 8,
                            "message": f"min_ebs_version={min_v} > current={_CURRENT_EBS_VERSION}"},
                )

            return manifest
    finally:
        try:
            tmp_path.unlink()
        except OSError:
            pass


@router.get("/skins")
def api_list_skins(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    items, total = list_skins(db, skip, limit)
    return ApiResponse(
        data=[SkinResponse.model_validate(s, from_attributes=True) for s in items],
        meta={"skip": skip, "limit": limit, "total": total},
    )


@router.get("/skins/active")
def api_get_active_skin(
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    s = get_active_skin(db)
    return ApiResponse(
        data=SkinResponse.model_validate(s, from_attributes=True) if s else None,
    )


@router.get("/skins/{skin_id}")
def api_get_skin(
    skin_id: int,
    _user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    s = get_skin(skin_id, db)
    return ApiResponse(data=SkinResponse.model_validate(s, from_attributes=True))


@router.post("/skins", status_code=201)
def api_create_skin(
    body: SkinCreate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    s = create_skin(body, db)
    return ApiResponse(data=SkinResponse.model_validate(s, from_attributes=True))


@router.put("/skins/{skin_id}")
def api_update_skin(
    skin_id: int,
    body: SkinUpdate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """SSOT Backend_HTTP.md L745 — canonical metadata update."""
    s = update_skin(skin_id, body, db)
    return ApiResponse(data=SkinResponse.model_validate(s, from_attributes=True))


@router.patch("/skins/{skin_id}/metadata")
def api_update_skin_metadata_legacy(
    skin_id: int,
    body: SkinUpdate,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """Deprecated alias. Prefer PUT /skins/:id."""
    s = update_skin(skin_id, body, db)
    return ApiResponse(data=SkinResponse.model_validate(s, from_attributes=True))


@router.post("/skins/{skin_id}/activate")
def api_activate_skin(
    skin_id: int,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """SSOT Backend_HTTP.md L749 — POST is canonical method."""
    s = activate_skin(skin_id, db)
    return ApiResponse(data=SkinResponse.model_validate(s, from_attributes=True))


@router.post("/skins/{skin_id}/deactivate")
def api_deactivate_skin(
    skin_id: int,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """V9.5 P7: 해당 skin 의 default 해제."""
    from src.services.skin_service import deactivate_skin
    s = deactivate_skin(skin_id, db)
    return ApiResponse(data=SkinResponse.model_validate(s, from_attributes=True))


@router.put("/skins/{skin_id}/activate")
def api_activate_skin_legacy(
    skin_id: int,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """Deprecated method alias. Prefer POST."""
    s = activate_skin(skin_id, db)
    return ApiResponse(data=SkinResponse.model_validate(s, from_attributes=True))


@router.delete("/skins/{skin_id}")
def api_delete_skin(
    skin_id: int,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    delete_skin(skin_id, db)
    return ApiResponse(data={"deleted": True})


# 2026-05-10 D8 — Issue #196 resolution.
# CCR-013 §1 spec compliance: .gfskin ZIP multipart upload.
# Pipeline: receive UploadFile -> read bytes (size guard) -> validate_gfskin
# 7-stage check -> persist to SKINS_STORAGE_ROOT/<uuid>.gfskin -> create Skin
# row with manifest-derived metadata.
@router.post("/skins/upload", status_code=201)
async def api_upload_skin(
    file: UploadFile = File(...),
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    """Upload a .gfskin ZIP archive (CCR-013 spec, SG-004 7-stage validation).

    Returns the created Skin row plus the storage path. The archive itself is
    parsed by tools/validate_gfskin.py; only the manifest summary is mirrored
    into the DB. Errors propagate as 422 with the canonical SG-004 code
    (e.g. GFSKIN_MANIFEST_INVALID, GFSKIN_RIVE_MISSING, ...).
    """
    if not file.filename or not file.filename.lower().endswith(".gfskin"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": "GFSKIN_BAD_EXTENSION",
                    "message": "Filename must end with .gfskin"},
        )

    raw = await file.read()
    if len(raw) > MAX_GFSKIN_BYTES:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail={"code": "GFSKIN_ZIP_TOO_LARGE",
                    "message": f"size {len(raw)} > {MAX_GFSKIN_BYTES}"},
        )
    if len(raw) == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": "GFSKIN_EMPTY", "message": "Empty upload"},
        )

    manifest = _validate_gfskin_bytes(raw)

    # Derive name from manifest.name (localized) — prefer EN, fallback any key.
    names_obj = manifest.get("name") or {}
    skin_display_name = (
        names_obj.get("en")
        or names_obj.get("ko")
        or next(iter(names_obj.values()), None)
        or manifest.get("skin_id")
        or "unnamed-skin"
    )

    # Persist archive on disk.
    SKINS_STORAGE_ROOT.mkdir(parents=True, exist_ok=True)
    storage_id = uuid.uuid4().hex
    storage_path = SKINS_STORAGE_ROOT / f"{storage_id}.gfskin"
    storage_path.write_bytes(raw)

    # Mirror manifest metadata into the Skin row.
    theme_payload = json.dumps({
        "spec_version": manifest.get("spec_version"),
        "version": manifest.get("version"),
        "rive_file": manifest.get("rive_file"),
        "rive_artboard": manifest.get("rive_artboard"),
        "supported_output_events": manifest.get("supported_output_events", []),
        "min_ebs_version": manifest.get("min_ebs_version"),
        "storage_path": str(storage_path),
        "storage_id": storage_id,
        "byte_size": len(raw),
    }, ensure_ascii=False)

    skin_create = SkinCreate(
        name=skin_display_name,
        description=manifest.get("author") or manifest.get("license") or None,
        theme_data=theme_payload,
    )
    try:
        skin = create_skin(skin_create, db)
    except HTTPException:
        # Roll back the on-disk archive on DB conflict (duplicate name).
        try:
            storage_path.unlink()
        except OSError:
            pass
        raise

    return ApiResponse(
        data=SkinResponse.model_validate(skin, from_attributes=True),
        meta={
            "manifest": {
                "skin_id": manifest.get("skin_id"),
                "version": manifest.get("version"),
                "spec_version": manifest.get("spec_version"),
                "rive_artboard": manifest.get("rive_artboard"),
                "events": len(manifest.get("supported_output_events", [])),
            },
            "storage_id": storage_id,
            "size_bytes": len(raw),
        },
    )
