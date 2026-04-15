#!/usr/bin/env python3
"""Active-edits 레지스트리 garbage collection.

GC_AGE_HOURS(=24) 이상 된 stale claim 파일을 meta/active-edits 브랜치에서 제거.

Usage:
    python tools/active_edits_gc.py            # dry-run
    python tools/active_edits_gc.py --apply    # 실제 정리
"""
from __future__ import annotations

import argparse
import datetime
import json
import sys
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT / ".claude" / "hooks"))

from _registry import (  # noqa: E402
    fetch_registry, CACHE_DIR, GC_AGE_HOURS, _build_and_push,
)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    fetch_registry()
    if not CACHE_DIR.exists():
        print("no cache, nothing to GC")
        return 0

    now = datetime.datetime.now()
    threshold = now - datetime.timedelta(hours=GC_AGE_HOURS)
    stale: list[str] = []
    for f in CACHE_DIR.glob("*.json"):
        try:
            data = json.loads(f.read_text(encoding="utf-8"))
        except Exception:
            stale.append(f.name)
            continue
        hb = data.get("heartbeat_at") or data.get("started_at")
        if not hb:
            stale.append(f.name)
            continue
        try:
            ts = datetime.datetime.fromisoformat(hb)
            if ts < threshold:
                stale.append(f.name)
        except Exception:
            stale.append(f.name)

    print(f"stale claims: {len(stale)}")
    for s in stale:
        print(f"  · {s}")

    if not args.apply:
        print("\n--apply 미지정. 실제 정리하려면 --apply 추가.")
        return 0

    if not stale:
        print("nothing to remove")
        return 0

    ok = _build_and_push([], stale, f"active-edit: gc {len(stale)} stale")
    print(f"push: {'ok' if ok else 'fail'}")
    if ok:
        for s in stale:
            try:
                (CACHE_DIR / s).unlink()
            except Exception:
                pass
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
