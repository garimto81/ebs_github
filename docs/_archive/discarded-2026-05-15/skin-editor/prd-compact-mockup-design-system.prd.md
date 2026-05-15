---
doc_type: "design-system"
doc_id: "PRD-CMD001"
version: "1.0.0"
status: "approved"
depends_on:
  - "PRD-0007-S2: ebs-ui-design-strategy.md (L2 전략)"
  - "EBS-Skin-Editor_v2.prd.md (01~61, GE-01~GE-23)"
owner: team1
tier: internal
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "PRD-CMD001 status=approved (20KB) — 디자인 시스템 확정"
confluence-page-id: 3819274944
confluence-parent-id: 3811606750
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819274944/EBS+Compact+Mockup+Design+System
discarded: "2026-05-15: absorbed into Lobby Settings"
---
# EBS Compact Mockup Design System

## 1장. 개요

### 1.1 목적
SE 목업(ebs-skin-editor.html)에서 검증된 compact CSS 토큰과 HTML 패턴을 정본화.
모든 EBS 목업(SE + GE 8종)에 동일 visual language 적용을 보장.

### 1.2 적용 대상
- Skin Editor 목업 (ebs-skin-editor.html) — 정본
- Graphic Editor 8종 (board, player, blinds, outs, strip, history, leaderboard, field)

### 1.3 기존 문서 관계
- ebs-ui-design-strategy.md (PRD-0007-S2): L2 전략 — Quasar 레벨 (SCSS 변수, 8px 그리드)
- **본 문서**: L1 전술 — Compact Mockup 레벨 (커스텀 HTML 컨트롤, 1-4px 간격)
- 관계: 전략 원칙을 극한 밀도 환경(720×480)에서 구현한 전술 사양

### 1.4 설계 원칙
| # | 원칙 | 설명 |
|:-:|------|------|
| 1 | 720×480 viewport | 16:9 비율, 모든 콘텐츠 스크롤 없이 표시 |
| 2 | 빈 공간 zero tolerance | 모든 영역의 수직 간격 공격적 압축 |
| 3 | 가독성 하한 9px | 최소 font-size 9px 유지 |
| 4 | SE↔GE 일관성 | 동일 컨트롤은 동일 CSS 클래스/사양 |
| 5 | Quasar 독립 | 목업은 커스텀 HTML만, Quasar CDN 불필요 |

---

## 2장. Color Tokens

SE 목업에서 추출한 정확한 값:

### 2.1 CSS Custom Properties

`body.body--dark` 선언부에 정의된 CSS 변수:

| Variable | Value | Usage |
|----------|-------|-------|
| `--ebs-surface` | `#2d2d30` | Input backgrounds, alt-row odd |
| `--ebs-panel` | `#252526` | Dialog/panel background, alt-row even |
| `--ebs-border` | `#3e3e42` | All borders, dividers |
| `--ebs-bg` | `#1e1e1e` | Body/page background |

### 2.2 Text Colors
| Token | Value | Usage |
|-------|-------|-------|
| text-primary | `#cccccc` | Default text, input values |
| text-secondary | `#808080` | Annotations, chevrons, disabled |
| text-muted | `#aaaaaa` | Field labels |
| text-dim | `#555` | Footer |

### 2.3 Accent Colors
| Token | Value | Usage |
|-------|-------|-------|
| accent-primary | `#0e639c` | Toggle checked, slider fill, btn-primary |
| titlebar-bg | `#1a1a1b` | Titlebar background |
| card-default | `#3a3a3e` | Mini card bg |
| toggle-handle-off | `#808080` | Toggle handle unchecked |
| toggle-handle-on | `#ffffff` | Toggle handle checked |
| hover-border | `#5a5a5e` | Input hover state (`.q-field--outlined:hover`) |
| hover-bg | `rgba(255,255,255,0.05)` | Flat button hover (`.btn-flat:hover`) |

### 2.4 Alt-row Colors
| Selector | Value |
|----------|-------|
| `.alt-row:nth-child(odd)` | `#2d2d30` |
| `.alt-row:nth-child(even)` | `#252526` |

