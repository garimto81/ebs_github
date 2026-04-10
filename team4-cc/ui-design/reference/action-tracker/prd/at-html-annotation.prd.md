---
doc_type: "prd"
doc_id: "PRD-AT-004"
version: "1.4.0"
status: "draft"
owner: "BRACELET STUDIO"
created: "2026-03-17"
last_updated: "2026-03-20"
phase: "phase-2"
priority: "medium"
parent_doc: "at-workflow.prd.md"
---

# PRD-AT-004: HTML UI Design + Annotation 워크플로우

## 1. 개요

- **목적**: PokerGFX 원본 스크린샷 6장을 기반으로 HTML UI Design을 설계하고, 해당 Design의 각 요소를 Annotation하는 워크플로우를 정의
- **워크플로우**: `스크린샷 → HTML UI Design (1차 산출물) → Annotation (2차 산출물)`
- **범위**: 6화면, 화면당 2파일 (UI Design HTML + Annotation HTML), 총 12파일

**문서 관계**:

| 문서 | doc_id | 관계 |
|------|--------|------|
| [Action Tracker PRD](action-tracker.prd.md) | PRD-AT-001 | 44개 기능 요구사항 (본 문서의 annotation이 근거) |
| [UI Design PRD](EBS-AT-UI-Design.prd.md) | PRD-AT-002 | EBS UI 설계 (본 문서의 UI Design이 입력물) |
| [워크플로우 PRD](at-workflow.prd.md) | PRD-AT-003 | Phase 2 체크리스트 2.8a/2.8b가 본 문서의 산출물 |
| **본 문서** | PRD-AT-004 | HTML UI Design + Annotation 설계 기준 및 체크리스트 |

**2-파일 구조 원칙**: 각 화면은 UI Design HTML(순수 UI 설계)과 Annotation HTML(오버레이 분석)로 분리하여 관심사를 분리한다.

## 2. 2-파일 구조 정의

화면당 2파일로 구성하여 **설계(Design)**와 **분석(Annotation)**을 분리한다.

| 파일 | 유형 | 역할 | 규격 |
|------|------|------|------|
| `at-{NN}-{name}.html` | UI Design (1차 산출물) | 스크린샷 기반 HTML/CSS UI 설계 | `data-element-*` 속성 포함, 원본과 시각적 동일 |
| `at-{NN}-{name}-annotated.html` | Annotation (2차 산출물) | UI Design 위 배지+바운딩박스 오버레이 | `anno-*` CSS 체계, `%` 단위 좌표 |

**디렉토리**: `docs/analysis/html_reproductions/` (기존 디렉토리 그대로 사용)

**파일 생성 순서**:
1. 원본 스크린샷 분석 → UI Design HTML 생성
2. UI Design HTML 기반 → Annotation HTML 생성 (오버레이 레이어 추가)
3. Annotation HTML 기반 → Annotation JSON 생성 (요소 좌표·프로토콜 매핑)

**의존 관계**:
```
스크린샷 (.png) ──→ UI Design HTML (.html) ──→ Annotation HTML (-annotated.html)
                                                        │
                                                        └──→ Annotation JSON (.json)
```

## 3. 6화면 목록

| # | 화면 | 원본 스크린샷 | 요소 수 | UI Design HTML | Annotation HTML |
|---|------|-------------|:-------:|----------------|-----------------|
| at-01 | Setup Mode | `at-01-setup-mode.png` | 90 | `at-01-setup-mode.html` | `at-01-setup-mode-annotated.html` |
| at-02 | Pre-Flop Action | `at-02-action-preflop.png` | 41 | `at-02-action-preflop.html` | `at-02-action-preflop-annotated.html` |
| at-03 | Card Selector | `at-03-card-selector.png` | 8 | `at-03-card-selector.html` | `at-03-card-selector-annotated.html` |
| at-04 | Post-Flop Action | `at-04-action-postflop.png` | 41 | `at-04-action-postflop.html` | `at-04-action-postflop-annotated.html` |
| at-05 | Statistics/Register | `at-05-statistics-register.png` | 22 | `at-05-statistics-register.html` | `at-05-statistics-register-annotated.html` |
| at-06 | RFID Registration | `at-06-rfid-registration.png` | 9 | `at-06-rfid-registration.html` | `at-06-rfid-registration-annotated.html` |

- 스크린샷 경로: `docs/analysis/`
- HTML 경로: `docs/analysis/html_reproductions/`
- 총 요소 수: **211개** (6화면 합산)

## 4. UI Design HTML 설계 기준

### 4.1 소스 및 목표

- **소스**: PokerGFX 원본 스크린샷 6장 (`docs/analysis/at-*.png`)
- **목표**: 스크린샷과 시각적으로 동일한 UI를 HTML/CSS로 설계
- **용도**: Annotation의 기반 레이아웃, EBS UI 설계의 역설계 참조

### 4.2 필수 data 속성

모든 인터랙티브 UI 요소에 다음 속성을 부여한다:

