---
title: Concurrency and Race Conditions (Auth domain)
owner: team2
tier: internal
last-updated: 2026-04-28
related-arch: ../../2.5 Shared/Authentication/Distributed_Architecture.md (M2)
related-seq: ../../2.5 Shared/Authentication/Token_Lifecycle_Sequences.md (M3)
related-plan: ~/.claude/plans/role-and-objective-reactive-canyon.md (M4)
confluence-page-id: 3818816121
confluence-parent-id: 3811770578
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818816121/EBS+Concurrency+and+Race+Conditions+Auth+domain
---

# Concurrency and Race Conditions — Auth Domain (M4)

M2 Distributed_Architecture.md §3 Decision Matrix 의 각 row 를 **실제 발생 조건 + 재현
코드 + 해소 패턴 + 모니터링 메트릭** 까지 풀어 설명. team2 backend 개발자가 새 endpoint
또는 background worker 작성 시 reference.

## 6 Race 시나리오 카탈로그

| # | 시나리오 | 발생 빈도 | 영향 | 현재 상태 |
|:-:|---------|:--------:|------|----------|
| R1 | Failed login 카운터 동시 증가 | 흔함 (brute force 시) | 카운터 부정확 → 잠금 임계값 N배 부풀려짐 | ✅ atomic UPDATE 로 해소 |
| R2 | Refresh token rotation race | 드묾 (refresh 가 만료 직전) | 한 사용자 무작위 401 + 재로그인 | 🟡 rotation 미구현 → race 미발생. M8 도입 시 PG FOR UPDATE |
| R3 | Same-device 동시 로그인 | 흔함 (브라우저 multi-tab) | UNIQUE(user_id, device_id) 충돌 → IntegrityError | 🟡 app-level UPSERT catch 필요 (PR 8 후속) |
| R4 | OAuth client_credentials 만료 직전 동시 fetch | 매 1h (token TTL) | Vendor API rate limit 도달 + cost 증가 | 🟡 Redis SETNX 락 미구현. M5 시점 |
| R5 | Blacklist add ↔ is_revoked 동시 | 매 logout 시 | revoked 토큰이 잠시 valid 보일 수 있음 (< 50ms) | ✅ Redis 단일 명령 atomic, 영향 < user-visible |
| R6 | Rate limit 카운터 분산 (per-worker) | N worker 마다 | 한도 N배 부풀려짐 → DDoS 보호 약화 | 🟡 Redis INCR 통합 미구현. M8 시점 |

---

## R1 — Failed Login Counter

### 발생 조건

```
2 worker 가 동시에 같은 user 의 잘못된 비밀번호 로그인 처리
W1: SELECT failed_login_count → 9
W2: SELECT failed_login_count → 9  (동시 read)
W1: UPDATE failed_login_count = 9 + 1 = 10
W2: UPDATE failed_login_count = 9 + 1 = 10  (잃어버린 update)
```

→ 실제는 11 회 실패였지만 카운터는 10 → 11회째 시도가 통과 가능 (정책: 10회 → 잠금).

### 해소 (atomic UPDATE)

```python
# auth_service.py — 이미 SQLModel ORM 의 UPDATE statement 가 atomic 보장
db.exec(
    update(User)
    .where(User.user_id == user.user_id)
    .values(failed_login_count=User.failed_login_count + 1)
)
db.commit()
```

또는 PostgreSQL `RETURNING` 절로 새 카운트 즉시 확인:
```sql
UPDATE users SET failed_login_count = failed_login_count + 1
WHERE user_id = :uid
RETURNING failed_login_count;
```

### 모니터링

- metric `auth.lockout.triggered{user_id, count}` — 잠금 trigger 시 emit
- alarm: 동일 user 의 lockout 이 10초 내 2회+ 발생 → race 의심

---

## R2 — Refresh Token Rotation (M8 Reserved)

### 발생 조건 (rotation 도입 시)

Seq 2 (Token_Lifecycle_Sequences §Seq 2) 참조. 현재 EBS 는 rotation 미구현이므로 race 자체 미발생.

### 해소 패턴 (M8 활성화 예정)

