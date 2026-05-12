"""Precise mismatch analysis between .http scenarios and BO routers.

Matching logic:
- A router pattern `/api/v1/decks/{}` matches a .http call `/api/v1/decks/anything`
- Conversely, a router pattern `/api/v1/decks/{}/cards/{}` matches `/api/v1/decks//cards/AS`
  (treating literal IDs in .http as path-param substitutions)
- Same method required for a match
- Empty path-param segments (`//`) treated as `{}` for matching

Outputs:
  - covered: .http endpoints that DO match a router
  - uncovered_routers: router endpoints WITHOUT any .http scenario
  - orphan_http: .http endpoints that don't match any router (could be Engine API or stale)
  - sub_task breakdown by router file
"""
from __future__ import annotations
import json
import re
from collections import defaultdict
from pathlib import Path

JOB = Path("C:/Users/AidenKim/.claude/jobs/799514b9")


def to_regex(router_path: str) -> re.Pattern:
    """Convert `/api/v1/decks/{}/cards/{}` → regex matching any segment values."""
    # split by `{}`, escape literals, then join with `[^/]+`
    parts = router_path.split("{}")
    escaped = [re.escape(p) for p in parts]
    pattern = r"[^/]*".join(escaped)  # allow empty (e.g., `//`)
    return re.compile(f"^{pattern}$")


def main() -> None:
    auth_extra_prefix = "/api/v1"  # main.py: app.include_router(auth_router, prefix="/api/v1")

    http_rows = json.loads((JOB / "http_endpoints.json").read_text(encoding="utf-8"))
    router_rows = json.loads((JOB / "router_endpoints.json").read_text(encoding="utf-8"))

    # Apply auth router's extra prefix
    for r in router_rows:
        if r["file"] == "auth.py":
            r["path_norm"] = auth_extra_prefix + r["path_norm"]

    http_unique = sorted({(r["method"], r["path_norm"]) for r in http_rows})
    router_unique = sorted({(r["method"], r["path_norm"]) for r in router_rows})

    # Build regex registry for routers
    router_regex = []
    for method, path in router_unique:
        router_regex.append((method, path, to_regex(path)))

    # Determine .http coverage
    covered_http: list[tuple[str, str, str]] = []  # (method, http_path, router_pattern)
    orphan_http: list[tuple[str, str]] = []
    for method, path in http_unique:
        match = None
        for r_method, r_path, r_re in router_regex:
            if method != r_method:
                continue
            if r_re.match(path):
                match = r_path
                break
        if match:
            covered_http.append((method, path, match))
        else:
            orphan_http.append((method, path))

    # Determine router coverage (which router endpoints have ANY .http call)
    covered_router_set = {(m, mp) for (m, _hp, mp) in covered_http}
    uncovered_routers: list[tuple[str, str, str]] = []  # (method, path, file)
    # Map router → file
    router_to_file = defaultdict(list)
    for r in router_rows:
        router_to_file[(r["method"], r["path_norm"])].append(r["file"])
    for method, path in router_unique:
        if (method, path) not in covered_router_set:
            files = sorted(set(router_to_file[(method, path)]))
            uncovered_routers.append((method, path, ",".join(files)))

    # ── Output ──
    out = {
        "stats": {
            "http_total_calls": len(http_rows),
            "http_unique_endpoints": len(http_unique),
            "router_unique_endpoints": len(router_unique),
            "covered_http_count": len(covered_http),
            "orphan_http_count": len(orphan_http),
            "covered_router_count": len(covered_router_set),
            "uncovered_router_count": len(uncovered_routers),
            "coverage_pct": round(100 * len(covered_router_set) / max(1, len(router_unique)), 1),
        },
        "covered_http": [
            {"method": m, "http_path": hp, "router_pattern": mp}
            for (m, hp, mp) in covered_http
        ],
        "orphan_http": [
            {"method": m, "path": p} for (m, p) in orphan_http
        ],
        "uncovered_routers": [
            {"method": m, "path": p, "file": f} for (m, p, f) in uncovered_routers
        ],
    }

    # By-file breakdown for uncovered routers
    by_file: dict[str, int] = defaultdict(int)
    for m, p, f in uncovered_routers:
        by_file[f] += 1
    out["uncovered_by_file"] = dict(sorted(by_file.items(), key=lambda kv: -kv[1]))

    print(json.dumps(out, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
