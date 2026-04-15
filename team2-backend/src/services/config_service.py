"""Config scope resolution service — G-A3 (2026-04-15).

Schema.md §configs resolve_config() 의사코드 SSOT 기반 구현.
Override chain: table → event → series → global.

per-worker in-memory LRU cache (TTL 60s, maxsize 1024).
WebSocket ConfigChanged 수신 시 invalidate_config() 호출.
"""
from __future__ import annotations

import time
from threading import Lock
from typing import Optional

from sqlmodel import Session, select

from src.models.competition import Event, EventFlight
from src.models.config import Config
from src.models.table import Table

__all__ = [
    "resolve_config",
    "upsert_config",
    "invalidate_config",
    "invalidate_all",
]

# Scope priority (높을수록 좁음)
SCOPE_PRIORITY = {"table": 4, "event": 3, "series": 2, "global": 1}
VALID_SCOPES = frozenset(SCOPE_PRIORITY.keys())

# per-worker in-memory cache
# key: (config_key, table_id or None, event_id or None, series_id or None)
# value: (resolved_value, expires_at_unix)
_CACHE_TTL_SEC = 60.0
_CACHE_MAXSIZE = 1024
_cache: dict[tuple, tuple[Optional[str], float]] = {}
_cache_lock = Lock()


# ──────────────────────────────────────────────────────────────────
# applied_at_hint 판정 (Gap-Final-2)
# ──────────────────────────────────────────────────────────────────

_NEXT_HAND_KEY_PREFIXES = ("game.", "rule.", "blind.")
_MANUAL_KEY_PREFIXES = ("overlay.force_reload", "ops.maintenance")


def hint_for_key(key: str) -> str:
    """config key → applied_at_hint (immediate/next_hand/manual).

    Back_Office/Overview.md §3.6 핸드 중간 설정 변경 지연 규정 기반.
    """
    for p in _MANUAL_KEY_PREFIXES:
        if key.startswith(p):
            return "manual"
    for p in _NEXT_HAND_KEY_PREFIXES:
        if key.startswith(p):
            return "next_hand"
    return "immediate"


def _cache_key(key: str, table_id, event_id, series_id) -> tuple:
    return (key, table_id, event_id, series_id)


def _cache_get(ck: tuple) -> tuple[bool, Optional[str]]:
    with _cache_lock:
        entry = _cache.get(ck)
        if entry is None:
            return False, None
        value, expires_at = entry
        if time.monotonic() > expires_at:
            _cache.pop(ck, None)
            return False, None
        return True, value


def _cache_put(ck: tuple, value: Optional[str]) -> None:
    with _cache_lock:
        if len(_cache) >= _CACHE_MAXSIZE:
            # 가장 오래된 것 1개 제거 (단순 FIFO — 정확한 LRU 불필요)
            _cache.pop(next(iter(_cache)), None)
        _cache[ck] = (value, time.monotonic() + _CACHE_TTL_SEC)


def invalidate_config(
    key: str,
    scope: str,
    scope_id: Optional[int] = None,
) -> None:
    """ConfigChanged 수신 시 호출. 해당 scope 와 더 넓은 scope 의 cache entry 무효화.

    단순화: 해당 key 로 시작하는 모든 cache entry 제거 (정밀 invalidate 는 Phase 2+).
    """
    with _cache_lock:
        stale_keys = [ck for ck in _cache if ck[0] == key]
        for ck in stale_keys:
            _cache.pop(ck, None)


def invalidate_all() -> None:
    """전체 cache flush (테스트 및 설정 대량 변경 시)."""
    with _cache_lock:
        _cache.clear()


def _resolve_scope_ids(
    session: Session,
    *,
    table_id: Optional[int],
    event_id: Optional[int],
    series_id: Optional[int],
) -> tuple[Optional[int], Optional[int], Optional[int]]:
    """table_id 만 받으면 event_id / series_id 역참조."""
    if table_id and (event_id is None or series_id is None):
        row = session.exec(
            select(Event.event_id, Event.series_id)
            .join(EventFlight, EventFlight.event_id == Event.event_id)
            .join(Table, Table.event_flight_id == EventFlight.event_flight_id)
            .where(Table.table_id == table_id)
        ).first()
        if row is not None:
            if event_id is None:
                event_id = row[0]
            if series_id is None:
                series_id = row[1]
    return table_id, event_id, series_id


