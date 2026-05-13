---
title: CR-039-event-type-catalog
owner: conductor
tier: internal
legacy-id: CCR-039
last-updated: 2026-04-15
confluence-page-id: 3818521631
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818521631/EBS+CR-039-event-type-catalog
---

# CCR-039: audit_events.event_type 카탈로그 35값 공식 정의

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-13) |
| **제안팀** | team2 |
| **제안일** | 2026-04-13 |
| **처리일** | 2026-04-13 |
| **영향팀** | team1, team4 |
| **변경 대상** | `contracts/data/DATA-04-db-schema.md` |
| **변경 유형** | add |
| **리스크 등급** | HIGH |

## 변경 근거

WSOP LIVE Confluence 실데이터(`Action History` page, EventFlightActionType 70+ enum)와 EBS audit_events.event_type 대조 결과, EBS가 7개 예시만 정의하여 운영 추적 세분화 부족. WSOP 운영 범위 중 EBS에 해당하는 35값을 공식 카탈로그로 확정.

## 적용된 파일

- `contracts/data/DATA-04-db-schema.md`

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team2-20260413-event-type-catalog.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team1, team4) 개별 확인
- [ ] 통합 테스트 업데이트 (`integration-tests/`)
- [ ] git commit `[CCR-039] audit_events.event_type 카탈로그 35값 공식 정의`
