---
title: Token Lifecycle Sequences
owner: conductor
tier: contract
last-updated: 2026-04-28
related-ssot: ../Authentication.md (BS-01)
related-arch: Distributed_Architecture.md (M2)
related-impl: ../../2.2 Backend/Engineering/M1_Session_Drift_Audit_2026-04-28.md
related-plan: ~/.claude/plans/role-and-objective-reactive-canyon.md (M3)
reimplementability: PASS
reimplementability_checked: 2026-05-03
reimplementability_notes: "M3 — 7 Mermaid 시퀀스 + invariant 명시, 외부 재구현 가능"
confluence-page-id: 3818684817
confluence-parent-id: 3812032646
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818684817/EBS+Token+Lifecycle+Sequences
derivative-of: ../../2.2 Backend/Back_Office/Overview.md
if-conflict: derivative-of takes precedence
---
# Token Lifecycle Sequences (M3)

7 Mermaid 시퀀스로 BS-01 정책 + M2 분산 아키텍처가 실제 호출 흐름에서 어떻게
동작하는지 시각화. 각 시퀀스는 한 줄 invariant + 다이어그램 + 1-2 paragraph 설명
+ 위반 시 영향.

## 목차 + Invariant

| Seq | 시나리오 | 핵심 invariant |
|:---:|---------|--------------|
| 1 | Login (Email + Password + 2FA) | 2FA 활성 사용자는 access_token 직접 발급 받지 못함 (반드시 verify-2fa 통과) |
| 2 | Refresh Token Rotation (M8 PG FOR UPDATE) | 동일 refresh_token 으로 동시 N call → 정확히 1건만 새 토큰 받음 |
| 3 | Access Token 만료 → Auto Refresh (Frontend 401 hook) | 401 발생 → refresh 1회 시도 → 실패 시 로그인 화면 redirect |
| 4 | Logout (DB delete + blacklist add) | logout 후 동일 access token 으로 후속 호출 시 즉시 401 (TTL 잔여 무관) |
| 5 | 강제 무효화 (Admin → 모든 jti revoke) | role 강등 / 비밀번호 강제 변경 → 영향 사용자의 모든 활성 worker 가 < 50ms 내 401 |
| 6 | Lobby → CC Token Handoff | CC 는 독립 로그인 없이 Lobby 가 발급한 access token 으로 BO 인증 |
| 7 | OAuth client_credentials Cluster Cache | N worker 동시 만료 직전 → vendor API 호출 정확히 1회 |

---

## Seq 1 — Login (Email + Password + 2FA)

```mermaid
sequenceDiagram
    participant U as User (Lobby)
    participant BO as BO (FastAPI)
    participant DB as PostgreSQL
    participant R as Redis (rate limit)

    U->>BO: POST /auth/login {email, password}
    BO->>R: INCR rate_limit:ip:{ip}:login (with EXPIRE 60s)
    alt rate exceeded
        R-->>BO: count > 5
        BO-->>U: 429 RATE_LIMIT_EXCEEDED
    end
    BO->>DB: SELECT * FROM users WHERE email=?
    DB-->>BO: user row
    alt locked or inactive
        BO-->>U: 403 AUTH_ACCOUNT_LOCKED / 401 AUTH_USER_INACTIVE
    end
    BO->>BO: verify_password(password, hash)
    alt wrong password
        BO->>DB: UPDATE failed_login_count + 1<br/>(if >= 10: locked_until = sentinel)
        BO-->>U: 401 AUTH_INVALID_CREDENTIALS
    end
    alt totp_enabled = false
        BO->>BO: create_access_token + create_refresh_token (jti 포함)
        BO->>DB: UPSERT user_sessions (user_id, device_id='default')
        BO-->>U: 200 {access_token, refresh_token, ...}
    else totp_enabled = true
        BO->>BO: create_2fa_temp_token (5분)
        BO-->>U: 200 {two_factor_required: true, temp_token}
        Note over U,BO: 후속 POST /auth/verify-2fa 로 access 발급
    end
```

