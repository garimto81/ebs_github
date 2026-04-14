# EBS UI Layout Anatomy — 화면별 상세 레이아웃 명세서

> **버전**: v1.0.0 | **날짜**: 2026-03-16
> **위치**: L2(전략) ↔ L0(목업/코드) 사이의 L1 전술 레이어
> **참조**: [ebs-ui-design-strategy.md](ebs-ui-design-strategy.md) · [EBS-Skin-Editor.prd.md](EBS-Skin-Editor.prd.md) · [ebs-ui-design-plan.md](ebs-ui-design-plan.md)

---

## 1. 분석 방법론 — 5-Step Layout Derivation

각 화면의 레이아웃을 도출하는 표준 프로세스:

```
Step 1          Step 2          Step 3          Step 4          Step 5
Element 수집 → Tier 분류    → 그룹핑       → 배치          → 검증
PRD §2/§3에서   T1/T2/T3      패널(Section)   전략 패턴 적용   5대 지표
ID 전체 추출    매핑           으로 묶기       + Gutenberg     충족 확인
```

| Step | 입력 | 출력 | 참조 |
|:----:|------|------|------|
| **1. Element 수집** | PRD §2 (SE: 01~61) / §3 (GE: GE-01~GE-23) | Element ID 전체 목록 | EBS-Skin-Editor.prd.md |
| **2. Tier 분류** | Element 목록 + 사용 빈도/중요도 | T1(항상)/T2(1클릭)/T3(Advanced) 라벨 | ebs-ui-design-strategy.md §4 |
| **3. 그룹핑** | Tier-tagged Element 목록 | EbsSectionHeader 단위 패널 | 기능적 응집도 기준 |
| **4. 배치** | 패널 그룹 + 레이아웃 패턴 | 열/행 위치, flex 비율, 치수 | ebs-ui-design-strategy.md §2 |
| **5. 검증** | 완성된 배치 | PASS/FAIL + 조정 | ebs-ui-design-strategy.md §7 |

### Gutenberg Diagram 배치 규칙 (Step 4 적용)

```
┌─────────────┬─────────────────┬─────────────┐
│ PRIMARY (★★★)│   STRONG (★★★★) │  WEAK (★★)  │ ← 시선 진입
│ Element Grid│  Text/Font      │ Chipcount   │
├─────────────┼─────────────────┼─────────────┤
│ STRONG (★★★)│   CORE (★★★★★)  │ STRONG (★★★)│ ← 핵심 영역
│ Colour Adj. │  Cards/Player   │ Layout/Curr.│
├─────────────┼─────────────────┼─────────────┤
│ FALLOW (★)  │   FALLOW (★★)   │ TERMINAL(★★★)│ ← 시선 종료
│ Advanced    │  Advanced       │ Advanced    │
└─────────────┴─────────────────┴─────────────┘
```

**규칙**: 각 열 내 T1 → 상단(시선 진입) / T2 → 중간(핵심) / T3 → 하단(Terminal)

---

## 2. Skin Editor 메인 — Layout Anatomy

### 2.1 전체 구조 트리

