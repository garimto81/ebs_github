---
title: CR-048-auth-ggpass-pattern
owner: conductor
tier: internal
legacy-id: CCR-048
last-updated: 2026-04-15
confluence-page-id: 3819275524
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819275524/EBS+CR-048-auth-ggpass-pattern
mirror: none
---

# CCR-048: 인증 체계 WSOP LIVE GGPass 패턴 정렬

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-14) |
| **제안팀** | team2 |
| **제안일** | 2026-04-14 |
| **처리일** | 2026-04-14 |
| **영향팀** | team1, team4 |
| **변경 대상** | `contracts/specs/BS-01-auth/BS-01-auth.md`<br/>`Auth_and_Session.md` (legacy-id: API-06) |
| **변경 유형** | add |
| **리스크 등급** | MEDIUM |

## 변경 근거

WSOP LIVE는 GGPass 통합 SSO(Page 1972863063, 2202861710, 1701380121)를 운영하며 JWT + 3-step Password Reset + 4-level 2FA + 10회 실패 자동 잠금 패턴을 표준화. EBS 현행 BS-01-auth는 일부 요소만 정의, Password Reset API/2FA 레벨/자동 잠금 정책 누락. 정식 전체 개발 단계에서 GGPass 패턴 준거 필요.

## 적용된 파일

- `Auth_and_Session.md` (legacy-id: API-06)
- `contracts/specs/BS-01-auth/BS-01-auth.md`

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team2-20260414-auth-ggpass-pattern.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team1, team4) 개별 확인
- [ ] 통합 테스트 업데이트 (`integration-tests/`)
- [ ] git commit `[CCR-048] 인증 체계 WSOP LIVE GGPass 패턴 정렬`
