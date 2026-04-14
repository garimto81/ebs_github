# API-06 Auth & Session — 인증·토큰·세션·RBAC API

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | JWT 인증, 토큰 관리, 세션 API, RBAC 매트릭스 |
| 2026-04-09 | 수정 | `username`→`email` (DATA-04 User 모델 기준), `sub` UUID→int, 2FA 흐름 반영 |
| 2026-04-09 | GAP-L-001 보강 | §2.1 앱 시작 시 토큰 생명주기 섹션 추가 (토큰 검증 흐름, 로그인 페이지 진입 조건) |
| 2026-04-10 | CCR-003 | 로그인/로그아웃/refresh 등 mutation 엔드포인트에 `Idempotency-Key` 헤더 적용 (API-01 §3 멱등성 동작 참조) |
| 2026-04-10 | CCR-006 | JWT Access/Refresh 만료 정책 + BS-01 세부 명세 연계 |
| 2026-04-13 | refresh_token 전달 방식 | login 응답에 `refresh_token_delivery` 필드 추가. 환경별 차등: dev/staging/prod=body, live=HttpOnly Cookie |
| 2026-04-13 | 네이밍 규칙 | snake_case 통일 규칙 명시 (WSOP LIVE camelCase와의 변환 책임 = API-01 Part II) |
| 2026-04-14 | CCR-048 | Password Reset 3-step 엔드포인트 추가 (§8). WSOP LIVE GGPass 패턴 준거. SSOT: Confluence Page 1701380121 |
| 2026-04-14 | SSOT 슬림화 | §1.1 토큰 TTL 표·§5 RBAC 매트릭스·§6.3-6.4 클라이언트 저장 정책을 BS-01-auth.md로 위임. 본 문서는 순수 기술 계약(Request/Response)만 유지. user_id 필드명 통일(§4 user.id→user.user_id, username→email). 잠금 정책(5회→10회) BS-01 정렬. |

---

## 개요

이 문서는 EBS Back Office(BO)의 **인증, 토큰, 세션, 역할 기반 접근 제어(RBAC)** API를 정의한다. Lobby(웹)와 CC(Flutter)는 동일한 인증 API를 사용하며, JWT 토큰으로 세션을 유지한다.

> **참조**: 용어 정의는 `BS-00-definitions.md`, RBAC 역할 정의는 `PRD-EBS_Foundation.md §Ch.8`, 로그인 UI 행동 명세는 `BS-01-auth/`

### 멱등성 (CCR-003)

`POST /auth/login`, `POST /auth/refresh`, `DELETE /auth/session`, `POST /auth/verify-2fa` 등 **모든 mutation 엔드포인트**는 `Idempotency-Key` 헤더를 수용한다. 동작 상세는 `API-01-backend-api.md §3 공통 응답 포맷 — 멱등성 동작` 을 준수한다.

- 클라이언트: 네트워크 재시도·더블 클릭 방지를 위해 UUIDv4/ULID를 요청당 1회 생성
- 서버: `idempotency_keys` 테이블(DATA-04 §4)에 24h 캐시
- 상이한 바디로 동일 키 재사용 시 `409 IDEMPOTENCY_KEY_REUSED` 반환

### 필드 네이밍 규칙

모든 JSON 응답 필드는 **`snake_case`** 를 사용한다.

- WSOP LIVE API 는 `camelCase`(예: `accessToken`, `staffInfo`, `eventFlightId`)를 사용하나, EBS는 Python/FastAPI 생태계에 맞춰 `snake_case`(예: `access_token`, `staff_info`, `event_flight_id`)로 통일한다.
- WSOP LIVE 데이터 동기화 시 API-01 Part II (WSOP LIVE Integration) 계층의 UPSERT 로직이 camelCase → snake_case 변환을 수행한다.
- 클라이언트(team1 Lobby, team4 CC)는 항상 snake_case 기준으로 구현한다.

---

## 1. 인증 방식 — JWT 토큰

### 1.1 토큰 구조

EBS는 **Access Token + Refresh Token** 이중 토큰 방식을 사용한다.

> **TTL·환경 프로파일·클라이언트 저장 위치 정책 SSOT**: `BS-01-auth.md §JWT 만료 정책` + `§앱별 토큰 저장·갱신 비교`. 본 절은 토큰 페이로드 구조만 정의한다.

### 1.2 Access Token Payload (JWT Claims)

