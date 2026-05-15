---
title: CR-043-wsop-sync-catalog
owner: conductor
tier: internal
legacy-id: CCR-043
last-updated: 2026-04-15
confluence-page-id: 3819242575
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819242575/EBS+CR-043-wsop-sync-catalog
mirror: none
---

# CCR-043: WSOP LIVE Sync 대상 엔드포인트 카탈로그 + GGPass 통합 전략

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-14) |
| **제안팀** | team2 |
| **제안일** | 2026-04-14 |
| **처리일** | 2026-04-14 |
| **영향팀** | team1 |
| **변경 대상** | `Backend_HTTP.md` (legacy-id: API-01) (Part II, WSOP LIVE Integration) |
| **변경 유형** | add |
| **리스크 등급** | LOW |

## 변경 근거

WSOP LIVE는 공개 Public API 카탈로그가 별도 존재하지 않음 (조사 결과). Staff App API는 내부 사용. 외부 통합은 GGPass External API(S2S, Page 1975582764, API Key + JWT) 경유. EBS 동기화 전략을 명시화 필요: Phase 1 mock seed, Phase 2 GGPass 통합 협상, Phase 3 Staff App API 양방향.

## 적용된 파일

- `Backend_HTTP.md` (legacy-id: API-01) (Part II, WSOP LIVE Integration)

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team2-20260414-wsop-sync-catalog.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team1) 개별 확인
- [ ] 통합 테스트 업데이트 (`integration-tests/`)
- [ ] git commit `[CCR-043] WSOP LIVE Sync 대상 엔드포인트 카탈로그 + GGPass 통합 전략`
