---
title: Production Deployment (Auth domain)
owner: team2
tier: internal
last-updated: 2026-04-28
related-arch: ../../2.5 Shared/Authentication/Distributed_Architecture.md (M2)
related-runbook: ../../2.5 Shared/Authentication/Troubleshooting_Runbook.md (M6)
related-quickstart: Quickstart_Local_Cluster.md (M5)
related-plan: ~/.claude/plans/role-and-objective-reactive-canyon.md (M8)
confluence-page-id: 3833626839
confluence-parent-id: 3811770578
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3833626839/Deployment
---

# Production Deployment — Authentication Domain (M8)

production 환경의 EBS BO 인증 도메인 배포 가이드. M2 의 production 토폴로지를
실제 운영 환경 (k8s/Helm 또는 docker-compose + supervisor) 으로 옮길 때의
구체 절차 + 체크리스트 + 롤백 시나리오.

> **본 문서 범위 외 (별 SOP)**:
> - Terraform 인프라 코드 (네트워크, IAM, K8s cluster)
> - 모니터링 스택 (Datadog/Prometheus 설정 자체)
> - 백업/DR 정책 (PG, Redis)

## 1. 배포 사전 점검 (Pre-Deploy Checklist)

### 1.1 Drift Gate 통과

```bash
cd ebs/
python tools/spec_drift_check.py --auth --schema --api
# Expected: 0 violations across all 3 contracts
```

→ 위반 시 배포 중단. M9 Drift Gate 가 PR 단계에서 차단했어야 정상.

### 1.2 회귀 테스트 baseline

```bash
cd team2-backend/
python -m pytest tests/ -v
# Expected: ≥255 PASS (M1 후 247 + M1 추가 8 = 255 내외)
```

### 1.3 Secrets 검증

| Secret | 출처 | 검증 |
|--------|------|------|
| `JWT_SECRET` | k8s Secret / vault | `wc -c` ≥ 64 (256 bits) |
| `DATABASE_URL` | k8s Secret | `psql ... -c "SELECT 1"` 연결 성공 |
| `REDIS_URL` | k8s Secret | `redis-cli -u $REDIS_URL ping` |
| `WSOP_OAUTH_CLIENT_ID/SECRET` | vault | adapters/wsop_auth.py 의 health check 성공 |

### 1.4 Migration 적용 확인

```bash
# 새 migration 이 production 에 미적용 시 startup 실패
python -m alembic current  # 현재 revision
python -m alembic heads    # 목표 revision
# current = heads 이어야 정상
```

## 2. Production Topology 적용

### 2.1 Redis Cluster 구성

**최소 사양**: 3 master + 3 replica (각 master 별 replica 1개). 메모리 4GB+/노드.

```bash
# 예: AWS ElastiCache Redis Cluster mode
aws elasticache create-replication-group \
  --replication-group-id ebs-redis-cluster \
  --num-node-groups 3 \
  --replicas-per-node-group 1 \
  --cache-node-type cache.r6g.large \
  --engine redis \
  --engine-version 7.0 \
  --cluster-mode-enabled
```

**키 분포**:
- `blacklist:jti:{jti}` — hash slot 자동 분산 (16384 slots)
- `rate_limit:{cat}:{key}` — 동일
- `oauth:wsop_live:token` — single key, 단일 slot
- `lock:oauth:wsop_live:refresh` — 동일

**검증**:
```bash
redis-cli -c -h <cluster-endpoint> CLUSTER INFO
# cluster_state:ok
# cluster_slots_ok:16384
```

### 2.2 PostgreSQL primary/replica

**최소 사양**: primary 1 + read replica 1 (streaming replication). vCPU 4+, RAM 16GB+/노드.

**복제 지연 모니터링**:
```sql
-- on primary
SELECT * FROM pg_stat_replication;

-- on replica
SELECT EXTRACT(EPOCH FROM (now() - pg_last_xact_replay_timestamp())) AS lag_seconds;
-- 정상: < 1s
```

**ADR 준수**: 인증 mutation 은 모두 primary (M2 §2 Authority Map).

### 2.3 BO Worker 배포 (k8s 예)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ebs-bo
spec:
  replicas: 4  # production 시작값. autoscaling HPA 추가 권장
  selector:
    matchLabels:
      app: ebs-bo
  template:
    metadata:
      labels:
        app: ebs-bo
    spec:
      containers:
        - name: bo
          image: ebs-bo:{{tag}}
          ports:
            - containerPort: 8000
          env:
            - name: AUTH_PROFILE
              value: live
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: ebs-secrets
                  key: database-url
            - name: REDIS_URL
              valueFrom:
                secretKeyRef:
                  name: ebs-secrets
                  key: redis-url
            - name: JWT_SECRET
              valueFrom:
                secretKeyRef:
                  name: ebs-secrets
                  key: jwt-secret
          readinessProbe:
            httpGet:
              path: /health
              port: 8000
            initialDelaySeconds: 10
            periodSeconds: 5
          livenessProbe:
            httpGet:
              path: /health
              port: 8000
            initialDelaySeconds: 30
            periodSeconds: 30
          resources:
            requests:
              cpu: 500m
              memory: 512Mi
            limits:
              cpu: 1000m
              memory: 1Gi