```
SkinEditorDialog (QDialog, 모달)
│
├─ SkinMetadata ─────────────────────────────────── 상단 전폭, 고정 ~80px
│   └─ 01 Name | 02 Details | 03 RemoveTransparency
│      04 4K | 05 AdjustSize
│
├─ QSplitter (수평, leftRatio=25%) ──────────────── 메인 영역, flex-grow:1
│   │
│   ├─ before: 좌측 열 ─────────────────────────── 240px, flex-shrink:0
│   │   │
│   │   ├─ ElementGrid (고정 높이 ~120px) [T1]
│   │   │   └─ 06: QBtn×8 (4×2 grid)
│   │   │       Board | Blinds | Outs | Strip
│   │   │       History | Clock | Leaderboard | Field
│   │   │
│   │   ├─ ColourAdjust (flex-grow:1) [T2]
│   │   │   └─ EbsSectionHeader "Colour Adjustment"
│   │   │       ├─ 27 MasterOpacity (EbsSlider)
│   │   │       ├─ 28 Hue (EbsSlider)
│   │   │       └─ 29 TintR/G/B (EbsSlider×3)
│   │   │
│   │   └─ ColourReplace (접힘 기본) [T3]
│   │       └─ EbsSectionHeader "Colour Replace" [Advanced]
│   │           ├─ 30 Rule1 (EbsColorPicker×2 + EbsSlider)
│   │           ├─ 30 Rule2 (EbsColorPicker×2 + EbsSlider)
│   │           └─ 30 Rule3 (EbsColorPicker×2 + EbsSlider)
│   │
│   └─ after: QSplitter (수평, 중앙:우측) ──────── flex:1
│       │
│       ├─ before: 중앙 열 ─────────────────────── flex:1.2, overflow-y:auto
│       │   │
│       │   ├─ EbsSectionHeader "Text & Font" [T1 기본펼침]
│       │   │   ├─ 07 AllCaps (EbsToggle)
│       │   │   ├─ 08 RevealSpeed (EbsSlider)
│       │   │   ├─ 09 Font1/Font2 (EbsSelect×2)
│       │   │   └─ 10 Language (EbsSelect)
│       │   │
│       │   ├─ EbsSectionHeader "Cards" [T2]
│       │   │   ├─ 11 CardPreview
│       │   │   ├─ 12 CardManagement (EbsSelect)
│       │   │   └─ 13 ImportBack (QBtn)
│       │   │
│       │   ├─ EbsSectionHeader "Player" [T2]
│       │   │   ├─ 14 Variant (EbsSelect)
│       │   │   ├─ 15 PlayerSet (EbsSelect)
│       │   │   ├─ 16 SetManagement (QBtn)
│       │   │   └─ 17 CropCircle (EbsToggle)
│       │   │
│       │   └─ EbsSectionHeader "Flags" [T2]
│       │       ├─ 18 FlagMode (EbsSelect)
│       │       ├─ 19 EditFlags (QBtn)
│       │       └─ 20 HideAfter (EbsNumberInput)
│       │
│       └─ after: 우측 열 ──────────────────────── flex:1, overflow-y:auto
│           │
│           ├─ EbsSectionHeader "Chipcount Display" [T1 기본펼침]
│           │   ├─ 31 Precision×8 (EbsNumberInput×8)
│           │   ├─ 32 DisplayType (EbsSelect)
│           │   └─ 33 TextSize (EbsSlider)
│           │
│           ├─ EbsSectionHeader "Layout" [T1 기본펼침]
│           │   ├─ 50 BoardPosition (EbsSelect)
│           │   ├─ 51 Vertical (EbsToggle)
│           │   ├─ 52 BottomUp (EbsToggle)
│           │   ├─ 53 FitToScreen (EbsToggle)
│           │   ├─ 54 HeadsUpMode (EbsSelect)
│           │   ├─ 55 MarginsH (EbsSlider)
│           │   └─ 56 MarginsV (EbsSlider)
│           │
│           ├─ EbsSectionHeader "Currency" [T2]
│           │   ├─ 34 CurrencySymbol (EbsSelect)
│           │   ├─ 35 Position (EbsSelect)
│           │   ├─ 36 Decimals (EbsNumberInput)
│           │   └─ 37 Separator (EbsSelect)
│           │
│           ├─ EbsSectionHeader "Statistics" [T2]
│           │   ├─ 38 ShowStats (EbsToggle)
│           │   ├─ 39 StatMode (EbsSelect)
│           │   ├─ 40 FontSize (EbsSlider)
│           │   ├─ 41 Columns (EbsNumberInput)
│           │   ├─ 42 Rows (EbsNumberInput)
│           │   └─ 43 AutoHide (EbsToggle)
│           │
│           ├─ EbsSectionHeader "Card Display" [T3 Advanced]
│           │   ├─ 44 CardSize (EbsSlider)
│           │   ├─ 45 CardSpacing (EbsSlider)
│           │   ├─ 46 CardShadow (EbsToggle)
│           │   ├─ 47 CardBorder (EbsToggle)
│           │   ├─ 48 AnimationType (EbsSelect)
│           │   └─ 49 AnimationSpeed (EbsSlider)
│           │
│           └─ EbsSectionHeader "Misc" [T3 Advanced]
│               ├─ 57 ShowLogo (EbsToggle)
│               ├─ 58 LogoPosition (EbsSelect)
│               ├─ 59 WatermarkOpacity (EbsSlider)
│               ├─ 60 DebugMode (EbsToggle)
│               └─ 61 CustomCSS (QInput textarea)
│
└─ EbsActionBar ─────────────────────────────────── 하단 전폭, 고정 ~48px
    ├─ 21 Import (QBtn outlined)
    ├─ 22 Export (QBtn outlined)
    ├─ 23 Download (QBtn outlined)
    ├─ [spacer]
    ├─ 24 Reset (QBtn flat)
    ├─ 25 Discard (QBtn flat negative)
    └─ 26 Use (QBtn unelevated primary)
```

