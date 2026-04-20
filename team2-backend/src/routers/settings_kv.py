"""SG-003 Settings KV Router — 6탭 × 4-level scope override.

Endpoints:
  GET    /api/v1/settings?scope_level=&scope_id=&tab=&key=   — list (filter)
  PUT    /api/v1/settings                                    — upsert one key
  DELETE /api/v1/settings                                    — delete one key
  GET    /api/v1/settings/resolved?tab=&table_id=&event_id=&series_id=
                                                             — effective values
                                                               after 4-level override

Spec: docs/4. Operations/Conductor_Backlog/SG-003-settings-6tabs-schema.md
      docs/2. Development/2.2 Backend/Database/Schema.md §settings_kv

Scope hierarchy (lowest → highest precedence):
  global → series → event → table   (user-tab uses 'user' scope_level, scope_id=user_id)

This router is **skeleton only**. team2 session wires:
  [TODO-T2-011] DB session dependency + settings_kv table (migration 0002)
  [TODO-T2-012] RBAC gating (admin only for global; operator for table within assignment)
  [TODO-T2-013] resolved endpoint — run SELECT with WHERE scope_level IN (...) and
               ORDER BY CASE scope_level ('global'=1,'series'=2,'event'=3,'table'=4)
               then overlay rows in ascending precedence per (tab, key).
  [TODO-T2-014] audit_events: settings_changed (old_value, new_value, scope, actor)
  [TODO-T2-015] validate `value` JSON against per-(tab,key) schema when catalog exists
"""
from __future__ import annotations

from datetime import datetime
from typing import Any, Literal

from fastapi import APIRouter, HTTPException, Query, status
from pydantic import BaseModel, Field

router = APIRouter(prefix="/api/v1/settings", tags=["settings"])


# ---------------------------------------------------------------------------
# Enums / constants
# ---------------------------------------------------------------------------

ScopeLevel = Literal["global", "series", "event", "table", "user"]
SettingsTab = Literal[
    "outputs",    # Tab 1 — 방송 출력 (SDI/NDI/Preview)
    "gfx",        # Tab 2 — Rive 스킨 + 색상 + 애니메이션
    "display",    # Tab 3 — Lobby/CC UI 설정
    "rules",      # Tab 4 — 게임 규칙 (블라인드, 변종)
    "stats",      # Tab 5 — 통계 표시
    "preferences",# Tab 6 — 개인화 (단축키, 기본값)
]

VALID_SCOPE_LEVELS = {"global", "series", "event", "table", "user"}
VALID_TABS = {"outputs", "gfx", "display", "rules", "stats", "preferences"}


# ---------------------------------------------------------------------------
# Schemas
# ---------------------------------------------------------------------------


class SettingsKvIn(BaseModel):
    """PUT /settings payload — upsert single (scope, tab, key)."""

    scope_level: ScopeLevel
    scope_id: str | None = Field(
        default=None,
        description="series.id / event.id / table.id / user.id; NULL iff scope_level='global'",
    )
    tab: SettingsTab
    key: str = Field(..., min_length=1, max_length=100)
    value: Any = Field(..., description="JSON-serializable value (string/number/bool/list/dict)")


class SettingsKvOut(BaseModel):
    id: str
    scope_level: ScopeLevel
    scope_id: str | None
    tab: SettingsTab
    key: str
    value: Any
    updated_at: datetime
    updated_by: str | None


class SettingsKvDeleteIn(BaseModel):
    """DELETE /settings payload (body, not path) — targets exact 4-tuple."""

    scope_level: ScopeLevel
    scope_id: str | None = None
    tab: SettingsTab
    key: str


class SettingsResolvedOut(BaseModel):
    """GET /settings/resolved — effective values after override chain.

    Returns all keys for the requested tab at the requested target scope,
    with each key's value chosen from the most specific scope that defines it.
    """

    tab: SettingsTab
    target: dict[str, str | None] = Field(
        default_factory=dict,
        description="{series_id?, event_id?, table_id?, user_id?} — context used",
    )
    values: dict[str, Any] = Field(
        default_factory=dict,
        description="key → resolved value after 4-level override",
    )
    provenance: dict[str, ScopeLevel] = Field(
        default_factory=dict,
        description="key → scope_level that supplied the winning value",
    )


# ---------------------------------------------------------------------------
# Validation helpers (reusable by team2 DB-wired impl)
# ---------------------------------------------------------------------------


def _validate_scope(scope_level: str, scope_id: str | None) -> None:
    if scope_level not in VALID_SCOPE_LEVELS:
        raise HTTPException(
            status_code=400,
            detail={"code": "INVALID_SCOPE_LEVEL", "allowed": sorted(VALID_SCOPE_LEVELS)},
        )
    if scope_level == "global" and scope_id is not None:
        raise HTTPException(
            status_code=400,
            detail={"code": "SCOPE_ID_NOT_ALLOWED", "message": "global scope must have scope_id=null"},
        )
    if scope_level != "global" and not scope_id:
        raise HTTPException(
            status_code=400,
            detail={"code": "SCOPE_ID_REQUIRED", "message": f"scope_level={scope_level} requires scope_id"},
        )


