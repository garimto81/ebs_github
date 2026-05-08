---
title: Quickstart — Local Cluster (Auth domain)
owner: team2
tier: internal
last-updated: 2026-04-28
related-arch: ../../2.5 Shared/Authentication/Distributed_Architecture.md (M2)
related-runbook: ../../2.5 Shared/Authentication/Troubleshooting_Runbook.md (M6)
related-plan: ~/.claude/plans/role-and-objective-reactive-canyon.md (M5)
confluence-page-id: 3818455638
confluence-parent-id: 3811770578
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818455638/EBS+Quickstart+Local+Cluster+Auth+domain
---

# Quickstart — Local Cluster (M5)

**목표**: 신규 입사자가 30분 내에 multi-instance EBS BO + PostgreSQL + Redis 환경을
로컬에 띄우고, M1 Item 2 의 **blacklist propagation** 을 직접 관찰.

> Production 토폴로지 (Redis Cluster 3M+3R, PG primary/replica HA) 는
> `Production_Deployment.md` (M8) 참조. 본 가이드는 **개발/디버깅 용** 단순화 셋업.

## 사전 준비 (5분)

| 도구 | 최소 버전 | 확인 |
|------|:--------:|------|
| Docker Desktop | 4.30+ | `docker --version` |
| docker compose | v2 | `docker compose version` |
| Python | 3.12 | `python --version` |
| curl + jq | any | `curl --version; jq --version` |
| git worktree | 2.40+ | `git worktree --help` |

> **Windows 사용자**: WSL2 기반 Docker Desktop 권장. Native Windows 도 동작하나 일부 healthcheck timing 차이.

## 1단계 — Cluster 기동 (5분)

```bash
cd team2-backend
docker compose -f docker-compose.cluster.yml up -d --build

# healthcheck 60초 대기 (BO 가 PG/Redis healthy 될 때까지)
docker compose -f docker-compose.cluster.yml ps
```

**Expected output** (모두 `healthy`):
```
NAME                       STATUS
ebs-quickstart-pg          Up 30s (healthy)
ebs-quickstart-redis       Up 30s (healthy)
ebs-quickstart-bo-1        Up 20s (healthy)
ebs-quickstart-bo-2        Up 20s (healthy)
```

**노출 포트**:
- 8001 → BO worker A
- 8002 → BO worker B
- 5432 → PostgreSQL
- 6379 → Redis

## 2단계 — DB 스키마 + Admin 시드 (5분)

```bash
# init.sql 실행 (24 테이블 + alembic stamp 0009)
DATABASE_URL=postgresql://ebs:ebs_local_dev@localhost:5432/ebs \
  python tools/init_db.py --force

# admin user 생성
DATABASE_URL=postgresql://ebs:ebs_local_dev@localhost:5432/ebs \
  python tools/seed_admin.py --email admin@local --password 'Admin!Local123'
```

**Expected**:
```
Connecting to: localhost:5432/ebs
✓ Created user_id=1 email=admin@local role=admin
  Login: POST /auth/login {"email": "admin@local", "password": "<...>"}
```

## 3단계 — Login + Token 발급 (5분)

```bash
# Worker A 에서 로그인
TOKEN_A=$(curl -s -X POST http://localhost:8001/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"admin@local","password":"Admin!Local123"}' \
  | jq -r '.data.accessToken')

echo "Worker A 발급 토큰: ${TOKEN_A:0:40}..."

# Worker A 에서 /auth/me 확인
curl -s -H "Authorization: Bearer $TOKEN_A" http://localhost:8001/auth/me | jq '.'

# Worker B 에서도 같은 토큰 검증 (JWT stateless → 어느 worker 든 OK)
curl -s -H "Authorization: Bearer $TOKEN_A" http://localhost:8002/auth/me | jq '.'
```

**Expected**: 양쪽 worker 모두 200 OK + 동일 user info 반환.

## 4단계 — Multi-instance Logout Propagation (5분)

```bash
# Worker A 에서 logout (M1 Item 2: jti 가 Redis blacklist 에 등록됨)
curl -s -X POST http://localhost:8001/auth/logout \
  -H "Authorization: Bearer $TOKEN_A"

# 즉시 Worker B 에서 같은 token 으로 호출 — 401 AUTH_TOKEN_REVOKED 기대
RESPONSE=$(curl -s -w "\n%{http_code}" -H "Authorization: Bearer $TOKEN_A" \
  http://localhost:8002/auth/me)

echo "$RESPONSE"
# Expected:
#   {"detail":"AUTH_TOKEN_REVOKED"}
#   401
```