### 2.5 Zone Annotation Palette
| Zone Class | Color | Label |
|------------|-------|-------|
| `.zone-metadata` | `#2196F3` | Blue |
| `.zone-elements` | `#4CAF50` | Green |
| `.zone-settings-visual` | `#FF9800` | Orange |
| `.zone-settings-behavior` | `#FF9800` | Orange |
| `.zone-actions` | `#F44336` | Red |
| `.zone-layout` | `#9C27B0` | Purple |
| `.zone-colour` | `#4CAF50` | Green |

---

## 3장. Typography Scale

| Role | Class/Selector | Size | Weight | Line-height | Color | 용도 |
|------|---------------|:----:|:------:|:-----------:|-------|------|
| Body default | `body.body--dark` | 11px | 400 | 1.2 | — | 기본 텍스트 |
| Field label | `.label` | 9px | 500 | — | #aaaaaa | 속성 라벨 |
| Input value | `.text-input`, `.num-input` | 12px | 400 | — | #cccccc | 폼 입력값 |
| Section header | inline | 10px | 600 | — | #cccccc | 섹션 제목 |
| Column header | `.col-header` | 9px | 600 | — | #808080 | 열 제목 (uppercase) |
| Button | `.btn` | 11px | 500 | — | #cccccc | 액션 버튼 |
| Button small | `.btn-sm` | 10px | 500 | — | #cccccc | 소형 버튼 |
| Element button | `.element-btn-custom` | 9px | 500 | 1.3 | #cccccc | Element Grid 버튼 |
| Select | `select` | 11px | — | — | #cccccc | 드롭다운 |
| Titlebar | `.ebs-titlebar` | 11px | 600 | — | #cccccc | 타이틀바 |
| Annotation EID | `.eid` | 10px | 400 | — | #808080 | Element ID (인라인) |
| Annotation block | `.eid-block` | 9px | 400 | — | #808080 | Element ID (블록) |
| AF label | `.af::before` | 8px | 600 | 1.4 | white | Annotated 필드 라벨 |
| Zone label | `zone-*::before` | 9px | 600 | — | white | Zone 이름 |
| Legend | `.legend-bar` | 9px | 500 | — | #cccccc | 범례 |
| Footer | `.ebs-footer` | 9px | — | — | #555 | 파일 경로 |
| Chevron (expanded) | inline `▼` | 8px | — | — | #808080 | 섹션 펼침 |
| Chevron (collapsed) | inline `▶` | 10px | — | — | #808080 | 섹션 접힘 |

**Font family**: `'Inter', sans-serif` (전역)

---

## 4장. Spacing Scale

### 4.1 Container Spacing
| Component | Padding | Gap | 비고 |
|-----------|---------|-----|------|
| `.ebs-titlebar` | `3px 10px` | — | 24px 높이 |
| `.ebs-body` | `1px 8px` | `1px` (col) | 주요 콘텐츠 |
| `.ebs-expansion-body` | `0 4px 1px 4px` | `1px` (col) | 섹션 본문 |
| `.action-bar` | `padding-top 2px` | `4px` | 하단 액션 |
| `.legend-bar` | `3px 10px` | `8px` | 범례 (annotated) |

### 4.2 Grid Spacing
| Component | Gap | Padding |
|-----------|-----|---------|
| `.four-col` | `6px` | — |
| `.element-grid` | `3px` | `2px 0` |
| `.col-header` | — | `1px 0 2px 0` (margin-bottom `1px`) |

### 4.3 Row Spacing
| Helper | Gap | Padding |
|--------|-----|---------|
| `.row` | `4px` | — |
| `.row-between` | `4px` | — |
| `.row-wrap` | `3px` | — |
| `.col` | `2px` | — |
| `.alt-row` | `4px` | `1px 4px` |

### 4.4 Section Header
| Property | Value |
|----------|-------|
| Container padding | `1px 0` |
| Display | `flex`, `align-items: center`, `gap: 3px` |
| Border | `border-bottom: 1px solid var(--ebs-border)` |

---

## 5장. Control Components

### 5.1 Toggle Switch (`.toggle`)

