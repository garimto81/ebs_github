---
title: CR-014-ge-req-id-rework
owner: conductor
tier: internal
legacy-id: CCR-014
last-updated: 2026-04-15
confluence-page-id: 3820553440
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3820553440/EBS+CR-014-ge-req-id-rework
mirror: none
---

# CCR-014: GE 요구사항 ID prefix 재편 (범위 축소 반영)

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-10) |
| **제안팀** | conductor |
| **제안일** | 2026-04-11 |
| **처리일** | 2026-04-10 |
| **영향팀** | team1, team2 |
| **변경 대상** | `contracts/specs/BS-00-definitions.md` |
| **변경 유형** | modify |

## 변경 근거

기존 BS-00에 `GEB-*` (Board, 15개) + `GEP-*` (Player, 15개) = 30개 요구사항이 존재하나, 편집 범위 축소(CCR `ge-ownership-move`)로 Transform/Animation 편집이 out-of-scope가 되어 이 30개가 **실제로는 편집 UI 대상이 아님**. 본 CCR은 GEB-/GEP-를 "참고 자산"으로 유지하고, 새 편집 scope에 맞는 prefix 4개(GEM-/GEI-/GEA-/GER-)를 신설한다.

## 적용된 파일

- `contracts/specs/BS-00-definitions.md`

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-conductor-20260411-ge-req-id-rework.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team1, team2) 개별 확인
- [x] 통합 테스트 업데이트 (`integration-tests/scenarios/20-ge-upload-download.http`)
- [ ] git commit `[CCR-014] GE 요구사항 ID prefix 재편 (범위 축소 반영)`
