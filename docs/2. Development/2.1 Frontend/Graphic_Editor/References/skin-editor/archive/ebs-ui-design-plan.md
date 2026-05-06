---
doc_type: "implementation-plan"
doc_id: "PLAN-UI-001"
version: "1.0.0"
status: "SUPERSEDED"
superseded-by: "B-209 (회의 D3 GE 제거) + SG-014 SUPERSEDED + SG-021 (.gfskin → .riv 전환 DONE)"
superseded-date: 2026-04-27
depends_on:
  - "PRD-0007-S2: ebs-ui-design-strategy.md (전략)"
  - "EBS-Skin-Editor.prd.md (UI 설계 v1.5.0)"
  - "PRD-0007: prd-skin-editor-layout-references.prd.md (벤치마크)"
  - "PRD-0007-S1: skin-editor-layout-balance-solutions.md (솔루션)"
owner: team1
tier: internal
last-updated: 2026-05-03
reimplementability: N/A
reimplementability_checked: 2026-05-03
reimplementability_notes: "SUPERSEDED 2026-04-27 — Graphic Editor 영역 회의 D3 결정으로 폐기 (.gfskin → Rive 내장 .riv 전환). 신 SSOT: SG-021 + Foundation §5.3 Rive Manager"
---
# EBS UI Design 구현 계획

## 1장. 개요

PRD-0007-S2 전략 문서를 Quasar Framework 구현으로 변환하는 실행 계획.

| 항목 | 내용 |
|------|------|
| 범위 | Skin Editor (QDialog) + Graphic Editor (QDialog) + 공유 컴포넌트 |
| 기술 스택 | Vue 3 + Quasar Framework v2 + Pinia + TypeScript |
| 입력 | PRD-0007-S2 (전략), EBS-Skin-Editor.prd.md (UI 설계), PRD-0007 (벤치마크), PRD-0007-S1 (솔루션) |

### 전략 → 구현 매핑

| 전략 (PRD-0007-S2) | 구현 항목 |
|---------------------|----------|
| 1장 5대 설계 원칙 | 전 Phase에 걸쳐 적용 |
| 2장 레이아웃 아키텍처 | Phase 1 QSplitter 3열 + Phase 3 GfxEditorBase A/B/C |
| 3장 시각 디자인 시스템 | Phase 1 `quasar.variables.scss` + `editor-shared.scss` |
| 4장 정보 아키텍처 | Phase 2 T1/T2/T3 QExpansionItem 접이식 |
| 5장 Phase별 로드맵 | Phase 1~4 태스크 분해 (6장) |
| 6장 SE↔GE 일관성 | 공유 컴포넌트 8종 (4장) |
| 7장 검증 전략 | 검증 계획 (7장) |

---

## 2장. 프로젝트 구조

```
src/
├── css/
│   ├── quasar.variables.scss    ← Quasar Brand + EBS 커스텀
│   └── editor-shared.scss       ← SE+GE 공유 스타일
├── components/
│   ├── editor/                  ← 공유 에디터 컴포넌트 8종
│   │   ├── EbsSectionHeader.vue
│   │   ├── EbsPropertyRow.vue
│   │   ├── EbsColorPicker.vue
│   │   ├── EbsNumberInput.vue
│   │   ├── EbsSlider.vue
│   │   ├── EbsToggle.vue
│   │   ├── EbsSelect.vue
│   │   └── EbsActionBar.vue
│   ├── skin-editor/             ← SE 전용
│   │   ├── SkinEditorDialog.vue ← 메인 QDialog
│   │   ├── SkinMetadata.vue     ← 01~05
│   │   ├── ElementGrid.vue      ← 06
│   │   ├── ColourAdjust.vue     ← 27~30
│   │   ├── VisualSettings.vue   ← 07~20
│   │   └── BehaviourSettings.vue ← 31~61
│   └── graphic-editor/          ← GE 전용
│       ├── GfxEditorDialog.vue  ← 메인 QDialog (mode prop)
│       ├── GfxEditorBase.vue    ← 공통 패널 컨테이너 (A/B/C 분기)
│       ├── EbsGfxCanvas.vue     ← GE-01 커스텀 Canvas
│       ├── ElementSelector.vue  ← GE-02
│       ├── TransformPanel.vue   ← GE-03~GE-08
│       ├── AnimationPanel.vue   ← GE-09~GE-14
│       ├── TextPanel.vue        ← GE-15~GE-22
│       └── BackgroundPanel.vue  ← GE-23
├── stores/
│   └── useSkinStore.ts          ← ConfigurationPreset Pinia Store
└── types/
    └── skin-types.ts            ← ConfigurationPreset 타입 정의
```