```css
.toggle {
  position: relative;
  display: inline-block;
  width: 24px;
  height: 12px;
  flex-shrink: 0;
}
.toggle input { opacity: 0; width: 0; height: 0; position: absolute; }
.toggle .track {
  position: absolute; top: 0; left: 0; right: 0; bottom: 0;
  background: #3e3e42; border-radius: 6px;
}
.toggle .track::after {
  content: ''; position: absolute; top: 2px; left: 2px;
  width: 8px; height: 8px; border-radius: 50%;
  background: #808080;
  box-shadow: 0 1px 2px rgba(0,0,0,0.3);
}
.toggle input:checked + .track { background: #0e639c; }
.toggle input:checked + .track::after { background: #ffffff; margin-left: 12px; }
```

### 5.2 Slider (`.slider-track` + `.slider-handle`)

```css
.slider-track {
  position: relative; height: 3px;
  background: #3e3e42; border-radius: 2px;
  flex: 1; min-width: 60px;
}
.slider-fill { position: absolute; top: 0; left: 0; height: 3px; background: #0e639c; border-radius: 2px; }
.slider-handle {
  position: absolute; top: -4px;
  width: 10px; height: 10px; border-radius: 50%;
  background: #cccccc; border: 2px solid #0e639c;
  box-shadow: 0 1px 3px rgba(0,0,0,0.4);
}
```

Handle position: `left: calc(N% - 5px)` (5px = handle 반경)

### 5.3 Number Input (`.num-input`)

```css
.num-input {
  font-family: 'Inter', sans-serif;
  font-size: 12px;
  color: #cccccc;
  border: 1px solid var(--ebs-border);
  border-radius: 5px;
  padding: 1px 3px;
  width: 40px;
  text-align: center;
  background: var(--ebs-surface);
}
```

### 5.4 Text Input (`.text-input`)

```css
.text-input {
  font-family: 'Inter', sans-serif;
  font-size: 12px;
  color: #cccccc;
  border: 1px solid var(--ebs-border);
  border-radius: 5px;
  padding: 2px 4px;
  background: var(--ebs-surface);
  outline: none;
  width: 100%;
}
textarea.text-input { resize: none; height: 20px; }
```

### 5.5 Select (`select`)

```css
select {
  font-family: 'Inter', sans-serif;
  font-size: 11px;
  color: #cccccc;
  border: 1px solid var(--ebs-border);
  border-radius: 5px;
  padding: 1px 4px;
  background: var(--ebs-surface);
  cursor: default;
}
select:disabled { opacity: 0.4; }
```

### 5.6 Color Swatch (`.color-swatch`)

```css
.color-swatch {
  display: inline-block;
  width: 14px; height: 14px;
  border: 1px solid var(--ebs-border);
  border-radius: 4px;
  vertical-align: middle;
  flex-shrink: 0;
  cursor: pointer;
}
.color-rule { display: flex; flex-direction: column; gap: 1px; padding: 2px 0; }
.color-rule + .color-rule { border-top: 1px solid var(--ebs-border); padding-top: 2px; }
```

### 5.7 Button (`.btn`)

```css
.btn {
  font-family: 'Inter', sans-serif;
  font-size: 11px;
  font-weight: 500;
  color: #cccccc;
  background: transparent;
  border: 1px solid var(--ebs-border);
  border-radius: 5px;
  padding: 2px 6px;
  cursor: default;
  white-space: nowrap;
}
.btn-primary { background: #0e639c; color: #ffffff; border-color: #0e639c; font-weight: 600; }
.btn-sm { font-size: 10px; padding: 2px 5px; }
.btn-flat { border-color: transparent; background: transparent; }
.btn-flat:hover { background: rgba(255,255,255,0.05); }
```

### 5.8 Mini Card (`.mini-card`) — Cards 섹션 전용

```css
.mini-card {
  width: 20px; height: 28px;
  border: 1px solid var(--ebs-border);
  border-radius: 4px;
  background: #3a3a3e;
  display: flex; align-items: center; justify-content: center;
  font-size: 10px; font-weight: 600; color: #cccccc;
}
.mini-card.back { background: #1e1e1e; color: #808080; font-size: 8px; }
```

### 5.9 Element Grid Button (`.element-btn-custom`)

```css
.element-btn-custom {
  font-family: 'Inter', sans-serif;
  font-size: 9px;
  font-weight: 500;
  color: #cccccc;
  background: var(--ebs-surface);
  border: 1px solid var(--ebs-border);
  border-radius: 5px;
  padding: 2px 2px;
  text-align: center;
  cursor: default;
  line-height: 1.3;
}
```

