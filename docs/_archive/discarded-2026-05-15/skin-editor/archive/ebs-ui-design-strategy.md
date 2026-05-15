---
doc_type: "design-strategy"
doc_id: "PRD-0007-S2"
version: "1.2.0"
status: "SUPERSEDED"
superseded-by: "B-209 (회의 D3 GE 제거) + SG-014 SUPERSEDED + SG-021 (.gfskin → .riv 전환 DONE)"
superseded-date: 2026-04-27
depends_on:
  - "PRD-0007: prd-skin-editor-layout-references.prd.md (18개 에디터 벤치마크)"
  - "PRD-0007-S1: skin-editor-layout-balance-solutions.md (6개 솔루션)"
  - "EBS-Skin-Editor.prd.md (UI 설계 v1.4.0)"
owner: team1
tier: internal
last-updated: 2026-05-03
reimplementability: N/A
reimplementability_checked: 2026-05-03
reimplementability_notes: "SUPERSEDED 2026-04-27 — Graphic Editor 영역 회의 D3 결정으로 폐기. 신 SSOT: SG-021 + Foundation §5.3 Rive Manager"
discarded: "2026-05-15: absorbed into Lobby Settings"
---
# EBS UI Design 전략 제안서

## 1장. 전략 프레임워크

### 설계 비전

> **"화면 어디를 봐도 다음 행동이 명확한 에디터"**

### 5대 설계 원칙

| # | 원칙 | 설명 |
|:-:|------|------|
| 1 | **WYSIWYG-First** | Canvas 프리뷰가 편집의 중심. 모든 변경은 즉시 시각적 피드백 |
| 2 | **Progressive Disclosure** | T1(항상)/T2(1클릭)/T3(Advanced) 3단계로 정보 노출 제어 |
| 3 | **Spatial Consistency** | SE↔GE 간 동일 속성은 동일 위치. 학습 비용 최소화 |
| 4 | **Density Balance** | 열 간 정보 밀도 편차 ≤20%. 빈 공간 zero tolerance |
| 5 | **PokerGFX Parity** | 187필드 완전 매핑. 기능 누락 zero |

### 목표 계층

```
L3 (비전)  ─ "다음 행동이 명확한 에디터"
L2 (전략)  ─ 본 문서 (레이아웃/시각/IA/일관성 전략)
L1 (전술)  ─ CSS/컴포넌트 구현 (quasar.variables.scss, EbsSectionHeader 등)
```

---

## 2장. 레이아웃 아키텍처

### 현재 SE 문제 요약

- grid 160px 고정 → 좁은 좌측 열에 콘텐츠 부족
- `align-items: stretch` 없음 → 열 높이 불일치
- 좌측 320px vs 중앙 800px+ → **최대 600px 높이 차** (ref: PRD-0007-S1)

### 개선안 CSS (S1 솔루션)

```css
.three-col {
  display: flex;
  align-items: stretch;
  gap: 16px;
}
.col-left {
  width: 240px;          /* 160→240px */
  flex-shrink: 0;
}
.col-left .colour-section {
  flex-grow: 1;          /* 남는 높이 흡수 */
  overflow-y: auto;
}
.col-center { flex: 1.2; }
.col-right  { flex: 1; }
```

### 좌측 열 재구성

| 영역 | 높이 전략 | 비고 |
|------|----------|------|
| Element Grid | 고정 | 16요소 4×4 그리드 |
| Colour Adjustment | `flex-grow: 1` | 남는 높이 흡수 |
| Colour Replace | T3 Advanced | 접힘 기본 |

### GE 적응형 레이아웃

| 패턴 | 조건 | Canvas 위치 |
|------|------|-------------|
| A (3-col) | ≤300px canvas | 좌측 열 고정 |
| B (Canvas top + 2×2) | 극단 가로비 | 상단 전폭 |
| C (Canvas top + 3열) | 465px+ | 상단 전폭 |

단일 `GfxEditorBase` 컴포넌트에서 `mode` prop으로 분기.

### Before / After

```
BEFORE:                          AFTER:
┌──────┬───────────┬────────┐   ┌────────┬───────────┬────────┐
│160px │  flex 1fr │ flex   │   │ 240px  │ flex 1.2  │ flex 1 │
│      │           │ 1fr   │   │        │           │        │
│ Grid │ Visual    │Behav.  │   │ Grid   │ Visual    │Behav.  │
│      │ Settings  │Settings│   │        │ Settings  │Settings│
│ Hue  │           │ (접힘) │   │ Hue    │           │ (T1    │
│ Tint │           │        │   │ Tint   │           │  펼침) │
│      │           │        │   │ ┈┈┈┈┈┈ │           │        │
│ ~~~~ │           │        │   │Colour  │           │        │
│공백  │           │        │   │flex-   │           │        │
│      │           │        │   │grow:1  │           │        │
├──────┴───────────┴────────┤   ├────────┴───────────┴────────┤
│        Action Bar         │   │        Action Bar            │
└───────────────────────────┘   └─────────────────────────────┘
```

