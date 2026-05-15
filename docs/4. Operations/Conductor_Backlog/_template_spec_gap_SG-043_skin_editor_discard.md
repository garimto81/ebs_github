---
id: SG-043
title: "기획 결정: EBS Skin Editor 폐기 — Lobby Settings GFX 탭 흡수"
type: spec_decision
status: DONE
owner: conductor
created: 2026-05-15
resolved: 2026-05-15
affects_chapter:
  - docs/1. Product/Lobby.md §부록 D
  - docs/2. Development/2.1 Frontend/Lobby/Overview.md §UI 화면 설계
  - docs/2. Development/2.1 Frontend/Settings/Graphics.md §2 §6
  - docs/2. Development/2.1 Frontend/Graphic_Editor/Overview.md (참조 전용)
  - docs/_archive/discarded-2026-05-15/skin-editor/ (폐기 아카이브 16개 파일)
protocol: Spec_Gap_Triage
stream: S10-W
cycle: 21
broker_publish: pipeline:spec-patched
---

# SG-043 — EBS Skin Editor 폐기 + Lobby Settings GFX 탭 흡수

## 결정 (사용자 직접 결정, 2026-05-15)

> **"EBS Skin Editor discarded - absorbed into Lobby Settings"**

- **채택**: 폐기 + Settings 흡수
- **이유**: Skin Editor (독립 Graphic Editor 탭) 는 EBS 운영 5분 게이트웨이 가치에서 제외. 핵심 스킨 기능(선택·활성화)은 Settings GFX 탭에 이미 존재. Upload/Preview/Metadata 편집은 Rive 공식 에디터 담당.
- **영향 챕터 업데이트 PR**: `s10-w/cycle-21-skin-editor-discard` → PR 생성 (S10-W Cycle 21)
- **Confluence 처리 권고** (사용자 결정 영역, S10-W 자율 X):
  - WSOPLive v2 Skin Editor 관련 페이지 → archive 권고
  - personal space v3 PRD 페이지 → 사용자 결정 영역

---

## 변경 요약

### 폐기된 것

| 항목 | 위치 | 사유 |
|------|------|------|
| Skin Editor PRD 16개 파일 | `Graphic_Editor/References/skin-editor/` | 독립 스킨 에디터 개념 폐기 |
| Lobby 헤더 `[Graphic Editor]` 버튼 | Lobby 화면 구조 | 독립 진입점 폐기 |
| Upload / Metadata 편집 / Rive 프리뷰 기능 | GE Overview | EBS 운영 범위 외 |

### 흡수된 것 (Lobby Settings GFX 탭)

| 기능 | 위치 | 비고 |
|------|------|------|
| 스킨 선택 (Active Skin 드롭다운) | `Settings/Graphics.md §6` | 이미 존재 — 변경 없음 |
| 스킨 활성화 (`PUT /api/v1/Skins/{id}/Activate`) | `Settings/Graphics.md §6.2` | 이미 존재 — 변경 없음 |

### 아카이브 위치

`docs/_archive/discarded-2026-05-15/skin-editor/` — 16개 .md 파일, frontmatter `discarded: "2026-05-15: absorbed into Lobby Settings"` 추가됨.

---

## 영향받는 챕터 / 구현

- `Settings/Graphics.md`: §2 섹션 업데이트 (폐기 선언 + 흡수 위치), 개요 블록 note 갱신
- `Lobby/Overview.md`: changelog 2026-05-15 항목 추가, 화면 표 Graphic Editor 행 폐기 표시, 변경 블록 2026-05-15 discard note 추가
- `Lobby.md` (external PRD v3.0.6): 부록 D §D.2 GFX 탭 흡수 노트 추가, GFX 행 Active Skin 설명 보강

---

## Confluence 처리 권고 (비자율 — 사용자 결정)

| 공간 | 페이지 | 권고 |
|------|--------|------|
| WSOPLive v2 | EBS Skin Editor 관련 페이지 | archive 또는 "Deprecated" 배너 추가 |
| Personal v3 | Skin Editor PRD v3 페이지 | 사용자 결정 필요 |

> 이 권고는 S10-W 자율 영역 밖 — 실행은 사용자 직접 또는 별도 cycle 위임.