> ⚠️ 본 단계는 **M5 시점의 cluster 가 Redis blacklist backend 사용 가정**. 현재 코드는
> default in-memory backend 라 worker 간 propagation 안 됨 (각 worker 가 자기 dict 만 봄).
> 진정한 cross-worker propagation 검증은 `configure_redis_backend()` 가 startup 에서
> 호출되도록 변경 필요 (M5 후속 작업 — 별 PR).

**현 상태에서의 동작**:
- 같은 worker (둘 다 Worker A) 호출 시 → 401 AUTH_TOKEN_REVOKED ✓
- 다른 worker (A logout, B 검증) → 200 OK (in-memory backend 의 한계)

## 5단계 — Multi-Device Session 검증 (5분)

```bash
# 동일 user 가 lobby + cc 로 따로 로그인
TOKEN_LOBBY=$(curl -s -X POST http://localhost:8001/auth/login \
  -H 'Content-Type: application/json' \
  -H 'X-Device-Id: lobby' \
  -d '{"email":"admin@local","password":"Admin!Local123"}' \
  | jq -r '.data.accessToken')

TOKEN_CC=$(curl -s -X POST http://localhost:8002/auth/login \
  -H 'Content-Type: application/json' \
  -H 'X-Device-Id: cc' \
  -d '{"email":"admin@local","password":"Admin!Local123"}' \
  | jq -r '.data.accessToken')

# 양 토큰 모두 valid 인지 검증
curl -s -H "Authorization: Bearer $TOKEN_LOBBY" http://localhost:8001/auth/me | jq -r '.email'
curl -s -H "Authorization: Bearer $TOKEN_CC" http://localhost:8002/auth/me | jq -r '.email'

# DB 에서 device_id 별 row 분리 확인
docker exec -it ebs-quickstart-pg psql -U ebs -d ebs -c "
  SELECT user_id, device_id, LEFT(access_token, 20) AS token_prefix, updated_at
  FROM user_sessions
  WHERE user_id = 1
"
```

**Expected**: 2 row, device_id 별 분리 (lobby + cc).

> ⚠️ 현 코드는 X-Device-Id 헤더를 router 에서 읽지 않음 (PR 8 후속 작업). 본 단계는
> service layer (`create_session(user, db, device_id="...")`) 가 device 별 row 분리하는
> 동작을 SQL 로 직접 확인하는 의도. router 통합 시 자동 동작.

## 6단계 — Cleanup (5분)

```bash
# Cluster 종료 + 데이터 영구 삭제
docker compose -f docker-compose.cluster.yml down -v

# 확인
docker compose -f docker-compose.cluster.yml ps  # empty
docker volume ls | grep ebs-quickstart           # empty
```

## 다음 단계

| 학습 목적 | 다음 문서 |
|----------|----------|
| 분산 아키텍처 깊이 이해 | `../../2.5 Shared/Authentication/Distributed_Architecture.md` (M2) |
| 토큰 흐름 시각화 | `../../2.5 Shared/Authentication/Token_Lifecycle_Sequences.md` (M3) |
| Race condition 분석 | `Concurrency_and_Race_Conditions.md` (M4) |
| 사고 발생 시 대응 | `../../2.5 Shared/Authentication/Troubleshooting_Runbook.md` (M6) |
| Production 배포 | `Production_Deployment.md` (M8, 후속) |
| 코드 IMPL 추적 | `../Engineering/M1_Session_Drift_Audit_2026-04-28.md` |

## 트러블슈팅

| 증상 | 해소 |
|------|------|
| `docker compose ps` 에서 BO 가 unhealthy | `docker compose logs bo-1` 확인. 보통 PG 연결 실패 (healthcheck 60s+ 대기) |
| `init_db.py` 가 SQLite 모드로 실행 | `DATABASE_URL` 환경변수 export 했는지 확인 |
| `python tools/seed_admin.py` 가 ImportError | team2-backend 디렉토리에서 실행. `python -m` 대신 직접 호출 |
| Login 응답이 `{"data": null}` | settings.jwt_secret 가 설정 안 됐을 수 있음. compose env 확인 |
| 401 + `AUTH_TOKEN_REVOKED` 가 같은 worker 에서만 | in-memory backend 정상. cross-worker 는 Redis backend 활성화 필요 (PR 후속) |

## 참조

- BS-01 정책 SSOT: `../../2.5 Shared/Authentication.md`
- M1 IMPL 추적: `../Engineering/M1_Session_Drift_Audit_2026-04-28.md`
- Audit plan: `~/.claude/plans/role-and-objective-reactive-canyon.md` M5