---

## 3장. 시각 디자인 시스템

### Brand Colors — `quasar.variables.scss`

VS Code Dark+ 계열, PokerGFX 톤 보정. Quasar Brand 8색 + EBS 커스텀 확장.

| Quasar Brand | SCSS 변수 | 값 | 용도 |
|---|---|---|---|
| primary | `$primary` | `#0e639c` | 포커스/선택 강조, CTA 버튼 |
| secondary | `$secondary` | `#26a69a` | 보조 액션 |
| accent | `$accent` | `#9c27b0` | 강조 |
| dark | `$dark` | `#1e1e1e` | 앱 배경 (Dark Mode 기본) |
| positive | `$positive` | `#21ba45` | 성공 상태 |
| negative | `$negative` | `#c10015` | 에러 상태 |
| info | `$info` | `#31ccec` | 정보 |
| warning | `$warning` | `#f2c03e` | 경고 |

```scss
// src/css/quasar.variables.scss
$primary   : #0e639c;
$secondary : #26a69a;
$accent    : #9c27b0;
$dark      : #1e1e1e;
$positive  : #21ba45;
$negative  : #c10015;
$info      : #31ccec;
$warning   : #f2c03e;

// EBS 커스텀 확장
$ebs-surface   : #2d2d30;
$ebs-panel     : #252526;
$ebs-hover     : #2a2d2e;
$ebs-border    : #3c3c3c;
$ebs-text-muted: #969696;
```

### Spacing — Quasar CSS 유틸리티 클래스

8px 그리드. 패턴: `q-[p|m][t|r|b|l|a|x|y]-[none|xs|sm|md|lg|xl]`

| Quasar 클래스 | 값 | 용도 | 예시 |
|---|---|---|---|
| `q-*-none` | 0 | 제로 간격 | `q-pa-none` |
| `q-*-xs` | 4px | 컨트롤 내부 | `q-pa-xs` |
| `q-*-sm` | 8px | 컨트롤 간격 | `q-mt-sm` |
| `q-*-md` | 16px | 섹션 간격 | `q-pa-md` |
| `q-*-lg` | 24px | 그룹 간격 | `q-mt-lg` |
| `q-*-xl` | 32px | 영역 간격 | `q-pa-xl` |

### Typography — Quasar text 클래스

| 역할 | Quasar 클래스 | 스타일 | 용도 |
|---|---|---|---|
| 섹션 헤더 | `text-subtitle1 text-weight-bold` | 16px/600 | QExpansionItem 헤더 |
| 서브 헤더 | `text-subtitle2` | 14px/500 | 패널 내 그룹 라벨 |
| 본문 라벨 | `text-body2` | 14px/400 | 속성 라벨 |
| 보조 텍스트 | `text-caption` | 12px/400 | 힌트, 범위 표시 |
| 코드/수치 | `text-body2 font-mono` | 14px mono | 좌표값, 색상코드 |

### 경계선 → 여백 전환

Figma UI3 패턴 적용. `border: 1px solid` 제거 → `class="q-mt-lg"` 섹션 간 여백 + `<q-separator />` 최소 경계선.

### 컴포넌트 시각 계층

| 단계 | Quasar 클래스 | 예시 |
|------|---------------|------|
| 섹션 헤더 | `text-subtitle1 text-weight-bold bg-dark-2` | "Text & Font" |
| 라벨 | `text-body2` | "Font Size" |
| 보조 텍스트 | `text-caption text-grey-6` | "px, 8~72" |

### 교차 배경색 (Unity Inspector 패턴)

```scss
.property-row:nth-child(odd)  { background: $ebs-surface; }
.property-row:nth-child(even) { background: $ebs-panel; }
```

---

## 4장. 정보 아키텍처

### Progressive Disclosure 매핑

| Tier | SE 항목 | GE 항목 |
|------|---------|---------|
| T1 (항상) | Element Grid, Text/Font, Chipcount, Layout | Transform, Element Selector, Canvas |
| T2 (1클릭) | Cards, Player/Flags, Currency, Statistics, Colour Adjust | Animation, Text, Background |
| T3 (Advanced) | Colour Replace, Misc, Card Display | Anchor, Margins, Corner Radius |

