---
title: CR-016-tech-stack-ssot
owner: conductor
tier: internal
legacy-id: CCR-016
last-updated: 2026-04-15
confluence-page-id: 3820553380
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3820553380/EBS+CR-016-tech-stack-ssot
mirror: none
---

# CCR-016: Tech Stack SSOT를 BS-00에 명시하고 team2 IMPL 시리즈 동기화

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-10) |
| **제안팀** | team1 |
| **제안일** | 2026-04-10 |
| **처리일** | 2026-04-10 |
| **영향팀** | team2, team3, team4 |
| **변경 대상** | `contracts/specs/BS-00-definitions.md` |
| **변경 유형** | modify |

## 변경 근거

Quasar 전환 commit(`347be60 refactor: change frontend tech stack React → Quasar`, 2026-04-10 12:35)이 `contracts/specs/BS-00-definitions.md` §1 앱 아키텍처 용어 표의 Lobby row와 `team2-backend/specs/impl/IMPL-01~03`에 전파되지 않음. 결과적으로 BS-00 SSOT와 team2 내부 스펙이 모두 stale한 Next.js/Zustand 기준으로 남아 Team 1 critic revision 중 발견. **재발 방지**를 위해 BS-00을 Tech Stack SSOT로 명시하고 team2 IMPL 시리즈 동기화 cleanup을 동봉 요청.

## 적용된 파일

- `contracts/specs/BS-00-definitions.md`

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team1-20260410-tech-stack-ssot.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team2, team3, team4) 개별 확인
- [ ] 통합 테스트 업데이트 (`integration-tests/`)
- [ ] git commit `[CCR-016] Tech Stack SSOT를 BS-00에 명시하고 team2 IMPL 시리즈 동기화`
