"""Dev/integration-tests admin user seed.

이 모듈은 `src/app/database.py:_seed_admin()` 의 thin re-export wrapper 다.
실제 시드 로직은 SSOT 인 `_seed_admin()` 에 위치하고, 본 모듈은 issue #236
의 명세 (team2-backend/seeds/admin.py) 와 entrypoint.sh / CLI 호출용 진입점
역할을 한다.

시드 대상 (`_DEV_SEED_ADMINS`):

  | email             | password           | role  | 용도                              |
  |-------------------|--------------------|-------|-----------------------------------|
  | admin@ebs.local   | admin123           | admin | 기존 dev (backward compat)        |
  | admin@ebs.test    | test-password-1234 | admin | integration-tests `_env.http` 정합 |

KPI (issue #236):
  curl -X POST http://localhost:18001/api/v1/auth/login \
       -H 'Content-Type: application/json' \
       -d '{"username":"admin@ebs.test","password":"test-password-1234"}'
  → 200 OK + access_token

호출 위치:
  1. `src/app/database.py:init_db()` → `_seed_admin()` 자동 호출
     (entrypoint.sh 의 `EBS_INIT_DB_ON_START=1` 기본값으로 컨테이너 기동 시 실행).
  2. CLI: `python -m seeds.admin` (team2-backend 디렉토리에서 직접 실행).

SECURITY:
  `AUTH_PROFILE=live` 환경에서는 자동 skip 된다. Production 에서는 본 seed 가
  실행되지 않으며, admin 계정은 운영 절차 (`tools/seed_admin.py --force`) 로
  명시적 생성한다.
"""
from __future__ import annotations

import sys
from pathlib import Path

# team2-backend root 를 sys.path 에 추가하여 src.* import 가능하게 함.
TEAM2_ROOT = Path(__file__).resolve().parents[1]
if str(TEAM2_ROOT) not in sys.path:
    sys.path.insert(0, str(TEAM2_ROOT))

from src.app.database import _DEV_SEED_ADMINS, _seed_admin, init_db  # noqa: E402


def seed_admins() -> None:
    """Idempotent dev/integration admin seed.

    `init_db()` 가 호출되지 않은 컨텍스트 (예: alembic post-migration hook,
    standalone CLI) 에서 안전하게 호출 가능. AUTH_PROFILE=live 시 자동 skip.
    """
    _seed_admin()


def main(argv: list[str] | None = None) -> int:
    """CLI 진입점.

    Usage:
      cd team2-backend && python -m seeds.admin

    옵션:
      --init-db    DB 스키마 생성 (init_db 전체) 후 시드.
                   첫 기동 또는 sqlite 파일 삭제 후 재구축 시 사용.
    """
    args = argv if argv is not None else sys.argv[1:]
    if "--init-db" in args:
        init_db()
        print("[seeds.admin] init_db() 호출 — 모든 테이블 생성 + admin seed 완료.")
    else:
        seed_admins()
        print(
            "[seeds.admin] dev/integration admin seed 완료. 대상: "
            + ", ".join(email for email, _, _ in _DEV_SEED_ADMINS)
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