### 2.2 열 치수 테이블

| 영역 | CSS | 값 | Quasar 클래스 | 비고 |
|------|-----|----|--------------|------|
| 좌측 열 | `width` | 240px | — | `flex-shrink: 0`, 고정 |
| 중앙 열 | `flex` | 1.2 | — | 좌/우 대비 20% 넓음 |
| 우측 열 | `flex` | 1 | — | 기준 열 |
| 열 간격 | `gap` | 16px | `q-gutter-md` | 8px 그리드 단위 |
| 컨트롤 내부 | `padding` | 4px | `q-pa-xs` | 최소 내부 여백 |
| QSplitter 좌측 | `limits` | [15%, 35%] | `:limits="[15,35]"` | 사용자 조절 범위 |
| QSplitter 중/우 | `limits` | [40%, 70%] | `:limits="[40,70]"` | 사용자 조절 범위 |

### 2.3 SE Tier 분포 요약

| 열 | T1 (기본펼침) | T2 (1클릭) | T3 (Advanced) | 총 패널 |
|----|:------------:|:----------:|:-------------:|:-------:|
| 좌측 | 1 (ElementGrid) | 1 (ColourAdj) | 1 (ColourReplace) | 3 |
| 중앙 | 1 (Text/Font) | 3 (Cards, Player, Flags) | 0 | 4 |
| 우측 | 2 (Chipcount, Layout) | 2 (Currency, Statistics) | 2 (CardDisplay, Misc) | 6 |

> **검증**: T1 분포 = 좌1/중1/우2 → 편차 1개 → ≤1 목표 **PASS**

### 2.4 Quasar 컴포넌트 매핑

| UI 영역 | Quasar 컴포넌트 | Props |
|---------|----------------|-------|
| Dialog Frame | `QDialog` | `persistent`, `maximized` |
| 수평 분할 | `QSplitter` | `horizontal`, `:limits`, `v-model` |
| 섹션 헤더 | `QExpansionItem` → `EbsSectionHeader` | `default-opened` (T1), `label` |
| 속성 행 | — → `EbsPropertyRow` | `label`, 교차 배경색 |
| Element 그리드 | `QBtn` × 8 in CSS Grid | `dense`, `outline` |
| Action Bar | `QBtn` × 6 | `flat`/`outlined`/`unelevated` |

### 2.5 접이식 상태 매핑

| EbsSectionHeader | Tier | 기본 상태 | 접힌 높이 | 펼친 높이(추정) |
|-----------------|:----:|:--------:|:---------:|:--------------:|
| Element Grid | T1 | **고정 (접이식 아님)** | — | ~120px |
| Colour Adjustment | T2 | 접힘 | 32px | ~180px |
| Colour Replace | T3 | 접힘 | 32px | ~220px |
| Text & Font | T1 | **펼침** | — | ~160px |
| Cards | T2 | 접힘 | 32px | ~120px |
| Player | T2 | 접힘 | 32px | ~140px |
| Flags | T2 | 접힘 | 32px | ~100px |
| Chipcount Display | T1 | **펼침** | — | ~280px |
| Layout | T1 | **펼침** | — | ~240px |
| Currency | T2 | 접힘 | 32px | ~140px |
| Statistics | T2 | 접힘 | 32px | ~200px |
| Card Display | T3 | 접힘 | 32px | ~200px |
| Misc | T3 | 접힘 | 32px | ~180px |

