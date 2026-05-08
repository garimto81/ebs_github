---
title: Form
owner: team1
tier: internal
legacy-id: BS-02-01-form
last-updated: 2026-05-08
---

# Login — Form (로그인 입력·인증 방식)

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-14 | 분리 신설 | `BS-02-00-overview.md` 의 §화면 0: 로그인 분리. CCR-DRAFT-team1-20260414-bs02-overview-rename.md 가 API-06 redirect 위임. |
| 2026-04-15 | v10 분할 | 구 `BS-02-01-auth-session.md` 를 Login/Form, Login/Session_Init, Login/Error_Handling, Lobby/Session_Restore 4파일로 분할. 본 파일은 **로그인 입력 폼 + 인증 방식**만 담당. |
| 2026-04-15 | SSOT 선언 | Quasar 구현자 대상으로 "이 문서의 담당 범위 vs 외부 SSOT" 블록 추가 (team1 발신, 기획 문서 충분성 보강 작업의 일부). |
| 2026-04-21 | Flutter 전환 (Lobby Web) | Foundation §5.1 결정 반영. "Quasar/Vue 구현" → "Flutter 구현" 대상 전환. Login = Lobby 의 §화면 0 이므로 배포 형태 = Lobby Web (Foundation §A.1, Docker `ebs-lobby-web:3000`). SSOT 범위 불변 |
| 2026-05-08 | #194 자매 영역 audit drift 정정 | "Flutter Desktop 전환" 표기 → "Flutter 전환 (Lobby Web)" 정합 (Lobby 영역). Conductor Phase C #194 자율 (Login = Lobby/Login Web, CC = Desktop 은 별도 §A.4 영역) |
| 2026-04-15 | Error_Handling 역참조 주석 | §화면 0 아래에 "에러 발생 시 `Error_Handling.md §에러 매핑 테이블` 참조" 한 줄 추가. 개발자가 구현 중 즉시 찾을 수 있도록. team1 발신, Round 2 Phase G. |

---

## 개요

로그인 폼의 입력 요소·인증 방식·Phase 별 전략을 정의한다.

### 이 문서의 담당 범위 (SSOT)

| 주제 | 정답 문서 | 비고 |
|------|-----------|------|
| **로그인 폼 UI · 필드 · Phase 별 인증 방식 매트릭스** | **이 문서** | Flutter 구현 시 이 문서를 그대로 반영 |
| 토큰 TTL · refresh 전략 · 2FA 정책 · Lockout 규칙 | `../../2.5 Shared/Authentication.md` | 수치·정책 변경은 그 문서에서만 |
| 로그인 API 요청/응답 스키마 · HTTP 경로 | `../../2.2 Backend/APIs/Auth_and_Session.md` | 필드명·코드 변경은 그 문서에서만 |
| 로그인 성공 후 세션 저장 · breadcrumb · 네비게이션 | `Session_Init.md` | — |
| 실패·가드·에러 코드 → UI 메시지 매핑 | `Error_Handling.md` | — |
| 재접속·세션 복원 | `../Lobby/Session_Restore.md` | — |

> 이 문서는 "화면 요소와 Phase 별 선택지" 만 다룬다. 구현 중 TTL 수치·API 응답 구조·에러 코드 문구가 불명확하면 위 SSOT 문서를 봐야 하며, 이 문서에서 해당 값을 **재정의하지 말아야 한다**. 중복이 발견되면 본 문서 쪽을 삭제하고 참조로 바꾼다.

---

## 화면 0: 로그인 (Login)

> **근거**: WSOP LIVE와 동일한 계정 체계를 사용. 로그인 성공 시 이전 세션 컨텍스트 복원.

**EBS 목업**: TBD — 디자인 자산 미생성 (team1 Backlog 등재 대상)

| 요소 | EBS 적용 |
|------|:-------:|
| Email / Password | O — 그대로 사용 |
| Forgot your Password? | O — 그대로 사용 |
| Login 버튼 | O — 그대로 사용 |
| Sign In With Entra ID | TBD — 아래 인증 방식 매트릭스 참조 |

> **에러 처리**: 로그인 실패·2FA 실패·계정 잠금·토큰 만료·네트워크 오류 등 모든 에러 경로의 UI 메시지·i18n 키·사용자 액션은 `Error_Handling.md §로그인 실패 처리 — 에러 매핑 테이블` 과 `§UI 상태 머신 — OTP 재시도·계정 잠금` 을 따른다. 본 문서에서 에러 문구를 재정의하지 말 것.

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
