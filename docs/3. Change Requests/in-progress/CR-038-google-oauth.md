---
title: CR-038-google-oauth
owner: conductor
tier: internal
legacy-id: CCR-038
last-updated: 2026-04-15
---

# CCR-038: Google OAuth Phase 1 도입

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-13) |
| **제안팀** | team1 |
| **제안일** | 2026-04-13 |
| **처리일** | 2026-04-13 |
| **영향팀** | team2 |
| **변경 대상** | `contracts/specs/BS-01-auth/BS-01-auth.md`<br/>`contracts/api/API-06-auth-session.md` |
| **변경 유형** | add |
| **리스크 등급** | HIGH |

## 변경 근거

WSOP LIVE Staff Page 스크린샷에서 Google OAuth 로그인 확인. 설계 원칙 1조 "동일하게 설계할 수 있는 것은 최대한 동일하게" 적용. Phase 2로 보류되어 있었으나 Phase 1에 포함 결정 (사용자 승인 2026-04-13).

## 적용된 파일

- `contracts/specs/BS-01-auth/BS-01-auth.md`
- `contracts/api/API-06-auth-session.md`

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team1-20260413-google-oauth.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team2) 개별 확인
- [ ] 통합 테스트 업데이트 (`integration-tests/`)
- [ ] git commit `[CCR-038] Google OAuth Phase 1 도입`
