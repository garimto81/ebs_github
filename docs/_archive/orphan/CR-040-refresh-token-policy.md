---
title: CR-040-refresh-token-policy
owner: conductor
tier: internal
legacy-id: CCR-040
last-updated: 2026-04-15
confluence-page-id: 3818521651
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818521651/EBS+CR-040-refresh-token-policy
---

# CCR-040: BS-01 refresh_token 전달 방식을 환경별 조건부로 통일

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-13) |
| **제안팀** | team2 |
| **제안일** | 2026-04-13 |
| **처리일** | 2026-04-13 |
| **영향팀** | team1 |
| **변경 대상** | `contracts/specs/BS-01-auth/BS-01-auth.md`<br/>`Auth_and_Session.md` (legacy-id: API-06) |
| **변경 유형** | modify |
| **리스크 등급** | HIGH |

## 변경 근거

BS-01에서 "Refresh Token은 HttpOnly Cookie"로 정의하고 있으나, API-06 `POST /auth/login` 응답에 `refresh_token` 필드가 JSON body에 포함되어 있어 모순. WSOP LIVE Staff App API를 확인한 결과 WSOP는 HttpOnly Cookie 방식을 사용. EBS는 개발 편의와 보안의 절충을 위해 환경별 조건부 방식을 채택.

## 적용된 파일

- `contracts/specs/BS-01-auth/BS-01-auth.md`
- `Auth_and_Session.md` (legacy-id: API-06)

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team2-20260413-refresh-token-policy.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team1) 개별 확인
- [ ] 통합 테스트 업데이트 (`integration-tests/`)
- [ ] git commit `[CCR-040] BS-01 refresh_token 전달 방식을 환경별 조건부로 통일`
