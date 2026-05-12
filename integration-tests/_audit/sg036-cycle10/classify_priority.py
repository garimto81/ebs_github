"""Classify 110 uncovered routers into priority sub-tasks."""
from __future__ import annotations
import json
from collections import defaultdict
from pathlib import Path

JOB = Path("C:/Users/AidenKim/.claude/jobs/21027efb")

d = json.loads((JOB / "mismatch_result.json").read_text(encoding="utf-8"))
uncovered = d["uncovered_routers"]

# Priority rules — first match wins
PRIORITY_RULES = [
    # (priority, label, predicate)
    ("P1-core-list", "기본 CRUD list (사용자 화면)",
        lambda r: r["method"] == "GET" and r["path"] in {
            "/api/v1/series", "/api/v1/events", "/api/v1/flights",
            "/api/v1/competitions", "/api/v1/tables", "/api/v1/players",
            "/api/v1/users", "/api/v1/blind-structures",
            "/api/v1/payout-structures",
        }),
    ("P1-core-read", "기본 CRUD read-by-id",
        lambda r: r["method"] == "GET" and r["path"].endswith("/{}") and
        any(x in r["path"] for x in ["/series/", "/events/", "/flights/", "/competitions/",
                                       "/tables/", "/players/", "/users/", "/decks/",
                                       "/hands/", "/blind-structures/", "/payout-structures/",
                                       "/configs/"]) and
        r["path"].count("{}") == 1),
    ("P1-core-create", "기본 CRUD create",
        lambda r: r["method"] == "POST" and r["path"] in {
            "/api/v1/series", "/api/v1/events", "/api/v1/competitions",
            "/api/v1/users", "/api/v1/players", "/api/v1/flights",
            "/api/v1/payout-structures",
        }),
    ("P1-core-update", "기본 CRUD update/delete",
        lambda r: r["method"] in {"PUT", "PATCH", "DELETE"} and r["path"].endswith("/{}") and
        any(x in r["path"] for x in ["/series/", "/events/", "/flights/", "/competitions/",
                                       "/tables/", "/players/", "/users/", "/decks/",
                                       "/blind-structures/", "/payout-structures/", "/skins/",
                                       "/configs/"])),

    ("P2-auth-2fa", "auth 2FA + password reset",
        lambda r: "/auth/" in r["path"]),
    ("P2-audit", "audit-events + audit-logs",
        lambda r: "/audit-" in r["path"]),
    ("P2-settings", "settings KV",
        lambda r: r["path"].startswith("/api/v1/settings")),

    ("P3-reports", "reports dashboard 6종",
        lambda r: r["path"].startswith("/api/v1/reports")),
    ("P3-sync", "sync (WSOP LIVE + mock)",
        lambda r: r["path"].startswith("/api/v1/sync")),

    ("P4-clock", "flights clock 액션 (start/pause/resume/restart)",
        lambda r: "/clock" in r["path"] and "/flights/" in r["path"]),
    ("P4-blind-levels", "blind-structures levels 서브",
        lambda r: "/levels/{}" in r["path"]),
    ("P4-seats", "tables seats CRUD",
        lambda r: "/seats" in r["path"]),
    ("P4-flight-tables", "flights tables 서브",
        lambda r: "/flights/{}/tables" in r["path"] or "/flights/{}/blind-structure" in r["path"]),
    ("P4-table-status", "tables status/events",
        lambda r: r["path"].startswith("/api/v1/tables/{}/")),
    ("P4-hand-detail", "hand actions/players 서브",
        lambda r: "/hands/{}/" in r["path"]),
    ("P4-skin-action", "skin upload/activate/deactivate",
        lambda r: "/skins/" in r["path"] and any(s in r["path"] for s in ["/upload", "/activate", "/deactivate"])),
    ("P4-player-search", "player search",
        lambda r: "/players/search" in r["path"]),
    ("P4-flight-cancel-complete", "flight cancel/complete",
        lambda r: "/flights/{}/cancel" in r["path"] or "/flights/{}/complete" in r["path"]),
    ("P4-series-events", "series events 서브",
        lambda r: "/series/{}/events" in r["path"]),
    ("P4-event-flights", "events {}/flights",
        lambda r: "/events/{}/flights" in r["path"]),
    ("P4-user-force-logout", "users force-logout",
        lambda r: "/users/{}/force-logout" in r["path"]),
    ("P4-flight-clock-get", "flights clock state get",
        lambda r: "/flights/{}/clock" in r["path"] and r["method"] == "GET"),
    ("P4-event-flights-list", "events flights list",
        lambda r: "/flights/{}/levels" in r["path"]),
]


def classify(row: dict) -> tuple[str, str]:
    for prio, label, pred in PRIORITY_RULES:
        try:
            if pred(row):
                return prio, label
        except Exception:
            continue
    return "P5-misc", "기타 (분류 누락)"


by_prio = defaultdict(list)
for r in uncovered:
    prio, label = classify(r)
    by_prio[(prio, label)].append(r)

print("=== Priority breakdown ===\n")
total = 0
for (prio, label), items in sorted(by_prio.items()):
    print(f"{prio:25s} {label:50s} {len(items):3d}")
    total += len(items)
print(f"\nTotal: {total}")

print("\n\n=== Detail by priority ===")
for (prio, label), items in sorted(by_prio.items()):
    print(f"\n--- {prio} {label} ({len(items)}) ---")
    for r in sorted(items, key=lambda x: (x["path"], x["method"])):
        print(f"  {r['method']:7s} {r['path']:55s} {r['file']}")

# Save JSON
out = {
    "total_uncovered": len(uncovered),
    "by_priority": {
        f"{prio}|{label}": [r for r in items]
        for (prio, label), items in sorted(by_prio.items())
    },
}
(JOB / "priority_classified.json").write_text(json.dumps(out, ensure_ascii=False, indent=2), encoding="utf-8")