---

## 6장. Layout Containers

### 6.1 Dialog Container (`.ebs-dialog`)

```css
.ebs-dialog {
  background: var(--ebs-panel);
  border-radius: 12px;
  box-shadow: 0 4px 24px rgba(0,0,0,0.5);
  overflow: hidden;
  max-width: 720px;
}
```

### 6.2 Titlebar (`.ebs-titlebar`)

```css
.ebs-titlebar {
  background: #1a1a1b;
  color: #cccccc;
  padding: 3px 10px;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.2px;
  display: flex;
  align-items: center;
  border-bottom: 1px solid var(--ebs-border);
}
```

### 6.3 Body (`.ebs-body`)

```css
.ebs-body {
  padding: 1px 8px;
  display: flex;
  flex-direction: column;
  gap: 1px;
  background: var(--ebs-panel);
}
```

### 6.4 Multi-Column (`.four-col`)

```css
.four-col { display: flex; gap: 6px; align-items: stretch; }
.col-1, .col-2, .col-3, .col-4 {
  display: flex; flex-direction: column; gap: 0; min-width: 0;
}
.col-1 { flex: 1; }
.col-2 { flex: 1; }
.col-3 { flex: 1; }
.col-4 { flex: 0.85; }
```

### 6.5 Column Header (`.col-header`)

```css
.col-header {
  font-size: 9px;
  font-weight: 600;
  color: #808080;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  padding: 1px 0 2px 0;
  margin-bottom: 1px;
  border-bottom: 1px solid var(--ebs-border);
}
```

### 6.6 Action Bar (`.action-bar`)

```css
.action-bar {
  display: flex;
  gap: 4px;
  align-items: center;
  padding-top: 2px;
  border-top: 1px solid var(--ebs-border);
}
.action-bar .spacer { flex: 1; }
```

### 6.7 Footer (`.ebs-footer`)

```css
.ebs-footer {
  text-align: center;
  padding: 2px 0;
  font-size: 9px;
  color: #555;
  background: var(--ebs-bg);
}
```

---

## 7장. Section Pattern (Expansion)

### 7.1 Section Header (커스텀)

```html
<div style="display:flex;align-items:center;gap:3px;padding:1px 0;cursor:default;">
  <span style="font-size:8px;color:#808080;">▼</Span>
  <span style="font-size:10px;font-weight:600;color:#cccccc;">Section Title</Span>
</Div>
```

- 펼침: `▼` (font-size 8px)
- 접힘: `▶` (font-size 10px)
- 접힌 섹션은 `display:none` 또는 `v-show="false"` 처리

### 7.2 Section Body

```html
<div class="ebs-expansion-body">
  <div class="alt-row row-between">...</Div>
  <div class="alt-row row">...</Div>
</Div>
```

```css
.ebs-expansion-body {
  padding: 0 4px 1px 4px;
  display: flex;
  flex-direction: column;
  gap: 1px;
}
```

### 7.3 Alt-Row Pattern

```css
.alt-row:nth-child(odd)  { background: #2d2d30; }
.alt-row:nth-child(even) { background: #252526; }
.alt-row {
  padding: 1px 4px;
  display: flex;
  align-items: center;
  gap: 4px;
  border-radius: 2px;
}
```

### 7.4 Progressive Disclosure

| Tier | 상태 | SE 예시 | GE 예시 |
|------|------|---------|---------|
| T1 | 항상 펼침 | Text/Font, Chipcount | Transform |
| T2 | 1클릭 펼침 | Cards, Currency, Statistics | Text, Animation |
| T3 | Advanced (접힘) | Card Display, Misc | Background |

---

## 8장. Annotation System

### 8.1 3 Display Modes

| Mode | URL Param | 동작 |
|------|-----------|------|
| Default | (없음) | 모든 annotation 표시 (eid, eid-block, p2-label) |
| Clean | `?clean` | 모든 annotation 숨김 |
| Annotated | `?annotated` | eid/eid-block 숨김 + zone outline + AF labels + legend |

### 8.2 Zone Bounding Box

```css
body.annotated .zone-metadata {
  outline: 2px solid #2196F3;
  outline-offset: 3px;
  position: relative;
}
/* 각 zone 동일 패턴, color만 상이 */
```

