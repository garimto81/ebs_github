---
title: CR-027-bs05-07-statistics-screen
owner: conductor
tier: internal
legacy-id: CCR-027
last-updated: 2026-04-15
confluence-page-id: 3833069731
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3833069731/Statistics
---

# CCR-027: BS-05-07 Statistics 화면 (AT-04) 신규 작성

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-10) |
| **제안팀** | team4 |
| **제안일** | 2026-04-10 |
| **처리일** | 2026-04-10 |
| **영향팀** | team2 |
| **변경 대상** | `contracts/specs/BS-05-command-center/BS-05-07-statistics.md`<br/>`contracts/specs/BS-05-command-center/BS-05-00-overview.md` |
| **변경 유형** | add |

## 변경 근거

CCR-017(BS-05에 AT 화면 체계 도입)에서 AT-04 Statistics 화면을 "BS-05-07-stats.md (신규 예정)"로 dangling reference 처리했으나 실제 파일이 존재하지 않아 계약 참조 체인이 끊긴 상태다. WSOP 원본(`EBS UI Design Action Tracker.md` §6.4)은 AT-04 Statistics 화면을 "10좌석 통계 테이블 + 방송 GFX 제어"로 정의하며, 운영자가 실시간으로 각 플레이어의 VPIP/PFR/핸드 수 등을 확인하고 방송 송출 여부를 결정할 수 있어야 한다. 본 CCR은 이 dangling reference를 해소한다.

## 적용된 파일

- `contracts/specs/BS-05-command-center/BS-05-07-statistics.md`
- `contracts/specs/BS-05-command-center/BS-05-00-overview.md`

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team4-20260410-bs05-07-statistics-screen.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team2) 개별 확인
- [ ] 통합 테스트 업데이트 (`integration-tests/`)
- [ ] git commit `[CCR-027] BS-05-07 Statistics 화면 (AT-04) 신규 작성`
