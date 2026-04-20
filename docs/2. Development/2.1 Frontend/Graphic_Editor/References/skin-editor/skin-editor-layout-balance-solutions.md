---
doc_type: "design-proposal"
doc_id: "PRD-0007-S1"
version: "1.0.0"
status: "draft"
depends_on:
  - "PRD-0007: prd-skin-editor-layout-references.prd.md (레퍼런스 분석)"
  - "EBS-Skin-Editor.prd.md (UI 설계 v1.4.0)"
  - "mockups/ebs-skin-editor.html (현재 CSS 구조)"
owner: team1
tier: internal
reimplementability: UNKNOWN
reimplementability_checked: 2026-04-20
reimplementability_notes: "PRD-0007-S1 status=draft (14KB) — 레이아웃 밸런스 제안"
---
# Skin Editor 레이아웃 밸런스 솔루션 제안서

## 1. 근본 원인 진단

현재 목업(`ebs-skin-editor.html`)의 CSS 구조:

```css
.three-col {
  display: grid;
  grid-template-columns: 160px 1fr 1fr;   /* 좌측 고정, 중앙/우측 균등 */
  gap: 16px;
  /* align-items: stretch 없음 → 열 높이 독립 */
}
.col-left   { display: flex; flex-direction: column; gap: 16px; }
.col-center { display: flex; flex-direction: column; gap: 0; }
.col-right  { display: flex; flex-direction: column; gap: 0; }
```

**실제 렌더링 높이**:

```
  col-left (~320px)    col-center (~800px+)   col-right (~200px)
  ┌──────────┐         ┌──────────────┐       ┌──────────┐
  │ Element  │         │ Text/Font ▼  │       │ Chip ▶   │
  │ Grid     │         │ (상세 펼침)  │       │ Currency▶│
  │ [7 btns] │         │              │       │ Stats ▶  │
  ├──────────┤         │ Cards ▶      │       │ Layout ▶ │
  │ Colour   │         │              │       │ Misc ▶   │
  │ Adj.     │         │ Player ▶     │       └──────────┘
  │          │         │              │       ↑ ~200px
  ├──────────┤         │ Flags ▶      │
  │ Colour   │         │              │         ~600px
  │ Replace  │         │              │         공백
  └──────────┘         └──────────────┘
  ↑ ~320px             ↑ ~800px+
```

**근본 원인 3가지**:

| # | 원인 | CSS 레벨 | 영향 |
|---|------|---------|------|
| 1 | Grid에 `align-items: stretch` 없음 | 열 높이가 콘텐츠 기준으로 독립 렌더링 | 열 간 높이 차 최대 600px |
| 2 | 좌측 폭 160px 고정 | 업계 평균(220-280px) 대비 협소 → 콘텐츠 적재량 제한 | 좌측 세로 밀도 낮음 |
| 3 | 우측 Behaviour 전부 접힘 | 헤더만 표시 → ~200px로 축소 | 우측 빈 공간 극대화 |

## 2. 방법론: 콘텐츠 중요도 기반 배치

### 2.1 Gutenberg Diagram + F-Pattern

에디터 다이얼로그에서 사용자의 시선 흐름:

```
  ┌─────────┬──────────────┬──────────┐
  │ ★★★     │  ★★★★        │  ★★      │ ← Primary Optical Area
  │ 좌상단   │  중앙 상단    │  우상단   │    시선 시작점
  │         │              │          │
  │ ★★★     │  ★★★★★       │  ★★★     │ ← Strong Fallow Area
  │ 좌중단   │  중앙 (핵심)  │  우중단   │    핵심 작업 영역
  │         │              │          │
  │ ★       │  ★★          │  ★★★     │ ← Terminal Area
  │ 좌하단   │  중앙 하단    │  우하단   │    CTA/Action 배치
  └─────────┴──────────────┴──────────┘
```

**적용 원칙**:
- **좌상단(★★★)**: Element Grid — 현재 위치 적절
- **중앙(★★★★★)**: Visual Settings — 현재 위치 적절
- **우측(★★~★★★)**: Behaviour Settings — 위치 적절하나 **밀도 부족**
- **좌하단(★)**: Colour — 최저 주목 영역에 배치되어 공백 느낌 극대화

