---
title: CR-team1-20260413-google-oauth
owner: conductor
tier: internal
last-updated: 2026-04-15
legacy-id: CCR-DRAFT-team1-20260413-google-oauth
confluence-page-id: 3819275384
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819275384/EBS+CR-team1-20260413-google-oauth
---

# CCR-DRAFT: Google OAuth Phase 1 도입

- **제안팀**: team1
- **제안일**: 2026-04-13
- **영향팀**: [team2]
- **변경 대상 파일**: contracts/specs/BS-01-auth/BS-01-auth.md, contracts/api/`Auth_and_Session.md` (legacy-id: API-06)
- **변경 유형**: add
- **변경 근거**: WSOP LIVE Staff Page 스크린샷에서 Google OAuth 로그인 확인. 설계 원칙 1조 "동일하게 설계할 수 있는 것은 최대한 동일하게" 적용. Phase 2로 보류되어 있었으나 Phase 1에 포함 결정 (사용자 승인 2026-04-13).

## 변경 요약

### 1. BS-01-auth.md 변경

#### A-30 유저스토리 추가

| 시나리오 | A-30 Google OAuth 로그인 |
|---------|------------------------|
| 주체 | Admin / Operator / Viewer |
| 전제 | BO 서버 실행, 사용자 Google 계정이 EBS 계정에 연결됨 |
| 트리거 | 사용자가 [Sign in with Google] 클릭 |
| 플로우 | 1. `GET /auth/google` → Google OAuth consent redirect<br>2. Google 인증 완료 → `GET /auth/google/callback?code=...`<br>3. 서버: Google ID 토큰 검증 → email로 EBS 계정 매칭 → JWT 발급<br>4. 응답은 일반 로그인과 동일: `{ access_token, refresh_token, user, lastContext }`<br>5. 2FA 활성 계정: Google 인증 후에도 TOTP 검증 필요 (temp_token 발급) |
| 성공 | Series 목록 이동 (또는 Session Restore Dialog) |
| 실패 | `AUTH_GOOGLE_NOT_LINKED` (403) — EBS 계정과 매칭되지 않는 Google 계정 |

#### Phase 1 인증 방식 수정

현행: "Phase 1: Email + Password + TOTP"
변경: "Phase 1: Email + Password + TOTP **+ Google OAuth**"

현행: "Phase 2+: Google OAuth"
변경: **삭제** (Phase 1으로 이동)

### 2. `Auth_and_Session.md` (legacy-id: API-06) 변경

#### 신규 엔드포인트 2개

| Method | Path | 설명 | 역할 제한 |
|:------:|------|------|:---------:|
| GET | `/auth/google` | Google OAuth consent URL redirect | 미인증 |
| GET | `/auth/google/callback` | Google OAuth callback (code → JWT) | 미인증 |

#### GET /auth/google

- **동작**: Google OAuth 2.0 consent URL 생성 후 302 redirect
- **Query params**: `redirect_uri` (Lobby callback URL)
- **Response**: 302 → `https://accounts.google.com/o/oauth2/v2/auth?...`

#### GET /auth/google/callback

- **Query params**: `code` (authorization code), `state` (CSRF token)
- **Response 200** (no 2FA):
```json
{
  "access_token": "...",
  "refresh_token": "...",
  "expires_in": 7200,
  "user": { "user_id": 1, "email": "admin@ebs.local", "role": "admin" },
  "requires_2fa": false,
  "lastContext": null
}
```
- **Response 200** (2FA required): `{ "requires_2fa": true, "temp_token": "tmp_..." }`
- **Error 403** (`AUTH_GOOGLE_NOT_LINKED`): Google 계정과 매칭되는 EBS 계정 없음
- **Error 403** (`AUTH_ACCOUNT_DISABLED`): 매칭 계정이 비활성 상태
- **Error 400** (`AUTH_GOOGLE_INVALID_CODE`): 잘못된 authorization code

#### 신규 에러 코드

| 코드 | HTTP | 설명 |
|------|------|------|
| `AUTH_GOOGLE_NOT_LINKED` | 403 | Google 계정과 매칭되는 EBS 계정이 없음 |
| `AUTH_GOOGLE_INVALID_CODE` | 400 | Google authorization code가 유효하지 않음 |

## Diff 초안

### BS-01-auth.md

Phase 1 인증 방식 텍스트에 Google OAuth 추가. A-30 유저스토리 블록 추가. 에러 코드 테이블에 2건 추가.

### `Auth_and_Session.md` (legacy-id: API-06)

엔드포인트 표에 `/auth/google`, `/auth/google/callback` 2행 추가. 응답 스키마 섹션 추가.

## 영향 분석

- **Team 2 (Backend)**: FastAPI에 Google OAuth 2.0 flow 구현 필요 (google-auth-oauthlib 또는 httpx). EBS 계정 테이블에 `google_id` 컬럼 추가. 환경변수 GOOGLE_CLIENT_ID/SECRET 설정.
- **Team 1 (Frontend)**: Login 화면에 [Sign in with Google] 버튼 추가. OAuth redirect 처리. (UI-01 §0 이미 반영)
- **Team 3, 4**: 영향 없음

## 검증 방법

- 단위: Mock Google OAuth provider로 callback 응답 검증
- 통합: Google consent → callback → JWT 발급 → Lobby 진입 전체 플로우
- 에러: 미연결 Google 계정 → AUTH_GOOGLE_NOT_LINKED 403 응답 확인

## 승인 요청

- [ ] Conductor 승인
- [ ] Team 2 기술 검토