---
apiVersion: v1
kind: Service
metadata:
  name: ebs-bo-svc
spec:
  type: LoadBalancer
  selector:
    app: ebs-bo
  ports:
    - port: 80
      targetPort: 8000
  sessionAffinity: None  # M2 ADR-2: sticky 미사용
```

### 2.4 Redis backend 활성화 (Blacklist)

`src/main.py` startup event 에 추가 필요:

```python
import redis.asyncio as redis
from src.app.config import settings
from src.security.blacklist import configure_redis_backend

@app.on_event("startup")
async def init_blacklist_backend():
    if settings.redis_url and settings.auth_profile in ("staging", "prod", "live"):
        client = redis.from_url(settings.redis_url, decode_responses=True)
        configure_redis_backend(client)
        logger.info("Blacklist Redis backend activated")
    else:
        logger.warning("Blacklist using in-memory backend (per-worker only)")
```

> 본 코드는 PR (M5 후속 또는 M8) 에서 추가. 현재 코드는 in-memory default.

## 3. JWT 서명 키 회전 절차

### 3.1 정상 회전 (90일 주기 권장)

**전제**: `kid` (key id) 클레임 도입 후 양방향 키 운영. 현재 코드는 단일 키.

**Phase A — 양방향 키 도입 PR (별도)**:
1. JWT 발행 시 `kid: "v2"` 클레임 추가
2. JWT decode 시 `kid` 에 따라 keymap 에서 키 조회
3. keymap = `{"v1": OLD_SECRET, "v2": NEW_SECRET}` (env-based)
4. 새 발급은 v2, 기존 v1 토큰은 만료까지 검증만 허용

**Phase B — 회전 실행**:
```bash
# 1. 새 키 생성
NEW_KEY=$(openssl rand -hex 32)
kubectl create secret generic ebs-secrets-new \
  --from-literal=jwt-secret-v2=$NEW_KEY

# 2. ConfigMap 또는 Secret 의 keymap 갱신 (v1 + v2 양쪽 포함)
# 3. Rolling restart
kubectl rollout restart deployment/ebs-bo

# 4. 모니터링: 신규 발급 토큰의 kid 분포 (v2 비율 100% 도달 확인)

# 5. v1 토큰 자연 만료 대기 (live 12h, refresh 48h → 최대 48h 후)

# 6. v1 키 keymap 에서 제거 + 다시 rolling restart
```

### 3.2 비상 회전 (키 유출 의심)

**즉시**:
1. 새 키 생성 + Secret 갱신
2. 모든 worker rolling restart (옛 키 즉시 무효화)
3. 모든 사용자 알림: "보안 사고로 재로그인 필요"
4. Frontend 가 401 받는 즉시 로그인 화면 redirect

> 이 경우 모든 활성 user 가 재로그인 → 사용자 영향 큼. **사고 보고 + post-mortem 필수**.

### 3.3 Worker 별 키 동기화 검증

```bash
for pod in $(kubectl get pods -l app=ebs-bo -o name); do
  kubectl exec $pod -- python -c "
from src.app.config import settings
import hashlib
print(hashlib.sha256(settings.jwt_secret.encode()).hexdigest()[:8])
  "
done
# 모든 worker 가 동일 hash 출력해야 정상
```

## 4. Refresh Token Rotation 활성화 (M8 신규)

M2 §3.1 의 PG `SELECT FOR UPDATE` 패턴을 production refresh 에 도입:

```python
# src/services/auth_service.py — 수정 (별 PR)
async def refresh_session_with_rotation(refresh_token: str, db: AsyncSession):
    async with db.begin():
        result = await db.execute(
            select(UserSession)
            .where(UserSession.refresh_token == refresh_token)
            .with_for_update()
        )
        row = result.scalar_one_or_none()
        if row is None:
            raise InvalidRefreshTokenError()
        new_pair = issue_pair(row.user_id, row.device_id)
        row.refresh_token = new_pair.refresh
        row.access_token = new_pair.access
        return new_pair
