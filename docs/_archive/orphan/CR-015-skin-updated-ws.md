---
title: CR-015-skin-updated-ws
owner: conductor
tier: internal
legacy-id: CCR-015
last-updated: 2026-04-15
confluence-page-id: 3818914835
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818914835/EBS+CR-015-skin-updated-ws
mirror: none
---

# CCR-015: API-05에 skin_updated WebSocket 이벤트 추가

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-10) |
| **제안팀** | conductor |
| **제안일** | 2026-04-14 |
| **처리일** | 2026-04-10 |
| **영향팀** | team2, team4 |
| **변경 대상** | `WebSocket_Events.md` (legacy-id: API-05) |
| **변경 유형** | modify |

## 변경 근거

CCR `ge-ownership-move`의 멀티 CC 동기화 결단(D11)에 따라, Activate 시 서버가 모든 CC/Overlay 인스턴스에 `skin_updated` 이벤트를 broadcast 해야 한다. 현재 API-05에는 해당 이벤트가 없다. Team 4 기존 CCR(`CCR-DRAFT-team4-20260410-bs08-graphic-editor-new.md §BS-08-05`)은 `SkinChanged` 이름을 사용하나, `*_updated` 명명 관습(WSOP parity, CCR-016)에 맞춰 `skin_updated`로 표준화. CCR-015 seq 단조증가 정책 준수.

## 적용된 파일

- `WebSocket_Events.md` (legacy-id: API-05)

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-conductor-20260414-skin-updated-ws.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team2, team4) 개별 확인
- [x] 통합 테스트 업데이트 (`integration-tests/scenarios/22-ge-activate-broadcast.http`)
- [ ] git commit `[CCR-015] API-05에 skin_updated WebSocket 이벤트 추가`