### Gutenberg Diagram 콘텐츠 배치

```
┌─────────┬──────────────┬──────────┐
│ ★★★     │  ★★★★        │  ★★      │ ← 시선 시작
│ Element │  Text/Font   │ Chipcount│
│ Grid    │  (T1 펼침)   │ (T1 펼침)│
├─────────┼──────────────┼──────────┤
│ ★★★     │  ★★★★★       │  ★★★     │ ← 핵심 영역
│ Colour  │  Cards/Player│ Layout/  │
│ Adjust  │  (T2 접힘)   │ Currency │
├─────────┼──────────────┼──────────┤
│ ★       │  ★★          │  ★★★     │ ← Terminal
│Advanced │  Advanced    │ Advanced │
│(T3 숨김)│  (T3 숨김)   │ (T3 숨김)│
└─────────┴──────────────┴──────────┘
```

★ 수는 Gutenberg 모델 시선 빈도 — 좌상(Primary) → 우하(Terminal) 순으로 감소.

### SE → GE 네비게이션 흐름

```
06 Element Grid 버튼
  └─→ GE QDialog(mode 파라미터)
        └─→ GE-02 Element Selector
              └─→ 서브요소 선택
                    └─→ Transform / Animation / Text / Background 패널 편집
```

SE에서 GE 진입 시 `mode` 파라미터가 Canvas 레이아웃(A/B/C)과 Element Selector 내용을 결정한다. 편집 대상 속성 패널(Transform, Animation, Text, Background)은 모든 mode에서 동일 컴포넌트를 재사용한다.

---

## 5장. Phase별 실행 로드맵

### Phase 1 (1-2일): 기본 균형

**적용**: S1 + S3 + 토큰 추출

| 작업 | 상세 |
|------|------|
| flexbox stretch | `align-items: stretch` + 240px 좌측 |
| T1 기본 펼침 | Chipcount, Layout 섹션 기본 expanded |
| editor-tokens.css | 8 color + 5 spacing + 4 typography 토큰 |
| 교차 배경색 | `property-row:nth-child` odd/even 적용 |

**목표**: 3열 동일 높이 + 기본 밀도 균형

### Phase 2 (1 스프린트): 맞춤 레이아웃

**적용**: S2 + S4 + 여백 전환 + GE CSS 통합

| 작업 | 상세 |
|------|------|
| QSplitter 중첩 | 좌\|중앙+우 → 중앙\|우 |
| auto/1fr 분할 | 열 내부 고정/유동 영역 분리 |
| border → margin | 경계선 제거, 배경색 차이로 구분 |
| GfxEditorBase | A/B/C 패턴 단일 컴포넌트 mode 분기 |

**목표**: 사용자 맞춤 레이아웃 + 업계 수준 시각 세련도

### Phase 3 (2 스프린트): UX 완성

**적용**: S5 + 패널 토글 + Advanced 분리

| 작업 | 상세 |
|------|------|
| Quick Preview | 좌측 하단 미니 프리뷰 영역 |
| 패널 Toggle | 좌/우 패널 접기 버튼 (Figma 패턴) |
| T3 Advanced 토글 | 별도 토글 분리 (Unreal Details 패턴) |

**목표**: UX 완성 + 전문가 워크플로우 최적화

---

## 6장. SE ↔ GE 일관성 전략

### 현재 비일관성 진단

| 항목 | SE | GE | 문제 |
|------|----|----|------|
| 섹션 헤더 | `QExpansionItem` 아코디언 | 패턴별 상이 (A: sidebar, B: 2×2, C: 3열) | 접이식 패턴 불일치 |
| 배경색 | 없음 | 패턴별 상이 | 시각 톤 불일치 |
| 간격 체계 | gap: 16px | 패턴별 상이 (12px~20px) | 수직 리듬 불일치 |
| 폰트 크기 | 미정의 | 패턴별 상이 | 텍스트 계층 불일치 |
| Action 버튼 | 하단 6버튼 | 없음 (자동 저장) | 저장 패턴 불일치 |

### 공유 컴포넌트 8종

| # | 컴포넌트 | 역할 |
|:-:|----------|------|
| 1 | `EbsSectionHeader` | 접이식 섹션 헤더 (QExpansionItem 래퍼) |
| 2 | `EbsPropertyRow` | 라벨+컨트롤 행 (교차 배경색) |
| 3 | `EbsColorPicker` | QColor + QPopupProxy 래퍼 |
| 4 | `EbsNumberInput` | QInput[type=number] + min/max/step |
| 5 | `EbsSlider` | QSlider + label-always 래퍼 |
| 6 | `EbsToggle` | QToggle + 라벨 정렬 |
| 7 | `EbsSelect` | QSelect + emit-value + map-options |
| 8 | `EbsActionBar` | 하단 버튼 행 (SE: 6버튼, GE: Apply/Reset) |

