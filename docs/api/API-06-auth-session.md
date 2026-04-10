# API-06 Auth & Session — 인증·토큰·세션·RBAC API

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | JWT 인증, 토큰 관리, 세션 API, RBAC 매트릭스 |
| 2026-04-09 | 수정 | `username`→`email` (DATA-04 User 모델 기준), `sub` UUID→int, 2FA 흐름 반영 |
| 2026-04-09 | GAP-L-001 보강 | §2.1 앱 시작 시 토큰 생명주기 섹션 추가 (토큰 검증 흐름, 로그인 페이지 진입 조건) |

---

## 개요

이 문서는 EBS Back Office(BO)의 **인증, 토큰, 세션, 역할 기반 접근 제어(RBAC)** API를 정의한다. Lobby(웹)와 CC(Flutter)는 동일한 인증 API를 사용하며, JWT 토큰으로 세션을 유지한다.

> **참조**: 용어 정의는 `BS-00-definitions.md`, RBAC 역할 정의는 `PRD-EBS_Foundation.md §Ch.8`, 로그인 UI 행동 명세는 `BS-01-auth/`

---

## 1. 인증 방식 — JWT 토큰

### 1.1 토큰 구조

EBS는 **Access Token + Refresh Token** 이중 토큰 방식을 사용한다.

| 토큰 | 용도 | 유효기간 | 저장 위치 |
|------|------|---------|----------|
| **Access Token** | API 요청 인증 | 15분 | Lobby: 메모리 / CC: Secure Storage |
| **Refresh Token** | Access Token 갱신 | 7일 | Lobby: HttpOnly Cookie / CC: Secure Storage |

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
    "token_type": "Bearer",
    "expires_in": 900,
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
| `refresh_token` | string | JWT Refresh Token |
| `token_type` | string | 항상 `"Bearer"` |
| `expires_in` | int | Access Token 유효 시간 (초) |
| `user.last_table_id` | int / null | 마지막 접속 테이블 (세션 복원용) |

**에러 응답:**

| 코드 | 상태 | 설명 |
|------|------|------|
| `AUTH_INVALID_CREDENTIALS` | 401 | 사용자명 또는 비밀번호 불일치 |
| `AUTH_ACCOUNT_LOCKED` | 403 | 5회 연속 실패 → 30분 잠금 |
| `AUTH_ACCOUNT_DISABLED` | 403 | 비활성 계정 |

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
  "expires_in": 900
}
```

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
    "id": "user-uuid-1234",
    "username": "john.doe",
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

> **참조**: `PRD-EBS_Foundation.md §Ch.8` 역할 3가지

### 5.1 역할 정의

| 역할 | 설명 | 테이블 범위 |
|------|------|:----------:|
| **Admin** | 전체 관리자. 모든 화면, 모든 테이블 접근 | 전체 |
| **Operator** | 운영자. 할당된 테이블의 CC만 조작 | 할당 1개 |
| **Viewer** | 열람자. 읽기 전용 접근 | 전체 (읽기만) |

### 5.2 엔티티별 CRUD 권한

| 엔티티 | Admin | Operator | Viewer |
|--------|:-----:|:--------:|:------:|
| Series | CRUD | R | R |
| Event | CRUD | R | R |
| Flight | CRUD | R | R |
| Table | CRUD | R (할당 테이블) | R |
| Player | CRUD | RU (할당 테이블) | R |
| Seat | CRUD | RU (할당 테이블) | R |
| Hand | CRUD | CR (할당 테이블) | R |
| Config (Settings) | CRUD | — | — |
| BlindStructure | CRUD | R | R |
| User (계정 관리) | CRUD | R (자기 정보) | R (자기 정보) |

> **C** = Create, **R** = Read, **U** = Update, **D** = Delete

### 5.3 API 엔드포인트별 접근 제한

| 엔드포인트 패턴 | Admin | Operator | Viewer | 비고 |
|---------------|:-----:|:--------:|:------:|------|
| `POST /auth/*` | O | O | O | 인증은 역할 무관 |
| `GET /series/*` | O | O | O | |
| `POST /series/*` | O | — | — | |
| `GET /tables/{id}` | O | 할당만 | O | |
| `PUT /tables/{id}` | O | — | — | |
| `POST /tables/{id}/hands` | O | 할당만 | — | CC에서 핸드 생성 |
| `GET /config/*` | O | — | — | Settings 접근 |
| `PUT /config/*` | O | — | — | Settings 수정 |
| `GET /users/*` | O | — | — | 계정 관리 |
| `POST /users/*` | O | — | — | 계정 생성 |
| `WebSocket /ws/cc` | O | 할당만 | — | CC 데이터 발행 |
| `WebSocket /ws/lobby` | O | O | O | 모니터링 구독 |

### 5.4 역할별 API 접근 제한 미들웨어

```
Request → JWT 검증 → 역할 추출 → 엔드포인트 매칭 → 허용/거부
                                      │
                                      ├─ Admin → 전체 허용
                                      ├─ Operator → 할당 테이블 확인
                                      │    └─ table_ids에 포함? → 허용 / 403
                                      └─ Viewer → GET만 허용
                                           └─ GET 아닌 메서드? → 403
```

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
| Access Token 만료 (15분) | 클라이언트가 자동으로 `/auth/refresh` 호출 → 새 Access Token 발급 |
| Refresh Token 유효 (7일 이내) | `/auth/refresh` 성공 → 끊김 없이 계속 사용 |
| Refresh Token 만료 (7일 초과) | `/auth/refresh` 실패 → 로그인 화면으로 리다이렉트 |

### 6.2 비정상 흐름

| 시나리오 | 시스템 반응 |
|---------|-----------|
| 네트워크 단절 후 복구 | Access Token 만료 확인 → Refresh 시도 → 성공 시 세션 복원 |
| 앱 크래시 후 재시작 | Secure Storage에서 Refresh Token 로드 → 갱신 시도 |
| 다른 기기에서 로그인 | 기존 세션 유지 (다중 세션 허용). Admin 설정으로 단일 세션 강제 가능 |
| Admin이 사용자 비활성화 | 다음 토큰 갱신 시 `AUTH_ACCOUNT_DISABLED` → 강제 로그아웃 |
| 비밀번호 변경 | 모든 Refresh Token 무효화 → 전 기기 재로그인 |

### 6.3 CC (Flutter) 특수 사항

| 항목 | 동작 |
|------|------|
| 토큰 저장 | `flutter_secure_storage` 사용 |
| 백그라운드 갱신 | 앱이 포그라운드일 때 만료 2분 전 자동 갱신 |
| 오프라인 동작 | Access Token 유효 기간 동안 로컬 캐시로 게임 진행 가능 |
| WebSocket 재연결 | 새 Access Token으로 WebSocket 재인증 |

### 6.4 Lobby (웹) 특수 사항

| 항목 | 동작 |
|------|------|
| Access Token 저장 | JavaScript 메모리 (XSS 방지) |
| Refresh Token 저장 | HttpOnly Cookie (CSRF 방지 + SameSite=Strict) |
| 탭 복원 | `beforeunload` 시 세션 상태 `sessionStorage` 백업 |
| 다중 탭 | 탭 간 토큰 공유 (`BroadcastChannel API`) |

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
