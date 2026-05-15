---
title: CR-010-jwt-expiry
owner: conductor
tier: internal
legacy-id: CCR-010
last-updated: 2026-04-15
confluence-page-id: 3818947673
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818947673/EBS+CR-010-jwt-expiry
mirror: none
---

# CCR-010: BS-01에 JWT Access/Refresh 만료 정책 명시

| 필드 | 값 |
|------|-----|
| **상태** | SKIPPED (already applied; reprocessed 2026-04-10) |
| **제안팀** | team2 |
| **제안일** | 2026-04-10 |
| **처리일** | 2026-04-10 |
| **영향팀** | team1 |
| **변경 대상** | `contracts/specs/BS-01-auth/BS-01-auth.md`<br/>`Auth_and_Session.md` (legacy-id: API-06) |
| **변경 유형** | modify |

## 변경 근거

WSOP Staff App `Auth.md` 는 JWT `expires_in: 43200초(12h)` 를 운영 기준으로 사용한다. EBS의 현재 BS-01에는 "Access 15분, Refresh 7일"이 명시되어 있는데(Phase 1 초안), 14-16시간 연속 방송 시나리오에서 Access 15분은 과도한 refresh 오버헤드(방송 중 분당 4회 refresh × 운영자 N명)와 WebSocket 재연결 리스크를 유발한다. 동시에 너무 길면 토큰 탈취 시 노출 창이 커진다. 운영 환경에 맞춰 Phase별 정책을 명시적으로 정한다.

## 적용된 파일

_(없음 — 이전 세션에서 이미 반영됨)_

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team2-20260410-jwt-expiry.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team1) 개별 확인
- [x] 통합 테스트 업데이트 (`integration-tests/scenarios/10-auth-login-profile.http`)
- [ ] git commit `[CCR-010] BS-01에 JWT Access/Refresh 만료 정책 명시`