**위반 시 영향**: 2FA-required 사용자가 직접 access_token 받으면 BS-01 §2FA Level 정책 위반 (Medium/High level → bypass). 회귀 가드: `tests/test_auth_security.py::test_2fa_required_blocks_direct_access`.

---

## Seq 2 — Refresh Token Rotation (M8 PG FOR UPDATE)

```mermaid
sequenceDiagram
    participant W1 as Worker A
    participant W2 as Worker B
    participant PG as PostgreSQL primary
    participant Cli as Client

    Note over Cli,PG: 동일 refresh_token 으로 동시 2 call
    par Worker A 처리
        Cli->>W1: POST /auth/refresh
        W1->>PG: BEGIN
        W1->>PG: SELECT * FROM user_sessions<br/>WHERE refresh_token=:rt FOR UPDATE
    and Worker B 처리
        Cli->>W2: POST /auth/refresh (동일 token)
        W2->>PG: BEGIN
        W2->>PG: SELECT ... FOR UPDATE
        Note over W2,PG: A 의 트랜잭션 끝까지 BLOCKED
    end
    PG-->>W1: row (locked)
    W1->>W1: issue new pair
    W1->>PG: UPDATE refresh_token = :new
    W1->>PG: COMMIT
    PG-->>W1: OK
    W1-->>Cli: 200 {new access + refresh}
    PG-->>W2: row (now refresh_token = :new, 다름)
    Note over W2: WHERE 절에서 매칭 실패 → row None
    W2->>PG: COMMIT
    W2-->>Cli: 401 AUTH_INVALID_REFRESH<br/>(Frontend → 로그인 화면)
```

**위반 시 영향**: FOR UPDATE 없이 구현하면 두 worker 모두 row 발견 → 둘 다 새 pair 발행 → DB 에 last-write-wins → 한 worker 의 응답 토큰은 DB 에 없는 상태 → 다음 호출 시 401. user 가 무작위 로그아웃 경험.

> **현재 상태 (2026-04-28)**: refresh rotation 미구현 (refresh token 은 48h 동안 동일 값). M8 Production_Deployment 시 본 시퀀스 활성화.

---

## Seq 3 — Access Token 만료 → Auto Refresh (Frontend hook)

```mermaid
sequenceDiagram
    participant U as Browser (Lobby)
    participant FE as Frontend (axios interceptor)
    participant BO as BO

    U->>FE: API 호출 (예: GET /api/v1/Series)
    FE->>BO: GET /api/v1/Series<br/>Authorization: Bearer {access (만료)}
    BO->>BO: decode → exp 과거
    BO-->>FE: 401 AUTH_UNAUTHORIZED
    FE->>FE: 401 hook 발동
    FE->>BO: POST /auth/refresh<br/>{refresh_token} or Cookie
    alt refresh valid
        BO-->>FE: 200 {new access}
        FE->>FE: store new access
        FE->>BO: GET /api/v1/Series<br/>Authorization: Bearer {new access} (재시도)
        BO-->>FE: 200 {data}
        FE-->>U: 데이터 표시 (사용자 무중단)
    else refresh expired or revoked
        BO-->>FE: 401 AUTH_INVALID_REFRESH
        FE->>FE: clear local tokens
        FE-->>U: 로그인 화면 redirect
    end
```

**위반 시 영향**: hook 미구현 시 매 access 만료마다 user 가 명시적 재로그인. live (12h TTL) 환경에서는 1일 1-2 회 발생, dev (1h) 는 잦은 끊김. UX 저하.

---

## Seq 4 — Logout (DB delete + Blacklist add)

