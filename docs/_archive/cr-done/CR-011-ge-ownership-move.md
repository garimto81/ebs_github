---
title: CR-011-ge-ownership-move
owner: conductor
tier: internal
legacy-id: CCR-011
last-updated: 2026-04-15
confluence-page-id: 3820553360
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3820553360/EBS+CR-011-ge-ownership-move
mirror: none
---

# CCR-011: Graphic Editor 소유권 Team 4 → Team 1 이관 (Lobby 허브)

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-10) |
| **제안팀** | conductor |
| **제안일** | 2026-04-10 |
| **처리일** | 2026-04-10 |
| **영향팀** | team1, team2, team4 |
| **변경 대상** | `contracts/specs/BS-08-graphic-editor/BS-08-00-overview.md`<br/>`contracts/specs/BS-08-graphic-editor/BS-08-01-import-flow.md`<br/>`contracts/specs/BS-08-graphic-editor/BS-08-02-metadata-editing.md`<br/>`contracts/specs/BS-08-graphic-editor/BS-08-03-activate-broadcast.md`<br/>`contracts/specs/BS-08-graphic-editor/BS-08-04-rbac-guards.md`<br/>`contracts/specs/BS-00-definitions.md` |
| **변경 유형** | add + modify |

## 변경 근거

사용자(Conductor)가 2026-04-10 AskUserQuestion 세션에서 "GE 허브 위치 = Lobby (Team 1 Quasar+rive-js)" 및 "편집 범위 = Import+Activate 허브"를 명시 결정. 기존 `CCR-DRAFT-team4-20260410-bs08-graphic-editor-new.md`는 CC 내부 Flutter 화면 + 8모드 99컨트롤 풀 편집을 가정하여 다음과 충돌: ①"Settings는 글로벌" 원칙 (memory: feedback_settings_global.md), ②멀티 CC 동기화 시 편집권 락 프로토콜 필요성, ③Rive 공식 에디터와의 중복 투자, ④YAGNI. 본 CCR은 Team 4 제안의 유용한 자산(8모드 정의, Rive Import 흐름, SkinChanged 이벤트)을 Team 1 Quasar 허브 아키텍처로 재매핑한다.

## 적용된 파일

- `contracts/specs/BS-08-graphic-editor/BS-08-00-overview.md`
- `contracts/specs/BS-08-graphic-editor/BS-08-01-import-flow.md`
- `contracts/specs/BS-08-graphic-editor/BS-08-02-metadata-editing.md`
- `contracts/specs/BS-08-graphic-editor/BS-08-03-activate-broadcast.md`
- `contracts/specs/BS-08-graphic-editor/BS-08-04-rbac-guards.md`
- `contracts/specs/BS-00-definitions.md`

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-conductor-20260410-ge-ownership-move.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team1, team2, team4) 개별 확인
- [x] 통합 테스트 업데이트 (`integration-tests/scenarios/20-ge-upload-download.http`, `integration-tests/scenarios/21-ge-patch-metadata-etag.http`, `integration-tests/scenarios/22-ge-activate-broadcast.http`, `integration-tests/scenarios/23-ge-rbac-denied.http`)
- [ ] git commit `[CCR-011] Graphic Editor 소유권 Team 4 → Team 1 이관 (Lobby 허브)`
