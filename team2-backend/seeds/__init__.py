"""Seed modules for team2-backend.

각 seed module 은 idempotent 한 단일 의도 dev/integration seed 를 노출한다.
운영 환경 (`AUTH_PROFILE=live`) 에서는 자동 호출되지 않는다.

| 모듈 | 시드 대상 |
|------|----------|
| `seeds.admin` | dev/integration admin 계정 (admin@ebs.local + admin@ebs.test) |

신규 seed 추가 시 본 모듈에 import 라인 + 표 행 추가.
"""
from __future__ import annotations

from seeds.admin import seed_admins  # noqa: F401