```mermaid
sequenceDiagram
    participant U as User
    participant BO as BO
    participant DB as PostgreSQL
    participant R as Redis (blacklist)
    participant W2 as Worker B

    U->>BO: POST /auth/logout<br/>Bearer {access}
    BO->>BO: get_current_token_payload (decode)
    BO->>BO: extract jti, exp
    BO->>R: SET blacklist:jti:{jti} 1 EX (exp - now)
    BO->>DB: DELETE FROM user_sessions<br/>WHERE user_id = :uid
    DB-->>BO: rows affected
    BO-->>U: 200 {message: "Logged out"}

    Note over U,W2: 같은 token 으로 다른 worker 호출 시도
    U->>W2: GET /auth/me<br/>Bearer {access (이미 logged out)}
    W2->>W2: decode → jti 추출
    W2->>R: EXISTS blacklist:jti:{jti}
    R-->>W2: 1 (revoked)
    W2-->>U: 401 AUTH_TOKEN_REVOKED
```

**위반 시 영향**: blacklist add 누락 → logout 후에도 동일 access token 이 잔여 TTL 동안 valid. live (12h) 환경에서 분실/탈취 토큰의 위험 노출. 회귀 가드: `tests/test_blacklist_propagation.py::test_logout_blacklists_access_jti`.

---

## Seq 5 — 강제 무효화 (Admin → 모든 jti revoke)

```mermaid
sequenceDiagram
    participant Adm as Admin (Lobby)
    participant BO as BO
    participant DB as PostgreSQL
    participant R as Redis
    participant Pub as Redis Pub/Sub
    participant U as Affected User<br/>(다른 device)

    Adm->>BO: PATCH /api/v1/Users/{id} {role: "viewer"}<br/>(was admin)
    BO->>DB: UPDATE users SET role=...
    BO->>DB: SELECT id, jti FROM user_sessions<br/>WHERE user_id = :affected
    Note over BO: M8: 모든 device 의 access jti 회수<br/>(현재는 access jti 가 user_sessions 에 영구 저장 안 됨 — 향후 보강)
    loop for each active jti
        BO->>R: SET blacklist:jti:{jti} 1 EX 12h
    end
    BO->>DB: DELETE FROM user_sessions WHERE user_id = :affected
    BO->>Pub: PUBLISH ebs.auth.revoke.{user_id} {reason}
    BO-->>Adm: 200 {updated}

    Note over U,Pub: 영향 user 의 active WS 즉시 종료
    Pub-->>U: WebSocket close (1000, "AUTH_REVOKED")
    U->>U: Frontend → 로그인 화면 redirect

    Note over U: HTTP 호출 시도
    U->>BO: GET /api/v1/Series<br/>Bearer {old admin token}
    BO->>R: EXISTS blacklist:jti:{jti}
    R-->>BO: 1
    BO-->>U: 401 AUTH_TOKEN_REVOKED
```