### 2.2 Content Priority Matrix

각 UI 요소를 **사용 빈도 × 작업 중요도**로 분류:

| UI 요소 | 빈도 | 중요도 | Priority | 현재 위치 | 권고 |
|---------|:----:|:-----:|:--------:|----------|------|
| Element Grid (7 버튼) | ★★★★★ | ★★★★ | **P1** | 좌상 ✓ | 유지 |
| Visual: Text/Font | ★★★★ | ★★★★★ | **P1** | 중앙 ✓ | 유지 |
| Visual: Cards | ★★★ | ★★★★ | **P2** | 중앙 ✓ | 유지 |
| Visual: Player/Flags | ★★★ | ★★★ | **P2** | 중앙 ✓ | 유지 |
| Colour Adjustment | ★★ | ★★★ | **P3** | 좌중 | 중앙 통합 또는 우측 이동 |
| Colour Replacement | ★★ | ★★ | **P3** | 좌하 | 중앙 통합 |
| Behaviour: Chipcount | ★★★ | ★★★ | **P2** | 우상 ✓ | 유지 + 기본 펼침 |
| Behaviour: Currency | ★★ | ★★ | **P3** | 우중 ✓ | 유지 |
| Behaviour: Statistics | ★★ | ★★ | **P3** | 우중 ✓ | 유지 |
| Behaviour: Layout | ★★★ | ★★★ | **P2** | 우중 ✓ | 유지 + 기본 펼침 |
| Behaviour: Misc | ★ | ★ | **P4** | 우하 ✓ | Advanced 숨김 |

### 2.3 Progressive Disclosure 3-Tier 모델

콘텐츠를 노출 수준에 따라 3계층으로 분류:

| Tier | 노출 수준 | 적용 대상 | 패턴 |
|------|----------|----------|------|
| **T1** (항상 표시) | 기본 펼침 | Element Grid, Text/Font, Chipcount, Layout | `default-opened` |
| **T2** (접힘, 1클릭) | 접힌 헤더 표시 | Cards, Player/Flags, Currency, Statistics | 접힌 상태 |
| **T3** (숨김, Advanced) | 토글 뒤 | Colour Replacement, Misc, Card Display | "Advanced" 토글 |

**Tier 적용 후 기본 표시 콘텐츠 균형**:
- 좌측: Element Grid(T1) + Colour Adjust(T2) — Colour Replacement는 T3
- 중앙: Text/Font(T1) + Cards(T2) + Player/Flags(T2) — Card Display는 T3
- 우측: Chipcount(T1) + Layout(T1) + Currency(T2) + Statistics(T2) — Misc는 T3

### 2.4 Vertical Data Density

Fresh Consulting 원칙: 상단 = High-level, 하단 = Low-level

```
  좌측 열              중앙 열              우측 열
  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
  │ [High-Level] │   │ [High-Level] │   │ [High-Level] │
  │ Element Grid │   │ Text/Font ▼  │   │ Chipcount ▼  │
  │ ■■ ■■ ■■ ■■ │   │  (상세 펼침)  │   │  (상세 펼침)  │
  ├──────────────┤   ├──────────────┤   ├──────────────┤
  │ [Mid-Level]  │   │ [Mid-Level]  │   │ [Mid-Level]  │
  │ Colour Adj ▶ │   │ Cards ▶      │   │ Layout ▼     │
  │ (접힌 상태)  │   │ Player ▶     │   │ Currency ▶   │
  │              │   │              │   │ Statistics ▶ │
  ├──────────────┤   ├──────────────┤   ├──────────────┤
  │ [Low-Level]  │   │ [Low-Level]  │   │ [Low-Level]  │
  │ ⚙ Advanced   │   │ ⚙ Advanced   │   │ ⚙ Advanced   │
  │  (토글 뒤)   │   │  (토글 뒤)   │   │  (토글 뒤)   │
  └──────────────┘   └──────────────┘   └──────────────┘
```