### 공유 CSS: `quasar.variables.scss` + `editor-shared.scss`

```scss
// src/css/quasar.variables.scss (Quasar 자동 로드)
$primary   : #0e639c;
$secondary : #26a69a;
$accent    : #9c27b0;
$dark      : #1e1e1e;
$positive  : #21ba45;
$negative  : #c10015;
$info      : #31ccec;
$warning   : #f2c03e;

// EBS 커스텀 확장
$ebs-surface   : #2d2d30;
$ebs-panel     : #252526;
$ebs-hover     : #2a2d2e;
$ebs-border    : #3c3c3c;
$ebs-text-muted: #969696;
```

```scss
// src/css/editor-shared.scss (SE + GE 공유)
@import './Quasar.variables';

// 교차 배경색 (Unity Inspector 패턴)
.property-row:nth-child(odd)  { background: $ebs-surface; }
.property-row:nth-child(even) { background: $ebs-panel; }

// 커스텀 폰트
.font-mono { font-family: 'Consolas', 'Courier New', monospace; }
```

### GE 모드 전환 시 패널 일관성

`GfxEditorBase`에서 `mode` prop → `computed`로 패널 가시성 결정:

- Transform / Animation / Text / Background — 4패널은 **모든 모드에서 동일 컴포넌트** 사용
- Element Selector — 내용만 mode별 변경 (Board: 카드/딜러 버튼, Player: 이름/칩카운트/카드, 등)

---

## 7장. 검증 전략

### 정량 지표 5종

| 지표 | 측정 방법 | 목표 |
|------|----------|------|
| 열 높이 편차 | `max(col height) - min(col height)` | ≤ 50px |
| T1 분포 | 각 열의 T1 항목 수 | 편차 ≤ 1개 |
| 정보 밀도 | 컨트롤 수 / 열 면적 | 열 간 편차 ≤ 20% |
| 여백 비율 | 여백 / 전체 면적 | 각 열 25-35% |
| 경계선 수 | `border` 속성 카운트 | Phase 2 후 ≤ 5개 |

### 사용성 체크리스트

| # | 항목 |
|:-:|------|
| 1 | 첫 방문 사용자가 3초 내 편집 시작점을 찾을 수 있는가? |
| 2 | Element Grid → GE → 속성 편집 → 결과 확인이 3클릭 이내인가? |
| 3 | T1 섹션만으로 기본 스킨 편집이 완료 가능한가? |
| 4 | SE와 GE에서 동일 속성(예: 색상)이 동일 위치에 있는가? |
| 5 | 모든 열의 높이가 시각적으로 균등한가? |
| 6 | 접힌 섹션 헤더만으로 내용을 예측할 수 있는가? |
| 7 | Advanced 토글 없이도 핵심 기능이 모두 접근 가능한가? |
| 8 | 8px 그리드에서 벗어난 간격이 없는가? |
| 9 | 교차 배경색으로 밀집 행이 시각적으로 구분되는가? |
| 10 | Canvas 프리뷰가 속성 변경에 즉시 반응하는가? |

### 목업 검증 사이클

```
HTML 수정 → Chrome headless 캡처 → Read 도구 시각 검증 → 지표 측정 → 수정 반복
```

---

## Changelog

| 날짜 | 버전 | 변경 내용 | 변경 유형 | 결정 근거 |
|------|------|-----------|----------|----------|
| 2026-03-16 | v1.2.0 | Layout Anatomy 문서 링크 추가 — [ebs-ui-layout-anatomy.md](ebs-ui-layout-anatomy.md) L1 전술 레이어 | PRODUCT | L2↔L0 갭 해소, 화면별 상세 배치 명세 |
| 2026-03-16 | v1.1.0 | 3장/6장 Quasar Framework 테마 시스템 전환 — Brand Colors, SCSS 변수, CSS 유틸리티 클래스 매핑 | TECH | Quasar 표준 준수로 raw CSS 변수 제거 |
| 2026-03-16 | v1.0.0 | 최초 작성 — 7장 전략 프레임워크 + 레이아웃/시각/IA/로드맵/일관성/검증 | PRODUCT | PRD-0007 벤치마크 + PRD-0007-S1 솔루션 종합 |