**위반 시 영향**: revoke 미구현 시 강등된 user 가 잔여 access TTL (live 최대 12h) 동안 admin 권한 유지. PCI/SOC 규정 위반 위험. M1 Item 2 (PR #42) 가 logout 경로에 blacklist 도입했으므로 admin 강등 경로 활성화는 향후 작은 PR.

---

## Seq 6 — Lobby Launch CC (Token Handoff)

```mermaid
sequenceDiagram
    participant U as Operator
    participant L as Lobby (Flutter Web)
    participant CC as CC App (Flutter Desktop)
    participant BO as BO

    U->>L: 로그인 + 테이블 선택 + "Launch CC" 클릭
    L->>L: 현재 access + refresh 토큰 보유
    L->>CC: ebs-cc://launch?token={one_time_handoff_token}<br/>(URL scheme)
    Note over CC: handoff_token 은 단명 (60s) JWT.<br/>포함: user_id, device_id="cc", table_id
    CC->>BO: POST /auth/exchange<br/>{handoff_token}
    BO->>BO: verify handoff_token (type=handoff, exp <= 60s)
    BO->>BO: create_session(user, db, device_id="cc")
    BO-->>CC: 200 {access, refresh}
    Note over CC: 이제 CC 는 BO 에 직접 인증 (Lobby 와 분리된 device)
    CC->>BO: GET /api/v1/Tables/{table_id}<br/>Bearer {cc_access}
    BO-->>CC: 200 {table state}
```

**위반 시 영향**: handoff 미구현 시 CC 가 별도 로그인 화면 필요 (UX 저하 + 2FA 두 번). 또는 access token 을 query parameter 로 전달 (URL 로그/브라우저 history 노출 = 보안 위험).

> **현재 상태**: Lobby Launch CC 패턴은 BS-01 §A-02/A-04 (CC 독립 로그인 삭제, Lobby-Only Launch) 에 정책 정의. 코드 구현 (handoff_token + /auth/exchange endpoint) 은 별 PR 진행.

---

## Seq 7 — OAuth client_credentials Cluster Cache

```mermaid
sequenceDiagram
    participant W1 as Worker A
    participant W2 as Worker B
    participant W3 as Worker C
    participant R as Redis Cluster
    participant V as WSOP LIVE Auth API

    Note over W1,W3: 모든 worker 가 동시에 vendor 호출 필요한 시점<br/>(cached token expires_in - 30s 시점)
    par
        W1->>R: GET oauth:wsop_live:token
        W2->>R: GET oauth:wsop_live:token
        W3->>R: GET oauth:wsop_live:token
    end
    R-->>W1: nil (만료 직전)
    R-->>W2: nil
    R-->>W3: nil
    par
        W1->>R: SET lock:oauth NX EX 30 (value=W1)
        W2->>R: SET lock:oauth NX EX 30 (value=W2)
        W3->>R: SET lock:oauth NX EX 30 (value=W3)
    end
    R-->>W1: OK (획득)
    R-->>W2: nil (실패)
    R-->>W3: nil (실패)
    W1->>V: POST /auth/token grant=client_credentials
    V-->>W1: {access_token, expires_in: 3600}
    W1->>R: SETEX oauth:wsop_live:token 3570 {token}
    W1->>R: DEL lock:oauth (CAS — value 일치 시만)

    Note over W2,W3: 짧은 sleep (100ms) 후 cache 재조회
    W2->>R: GET oauth:wsop_live:token
    R-->>W2: {token} (방금 W1 이 SETEX)
    W3->>R: GET oauth:wsop_live:token
    R-->>W3: {token}
```

**위반 시 영향**: 락 없이 구현 시 N worker 가 동시 vendor API 호출 → vendor rate limit 도달 + cost 증가. 또한 SET 순서 race 로 만료 시점 불일치.

---

## Cross-reference

| Seq | 관련 코드 | 회귀 테스트 |
|:---:|----------|-------------|
| 1 | `auth_service.py::authenticate`, `routers/auth.py::login` | `test_auth.py::test_login_*`, `test_auth_security.py::test_2fa_*` |
| 2 | `auth_service.py::refresh_session` (현재 단순), M8: PG FOR UPDATE 추가 | M8: `test_refresh_race.py` |
| 3 | Frontend `lib/.../api/interceptor.dart` | E2E `test_login_session_restore.dart` |
| 4 | `routers/auth.py::logout` + `security/blacklist.py` | `test_blacklist_propagation.py::test_logout_blacklists_access_jti` |
| 5 | (M5 구현 예정) `routers/users.py::patch_user` 의 revoke trigger | (M5) |
| 6 | (별 PR) `routers/auth.py::exchange` + Lobby URL scheme | E2E `test_launch_cc_handoff.dart` |
| 7 | `adapters/wsop_auth.py` (이미 OAuth client_credentials 구현) | `test_wsop_auth_extended.py` |

---

## 참조

- Architecture: `Distributed_Architecture.md` (M2)
- Concurrency: `Concurrency_and_Race_Conditions.md` (M4, 후속)
- Production: `../../2.2 Backend/Authentication/Production_Deployment.md` (M8, 후속)
- BS-01 정책 SSOT: `../Authentication.md`
