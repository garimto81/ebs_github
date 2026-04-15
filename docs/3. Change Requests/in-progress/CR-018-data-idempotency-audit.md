---
title: CR-018-data-idempotency-audit
owner: conductor
tier: internal
legacy-id: CCR-018
last-updated: 2026-04-15
---

# CCR-018: DATA-04에 idempotency_keys, audit_events 테이블 신설

| 필드 | 값 |
|------|-----|
| **상태** | SKIPPED (already applied; reprocessed 2026-04-10) |
| **제안팀** | team2 |
| **제안일** | 2026-04-10 |
| **처리일** | 2026-04-10 |
| **영향팀** | team1, team4 |
| **변경 대상** | `contracts/data/DATA-04-db-schema.md` |
| **변경 유형** | add |

## 변경 근거

WSOP+ Database 문서의 `EventFlightSeatHistory`, Audit 테이블 설계를 참고하면, 좌석/칩/블라인드 등 모든 상태 변경은 append-only 이벤트 스토어로 기록되어야 복구·감사·핸드 리플레이·Undo/Revive가 가능하다. 또한 `Idempotency-Key` CCR(동일 일자)과 WebSocket seq CCR(동일 일자)은 모두 전용 스토리지가 필요하므로 DATA-04 확장 필수.

## 적용된 파일

_(없음 — 이전 세션에서 이미 반영됨)_

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team2-20260410-data-idempotency-audit.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team1, team4) 개별 확인
- [ ] 통합 테스트 업데이트 (`integration-tests/`)
- [ ] git commit `[CCR-018] DATA-04에 idempotency_keys, audit_events 테이블 신설`
