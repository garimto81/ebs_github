---
title: CR-029-bs05-launch-flow
owner: conductor
tier: internal
legacy-id: CCR-029
last-updated: 2026-04-15
---

# CCR-029: BS-05 Lobby → BO → CC Launch 플로우 상세 명세

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-10) |
| **제안팀** | team4 |
| **제안일** | 2026-04-10 |
| **처리일** | 2026-04-10 |
| **영향팀** | team1, team2 |
| **변경 대상** | `contracts/specs/BS-05-command-center/BS-05-00-overview.md`<br/>`contracts/api/API-01-backend-api.md` |
| **변경 유형** | modify |

## 변경 근거

현재 BS-05-00-overview에 "Launch 플로우: Lobby에서 [Launch] 클릭 → BO 인스턴스 생성 → WebSocket 연결 → IDLE 상태 수신"이라는 한 줄만 있다. 실제 구현 시 필요한 세부(운영자 인증 전파, 초기 상태 수신, Launch 실패 복구, CC 프로세스 실행 방식, BO와의 Handshake)가 모두 누락되어 Team 1/2/4 각자 임의 구현 위험이 있다. WSOP 원본(`EBS UI Design Action Tracker.md` §로그인)과 일치시키며, team1의 BS-02-lobby §Launch 섹션과 양방향 참조가 필요하다.

## 적용된 파일

- `contracts/specs/BS-05-command-center/BS-05-00-overview.md`
- `contracts/api/API-01-backend-api.md`

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team4-20260410-bs05-launch-flow.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team1, team2) 개별 확인
- [x] 통합 테스트 업데이트 (`integration-tests/scenarios/30-cc-launch-flow.http`)
- [ ] git commit `[CCR-029] BS-05 Lobby → BO → CC Launch 플로우 상세 명세`
