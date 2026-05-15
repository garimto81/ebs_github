---
title: CR-019-idempotency-key
owner: conductor
tier: internal
legacy-id: CCR-019
last-updated: 2026-04-15
confluence-page-id: 3818849286
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818849286/EBS+CR-019-idempotency-key
mirror: none
---

# CCR-019: 모든 Mutation API에 Idempotency-Key 헤더 표준 도입

| 필드 | 값 |
|------|-----|
| **상태** | SKIPPED (already applied; reprocessed 2026-04-10) |
| **제안팀** | team2 |
| **제안일** | 2026-04-10 |
| **처리일** | 2026-04-10 |
| **영향팀** | team1, team4 |
| **변경 대상** | `Backend_HTTP.md` (legacy-id: API-01)<br/>`WebSocket_Events.md` (legacy-id: API-05)<br/>`Auth_and_Session.md` (legacy-id: API-06) |
| **변경 유형** | add |

## 변경 근거

WSOP LIVE Confluence 검토 결과(`Chip Master.md`의 2-phase confirmation, `Waiting API.md`의 seat draw 재시도 케이스) — 네트워크 재시도·운영자 더블 클릭·클라이언트 크래시 후 재전송 시 동일 요청이 중복 적용되어 좌석/칩/토큰 상태가 불일치하는 사고를 방지하려면 멱등성 계약이 필수. 현재 API-01~06 계약에는 관련 헤더/응답이 없음.

## 적용된 파일

_(없음 — 이전 세션에서 이미 반영됨)_

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team2-20260410-idempotency-key.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team1, team4) 개별 확인
- [x] 통합 테스트 업데이트 (`integration-tests/scenarios/11-idempotency-key.http`)
- [ ] git commit `[CCR-019] 모든 Mutation API에 Idempotency-Key 헤더 표준 도입`
