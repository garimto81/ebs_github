---
title: Authentication Troubleshooting Runbook
owner: conductor
tier: contract
last-updated: 2026-04-28
related-arch: Distributed_Architecture.md (M2)
related-seq: Token_Lifecycle_Sequences.md (M3)
related-concurrency: ../../2.2 Backend/Authentication/Concurrency_and_Race_Conditions.md (M4)
related-plan: ~/.claude/plans/role-and-objective-reactive-canyon.md (M6)
---

# Authentication Troubleshooting Runbook (M6)

운영 중 발생하는 인증 도메인 사고에 대한 1차 진단 + 해소 절차. 각 시나리오는
**증상 → 진단 명령 (1~3건) → 해소 절차 → 재발 방지**.

## 6 시나리오 카탈로그

| ID | 증상 | 평균 빈도 | 평균 MTTR |
|:--:|------|:--------:|:--------:|
| T1 | "Refresh 401" — 사용자가 refresh 시 자주 로그아웃됨 | 주 1-3회 | < 10분 |
| T2 | "Login Locked" — 정상 사용자가 잠금 상태 | 월 1-2회 | < 5분 |
| T3 | Redis 다운 → 인증 동작 이상 | 분기 1회 미만 | < 30분 (Sentinel/Cluster), < 2h (단일) |
| T4 | JWT 서명 키 회전 시 모든 user 401 | 연 1-2회 (계획) | 0 (계획) ~ 2h (실수) |
| T5 | "동시 세션 한도 초과" — Lobby + CC + 추가 device | 월 5-10회 | < 1분 |
| T6 | OAuth client_credentials 만료 동시 N worker fetch | 매 1h (token TTL) | 자가 회복 (락 미동작 시 vendor rate limit) |

---

## T1 — "Refresh 401"

### 증상
- 클라이언트에서 access 만료 후 refresh 호출 시 401
- 사용자가 강제 로그아웃 → 다시 로그인 필요
- Sentry/Datadog 에 `AUTH_INVALID_REFRESH` 빈도 증가

### 진단 명령

```bash
# 1. 영향 사용자의 active session 확인 (PostgreSQL)
psql -h pg-primary -U readonly -d ebs -c "
  SELECT user_id, device_id, token_expires_at, updated_at
  FROM user_sessions
  WHERE user_id = <USER_ID>
"

# 2. Redis blacklist 의심 (해당 jti 가 잘못 등록되었는지)
redis-cli -h redis-cluster GET "blacklist:jti:<JTI>"

# 3. 최근 logout 로그 확인
grep "POST /auth/logout" /var/log/ebs/bo.log | tail -20
```

### 분기 진단

| 진단 결과 | 원인 | 해소 |
|----------|------|------|
| user_sessions row 없음 | 이미 logout 됨 | 정상 동작. 사용자는 재로그인 필요 |
| user_sessions row 의 refresh_token 이 client 의 token 과 다름 | rotation race (M2 §3) | M8 PG FOR UPDATE 도입 진행. 임시: client retry |
| token_expires_at 이 과거 | TTL 만료 | 정상. 사용자는 재로그인 |
| Redis blacklist HIT (값 있음) | logout/admin revoke 됨 | 사용자에게 알림 ("관리자가 세션 무효화") |
| jti 없음 + token type mismatch | client 가 access token 을 refresh 자리에 보냄 | client 측 버그. Frontend 디버깅 |

### 재발 방지

- M8 활성화 시 Refresh rotation race 자동 해소
- Frontend 의 401 hook 가 `AUTH_INVALID_REFRESH` 를 silent 로 처리하지 않도록 — 사용자에게 명확한 메시지

---

## T2 — "Login Locked"

### 증상
- 사용자가 정상 비밀번호 입력 시 403 `AUTH_ACCOUNT_LOCKED`
- BS-01 §자동 잠금: 10회 연속 실패 → permanent (Admin unlock 필수)

### 진단 명령

```bash
# 1. 사용자 잠금 상태 확인
psql -c "
  SELECT user_id, email, failed_login_count, locked_until, last_login_at
  FROM users
  WHERE email = '<EMAIL>'
"

# 2. 잠금 trigger 한 audit 이벤트 (최근 실패 패턴 확인)
psql -c "
  SELECT created_at, ip_address, user_agent
  FROM audit_logs
  WHERE actor_id = <USER_ID> AND event_type = 'AUTH_LOGIN_FAILED'
  ORDER BY created_at DESC LIMIT 15
"

# 3. brute force 의심 IP 확인
psql -c "
  SELECT ip_address, COUNT(*) as fails
  FROM audit_logs
  WHERE event_type = 'AUTH_LOGIN_FAILED'
    AND created_at >= NOW() - INTERVAL '1 hour'
  GROUP BY ip_address
  ORDER BY fails DESC LIMIT 10
"
```

### 분기 진단 + 해소