---

## 3장. Quasar 테마 설정

### `quasar.variables.scss`

```scss
// src/css/quasar.variables.scss
// Quasar Brand 8색 — VS Code Dark+ 계열
$primary   : #0e639c;
$secondary : #26a69a;
$accent    : #9c27b0;
$dark      : #1e1e1e;
$positive  : #21ba45;
$negative  : #c10015;
$info      : #31ccec;
$warning   : #f2c03e;

// EBS 커스텀 확장 5색
$ebs-surface   : #2d2d30;
$ebs-panel     : #252526;
$ebs-hover     : #2a2d2e;
$ebs-border    : #3c3c3c;
$ebs-text-muted: #969696;
```

### `editor-shared.scss`

```scss
// src/css/editor-shared.scss
@import './Quasar.variables';

// 교차 배경색 (Unity Inspector 패턴)
.property-row:nth-child(odd)  { background: $ebs-surface; }
.property-row:nth-child(even) { background: $ebs-panel; }

// 커스텀 폰트
.font-mono { font-family: 'Consolas', 'Courier New', monospace; }
```

### `quasar.config.js` 설정

```js
// quasar.config.js (관련 부분)
framework: {
  config: {
    dark: true  // Dark Mode 기본 활성화
  },
  plugins: ['Dialog', 'Notify', 'Loading']
}
```

---

## 4장. 공유 컴포넌트 8종 설계

### EbsSectionHeader.vue

접이식 섹션 헤더. SE/GE 모든 섹션의 일관된 접이식 패턴.

```typescript
interface EbsSectionHeaderProps {
  label: string;
  tier: 1 | 2 | 3;        // T1=항상 펼침, T2=1클릭, T3=Advanced
  group?: string;          // QExpansionItem group
}
```

Quasar 의존성: `QExpansionItem`, `QCard`, `QCardSection`

```vue
<template>
  <q-expansion-item
    :label="label"
    :default-opened="tier === 1"
    :group="group"
    header-class="text-subtitle1 text-weight-bold"
    expand-icon-class="text-grey-6"
  >
    <q-card flat>
      <q-card-section class="q-pa-sm">
        <slot />
      </QCardSection>
    </QCard>
  </QExpansionItem>
</Template>
```

### EbsPropertyRow.vue

라벨+컨트롤 행. 교차 배경색 자동 적용.

```typescript
interface EbsPropertyRowProps {
  label: string;
}
```

Quasar 의존성: 없음 (CSS 유틸리티만 사용)

```vue
<template>
  <div class="row items-center q-py-xs property-row">
    <div class="col-5 text-body2 q-pl-sm">{{ label }}</Div>
    <div class="col-7"><slot /></Div>
  </Div>
</Template>
```

### EbsColorPicker.vue

```typescript
interface EbsColorPickerProps {
  modelValue: string;      // hex color (#RRGGBB)
  label?: string;
}
```

Quasar 의존성: `QColor`, `QPopupProxy`, `QBtn`

사용 예시: `<ebs-color-picker v-model="store.textColour" label="Text" />`

### EbsNumberInput.vue