---

## 3. Graphic Editor — 모드별 Layout Anatomy

### 3.1 패턴 총괄 — A/B/C 적응형 레이아웃

모든 GE 모드는 단일 `GfxEditorBase` 컴포넌트가 `mode` prop에 따라 3가지 패턴 중 하나로 렌더링된다.

| 패턴 | 조건 | Canvas 위치 | 패널 배치 | 적용 모드 |
|:----:|------|:----------:|----------|----------|
| **A** | Canvas ≤300px | 좌측 3열 | ElementList \| Canvas \| Props | Board, Field, Strip |
| **B** | 극단 가로비 | 상단 전폭 | Canvas(전폭) + 2×2 grid | Blinds, History |
| **C** | Canvas 465px+ | 상단 전폭 | Canvas(전폭) + 3열 grid | Player, Outs, Leaderboard |

```
패턴 A (3열)              패턴 B (전폭+2×2)        패턴 C (전폭+3열)
┌────┬───────┬─────┐     ┌──────────────────┐     ┌──────────────────┐
│List│Canvas │Props│     │  Canvas (전폭)   │     │  Canvas (전폭)   │
│    │296×197│     │     │   790×52         │     │   465×120        │
│120 │       │ 280 │     ├────────┬─────────┤     ├──────┬─────┬─────┤
│ px │       │  px │     │Transform│Animat. │     │Trans.│Anim.│Text │
│    │       │     │     ├────────┼─────────┤     │      │     │     │
│    │       │     │     │Text    │Backgnd. │     │      │     │     │
└────┴───────┴─────┘     └────────┴─────────┘     └──────┴─────┴─────┘
```

### 3.2 모드별 상세

#### 3.2.1 Board (패턴 A) — 296×197px, 14 서브요소

```
GfxEditorBase mode="board"
│
├─ QSplitter (수평)
│   │
│   ├─ before: ElementList ─────────── 120px 고정
│   │   └─ QList dense
│   │       ├─ Background (selected)
│   │       ├─ FeltBackground
│   │       ├─ Logo
│   │       ├─ PotLabel
│   │       ├─ PotValue
│   │       ├─ Card1~Card5
│   │       ├─ DealerButton
│   │       ├─ BlindLevel
│   │       └─ Timer
│   │       (14개)
│   │
│   ├─ center: CanvasPreview ───────── flex:1
│   │   └─ .canvas-area (296×197)
│   │       └─ .canvas-el × 14 (absolute positioned)
│   │
│   └─ after: PropertyPanels ───────── 280px 고정
│       ├─ EbsSectionHeader "Transform" [T1 펼침]
│       │   └─ GE-03~GE-08 (+ GE-08a~d)
│       ├─ EbsSectionHeader "Animation" [T2]
│       │   └─ GE-09~GE-14
│       ├─ EbsSectionHeader "Text" [T2]
│       │   └─ GE-15~GE-22
│       └─ EbsSectionHeader "Background" [T2]
│           └─ GE-23
│
└─ EbsActionBar
    └─ Apply | Reset
```

#### 3.2.2 Field (패턴 A) — 270×90px, 3 서브요소

```
GfxEditorBase mode="field"
│
├─ QSplitter (수평)
│   ├─ before: ElementList ─────────── 120px
│   │   └─ Background | FieldLabel | FieldValue (3개)
│   ├─ center: CanvasPreview ───────── flex:1
│   │   └─ .canvas-area (270×90)
│   └─ after: PropertyPanels ───────── 280px
│       └─ Transform | Animation | Text | Background
│
└─ EbsActionBar
```

