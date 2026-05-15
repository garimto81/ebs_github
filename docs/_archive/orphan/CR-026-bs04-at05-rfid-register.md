---
title: CR-026-bs04-at05-rfid-register
owner: conductor
tier: internal
legacy-id: CCR-026
last-updated: 2026-04-15
confluence-page-id: 3819209922
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819209922/EBS+CR-026-bs04-at05-rfid-register
mirror: none
---

# CCR-026: BS-04 AT-05 RFID Register 화면 명세 추가

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-10) |
| **제안팀** | team4 |
| **제안일** | 2026-04-10 |
| **처리일** | 2026-04-10 |
| **영향팀** | team2 |
| **변경 대상** | `contracts/specs/BS-04-rfid/BS-04-05-register-screen.md`<br/>`contracts/specs/BS-04-rfid/BS-04-01-deck-registration.md` |
| **변경 유형** | add |

## 변경 근거

CCR-DRAFT-team4-20260410-bs05-at-screens에서 AT-05 RFID Register 화면을 "BS-04 참조"로 연결했으나, **BS-04에는 해당 화면의 행동 명세가 없다**. WSOP 원본 `EBS UI Design Action Tracker.md` §3.2 및 `team4-cc/ui-design/reference/action-tracker/analysis/`에 54장 카드 UID 매핑 등록 화면이 정의되어 있지만 계약에는 반영되지 않았다. 본 CCR은 이 공백을 메운다.

## 적용된 파일

- `contracts/specs/BS-04-rfid/BS-04-05-register-screen.md`
- `contracts/specs/BS-04-rfid/BS-04-01-deck-registration.md`

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team4-20260410-bs04-at05-rfid-register.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team2) 개별 확인
- [x] 통합 테스트 업데이트 (`integration-tests/scenarios/50-rfid-deck-register.http`)
- [ ] git commit `[CCR-026] BS-04 AT-05 RFID Register 화면 명세 추가`
