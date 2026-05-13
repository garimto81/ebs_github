---
title: CR-034-bs07-cc-visual-sync
owner: conductor
tier: internal
legacy-id: CCR-034
last-updated: 2026-04-15
confluence-page-id: 3819602925
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819602925/EBS+CR-034-bs07-cc-visual-sync
---

# CCR-034: BS-07 Overlay 시각 일관성 (CC 색상 체계 재사용)

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-10) |
| **제안팀** | team4 |
| **제안일** | 2026-04-10 |
| **처리일** | 2026-04-10 |
| **영향팀** | team1 |
| **변경 대상** | `contracts/specs/BS-07-overlay/BS-07-01-elements.md`<br/>`contracts/specs/BS-07-overlay/BS-07-04-scene-schema.md` |
| **변경 유형** | modify |

## 변경 근거

CCR-DRAFT-team4-20260410-bs05-visual-spec에서 BS-05-03에 포지션 마커 색상(Dealer 빨강, SB 노랑, BB 파랑, UTG 초록)과 좌석 상태 배경색(Active 녹색, Folded 40% 반투명, All-In 검정)을 명시했으나, **Overlay 쪽 BS-07-01-elements.md는 이 색상 체계를 참조하지 않는다**. CC(운영자 화면)와 Overlay(방송 시청자 화면)에서 좌석/포지션 색상이 다르면 운영자와 시청자가 **다른 시각 언어**를 보게 되어 혼란을 유발하며, Graphic Editor(BS-08)의 Skin 편집 시에도 기준이 두 개로 분열된다. 본 CCR은 BS-07을 BS-05-03의 색상 체계에 정렬한다.

## 적용된 파일

- `contracts/specs/BS-07-overlay/BS-07-01-elements.md`
- `contracts/specs/BS-07-overlay/BS-07-04-scene-schema.md`

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team4-20260410-bs07-cc-visual-sync.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team1) 개별 확인
- [ ] 통합 테스트 업데이트 (`integration-tests/`)
- [ ] git commit `[CCR-034] BS-07 Overlay 시각 일관성 (CC 색상 체계 재사용)`