```typescript
interface EbsNumberInputProps {
  modelValue: number;
  min?: number;
  max?: number;
  step?: number;
  suffix?: string;         // "px", "°", "ms"
}
```

Quasar 의존성: `QInput`

사용 예시: `<ebs-number-input v-model="left" :min="0" :max="3840" suffix="px" />`

### 나머지 4종 요약

| 컴포넌트 | Props 핵심 | Quasar 의존성 |
|----------|-----------|---------------|
| `EbsSlider` | `modelValue`, `min`, `max`, `step`, `labelAlways` | `QSlider` |
| `EbsToggle` | `modelValue`, `label` | `QToggle` |
| `EbsSelect` | `modelValue`, `options`, `emitValue`, `mapOptions` | `QSelect` |
| `EbsActionBar` | `buttons: ActionButton[]` | `QBtn`, `QSeparator` |

### GfxEditorBase.vue (A/B/C 레이아웃 분기)

```typescript
interface GfxEditorBaseProps {
  mode: 'board' | 'player' | 'blinds' | 'outs' | 'strip'
    | 'history' | 'leaderboard' | 'field' | 'clock';
  pattern: 'A' | 'B' | 'C';
}
```

```vue
<template>
  <!-- Pattern A: 3-Column (Board, Field, Strip) -->
  <div v-if="pattern === 'A'" class="row items-stretch" style="height: 100%">
    <div class="col-auto q-pa-sm" style="width: 160px; overflow-y: auto;">
      <element-selector :mode="mode" />
    </Div>
    <div class="col q-pa-sm">
      <ebs-gfx-canvas :mode="mode" />
    </Div>
    <div class="col-auto q-pa-sm" style="width: 280px; overflow-y: auto;">
      <transform-panel />
      <animation-panel />
      <text-panel v-if="hasText" />
      <background-panel />
    </Div>
  </Div>
  <!-- Pattern B: Canvas Top + 2x2 Grid (Blinds, History) -->
  <div v-else-if="pattern === 'B'" class="column">
    <ebs-gfx-canvas :mode="mode" class="q-mb-md" />
    <div class="row q-gutter-md">
      <div class="col-6"><transform-panel /><text-panel v-if="hasText" /></Div>
      <div class="col-6"><animation-panel /><background-panel /></Div>
    </Div>
  </Div>
  <!-- Pattern C: Canvas Top + 3-col (Player, Outs, Leaderboard) -->
  <div v-else class="column">
    <ebs-gfx-canvas :mode="mode" class="q-mb-md" />
    <div class="row q-gutter-md">
      <div class="col"><transform-panel /></Div>
      <div class="col"><animation-panel /></Div>
      <div class="col"><text-panel v-if="hasText" /><background-panel /></Div>
    </Div>
  </Div>
</Template>
```

### SkinEditorDialog.vue (메인 레이아웃)

```vue
<template>
  <q-dialog persistent maximized>
    <q-card class="column" style="height: 100vh">
      <!-- Metadata (01~05) -->
      <skin-metadata class="q-pa-md" />
      <!-- 3-Column Body: QSplitter 중첩 -->
      <q-splitter v-model="leftRatio" :limits="[15, 35]" class="col">
        <template #before>
          <div class="column q-pa-sm" style="height: 100%">
            <element-grid />
            <colour-adjust class="col" />  <!-- flex-grow: 1 -->
          </Div>
        </Template>
        <template #after>
          <q-splitter v-model="rightRatio" :limits="[40, 70]">
            <template #before>
              <visual-settings class="q-pa-sm" style="overflow-y: auto" />
            </Template>
            <template #after>
              <behaviour-settings class="q-pa-sm" style="overflow-y: auto" />
            </Template>
          </QSplitter>
        </Template>
      </QSplitter>
      <!-- Action Bar (21~26) -->
      <ebs-action-bar :buttons="skinEditorButtons" />
    </QCard>
  </QDialog>
</Template>
```

---