#### 3.2.3 Strip (패턴 A) — 270×90px, 6 서브요소

```
GfxEditorBase mode="strip"
│
├─ QSplitter (수평)
│   ├─ before: ElementList ─────────── 120px
│   │   └─ Background | StripBG | Name | Chip | Flag | Action (6개)
│   ├─ center: CanvasPreview ───────── flex:1
│   │   └─ .canvas-area (270×90)
│   └─ after: PropertyPanels ───────── 280px
│       └─ Transform | Animation | Text | Background
│
└─ EbsActionBar
```

#### 3.2.4 Blinds (패턴 B) — 790×52px, 4 서브요소

```
GfxEditorBase mode="blinds"
│
├─ CanvasPreview ───────────────────── 전폭
│   └─ .canvas-area (790×52, min-height:60px)
│       └─ Background | SmallBlind | BigBlind | Ante (4개)
│
├─ .grid-2x2 ──────────────────────── grid-template-columns: 1.15fr 1fr
│   ├─ [0,0] EbsSectionHeader "Transform" [T1]
│   │   └─ GE-03~GE-08
│   ├─ [0,1] EbsSectionHeader "Animation" [T2]
│   │   └─ GE-09~GE-14
│   ├─ [1,0] EbsSectionHeader "Text" [T2]
│   │   └─ GE-15~GE-22
│   └─ [1,1] EbsSectionHeader "Background" [T2]
│       └─ GE-23
│
└─ EbsActionBar
```

#### 3.2.5 History (패턴 B) — 345×33px, 3 서브요소

```
GfxEditorBase mode="history"
│
├─ CanvasPreview ───────────────────── 전폭
│   └─ .canvas-area (345×33)
│       └─ Background | HandNumber | Result (3개)
│
├─ .grid-2x2 ──────────────────────── 1.15fr 1fr
│   ├─ Transform | Animation
│   └─ Text      | Background
│
└─ EbsActionBar
```

#### 3.2.6 Player (패턴 C) — 465×120px, 9 서브요소

```
GfxEditorBase mode="player"
│
├─ CanvasPreview ───────────────────── 전폭
│   └─ .canvas-area (465×120)
│       └─ Background | PlayerName | ChipCount | Flag
│          Card1 | Card2 | Action | Timer | DealerBtn (9개)
│
├─ .three-col ─────────────────────── grid: 1.2fr 1fr 1.3fr
│   ├─ [col-1] EbsSectionHeader "Transform" [T1]
│   │   └─ GE-03~GE-08
│   ├─ [col-2] EbsSectionHeader "Animation" [T2]
│   │   └─ GE-09~GE-14
│   └─ [col-3] EbsSectionHeader "Text" [T2]
│       └─ GE-15~GE-22
│
├─ EbsSectionHeader "Background" [T2] ── 전폭
│   └─ GE-23
│
└─ EbsActionBar
```

#### 3.2.7 Outs (패턴 C) — 465×84px, 3 서브요소

```
GfxEditorBase mode="outs"
│
├─ CanvasPreview ───────────────────── 전폭
│   └─ .canvas-area (465×84)
│       └─ Background | OutsLabel | OutsCards (3개)
│
├─ .three-col ─────────────────────── 1.2fr 1fr 1.3fr
│   ├─ Transform | Animation | Text
│
├─ Background (전폭)
│
└─ EbsActionBar
```

#### 3.2.8 Leaderboard (패턴 C) — 800×103px, 9 서브요소

```
GfxEditorBase mode="leaderboard"
│
├─ CanvasPreview ───────────────────── 전폭
│   └─ .canvas-area (800×103)
│       └─ Background | Rank | PlayerName | ChipCount
│          CountryFlag | Bounty | Prize | Status | Trend (9개)
│
├─ .three-col ─────────────────────── 1.2fr 1fr 1.3fr
│   ├─ Transform | Animation | Text
│
├─ Background (전폭)
│
└─ EbsActionBar
```

### 3.3 모드별 치수 요약 테이블

