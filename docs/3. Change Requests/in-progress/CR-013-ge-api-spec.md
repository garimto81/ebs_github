---
title: CR-013-ge-api-spec
owner: conductor
tier: internal
legacy-id: CCR-013
last-updated: 2026-04-15
---

# CCR-013: API-07 Graphic Editor 엔드포인트 신설

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-10) |
| **제안팀** | conductor |
| **제안일** | 2026-04-11 |
| **처리일** | 2026-04-10 |
| **영향팀** | team1, team2 |
| **변경 대상** | `Graphic_Editor_API.md` (legacy-id: API-07) |
| **변경 유형** | add |

## 변경 근거

`contracts/api/`에 GE 관련 Backend 엔드포인트 스펙이 **존재하지 않는다**. Team 1 Lobby가 Backend를 호출해야 하는데 호출할 API가 계약에 없어 Team 2가 무엇을 구현해야 하는지 불명확. CCR `ge-ownership-move` 승격 후 즉시 필요. Idempotency-Key (CCR-003 준수), `If-Match` ETag 낙관적 동시성, `X-Game-State` 헤더 검증 (방송 중 activate 경고)을 공식화.

## 적용된 파일

- `Graphic_Editor_API.md` (legacy-id: API-07)

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-conductor-20260411-ge-api-spec.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team1, team2) 개별 확인
- [x] 통합 테스트 업데이트 (`integration-tests/scenarios/20-ge-upload-download.http`, `integration-tests/scenarios/21-ge-patch-metadata-etag.http`, `integration-tests/scenarios/22-ge-activate-broadcast.http`, `integration-tests/scenarios/23-ge-rbac-denied.http`)
- [ ] git commit `[CCR-013] API-07 Graphic Editor 엔드포인트 신설`