## 5장. Pinia Store 설계

### `useSkinStore` 구조

```typescript
// stores/useSkinStore.ts
import { defineStore } from 'pinia';
import { shallowRef } from 'vue';
import type { ConfigurationPreset } from '@/Types/SkinTypes';

export const useSkinStore = defineStore('skin', () => {
  // shallowRef: deep reactivity 방지 (187+ 필드 성능 보호)
  const preset = shallowRef<ConfigurationPreset>(createDefaultPreset());
  const isDirty = ref(false);

  // Getters
  const modeElements = computed(() => (mode: string) =>
    getElementsForMode(preset.value, mode)
  );
  const t1Sections = computed(() => filterByTier(preset.value, 1));
  const t2Sections = computed(() => filterByTier(preset.value, 2));
  const t3Sections = computed(() => filterByTier(preset.value, 3));

  // Actions
  async function loadGfskin(file: File) { /* ZIP 해제 → JSON 파싱 → preset 갱신 */ }
  async function saveGfskin() { /* preset → JSON → ZIP → .gfskin 다운로드 */ }
  function applyToCanvas() { /* preset → GPU Canvas 반영 (26 USE) */ }
  function resetToDefault() { /* 기본 프리셋 복원 (24 RESET) */ }

  return { preset, isDirty, modeElements, t1Sections, t2Sections, t3Sections,
           loadGfskin, saveGfskin, applyToCanvas, resetToDefault };
});
```

### Debounce 전략

| 컨트롤 유형 | Debounce | 이유 |
|:---:|:---:|------|
| QInput (텍스트/숫자) | 300ms | 키 입력마다 반응 체인 방지 |
| QSlider | 100ms | 부드러운 드래그 + 적절한 갱신 빈도 |
| QToggle / QSelect | 즉시 | 이산값, 반응 체인 짧음 |

---

## 6장. Phase별 구현 로드맵

### Phase 1 (1-2일): Foundation

| # | 태스크 | 파일 | 산출물 |
|:-:|--------|------|--------|
| 1.1 | Quasar 프로젝트 초기화 | `quasar.config.js`, `quasar.variables.scss` | Brand 테마 + Dark Mode |
| 1.2 | 공유 컴포넌트 4종 | `components/editor/EbsSectionHeader.vue` 외 3종 | SectionHeader, PropertyRow, NumberInput, Select |
| 1.3 | SkinEditorDialog 스켈레톤 | `SkinEditorDialog.vue` | QSplitter 중첩 3열 레이아웃 |
| 1.4 | ElementGrid 구현 | `ElementGrid.vue` | 4×2 QBtn Grid (06) |
| 1.5 | useSkinStore 기본 | `stores/useSkinStore.ts`, `types/skin-types.ts` | ConfigurationPreset 타입 + 초기 상태 |

### Phase 2 (1 스프린트): Core Editor

| # | 태스크 | 파일 | 산출물 |
|:-:|--------|------|--------|
| 2.1 | SkinMetadata (01~05) | `SkinMetadata.vue` | 5개 컨트롤 |
| 2.2 | VisualSettings (07~20) | `VisualSettings.vue` | 4섹션: Text/Font, Cards, Player, Flags |
| 2.3 | BehaviourSettings (31~61) | `BehaviourSettings.vue` | 6섹션: Chipcount, Currency, Stats, CardDisplay, Layout, Misc |
| 2.4 | ColourAdjust (27~30) | `ColourAdjust.vue` | Hue/Tint + Color Replace 3규칙 |
| 2.5 | ActionBar (21~26) | `EbsActionBar.vue` | 6버튼 + Import/Export 로직 |
| 2.6 | .gfskin 로드/저장 | `useSkinStore.ts` | ZIP+JSON 직렬화 |

### Phase 3 (1 스프린트): Graphic Editor

