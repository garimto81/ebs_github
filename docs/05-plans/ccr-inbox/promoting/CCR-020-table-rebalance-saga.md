# CCR-020: /tables/rebalance 응답에 saga 구조 추가

| 필드 | 값 |
|------|-----|
| **상태** | SKIPPED (already applied; reprocessed 2026-04-10) |
| **제안팀** | team2 |
| **제안일** | 2026-04-10 |
| **처리일** | 2026-04-10 |
| **영향팀** | team1 |
| **변경 대상** | `contracts/api/API-01-backend-endpoints.md` |
| **변경 유형** | modify |

## 변경 근거

WSOP `Tables API.md` 의 리밸런싱은 여러 테이블에 걸친 **다단계 연산**(seat release → seat assign → chip move → WSOP LIVE notify)이며, 중간에 부분 실패 시 일부 플레이어만 이동 완료되는 고장 모드가 실제로 발생한다. 현재 API-01의 `/tables/rebalance` 계약은 단순 200/400 응답만 정의되어 있어, 부분 실패 시 운영자가 어떤 단계가 성공했고 어떤 단계가 롤백됐는지 확인할 방법이 없다. saga 패턴 응답으로 가시화한다.

## 적용된 파일

_(없음 — 이전 세션에서 이미 반영됨)_

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team2-20260410-table-rebalance-saga.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team1) 개별 확인
- [x] 통합 테스트 업데이트 (`integration-tests/scenarios/12-table-rebalance-saga.http`)
- [ ] git commit `[CCR-020] /tables/rebalance 응답에 saga 구조 추가`