| 모드 | 패턴 | Canvas (px) | 서브요소 | ElementList | Props 열 | CSS Grid |
|------|:----:|:-----------:|:--------:|:-----------:|:--------:|----------|
| Board | A | 296×197 | 14 | 120px 고정 | 280px 고정 | — |
| Field | A | 270×90 | 3 | 120px 고정 | 280px 고정 | — |
| Strip | A | 270×90 | 6 | 120px 고정 | 280px 고정 | — |
| Blinds | B | 790×52 | 4 | — | — | `1.15fr 1fr` (2×2) |
| History | B | 345×33 | 3 | — | — | `1.15fr 1fr` (2×2) |
| Player | C | 465×120 | 9 | — | — | `1.2fr 1fr 1.3fr` (3열) |
| Outs | C | 465×84 | 3 | — | — | `1.2fr 1fr 1.3fr` (3열) |
| Leaderboard | C | 800×103 | 9 | — | — | `1.2fr 1fr 1.3fr` (3열) |

> **Action Clock 제외**: PRD §3.3에서 Action Clock(109×109, 2개 서브요소)이 정의되어 있으나, 목업 미정의 상태("--")이므로 본 문서에서 제외. 구현 시점에 패턴 B 또는 C로 분류 예정.

---

## 4. 패널 내부 구성 — GE 공통 4패널

모든 GE 모드는 동일한 4개 속성 패널을 공유한다. 모드에 따라 배치만 달라진다(§3.1 참조).

### 4.1 TransformPanel — 위치/크기/회전 (10 컨트롤)

```
EbsSectionHeader "Transform" [T1 기본펼침]
│
├─ .prop-grid-2 (2열 grid, gap: 8px)
│   ├─ GE-03 PosX (EbsNumberInput)    │ GE-04 PosY (EbsNumberInput)
│   ├─ GE-05 Width (EbsNumberInput)   │ GE-06 Height (EbsNumberInput)
│   └─ GE-07 Rotation (EbsSlider)     │ GE-08 Opacity (EbsSlider)
│
└─ Sub-properties (GE-08 확장)
    ├─ GE-08a AnchorX (EbsSelect)
    ├─ GE-08b AnchorY (EbsSelect)
    ├─ GE-08c FlipH (EbsToggle)
    └─ GE-08d FlipV (EbsToggle)
```

| ID | 이름 | 컨트롤 | 범위/값 |
|----|------|--------|---------|
| GE-03 | Position X | EbsNumberInput | 0 ~ canvas.width |
| GE-04 | Position Y | EbsNumberInput | 0 ~ canvas.height |
| GE-05 | Width | EbsNumberInput | 1 ~ 9999 |
| GE-06 | Height | EbsNumberInput | 1 ~ 9999 |
| GE-07 | Rotation | EbsSlider | 0° ~ 360° |
| GE-08 | Opacity | EbsSlider | 0% ~ 100% |
| GE-08a | Anchor X | EbsSelect | Left/Center/Right |
| GE-08b | Anchor Y | EbsSelect | Top/Center/Bottom |
| GE-08c | Flip Horizontal | EbsToggle | on/off |
| GE-08d | Flip Vertical | EbsToggle | on/off |

### 4.2 AnimationPanel — 등장/퇴장 효과 (6 컨트롤)

```
EbsSectionHeader "Animation" [T2 접힘]
│
├─ GE-09 EntryType (EbsSelect)      ← Fade/Slide/Scale/None
├─ GE-10 EntryDuration (EbsSlider)  ← 0~2000ms
├─ GE-11 EntryDelay (EbsSlider)     ← 0~5000ms
├─ GE-12 ExitType (EbsSelect)       ← Fade/Slide/Scale/None
├─ GE-13 ExitDuration (EbsSlider)   ← 0~2000ms
└─ GE-14 ExitDelay (EbsSlider)      ← 0~5000ms
```

