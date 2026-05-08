---
title: CR-021-ws-event-seq
owner: conductor
tier: internal
legacy-id: CCR-021
last-updated: 2026-04-15
confluence-page-id: 3818882250
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818882250/EBS+CR-021-ws-event-seq
---

# CCR-021: WebSocket 이벤트에 단조증가 seq 필드 + replay 엔드포인트 추가

| 필드 | 값 |
|------|-----|
| **상태** | SKIPPED (already applied; reprocessed 2026-04-10) |
| **제안팀** | team2 |
| **제안일** | 2026-04-10 |
| **처리일** | 2026-04-10 |
| **영향팀** | team1, team4 |
| **변경 대상** | `WebSocket_Events.md` (legacy-id: API-05)<br/>`Backend_HTTP.md` (legacy-id: API-01) |
| **변경 유형** | add |

## 변경 근거

WSOP+ Architecture(`SignalR Real-Time Stream Server + MSK Event Stream 이중 구조`)를 참고하면, 실시간 방송 환경에서는 네트워크 순간 단절·백그라운드 복귀·WebSocket 재연결 후 **놓친 이벤트를 안전하게 재생**해야 한다. 현재 API-05 계약에는 이벤트 순번이 없어 클라이언트가 gap 감지 및 replay를 구현할 수 없다. 상태가 GameState/TableState처럼 순서에 민감하면 ad-hoc 재동기화로는 오결정 위험이 있다.

## 적용된 파일

_(없음 — 이전 세션에서 이미 반영됨)_

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team2-20260410-ws-event-seq.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team1, team4) 개별 확인
- [x] 통합 테스트 업데이트 (`integration-tests/scenarios/13-ws-event-seq-replay.http`)
- [ ] git commit `[CCR-021] WebSocket 이벤트에 단조증가 seq 필드 + replay 엔드포인트 추가`
