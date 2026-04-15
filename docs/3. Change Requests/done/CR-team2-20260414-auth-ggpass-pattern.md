---
title: CR-team2-20260414-auth-ggpass-pattern
owner: conductor
tier: internal
last-updated: 2026-04-15
legacy-id: CCR-DRAFT-team2-20260414-auth-ggpass-pattern
---

# CCR-DRAFT: 인증 체계 WSOP LIVE GGPass 패턴 정렬

- **제안팀**: team2
- **제안일**: 2026-04-14
- **영향팀**: [team1, team4]
- **변경 대상 파일**: contracts/specs/BS-01-auth/BS-01-auth.md, contracts/api/API-06-auth-session.md
- **변경 유형**: add
- **변경 근거**: WSOP LIVE는 GGPass 통합 SSO(Page 1972863063, 2202861710, 1701380121)를 운영하며 JWT + 3-step Password Reset + 4-level 2FA + 10회 실패 자동 잠금 패턴을 표준화. EBS 현행 BS-01-auth는 일부 요소만 정의, Password Reset API/2FA 레벨/자동 잠금 정책 누락. 정식 전체 개발 단계에서 GGPass 패턴 준거 필요.

## 변경 요약

1. `contracts/api/API-06-auth-session.md` 에 Password Reset 3-step 엔드포인트 추가
2. `contracts/specs/BS-01-auth` 에 2FA 4-level 정책 추가 (Off/Low/Medium/High)
3. `contracts/specs/BS-01-auth` 에 자동 잠금 정책 명시 (10회 연속 실패 → Lock, Forgot Password만 해제)
4. `contracts/specs/BS-01-auth` 에 Refresh Token TTL = 48시간 확정 (WSOP LIVE 정책 준거)
5. Phase별 SSO 전략: Phase 1 자체 JWT, Phase 2 GGPass 통합 검토 (divergence 가능)

## Diff 초안

### contracts/api/API-06-auth-session.md (Password Reset 3-step)

```diff
 ### 5.X Password Reset
+
+> **WSOP LIVE GGPass 대응**: `POST /Password/Reset/Send` → `POST /Verify` → `POST /Password/Reset` (Page 1701380121). EBS도 동일 3-step 구조.
+
+| Method | Path | 설명 | 역할 |
+|:---:|---|---|:---:|
+| POST | `/auth/password/reset/send` | 이메일로 reset 토큰 발송 | 미인증 |
+| POST | `/auth/password/reset/verify` | 토큰 검증 (만료/사용 여부 확인) | 미인증 |
+| POST | `/auth/password/reset` | 새 비밀번호 설정 (토큰 + new_password) | 미인증 |
+
+**POST /auth/password/reset/send — Request:**
+```json
+{ "email": "user@example.com" }
+```
+> 이메일 존재 여부 응답으로 노출 안 함 (enumeration 방어). 항상 200 + 일반 메시지.
+
+**POST /auth/password/reset/verify — Request:**
+```json
+{ "token": "..." }
+```
+> 응답: `{ "valid": true, "expires_at": "..." }` 또는 400 invalid/expired.
+
+**POST /auth/password/reset — Request:**
+```json
+{ "token": "...", "new_password": "..." }
+```
+> 성공 시 모든 활성 세션 무효화(refresh token blacklist). 토큰 1회용(used_at 기록).
+> 토큰 TTL 1시간.
```

### contracts/specs/BS-01-auth/BS-01-auth.md (2FA Level 정책)

```diff
+## 2FA Level 정책 (WSOP LIVE GGPass 준거)
+
+| Level | 의미 | 동작 | 출처 |
+|---|---|---|---|
+| 0 (Off) | 비활성 | 비밀번호만 요구 | Phase 1 기본값 |
+| 1 (Low) | 알림 | 로그인 성공 시 이메일/SMS 알림 | 신규 기기 감지 |
+| 2 (Medium) | 의심 로그인 시 2FA | 새 IP/기기/지역 감지 시 2FA 요구 | 위험 기반 |
+| 3 (High) | 모든 로그인 2FA | 매 로그인 TOTP/Email/SMS 요구 | Admin 계정 권장 |
+
+**2FA 방식** (WSOP LIVE 준거):
+- Email OTP
+- Mobile SMS
+- Google OTP (TOTP)
+- Trusted Device: 특정 기기 2FA 스킵 가능 (30일)
+
+## 자동 잠금 정책
+
+- **비밀번호 실패 10회 연속** → `users.is_locked = true` (WSOP LIVE 준거)
+- 해제 경로: Forgot Password 플로우만 (Admin unlock 병행 허용)
+- 실패 카운터: `users.failed_login_count`, `users.last_failed_at`
+- 성공 로그인 시 카운터 리셋
+
+## Refresh Token TTL
+
+- **48시간** (WSOP LIVE 현행 정책, Page 2202861710)
+- Access Token: 15분 (기존 정책 유지)
+- Refresh 시 rotation (기존 refresh token 블랙리스트 추가)
```

## Divergence from WSOP LIVE (Why)

1. **GGPass SSO 미도입 (Phase 1)**:
   - **Why**: EBS는 초기 단계에서 WSOP 조직 계정 통합 전. Phase 2 Vegas 이후 GGPass 연동 검토. Phase 1은 자체 JWT + 2FA로 운영.
2. **URL 컨벤션**: WSOP `/Password/Reset/Send` → EBS `/auth/password/reset/send`.
   - **Why**: EBS REST 컨벤션(lowercase kebab).
3. **Trusted Device 기능 Phase 1 미구현**:
   - **Why**: Phase 1은 Admin 소수 운영. Phase 2에서 TD 구현.

## 영향 분석

- **Team 1 (Lobby)**:
  - Password Reset 3-step UI 추가 (1일)
  - 2FA 레벨 설정 UI 추가 (1일)
  - 로그인 실패 카운터 응답 처리 (2시간)
- **Team 4 (CC)**:
  - 2FA 챌린지 화면 재사용 (영향 적음)
- **Team 2**:
  - 3 신규 엔드포인트 + SMTP/Email 통합 어댑터
  - failed_login_count, last_failed_at 필드 (Alembic revision)

## 대안 검토

1. **GGPass 즉시 통합**: 탈락. 조직 계약 Phase 2 이후.
2. **Refresh TTL 기본 7일**: 탈락. WSOP LIVE 48시간 원본 존중.
3. **2FA Level 3-단계만 (Off/On/Mandatory)**: 탈락. WSOP LIVE 4-단계 표준 유지.

## 검증

- Password reset 토큰 TTL 경계 테스트 (59분 success, 61분 fail)
- 10회 실패 자동 잠금 테스트 (9→카운터 유지, 10→is_locked=true)
- Refresh token rotation (old token 사용 시 401)
- 2FA Level 2 위험 감지 트리거(새 IP)

## 승인 요청

- [ ] Team 1, 4 기술 검토
- [ ] 리스크 판정

## 참고 출처

| Page ID | 제목 |
|---|---|
| 1972863063 | GGPass - WSOP+ Login (SSO, 2FA 4-level) |
| 2202861710 | MFA 설정 페이지 개발 및 보안 관련 개편 (Refresh TTL 48h) |
| 1701380121 | Staff App Auth API (3-step password reset) |
| 1975582764 | GGPass External API (kickout, deleteRefreshToken) |
