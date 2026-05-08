---
title: CR-024-api05-writegameinfo-schema
owner: conductor
tier: internal
legacy-id: CCR-024
last-updated: 2026-04-15
---

# CCR-024: API-05 WriteGameInfo 프로토콜 22+ 필드 스키마 완전 명세

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-10) |
| **제안팀** | team4 |
| **제안일** | 2026-04-10 |
| **처리일** | 2026-04-10 |
| **영향팀** | team2, team3 |
| **변경 대상** | `WebSocket_Events.md` (legacy-id: API-05)<br/>`contracts/specs/BS-05-command-center/BS-05-02-action-buttons.md` |
| **변경 유형** | modify |

## 변경 근거

CCR-018(BS-05 서버 프로토콜 매핑)에서 `WriteGameInfo` 프로토콜을 NEW HAND 버튼 매핑으로 명시하며 "22+ 필드"라고만 기술하고 실제 필드 목록은 누락했다. 이는 CCR-018의 미완 부분이며, Team 2가 WriteGameInfo 핸들러를 구현할 때 필드 이름/타입/필수 여부를 임의로 결정할 위험이 있다. WSOP 원본 PokerGFX 역설계(`team4-cc/ui-design/reference/action-tracker/analysis/EBS-AT-Design-Rationale.md` §I-4 Blind 자동화)에 따르면 WriteGameInfo는 블라인드 자동화의 핵심 프로토콜이며, 필드 누락은 자동화 실패로 직결된다. 본 CCR은 22+ 필드 전체 스키마를 계약으로 확정한다.

## 적용된 파일

- `WebSocket_Events.md` (legacy-id: API-05)
- `contracts/specs/BS-05-command-center/BS-05-02-action-buttons.md`

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team4-20260410-api05-writegameinfo-schema.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team2, team3) 개별 확인
- [x] 통합 테스트 업데이트 (`integration-tests/scenarios/32-cc-write-game-info.http`)
- [ ] git commit `[CCR-024] API-05 WriteGameInfo 프로토콜 22+ 필드 스키마 완전 명세`