| 진단 결과 | 해소 |
|----------|------|
| `locked_until = '9999-12-31...'` (sentinel) + 본인 실수 (10회 오타) | Admin 수동 unlock: `UPDATE users SET failed_login_count=0, locked_until=NULL WHERE user_id=<UID>` |
| `locked_until = sentinel` + brute force IP 패턴 발견 | unlock 전 IP 차단 (firewall + rate limit IP whitelist 검토). 사용자 알림 + 비밀번호 변경 권유 |
| `locked_until` 이 과거 | 자동 만료된 상태 — 다음 로그인 성공 시 카운터 리셋. 사용자에게 재시도 안내 |
| `failed_login_count >= 10` 인데 `locked_until` 가 NULL | 코드 버그 (drift) — `tools/spec_drift_check.py --auth` 실행하여 Rule 1/1b 확인 |

### 재발 방지

- M5 Quickstart 의 admin 운영 가이드에 "잠금 해제 절차" 추가
- Admin BO UI 에 "사용자 잠금 해제" 버튼 (별 PR)

---

## T3 — Redis 다운

### 증상
- 인증 endpoint latency 급증 (timeout)
- blacklist 검증 fail-open → revoked 토큰 잠시 valid (보안 윈도우)
- rate limit 검증 fail-open → 한도 초과 트래픽 통과

### 진단 명령

```bash
# 1. Redis cluster 상태 (Sentinel)
redis-cli -h redis-sentinel -p 26379 SENTINEL master ebs-redis

# 2. Redis 직접 PING (각 노드)
redis-cli -h redis-1 PING  # 응답: PONG (정상) / 연결실패 (다운)
redis-cli -h redis-2 PING
redis-cli -h redis-3 PING

# 3. BO worker 의 Redis client 에러 로그
grep -E "(Connection.*refused|Redis.*timeout|TimeoutError)" /var/log/ebs/bo.log | tail -20
```

### 해소

| 단계 | 액션 |
|:--:|------|
| 1 | Sentinel/Cluster 가 자동 failover 진행 중인지 확인. promote 완료 시 (~10s) 자연 회복 |
| 2 | 단일 Redis (Sentinel/Cluster 미사용) 시 즉시 재시작 + 데이터 손실 (in-memory) |
| 3 | 회복 후 application 자동 재연결 (redis-py auto-reconnect 기본 활성) |
| 4 | M2 §6.1 토픽 review — 단일 Redis 사용 중이면 Sentinel/Cluster 도입 (POSTMORTEM) |

### 보안 윈도우 mitigations

- 단기: alarm 발생 즉시 (1) 비정상 트래픽 모니터링 강화, (2) 의심 활동 user lockout 임시 강화
- 장기: M8 fail-closed 옵션 (Redis 다운 시 인증 reject) 평가 — 가용성 vs 보안 trade-off

### 재발 방지

- Redis Sentinel (3+노드) 또는 Cluster 모드 전환 (M8 production)
- monitoring: Redis ping latency p99 > 100ms → alarm

---

## T4 — JWT 서명 키 회전 시 모든 user 401

### 증상
- 키 회전 후 기존 access/refresh 모두 invalid signature 로 401
- 모든 활성 사용자 강제 재로그인

### 정상 절차 (회전 trigger 사유: 키 유출 의심, 정기 rotation)

```bash
# 1. 새 키 생성 (32 bytes random)
NEW_KEY=$(openssl rand -hex 32)

# 2. .env or settings 의 JWT_SECRET 갱신 (rolling restart 권장)
# Phase A: 양방향 키 (kid 도입 시) — 신구 둘 다 검증, 새 발급은 신키
# Phase B: 신키만 사용

# 3. 모든 BO worker rolling restart
kubectl rollout restart deployment/ebs-bo

# 4. 모든 사용자에게 재로그인 알림 (Slack/Email)
```

### 사고 진단 (실수로 회전 발생 시)

```bash
# 1. Settings 환경변수 확인
echo $JWT_SECRET | sha256sum  # 새 worker 와 옛 worker 가 다른 hash 면 회전 발생

# 2. BO worker 별 키 hash 확인 (모두 동일해야 정상)
for pod in $(kubectl get pods -l app=ebs-bo -o name); do
  kubectl exec $pod -- python -c "from src.app.config import settings; import hashlib; print(hashlib.sha256(settings.jwt_secret.encode()).hexdigest()[:8])"
done
```

### 해소

| 시나리오 | 액션 |
|---------|------|
| 의도된 회전 | 사용자 알림 후 재로그인 안내 (정상) |
| 실수 회전 | 즉시 옛 키로 rollback + rolling restart. 사용자에게 사과 통지 |
| Worker 별 키 불일치 | secret 배포 누락. ConfigMap/Secret 재배포 + restart |

### 재발 방지

- 키 회전 절차 SOP 문서화 (Confluence)
- `kid` (key id) 클레임 도입 → 양방향 키 운영 (M8)
- 키 로테이션 calendar event (90일 주기 권장)

---

## T5 — "동시 세션 한도 초과"

### 증상
- BS-01 §A-25: "최대 동시 세션 2개 (1 Lobby + 1 CC)"
- 사용자가 3번째 device 에서 로그인 시 응답 미정의 (현재 구현은 UPSERT 라 무한 device 허용)

### 현재 상태 (PR #43 시점)

