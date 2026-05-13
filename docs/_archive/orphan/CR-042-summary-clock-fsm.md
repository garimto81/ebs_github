---
title: CR-042-summary-clock-fsm
owner: conductor
tier: internal
legacy-id: CCR-042
last-updated: 2026-04-15
confluence-page-id: 3818750914
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818750914/EBS+CR-042-summary-clock-fsm
---

# CCR-042: API-05에 EventFlightSummary 이벤트 + Clock FSM 행동 명세 신설

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-13) |
| **제안팀** | team2 |
| **제안일** | 2026-04-13 |
| **처리일** | 2026-04-13 |
| **영향팀** | team1, team3, team4 |
| **변경 대상** | `WebSocket_Events.md` (legacy-id: API-05)<br/>`contracts/specs/` |
| **변경 유형** | add |
| **리스크 등급** | HIGH |

## 변경 근거

WSOP LIVE Confluence `Staff App Live` page에서 `EventFlightSummary`(25+ 필드 실시간 모델)와 `Clock`(13필드 + BlindDetailType enum)이 WebSocket Subscribe로 전달되는데, EBS API-05에는 해당 이벤트가 전혀 없어 Lobby 대시보드와 블라인드 타이머 UI 구현 불가. WSOP `Staff App Live` page를 정본으로 참조.

## 적용된 파일

- `WebSocket_Events.md` (legacy-id: API-05)
- `contracts/specs/BS-07-clock.md`

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team2-20260413-summary-clock-fsm.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team1, team3, team4) 개별 확인
- [ ] 통합 테스트 업데이트 (`integration-tests/`)
- [ ] git commit `[CCR-042] API-05에 EventFlightSummary 이벤트 + Clock FSM 행동 명세 신설`
