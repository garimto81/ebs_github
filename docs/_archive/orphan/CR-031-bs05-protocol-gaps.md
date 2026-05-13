---
title: CR-031-bs05-protocol-gaps
owner: conductor
tier: internal
legacy-id: CCR-031
last-updated: 2026-04-15
confluence-page-id: 3818947713
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818947713/EBS+CR-031-bs05-protocol-gaps
---

# CCR-031: BS-05 서버 프로토콜 매핑 및 내부 모호성 해소

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-10) |
| **제안팀** | team4 |
| **제안일** | 2026-04-10 |
| **처리일** | 2026-04-10 |
| **영향팀** | team2 |
| **변경 대상** | `contracts/specs/BS-05-command-center/BS-05-00-overview.md`<br/>`contracts/specs/BS-05-command-center/BS-05-01-hand-lifecycle.md`<br/>`contracts/specs/BS-05-command-center/BS-05-02-action-buttons.md`<br/>`contracts/specs/BS-05-command-center/BS-05-03-seat-management.md`<br/>`contracts/specs/BS-05-command-center/BS-05-04-manual-card-input.md`<br/>`WebSocket_Events.md` (legacy-id: API-05) |
| **변경 유형** | modify |

## 변경 근거

WSOP 원본(`EBS UI Design Action Tracker.md` §6)에 명시된 서버 프로토콜 이름(SendPlayerFold, SendPlayerBet, SendPlayerAllIn, UndoLastAction, WriteGameInfo, ActionOnResponse)이 BS-05에 누락되어 있고, 이전 critic 분석에서 식별된 내부 모호성 6건(W2, W6, W8, W9, W10, W12)이 구현 리스크로 남아 있음. 특히 BO 연결 상실 시 복구 규칙 부재는 라이브 방송 사고의 직접 원인이 될 수 있음.

## 적용된 파일

- `contracts/specs/BS-05-command-center/BS-05-00-overview.md`
- `contracts/specs/BS-05-command-center/BS-05-01-hand-lifecycle.md`
- `contracts/specs/BS-05-command-center/BS-05-02-action-buttons.md`

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team4-20260410-bs05-protocol-gaps.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team2) 개별 확인
- [x] 통합 테스트 업데이트 (`integration-tests/scenarios/31-cc-bo-reconnect-replay.http`)
- [ ] git commit `[CCR-031] BS-05 서버 프로토콜 매핑 및 내부 모호성 해소`
