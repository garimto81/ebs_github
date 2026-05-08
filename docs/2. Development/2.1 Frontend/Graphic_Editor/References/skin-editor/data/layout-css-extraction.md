---
title: layout-css-extraction
owner: team1
tier: internal
last-updated: 2026-04-15
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "레이아웃 CSS 추출 데이터 (15KB) 완결"
confluence-page-id: 3818750473
confluence-parent-id: 3811606750
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818750473/EBS+layout-css-extraction
---
# SE & GE 목업 CSS 레이아웃 추출 문서

**생성일**: 2026-03-16 | **대상**: Skin Editor (SE) + Graphic Editor (GE) 4가지 모드 (Board, Player, Blinds, Leaderboard)

---

## 1. EBS Skin Editor (SE) 레이아웃

**파일**: `docs/01-plan/mockups/ebs-skin-editor.html`
**뷰포트**: `max-width: 720px`
**배경**: `#F4F5F8` | **글꼴**: Inter 13px

### 전체 구조

```
┌─────────────────────────────────────────┐
│ Titlebar (10px 16px, #222326 배경)     │
│ Skin Editor — Titanium                  │
├─────────────────────────────────────────┤
│ Dialog Body (16px padding, flex column) │
│                                         │
│ ┌─── Zone: Metadata (01~05) ────┐ │
│ │ Name (40% width) | Details (flex) │ │
│ │ Remove Transparency | 4K Design    │ │
│ │ Adjust Size (slider)               │ │
│ └───────────────────────────────────┘ │
│                                         │
│ ┌──── Three-Column Layout ──────────┐ │
│ │ ┌─────┬─────────────┬──────────┐ │ │
│ │ │  L  │      C      │    R     │ │ │
│ │ │160px│    flex1    │  flex1   │ │ │
│ │ │     │             │          │ │ │
│ │ └─────┴─────────────┴──────────┘ │ │
│ └───────────────────────────────────┘ │
│                                         │
│ ┌──── Action Bar ────────────────────┐ │
│ │ [Adjust Colours]  ⎿spacer⏵  OK Cancel│ │
│ └───────────────────────────────────┘ │
│                                         │
│ Legend Bar (flex, 16px padding)        │
└─────────────────────────────────────────┘
```

### 섹션 상세

#### **Zone: Metadata (01 ~ 05)**
- **레이아웃**: Flex column, gap 10px
- **내용 1**: Name + Details (flex row, gap 12px)
  - Name: 40% width (01)
  - Details: flex 1 (02)
  - Control: `text-input` 12px, padding 6px 8px

- **내용 2**: Toggle 그룹 (flex row, gap 16px, flex-wrap)
  - 03: Remove Transparency (toggle 36x20px)
  - 04: 4K Design (toggle 36x20px)
  - 05: Adjust Size (slider, flex 1, min-width 140px)

#### **Three-Column Layout (메인 컨텐츠)**
```css
.three-col {
  display: grid;
  grid-template-columns: 160px 1fr 1fr;
  gap: 16px;
}
```

**Left Column (160px, col-left)**
- **06**: Element Grid (2x4 버튼)
  - `element-grid`: `grid-template-columns: repeat(2, 1fr)`, gap 6px
  - `element-btn`: padding 10px 4px, height auto, font-size 10px

- **27~29**: Colour Adjustment (expansion)
  - 28: Hue slider (range -180 ~ +180)
  - 29: Tint RGB (3개 슬라이더, 각 0~255 범위)

**Center Column (flex 1)**
- **07~26**: Visual & Behavior Settings (확장가능 섹션들)
- 각 섹션: expansion-header + expansion-body (flex column, gap 10px)

**Right Column (flex 1)**
- (현재 구조에서는 설명 부족, HTML 상세 필요)

#### **Action Bar (21 ~ 26)**
```css
.action-bar {
  display: flex;
  gap: 8px;
  align-items: center;
  padding-top: 12px;
  border-top: 1px solid #e5e5e5;
}
```
- `[Adjust Colours]` — primary button
- spacer (flex 1)
- `[OK]` + `[Cancel]` — secondary buttons

