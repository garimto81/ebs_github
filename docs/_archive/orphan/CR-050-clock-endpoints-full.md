---
title: CR-050-clock-endpoints-full
owner: conductor
tier: internal
legacy-id: CCR-050
last-updated: 2026-04-15
confluence-page-id: 3819602945
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819602945/EBS+CR-050-clock-endpoints-full
---

# CCR-050: Clock 엔드포인트 10종 완성 (WSOP LIVE Staff App 정렬)

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-14) |
| **제안팀** | team2 |
| **제안일** | 2026-04-14 |
| **처리일** | 2026-04-14 |
| **영향팀** | team1, team4 |
| **변경 대상** | `Backend_HTTP.md` (legacy-id: API-01)<br/>`Triggers.md` (legacy-id: `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: BS-06-00-triggers)))<br/>`WebSocket_Events.md` (legacy-id: API-05) |
| **변경 유형** | add |
| **리스크 등급** | MEDIUM |

## 변경 근거

현행 API-01 §5.6.1은 Clock 엔드포인트 5종(GET/Start/Pause/Resume/PUT)만 정의. WSOP LIVE Staff App(`/전광판 API`, Page 1651343762; `Clock System Architecture and Operations`, Page 3728441546)은 10종을 제공하며 EBS 정식 전체 개발은 WSOP LIVE 패턴에 정렬해야 함. 누락 5종(Restart/Detail/ReloadPage/AdjustStack + Flight Complete/Cancel)은 토너먼트 운영 필수 기능.

## 적용된 파일

- `Backend_HTTP.md` (legacy-id: API-01)
- `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: BS-06-00-triggers)))
- `WebSocket_Events.md` (legacy-id: API-05)

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team2-20260414-clock-endpoints-full.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team1, team4) 개별 확인
- [ ] 통합 테스트 업데이트 (`integration-tests/`)
- [ ] git commit `[CCR-050] Clock 엔드포인트 10종 완성 (WSOP LIVE Staff App 정렬)`
