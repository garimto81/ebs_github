#!/bin/sh
# V9.5 P16 — BO container entrypoint
# Seed admin idempotent (already exists → no-op) + run uvicorn

set -e

# Run alembic migrations (idempotent — already-applied 시 no-op)
if [ "${EBS_MIGRATE_ON_START:-1}" = "1" ]; then
  echo "[entrypoint] running alembic upgrade head..."
  alembic upgrade head || echo "[entrypoint] alembic failed (continuing): $?"
fi

# Seed admin (idempotent — tools/seed_admin.py 가 already-exists 처리)
if [ "${EBS_SEED_ON_START:-1}" = "1" ]; then
  echo "[entrypoint] seeding admin (idempotent)..."
  python tools/seed_admin.py \
    --email "${EBS_SEED_ADMIN_EMAIL:-admin@ebs.local}" \
    --password "${EBS_SEED_ADMIN_PASSWORD:-admin1234!}" \
    --display-name "${EBS_SEED_ADMIN_NAME:-EBS Admin}" \
    --role admin \
    ${EBS_SEED_FORCE:+--force} || echo "[entrypoint] seed failed (continuing): $?"
fi

# Hand off to CMD (uvicorn)
exec "$@"