| # | 태스크 | 파일 | 산출물 |
|:-:|--------|------|--------|
| 3.1 | GfxEditorBase (A/B/C) | `GfxEditorBase.vue` | 3패턴 레이아웃 분기 |
| 3.2 | EbsGfxCanvas | `EbsGfxCanvas.vue` | Canvas 2D WYSIWYG 프리뷰 |
| 3.3 | TransformPanel (GE-03~08) | `TransformPanel.vue` | 6+4 컨트롤 (L/T/W/H/Z/Angle + Anchor/Margins/Corner) |
| 3.4 | AnimationPanel (GE-09~14) | `AnimationPanel.vue` | 6 컨트롤 (In/Out Type/File/Speed) |
| 3.5 | TextPanel (GE-15~22) | `TextPanel.vue` | 8 컨트롤 (Visible/Font/Color/Hilite/Align/Shadow) |
| 3.6 | BackgroundPanel (GE-23) | `BackgroundPanel.vue` | Import + Preview + Mode 드롭다운 |
| 3.7 | Board/Player 모드 통합 | `GfxEditorDialog.vue` | 8 모드 Element Selector + Canvas 크기 분기 |

### Phase 4 (2 스프린트): Polish & UX

| # | 태스크 | 파일 | 산출물 |
|:-:|--------|------|--------|
| 4.1 | 교차 배경색 | `editor-shared.scss` | nth-child odd/even 패턴 |
| 4.2 | 패널 Toggle 버튼 | `SkinEditorDialog.vue` | 좌/우 패널 접기 (Figma 패턴) |
| 4.3 | T3 Advanced 토글 | `BehaviourSettings.vue` | Colour Replace/Misc/CardDisplay 분리 |
| 4.4 | Quick Preview | `ColourAdjust.vue` | 좌측 하단 미니 프리뷰 영역 |
| 4.5 | Dark Mode 전환 | `quasar.config.js` | `setCssVar()` 런타임 Brand 오버라이드 |

---

## 7장. 검증 계획

### Phase별 검증 기준

| Phase | 검증 항목 | 목표 (PRD-0007-S2 §7) |
|:-----:|----------|----------------------|
| 1 | 3열 동일 높이 렌더링 | 열 높이 편차 ≤ 50px |
| 2 | T1 분포 균형 | 각 열 T1 항목 수 편차 ≤ 1개 |
| 2 | 정보 밀도 균일 | 열 간 컨트롤 밀도 편차 ≤ 20% |
| 3 | GE A/B/C 패턴 정상 분기 | 9개 모드 각각 올바른 패턴 렌더링 |
| 4 | 여백 비율 | 각 열 25-35% |

### 테스트 전략

| 레벨 | 도구 | 범위 |
|------|------|------|
| 단위 | Vitest | Pinia Store, 유틸 함수, 컴포넌트 props |
| 컴포넌트 | Cypress Component | 공유 컴포넌트 8종 독립 렌더링 |
| E2E | Playwright | SE 전체 플로우 (Import → Edit → Export), GE 모드 전환 |

### 성능 기준

| ID | 항목 | 기준 |
|:--:|------|------|
| SE-NF01 | .gfskin 로드 | < 2s (5MB 기준) |
| SE-NF02 | Canvas 프리뷰 | 30fps 이상 |
| SE-NF03 | GPU 메모리 | < 512MB VRAM |

---

## Changelog

| 날짜 | 버전 | 변경 내용 | 변경 유형 | 결정 근거 |
|------|------|-----------|----------|----------|
| 2026-03-16 | v1.1.0 | Layout Anatomy 문서 링크 추가 — [ebs-ui-layout-anatomy.md](ebs-ui-layout-anatomy.md) L1 전술 레이어 | PRODUCT | L2↔L0 갭 해소, 화면별 상세 배치 명세 |
| 2026-03-16 | v1.0.0 | 최초 작성 — Quasar Framework 기반 EBS UI Design 구현 계획 | PRODUCT | PRD-0007-S2 전략 → 구현 변환 |