#### **색상 팔레트**
| 요소 | 색상 |
|------|------|
| 배경 | `#F4F5F8` |
| 다이얼로그 배경 | `#ffffff` |
| 타이틀바 | `#222326` |
| 테두리 | `#e5e5e5` |
| 라벨 텍스트 | `#555555` |
| 보조 텍스트 | `#8a8a8a` |
| 토글/슬라이더 활성 | `#222326` |

---

## 2. EBS Graphic Editor (GE) — 공통 구조

**프레임워크**: Quasar 2 (Vue 3)
**뷰포트**: `max-width: 720px, max-height: 1280px`
**배경**: `#F4F5F8`

### 공통 요소 구조

```
┌──────────────────────────────┐
│ q-header (bg-grey-10)        │
│ ┌─ q-toolbar ─────────────┐  │
│ │ Graphic Editor — {Mode} │  │
│ │ [close button]          │  │
│ └─────────────────────────┘  │
├──────────────────────────────┤
│ q-page (flex, column)        │
│                              │
│ ┌─── zone-canvas ────────┐  │
│ │ Canvas Area (responsive) │  │
│ │ [Element + Import selects] │  │
│ └──────────────────────────┘  │
│                              │
│ ┌─── Properties Panels ──┐  │
│ │ (모드별 레이아웃 상이)  │  │
│ └──────────────────────────┘  │
│                              │
│ ┌─── zone-actions ──────┐  │
│ │ [Adjust Colours] OK Cancel │  │
│ └──────────────────────────┘  │
│                              │
│ Legend Bar (조건부 표시)      │
└──────────────────────────────┘
```

### Canvas Area (모든 모드 공통)

```css
.canvas-area {
  background: #2a2a2a;  /* Board, Player, Leaderboard */
  /* 또는 #e0e0e0 (Blinds) */
  border: 1px solid #bdbdbd;
  border-radius: 4px;
  position: relative;
}

.canvas-el {
  position: absolute;
  border: 1px dashed #9e9e9e;
  background: rgba(255,255,255,0.06);
  border-radius: 2px;
  font-size: 10px;
  color: #bdbdbd;
  display: flex;
  align-items: center;
  justify-content: center;
}

.canvas-el.selected {
  border: 2px dashed #FFD700;
  color: #FFD700;
}
```

**각 모드별 Canvas 크기 (aspect-ratio)**:
| 모드 | 크기 | 요소 수 |
|------|------|--------|
| Board | 296×197 | 14개 |
| Player | 465×120 | 9개 |
| Blinds | 790×52 | 4개 |
| Leaderboard | 800×103 | 9개 |

### Element Selector Panel (모든 모드)

```css
.bottom-panels {
  display: grid;
  grid-template-columns: 120px 1fr;  /* Board only */
}

.el-panel {
  border-right: 1px solid #e0e0e0;
  background: #fafafa;
  overflow-y: auto;
}

.el-panel .q-item { min-height: 28px; padding: 0 6px; }
```

**Board 전용**: 좌측 Elements 패널 (120px) + 우측 Properties 그리드 (2x2)

---

## 3. GE Board Mode 상세

**파일**: `docs/01-plan/mockups/ebs-ge-board.html`

### 레이아웃 구조

```
┌─ q-page ───────────────────────────┐
│                                     │
│ ┌─ zone-canvas (border-bottom) ──┐│
│ │ Canvas: 296×197 aspect-ratio   ││
│ │ Card 1 ~ Card 5 (각 18% width) ││
│ │ Pot, Blinds, Hand #, ... (overlay) ││
│ │ [Element select] [Import Mode]  ││
│ └─────────────────────────────────┘│
│                                     │
│ ┌─ bottom-panels ─────────────────┐│
│ │ ┌─ el-panel (120px) ┬ ┬ ┬ ┬ ┐ ││
│ │ │ ELEMENTS header   │ │ │ │ ││
│ │ │ □ Card 1 (checked)││ │ │ │ ││
│ │ │ □ Card 2         ││ │ │ │ ││
│ │ │ ...              ││ │ │ │ ││
│ │ └───────────────────┴─┴─┴─┴─┘ ││
│ │     │     │     │     │       ││
│ │     │  props-2x2 (grid-cols: 1fr 1fr) ││
│ │     ├─ Transform ─┤ ├─ Text ──┤ ││
│ │     ├─ Animation ─┤ ├─ BG ───┤ ││
│ │     └─────────────┘ └────────┘ ││
│ └─────────────────────────────────┘│
│                                     │
│ ┌─ zone-actions ──────────────────┐│
│ │ [Adjust Colours]  ⎿spacer⏵ OK Cancel ││
│ └─────────────────────────────────┘│
│                                     │
│ Legend Bar                          │
└─────────────────────────────────────┘
```

