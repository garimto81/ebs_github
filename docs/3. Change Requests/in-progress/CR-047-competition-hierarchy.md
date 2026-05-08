---
title: CR-047-competition-hierarchy
owner: conductor
tier: internal
legacy-id: CCR-047
last-updated: 2026-04-15
confluence-page-id: 3818849386
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818849386/EBS+CR-047-competition-hierarchy
---

# CCR-047: Competition 계층 WSOP LIVE 정렬 (Series→Event→EventFlight)

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-14) |
| **제안팀** | team2 |
| **제안일** | 2026-04-14 |
| **처리일** | 2026-04-14 |
| **영향팀** | team1, team4 |
| **변경 대상** | `contracts/data/DATA-02-entities.md`<br/>`contracts/data/DATA-04-db-schema.md`<br/>`Backend_HTTP.md` (legacy-id: API-01) |
| **변경 유형** | add |
| **리스크 등급** | HIGH |

## 변경 근거

WSOP LIVE Staff App 계층(Series→Event→EventFlight, Page 1599537917)에서 Competition은 Series 상위 실체가 아니라 Series 분류 태그(`CompetitionType` enum, Page 1960411325). EBS 현행 `competitions` 테이블 + §5.3 Competitions CRUD 5종은 불필요한 중간 계층. WSOP LIVE 패턴에 정렬 필요. 단, 기존 competitions 테이블은 Phase 1 호환용으로 deprecated 표기 유지, 신규 API 접근은 차단.

## 적용된 파일

- `contracts/data/DATA-02-entities.md`
- `contracts/data/DATA-04-db-schema.md`
- `Backend_HTTP.md` (legacy-id: API-01)

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team2-20260414-competition-hierarchy.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team1, team4) 개별 확인
- [ ] 통합 테스트 업데이트 (`integration-tests/`)
- [ ] git commit `[CCR-047] Competition 계층 WSOP LIVE 정렬 (Series→Event→EventFlight)`