```

**활성화 전제**:
- PostgreSQL 사용 (SQLite `FOR UPDATE` 무시)
- async DB driver (asyncpg) 권장 (성능)
- 회귀 테스트 `test_refresh_race.py` PASS (asyncio.gather 100x → 1 success)

## 5. 모니터링 SLO + 알람

| Metric | Threshold | Action |
|--------|----------|--------|
| `auth.login.latency.p99` | > 500ms (5분 평균) | P3 alarm |
| `auth.me.latency.p99` | > 100ms | P3 |
| `auth.lockout.triggered` per minute | > 5/min | P2 — brute force 의심 |
| `auth.refresh.race_detected` per minute | > 5/min | P2 — rotation 락 미동작 |
| `oauth.wsop_live.refresh_count` per hour | > 10 | P2 — SETNX 락 미동작 |
| `redis.ping.latency.p99` | > 100ms | P2 — Redis 부하 또는 네트워크 이슈 |
| `pg.replica.lag_seconds` | > 5s | P3 — replica lag (RBAC 판정 stale 위험) |
| `bo.worker.health` | 1+ unhealthy 30s+ | P3 — k8s 자동 restart 검증 |

## 6. 배포 절차 (Step-by-step)

### Production Deploy Day

```bash
# 1. Pre-deploy Drift Gate
cd ebs/ && python tools/spec_drift_check.py --auth
# PASS 확인 후 진행

# 2. 회귀 테스트 (CI 가 자동 처리하지만 확인)
cd team2-backend/ && python -m pytest tests/ -v
# Baseline ≥ 255 PASS

# 3. Migration dry-run (staging 에서 먼저)
python -m alembic upgrade head --sql > /tmp/migration.sql
# /tmp/migration.sql 검토

# 4. Migration 적용 (production)
python -m alembic upgrade head

# 5. Image build + push
docker build -t ebs-bo:$(git rev-parse --short HEAD) .
docker push registry/ebs-bo:$(git rev-parse --short HEAD)

# 6. Helm/k8s deploy (rolling)
helm upgrade ebs-bo ./charts/ebs-bo \
  --set image.tag=$(git rev-parse --short HEAD) \
  --wait --timeout 5m

# 7. 검증 — Live 환경 health
curl https://api.ebs.example.com/health
curl https://api.ebs.example.com/auth/me -H "Authorization: Bearer ..."  # smoke test

# 8. 모니터링 — SLO dashboard 확인 (latency, error rate)
```

## 7. 롤백 절차

### 7.1 코드 롤백 (k8s)

```bash
kubectl rollout undo deployment/ebs-bo
# 또는 특정 revision
kubectl rollout undo deployment/ebs-bo --to-revision=N
```

### 7.2 Migration 롤백

> ⚠️ **하지 말 것**: PostgreSQL DDL 롤백 (DROP COLUMN 등) 은 데이터 손실. Forward fix 권장.

대안:
- 이전 코드 버전이 새 schema 에서도 동작하도록 backward-compat 유지 (권장)
- 새 schema 가 옛 코드와 호환 안 되면 hotfix 코드 PR 가 더 빠름

### 7.3 JWT 키 롤백

키 회전 직후 사고 발생 시:
```bash
# Secret 의 jwt-secret 을 옛 값으로 되돌림
kubectl edit secret ebs-secrets
kubectl rollout restart deployment/ebs-bo
```

## 8. 운영 SLO (M2 §7 정합)

| Item | Target |
|------|:------:|
| Login p99 | < 500ms |
| /auth/me p99 | < 100ms |
| Blacklist propagation cross-worker | < 50ms |
| Refresh rotation 충돌율 | < 0.01% |
| Failover RTO (Redis Cluster) | < 15s |
| Failover RTO (PostgreSQL primary) | < 60s |
| 동시 활성 세션 수 (target) | 5,000 (10K rows) |
| 가용성 (live) | 99.9% (월 43분 downtime 허용) |

## 9. 후속 작업 (별 PR / 별 plan 범위)

- `kid` 키 회전 시스템 도입 (양방향 키 검증)
- Refresh rotation 활성화 (PG FOR UPDATE)
- Redis backend startup 활성화 코드 (`src/main.py`)
- X-Device-Id 헤더 router 통합 + max session enforcement
- Admin 강등 시 user 의 모든 jti 자동 revoke (Pub/Sub publish)
- Rate limit Redis 통합 (per-worker → 분산)
- Sentry/Datadog SDK 통합 (현재 sourcemap 만 구성)

## 10. 참조

- Architecture: `../../2.5 Shared/Authentication/Distributed_Architecture.md` (M2)
- Sequences: `../../2.5 Shared/Authentication/Token_Lifecycle_Sequences.md` (M3)
- Concurrency: `Concurrency_and_Race_Conditions.md` (M4)
- Quickstart (개발): `Quickstart_Local_Cluster.md` (M5)
- Runbook: `../../2.5 Shared/Authentication/Troubleshooting_Runbook.md` (M6)
- BS-01 정책 SSOT: `../../2.5 Shared/Authentication.md`
- M1 IMPL 추적: `../Engineering/M1_Session_Drift_Audit_2026-04-28.md`