| 속성 | 형식 | 예시 |
|------|------|------|
| `data-element-id` | 화면 내 순번 (number) | `1`, `2`, `101` |
| `data-element-name` | 영문 요소명 | `game-type-dropdown` |
| `data-element-group` | 카테고리명 | `titlebar`, `player-slot`, `action-button` |

### 4.3 시각 규격

| 항목 | 규격 |
|------|------|
| 해상도 기준 | 786 x 553 px (원본 스크린샷 기준) |
| CSS 방식 | 인라인 `<style>` 블록, 외부 파일 참조 없음 (self-contained) |
| 폰트 | 시스템 sans-serif (`Segoe UI`, `Arial`) |
| 색상 | 원본 색상 최대한 근사 (eyedrop 기반) |
| 레이아웃 | CSS Grid/Flexbox, 구조화된 시맨틱 마크업 |

## 5. Annotation HTML 오버레이 구조

### 5.1 오버레이 CSS 체계

Annotation HTML은 UI Design HTML 위에 오버레이 레이어를 추가한다.

| CSS 클래스 | 역할 | 스타일 |
|-----------|------|--------|
| `anno-overlay` | 오버레이 컨테이너 + 바운딩박스 | `position: absolute`, `border: 2px solid`, 카테고리 색상 배경/테두리 |
| `anno-badge` | 배지 레이블 | 카테고리 색상 배경, 흰색 텍스트, `font-size: 9px` |
| `anno-tooltip` | 툴팁 정보 | `hover` 시 요소 상세 표시 (이름, 프로토콜, 카테고리) |
| `anno-cat-{name}` | 카테고리 색상 지정 | `anno-overlay`에 병합, 카테고리별 `border-color`/`background` |

> `anno-overlay`가 바운딩박스 역할을 겸한다 (별도 `anno-bbox` 클래스 불필요).

### 5.2 좌표 기준

- **단위**: `%` (퍼센트) — UI Design HTML 레이아웃 기준
- **기준점**: 컨테이너 좌상단 (0%, 0%)
- **bbox**: `{ x, y, w, h }` 각각 `%` 단위

### 5.3 카테고리 색상

25개 카테고리별 `anno-cat-{name}` 클래스로 색상을 지정한다. 화면에 따라 사용하는 카테고리가 다르다.

**공통 카테고리** (3개 이상 화면에서 사용):

| 카테고리 | CSS 클래스 | 배지 색상 | 테두리 색상 |
|---------|-----------|----------|------------|
| titlebar | `anno-cat-titlebar` | `#3498db` | `rgba(52,152,219,0.8)` |
| toolbar | `anno-cat-toolbar` | `#27ae60` | `rgba(46,204,113,0.8)` |
| seat | `anno-cat-seat` | `#e67e22` | `rgba(230,126,34,0.8)` |
| navigation | `anno-cat-navigation` | `#4caf50` | `rgba(76,175,80,0.8)` |

**Action 화면 카테고리** (at-02, at-04):

| 카테고리 | CSS 클래스 | 배지 색상 | 테두리 색상 |
|---------|-----------|----------|------------|
| card_icon | `anno-cat-card_icon` | `#f39c12` | `rgba(241,196,15,0.8)` |
| action_panel | `anno-cat-action_panel` | `#c0392b` | `rgba(231,76,60,0.8)` |
| action_button | `anno-cat-action_button` | `#8e44ad` | `rgba(155,89,182,0.8)` |
| community_cards | `anno-cat-community_cards` | `#00838f` | `rgba(0,188,212,0.8)` |
| info_bar | `anno-cat-info_bar` | `#009688` | `rgba(0,150,136,0.8)` |

**Setup 화면 카테고리** (at-01):

| 카테고리 | CSS 클래스 | 배지 색상 | 테두리 색상 |
|---------|-----------|----------|------------|
| card_area | `anno-cat-card_area` | `#f39c12` | `rgba(241,196,15,0.8)` |
| game_settings | `anno-cat-game_settings` | `#607d8b` | `rgba(96,125,139,0.8)` |
| hand_control | `anno-cat-hand_control` | `#00bcd4` | `rgba(0,188,212,0.8)` |
| option | `anno-cat-option` | `#9c27b0` | `rgba(156,39,176,0.8)` |
| position | `anno-cat-position` | `#ff5722` | `rgba(255,87,34,0.8)` |
| blind | `anno-cat-blind` | `#795548` | `rgba(121,85,72,0.8)` |

**Statistics/Card Selector 카테고리** (at-03, at-05):

| 카테고리 | CSS 클래스 | 배지 색상 | 테두리 색상 |
|---------|-----------|----------|------------|
| chrome | `anno-cat-chrome` | `#607d8b` | `rgba(96,125,139,0.8)` |
| display | `anno-cat-display` | `#00bcd4` | `rgba(0,188,212,0.8)` |
| action | `anno-cat-action` | `#e91e63` | `rgba(233,30,99,0.8)` |
| card_grid | `anno-cat-card_grid` | `#ff9800` | `rgba(255,152,0,0.8)` |
| table_header | `anno-cat-table_header` | `#3f51b5` | `rgba(63,81,181,0.8)` |
| table_data | `anno-cat-table_data` | `#607d8b` | `rgba(96,125,139,0.8)` |
| broadcast_control | `anno-cat-broadcast_control` | `#ff5722` | `rgba(255,87,34,0.8)` |
| input | `anno-cat-input` | `#009688` | `rgba(0,150,136,0.8)` |