def _validate_tab(tab: str) -> None:
    if tab not in VALID_TABS:
        raise HTTPException(
            status_code=400,
            detail={"code": "INVALID_TAB", "allowed": sorted(VALID_TABS)},
        )


# ---------------------------------------------------------------------------
# Endpoints — skeleton (501) with complete arg validation + schema
# ---------------------------------------------------------------------------


@router.get("", response_model=list[SettingsKvOut])
async def list_settings(
    scope_level: ScopeLevel | None = Query(default=None),
    scope_id: str | None = Query(default=None),
    tab: SettingsTab | None = Query(default=None),
    key: str | None = Query(default=None),
) -> list[SettingsKvOut]:
    """List settings rows, optionally filtered.

    No filter → full catalog (Admin only). Typical usage: (scope_level, scope_id, tab).

    [TODO-T2-011]: replace with db.exec(select(SettingsKv).where(...))
    """
    if scope_level is not None:
        _validate_scope(scope_level, scope_id)
    if tab is not None:
        _validate_tab(tab)
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="skeleton: team2 session to implement [TODO-T2-011]",
    )


@router.put("", response_model=SettingsKvOut)
async def upsert_setting(payload: SettingsKvIn) -> SettingsKvOut:
    """Upsert one setting row. Idempotent on (scope_level, scope_id, tab, key).

    [TODO-T2-011]: INSERT ... ON CONFLICT (scope_level, scope_id, tab, key) DO UPDATE.
    [TODO-T2-014]: emit audit_event settings_changed with old/new value.
    [TODO-T2-015]: validate payload.value against tab+key schema (when catalog ready).
    """
    _validate_scope(payload.scope_level, payload.scope_id)
    _validate_tab(payload.tab)
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="skeleton: team2 session to implement [TODO-T2-011]",
    )


@router.delete("", status_code=status.HTTP_204_NO_CONTENT)
async def delete_setting(payload: SettingsKvDeleteIn) -> None:
    """Delete a single (scope, tab, key). Scope falls back to next level on resolve.

    [TODO-T2-011]: DELETE FROM settings_kv WHERE ... .
    [TODO-T2-014]: emit audit_event settings_deleted.
    """
    _validate_scope(payload.scope_level, payload.scope_id)
    _validate_tab(payload.tab)
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="skeleton: team2 session to implement [TODO-T2-011]",
    )


@router.get("/resolved", response_model=SettingsResolvedOut)
async def get_resolved_settings(
    tab: SettingsTab,
    table_id: str | None = Query(default=None),
    event_id: str | None = Query(default=None),
    series_id: str | None = Query(default=None),
    user_id: str | None = Query(default=None),
) -> SettingsResolvedOut:
    """Return effective values for `tab` after 4-level scope override.

    Resolution order (lowest → highest precedence, highest wins):
      1. global                            — always applies
      2. series (if series_id given)       — overrides global
      3. event  (if event_id  given)       — overrides series
      4. table  (if table_id  given)       — overrides event
      5. user   (if user_id   given, only for preferences/display tabs)

    Implementation sketch [TODO-T2-013]:
    ```
    scopes = [('global', None)]
    if series_id: scopes.append(('series', series_id))
    if event_id:  scopes.append(('event',  event_id))
    if table_id:  scopes.append(('table',  table_id))
    if user_id and tab in ('preferences','display'):
        scopes.append(('user', user_id))

    rows = db.exec(
        select(SettingsKv).where(
            SettingsKv.tab == tab,
            or_(*[(SettingsKv.scope_level==lvl) & (SettingsKv.scope_id==sid) for lvl,sid in scopes])
        )
    ).all()

    # Overlay in ascending precedence (later overrides earlier)
    PRECEDENCE = {'global':0,'series':1,'event':2,'table':3,'user':4}
    rows.sort(key=lambda r: PRECEDENCE[r.scope_level])

    values, provenance = {}, {}
    for r in rows:
        values[r.key] = r.value
        provenance[r.key] = r.scope_level
    return SettingsResolvedOut(
        tab=tab,
        target={'series_id':series_id,'event_id':event_id,'table_id':table_id,'user_id':user_id},
        values=values,
        provenance=provenance,
    )
    ```
    """
    _validate_tab(tab)
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="skeleton: team2 session to implement [TODO-T2-013]",
    )


# ---------------------------------------------------------------------------
# Router registration note
# ---------------------------------------------------------------------------
# In src/main.py, add after existing configs_router include:
#
#   from src.routers.settings_kv import router as settings_kv_router
#   app.include_router(settings_kv_router)
#
# Co-exists with legacy /api/v1/configs/{section} (configs.py) — configs.py is
# the thin section-scoped wrapper; settings_kv.py is the 4-level scope store
# used by SG-003 Settings 6-탭.