### 2.5 밸런스 검증 체크리스트

배치 재설계 후 정량 검증 기준:

| 기준 | 측정 방법 | 목표 |
|------|----------|------|
| **열 높이 편차** | max - min(열 높이) | ≤ 50px |
| **T1 콘텐츠 분포** | 각 열의 T1 항목 수 | 편차 ≤ 1개 |
| **정보 밀도** | (컨트롤 수 / 열 면적) 비율 | 열 간 편차 ≤ 20% |
| **여백 비율** | (여백 / 전체) 백분율 | 각 열 25-35% |
| **스크롤 필요성** | 열별 스크롤 필요 여부 | 0~1개 열만 |

## 3. 솔루션 6개

### S1. Flexbox Stretch + Colour flex-grow (P1, Low)

**문제**: 3개 열 높이 불균형 (최대 600px 차이)
**해법**: Grid → Flexbox 전환 + `align-items: stretch`로 전체 열 동일 높이 강제

```css
/* Before */
.three-col {
  display: grid;
  grid-template-columns: 160px 1fr 1fr;
}

/* After */
.three-col {
  display: flex;
  align-items: stretch;     /* 모든 열 동일 높이 */
  gap: 16px;
  min-height: 0;            /* 중첩 flex overflow 방지 */
}
.col-left {
  width: 240px;             /* 160→240px 확대 (업계 평균) */
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
  gap: 16px;
  min-height: 0;
}
.col-left .colour-section {
  flex-grow: 1;             /* 남는 높이를 Colour가 흡수 */
  overflow-y: auto;
}
.col-center, .col-right {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-height: 0;
  overflow-y: auto;
}
```

**Quasar 대응**: `class="row items-stretch"` + `class="col-auto"` / `class="col"`

### S2. QSplitter 중첩 — 사용자 조절 가능 패널 (P2, Medium)

**문제**: 패널 비율이 콘텐츠 양에 따라 가변적
**해법**: Quasar QSplitter로 좌|중앙+우 → 중앙|우 2단 분할

```vue
<q-splitter v-model="leftRatio" :limits="[15, 35]"
            style="height: calc(100vh - 120px)">
  <template v-slot:before>
    <!-- 좌측: Element Grid + Colour -->
  </template>
  <template v-slot:after>
    <q-splitter v-model="rightRatio" :limits="[40, 70]">
      <template v-slot:before>
        <!-- 중앙: Visual Settings -->
      </template>
      <template v-slot:after>
        <!-- 우측: Behaviour Settings -->
      </template>
    </q-splitter>
  </template>
</q-splitter>
```

**핵심**: QSplitter 부모에 명시적 높이(`calc(100vh - header - actionbar)`) 필수. 없으면 splitter가 콘텐츠 높이로 축소됨.

### S3. QExpansionItem 아코디언 — 밀도 자율 조절 (P2, Medium)

**문제**: 우측 열 밀도 부족 (접힌 헤더만 ~200px)
**해법**: 주요 섹션 기본 펼침 + 아코디언 모드 + 교차 배경색

```vue
<q-expansion-item
  v-for="section in behaviourSections"
  :key="section.id"
  :default-opened="section.tier === 1"
  group="behaviour"
  :label="section.label"
  header-class="text-weight-bold bg-grey-2"
>
  <!-- 섹션 내용 -->
</q-expansion-item>
```

**교차 배경색** (Unity Inspector 패턴):

```css
.expansion-content > .row:nth-child(odd)  { background: #fafafa; }
.expansion-content > .row:nth-child(even) { background: #ffffff; }
```

**기본 펼침 대상**: Chipcount Display(T1), Layout(T1) → 우측 열 기본 높이 ~400px+로 증가

### S4. Grid 내부 auto/1fr 분할 (P2, Low)

**문제**: 열 내부에서 헤더와 본문의 높이 분배 불균형
**해법**: 각 열 내부를 `grid-template-rows: auto 1fr`로 분할

