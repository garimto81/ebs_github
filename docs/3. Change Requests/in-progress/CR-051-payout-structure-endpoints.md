---
title: CR-051-payout-structure-endpoints
owner: conductor
tier: internal
legacy-id: CCR-051
last-updated: 2026-04-15
---

# CCR-051: PayoutStructure (PrizePool) 엔드포인트 추가 (WSOP LIVE 정렬)

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-14) |
| **제안팀** | team2 |
| **제안일** | 2026-04-14 |
| **처리일** | 2026-04-14 |
| **영향팀** | team1, team4 |
| **변경 대상** | `Backend_HTTP.md` (legacy-id: API-01)<br/>`contracts/data/DATA-02-entities.md` |
| **변경 유형** | add |
| **리스크 등급** | MEDIUM |

## 변경 근거

WSOP LIVE Staff App(Page 1603600679)은 PayoutStructure(상금 구조) 템플릿 + Flight별 적용 엔드포인트 7종을 제공. EBS API-01에 상금 관리 API 부재. `prize_pool_changed` WebSocket 이벤트(S0-05 CCR)의 소스 API 확립 필요.

## 적용된 파일

- `Backend_HTTP.md` (legacy-id: API-01)
- `contracts/data/DATA-02-entities.md`

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team2-20260414-payout-structure-endpoints.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team1, team4) 개별 확인
- [ ] 통합 테스트 업데이트 (`integration-tests/`)
- [ ] git commit `[CCR-051] PayoutStructure (PrizePool) 엔드포인트 추가 (WSOP LIVE 정렬)`