def resolve_config(
    session: Session,
    key: str,
    *,
    table_id: Optional[int] = None,
    event_id: Optional[int] = None,
    series_id: Optional[int] = None,
    default: Optional[str] = None,
    use_cache: bool = True,
) -> Optional[str]:
    """Config override 체인 해결: table → event → series → global → default.

    Args:
        session: SQLModel Session
        key: config key
        table_id/event_id/series_id: 좁은 순서대로 시도할 scope IDs
        default: 전부 없으면 반환값
        use_cache: per-worker in-memory cache 사용 여부

    Returns:
        value or default. 체인의 가장 좁은 scope 값을 반환.
    """
    # 1) scope_id 역참조
    table_id, event_id, series_id = _resolve_scope_ids(
        session, table_id=table_id, event_id=event_id, series_id=series_id
    )

    # 2) cache 조회
    ck = _cache_key(key, table_id, event_id, series_id)
    if use_cache:
        hit, cached = _cache_get(ck)
        if hit:
            return cached if cached is not None else default

    # 3) scope 체인 순회 (가장 좁은 순)
    candidates: list[tuple[str, Optional[int]]] = [
        ("table", table_id),
        ("event", event_id),
        ("series", series_id),
        ("global", None),
    ]

    resolved: Optional[str] = None
    for scope, sid in candidates:
        if scope != "global" and sid is None:
            continue
        stmt = select(Config.value).where(Config.key == key, Config.scope == scope)
        if scope == "global":
            stmt = stmt.where(Config.scope_id.is_(None))  # type: ignore[union-attr]
        else:
            stmt = stmt.where(Config.scope_id == sid)
        row = session.exec(stmt).first()
        if row is not None:
            resolved = row
            break

    if use_cache:
        _cache_put(ck, resolved)

    return resolved if resolved is not None else default


async def upsert_config(
    session: Session,
    key: str,
    value: str,
    *,
    scope: str = "global",
    scope_id: Optional[int] = None,
    category: str = "system",
    description: Optional[str] = None,
    actor_user_id: Optional[int] = None,
    ws_manager: Optional[Any] = None,
) -> tuple[Config, Optional[str]]:
    """Config upsert + cache invalidate.

    Returns:
        (config_row, old_value) — old_value 는 신규 insert 시 None.

    Note:
        WebSocket ConfigChanged 브로드캐스트는 호출자 책임 (서비스 레이어 분리).
    """
    if scope not in VALID_SCOPES:
        raise ValueError(f"invalid scope: {scope}")
    if scope == "global" and scope_id is not None:
        raise ValueError("global scope must not have scope_id")
    if scope != "global" and scope_id is None:
        raise ValueError(f"scope '{scope}' requires scope_id")

    row = session.exec(
        select(Config).where(
            Config.key == key,
            Config.scope == scope,
            Config.scope_id == scope_id if scope != "global" else Config.scope_id.is_(None),  # type: ignore[union-attr]
        )
    ).first()

    old_value: Optional[str] = None
    if row is not None:
        old_value = row.value
        row.value = value
        row.category = category
        if description is not None:
            row.description = description
        from src.models.config import utcnow as _utcnow
        row.updated_at = _utcnow()
        session.add(row)
    else:
        row = Config(
            key=key,
            value=value,
            scope=scope,
            scope_id=scope_id,
            category=category,
            description=description,
        )
        session.add(row)

    session.commit()
    session.refresh(row)

    # cache invalidate (해당 key 전체)
    invalidate_config(key, scope, scope_id)

    # Gap-Final-2 (2026-04-15): ConfigChanged WebSocket broadcast
    if ws_manager is not None:
        event = {
            "type": "ConfigChanged",
            "table_id": "*" if scope != "table" else str(scope_id),
            "payload": {
                "scope": scope,
                "scope_id": scope_id,
                "config_key": key,
                "old_value": old_value,
                "new_value": value,
                "actor_user_id": actor_user_id,
                "applied_at_hint": hint_for_key(key),
            },
        }
        # Lobby: 모든 CC/Lobby 구독자에게 (table scope 필터링은 client 측)
        await ws_manager.broadcast("lobby", "*", event)
        # CC 채널: table scope 면 해당 테이블만, 그 외는 fan-out
        cc_key = str(scope_id) if scope == "table" else "*"
        try:
            await ws_manager.broadcast("cc", cc_key, event)
        except Exception:
            # cc 채널 없음 허용 (Lobby-Only 배포)
            pass

    return row, old_value
