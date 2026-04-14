# CCR-028: BS-05에 AT 화면 체계(AT-00~AT-07) 도입

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-10) |
| **제안팀** | team4 |
| **제안일** | 2026-04-10 |
| **처리일** | 2026-04-10 |
| **영향팀** | team1, team2 |
| **변경 대상** | `contracts/specs/BS-05-command-center/BS-05-00-overview.md`<br/>`contracts/specs/BS-05-command-center/BS-05-03-seat-management.md`<br/>`contracts/specs/BS-05-command-center/BS-05-04-manual-card-input.md`<br/>`contracts/specs/BS-05-command-center/BS-05-08-game-settings-modal.md`<br/>`contracts/specs/BS-05-command-center/BS-05-09-player-edit-modal.md` |
| **변경 유형** | add |

## 변경 근거

WSOP LIVE의 `EBS UI Design Action Tracker.md`(743줄)와 `EBS UI Design.md` §3 Action Tracker(421줄)에 정의된 8개 화면(AT-00~AT-07) 체계와 7 Zone(M-01~M-07) 구조를 BS-05 계약에 반영. 이미 `team4-cc/ui-design/reference/action-tracker/`에 복사본이 존재하지만 계약 문서에 구조적 핵심이 누락되어, Team 4 구현자가 복사본과 계약 사이에서 어느 쪽을 따를지 판단이 모호함. 근거: Miller's Law(7±2) 기반 인지 부하 최소화, 6시간+ 라이브 방송 피로 최소화 (출처: `team4-cc/ui-design/reference/action-tracker/analysis/EBS-AT-Design-Rationale.md` §3.1).

## 적용된 파일

- `contracts/specs/BS-05-command-center/BS-05-00-overview.md`
- `contracts/specs/BS-05-command-center/BS-05-04-manual-card-input.md`
- `contracts/specs/BS-05-command-center/BS-05-08-game-settings-modal.md`
- `contracts/specs/BS-05-command-center/BS-05-09-player-edit-modal.md`

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team4-20260410-bs05-at-screens.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team1, team2) 개별 확인
- [ ] 통합 테스트 업데이트 (`integration-tests/`)
- [ ] git commit `[CCR-028] BS-05에 AT 화면 체계(AT-00~AT-07) 도입`