| ID | 이름 | 컨트롤 | 범위/값 |
|----|------|--------|---------|
| GE-09 | Entry Type | EbsSelect | None, Fade, SlideL/R/U/D, Scale |
| GE-10 | Entry Duration | EbsSlider | 0 ~ 2000ms (step 50) |
| GE-11 | Entry Delay | EbsSlider | 0 ~ 5000ms (step 100) |
| GE-12 | Exit Type | EbsSelect | None, Fade, SlideL/R/U/D, Scale |
| GE-13 | Exit Duration | EbsSlider | 0 ~ 2000ms (step 50) |
| GE-14 | Exit Delay | EbsSlider | 0 ~ 5000ms (step 100) |

### 4.3 TextPanel — 폰트/색상/정렬 (8 컨트롤)

```
EbsSectionHeader "Text" [T2 접힘]
│
├─ GE-15 FontFamily (EbsSelect)
├─ GE-16 FontSize (EbsNumberInput)
├─ GE-17 FontWeight (EbsSelect)     ← Regular/Bold/Light
├─ GE-18 FontColor (EbsColorPicker)
├─ GE-19 TextAlign (EbsSelect)      ← Left/Center/Right
├─ GE-20 LineHeight (EbsSlider)
├─ GE-21 LetterSpacing (EbsSlider)
└─ GE-22 TextTransform (EbsSelect)  ← None/Uppercase/Lowercase
```

| ID | 이름 | 컨트롤 | 범위/값 |
|----|------|--------|---------|
| GE-15 | Font Family | EbsSelect | 시스템 폰트 목록 |
| GE-16 | Font Size | EbsNumberInput | 6 ~ 200px |
| GE-17 | Font Weight | EbsSelect | Light/Regular/Medium/Bold/Black |
| GE-18 | Font Color | EbsColorPicker | HEX/RGB |
| GE-19 | Text Align | EbsSelect | Left/Center/Right |
| GE-20 | Line Height | EbsSlider | 0.8 ~ 3.0 (step 0.1) |
| GE-21 | Letter Spacing | EbsSlider | -5 ~ 20px |
| GE-22 | Text Transform | EbsSelect | None/Uppercase/Lowercase/Capitalize |

### 4.4 BackgroundPanel — 배경 이미지 (1 컨트롤)

```
EbsSectionHeader "Background" [T2 접힘]
│
└─ GE-23 BackgroundImage
    ├─ ImportBtn (QBtn "Import Image")
    └─ Preview (.bg-preview, 100%×52px)
```

| ID | 이름 | 컨트롤 | 비고 |
|----|------|--------|------|
| GE-23 | Background Image | QBtn + Preview | 이미지 파일 선택 → 미리보기 표시 |

### 4.5 패널별 Tier 요약

| 패널 | Tier | 기본 상태 | 컨트롤 수 | 추정 높이 |
|------|:----:|:--------:|:---------:|:---------:|
| Transform | T1 | **펼침** | 10 | ~260px |
| Animation | T2 | 접힘 | 6 | ~200px |
| Text | T2 | 접힘 | 8 | ~280px |
| Background | T2 | 접힘 | 1 | ~100px |
| **합계** | — | — | **25** | — |

---

## 5. 균형 검증 체크시트

전략 문서 §7의 5대 정량 지표를 각 화면에 적용한 검증표.

### 5.1 SE 메인 검증

| # | 지표 | 측정 방법 | 목표 | 현재 추정 | 판정 |
|:-:|------|----------|:----:|:---------:|:----:|
| 1 | 열 높이 편차 | `max(col) - min(col)` | ≤50px | ~40px (S1 적용 후) | PASS |
| 2 | T1 분포 | 각 열의 T1 항목 수 | 편차 ≤1개 | 좌1/중1/우2 (편차 1) | PASS |
| 3 | 정보 밀도 | 컨트롤 수 / 열 면적 | 편차 ≤20% | 좌9/중11/우24 → 밀도 보정 필요 | WARN |
| 4 | 여백 비율 | 여백 / 전체 면적 | 25-35% | ~30% (T2 접힘 시) | PASS |
| 5 | 경계선 수 | `border` CSS 카운트 | ≤5 | 3 (QSplitter 핸들 2 + dialog border 1) | PASS |