```css
.col-left, .col-center, .col-right {
  display: grid;
  grid-template-rows: auto 1fr;  /* 헤더 auto + 본문 나머지 */
}
.col-body {
  overflow-y: auto;
  min-height: 0;                  /* Grid 내부 overflow 허용 */
}
```

S1의 Flexbox stretch와 결합하면, 각 열이 동일 높이를 유지하면서 내부적으로 헤더/본문 비율이 자동 조정된다.

### S5. 좌측 하단 프리뷰 영역 (P3, Medium)

**문제**: 좌측 열 하단 공백
**해법**: 빈 공간에 선택 요소의 미니 프리뷰 또는 Quick Actions 배치

```
  +------------------+
  | Element Grid     |  ← 고정
  |   [Board][Blinds]|
  |   [Outs][Strip]  |
  +------------------+
  | Colour Adjust.   |  ← 접이식
  +------------------+
  | ◆ Quick Preview  |  ← 신규: flex-grow: 1
  |   [선택 요소     |
  |    미리보기]     |
  +------------------+
```

vMix GT의 Properties 밀도 패턴 차용. 콘텐츠로 공백을 채움.

**Quasar 구현**: `<q-card flat class="full-height">` + 선택 element의 축소 렌더링

### S6. Sticky Bottom Colour (P4, Low)

**문제**: Colour 패널이 위에 붙어 아래 공백 발생
**해법**: `position: sticky; bottom: 0`으로 Colour를 열 하단에 고정

```css
.colour-section {
  position: sticky;
  bottom: 0;
  margin-top: auto;  /* 상단 공간 밀어내기 */
}
```

**단점**: 스크롤 시 동작이 직관적이지 않음. S1과 병행하면 불필요.
**권고**: S1 적용 후에도 공백이 남는 경우에만 대안으로 고려.

## 4. 종합 적용 전략

### Phase 1 (즉시): S1 + S3

| # | 적용 항목 | 솔루션 |
|---|----------|--------|
| 1 | `.three-col` → flexbox + `align-items: stretch` | S1 |
| 2 | 좌측 폭 160→240px | S1 |
| 3 | 좌측 Colour에 `flex-grow: 1` | S1 |
| 4 | 우측 Chipcount, Layout 기본 펼침 | S3 |
| 5 | 교차 배경색 적용 | S3 |

**예상 효과**: 3열 동일 높이 + 좌측 Colour 공간 흡수 + 우측 밀도 균일화

### Phase 2 (다음 스프린트): S2 + S4

| # | 적용 항목 | 솔루션 |
|---|----------|--------|
| 1 | QSplitter로 사용자 패널 비율 조절 | S2 |
| 2 | 열 내부 auto/1fr 분할 | S4 |
| 3 | 여백 기반 시각 계층 전환 (Figma 패턴) | — |

**예상 효과**: 사용자 맞춤 레이아웃 + 시각적 세련도 업계 수준 달성

### Phase 3 (향후): S5

| # | 적용 항목 | 솔루션 |
|---|----------|--------|
| 1 | 좌측 하단 Quick Preview 영역 | S5 |

**예상 효과**: 빈 공간의 기능적 활용 + 작업 효율성 향상

### Impact × Effort 매트릭스

```
  High ┌─────────────────────────────────┐
       │           │ S2        S5       │
  I    │           │ QSplitter Preview  │
  m    │-----------│--------------------│
  p    │ S1★       │ S3                 │
  a    │ Flexbox   │ Accordion          │
  c    │           │                    │
  t    │ S4        │                    │
       │ auto/1fr  │           S6       │
  Low  └─────────────────────────────────┘
       Low Effort            High Effort

  ★ = 최우선 적용
```

## Changelog

| 날짜 | 버전 | 변경 내용 | 변경 유형 | 결정 근거 |
|------|------|-----------|----------|----------|
| 2026-03-16 | v1.0.0 | 최초 작성 — 6개 솔루션 + Phase별 적용 전략 | PRODUCT | PRD-0007 레퍼런스 분석 기반 레이아웃 품질 개선 |
