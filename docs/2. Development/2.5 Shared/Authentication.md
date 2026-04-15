---
title: Authentication
owner: conductor
tier: internal
last-updated: 2026-04-15
legacy-id: BS-01
---

# BS-01 Auth — 인증·세션·RBAC 행동 명세

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 인증, 세션, RBAC 행동 명세 초기 버전 |
| 2026-04-09 | CC 접속 모델 변경 | CC 독립 로그인 삭제, Lobby-Only Launch 패턴으로 전환. A-02/A-04 변경, A-10/A-25 변경 |
| 2026-04-09 | 비밀번호 재설정 추가 | Forgot Password 흐름(A-26~A-29), 에러 코드 2건, Audit 이벤트 2건 |
| 2026-04-09 | doc-critic FAIL 항목 수정 | 정의 섹션 용어 사전 14개 추가, 인증 전체 흐름 시각화 추가, 전문 용어 첫 등장 시 괄호 설명 30건 추가 |
| 2026-04-09 | GAP-L-001 보강 | 세션 관리 A-20(앱 재방문 토큰 검증), A-21(로그인 페이지 진입 조건) 추가 |
| 2026-04-10 | CCR-006 | JWT Access/Refresh 만료 정책 환경별 차등 명시 (`## Session & Token Lifecycle` 섹션 신설) |
| 2026-04-13 | CCR promote 반영 | Refresh Token 전달 방식을 환경별 조건부로 변경 (dev~prod: JSON body, live: HttpOnly Cookie). API-06 `refresh_token_delivery` 필드와 정합 |
| 2026-04-13 | CCR-017 통합 | BS-01-02-rbac.md Permission Bit Flag 섹션 흡수. 역할 정의 중복 제거. |
| 2026-04-14 | CCR-048 | 2FA Level 4-단계(Off/Low/Medium/High), 자동 잠금 10회 실패, Refresh Token TTL 48h 명시. WSOP LIVE GGPass 정렬 (SSOT Page 1972863063, 2202861710) |
| 2026-04-14 | CCR-052 | Rate Limiting 정책 섹션 신설 (카테고리별 한계, 응답 헤더, 저장소 전략, IP whitelist). OWASP + WSOP LIVE 준거 |
| 2026-04-14 | CCR-053 | Provisioning 전략 (Phase별 유저 생성 방식) + Suspend vs Lock 의미 차이 섹션 신설. WSOP LIVE Staff 패턴 정렬 (SSOT Page 1597768061) |
| 2026-04-15 | G5 추가 | **방향별 인증 2-스택** 섹션 신설. EBS 내부(UI→BO) = JWT Bearer (기존), EBS outbound(BO→WSOP LIVE) = OAuth 2.0 client_credentials (신규). 구현: `team2-backend/src/adapters/wsop_auth.py`. **decision_owner = Conductor** — team2 브랜치에서 직접 편집 + PR 로 리뷰 요청 (v6 거버넌스, CR draft 파일 미생성) |
| 2026-04-15 | SSOT 선언 블록 추가 | 토큰 TTL · refresh · 2FA · Lockout · Rate Limit 정책 수치의 단일 진실임을 명시. Login/* 및 Backend/APIs/Auth_and_Session.md 가 본 문서를 참조하도록 규정 (team1 발신, 기획 문서 충분성 보강). |

---

## 개요

운영자가 EBS 시스템에 **로그인하고 권한을 부여받는 과정**을 정의한다. Lobby(웹)에서 로그인 후 테이블을 선택하여 Command Center(CC, 실시간 방송 입력 Flutter 앱)를 Launch한다. CC는 독립 로그인 없이 Lobby에서 전달받은 토큰으로 BO(EBS 중앙 서버)에 인증한다.

> 참조: BS-00 §1 앱 아키텍처 용어, API-06 Auth & Session, BO-02 User Management, Foundation PRD Ch.8 RBAC

---

## 이 문서의 SSOT 범위 (정책 수치의 정답 위치)

본 문서는 EBS 전체 인증 정책의 **단일 진실 (Single Source of Truth)** 이다. 아래 항목의 값은 오직 이 문서에서만 정의되며, 다른 문서는 반드시 이 문서를 가리켜야 한다. 다른 문서에서 수치가 재정의되어 있으면 **해당 중복을 제거하고 본 문서를 참조하도록 고치는 것이 옳다**.

| 주제 | 본 문서 섹션 | 다른 문서의 의무 |
|------|-------------|----------------|
| **Access Token TTL** (환경별: dev/staging/prod/live) | `## Session & Token Lifecycle` | 수치 재정의 금지. placeholder 또는 참조 링크만 |
| **Refresh Token TTL** (dev 24h / staging·prod·live 48h) | `## Session & Token Lifecycle` | 동 위 |
| **Refresh Token 전달 방식** (dev~prod JSON body / live HttpOnly Cookie) | `## Session & Token Lifecycle` | `../2.2 Backend/APIs/Auth_and_Session.md` 의 `refresh_token_delivery` 필드 정합 유지 |
| **2FA Level 정책** (Off/Low/Medium/High 4단계) | CCR-048 통합 섹션 | Login 화면 문서는 UI 표시만, 규칙 값은 본 문서 |
| **Lockout Policy** (최대 시도 10회, 잠금 시간) | CCR-048 통합 섹션 | `../2.1 Frontend/Login/Error_Handling.md` 는 UI 표시만, 수치는 본 문서 |
| **Rate Limit 정책** (카테고리별 한계, 응답 헤더) | CCR-052 통합 섹션 | 동 위 |
| **RBAC Permission Bit Flag** (역할별 권한 비트) | CCR-017 통합 섹션 | Frontend `authStore.permissions` 필드 규격은 본 문서 기준 |
| **Provisioning 전략** (Phase별 유저 생성) | CCR-053 통합 섹션 | — |

### 이 문서에서 다루지 않는 것

| 주제 | 정답 위치 |
|------|----------|
| 로그인 API 요청/응답 HTTP 스키마 | `../2.2 Backend/APIs/Auth_and_Session.md` |
| 로그인 화면 UI · 폼 요소 · Phase 별 인증 방식 선택지 | `../2.1 Frontend/Login/Form.md` |
| 로그인 에러 코드 → 한글 문구 · i18n 키 매핑 | `../2.1 Frontend/Login/Error_Handling.md` |
| Pinia `authStore` 구현 · 401 refresh 시퀀스 | `../2.1 Frontend/Engineering.md §4.4` |
| 세션 복원 Fallback Ladder (Table→Flight→Event→Series→fresh) | `../2.1 Frontend/Lobby/Session_Restore.md` |

### 중복 탐지 규칙

개발자·리뷰어는 PR 에서 다음을 검증한다:

- 본 문서 SSOT 표의 값이 다른 문서에 **상수로 하드코딩** 되어 있으면 즉시 참조로 교체.
- 본 문서가 가리키는 정책 이름(`AUTH_ACCOUNT_LOCKED` 등)을 다른 문서가 **재정의** 하면 즉시 제거.
- 값이 환경별로 다른 경우(dev/staging/prod/live), 다른 문서는 "`## Session & Token Lifecycle` 참조" 로만 기재.

---

## 정의

**Auth**는 EBS 사용자가 자격 증명(email + password)을 제출하여 **신원을 확인(Authentication)**받고, 역할(Admin/Operator/Viewer)에 따라 **접근 권한을 부여(Authorization)**받는 일련의 과정이다.

| 구성 요소 | 설명 |
|----------|------|
| **Authentication** | 사용자 식별 — email + password + 선택적 TOTP 2FA |
| **Authorization** | 권한 결정 — JWT 토큰의 `role` 클레임 기반 RBAC |
| **Session** | 인증 상태 유지 — Access Token + Refresh Token (만료 정책은 환경별 차등, `## Session & Token Lifecycle` 참조) |

### 용어 사전

| 용어 | 설명 |
|------|------|
| **JWT** (JSON Web Token) | 로그인 성공 시 서버가 발급하는 디지털 출입증. 매 요청마다 이 출입증을 보여 신원을 증명 |
| **TOTP** (Time-based One-Time Password) | 30초마다 바뀌는 6자리 숫자 코드. Google Authenticator 같은 앱에서 생성 |
| **RBAC** (Role-Based Access Control) | 역할(Admin/Operator/Viewer)에 따라 접근 가능한 기능을 제한하는 방식 |
| **Access Token** | 단기 출입증. API 요청 시 매번 제출. 만료 시간은 환경별 차등 (dev 1h / staging·prod 2h / **prod-live 12h**) |
| **Refresh Token** | 장기 출입증. Access Token 만료 시 새 Access Token을 발급받는 데 사용. 만료 시간: dev 24h / staging·prod·live 48h (CCR-048 WSOP LIVE 정렬) |
| **WebSocket** | 서버와 브라우저 간 실시간 양방향 통신 채널. 채팅처럼 즉시 메시지를 주고받음 |
| **OAuth** | 외부 서비스(Google, Microsoft)의 계정으로 로그인하는 방식. 비밀번호를 직접 관리하지 않아도 됨 |
| **SSO** (Single Sign-On) | 한 번 로그인하면 여러 서비스에 추가 로그인 없이 접근하는 방식 |
| **IdP** (Identity Provider) | 사용자 인증을 대행하는 외부 서비스 (예: Google, Azure AD) |
| **XSS** (Cross-Site Scripting) | 악성 스크립트를 웹 페이지에 주입하는 공격. 토큰 탈취 방지를 위해 방어 필요 |
| **HttpOnly Cookie** | JavaScript로 접근할 수 없는 특수 쿠키. XSS 공격으로부터 토큰 보호 |
| **BO** (Back Office) | EBS 중앙 서버. 데이터베이스, API, 인증을 관리 |
| **CC** (Command Center) | 실시간 방송 입력 Flutter 앱. 테이블당 1개 실행 |
| **FastAPI** | Python 기반 웹 서버 프레임워크. BO 서버 구현에 사용 |

---

## 방향별 인증 2-스택 (2026-04-15 G5)

EBS 는 **2가지 독립된 인증 스택**을 운영한다. 방향별 프로토콜·TTL·자격증명이 다르며, 구현도 분리된다.

| 방향 | 프로토콜 | 자격증명 | 토큰 TTL | 구현 |
|------|---------|---------|---------|------|
| **내부 UI → BO** (Lobby, CC) | JWT Bearer | email + password + TOTP(옵션) | Access 1~12h / Refresh 48h (환경별 차등, CCR-006/048) | `src/security/jwt.py` (기존) |
| **BO → WSOP LIVE (outbound)** | OAuth 2.0 client_credentials | Basic base64(client_id:secret) | access_token `expires_in` 그대로 (보통 3600s). 만료 30초 전 선제 재발급 | `team2-backend/src/adapters/wsop_auth.py` (2026-04-15 신설) |

### Outbound 요청 플로우 (BO → WSOP LIVE)

```
1. BO → WSOP Auth URL:
   POST /auth/token?grant_type=client_credentials
   Authorization: Basic base64(CLIENT_ID:CLIENT_SECRET)

2. WSOP 응답:
   { access_token, token_type: "Bearer", expires_in: 3600 }

3. BO 캐시:
   in-memory (per-worker). expires_at = now + expires_in.
   재발급 임박(30초 전) 시 자동 갱신 (asyncio.Lock 보호).

4. WSOP LIVE API 호출:
   GET /Series/{id}/Events
   Authorization: Bearer <access_token>
```

### 환경변수

| 변수 | 용도 |
|------|------|
| `WSOP_LIVE_AUTH_URL` | 토큰 발급 엔드포인트 전체 URL |
| `WSOP_LIVE_CLIENT_ID` | OAuth client_id |
| `WSOP_LIVE_CLIENT_SECRET` | OAuth client_secret (secret manager 권장) |

> Phase 1 (mock) 은 환경변수 미설정 허용. `wsop_sync_service` 가 mock 데이터를 사용할 때 auth 호출을 생략. Phase 2 실통합 시 위 3개 변수 필수.

### 캐시 정책

- **per-worker 메모리 캐시** — Redis 공유 불필요. OAuth client_credentials 는 stateless 이므로 각 워커가 독립 발급해도 정합.
- **asyncio.Lock** 으로 동시 재발급 race 방지 (하나의 워커 내에서).
- 만료 임박(30초 전) 선제 재발급 → 요청 경계에서 만료된 토큰 사용 방지.

### 영향 받는 영역

| 영역 | 영향 | 담당팀 |
|------|------|-------|
| `team1-frontend` Lobby 인증 | 영향 없음 (내부 JWT 스택 유지) | team1 |
| `team4-cc` CC 인증 | 영향 없음 (Lobby-Only Launch 토큰 전달) | team4 |
| `team2-backend` BO | **outbound 호출부만 신규** (`src/adapters/wsop_auth.py` + `src/services/wsop_sync_service.py` 에서 사용) | team2 |

---

## 트리거

| 트리거 | 발동 주체 | 설명 |
|--------|----------|------|
| **로그인** | 사용자 (수동) | Lobby에서 email + password 입력 (CC는 독립 로그인 없음) |
| **로그아웃** | 사용자 (수동) | 메뉴에서 로그아웃 선택 |
| **세션 만료 — Access Token** | 시스템 (자동) | 환경별 Access TTL 경과 → 자동 Refresh 시도 (만료 5분 전 선제 갱신). 상세: `## Session & Token Lifecycle` |
| **세션 만료 — Refresh Token** | 시스템 (자동) | 환경별 Refresh TTL(기본 48h, CCR-048) 경과 → 로그인 화면 리다이렉트 |
| **재인증** | 시스템 (자동) | 네트워크 복구, 앱 재시작 시 토큰 갱신 |
| **강제 로그아웃** | Admin (수동) | Admin이 사용자 비활성화 → 다음 토큰 갱신 시 차단 |
| **비밀번호 변경** | 사용자/Admin (수동) | 모든 Refresh Token 무효화 → 전 기기 재로그인 |
| **역할 변경** | Admin (수동) | 현재 토큰 무효화 → 새 토큰 발급 필요 |

---

## 전제조건

| 조건 | 상세 |
|------|------|
| BO 서버 가동 | FastAPI(Python 웹 서버 프레임워크) 서버 실행 중, DB 연결 정상 |
| 계정 존재 | Admin이 `POST /users`(사용자 생성 API)로 사용자를 사전 생성 |
| 계정 활성 상태 | `is_active = true` |
| 네트워크 연결 | Lobby(웹): 브라우저→BO HTTP / CC(Flutter): Lobby Launch → BO HTTP |

---

## 유저 스토리

### 인증 전체 흐름 (시각화)

아래 표는 로그인부터 CC 진입까지의 전체 흐름을 단계별로 보여준다.

| 단계 | 누가 | 무엇을 | 결과 |
|:----:|------|--------|------|
| 1 | 사용자 | Lobby에서 email + password 입력 | BO에 로그인 요청 |
| 2 | BO 서버 | 자격 증명 검증 | 성공 → JWT 토큰 발급 / 실패 → 에러 |
| 3 | BO 서버 | 2FA 활성 여부 확인 | 활성 → TOTP 코드 요청 / 비활성 → 토큰 즉시 발급 |
| 4 | 사용자 | (2FA 시) Authenticator 앱의 6자리 코드 입력 | 검증 성공 → 최종 토큰 발급 |
| 5 | Lobby | 이전 세션 확인 | 있음 → "Continue/Change" 선택 / 없음 → Series 선택 |
| 6 | 사용자 | 테이블 선택 → [Launch CC] 클릭 | one_time_token(1회용 인증 코드) 생성 |
| 7 | CC 앱 | one_time_token으로 BO에 교환 요청 | CC 전용 JWT 토큰 발급 |
| 8 | CC 앱 | 자체 토큰으로 게임 진행 | Lobby와 독립 세션 |

### 로그인

| # | As a | When | Then | Edge Case |
|:-:|------|------|------|-----------|
| A-01 | Admin | Lobby에서 email + password 입력 | JWT 토큰 발급 → Lobby 메인 화면 진입 | 2FA 활성 시: TOTP 코드 추가 입력 |
| A-02 | Operator | Lobby Table 화면에서 할당 테이블의 [Launch CC] 클릭 | CC Flutter 앱 실행, launch token + table_id 전달 → CC 진입 | 할당 테이블 없음: [Launch CC] 버튼 비활성화 |
| A-03 | Viewer | Lobby에서 email + password 입력 | JWT 토큰 발급 → 읽기 전용 Lobby 진입 | 쓰기 버튼 비활성화 상태로 렌더링 |
| A-04 | Admin | Lobby Table 화면에서 모든 테이블의 [Launch CC] 클릭 | CC Flutter 앱 실행, launch token + table_id 전달 → CC 진입 | 동시 여러 테이블 CC Launch 가능 (각각 별도 인스턴스) |

### 인증 실패

| # | As a | When | Then | Edge Case |
|:-:|------|------|------|-----------|
| A-05 | 모든 역할 | 잘못된 비밀번호 입력 | `AUTH_INVALID_CREDENTIALS` (401) → "사용자명 또는 비밀번호가 일치하지 않습니다" | 사용자명/비밀번호 중 어느 것이 틀렸는지 구분하지 않음 (보안) |
| A-06 | 모든 역할 | 10회 연속 비밀번호 실패 (CCR-048) | `AUTH_ACCOUNT_LOCKED` (403) → 자동 영구 잠금 | 잠금 해제: Admin 수동 해제 (`is_locked=false`). 상세: §자동 잠금 정책 |
| A-07 | 모든 역할 | 비활성 계정으로 로그인 시도 | `AUTH_ACCOUNT_DISABLED` (403) → "비활성 계정입니다. 관리자에게 문의하세요" | Admin이 `PUT /users/{id}` → `is_active = true`로 복구 |

### 세션 관리

| # | As a | When | Then | Edge Case |
|:-:|------|------|------|-----------|
| A-08 | 모든 역할 | Access Token 환경별 TTL 만료 (dev 1h / prod 2h / **live 12h**) | 클라이언트가 만료 5분 전 자동으로 `POST /auth/refresh`(토큰 갱신 API) → 새 Access Token | Refresh 실패 시 로그인 화면 리다이렉트. WebSocket은 끊지 않고 `reauth` 커맨드로 유지 |
| A-09 | 모든 역할 | Refresh Token TTL(dev 24h / staging·prod·live 48h, CCR-048) 만료 | 로그인 화면 리다이렉트, 세션 데이터는 서버에 보존 | 재로그인 시 세션 복원 다이얼로그 표시 |
| A-20 | 모든 역할 | 브라우저를 닫았다가 Lobby URL 재방문 | `GET /auth/session`으로 서버 토큰 검증 → 유효: 이전 화면 유지 / 만료: `logout()` → 로그인 화면 리다이렉트 | localStorage에 토큰이 있어도 서버 검증 없이 Lobby 진입 금지 |
| A-21 | 모든 역할 | 유효한 세션 상태에서 로그인 페이지(`/login`) 직접 접근 | `GET /auth/session` 성공 → 자동으로 `/series`로 리다이렉트 | 로그인 폼 표시 금지 (이미 인증된 상태) |
| A-10 | Operator | Lobby에서 CC Launch 시 | Lobby가 one_time_token(1회용 인증 코드) 생성 → CC 실행 파라미터로 전달 → CC가 token exchange로 자체 JWT 발급 | one_time_token 유효기간 5분. 만료 시 CC 종료, Lobby에서 재Launch 필요 |

### 연결 끊김·복원

| # | As a | When | Then | Edge Case |
|:-:|------|------|------|-----------|
| A-11 | Operator | CC에서 BO 연결 끊김 | Access Token 유효 기간 동안 로컬 캐시 모드로 게임 진행 | 캐시 모드에서 생성된 핸드는 연결 복구 시 BO에 동기화 |
| A-12 | 모든 역할 | 네트워크 복구 후 Access Token 만료 상태 | Refresh Token으로 자동 갱신 시도 → 성공 시 세션 복원 | Refresh Token도 만료: 재로그인 필요 |

### 역할·계정 변경

| # | As a | When | Then | Edge Case |
|:-:|------|------|------|-----------|
| A-13 | Admin | Operator의 역할을 Viewer로 변경 | 해당 Operator의 모든 토큰 무효화 → 다음 API 호출 시 재로그인 | 진행 중인 핸드가 있으면: 핸드 완료 후 적용 (CC 로컬 캐시) |
| A-14 | Admin | 사용자 비활성화 | `is_active = false` → 해당 사용자의 모든 Refresh Token 블랙리스트 → WebSocket 연결 종료 | 마지막 Admin 비활성화 시도: 시스템이 차단 (최소 Admin 1명 보장) |

### 2FA (2단계 인증)

| # | As a | When | Then | Edge Case |
|:-:|------|------|------|-----------|
| A-15 | Admin | 2FA 초기 설정 (`POST /auth/2fa/setup`) | QR 코드 반환 → Authenticator 앱에 등록 → 확인 코드 검증 | 설정 중 취소: 2FA 미활성 상태 유지 |
| A-16 | 모든 역할 | 2FA 활성 계정으로 로그인 시 | 1차 인증 성공 → `requires_2fa: true` + `temp_token` 반환 → TOTP 코드 입력 → 최종 토큰 발급 | TOTP 코드 불일치: 401, 3회 실패 시 30초 대기 |
| A-17 | Admin | 사용자의 2FA 비활성화 (`POST /auth/2fa/disable`) | 해당 사용자의 `totp_enabled = false`, `totp_secret` 초기화 | 본인 2FA 비활성화: Admin만 가능 |

### 비밀번호 재설정

| # | As a | When | Then | Edge Case |
|:-:|------|------|------|-----------|
| A-26 | 모든 역할 | 로그인 화면에서 "Forgot Password?" 클릭 | 이메일 입력 다이얼로그 표시 → 등록된 이메일이면 재설정 링크 발송 | 미등록 이메일: 동일 메시지 표시 (보안 — 계정 존재 여부 노출 방지) |
| A-27 | 모든 역할 | 재설정 링크(이메일) 클릭 | 새 비밀번호 입력 화면 → 비밀번호 변경 완료 → 로그인 화면 리다이렉트 | 링크 만료(1시간): "링크가 만료되었습니다. 다시 요청하세요" |
| A-28 | 모든 역할 | 비밀번호 변경 완료 | 모든 기기의 Refresh Token 무효화 → 새 비밀번호로 재로그인 필요 | 진행 중 CC: 핸드 완료 후 로컬 캐시 유지, 다음 토큰 갱신 시 재로그인 |
| A-29 | Admin | 다른 사용자의 비밀번호 강제 재설정 | `PUT /users/{id}/password` → 해당 사용자 모든 토큰 무효화 | 마지막 Admin 비밀번호 강제 재설정: 허용 (본인 재로그인으로 복구) |

### 로그아웃

| # | As a | When | Then | Edge Case |
|:-:|------|------|------|-----------|
| A-18 | 모든 역할 | 메뉴에서 로그아웃 선택 | `DELETE /auth/session` → Refresh Token 블랙리스트 → WebSocket 종료 → 로그인 화면 | 오프라인 상태에서 로그아웃: 로컬 토큰 삭제, 서버 측은 다음 접속 시 처리 |
| A-19 | Admin | 다른 사용자를 강제 로그아웃 | 해당 사용자 비활성화 → 모든 토큰 무효화 → WebSocket 강제 종료 | CC에서 핸드 진행 중: 핸드 완료까지 로컬 캐시 유지 후 종료 |

### 동시 세션·대회 비밀번호

| # | As a | When | Then | Edge Case |
|:-:|------|------|------|-----------|
| A-20 | 모든 역할 | 다른 기기에서 동일 계정으로 로그인 | 최대 동시 세션 2개 (1 Lobby + 1 CC). 초과 시 이전 세션 무효화 | 같은 유형(Lobby+Lobby) 로그인: 이전 Lobby 세션 무효화 |
| A-21 | Operator | 대회 진입 비밀번호가 설정된 Event 접근 시 | Event 비밀번호 입력 다이얼로그 표시 → 일치 시 접근 허용 | 비밀번호 불일치: Event 목록으로 복귀, 재시도 제한 없음 |

### 세션 복원

| # | As a | When | Then | Edge Case |
|:-:|------|------|------|-----------|
| A-22 | 모든 역할 | 재로그인 시 이전 세션 데이터 존재 | 복원 다이얼로그: "Continue (마지막 테이블)" / "Change (새로 선택)" | 세션 데이터 없음 (첫 접속): Series 선택부터 시작 |
| A-23 | Admin | 세션 복원 시 마지막 테이블이 삭제된 경우 | "테이블이 삭제되었습니다" 안내 → Flight 목록으로 이동 | Series/Event/Flight도 삭제: Lobby 4화면 탐색부터 시작 |
| A-24 | Operator | 세션 복원 시 할당 테이블이 변경된 경우 | 새 할당 테이블 목록 표시 → 선택 후 CC 진입 | 할당 테이블 0개: "테이블 미할당" 안내 |
| A-25 | 모든 역할 | Lobby 재로그인 시 이전 CC 세션 존재 | 세션 복원 다이얼로그에서 "Continue" 선택 시 해당 테이블로 이동 + [Launch CC] 자동 표시 | CC 직접 복원 불가 — Lobby에서 테이블 선택 후 재Launch 필요 |

---

## 경우의 수 매트릭스

### 역할 × 화면 × 접근 가능 여부

| 역할 | Lobby | CC | Settings |
|------|:-----:|:--:|:--------:|
| **Admin** | 전체 CRUD | 모든 테이블 Launch 가능 | 전체 CRUD |
| **Operator** | 할당 테이블 읽기 | 할당 테이블만 Launch 가능 | 접근 불가 (403) |
| **Viewer** | 읽기 전용 | Launch 불가 (읽기 전용) | 접근 불가 (403) |

### 역할 × 리소스 × 권한 (비트값·CRUD 통합)

| 리소스 | Admin | Operator(할당) | Operator(타) | Viewer |
|--------|:-----:|:--------------:|:------------:|:------:|
| Series / Event / Flight | 7 (CRUD) | 1 (R) | 1 (R) | 1 (R) |
| Table | 7 (CRUD) | 3 (RW) | 1 (R) | 1 (R) |
| Seat / Player | 7 (CRUD) | 7 (CRUD) | 1 (R) | 1 (R) |
| Hand | 7 (CRUD) | 3 (CR) | 1 (R) | 1 (R) |
| Settings.Rules / Outputs | 7 (CRUD) | 3 (RW) | 1 (R) | 1 (R) |
| Settings.GFX / Display | 7 (CRUD) | 1 (R) | 1 (R) | 1 (R) |
| BlindStructure | 7 (CRUD) | 1 (R) | 1 (R) | 1 (R) |
| User (계정) | 7 (CRUD) | 1 (R, 본인만) | 1 (R, 본인만) | 1 (R, 본인만) |
| Graphic Editor (BS-08) | 7 (CRUD) | 1 (R) | 1 (R) | **0** (차단) |

> 비트: `1`=Read, `2`=Write, `4`=Delete, 조합: `3`=RW, `7`=RWD(전체). 상세: `## Permission Bit Flag`

### 세션 상태 × 인증 상태 × 시스템 반응

| 세션 상태 | Access Token | Refresh Token | 시스템 반응 |
|----------|:-----------:|:------------:|-----------|
| 정상 | 유효 | 유효 | API 정상 처리 |
| Access 만료 | 만료 | 유효 | 자동 Refresh → 새 Access Token 발급 |
| 전체 만료 | 만료 | 만료 | 로그인 화면 리다이렉트 |
| 강제 무효화 | 유효/만료 | 블랙리스트 | 즉시 로그아웃 + 로그인 화면 |
| 네트워크 단절 | 유효 | 유효 | Lobby: 읽기 전용 / CC: 로컬 캐시 모드 |
| 네트워크 단절 | 만료 | 유효 | 복구 시 Refresh 시도 |
| 네트워크 단절 | 만료 | 만료 | 복구 시 재로그인 필요 |
| 계정 비활성화 | 유효 | 유효 | 다음 Refresh 시 `AUTH_ACCOUNT_DISABLED` |
| 역할 변경됨 | 유효 | 유효 | 현재 토큰 무효화 → 재로그인 시 새 역할 반영 |

### 인증 흐름 단계별 분기

| 단계 | 정상 | 실패 | 분기 조건 |
|:----:|------|------|----------|
| 1. credential 전송 | 200 OK | 401 Invalid / 403 Locked / 403 Disabled | email+password 검증 |
| 2. 2FA 확인 | `requires_2fa: false` → 토큰 발급 | `requires_2fa: true` → 3단계 | `totp_enabled` 여부 |
| 3. TOTP 검증 | 200 OK → 토큰 발급 | 401 Invalid TOTP | 6자리 코드 일치 |
| 4. 세션 복원 확인 | 이전 세션 존재 → 복원 다이얼로그 | 이전 세션 없음 → 기본 화면 | `user_sessions` 테이블 조회 |
| 5. 화면 진입 | 역할별 화면 렌더링 | 권한 부족 → 403 | `role` 클레임 |

### WebSocket(실시간 양방향 통신) 채널별 인증 권한

| 채널 | Admin | Operator | Viewer | 인증 방식 |
|------|:-----:|:--------:|:------:|----------|
| `table:{id}` | 모든 테이블 구독 | 할당 테이블만 | 모든 테이블 (읽기) | Access Token으로 WebSocket 핸드셰이크 |
| `config` | 구독 가능 | 구독 가능 | 구독 불가 | 역할 확인 |
| `monitor` | 구독 가능 | 구독 불가 | 구독 가능 (읽기) | 역할 확인 |

### 동시 세션 정책 상세

| 정책 | 값 | 설명 |
|------|:--:|------|
| 최대 동시 세션 | 2 | 1 Lobby + 1 CC |
| 동일 유형 중복 | 이전 세션 무효화 | Lobby+Lobby → 이전 Lobby 세션 종료 |
| 세션 비활동 타임아웃 | 4시간 | 방송 중에는 하트비트로 유지 |
| 하트비트 간격 | 30초 | WebSocket ping/pong |
| 세션 데이터 보존 | 서버 측 영구 보존 | 로그아웃/만료 후에도 복원용 데이터 유지 |

> **CC 세션 생성**: CC 세션은 Lobby의 [Launch CC]로만 생성된다. CC에서 직접 로그인하여 세션을 생성할 수 없다.

### JWT 만료 정책 (CCR-006)

> **근거**: WSOP Staff App `Auth.md` 의 `expires_in: 43200초(12h)` 운영 기준. 14-16시간 연속 방송 시나리오에서 짧은 Access Token은 과도한 refresh 오버헤드와 WebSocket 재연결 리스크를 유발한다. 환경별 프로파일로 보안/편의를 절충한다.

#### 환경별 만료 정책

| 환경 | Access | Refresh | 근거 |
|------|--------|---------|------|
| dev | 1h | 24h | 개발 편의 |
| staging | 2h | 48h (CCR-048) | QA 테스트 세션 |
| prod(방송 외) | 2h | 48h (CCR-048) | 사무/관리 세션 |
| **prod(live 방송)** | **12h** | **48h (CCR-048)** | WSOP Staff App 준거. 14-16h 연속 방송 중 재인증 최소화 |

환경 플래그는 BO 설정 `AUTH_PROFILE=dev|staging|prod|live` 로 제어한다. 본 문서 상단의 "Access Token 15분" 기술은 과거 초안이며 실제 운영 기준은 위 표를 따른다.

#### 토큰 갱신 규칙

| 항목 | 규칙 |
|------|------|
| 자동 refresh 시점 | 클라이언트는 Access 만료 5분 전 자동 refresh 시도 |
| Refresh 실패 | Refresh Token 만료/무효 → 즉시 로그아웃 → Lobby 로그인 화면 |
| Refresh 성공 | 새 Access Token으로 교체, WebSocket 연결은 유지 (끊지 않음) |

#### WebSocket 재연결 interplay

| 상황 | 동작 |
|------|------|
| 최초 연결 | Access Token 검증 (URL query `token`) |
| 연결 중 Access 만료 | BO는 연결을 끊지 않고 `token_expiring` 이벤트 발행 → 클라이언트가 refresh 후 `reauth` 커맨드 전송 |
| `reauth` 미수신 60초 경과 | BO가 연결 강제 종료 |

#### 강제 무효화

| 트리거 | 동작 |
|--------|------|
| 관리자 비밀번호 변경 | 해당 사용자의 모든 Refresh Token blacklist |
| 역할 박탈 | Refresh Token blacklist → 다음 refresh 시 `AUTH_ACCOUNT_DISABLED` |
| 수동 kick | Refresh Token blacklist + WebSocket 연결 즉시 종료 |
| Access Token 처리 | 짧은 수명으로 자연 무효화 대기 (stateless) |
| live 환경(12h) 최적화 | Redis `blacklist:jti:{jti}` 캐시로 blacklist 조회 성능 보장 |

### Audit 이벤트 매트릭스

| 이벤트 | 기록 대상 | Audit Log 필드 |
|--------|----------|---------------|
| 로그인 성공 | `user_id`, `ip`, `app` (lobby/cc) | `action: LOGIN_SUCCESS` |
| 로그인 실패 | `username` (입력값), `ip`, `reason` | `action: LOGIN_FAILED` |
| 계정 잠금 | `user_id`, `ip`, `failed_count: 5` | `action: ACCOUNT_LOCKED` |
| 로그아웃 | `user_id`, `session_duration` | `action: LOGOUT` |
| 토큰 갱신 | `user_id` | `action: TOKEN_REFRESHED` |
| 역할 변경 | `user_id`, `old_role`, `new_role`, `changed_by` | `action: ROLE_CHANGED` |
| 계정 비활성화 | `user_id`, `disabled_by` | `action: ACCOUNT_DISABLED` |
| 2FA 설정/해제 | `user_id`, `2fa_enabled: true/false` | `action: 2FA_CHANGED` |
| 강제 세션 종료 | `user_id`, `terminated_by` | `action: SESSION_TERMINATED` |
| CC Launch | `user_id`, `table_id`, `one_time_token` 해시 | `action: CC_LAUNCHED` |
| CC Launch Token 만료 | `user_id`, `token_hash`, `elapsed_time` | `action: CC_LAUNCH_TOKEN_EXPIRED` |
| 비밀번호 재설정 요청 | `email` (입력값), `ip` | `action: PASSWORD_RESET_REQUESTED` |
| 비밀번호 재설정 완료 | `user_id`, `ip` | `action: PASSWORD_RESET_COMPLETED` |

### 앱별 토큰 저장·갱신 비교

| 항목 | Lobby (웹) | CC (Flutter) |
|------|-----------|-------------|
| Access Token 저장 | JavaScript 메모리 (XSS(웹 스크립트 공격) 방지) | Secure Storage(Flutter 보안 저장소) |
| Refresh Token 전달 | dev/staging/prod: JSON body `refresh_token` 필드. **live**: `Set-Cookie: refresh_token=...; HttpOnly; Secure; SameSite=Strict; Path=/auth/refresh` 헤더로 전달 (JSON body의 `refresh_token`은 빈 문자열) | Secure Storage(Flutter 보안 저장소) — Cookie 방식 영향 없음 |
| 자동 갱신 | 만료 전 자동 호출 | 포그라운드 시 만료 2분 전 갱신 |
| 오프라인 동작 | 읽기 전용 (캐시된 데이터) | 로컬 캐시 모드 (게임 진행 가능) |
| 다중 탭/인스턴스 | `BroadcastChannel API`(브라우저 탭 간 데이터 공유 API)로 토큰 공유 | 단일 인스턴스 |
| WebSocket 재연결 | 새 Access Token으로 재인증 | 새 Access Token으로 재인증 |

---

## Phase별 인증 방식

| Phase | 인증 방식 | 2FA | 비고 |
|:-----:|----------|:---:|------|
| **1** | Email + Password + TOTP | O | 자체 인증 |
| 2 | + Google OAuth(외부 계정 로그인) | Google 자체 | 외부 IdP(인증 대행 서비스) 연동 |
| 3+ | + Entra ID(Microsoft 기업 인증 서비스) (Azure AD) | Entra 자체 | 기업 SSO(통합 로그인) |

> Phase 1-2에서는 Admin 1명이 모든 화면을 조작한다. Phase 3+에서 Operator를 테이블별로 배치한다.

### 초기 계정 부트스트랩

| 단계 | 동작 | 비고 |
|:----:|------|------|
| 1 | BO 최초 실행 시 환경 변수에서 초기 Admin 계정 생성 | `EBS_ADMIN_EMAIL`, `EBS_ADMIN_PASSWORD` |
| 2 | 초기 Admin이 Lobby에서 로그인 | 초기 비밀번호 변경 강제 |
| 3 | Admin이 추가 사용자(Operator, Viewer) 생성 | `POST /users` |
| 4 | Admin이 Operator에게 테이블 할당 | `PUT /users/{id}/tables` |

### CC Launch 인증 전달 상세

**CC는 Lobby에서만 Launch 가능하다.** CC 자체 로그인 화면은 존재하지 않으며, 아래 흐름으로만 CC에 진입한다:

| 단계 | Lobby 동작 | CC 동작 |
|:----:|-----------|--------|
| 1 | CC Launch 버튼 클릭 → Launch URL 생성 | — |
| 2 | URL에 `table_id` + `one_time_token` 포함 | — |
| 3 | — | CC 앱 시작 → `one_time_token`으로 `POST /auth/exchange` |
| 4 | — | BO가 one_time_token 검증 → JWT 토큰 쌍 발급 |
| 5 | — | CC가 자체 토큰으로 BO에 독립 인증 |

> **핵심**: CC는 Lobby와 토큰을 공유하지 않는다. One-time token 교환으로 별도 JWT 세션을 생성한다.

---

## Permission Bit Flag (CCR-017)

WSOP LIVE parity를 위해 문자열 역할과 **별도로** 비트 플래그로 리소스별 세분화된 권한을 표현한다. 기존 코드는 `role` 문자열을, 신규 코드는 `permission` 비트를 사용해 점진 마이그레이션한다.

### 비트 정의

```
None   = 0   // 접근 차단
Read   = 1   // 조회
Write  = 2   // 생성/수정
Delete = 4   // 삭제
```

| 값 | 2진 | 의미 |
|---:|-----|------|
| 0 | 000 | None (접근 차단) |
| 1 | 001 | Read only |
| 3 | 011 | Read + Write |
| 7 | 111 | Read + Write + Delete (full) |

### 판정 코드

```typescript
// 올바른 사용 — 비트 연산
if ((user.permission & Permission.Write) !== 0) showEditButton();

// 금지 — 폐기된 문자열 비교
// if (user.role === 'admin' || user.role === 'operator') { ... }
```

### 서버 판정 로직

```python
def compute_permission(user: User, resource: str) -> int:
    if user.role == "admin":
        return 7  # full
    if user.role == "operator":
        if is_own_table_resource(user, resource):
            return TABLE_RESOURCE_PERMISSIONS[resource]  # 위 매트릭스 참조
        return 1  # 타 테이블 = read only
    if user.role == "viewer":
        return 0 if resource == "graphic_editor" else 1
    return 0
```

### 마이그레이션 단계

| Phase | 내용 |
|:-----:|------|
| 1 | JWT payload에 `permission` 정수 필드 추가 (기존 코드 영향 없음) |
| 2 | 클라이언트 UI 게이트 → 비트 연산으로 교체 |
| 3 | 서버 권한 판정 → 비트 기반 전환 |
| 4 | `role` 문자열은 로깅·표시 용도만 유지 |

---

## Session & Token Lifecycle (CCR-006)

> **근거**: WSOP Staff App `Auth.md` 의 `expires_in: 43200초(12h)` 기준을 참조하여, 14-16시간 연속 방송 시나리오에서 과도한 refresh 오버헤드와 WebSocket 재연결 리스크를 피하고, 동시에 사무/개발 환경의 짧은 노출 창을 보장한다. Phase별·환경별로 차등 적용한다.

### 1. 만료 정책 (환경별 차등)

| 환경 | Access Token | Refresh Token | 근거 |
|------|:------------:|:-------------:|------|
| `dev` | 1h | 24h | 개발 편의, 재인증 빈번 허용 |
| `staging` | 2h | 48h (CCR-048) | QA 테스트 세션 연속성 |
| `prod` (방송 외) | 2h | 48h (CCR-048) | 사무/관리 세션 |
| **`live`** (방송 운영) | **12h** | **48h (CCR-048)** | WSOP Staff App 준거. 14-16h 연속 방송 중 재인증 최소화 |

**환경 플래그**: BO 설정 `AUTH_PROFILE=dev|staging|prod|live`로 제어. 기본값 `prod`.

> **주의**: 기존 경우의 수 매트릭스(A-08, A-09)의 "Access 15분 / Refresh 7일" 문구는 `prod` 기본값 기준이 아닌 초기 초안 값이다. 본 섹션이 **SSOT**이며, 해당 매트릭스는 CCR-006 후속 정리 대상.

### 2. 토큰 갱신 규칙

| 규칙 | 동작 |
|------|------|
| 자동 refresh | 클라이언트는 Access 만료 **5분 전** 자동 `POST /auth/refresh` 시도 |
| Refresh 실패 | 만료/무효 시 즉시 로그아웃 → Lobby 로그인 화면 리다이렉트 |
| Refresh 성공 | 새 Access로 교체. WebSocket 연결은 **끊지 않음** |
| Access Token 저장 | Lobby: JavaScript 메모리 / CC: Flutter Secure Storage |
| Refresh Token 전달 | 환경별 조건부 — 아래 상세 참조 |

환경별 Refresh Token 전달 방식:
- dev / staging / prod: JSON body `refresh_token` 필드로 전달
- **live (방송 운영)**: `Set-Cookie: refresh_token=...; HttpOnly; Secure; SameSite=Strict; Path=/auth/refresh` 헤더로 전달. JSON body의 `refresh_token` 필드는 빈 문자열.

클라이언트 대응:
- Lobby (웹): live 환경에서 `credentials: 'include'` fetch 옵션 필수
- CC (Flutter): Secure Storage에 refresh_token 직접 저장 (Cookie 방식 영향 없음)
- `refresh_token_delivery` 응답 필드(`"body"` 또는 `"cookie"`)로 현재 전달 방식 확인 가능 (API-06 참조)

### 3. WebSocket 재연결 Interplay

| 단계 | BO 동작 | 클라이언트 동작 |
|:----:|---------|----------------|
| 1 | 최초 연결 시 Access 토큰 검증 (`?token=` query param, API-05 §1.3) | — |
| 2 | 토큰이 연결 중 만료되면 **연결을 끊지 않고** `token_expiring` 이벤트 발행 | — |
| 3 | — | `POST /auth/refresh` → 새 Access 취득 |
| 4 | `reauth` 커맨드 수신 → 새 토큰으로 세션 권한 갱신 | `reauth` 커맨드 전송 (envelope `type: "ReauthCommand"`) |
| 5 | `reauth` 미수신 **60초** 경과 시 연결 강제 종료 | 재접속 필요 |

### 4. 강제 무효화

| 트리거 | 동작 | 비고 |
|--------|------|------|
| 관리자 비밀번호 변경 | 해당 사용자의 모든 Refresh Token을 DB blacklist | Access는 짧은 수명으로 자연 무효화 대기 |
| 역할 박탈/강등 | Refresh blacklist + WebSocket 연결 종료 | 다음 API 호출 시 403 |
| Admin 수동 kick | Refresh blacklist + 현재 Access도 `jti` blacklist 등록 | `live` 환경(12h) 필수 |
| `live` 환경 blacklist 저장소 | Redis `blacklist:jti:{jti}` 캐시 (TTL=Access 잔여) | 성능 핵심, Phase 3+ 구현 |

### 5. API-06 응답 필드 (CCR-006)

`POST /auth/login`, `POST /auth/refresh` 응답 JSON에 다음 필드를 포함한다.

| 필드 | 타입 | 설명 |
|------|------|------|
| `access_token` | string | JWT Access Token |
| `refresh_token` | string | JWT Refresh Token. dev/staging/prod: 값 포함. **live**: 빈 문자열 (HttpOnly Cookie로 전달) |
| `refresh_token_delivery` | string | `"body"` 또는 `"cookie"` — 현재 환경의 Refresh Token 전달 방식 |
| `expires_in` | int (seconds) | Access Token 유효 기간 (`AUTH_PROFILE`에 따라 3600~43200) |
| `expires_at` | string (ISO 8601) | Access Token 만료 시각 (절대시간) |
| `refresh_expires_in` | int (seconds) | Refresh Token 유효 기간 (기본 172800 = 48h, CCR-048) |
| `auth_profile` | string | `dev`/`staging`/`prod`/`live` 중 하나 (클라이언트 UX 분기용) |
| `permission` | int | 비트 플래그 기본값 (리소스별 세분화는 API 호출 시 확정). 상세: `## Permission Bit Flag` |
| `assigned_tables` | string[] | Operator 전용. write 가능한 테이블 ID 목록. Admin·Viewer는 빈 배열 |

> 상세 응답 샘플과 에러 코드는 `API-06-auth-session.md §CCR-006` 참조.

---

## 에러 메시지 정의

| 에러 코드 | HTTP | 사용자 노출 메시지 | 내부 로그 |
|----------|:----:|-----------------|----------|
| `AUTH_INVALID_CREDENTIALS` | 401 | "사용자명 또는 비밀번호가 일치하지 않습니다" | 실패 사용자명 + IP |
| `AUTH_ACCOUNT_LOCKED` | 403 | "계정이 잠겼습니다. 관리자에게 잠금 해제를 요청하세요." (CCR-048: 자동 영구 잠금) | 잠금 시각 + 실패 횟수 |
| `AUTH_ACCOUNT_DISABLED` | 403 | "비활성 계정입니다. 관리자에게 문의하세요" | 비활성화 시각 + 비활성화 주체 |
| `AUTH_TOKEN_EXPIRED` | 401 | (자동 Refresh 시도, UI 노출 없음) | 만료 시각 |
| `AUTH_TOKEN_REVOKED` | 401 | "세션이 종료되었습니다. 다시 로그인하세요" | 무효화 사유 |
| `AUTH_TOKEN_INVALID` | 401 | "인증 오류. 다시 로그인하세요" | 서명 불일치 상세 |
| `AUTH_UNAUTHORIZED` | 401 | "로그인이 필요합니다" | 토큰 누락 |
| `AUTH_FORBIDDEN` | 403 | "접근 권한이 없습니다" | 요청 역할 + 요청 엔드포인트 |
| `AUTH_PERMISSION_DENIED` | 403 | "이 작업에 필요한 권한이 없습니다" | `required_permission`, `current_permission`, `resource` 포함 |
| `AUTH_TABLE_NOT_ASSIGNED` | 403 | "할당되지 않은 테이블입니다" | Operator ID + 요청 테이블 ID |
| `AUTH_2FA_INVALID` | 401 | "인증 코드가 올바르지 않습니다" | 실패 횟수 |
| `AUTH_RESET_LINK_EXPIRED` | 401 | "재설정 링크가 만료되었습니다. 다시 요청하세요" | 링크 생성 시각 + 만료 시각 |
| `AUTH_RESET_LINK_USED` | 401 | "이미 사용된 재설정 링크입니다" | 사용 시각 |

---

## 비활성 조건

| 조건 | 영향 | 복구 방법 |
|------|------|----------|
| BO 서버 미실행 | 로그인 불가, 모든 인증 API 응답 없음 | BO 서버 재시작 |
| DB 연결 끊김 | 토큰 검증 불가 → 모든 API 401 | DB 연결 복구 |
| 마지막 Admin 비활성화 시도 | 시스템이 차단 (최소 Admin 1명 보장) | 다른 Admin 계정 생성 후 재시도 |
| Refresh Token 전체 만료 (48h 무접속, CCR-048) | 세션 완전 소멸 → 재로그인 필요 | 재로그인 (세션 데이터는 서버 보존) |
| 비밀번호 10회 연속 실패 (CCR-048) | 자동 영구 계정 잠금 | Admin 수동 해제 |

---

## 2FA Level 정책 (CCR-048, WSOP LIVE GGPass 준거)

> SSOT: Confluence Page 1972863063 (GGPass 4-level 2FA). WSOP LIVE 는 Off/Low/Medium/High 4-단계 정책을 표준화.

| Level | 의미 | 동작 | 적용 범위 |
|:---:|---|---|---|
| 0 (Off) | 비활성 | 비밀번호만 요구 | Phase 1 기본값 |
| 1 (Low) | 알림 | 로그인 성공 시 이메일/SMS 알림 | 신규 기기 감지 |
| 2 (Medium) | 의심 로그인 시 2FA | 새 IP/기기/지역 감지 시 2FA 요구 | 위험 기반 |
| 3 (High) | 모든 로그인 2FA | 매 로그인 TOTP/Email/SMS 요구 | Admin 계정 권장 |

**2FA 방식** (WSOP LIVE 준거):
- Email OTP
- Mobile SMS
- Google OTP (TOTP)
- Trusted Device: 특정 기기 2FA 스킵 가능 (30일). **Phase 1 미구현**, Phase 2 도입.

---

## 자동 잠금 정책 (CCR-048, CCR-052)

> SSOT: Confluence Page 1972863063. WSOP LIVE 는 비밀번호 10회 연속 실패 시 자동 잠금.

- **비밀번호 실패 10회 연속** → `users.is_locked = true`
- **2FA 실패 10회 연속** → 동일 Lock
- **5분 내 토큰 refresh 50회 초과** → 의심 활동, `is_locked=true` + Admin 알림
- 해제 경로: Forgot Password 플로우 또는 Admin 수동 Unlock
- 실패 카운터: `users.failed_login_count`, `users.last_failed_at` (Phase 2 신설)
- 성공 로그인 시 카운터 리셋

> **비고**: "5회 연속 실패 → 30분 잠금" 종전 정책은 레거시. CCR-048 반영 후 10회 실패 자동 잠금으로 상향 정렬.

---

## Refresh Token TTL (CCR-048)

- **48시간** (WSOP LIVE 현행 정책, SSOT Page 2202861710)
- Access Token: 환경별 TTL 유지 (CCR-006)
- Refresh 시 rotation (기존 refresh token 블랙리스트 추가)

> 기존 Refresh TTL 7일 정책은 EBS 초기 값. CCR-048 반영 후 WSOP LIVE 48h 로 정렬한다. 환경별 플래그로 덮어쓸 수 있다.

---

## Rate Limiting 정책 (CCR-052)

> **정렬 기준**:
> - WSOP LIVE: IP whitelist (GGPass, SSOT Page 1975582764) + 비밀번호 10회 실패 자동 잠금 (Page 1972863063)
> - OWASP API Security Top 10 #4 (Unrestricted Resource Consumption)
> - WSOP LIVE 엔드포인트별 수치 정책 부재 → 아래 표는 EBS 독자 정의 (이유: 보안 기본값 명시 필수)

### 엔드포인트 카테고리별 정책

| 카테고리 | 한계치 | 범위 | 실패 응답 | 적용 엔드포인트 예시 |
|---|---|---|---|---|
| **인증 (로그인)** | 5회/분 + 10회 실패 자동 잠금 | per IP + per email | 429 + `Retry-After: 60` | `/auth/login`, `/auth/verify-2fa` |
| **인증 (토큰)** | 10회/분 | per user | 429 + `Retry-After: 60` | `/auth/refresh`, `/auth/logout` |
| **인증 (Password Reset)** | 3회/시간 | per email | 429 + `Retry-After: 3600` | `/auth/password/reset/send` |
| **쓰기 (POST/PUT/DELETE)** | 60회/분 | per user | 429 + `Retry-After: 60` | 전체 RW 엔드포인트 |
| **읽기 (GET)** | 300회/분 | per user | 429 + `Retry-After: 60` | 전체 R 엔드포인트 |
| **WebSocket 메시지** | 100msg/초 | per connection | 연결 종료 + Error 이벤트 | `/ws/cc`, `/ws/lobby` |
| **WebSocket 연결** | 10 connections | per user | 429 connection rejected | 재연결 폭주 방어 |
| **Sync (내부)** | 동시 1 작업 | per entity_type | Skip (lock wait) | 내부 polling worker |

### 응답 헤더 (표준)

| 헤더 | 값 예시 | 설명 |
|---|---|---|
| `X-RateLimit-Limit` | 60 | 카테고리 한계 |
| `X-RateLimit-Remaining` | 12 | 남은 요청 수 |
| `X-RateLimit-Reset` | 1712345678 | Unix timestamp (초) |
| `Retry-After` | 60 | 429 응답 시만 |

### 저장소 전략

| Phase | 저장소 | 근거 |
|---|---|---|
| Phase 1 | in-memory (`slowapi` 또는 custom) | 단일 인스턴스 운영 |
| Phase 2+ | Redis (`SET counter:{key} ... EX ...`) | 다중 인스턴스 horizontal scaling |

### IP Whitelist (Admin 전용)

> WSOP LIVE GGPass External API IP whitelist 패턴 준거. Phase 2+ 에서 특정 Admin 엔드포인트(`/users/*/suspend`, `/users/*/lock`, DB 관리 등)는 사내 VPN IP 대역만 허용. 환경변수 `ADMIN_IP_WHITELIST` 로 관리.

### 관측(Observability)

- `rate_limit_exceeded` 이벤트 → `audit_events` 기록 (event_type, endpoint, user_id, ip, count)
- Prometheus 메트릭 노출: `http_rate_limit_rejected_total{endpoint, reason}`

---

## Provisioning — 유저 생성 전략 (CCR-053, Phase별)

> SSOT: Confluence Page 1597768061. WSOP LIVE Staff App 에는 POST/DELETE 엔드포인트가 없고 외부 조직 시스템이 유저를 provisioning 한다. EBS 는 Phase 단계적 정렬.

| Phase | 유저 생성 방식 | 근거 |
|:---:|---|---|
| Phase 1 (현행) | Admin 수동 + 초기 seed 스크립트 | 조직 통합 전, 소규모 운영 |
| Phase 2 | Google OAuth 자동 생성 (`allowed_email_domains` whitelist) | Vegas 운영, 조직 계정 연동 |
| Phase 3 | WSOP LIVE Staff 단방향 동기화 | 완전 통합 |

---

## Suspend vs Lock 의미 차이 (CCR-053)

> SSOT: Confluence Page 1597768061. WSOP LIVE Staff 는 `isSuspended`, `isLocked` 두 플래그를 독립 관리.

| 항목 | Suspend | Lock |
|---|---|---|
| 트리거 | Admin 수동 결정 | 보안 위반 자동 or Admin 수동 |
| 사유 | 휴가, 일시 부재, 역할 재배치 대기 | 비밀번호 10회 실패, 의심 접근, 징계 |
| 해제 | Admin Un-suspend | Admin Unlock (자동 해제 없음) |
| `is_active` 영향 | 독립 | 독립 |
| 로그인 응답 | 401 `SUSPENDED` | 401 `LOCKED` |
| 동시 적용 | Suspend + Lock 동시 가능 (둘 중 하나라도 true 면 차단) | 동일 |

---

## 영향 받는 요소

| 영향 대상 | 관계 |
|----------|------|
| BS-02 Lobby | 로그인 후 Lobby 진입, 세션 복원 흐름 |
| BS-05 Command Center | CC Launch 시 인증 전달, 오프라인 캐시 모드 |
| API-06 Auth & Session | 이 문서의 API 계약 (JWT, 엔드포인트, 에러 코드) |
| BO-02 User Management | 계정 CRUD, 역할 할당, 비활성화 |
| BO-08 Audit Log | 로그인/로그아웃/역할 변경/잠금 이벤트 기록 |
| Foundation PRD Ch.8 | RBAC 3역할 정의 원본 |
| BS-08-04 rbac-guards | Graphic Editor RBAC 특화 규칙 (Viewer = permission 0) |
