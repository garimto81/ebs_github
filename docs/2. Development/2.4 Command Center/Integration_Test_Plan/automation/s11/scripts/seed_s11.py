"""S-11 seeder stub.

team2 가 실제 seeder 를 구현할 때 이 파일을 참조 (또는 대체):
- fixtures/fixtures.json 의 accounts/events/flights/tables/hands 를 BO 에 insert.
- POST /api/v1/users (admin=1st bootstrap 사용), POST /api/v1/events, POST /api/v1/flights,
  POST /api/v1/tables, hand 는 직접 DB insert (조회전용 API 이므로).

현재는 **structure check only** — 서버 도달 여부만 확인하고 실제 insert 는 수행 안 함.
"""
from __future__ import annotations

import json
import os
import sys
import urllib.request
from pathlib import Path

BACKEND = os.environ.get("BACKEND_HTTP_URL", "http://localhost:8000")
FIXTURES = Path(__file__).resolve().parent.parent / "fixtures" / "fixtures.json"


def main() -> int:
    if not FIXTURES.exists():
        print(f"[seed] fixtures not found: {FIXTURES}", file=sys.stderr)
        return 2

    with FIXTURES.open(encoding="utf-8") as f:
        data = json.load(f)

    print(f"[seed] backend = {BACKEND}")
    print(f"[seed] accounts = {len(data['accounts'])}")
    print(f"[seed] hands_today = {len(data['seed']['hands_today_table_1']) + len(data['seed']['hands_today_table_2'])}")

    try:
        with urllib.request.urlopen(f"{BACKEND}/health", timeout=3) as resp:
            print(f"[seed] /health status = {resp.status}")
    except Exception as exc:  # noqa: BLE001
        print(f"[seed] backend unreachable: {exc}")
        return 1

    print("[seed] stub complete — actual INSERT pending team2 implementation")
    return 0


if __name__ == "__main__":
    sys.exit(main())
