#!/usr/bin/env python3
"""Fresh DB 초기화 — init.sql + alembic stamp head (J1 2026-04-20).

hybrid 운영:
  - init.sql = 테이블 DDL 권위 (24 테이블)
  - alembic migrations = incremental 변경만 (0001~0005)
  - fresh DB 는 init.sql 먼저 실행 후 alembic stamp 로 완료 표시

사용:
  python team2-backend/tools/init_db.py
  python team2-backend/tools/init_db.py --force  (기존 DB 삭제 후 재빌드)

관련:
  - SG-006 decks + SG-003 settings_kv (migration 0005) 는 init.sql 이후 추가
  - alembic upgrade head 는 기존 DB 에만 사용 (fresh 는 stamp head)
"""
from __future__ import annotations

import argparse
import sqlite3
import subprocess
import sys
from pathlib import Path

TEAM2_ROOT = Path(__file__).resolve().parents[1]
DB_PATH = TEAM2_ROOT / "ebs.db"
INIT_SQL = TEAM2_ROOT / "src" / "db" / "init.sql"
ALEMBIC_INI = TEAM2_ROOT / "alembic.ini"


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--force", action="store_true", help="기존 DB 삭제 후 재빌드")
    ap.add_argument("--db", default=str(DB_PATH), help="대상 DB 경로")
    args = ap.parse_args(argv)

    db_path = Path(args.db)

    if db_path.exists():
        if not args.force:
            print(f"DB exists: {db_path}. Use --force to rebuild.", file=sys.stderr)
            return 1
        db_path.unlink()
        print(f"removed {db_path}")

    # Step 1: init.sql
    if not INIT_SQL.exists():
        print(f"init.sql not found: {INIT_SQL}", file=sys.stderr)
        return 2
    conn = sqlite3.connect(str(db_path))
    try:
        script = INIT_SQL.read_text(encoding="utf-8")
        conn.executescript(script)
        conn.commit()
    finally:
        conn.close()

    # Step 2: verify tables
    conn = sqlite3.connect(str(db_path))
    try:
        tables = [r[0] for r in conn.execute(
            "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
        ).fetchall()]
    finally:
        conn.close()
    print(f"init.sql applied — {len(tables)} tables created")

    # Step 3: alembic stamp head (migrations 0001~0005 를 완료 표시)
    # alembic_version 테이블이 없으면 자동 생성됨
    alembic_cmd = [
        sys.executable, "-m", "alembic",
        "-c", str(ALEMBIC_INI),
        "stamp", "head",
    ]
    result = subprocess.run(alembic_cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"alembic stamp failed:\n{result.stderr}", file=sys.stderr)
        # Non-fatal — DB 자체는 init.sql 로 준비 완료됨
        return 3

    print(f"alembic stamp head — migration state synced")
    print(f"\n✓ DB ready: {db_path}")
    print(f"  tables: {len(tables)}")
    print(f"  migrations: stamped to head (0005_decks_settings_kv)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