**특수 카테고리** (단일 화면):

| 카테고리 | CSS 클래스 | 배지 색상 | 테두리 색상 | 화면 |
|---------|-----------|----------|------------|------|
| rfid | `anno-cat-rfid` | `#795548` | `rgba(121,85,72,0.8)` | at-06 |
| background | `anno-cat-background` | `#757575` | `rgba(158,158,158,0.8)` | at-06 |

### 5.4 배지 코드 체계

| 접두사 | 범위 | 용도 |
|--------|------|------|
| `COM-XX-NN` | 공통 요소 | 여러 화면에서 반복되는 UI 요소 (titlebar, status 등) |
| `SNN-NNN` | 화면 고유 | 해당 화면에서만 존재하는 UI 요소 |

- 총 배지 수: **134개**
- 공통 배지: 화면 간 공유 요소에 동일 코드 할당

## 6. Annotation JSON 스키마

### 6.1 파일 구조

```json
{
  "screen_id": "at-01",
  "screen_name": "Setup Mode",
  "dimensions": { "width": 786, "height": 553 },
  "elements": [
    {
      "id": 1,
      "name": "App Icon",
      "category": "titlebar",
      "bbox_pct": { "x": 0.3, "y": 0.2, "w": 2.0, "h": 3.2 },
      "visual": "PokerGFX 앱 아이콘 (작은 정사각형)",
      "protocol": "—",
      "note": "윈도우 타이틀바 아이콘",
      "annotation_text": "[COM-TB-01] 앱 아이콘"
    }
  ]
}
```

### 6.2 필드 정의

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `id` | number | Y | 화면 내 요소 순번 |
| `name` | string | Y | 영문 요소명 |
| `category` | string | Y | 25개 카테고리 중 하나 (§5.3 참조) |
| `bbox_pct` | object | Y | `%` 단위 바운딩박스 `{ x, y, w, h }` |
| `visual` | string | Y | 시각적 설명 (한글) |
| `protocol` | string | Y | EBS 프로토콜 메시지 또는 `"—"` |
| `note` | string | N | 추가 설명 |
| `annotation_text` | string | Y | 배지 텍스트 `[CODE] 이름` |

### 6.3 JSON 파일 경로

`docs/analysis/analysis/at-{NN}-{name}.json` (6파일)

## 7. 화면별 체크리스트

각 화면에 대해 3단계 산출물을 생성한다.

| # | 화면 | UI Design HTML | Annotation HTML | Annotation JSON |
|---|------|:--------------:|:---------------:|:---------------:|
| at-01 | Setup Mode (90요소) | 완료 | 완료 | 완료 |
| at-02 | Pre-Flop Action (41요소) | 완료 | 완료 | 완료 |
| at-03 | Card Selector (8요소) | 완료 | 완료 | 완료 |
| at-04 | Post-Flop Action (41요소) | 완료 | 완료 | 완료 |
| at-05 | Statistics/Register (22요소) | 완료 | 완료 | 완료 |
| at-06 | RFID Registration (9요소) | 완료 | 완료 | 완료 |

**산출물 요약**:
- UI Design HTML: 6/6 완료
- Annotation HTML: 6/6 완료
- Annotation JSON: 6/6 완료
- 총 산출물: **18파일** (HTML 12 + JSON 6)

## 8. Changelog

| 날짜 | 버전 | 변경 내용 | 변경 유형 | 결정 근거 |
|------|------|-----------|----------|----------|
| 2026-03-20 | v1.4.0 | AT-01 요소 수 92→90 반영 (81 Hand Number Input + 91 #BOARDS Value 제거, 82/83 재배치), 총 요소 수 213→211 | PRODUCT | 하단 레이아웃 정리: 82 SINGLE BOARD→78 아래, 83 SETTINGS→80 아래 |
| 2026-03-20 | v1.3.0 | AT-01 요소 수 98→92 반영 (game_settings ◀▶ 10개 + 인풋 1개 → 값 버튼 5개), 총 요소 수 219→213 | TECH | 게임 설정 입력 구조 단순화 |
| 2026-03-19 | v1.2.0 | AT-01 요소 수 83→98 반영 (blind 구조 변경 + game_settings 입력 버튼 추가), 총 요소 수 204→219 | TECH | PRD-AT-002 v1.4.0 + AT-Annotation-Reference 동기화 |
| 2026-03-17 | v1.1.0 | 실제 구현 기반 보정: anno-bbox 제거 (anno-overlay 통합), 25개 카테고리 색상 전수 반영, data-element-id 형식 수정 | TECH | Gap 분석(G-8) 결과 반영 |
| 2026-03-17 | v1.0.0 | 최초 작성 | - | HTML UI Design + Annotation 워크플로우 표준화 |