```python
# 새 service: refresh_session_with_rotation
async def refresh_session_with_rotation(refresh_token: str, db: AsyncSession):
    async with db.begin():  # transaction
        result = await db.execute(
            select(UserSession)
            .where(UserSession.refresh_token == refresh_token)
            .with_for_update()  # SELECT ... FOR UPDATE
        )
        row = result.scalar_one_or_none()
        if row is None:
            raise InvalidRefreshTokenError()  # 이미 rotated

        new_pair = issue_pair(row.user_id, row.device_id)
        row.refresh_token = new_pair.refresh
        row.access_token = new_pair.access
        return new_pair
    # commit on exit; row lock released
```

### 모니터링

- metric `auth.refresh.race_detected` — 두 번째 호출이 401 받을 때 emit
- 통상 < 0.01% 이내 — 그 이상이면 rotation interval 재조정 필요

---

## R3 — Same-Device Concurrent Login

### 발생 조건

```
User 가 브라우저 2 탭에서 동시 로그인 (둘 다 device_id="default")
W1: SELECT user_sessions WHERE user_id=X AND device_id="default" → None
W2: SELECT user_sessions WHERE user_id=X AND device_id="default" → None
W1: INSERT user_sessions (user_id=X, device_id="default", access=A)
W2: INSERT user_sessions (user_id=X, device_id="default", access=B)
   ↓ UNIQUE(user_id, device_id) 위반 → IntegrityError
W2 응답: 500 Internal Server Error
```

### 해소 (App-level UPSERT catch)

```python
# auth_service.py::create_session — 후속 PR 에서 강화
def create_session(user, db, device_id="default"):
    for attempt in range(2):  # 1 retry on race
        try:
            row = db.exec(
                select(UserSession).where(
                    UserSession.user_id == user.user_id,
                    UserSession.device_id == device_id,
                )
            ).first()
            if row is None:
                row = UserSession(user_id=user.user_id, device_id=device_id)
            row.access_token = ...
            db.add(row)
            db.commit()
            return ...
        except IntegrityError:
            db.rollback()
            if attempt == 0:
                continue  # 다른 worker 가 INSERT 함 → 재조회 후 UPDATE
            raise
```