Zone label (`::before` pseudo-element):

```css
body.annotated .zone-metadata::before {
  content: 'Metadata  01 ~ 05';
  position: absolute; top: -14px; left: 0;
  font-size: 9px; font-weight: 600; padding: 1px 6px;
  background: #2196F3; color: white; border-radius: 2px; z-index: 10;
}
```

### 8.3 Element AF (Annotated Field)

```html
<div class="af" data-eid="07">...</Div>
```

```css
body.annotated .af {
  position: relative;
  outline: 1px solid var(--zc, #999);
  outline-offset: 1px;
  border-radius: 3px;
}
body.annotated .af::before {
  content: attr(data-eid);
  position: absolute; top: -11px; left: 0;
  font-size: 8px; font-weight: 600; padding: 0px 3px;
  background: var(--zc, #999); color: white;
  border-radius: 2px; line-height: 1.4;
  z-index: 10; white-space: nowrap;
}
```

### 8.4 Zone-to-AF Color Inheritance

```css
.zone-metadata .af          { --zc: #2196F3; }
.zone-elements .af          { --zc: #4CAF50; }
.zone-settings-visual .af   { --zc: #FF9800; }
.zone-settings-behavior .af { --zc: #FF9800; }
.zone-actions .af           { --zc: #F44336; }
.zone-layout .af            { --zc: #9C27B0; }
.zone-colour .af            { --zc: #4CAF50; }
```

### 8.5 Legend Bar

```css
.legend-bar {
  display: none;
  justify-content: center;
  gap: 8px;
  padding: 3px 10px;
  font-size: 9px;
  font-weight: 500;
  border-top: 1px solid var(--ebs-border);
  background: var(--ebs-panel);
  color: #cccccc;
}
body.annotated .legend-bar { display: flex; flex-wrap: wrap; }
.legend-item { display: flex; align-items: center; gap: 4px; }
.legend-swatch { width: 10px; height: 10px; border-radius: 2px; }
```

### 8.6 Mode Toggle Script

```javascript
var q = location.search;
if (q.includes('clean'))     document.body.classList.add('clean');
if (q.includes('annotated')) document.body.classList.add('annotated');
```

---

## 9장. GE 목업 적용 지침

### 9.1 적용 대상

| # | 파일 | 패턴 | 캔버스 크기 | 서브요소 수 |
|:-:|------|:----:|:----------:|:----------:|
| 1 | ebs-ge-board.html | A | 296×197 | 14 |
| 2 | ebs-ge-player.html | C | 465×120 | 가변 |
| 3 | ebs-ge-blinds.html | B | 790×52 | 4 |
| 4 | ebs-ge-outs.html | C | 465×120 | 6 |
| 5 | ebs-ge-strip.html | A | 296×197 | 가변 |
| 6 | ebs-ge-history.html | B | 790×52 | 7 |
| 7 | ebs-ge-leaderboard.html | C | 800×103 | 9 |
| 8 | ebs-ge-field.html | A | 296×197 | 가변 |

### 9.2 Quasar → 커스텀 HTML 매핑

| Quasar Component | 커스텀 대체 | CSS 클래스 |
|------------------|-----------|-----------|
| `QLayout` + `QToolbar` (50px) | `.ebs-dialog` + `.ebs-titlebar` (24px) | §6.1, §6.2 |
| `QToolbar` (action) | `.action-bar` (28px) | §6.6 |
| `QExpansionItem` | 커스텀 section (§7.1 + §7.2) | chevron toggle |
| `QInput[type=number]` | `<input class="num-input">` | §5.3 |
| `QInput[type=text]` | `<input class="text-input">` | §5.4 |
| `QSelect` | `<select>` | §5.5 |
| `QToggle` | `.toggle` | §5.1 |
| `QSlider` | `.slider-track` + `.slider-handle` | §5.2 |
| `QBtn` | `<button class="btn">` | §5.7 |
| `QCheckbox` | `<input type="checkbox">` (native) | — |
| `QList` + `QItem` | `<div class="el-item">` | alt-row 패턴 |

### 9.3 720×480 공간 예산 템플릿

