---
title: Form
owner: team1
tier: internal
legacy-id: BS-02-01
last-updated: 2026-04-15
---

# Login — Form (로그인 입력·인증 방식)

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-14 | 분리 신설 | `BS-02-00-overview.md` 의 §화면 0: 로그인 분리. CCR-DRAFT-team1-20260414-bs02-overview-rename.md 가 API-06 redirect 위임. |
| 2026-04-15 | v10 분할 | 구 `BS-02-01-auth-session.md` 를 Login/Form, Login/Session_Init, Login/Error_Handling, Lobby/Session_Restore 4파일로 분할. 본 파일은 **로그인 입력 폼 + 인증 방식**만 담당. |

---

## 개요

로그인 폼의 입력 요소·인증 방식·Phase 별 전략을 정의한다.

> **참조**:
> - 글로벌 인증 계약: `../../2.5 Shared/Authentication.md`
> - 로그인 성공 후 세션 저장·네비게이션: `Session_Init.md`
> - 로그인 실패·가드·에러 처리: `Error_Handling.md`
> - 재접속·세션 복원: `../Lobby/Session_Restore.md`

---

## 화면 0: 로그인 (Login)

> **근거**: WSOP LIVE와 동일한 계정 체계를 사용. 로그인 성공 시 이전 세션 컨텍스트 복원.

**EBS 목업:**

![EBS Login — 재설계](visual/screenshots/ebs-lobby-00-login.png)

| 요소 | EBS 적용 |
|------|:-------:|
| Email / Password | O — 그대로 사용 |
| Forgot your Password? | O — 그대로 사용 |
| Login 버튼 | O — 그대로 사용 |
| Sign In With Entra ID | TBD — 아래 인증 방식 매트릭스 참조 |

---

## 인증 방식 매트릭스

| 방식 | 설명 | 2FA | 장점 | 단점 | Phase 권장 |
|------|------|:---:|------|------|:----------:|
| **Email + 2FA** | 이메일/비밀번호 + TOTP 또는 SMS | O | 구현 단순, 외부 의존 없음 | 비밀번호 관리 부담 | **Phase 1** |
| **Google OAuth** | Google 계정 SSO | Google 자체 | 빠른 로그인, 비밀번호 불필요 | Google 계정 필수 | Phase 2 |
| **Entra ID (Azure AD)** | Microsoft SSO | Entra 자체 | 기업 통합, WSOP 조직과 연동 가능 | Azure 구독 필요 | Phase 3 |
| **Hybrid** | Email + Google + Entra 중 선택 | 방식별 | 유연성 최대 | 구현 복잡도 최대 | Phase 3+ |

> 참고: Phase 1에서는 Email + 2FA를 기본으로 구현한다. Google OAuth와 Entra ID는 Phase 2~3에서 점진 추가한다.

> 로그인 성공 → 역할(Admin/Operator/Viewer) 자동 할당 → 이전 세션 컨텍스트 복원 → 마지막 선택 화면으로 이동. 상세는 `../../2.5 Shared/Authentication.md` 참조.
