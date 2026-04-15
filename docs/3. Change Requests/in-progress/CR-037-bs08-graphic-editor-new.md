---
title: CR-037-bs08-graphic-editor-new
owner: conductor
tier: internal
legacy-id: CCR-037
last-updated: 2026-04-15
---

# CCR-037: BS-08 Graphic Editor 행동 명세 신규 작성 (WSOP 8모드)

| 필드 | 값 |
|------|-----|
| **상태** | ❌ REJECTED — SUPERSEDED by CCR-011 (2026-04-10) |
| **제안팀** | team4 |
| **제안일** | 2026-04-10 |
| **처리일** | 2026-04-10 |
| **영향팀** | team1, team2 |
| **변경 대상** | `contracts/specs/BS-08-graphic-editor/BS-08-00-overview.md`<br/>`contracts/specs/BS-08-graphic-editor/BS-08-01-modes.md`<br/>`contracts/specs/BS-08-graphic-editor/BS-08-02-skin-editor.md`<br/>`contracts/specs/BS-08-graphic-editor/BS-08-03-color-adjust.md`<br/>`contracts/specs/BS-08-graphic-editor/BS-08-04-rive-import.md`<br/>`contracts/specs/BS-08-graphic-editor/BS-08-05-preview-apply.md` |
| **변경 유형** | add |

## 변경 근거

현재 EBS 계약에 Graphic Editor 전용 행동 명세가 존재하지 않는다. team4 CLAUDE.md는 "Graphic Editor"를 Team 4의 3개 화면 중 하나로 명시하지만(`team4-cc/CLAUDE.md` §3개 화면), BS-01~07 어디에도 이 화면의 행동 명세가 없다. 반면 WSOP LIVE Confluence의 `EBS UI Design Action Tracker.md`와 `EBS UI Design.md` §3 Graphic Editor 섹션, 그리고 `team4-cc/ui-design/reference/skin-editor/EBS-Skin-Editor_v3.prd.md`에 PokerGFX 역설계 기반 8모드 구조(Board/Player/Dealer/House/Logo/Ticker/SSD/Action Clock)와 99개 컨트롤 매핑이 완전히 정의되어 있다. 이 조직 자산을 BS-08로 계약화하여 구현 혼란을 제거한다.

## 적용된 파일

_(없음 — REJECTED)_

## REJECT 사유

본 draft는 **CCR-011 (`ge-ownership-move`) 에 의해 명시적으로 대체**되었다. 두 CCR은 같은 BS-08 폴더를 정반대 방향으로 정의한다:

| 항목 | CCR-037 (이 draft, team4 제안) | CCR-011 (conductor 최종 결정) |
|------|-------------------------------|-------------------------------|
| GE 소유 | Team 4 CC 내부 Flutter 화면 | **Team 1 Lobby 탭** (Quasar + rive-js) |
| 편집 범위 | 8모드 × 99 컨트롤 풀 편집 | **메타데이터 + Import + Activate** 만 |
| Transform/keyframe 편집 | 포함 | **out-of-scope** (Rive 공식 에디터 사용) |
| 파일 체계 | `BS-08-01-modes`, `02-skin-editor`, `03-color-adjust`, `04-rive-import`, `05-preview-apply` | `BS-08-01-import-flow`, `02-metadata-editing`, `03-activate-broadcast`, `04-rbac-guards` |

CCR-011 의 reject 근거 (원본 인용):

> "기존 `CCR-DRAFT-team4-20260410-bs08-graphic-editor-new.md`는 CC 내부 Flutter 화면 + 8모드 99컨트롤 풀 편집을 가정하여 다음과 충돌:
> ① 'Settings는 글로벌' 원칙 (memory: feedback_settings_global.md),
> ② 멀티 CC 동기화 시 편집권 락 프로토콜 필요성,
> ③ Rive 공식 에디터와의 중복 투자,
> ④ YAGNI."

사용자(Conductor) 결정: **REJECT** (2026-04-10). 본 draft의 유용한 자산(8모드 정의, Rive Import 흐름, SkinChanged 이벤트)은 CCR-011 처리 시 Team 1 Lobby 허브 구조에 재매핑되어 통합됨. CCR-037은 이력 추적용으로만 보존된다.

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team4-20260410-bs08-graphic-editor-new.md` 참조

## 체크리스트

- [x] REJECT 결정 (CCR-011이 대체)
- [x] 원본 draft archived/ 이동
- [ ] team4 CLAUDE.md에서 "3개 화면 중 Graphic Editor" 항목 제거 — CCR-011 후속 작업 항목
- [ ] git commit `[CCR-037] REJECT: superseded by CCR-011 (GE ownership moved to Team 1 Lobby)`