```
Titlebar:           24px   (.ebs-titlebar)
Main content:      424px   (패턴별 레이아웃)
Action bar:         28px   (.action-bar)
Footer:              4px   (.ebs-footer)
──────────────────────────
합계:              480px
```

### 9.4 패턴별 가로 배분 (720px)

**패턴 A** (3열: Board, Strip, Field)

```
Elements: 100px | Canvas: flex:1 (~358px) | Props: 260px
```

**패턴 B** (전폭+2열: Blinds, History)

```
Canvas: 전폭 (720px, 높이 ~60px)
하단 2열: Elements 200px | Props flex:1 (~520px)
```

**패턴 C** (전폭+3열: Player, Outs, Leaderboard)

```
Canvas: 전폭 (720px, 높이 ~120px)
하단 3열: Elements 120px | Transform ~300px | Text/Anim ~300px
```

### 9.5 Properties 패널 2-col 최적화

수직 공간 절약을 위해 Properties 패널의 필드를 2열로 배치:

```html
<div class="prop-grid-2" style="display:grid;grid-template-columns:1fr 1fr;gap:2px;">
  <div class="alt-row row">Left [___]</Div>
  <div class="alt-row row">Top [___]</Div>
</Div>
```

**색상 필드 쌍**: Colour + Hilite를 한 행에 배치

```
| Colour [■][hex] | Hilite [■][hex] |
```

**Toggle+Select 쌍**: 관련 컨트롤을 한 행에 배치

```
| Visible [toggle] | Font [select] |
```

### 9.6 스크린샷 캡처 표준

```javascript
// Playwright (Node.js)
const { chromium } = require('playwright');
const page = await browser.newPage({ viewport: { width: 720, height: 480 } });
await page.goto('file:///path/to/mockup.html');
const dialog = page.locator('.ebs-dialog');
await dialog.screenshot({ path: 'docs/images/output.png' });

// Annotated mode
await page.goto('file:///path/to/mockup.html?annotated');
await dialog.screenshot({ path: 'docs/images/output-annotated.png' });
```

### 9.7 검증 체크리스트

모든 GE 목업 재설계 시 아래 항목을 확인:

- [ ] `.ebs-dialog` 높이 ≤ 490px (clean 모드 기준)
- [ ] 모든 컨트롤 잘림 없이 표시
- [ ] 텍스트 가독성 유지 (최소 font-size 9px)
- [ ] Canvas 비율 유지, 모든 요소 표시
- [ ] Annotated 모드 zone 정상 표시
- [ ] SE 목업과 동일한 visual language
- [ ] Quasar CDN 의존성 완전 제거

### 9.8 Preview 분리 원칙

Preview(Canvas)와 Properties(Transform/Text/Animation/BG)는 독립 영역:

| 영역 | 크기 | 위치 | 스크롤 |
|------|------|------|--------|
| Preview | 가변 (디자인 기반) | 헤더/상단 | 없음 |
| Properties | 고정 (콘텐츠 기반) | 하단/우측 | 없음 (접힘/펼침) |
| Elements | 고정 (항목 수 기반) | 좌측 span | 없음 |

- 스크롤 완전 금지 — overflow-y: auto/scroll 사용 금지
- 수직 공간 관리는 섹션 접힘/펼침(accordion)으로만 수행
- Preview 크기는 스펙 규격(296×197 등)과 일치시킬 필요 없음
- Canvas aspect-ratio 사용 시 `height` 고정 + `max-width:100%` (width:100% + max-height 금지)
- Properties 행에 flex:1 균등 분배 금지 — 자연 크기 유지

---

## Changelog

| 날짜 | 버전 | 변경 내용 | 변경 유형 | 결정 근거 |
|------|------|-----------|----------|----------|
| 2026-03-17 | v1.2.0 | §9.8 no-scroll 정책 반영 — overflow-y 금지, accordion 전용 | PRODUCT | 480px viewport 스크롤 제거, 접힘/펼침으로 수직 공간 관리 |
| 2026-03-17 | v1.1.0 | §9.8 Preview 분리 원칙 추가 | PRODUCT | Preview 가변/Properties 고정 아키텍처 명문화 |
| 2026-03-16 | v1.0.0 | 최초 작성 — SE 목업에서 토큰 추출 | PRODUCT | SE 720×480 재설계 완료, GE 8종 동일 적용 필요 |
