#!/bin/sh
# V9.5 P16 — BO container entrypoint
# Seed admin idempotent (already exists → no-op) + run uvicorn

set -e

# V9.5 P17: DB schema 정합 — src.main 전체 import 로 모든 model metadata 등록 후
# SQLModel.create_all() 호출. seed_admin.py 단독 호출 시 partial schema 생성
# 문제 (P15 발견) 를 회피.
if [ "${EBS_INIT_DB_ON_START:-1}" = "1" ]; then
  echo "[entrypoint] initializing DB schema (SQLModel.create_all + _seed_admin)..."
  python -c "
import src.main  # 모든 model 등록 (router → service → model chain)
from src.app.database import init_db
init_db()
print('[entrypoint] init_db done — all 21 tables, default admin@ebs.local seeded')
" || echo "[entrypoint] init_db failed (continuing): $?"
fi

# Run alembic migrations (idempotent — production 용, dev 는 SQLModel.create_all 가 충분)
if [ "${EBS_MIGRATE_ON_START:-0}" = "1" ]; then
  echo "[entrypoint] running alembic upgrade head..."
  alembic upgrade head || echo "[entrypoint] alembic failed (continuing): $?"
fi

# Seed admin force-update (E2E test 환경 — password 변경 필요 시)
if [ "${EBS_SEED_FORCE:-0}" = "1" ]; then
  echo "[entrypoint] force-updating admin password..."
  python tools/seed_admin.py \
    --email "${EBS_SEED_ADMIN_EMAIL:-admin@ebs.local}" \
    --password "${EBS_SEED_ADMIN_PASSWORD:-admin1234!}" \
    --display-name "${EBS_SEED_ADMIN_NAME:-EBS Admin}" \
    --role admin \
    --force || echo "[entrypoint] seed force failed (continuing): $?"
fi

# Hand off to CMD (uvicorn)
exec "$@"