> **현재 상태**: M1 Item 3 (PR #43) 이 schema 변경 완료. App-level UPSERT race 핸들링은 PR 8 (M5 Quickstart 와 함께) 또는 별 PR.

### 모니터링

- metric `auth.session.upsert_retry` — retry 발생 빈도

---

## R4 — OAuth Client Credentials Refresh Race

### 발생 조건

`adapters/wsop_auth.py` 가 token expires 30s 전 사전 refresh. N worker 가 동시 트리거.

### 해소 (Redis SETNX 락)

Distributed_Architecture.md §3.2 Redis SETNX 패턴 참조. asyncio.Lock 은 per-process 만 보호 → multi-worker 환경 부족.

```python
LOCK_KEY = "lock:oauth:wsop_live:refresh"
LOCK_TTL = 30  # vendor API timeout 보다 약간 김

if await redis.set(LOCK_KEY, worker_id, nx=True, ex=LOCK_TTL):
    try:
        new_token = await fetch_from_vendor()
        await redis.setex("oauth:wsop_live:token", new_token.expires_in - 30, new_token.value)
    finally:
        if await redis.get(LOCK_KEY) == worker_id:
            await redis.delete(LOCK_KEY)
else:
    # 다른 worker 가 fetch 중 → 잠시 대기 후 cache 재조회
    await asyncio.sleep(0.1)
    return await redis.get("oauth:wsop_live:token")
```

### 모니터링

- metric `oauth.wsop_live.refresh_count` per minute — 정상 1회/h 이내. 초과 시 락 미작동
- metric `oauth.wsop_live.lock_contention` — SETNX 실패 빈도

---

## R5 — Blacklist Add ↔ Check (M1 Item 2 OK)

### 시나리오

```
W1: User A logout → SET blacklist:jti:X 1 EX 3600
W2: User A 의 동일 access token 으로 GET /auth/me
    → EXISTS blacklist:jti:X
    → 만약 W1 의 SET 가 W2 의 EXISTS 보다 1ms 늦으면 → False (잠시 valid)
```

### 분석

- Redis 단일 명령은 atomic
- SET/EXISTS 명령 사이의 ms 단위 race 는 user-visible 영향 없음
- jti 가 logout 후 < 50ms 내 valid 인 경우 = 가능하지만 보안 위협 미세

→ **해소 불요**. M1 Item 2 (PR #42) 구현으로 충분.

---

## R6 — Rate Limit Counter Distribution

### 발생 조건

```
per-worker in-memory counter: 5회/분 한도
W1 카운트: 5
W2 카운트: 5
W3 카운트: 5
→ 총 15회/분 통과 → 한도 무력화
```

### 해소 (Redis INCR + EXPIRE)

```python
async def check_rate_limit(category: str, key: str, limit: int, window_s: int) -> bool:
    redis_key = f"rate_limit:{category}:{key}"
    count = await redis.incr(redis_key)
    if count == 1:
        # 첫 호출 — TTL 설정
        await redis.expire(redis_key, window_s)
    return count <= limit
```

> 위 INCR + EXPIRE 는 두 명령이지만 race 무해 (TTL 이 약간 늦게 set 돼도 한도 검증은 정확).

### 모니터링

- metric `rate_limit.exceeded{category}` per minute
- alarm: 카테고리별 정책 임계 초과 시

---

## 7. 타임아웃 권장값

| 동작 | 타임아웃 | 이유 |
|------|:-------:|------|
| `redis.set(... ex=...)` 자체 | 1s | Redis local cluster latency 1ms 이내 — timeout 은 fail-open trigger |
| `db.execute()` (read) | 5s | replica latency + connection pool wait |
| `db.execute()` (write with FOR UPDATE) | 10s | row lock contention |
| Vendor API call (OAuth) | 30s | WSOP LIVE timeout 추천 |
| WebSocket idle ping | 30s | client/server alive 검증 |
| Redis SETNX lock TTL | 30s | vendor API timeout + buffer |

---

## 8. 회귀 테스트 가드

| Race | 회귀 테스트 (현재 또는 계획) |
|------|------------------------------|
| R1 | (계획) `test_concurrent_failed_logins.py` — asyncio.gather 20x → 정확히 10번째 실패에서 lock |
| R2 | (M8) `test_refresh_race.py` — 동일 token 100x 동시 → 1건 성공 |
| R3 | `test_concurrent_sessions.py::test_two_devices_create_separate_rows` (PR #43) + 후속 same-device race test |
| R4 | (M5) `test_oauth_lock.py` — fakeredis 로 SETNX 동시 contention 시뮬 |
| R5 | `test_blacklist_propagation.py` (PR #42) — atomic 검증 |
| R6 | (M8) `test_rate_limit_distributed.py` — fakeredis 로 multi-worker 시뮬 |

---

## 9. Anti-patterns (금지)

| Anti-pattern | 이유 |
|--------------|------|
| `asyncio.Lock()` 으로 분산 보호 시도 | per-process 만 보호. multi-worker 무용 |
| `time.sleep()` + 재시도 (no jitter) | thundering herd 위험. exponential backoff + jitter 필요 |
| `db.exec(...).first(); compute; db.add(); commit()` (no FOR UPDATE) | TOCTOU race. 안전 임계 작업은 항상 FOR UPDATE |
| Redis `EXISTS` 후 `SET` | 두 명령 간 race. atomic 한 `SET NX` 또는 `SETEX` 사용 |
| `asyncio.gather(*[fetch_token() for _ in workers])` 같은 fan-out | OAuth refresh race 유발. 락 필수 |

---

## 참조

- Architecture: `../../2.5 Shared/Authentication/Distributed_Architecture.md` (M2)
- Sequences: `../../2.5 Shared/Authentication/Token_Lifecycle_Sequences.md` (M3)
- Quickstart: `Quickstart_Local_Cluster.md` (M5, 후속)
- Runbook: `../../2.5 Shared/Authentication/Troubleshooting_Runbook.md` (M6, 후속)
- Production: `Production_Deployment.md` (M8, 후속)
