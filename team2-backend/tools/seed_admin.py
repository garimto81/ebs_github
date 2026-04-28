#!/usr/bin/env python3
"""Seed admin user — Quickstart_Local_Cluster.md 의 [5분] 단계용.

다중 인스턴스 환경에서 첫 admin 을 빠르게 생성. SQLite/PostgreSQL 모두 동작
(DATABASE_URL 환경변수 또는 settings 에서 추론).

사용:
  cd team2-backend
  python tools/seed_admin.py --email admin@local --password 'Admin!123' --display-name 'Local Admin'

기본값:
  --email admin@local
  --password Admin!Local123 (production 절대 사용 금지)
  --display-name "Local Admin"
  --role admin

이미 동일 email 존재 시 no-op + 기존 user_id 출력.

관련:
  - BS-01 Authentication.md (정책 SSOT)
  - Quickstart_Local_Cluster.md (M5)
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

# Add team2-backend to sys.path so we can import src.*
TEAM2_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TEAM2_ROOT))

from sqlmodel import Session, create_engine, select  # noqa: E402

from src.app.config import settings  # noqa: E402
from src.models.user import User  # noqa: E402
from src.security.password import hash_password  # noqa: E402


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--email", default="admin@local")
    ap.add_argument("--password", default="Admin!Local123")
    ap.add_argument("--display-name", default="Local Admin")
    ap.add_argument("--role", default="admin", choices=["admin", "operator", "viewer"])
    ap.add_argument(
        "--database-url",
        default=None,
        help="기본은 settings.database_url. 명시 시 override (예: postgresql://...)",
    )
    args = ap.parse_args(argv)

    db_url = args.database_url or settings.database_url
    if not db_url:
        print("ERROR: DATABASE_URL not set. Run init_db.py first or set env var.")
        return 1

    print(f"Connecting to: {db_url.split('@')[-1] if '@' in db_url else db_url}")
    engine = create_engine(db_url)

    with Session(engine) as db:
        existing = db.exec(select(User).where(User.email == args.email)).first()
        if existing:
            print(
                f"User already exists: user_id={existing.user_id} email={existing.email} "
                f"role={existing.role}. No-op."
            )
            return 0

        user = User(
            email=args.email,
            password_hash=hash_password(args.password),
            display_name=args.display_name,
            role=args.role,
            is_active=True,
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    print(f"✓ Created user_id={user.user_id} email={args.email} role={args.role}")
    print(f"  Login: POST /auth/login {{\"email\": \"{args.email}\", \"password\": \"<...>\"}}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