### Props Grid (2×2)

```css
.props-2x2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
}

.props-2x2 > div {
  border: 1px solid #e0e0e0;
}
```

**좌상**: Transform (Left, Top, Width, Height, Z-order, Angle, Anchor H/V, Margins, Radius)
**우상**: Text (Font, Colour, Hilite, Alignment, Drop Shadow, Triggered by Language)
**좌하**: Animation (Transition In/Out, Speed, File imports)
**우하**: Background (Image upload, Import Mode)

---

## 4. GE Player Mode 상세

**파일**: `docs/01-plan/mockups/ebs-ge-player.html`

### 레이아웃 구조

```
Canvas: 465×120 aspect-ratio
Elements:
  - Photo (left, 14% width, full height)
  - Flag (top-left, 5% width, 22% height)
  - Position (15%, 8% width, 22% height)
  - NAME (center, 55% width, 40% height) — SELECTED
  - STACK (center, 55% width, 32% height)
  - Action (center, 35% width, 24% height)
  - Odds (right-center, 18% width, 24% height)
  - Card 1 (right, 11% width, 84% height)
  - Card 2 (far right, 11% width, 84% height)
```

### Properties Layout (3-Column)

```css
.three-col {
  display: grid;
  grid-template-columns: 1.2fr 1fr 1.3fr;  /* 비율 가변 */
}

.three-col > div {
  border-right: 1px solid #e0e0e0;
}

.three-col > div:last-child {
  border-right: none;
}
```

**좌측** (1.2fr): Transform
**중앙** (1fr): Animation
**우측** (1.3fr): Text + Background (2개 expansion)

---

## 5. GE Blinds Mode 상세

**파일**: `docs/01-plan/mockups/ebs-ge-blinds.html`

### Canvas 특징

```
Canvas: 790×52 aspect-ratio (매우 좁음)
Background: #2a2a2a
Elements:
  - Blinds (left, 14% width)
  - Amount "50,000/100,000" (14%~62%, 48% width)
  - Hand label (62%~72%, 10% width)
  - Hand # "123" (72%~100%, 28% width)
```

### Properties Layout (2×2 Grid)

```css
.grid-2x2 {
  display: grid;
  grid-template-columns: 1.15fr 1fr;
  grid-template-rows: auto auto;
}

.grid-2x2 > * {
  border: 1px solid #e0e0e0;
}
```

| | 우측 |
|---|------|
| **좌상** | Transform |
| **우상** | Text |
| **좌하** | Animation |
| **우하** | Background |

---

## 6. GE Leaderboard Mode 상세

**파일**: `docs/01-plan/mockups/ebs-ge-leaderboard.html`

### Canvas 특징

```
Canvas: 800×103 aspect-ratio
Elements:
  - Sponsor Logo (left, 8% width, 60% height, bottom-aligned)
  - Title (center, 10%~70%, 48% height, top)
  - Left/Centre/Right headers (10%~48%, 24% height, center)
  - Event Name (10%~70%, 48% height, bottom)
  - Player Photo (right, 8% width, 80% height) — SELECTED
  - Player Flag (right-offset, 5% width, 30% height)
  - Footer (right, 20% width, 20% height, bottom-right)
```

### Properties Layout (3-Column)

```
grid-template-columns: 1.2fr 1fr 1.3fr
```

**좌측**: Transform
**중앙**: Animation
**우측**: Text + Background

---

## 7. 공통 Form Control 스타일

### 색상 팔레트 (GE 공통)

| 요소 | 색상 |
|------|------|
| Canvas 배경 (어두움) | `#2a2a2a` |
| Canvas 배경 (밝음) | `#e0e0e0` |
| 라벨 텍스트 | `#9e9e9e`, `#bdbdbd` |
| 선택 highlight | `#FFD700` (황금색) |
| 패널 배경 | `#fafafa` |
| 헤더 배경 | `#F4F5F8` → `bg-grey-2` |
| 색상 견본 | 20×20px, 1px 테두리 |