```json
{
  "sub": "1",
  "email": "admin@ebs.local",
  "role": "admin",
  "iat": 1712534400,
  "exp": 1712535300,
  "type": "access"
}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `sub` | string (int) | 사용자 고유 ID (`user_id` 문자열 변환) |
| `email` | string | 로그인 이메일 (DATA-04 `users.email` 기준) |
| `role` | string | `admin` / `operator` / `viewer` |
| `iat` | int (Unix timestamp) | 발급 시각 |
| `exp` | int (Unix timestamp) | 만료 시각 |
| `type` | string | `access` / `refresh` / `2fa_temp` |

---

## 2. 로그인 API

### POST /auth/login

사용자 인증 후 토큰 쌍을 발급한다.

**Request:**

```json
{
  "email": "admin@ebs.local",
  "password": "********"
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `email` | string | O | 로그인 이메일 |
| `password` | string | O | 비밀번호 |

**Response (200 OK) — 2FA 미설정 시:**

```json
{
  "data": {
    "access_token": "eyJhbGciOi...",
    "refresh_token": "eyJhbGciOi...",
    "refresh_token_delivery": "body",
    "token_type": "Bearer",
    "expires_in": 7200,
    "expires_at": "2026-04-10T14:34:56Z",
    "refresh_expires_in": 604800,
    "auth_profile": "prod",
    "user": {
      "user_id": 1,
      "email": "admin@ebs.local",
      "role": "admin",
      "table_ids": []
    },
    "requires_2fa": false
  },
  "error": null
}
```

> **CCR-006**: `expires_in` 은 `AUTH_PROFILE` 에 따라 3600~43200초 범위에서 변동한다. 환경별 기본값: dev=3600(1h), staging/prod=7200(2h), **live=43200(12h)**. `auth_profile` 필드로 클라이언트가 현재 프로파일을 확인할 수 있다. 상세는 `BS-01-auth.md §JWT 만료 정책` 참조.

**Response (200 OK) — 2FA 설정 시:**

```json
{
  "data": {
    "requires_2fa": true,
    "temp_token": "eyJhbGciOi..."
  },
  "error": null
}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `access_token` | string | JWT Access Token |
| `refresh_token` | string | JWT Refresh Token. `refresh_token_delivery="cookie"` 이면 이 필드는 **빈 문자열**이고 실제 값은 `Set-Cookie` 헤더로 전달 |
| `refresh_token_delivery` | string | `"body"` (dev/staging/prod) 또는 `"cookie"` (live 환경). live에서는 `Set-Cookie: refresh_token=...; HttpOnly; Secure; SameSite=Strict; Path=/auth/refresh` 헤더 사용 |
| `token_type` | string | 항상 `"Bearer"` |
| `expires_in` | int | Access Token 유효 시간 (초). `AUTH_PROFILE` 기반 3600~43200 (CCR-006) |
| `expires_at` | string (ISO 8601) | Access Token 만료 절대 시각. 클라이언트 자동 refresh 스케줄링용 (CCR-006) |
| `refresh_expires_in` | int | Refresh Token 유효 시간 (초). 기본 604800 (7일) (CCR-006) |
| `auth_profile` | string | 현재 환경 프로파일 (`dev`/`staging`/`prod`/`live`) (CCR-006) |
| `user.last_table_id` | int / null | 마지막 접속 테이블 (세션 복원용) |

**에러 응답:**

| 코드 | 상태 | 설명 |
|------|------|------|
| `AUTH_INVALID_CREDENTIALS` | 401 | 사용자명 또는 비밀번호 불일치 |
| `AUTH_ACCOUNT_LOCKED` | 403 | 자동 잠금 발동 (정책: BS-01-auth §자동 잠금 정책 — CCR-048 10회 영구) |
| `AUTH_ACCOUNT_DISABLED` | 403 | 비활성 계정 |

> 전체 에러 코드 카탈로그(13종)는 `BS-01-auth.md §에러 메시지 정의` 참조.

---

### 2.1 앱 시작 시 토큰 생명주기

> **GAP-L-001 보강**: 앱(브라우저) 재방문 시 localStorage/Cookie에 남아있는 토큰의 유효성을 반드시 서버에서 확인해야 한다.

#### Lobby (웹) 앱 초기화 흐름

```
앱 로드
  │
  ├─ localStorage에 access_token 존재?
  │    │
  │    ├─ NO ──→ 로그인 화면 표시 (끝)
  │    │
  │    └─ YES
  │         │
  │         └─ GET /auth/session 호출 (서버 검증)
  │              │
  │              ├─ 200 OK ──→ user 설정 → 보호된 페이지 표시
  │              │
  │              └─ 401/403 ──→ logout() → 로그인 화면 리다이렉트
  │
  └─ 로그인 페이지 진입 조건
       └─ GET /auth/session → 200 이면 /series로 리다이렉트 (이미 유효한 세션)
            └─ 401/403 이면 로그인 폼 표시 (정상 진입)
```

**핵심 규칙:**

| 규칙 | 설명 |
|------|------|
| localStorage 존재 ≠ 유효한 세션 | 토큰 존재 여부만으로 인증 상태 판단 금지. 반드시 `GET /auth/session`으로 서버 검증 |
| 로그인 페이지 진입 조건 | 유효한 세션이 **없을 때만** 로그인 폼 표시. 유효한 세션이 있으면 즉시 `/series`로 리다이렉트 |
| 만료 토큰 → 강제 로그아웃 | `GET /auth/session` 실패 시 `logout()` 호출 후 `/login`으로 리다이렉트 |
| Refresh Token 만료 | `POST /auth/refresh` 실패(401) → 재로그인 필요. 서버에 저장된 세션 데이터는 보존됨 |

---

## 3. 토큰 갱신 API

### POST /auth/refresh

Refresh Token으로 새 Access Token을 발급한다.

**Request:**

```json
{
  "refresh_token": "eyJhbGciOi..."
}
```

**Response (200 OK):**

```json
{
  "access_token": "eyJhbGciOi...(new)",
  "expires_in": 7200,
  "expires_at": "2026-04-10T16:34:56Z",
  "auth_profile": "prod"
}
```

> **CCR-006**: `expires_in` 은 `AUTH_PROFILE` 환경 플래그에 따라 3600~43200초. 클라이언트는 `expires_at` 을 기준으로 다음 자동 refresh 시점(만료 5분 전)을 스케줄링한다.

**에러 응답:**

| 코드 | 상태 | 설명 |
|------|------|------|
| `AUTH_TOKEN_EXPIRED` | 401 | Refresh Token 만료 → 재로그인 필요 |
| `AUTH_TOKEN_REVOKED` | 401 | 로그아웃으로 무효화된 토큰 |
| `AUTH_TOKEN_INVALID` | 401 | 형식 오류 또는 서명 불일치 |

---

## 4. 세션 관리 API

### GET /auth/session

현재 세션 정보를 반환한다. Access Token 유효성 검증 겸용.

**Headers:** `Authorization: Bearer {access_token}`

**Response (200 OK):**

```json
{
  "user": {
    "user_id": 1,
    "email": "admin@ebs.local",
    "role": "admin",
    "table_ids": []
  },
  "session": {
    "last_series_id": 1,
    "last_event_id": 42,
    "last_flight_id": 3,
    "last_table_id": 5,
    "connected_at": "2026-04-08T09:00:00Z"
  }
}
```

> `user_id`/`email` 필드명은 `POST /auth/login` 응답(§2)과 동일. DATA-04 `users` 테이블 키 컬럼 그대로.

> **참조**: 세션 저장 데이터는 `BS-02-lobby.md §세션 저장 데이터` 참조

### DELETE /auth/session

로그아웃. Refresh Token을 무효화하고 세션을 종료한다.

**Headers:** `Authorization: Bearer {access_token}`

**Response (200 OK):**

```json
{
  "message": "Logged out successfully"
}
```

**동작:**
1. 서버 측 Refresh Token 무효화 (블랙리스트 추가)
2. `user_sessions` 테이블에 로그아웃 시각 기록
3. 해당 사용자의 WebSocket 연결 종료

---

## 5. RBAC 매트릭스

> **정책 SSOT**: `BS-01-auth.md §역할 정의·매트릭스`. 역할 정의(Admin/Operator/Viewer), 엔티티별 CRUD 권한, 엔드포인트별 접근 제한, 미들웨어 FSM, Bit Flag Permission(CCR-017) 모두 BS-01-auth가 단일 출처. 본 문서는 미들웨어 가드가 반환하는 에러 코드만 정의.

**미들웨어 가드 에러:**

| 코드 | 상태 | 설명 |
|------|------|------|
| `AUTH_UNAUTHORIZED` | 401 | 토큰 없음 또는 만료 |
| `AUTH_FORBIDDEN` | 403 | 역할 권한 부족 |
| `AUTH_TABLE_NOT_ASSIGNED` | 403 | Operator가 할당되지 않은 테이블에 접근 |

---

## 6. 세션 만료 및 재인증 시나리오

### 6.1 정상 흐름

| 시나리오 | 시스템 반응 |
|---------|-----------|
| Access Token 만료 (환경별 TTL: 1h/2h/12h) | 클라이언트가 만료 5분 전 자동으로 `/auth/refresh` 호출 → 새 Access Token 발급 |
| Refresh Token 유효 (TTL: 24h/7d) | `/auth/refresh` 성공 → 끊김 없이 계속 사용 (WebSocket 연결 유지, `reauth` 커맨드 전송) |
| Refresh Token 만료 | `/auth/refresh` 실패 → 로그인 화면으로 리다이렉트 |

### 6.2 비정상 흐름

| 시나리오 | 시스템 반응 |
|---------|-----------|
| 네트워크 단절 후 복구 | Access Token 만료 확인 → Refresh 시도 → 성공 시 세션 복원 |
| 앱 크래시 후 재시작 | Secure Storage에서 Refresh Token 로드 → 갱신 시도 |
| 다른 기기에서 로그인 | 기존 세션 유지 (다중 세션 허용). Admin 설정으로 단일 세션 강제 가능 |
| Admin이 사용자 비활성화 | 다음 토큰 갱신 시 `AUTH_ACCOUNT_DISABLED` → 강제 로그아웃 |
| 비밀번호 변경 | 모든 Refresh Token 무효화 → 전 기기 재로그인 |

### 6.3 클라이언트별 저장·갱신 정책

> SSOT: `BS-01-auth.md §앱별 토큰 저장·갱신 비교`. CC(Flutter Secure Storage·백그라운드 갱신·오프라인 동작·WebSocket 재인증), Lobby(메모리·HttpOnly Cookie·BroadcastChannel 다중 탭) 정책 모두 BS-01에서 단일 관리.

---

## 7. Phase 1 인증 방식

> **참조**: `BS-02-lobby.md §화면 0: 로그인` 인증 방식 매트릭스

| Phase | 인증 방식 | 2FA |
|:-----:|----------|:---:|
| **1** | Email + Password + TOTP | O |
| 2 | + Google OAuth | Google 자체 |
| 3 | + Entra ID (Azure AD) | Entra 자체 |

Phase 1에서는 Email + Password를 기본으로 구현하며, TOTP(Time-based One-Time Password) 2단계 인증을 지원한다.

### 2FA 흐름 (Phase 1)

```
POST /auth/login (username, password)
  → 200 { requires_2fa: true, temp_token: "..." }
  → POST /auth/verify-2fa (temp_token, totp_code)
    → 200 { access_token, refresh_token }
```

| 엔드포인트 | 설명 |
|-----------|------|
| `POST /auth/verify-2fa` | TOTP 코드 검증 후 최종 토큰 발급 |
| `POST /auth/2fa/setup` | 2FA 초기 설정 (QR 코드 반환) |
| `POST /auth/2fa/disable` | 2FA 비활성화 (Admin만) |

---

## 8. Password Reset (CCR-048, WSOP LIVE GGPass 정렬)

> **WSOP LIVE 대응**: `POST /Password/Reset/Send` → `POST /Verify` → `POST /Password/Reset` (SSOT: Confluence Page 1701380121). EBS 도 동일 3-step 구조를 채택하며 URL 은 EBS REST 컨벤션(lowercase kebab)으로 변환.

### 8.1 엔드포인트

| Method | Path | 설명 | 역할 제한 |
|:------:|------|------|:---------:|
| POST | `/auth/password/reset/send` | 이메일로 reset 토큰 발송 | 미인증 |
| POST | `/auth/password/reset/verify` | 토큰 검증 (만료/사용 여부 확인) | 미인증 |
| POST | `/auth/password/reset` | 새 비밀번호 설정 (토큰 + new_password) | 미인증 |

### 8.2 POST /auth/password/reset/send

**Request:**

```json
{ "email": "user@example.com" }
```

> 이메일 존재 여부는 응답으로 노출하지 않는다 (enumeration 방어). 항상 `200 OK` + 일반 메시지("If the email exists, a reset link has been sent.") 반환. Rate limit: 3회/시간/email (BS-01-auth §Rate Limiting).

### 8.3 POST /auth/password/reset/verify

**Request:**

```json
{ "token": "..." }
```

**Response (200):**

```json
{ "valid": true, "expires_at": "2026-04-14T15:30:00Z" }
```

만료/사용된 토큰은 `400 INVALID_TOKEN` 또는 `400 TOKEN_EXPIRED`.

### 8.4 POST /auth/password/reset

**Request:**

```json
{ "token": "...", "new_password": "..." }
```

**동작:**
- 성공 시 모든 활성 세션 무효화 (refresh token 블랙리스트)
- 토큰 1회용 (used_at 기록)
- 토큰 TTL: 1시간
- 이전 비밀번호 재사용 거부 (최근 5개 해시 비교)

**에러 응답:**

| 코드 | 상태 | 설명 |
|------|------|------|
| `PASSWORD_RESET_INVALID_TOKEN` | 400 | 존재하지 않는 토큰 |
| `PASSWORD_RESET_TOKEN_EXPIRED` | 400 | 토큰 만료 (1시간 초과) |
| `PASSWORD_RESET_TOKEN_USED` | 400 | 이미 사용된 토큰 |
| `PASSWORD_POLICY_VIOLATION` | 422 | 비밀번호 정책 미달 (BS-01-auth §비밀번호 정책) |