> **밀도 경고**: 우측 열(24 컨트롤)은 T3 접힘으로 초기 밀도가 억제되지만, 모두 펼칠 시 밀도 폭증. Phase 2에서 S2(QSplitter) + S4(auto/1fr grid) 적용으로 해소.

### 5.2 GE 모드별 검증

| 화면 | 열 높이 편차 | T1 분포 | 밀도 편차 | 여백 비율 | 경계선 수 | 판정 |
|------|:-----------:|:-------:|:---------:|:---------:|:---------:|:----:|
| Board (A) | ≤50px | T1×1열 | ≤20% | ~28% | 3 | PASS |
| Field (A) | ≤50px | T1×1열 | ≤20% | ~32% | 3 | PASS |
| Strip (A) | ≤50px | T1×1열 | ≤20% | ~30% | 3 | PASS |
| Blinds (B) | N/A (2×2) | T1×1셀 | ≤20% | ~27% | 4 | PASS |
| History (B) | N/A (2×2) | T1×1셀 | ≤20% | ~35% | 4 | PASS |
| Player (C) | ≤50px | T1×1열 | ≤20% | ~25% | 3 | PASS |
| Outs (C) | ≤50px | T1×1열 | ≤20% | ~33% | 3 | PASS |
| Leaderboard (C) | ≤50px | T1×1열 | ≤20% | ~26% | 3 | PASS |

### 5.3 교차 참조 커버리지

#### SE Element ID 매핑 검증

| 그룹 | PRD ID 범위 | 본 문서 §2 매핑 | 상태 |
|------|:----------:|:--------------:|:----:|
| Metadata | 01 ~ 05 | SkinMetadata 패널 | OK |
| Element Grid | 06 | ElementGrid 패널 | OK |
| Text & Font | 07 ~ 10 | 중앙 열 Text/Font | OK |
| Cards | 11 ~ 13 | 중앙 열 Cards | OK |
| Player | 14 ~ 17 | 중앙 열 Player | OK |
| Flags | 18 ~ 20 | 중앙 열 Flags | OK |
| Action Bar | 21 ~ 26 | EbsActionBar | OK |
| Colour | 27 ~ 30 | 좌측 열 ColourAdj/Replace | OK |
| Chipcount | 31 ~ 33 | 우측 열 Chipcount | OK |
| Currency | 34 ~ 37 | 우측 열 Currency | OK |
| Statistics | 38 ~ 43 | 우측 열 Statistics | OK |
| Card Display | 44 ~ 49 | 우측 열 Card Display | OK |
| Layout | 50 ~ 56 | 우측 열 Layout | OK |
| Misc | 57 ~ 61 | 우측 열 Misc | OK |

> **검증 결과**: 01 ~ 61 전체 61개 Element ID 매핑 완료. 누락 없음.

#### GE Element ID 매핑 검증

| 그룹 | PRD ID 범위 | 본 문서 §4 매핑 | 상태 |
|------|:----------:|:--------------:|:----:|
| Canvas | GE-01 | §3 각 모드 CanvasPreview | OK |
| Element Selector | GE-02 | §3 패턴A ElementList | OK |
| Transform | GE-03 ~ GE-08 (+a~d) | §4.1 TransformPanel | OK |
| Animation | GE-09 ~ GE-14 | §4.2 AnimationPanel | OK |
| Text | GE-15 ~ GE-22 | §4.3 TextPanel | OK |
| Background | GE-23 | §4.4 BackgroundPanel | OK |

> **검증 결과**: GE-01 ~ GE-23 (+ GE-08a~d) 전체 27개 Element ID 매핑 완료. 누락 없음.

---

## Changelog

| 날짜 | 버전 | 변경 내용 | 변경 유형 | 결정 근거 |
|------|------|-----------|----------|----------|
| 2026-03-16 | v1.0.0 | 최초 작성 — SE 메인 + GE 8모드 Layout Anatomy | PRODUCT | L2↔L0 갭 해소, 구현 전 상세 배치 명세 필요 |