- DB 는 device_id 별 row 분리 — 무한 device 허용 (3+ 도 OK)
- 정책 enforcement (max 2) 는 router 레벨 미구현 (별 PR)

### 진단 명령

```bash
# 사용자의 active session 수
psql -c "
  SELECT user_id, device_id, COUNT(*)
  FROM user_sessions
  WHERE user_id = <UID>
  GROUP BY user_id, device_id
"
```

### 분기 진단

| 진단 결과 | 해소 |
|----------|------|
| 2개 이하 | 정상. 정책 enforce 미구현이 사용자 혼란 원인 — 향후 PR |
| 3개 이상 | 사용자 device 누적 (분실/도난 가능성). Admin 이 오래된 row 수동 삭제 후 재로그인 안내 |

### 재발 방지

- 별 PR: router 에 `if active_count >= MAX_SESSIONS: invalidate_oldest()` 로직 추가
- Frontend 에 "현재 활성 device" 화면 + 로그아웃 버튼

---

## T6 — OAuth client_credentials 만료 동시 fetch

### 증상
- Vendor (WSOP LIVE) API 의 rate limit 도달
- BO 로그에 "OAuth refresh failed: 429 Too Many Requests"
- WSOP LIVE 동기화 일시 중단

### 진단 명령

```bash
# 1. OAuth 토큰 캐시 상태
redis-cli GET oauth:wsop_live:token | head -c 50
redis-cli TTL oauth:wsop_live:token

# 2. 락 상태 (정상이면 30s 미만)
redis-cli GET lock:oauth:wsop_live:refresh
redis-cli TTL lock:oauth:wsop_live:refresh

# 3. 최근 vendor refresh 호출 빈도
grep "POST.*wsop.*auth/token" /var/log/ebs/bo.log | tail -20
```

### 분기 진단

| 진단 결과 | 해소 |
|----------|------|
| TTL 음수 (이미 만료) + 락 GET 응답 nil | 락 미작동 → N worker 가 vendor 동시 호출 → vendor block. 락 코드 버그 |
| TTL 양수 + 락 GET 응답 worker_id | 다른 worker 가 fetch 중 — 정상 (대기 후 cache 재조회) |
| TTL 음수 + vendor 가 401 응답 | vendor secret 만료 또는 회전. credentials rotation 절차 |
| 토큰 cache 정상 + vendor 429 | 다른 endpoint (data sync) 가 vendor rate limit 초과. 백오프 강화 |

### 해소

```bash
# 1. 즉시 cache invalidate + 재시도 (단일 worker 가 fetch)
redis-cli DEL oauth:wsop_live:token
# BO 가 다음 호출 시 1 worker 만 fetch (락 정상 동작 시)

# 2. vendor rate limit hit 시 — exponential backoff 활성 (일시적)
# Application-level: max 5 retry, base 1s backoff, jitter 50%
```

### 재발 방지

- M2 §3.2 SETNX 락 패턴 활용
- `oauth.wsop_live.refresh_count` per minute metric → alarm: > 5/min 비정상

---

## 7. 일반 진단 명령 cheatsheet

```bash
# 활성 세션 수 (전체)
psql -c "SELECT COUNT(*) FROM user_sessions"

# 활성 blacklist jti 수
redis-cli DBSIZE  # blacklist + rate_limit + 기타 모두 포함
redis-cli --scan --pattern "blacklist:jti:*" | wc -l

# 최근 1h 로그인 시도 (성공/실패)
psql -c "
  SELECT
    SUM(CASE WHEN event_type = 'AUTH_LOGIN_SUCCESS' THEN 1 ELSE 0 END) AS success,
    SUM(CASE WHEN event_type = 'AUTH_LOGIN_FAILED' THEN 1 ELSE 0 END) AS failed
  FROM audit_logs
  WHERE created_at >= NOW() - INTERVAL '1 hour'
"

# Drift Gate 수동 실행 (정책 회귀 의심 시)
cd /path/to/ebs && python tools/spec_drift_check.py --auth
```

---

## 8. Escalation 매트릭스

| 사고 등급 | 트리거 | 1차 대응 | 2차 escalation |
|:--------:|--------|----------|---------------|
| **P1** | 모든 user 401 (T4 의도치 않음) / Redis cluster 전체 down | on-call SRE | Backend lead + CTO |
| **P2** | 일부 user 영향 (T1, T6 vendor block) | on-call SRE | Backend lead |
| **P3** | 단일 user (T2, T5) | Support team | SRE on confirm |
| **P4** | 모니터링 alarm 만 (drift 의심) | SRE 비상시간 외 처리 | — |

---

## 9. 참조

- Architecture: `Distributed_Architecture.md` (M2)
- Sequences: `Token_Lifecycle_Sequences.md` (M3)
- Concurrency 분석: `../../2.2 Backend/Authentication/Concurrency_and_Race_Conditions.md` (M4)
- Quickstart (로컬 클러스터 진단 환경): `../../2.2 Backend/Authentication/Quickstart_Local_Cluster.md` (M5, 후속)
- Production 운영 (배포/회전): `../../2.2 Backend/Authentication/Production_Deployment.md` (M8, 후속)
- BS-01 정책 SSOT: `../Authentication.md`