### Input / Select 스타일 (Quasar)

```css
q-input, q-select, q-toggle, q-slider {
  dense: true;  /* 기본값 */
  outlined: true;  /* 기본값 */
  class: "q-mb-xs" /* 섹션 간 8px 여백 */
}
```

### Expansion Item (공통)

```css
q-expansion-item {
  default-opened: true
  dense: true
  header-class: "bg-grey-2"
  label: "Transform" | "Text" | "Animation" | "Background"
  icon: "open_with" | "text_fields" | "animation" | "image"
}

q-card-section {
  class: "q-py-xs q-px-sm"  /* padding-y: extra-small, padding-x: small */
}
```

---

## 8. 제약 조건 & 규격

### Viewport 제약

| 요소 | 값 |
|------|-----|
| max-width | 720px (모든 목업) |
| max-height | 1280px (GE 목록) |
| padding | 0 (body) |
| margin | 0 (body) |

### Responsive 특징

- **SE**: 고정 3열 (160px + 1fr + 1fr) — 반응형 없음
- **GE Board**: 고정 2열 (120px + 1fr) — 반응형 없음
- **GE Player/Leaderboard**: 3열 가변 비율 (1.2fr 1fr 1.3fr)
- **GE Blinds**: 2×2 그리드 (1.15fr 1fr)

### Canvas Aspect Ratio (aspect-ratio CSS 사용)

```
Board:       aspect-ratio: 296/197
Player:      aspect-ratio: 465/120
Blinds:      aspect-ratio: 790/52
Leaderboard: aspect-ratio: 800/103
```

---

## 9. 색상 견본 / 컬러 선택 UI

**모든 모드에서 동일**:

```css
.color-swatch {
  width: 20px;
  height: 20px;
  border: 1px solid #bdbdbd;
  border-radius: 3px;
  display: inline-block;
  vertical-align: middle;
  margin-right: 6px;
  flex-shrink: 0;
}

.color-row {
  display: flex;
  align-items: center;
  gap: 6px;
}

.bg-preview {
  width: 100%;
  height: 52px;
  background: #f5f5f5;
  border: 1px solid #e0e0e0;
  border-radius: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  color: #9e9e9e;
}
```

---

## 10. Legend Bar (조건부 표시)

```css
.legend-bar {
  display: none;  /* 기본 숨김 */
}

body.annotated .legend-bar {
  display: flex;
  justify-content: center;
  gap: 16px;
  flex-wrap: wrap;
  padding: 8px 16px;
  font-size: 10px;
  font-weight: 500;
  border-top: 1px solid #e5e5e5;
  background: #ffffff;
}
```

**범례 항목** (색상별):
- 보라 (#9C27B0): Canvas
- 초록 (#4CAF50): Elements (Board만)
- 파랑 (#2196F3): Transform
- 주황 (#FF9800): Text / Animation / Background
- 빨강 (#F44336): Actions

---

## 11. 주석 모드 (annotated)

`?annotated` URL 파라미터로 활성화:

```javascript
<script>
if (location.search.includes('annotated')) {
  document.body.classList.add('annotated');
}
</Script>
```

### 주석 표시 규칙

**SE**: zone 라벨 + 필드별 data-eid 표시 (예: 01, 06.3)
**GE**: zone 라벨만 표시 (Canvas, Elements, Transform, Text/Anim/BG, Actions)

---

## 요약 테이블

| 요소 | SE | GE Board | GE Player | GE Blinds | GE Leaderboard |
|------|----|---------:|----------:|----------:|---------------:|
| **뷰포트** | 720px max | 720px | 720px | 720px | 720px |
| **주요 레이아웃** | 3열 고정 | 2열 고정 | 3열 가변 | 2×2 그리드 | 3열 가변 |
| **Canvas 크기** | — | 296×197 | 465×120 | 790×52 | 800×103 |
| **Properties Grid** | 확장 섹션 | 2×2 | 3열 | 2×2 | 3열 |
| **색상 팔레트** | 명도 중간 | 어두움 | 어두움 | 밝음 | 어두움 |

---

**Document ID**: layout-css-extraction.md | **Version**: 1.0.0
**Last Updated**: 2026-03-16 | **Status**: Complete
