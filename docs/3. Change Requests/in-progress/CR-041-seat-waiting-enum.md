---
title: CR-041-seat-waiting-enum
owner: conductor
tier: internal
legacy-id: CCR-041
last-updated: 2026-04-15
---

# CCR-041: DATA-04에 Seat Status enum 정의 + waiting_list 테이블 신설

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-13) |
| **제안팀** | team2 |
| **제안일** | 2026-04-13 |
| **처리일** | 2026-04-13 |
| **영향팀** | team1, team4 |
| **변경 대상** | `contracts/data/DATA-04-db-schema.md` |
| **변경 유형** | add + modify |
| **리스크 등급** | HIGH |

## 변경 근거

WSOP LIVE `Table Dealer Page` 및 `Staff App Live` Confluence 문서에서 좌석 상태(E/B/M/N/O)와 대기자 상태(Waiting/Front/Calling/Ready/Seated/Canceled)가 명시적 enum으로 운영됨. EBS DATA-04의 `table_seats.status`는 VARCHAR로 허용값 미정의, `waiting_list` 테이블 자체가 부재.

## 적용된 파일

- `contracts/data/DATA-04-db-schema.md`

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team2-20260413-seat-waiting-enum.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team1, team4) 개별 확인
- [ ] 통합 테스트 업데이트 (`integration-tests/`)
- [ ] git commit `[CCR-041] DATA-04에 Seat Status enum 정의 + waiting_list 테이블 신설`
