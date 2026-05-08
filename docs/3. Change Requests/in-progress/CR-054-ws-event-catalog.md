---
title: CR-054-ws-event-catalog
owner: conductor
tier: internal
legacy-id: CCR-054
last-updated: 2026-04-15
---

# CCR-054: WebSocket 이벤트 카탈로그 WSOP LIVE SignalR 정렬

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-14) |
| **제안팀** | team2 |
| **제안일** | 2026-04-14 |
| **처리일** | 2026-04-14 |
| **영향팀** | team1, team3, team4 |
| **변경 대상** | `WebSocket_Events.md` (legacy-id: API-05) |
| **변경 유형** | add |
| **리스크 등급** | HIGH |

## 변경 근거

WSOP LIVE Staff App SignalR Hub(Page 1793328277)은 8종 이벤트(Clock/ClockDetail/TournamentStatus/EventFlightSummary/BlindStructure/PrizePool/ClockReload/ClockReloadPage)를 발행. EBS API-05는 이 중 3종(event_flight_summary, clock_tick, clock_level_changed)만 대응. 정식 전체 개발에서 `blind_structure_changed`/`prize_pool_changed` 추가 + 전체 매핑 표가 필요. (clock_detail_changed/clock_reload_requested/tournament_status_changed는 별도 CCR S0-01에서 추가 제안.)

## 적용된 파일

- `WebSocket_Events.md` (legacy-id: API-05)

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team2-20260414-ws-event-catalog.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team1, team3, team4) 개별 확인
- [ ] 통합 테스트 업데이트 (`integration-tests/`)
- [ ] git commit `[CCR-054] WebSocket 이벤트 카탈로그 WSOP LIVE SignalR 정렬`
