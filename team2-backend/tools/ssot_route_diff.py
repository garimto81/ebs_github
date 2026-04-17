"""SSOT route diff — Backend_HTTP.md ↔ FastAPI app routes.

Enforces Backend_HTTP.md compliance at CI time. Exits non-zero with a
missing/extra summary so that Team 2 cannot silently drift from SSOT
again (the audit on 2026-04-17 found 26 missing REST endpoints).

Usage:
    python tools/ssot_route_diff.py

Exit codes:
    0 — all SSOT endpoints implemented
    1 — one or more SSOT endpoints missing (blocker)
    2 — usage / parse error

Informational (not a blocker): implementation-only endpoints. These are
reported but do not fail CI; documenting them back into the SSOT is a
separate governance step.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SSOT_PATH = ROOT.parent / "docs" / "2. Development" / "2.2 Backend" / "APIs" / "Backend_HTTP.md"

# Endpoints intentionally declared elsewhere (auth, clock subroutes) or
# covered by separate SSOT files (WebSocket_Events.md, Auth_and_Session.md).
_SECTIONS_TO_AUDIT: frozenset[str] = frozenset({
    # skip §5.1 Auth — Auth_and_Session.md is its SSOT
    "5.2", "5.3", "5.4", "5.5", "5.6", "5.6.1",
    "5.7", "5.8", "5.9", "5.10", "5.11", "5.12",
    "5.13", "5.13.1", "5.14", "5.15", "5.16",
})

# Informational endpoints that the impl exposes for operational reasons
# (mock seeding, audit export, test hooks). These are allowed and do not
# count as drift. Use `{*}` placeholder (same form as _normalize_path).
_ALLOWED_IMPL_ONLY: frozenset[str] = frozenset({
    "POST /sync/mock/seed",
    "DELETE /sync/mock/reset",
    "POST /sync/trigger/{*}",
    "GET /sync/status",
    "GET /audit-logs/download",
    "GET /audit-events",
    "POST /events/{*}/undo",
    "GET /skins/active",
    # Deprecated nested aliases retained for back-compat
    "GET /flights/{*}/tables",
    "POST /flights/{*}/tables",
    "GET /events/{*}/flights",
    "POST /events/{*}/flights",
    "GET /series/{*}/events",
    "POST /series/{*}/events",
    "PATCH /skins/{*}/metadata",  # deprecated alias of PUT /skins/:id
    "PUT /skins/{*}/activate",    # deprecated alias of POST /skins/:id/activate
    # Phase 1 flat-path variants retained until series-scoped landing (B-066)
    "GET /blind-structures",
    "GET /blind-structures/{*}",
    "POST /blind-structures",
    "PUT /blind-structures/{*}",
    "DELETE /blind-structures/{*}",
    "GET /payout-structures",
    "GET /payout-structures/{*}",
    "POST /payout-structures",
    "PUT /payout-structures/{*}",
    "DELETE /payout-structures/{*}",
})


# Known SSOT gaps tracked in Backlog B-066 (Phase C).
# Listing here distinguishes "planned & scheduled" from "silent drift".
# Gate fails on missing endpoints NOT in this set. Empty this list as
# Phase C lands, making the gate strict again.
_B066_KNOWN_GAPS: frozenset[str] = frozenset({
    # BlindStructure series scope (8)
    "GET /series/{*}/blind-structures",
    "GET /series/{*}/blind-structures/templates/{*}",
    "GET /series/{*}/blind-structures/{*}",
    "POST /series/{*}/blind-structures",
    "PUT /series/{*}/blind-structures/{*}",
    "DELETE /series/{*}/blind-structures/{*}",
    # PayoutStructure series + flight scope (7)
    "GET /flights/{*}/payout-structure",
    "PUT /flights/{*}/payout-structure",
    "GET /series/{*}/payout-structures",
    "GET /series/{*}/payout-structures/{*}",
    "POST /series/{*}/payout-structures",
    "PUT /series/{*}/payout-structures/{*}",
    "DELETE /series/{*}/payout-structures/{*}",
    # Skin file I/O (2)
    "GET /skins/{*}/download",
    "POST /skins/{*}/duplicate",
    "POST /skins/{*}/upload",
})


def _normalize_path(path: str) -> str:
    """Normalize path params to canonical `{*}` placeholders.

    SSOT uses `:id` style, FastAPI uses `{user_id}`, `{flight_id}` etc.
    Param *names* differ freely between SSOT and impl; we only care about
    method + positional parameterization, so replace all `:name` / `{name}`
    with `{*}` so equality compares structurally.
    """
    # Remove `/api/v1` prefix for comparison (all audited endpoints share it)
    path = re.sub(r"^/api/v1", "", path)
    # Collapse `:name` and `{name}` to `{*}`
    path = re.sub(r":(\w+)", r"{*}", path)
    path = re.sub(r"\{[^/}]+\}", "{*}", path)
    return path


def parse_ssot(ssot_text: str) -> set[str]:
    """Extract `METHOD /path` tuples from Backend_HTTP.md tables within scope.

    Grammar: markdown rows `| METHOD | \`/path\` | desc | role |` inside
    a section starting with `### <section_id> ...`.
    """
    endpoints: set[str] = set()
    current_section: str | None = None

    section_re = re.compile(r"^###+\s+(\d+(?:\.\d+)*)\s+")
    row_re = re.compile(
        r"^\|\s*(GET|POST|PUT|PATCH|DELETE)\s*\|\s*`([^`]+)`\s*\|"
    )

    for line in ssot_text.splitlines():
        m = section_re.match(line)
        if m:
            current_section = m.group(1)
            continue
        if current_section not in _SECTIONS_TO_AUDIT:
            continue
        m = row_re.match(line)
        if m:
            method = m.group(1)
            path = _normalize_path(m.group(2).strip())
            endpoints.add(f"{method} {path}")

    return endpoints


def collect_impl_routes() -> set[str]:
    """Return METHOD /path set from FastAPI app (strip /api/v1 prefix)."""
    sys.path.insert(0, str(ROOT))
    # Ensure settings loads with test profile to avoid prod guards
    import os

    os.environ.setdefault("AUTH_PROFILE", "dev")
    from src.main import app

    endpoints: set[str] = set()
    for route in app.routes:
        if not hasattr(route, "methods") or not hasattr(route, "path"):
            continue
        path = route.path
        # Audit only `/api/v1/...` (auth has its own SSOT file)
        if not path.startswith("/api/v1"):
            continue
        norm = _normalize_path(path)
        for method in route.methods - {"HEAD", "OPTIONS"}:
            endpoints.add(f"{method} {norm}")
    return endpoints


def main() -> int:
    if not SSOT_PATH.exists():
        print(f"ERROR: SSOT not found: {SSOT_PATH}", file=sys.stderr)
        return 2

    ssot_endpoints = parse_ssot(SSOT_PATH.read_text(encoding="utf-8"))
    if not ssot_endpoints:
        print("ERROR: no endpoints parsed from SSOT", file=sys.stderr)
        return 2

    impl_endpoints = collect_impl_routes()

    all_missing = ssot_endpoints - impl_endpoints
    unexpected_missing = sorted(all_missing - _B066_KNOWN_GAPS)
    planned_missing = sorted(all_missing & _B066_KNOWN_GAPS)
    extra = sorted((impl_endpoints - ssot_endpoints) - _ALLOWED_IMPL_ONLY)

    print(f"SSOT endpoints audited: {len(ssot_endpoints)}")
    print(f"Impl endpoints:         {len(impl_endpoints)}")
    print(f"Allow-listed impl-only: {len(_ALLOWED_IMPL_ONLY)}")
    print(f"Planned gaps (B-066):   {len(_B066_KNOWN_GAPS)}")
    print()

    if planned_missing:
        print(
            f"[PLANNED] {len(planned_missing)} SSOT endpoint(s) pending "
            f"(Backlog B-066, Phase C):"
        )
        for e in planned_missing:
            print(f"  - {e}")
        print()

    if unexpected_missing:
        print(
            f"[FAIL] {len(unexpected_missing)} unexpected SSOT gap(s) "
            f"(not in B-066 scope — new drift):"
        )
        for e in unexpected_missing:
            print(f"  - {e}")
        print()

    if extra:
        print(
            f"[WARN] {len(extra)} impl endpoint(s) not in SSOT "
            f"(not a blocker; update SSOT or _ALLOWED_IMPL_ONLY):"
        )
        for e in extra:
            print(f"  - {e}")
        print()

    if not unexpected_missing:
        print("[OK] No unexpected SSOT drift.")
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
