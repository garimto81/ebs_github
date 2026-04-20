---
id: SG-008-b14
title: "Auth 2FA 정책 — Admin/Operator 필수 여부 + provider 선택"
type: spec_gap
sub_type: spec_drift_b_escalated
parent_sg: SG-008-b13
status: RESOLVED
owner: conductor
decision_owners_notified: [team2, team1]
created: 2026-04-20
resolved: 2026-04-20
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "status=RESOLVED, 2FA 정책 default 채택"
---

# SG-008-b14 — Auth 2FA 정책

## 배경

SG-008-b13 triage 에서 `twoFactorEnabled` 필드가 team1 settings provider 에 code-only 로 존재 (D3). SG-008-b13 분류 단계에서 (b) 승격 — 2FA 는 단순 UI 토글이 아닌 **인증 아키텍처 결정**.

## 논점

1. **Admin 필수 여부**: Admin 계정에 2FA 강제할지, 선택적으로 할지?
2. **Provider 선택**: TOTP(Authenticator app) / SMS / Email OTP / hardware key?
3. **Enrollment 플로우**: 최초 로그인 시 강제 등록? 나중에 설정 탭에서?
4. **Recovery**: 백업 코드 / Admin reset 경로
5. **API 영향**: `/auth/login` 응답에 `requires_2fa` 필드, `/auth/verify-2fa` 신규 엔드포인트

## 결정 옵션

| 옵션 | 내용 | 장점 | 단점 |
|------|------|------|------|
| **1. TOTP 필수 (Admin only)** | Admin 계정 TOTP 강제 + Operator/Viewer 선택 | 보안 표준, 오프라인 동작 | 초기 설정 burden, 디바이스 분실 리스크 |
| **2. TOTP 선택 (모든 role)** | Preferences.2FA 토글, default OFF | UX 부담 적음 | Admin 계정 보안 약화 |
| **3. Email OTP 기본 + TOTP 옵션** | 이메일 전송, TOTP 로 upgrade | 인프라 복잡 (SMTP) | 이메일 지연, phishing 취약 |
| **4. 프로토타입 비지원** | 2FA 필드만 보존, 기능 Phase 2+ | 단순 | twoFactorEnabled 필드 의미 없음 |

## Default 제안

**채택: 옵션 1 — TOTP 필수 (Admin only)**

### 세부 결정

1. **Admin 필수**: JWT `role == 'admin'` 이면 로그인 성공 후 TOTP 검증 필수
2. **Operator/Viewer 선택**: Preferences 에서 opt-in
3. **Provider**: TOTP (RFC 6238, `pyotp` 라이브러리)
4. **Enrollment**: 첫 Admin 로그인 시 QR 코드 표시 + 백업 코드 10개 발급
5. **Recovery**: 백업 코드 사용 or 다른 Admin 이 UI 에서 reset (audit 기록)

### 이유

- EBS 는 방송 운영 도구 — Admin 권한 남용 시 방송 사고 직결. 2FA 필수 정당
- TOTP: 온라인 의존 없음, 표준(RFC 6238), `pyotp` 간단 통합
- Operator/Viewer 선택적: UX 부담 완화. Operator 는 IP 화이트리스트 + 세션 timeout 으로 보완
- Phase 2 에서 hardware key (FIDO2/WebAuthn) 추가 검토

### API 영향

`docs/2. Development/2.2 Backend/APIs/Auth_and_Session.md` 추가 사항:

```
POST /api/v1/auth/login
  → 200 + {access_token} (2FA off 또는 verified)
  → 200 + {requires_2fa: true, session_token, role} (2FA 대기 상태)

POST /api/v1/auth/2fa/enroll (Admin 첫 로그인 or opt-in)
  body: {password_confirmation}
  → 200 + {secret, qr_code_base64, backup_codes[10]}

POST /api/v1/auth/2fa/verify
  body: {session_token, totp_code}
  → 200 + {access_token, refresh_token}
  → 401 INVALID_TOTP

POST /api/v1/auth/2fa/backup-code
  body: {session_token, backup_code}
  → 200 + {access_token, refresh_token}

DELETE /api/v1/auth/2fa (opt-out for Operator/Viewer 자기 계정)
  → 204

POST /api/v1/users/{id}/2fa/reset (Admin 만, 다른 사용자 재설정)
  → 204 + audit_event: 2fa_reset
```

### DB 영향

`users` 테이블에 컬럼 추가 (migration 0006 제안):
- `twofa_enabled: bool`
- `twofa_secret: encrypted_str` (AES-GCM)
- `twofa_backup_codes: encrypted_json` (10 × random 10-char)

### Preferences 연동

`twoFactorEnabled` 필드를 **`Preferences §8 Security`** 서브그룹에 편입 (SG-008-b13 에서 Preferences 에 편입 결정).

**UI 동작**:
- Admin: 토글 회색 비활성 + "필수" 라벨 표시
- Operator/Viewer: 토글 동작 + 활성화 시 enrollment flow 진입

## 영향 챕터 업데이트

- [ ] `docs/2. Development/2.2 Backend/APIs/Auth_and_Session.md` — 2FA 섹션 추가 (6 endpoints)
- [ ] `docs/2. Development/2.1 Frontend/Settings/Preferences.md` §8 Security 서브그룹 신규
- [ ] `docs/2. Development/2.5 Shared/Authentication.md` — 2FA role 매트릭스
- [ ] team2 users 테이블 migration 0006
- [ ] team2 src/routers/auth.py — 2FA endpoint handlers
- [ ] team1 lib/features/auth/ — 2FA enrollment + verify screens

## 수락 기준

- [ ] Admin 로그인 시 TOTP 프롬프트 (Preferences.twoFactorEnabled 무관 — 필수)
- [ ] Operator/Viewer 가 Preferences 에서 2FA 활성화 가능
- [ ] QR 코드 + 백업 코드 10개 발급
- [ ] 백업 코드로 recovery 가능
- [ ] Admin 이 다른 사용자 2FA reset (audit_event 기록)
- [ ] `requires_2fa` 응답 후 session_token 으로 TOTP 검증

## Phase 2 확장 (별도 SG)

- FIDO2/WebAuthn hardware key
- Risk-based 2FA (new device, IP 변경 시 강제)
- SMS OTP (이메일 장애 시 fallback)

## 재구현 가능성

- SG-008-b14: **PASS** (본 문서 자립, Auth 팀 세션이 구현 가능)
- team2 Auth 재구현: 2FA spec 완성 후 PASS 전환
- team1 Settings §Preferences Security: PASS 도달
