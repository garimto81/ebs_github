# UI-00 Design System

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 색상, 타이포, 간격, 컴포넌트 토큰, 다크 모드, 포커 전용 정의 |
| 2026-04-10 | critic revision | Team 1 기술 스택 React TBD → Quasar Framework (Vue 3) + TypeScript 확정, Settings 탭 구조 6탭 반영, Team 4 Graphic Editor 경계 명시 |
| 2026-04-10 | CCR-011/025 후속 반영 | Graphic Editor 소유권 Team 4 → Team 1 이관 (CCR-011 APPLIED), §7 앱별 표에 Graphic Editor 를 Team 1 통합, Rive 에디터(외부) 역할 추가, BS-03-02-gfx 시각 asset 메타(CCR-025) 경계 반영 |
| 2026-04-10 | Readiness §9-12 신설 | §9 Quasar q-* 컴포넌트 매핑 (30+ 컴포넌트), §10 접근성(WCAG 2.1 AA, ARIA 랜드마크, 키보드 단축키), §11 성능 목표(Core Web Vitals + bundle size), §12 공통 상태 패턴(Loading/Error/Empty FSM + 재사용 컴포넌트) |
| 2026-04-13 | WSOP LIVE 레이아웃 토큰 | §13 헤더/사이드바/좌석그리드/역할뱃지 토큰 추가 (WSOP LIVE Staff Page 정렬) |

---

## 개요

EBS 전체 앱(Lobby, Command Center, Overlay, Settings)에 적용되는 디자인 시스템이다. 방송 환경(어두운 조명, 장시간 사용)에 최적화된 **다크 모드 기본** 설계.

---

## 1. 색상 팔레트

### 1.1 Core Colors

| 토큰 | Hex | 용도 |
|------|-----|------|
| **primary** | `#2563EB` | 주요 버튼, 링크, 강조 |
| **primary-hover** | `#1D4ED8` | Primary 호버 상태 |
| **primary-pressed** | `#1E40AF` | Primary 눌림 상태 |
| **secondary** | `#64748B` | 보조 버튼, 비활성 텍스트 |
| **accent** | `#F59E0B` | 경고, 하이라이트, 딜러 버튼 |
| **success** | `#22C55E` | 연결 완료, 승인, LIVE 상태 |
| **error** | `#EF4444` | 에러, 연결 끊김, FOLD |
| **warning** | `#F97316` | 주의, RFID 에러 |

### 1.2 Background / Surface

| 토큰 | Hex | 용도 |
|------|-----|------|
| **bg-primary** | `#0F172A` | 앱 전체 배경 (가장 어두운) |
| **bg-secondary** | `#1E293B` | 카드, 패널 배경 |
| **bg-tertiary** | `#334155` | 입력 필드, 드롭다운 배경 |
| **surface** | `#1E293B` | 모달, 다이얼로그 표면 |
| **surface-elevated** | `#334155` | 드롭다운, 툴팁 표면 |
| **border** | `#475569` | 일반 테두리 |
| **border-focus** | `#2563EB` | 포커스 테두리 |

### 1.3 Text Colors

| 토큰 | Hex | 용도 |
|------|-----|------|
| **text-primary** | `#F8FAFC` | 기본 텍스트 |
| **text-secondary** | `#94A3B8` | 보조 텍스트, 라벨 |
| **text-disabled** | `#64748B` | 비활성 텍스트 |
| **text-inverse** | `#0F172A` | 밝은 배경 위 텍스트 |

---

## 2. 타이포그래피

### 2.1 Font Family

| 용도 | Font | 비고 |
|------|------|------|
| **UI 전체** | Inter (TBD) | 가독성, 숫자 정렬 우수 |
| **숫자 전용** | Roboto Mono | 칩 카운트, 팟, 금액 — 고정폭 |
| **오버레이** | 스킨 정의 | 스킨별 폰트 오버라이드 가능 |

### 2.2 크기 체계

| 토큰 | 크기 | 줄 높이 | 용도 |
|------|:----:|:------:|------|
| **h1** | 32px | 40px | 페이지 타이틀 (Lobby) |
| **h2** | 24px | 32px | 섹션 타이틀 |
| **h3** | 20px | 28px | 카드 타이틀, 다이얼로그 헤더 |
| **h4** | 18px | 24px | 서브 헤더 |
| **h5** | 16px | 22px | 테이블 헤더 |
| **h6** | 14px | 20px | 캡션 헤더 |
| **body-lg** | 16px | 24px | 본문 (기본) |
| **body** | 14px | 20px | 본문 (보조) |
| **body-sm** | 13px | 18px | 소형 본문 |
| **caption** | 12px | 16px | 캡션, 타임스탬프 |
| **overline** | 11px | 16px | 오버라인 라벨, 뱃지 |

### 2.3 Font Weight

| 토큰 | 값 | 용도 |
|------|:--:|------|
| **regular** | 400 | 본문 |
| **medium** | 500 | 라벨, 버튼 |
| **semibold** | 600 | 강조 텍스트 |
| **bold** | 700 | 타이틀, 핵심 숫자 |

---

## 3. 간격 시스템

### 3.1 Base Grid: 4px

| 토큰 | 값 | 용도 |
|------|:--:|------|
| **space-1** | 4px | 아이콘-텍스트 간격, 인라인 간격 |
| **space-2** | 8px | 버튼 내부 패딩, 리스트 항목 간격 |
| **space-3** | 12px | 입력 필드 패딩 |
| **space-4** | 16px | 카드 내부 패딩, 섹션 간격 |
| **space-6** | 24px | 섹션 그룹 간격 |
| **space-8** | 32px | 영역 간격 |
| **space-12** | 48px | 대형 섹션 간격 |
| **space-16** | 64px | 페이지 상하 여백 |

### 3.2 레이아웃 간격

| 요소 | 간격 |
|------|------|
| 카드 그리드 gap | 16px |
| 모달 내부 패딩 | 24px |
| 상단 바 높이 | 48px |
| 하단 액션 패널 높이 | 80px (CC) |
| Breadcrumb 높이 | 40px |

---

## 4. 컴포넌트 토큰

### 4.1 라운드 코너

| 토큰 | 값 | 용도 |
|------|:--:|------|
| **radius-sm** | 4px | 뱃지, 태그 |
| **radius-md** | 8px | 버튼, 입력 필드 |
| **radius-lg** | 12px | 카드, 모달 |
| **radius-xl** | 16px | 대형 패널 |
| **radius-full** | 9999px | 아바타, 원형 버튼 |

### 4.2 그림자

| 토큰 | 값 | 용도 |
|------|-----|------|
| **shadow-sm** | `0 1px 2px rgba(0,0,0,0.3)` | 카드, 버튼 |
| **shadow-md** | `0 4px 8px rgba(0,0,0,0.4)` | 드롭다운, 팝오버 |
| **shadow-lg** | `0 8px 24px rgba(0,0,0,0.5)` | 모달 |
| **shadow-glow** | `0 0 12px rgba(37,99,235,0.4)` | 포커스, action_on |

### 4.3 테두리

| 토큰 | 값 | 용도 |
|------|-----|------|
| **border-default** | `1px solid #475569` | 일반 테두리 |
| **border-focus** | `2px solid #2563EB` | 포커스 상태 |
| **border-error** | `2px solid #EF4444` | 에러 상태 |
| **border-success** | `2px solid #22C55E` | 성공 상태 |

---

## 5. 다크 모드

### 5.1 기본 모드 = 다크

방송 환경은 조명이 어둡다. 운영자가 CC를 수 시간 연속 사용하므로 **다크 모드가 기본**이다. 라이트 모드는 Phase 2+에서 선택적 지원 검토.

### 5.2 다크 모드 원칙

| 원칙 | 설명 |
|------|------|
| **대비** | WCAG AA 이상 (텍스트 4.5:1, 대형 텍스트 3:1) |
| **피로 감소** | 순수 블랙(`#000`) 미사용 — `#0F172A` 기반 |
| **강조 색상** | 포화도 높은 색상은 면적 최소화, 텍스트/뱃지에만 |
| **테두리 의존** | 카드/패널 구분에 그림자보다 미묘한 테두리 우선 |

---

## 6. 포커 전용 디자인 토큰

### 6.1 수트 색상

| 수트 | 기호 | 색상 | Hex |
|------|:----:|------|-----|
| **Spades** | ♠ | 검정 (다크 모드: 밝은 회색) | `#E2E8F0` |
| **Clubs** | ♣ | 검정 (다크 모드: 밝은 회색) | `#E2E8F0` |
| **Hearts** | ♥ | 빨강 | `#EF4444` |
| **Diamonds** | ♦ | 빨강 | `#EF4444` |

> 다크 모드에서 ♠♣를 순수 검정으로 렌더링하면 배경에 묻히므로 밝은 회색(`#E2E8F0`)을 사용한다.

### 6.2 카드 렌더링

| 토큰 | 값 | 용도 |
|------|-----|------|
| **card-bg** | `#FFFFFF` | 카드 배경 (항상 흰색) |
| **card-back** | `#1E40AF` | 카드 뒷면 |
| **card-border** | `1px solid #CBD5E1` | 카드 테두리 |
| **card-radius** | 6px | 카드 라운드 코너 |
| **card-shadow** | `0 2px 4px rgba(0,0,0,0.3)` | 카드 그림자 |
| **card-width** | 48px (CC), 72px (Overlay) | 카드 기본 너비 |
| **card-ratio** | 2.5:3.5 (표준 포커 카드 비율) | 가로:세로 |

### 6.3 액션 배지 색상

| 액션 | 배경 | 텍스트 |
|------|------|--------|
| **CHECK** | `#22C55E` | `#FFFFFF` |
| **FOLD** | `#EF4444` | `#FFFFFF` |
| **BET** | `#F59E0B` | `#0F172A` |
| **CALL** | `#3B82F6` | `#FFFFFF` |
| **RAISE** | `#F59E0B` | `#0F172A` |
| **ALL-IN** | `#DC2626` | `#FFFFFF` |

### 6.4 테이블 상태 색상

| 상태 | 색상 | Hex |
|------|------|-----|
| **EMPTY** | 회색 | `#64748B` |
| **SETUP** | 황색 | `#F59E0B` |
| **LIVE** | 녹색 | `#22C55E` |
| **PAUSED** | 주황 | `#F97316` |
| **CLOSED** | 적색 | `#EF4444` |

### 6.5 포지션 뱃지

| 뱃지 | 배경 | 텍스트 | 용도 |
|------|------|--------|------|
| **D** | `#F59E0B` | `#0F172A` | 딜러 버튼 |
| **SB** | `#64748B` | `#FFFFFF` | Small Blind |
| **BB** | `#475569` | `#FFFFFF` | Big Blind |
| **STR** | `#7C3AED` | `#FFFFFF` | Straddle |

---

## 7. 앱별 디자인 특성

| 앱 | 기술 | 소속 팀 | 디자인 특성 |
|----|------|:------:|-----------|
| **Lobby + Settings + Graphic Editor** | Quasar Framework (Vue 3) + TypeScript + `@rive-app/canvas` | Team 1 | 정보 밀도 높음, 테이블/리스트 중심, 반응형, 폼 기반 설정 CRUD, `.gfskin` Import/Activate 허브 |
| **CC (Command Center)** | Flutter | Team 4 | 터치 최적화, 큰 터치 타겟(48px+), 키보드 단축키 |
| **Overlay** | Flutter + Rive | Team 4 | 스킨 시스템 소비자(`skin_updated` WS 수신), 1080p/4K 해상도 대응, 크로마키 |
| **Rive 에디터 (외부)** | Rive 공식 에디터 (SaaS) | 외부 (Designer) | `.riv` 작성, Transform/keyframe/color 편집. EBS 에 포함되지 않음 |

> **Team 1 / Team 4 경계 주석 (CCR-011 APPLIED 2026-04-10)**
> Team 1 은 Settings 6탭 CRUD 뿐 아니라 **Graphic Editor 허브**(`/lobby/graphic-editor`) 도 소유한다. 허브 범위: `.gfskin` ZIP Upload·검증·rive-js 프리뷰·메타데이터 편집(GEM-01~25)·Activate + `skin_updated` WS broadcast.
> Team 1 은 **Rive 내부 편집 UI 를 만들지 않는다**. Transform/keyframe/color adjust 편집은 Rive 공식 에디터(외부)에서 수행하고 완성된 `.gfskin` ZIP 을 Team 1 허브에 업로드한다.
> Team 4 는 **Overlay 렌더링 소비자**로 재정의되었다. CC(Flutter) 가 `skin_updated` WS 이벤트를 수신하여 Overlay 를 리렌더한다. BS-03-02-gfx 에 정의된 시각 asset 메타(CCR-025) 는 Team 4 가 제공하고 Team 1 Settings 폼에 필드로 노출된다.

---

## 8. 반응형 브레이크포인트 (Lobby 웹 전용)

| 브레이크포인트 | 너비 | 레이아웃 |
|:------------:|:----:|---------|
| **sm** | 640px+ | 1열 카드 |
| **md** | 768px+ | 2열 카드 |
| **lg** | 1024px+ | 3열 카드 |
| **xl** | 1280px+ | 4열 카드 |
| **2xl** | 1536px+ | 5열 카드 + 사이드 패널 |

> CC(Flutter)는 고정 해상도 디바이스 대상이므로 반응형 불필요. 터치스크린 1920x1080 또는 태블릿 기준 설계.

---

## 9. Quasar 컴포넌트 매핑

디자인 토큰(§2-6)과 컴포넌트 원칙(§7)을 Quasar 의 실제 `q-*` 컴포넌트로 매핑한다. 본 표는 `src/components/common/` 공용 컴포넌트 작성의 기준이 된다. 상세 API 는 [Quasar 공식 문서](https://quasar.dev/vue-components) 참조.

### 9.1 기본 컴포넌트 매핑

| 용도 | Quasar 컴포넌트 | 기본 props | 비고 |
|------|----------------|-----------|------|
| **Button (primary)** | `q-btn` | `color="primary" unelevated no-caps` | `no-caps` 필수 (자동 대문자화 방지) |
| **Button (secondary)** | `q-btn` | `outline color="primary" no-caps` | |
| **Button (destructive)** | `q-btn` | `color="negative" unelevated no-caps` | 삭제/취소 액션 |
| **Icon button** | `q-btn` | `flat dense round icon="..."` | 아이콘 전용 |
| **Text input** | `q-input` | `outlined dense` | 라벨 필드 |
| **Password input** | `q-input` | `outlined dense type="password"` | toggle 아이콘 `icon-right="visibility"` |
| **Number input** | `q-input` | `outlined dense type="number"` | validation `:rules` |
| **Select (dropdown)** | `q-select` | `outlined dense emit-value map-options` | `:options` 배열 `{label, value}` |
| **Multi-select** | `q-select` | `outlined dense multiple use-chips` | |
| **Checkbox** | `q-checkbox` | — | |
| **Radio** | `q-radio` | — | |
| **Toggle (on/off)** | `q-toggle` | — | boolean 설정 |
| **Slider** | `q-slider` | `label markers` | 값 범위 |
| **Date picker** | `q-date` + `q-input` | popup 패턴 | Flight 생성 폼 |
| **Time picker** | `q-time` + `q-input` | popup 패턴 | Blind level duration |
| **File upload** | `q-file` | `outlined accept=".gfskin"` | GE 전용 |
| **Card** | `q-card` + `q-card-section` | `flat bordered` | Table card, Flight card |
| **List** | `q-list` + `q-item` | `bordered separator` | Series/Event 리스트 |
| **Table** | `q-table` | `flat bordered dense virtual-scroll` | Player 대량 리스트 |
| **Tabs** | `q-tabs` + `q-tab-panels` | `dense active-color="primary"` | Settings 6탭 |
| **Dialog** | `q-dialog` + `q-card` | `persistent` (경고) 또는 `seamless` | Session restore, Activate warning |
| **Tooltip** | `q-tooltip` | `anchor="top middle"` | 상태 배지 설명 |
| **Badge** | `q-badge` | `color="..." floating` | 상태, `Restricted`, 카운트 |
| **Chip** | `q-chip` | `dense color="..."` | 권한 태그 |
| **Progress bar (linear)** | `q-linear-progress` | `stripe` 또는 `indeterminate` | Rebalance saga (CCR-020), Upload |
| **Progress (circular)** | `q-circular-progress` | `indeterminate color="primary"` | 페이지 로드 |
| **Skeleton** | `q-skeleton` | `type="rect / text / avatar"` | Loading 상태 |
| **Banner** | `q-banner` | `rounded class="bg-negative text-white"` | Error 상태 |
| **Notification (toast)** | `$q.notify({ ... })` | plugin | Save/Delete 알림 |
| **Layout** | `q-layout` + `q-header` + `q-drawer` + `q-page-container` | `view="lHh Lpr lFf"` | MainLayout.vue |

### 9.2 폼 검증 원칙

- **Quasar 내장 `:rules` 우선**. `vee-validate` 등 외부 라이브러리 미도입.
- 각 필드는 다음 패턴:
  ```vue
  <q-input
    v-model="form.email"
    :label="$t('login.email')"
    :rules="[
      val => !!val || $t('validation.required'),
      val => /.+@.+\..+/.test(val) || $t('validation.email'),
    ]"
    outlined dense
  />
  ```
- 폼 전체 검증: `q-form` 의 `@submit` + `ref.value.validate()`.
- 비동기 검증 (중복 체크 등)은 `debounce` + `:rules` 에 async 함수.

### 9.3 금지 패턴

- `q-btn` 에 `label="SAVE"` 하드코딩 → 반드시 `:label="$t('common.save')"`
- Settings 폼에 외부 form 라이브러리 도입
- `q-table` 의 `pagination` 서버사이드 로직을 컴포넌트 안에 직접 작성 → store 에서 처리 후 props 전달
- `$q.dialog` 남발 → 5초 이내 닫히는 것은 `$q.notify`, 사용자 결정이 필요한 것만 `q-dialog`

---

## 10. 접근성 (Accessibility)

**기준**: WCAG 2.1 AA 준수를 목표. Screen reader 와 키보드 전용 조작이 가능해야 한다.

### 10.1 ARIA 랜드마크

`MainLayout.vue` 는 다음 랜드마크를 명시한다:

| 영역 | ARIA role / Quasar prop |
|------|-------------------------|
| 상단 헤더 | `q-header` → role="banner" |
| 좌측 사이드 드로어 (Series/Event 네비게이션) | `q-drawer` → role="navigation" |
| 메인 페이지 컨테이너 | `q-page-container` → role="main" |
| 하단 푸터 (있다면) | `q-footer` → role="contentinfo" |
| 알림 영역 | `$q.notify` → role="alert" (aria-live=polite 기본) |

### 10.2 키보드 네비게이션

모든 화면은 마우스 없이 Tab / Shift+Tab / Enter / Esc / 화살표로 조작 가능해야 한다.

| 단축키 | 동작 |
|--------|------|
| `Tab` / `Shift+Tab` | 포커스 이동 |
| `Enter` | 버튼 클릭, 폼 제출 |
| `Space` | 체크박스/토글 전환 |
| `Esc` | 다이얼로그 닫기, 드롭다운 접기 |
| `↑` / `↓` | List/Select 항목 이동 |
| `Ctrl+K` (옵션) | 전역 검색 (Series/Event/Table) |
| `Ctrl+S` (옵션) | Settings 저장 |

### 10.3 Color Contrast

§3 Color 토큰의 배경/텍스트 조합은 모두 **4.5:1 이상** 대비비를 가져야 한다. `#0F172A` 배경 + `#F8FAFC` 텍스트 = 16.8:1 (통과). 경고색 `#F59E0B` 위 흰 텍스트는 `color-burn` 사용 금지.

### 10.4 Focus Indicator

모든 포커스 가능 요소는 **보이는 focus ring** 을 가져야 한다. Quasar 기본 `outline` 을 꺼두지 말 것:
```scss
// src/css/quasar.variables.scss 에서 tabindex:focus-visible 스타일 유지
```

### 10.5 화면별 체크리스트 (각 UI 문서에서 참조)

- [ ] 페이지 제목이 `document.title` 에 반영 (`useHead` 또는 `router.meta.title`)
- [ ] 이미지는 모두 `alt` 속성
- [ ] 폼 필드는 모두 `label` 또는 `aria-label`
- [ ] 에러 메시지는 `aria-live="polite"` 영역에 배치
- [ ] 다이얼로그 열릴 때 포커스가 첫 요소로 이동, 닫힐 때 원래 위치로 복귀
- [ ] Skip link: "메인 콘텐츠로 건너뛰기" 링크를 헤더 첫 요소로 (Tab 첫 번째 포커스)

---

## 11. 성능 목표

**기준**: Lighthouse CI Performance 점수 90 이상 (desktop), 80 이상 (mobile). Core Web Vitals:

| 지표 | 목표 | 측정 방법 |
|------|:----:|-----------|
| **FCP** (First Contentful Paint) | < 1.5s | Lighthouse |
| **LCP** (Largest Contentful Paint) | < 2.5s | Lighthouse |
| **TTI** (Time to Interactive) | < 3.5s | Lighthouse |
| **CLS** (Cumulative Layout Shift) | < 0.1 | Lighthouse |
| **INP** (Interaction to Next Paint) | < 200ms | Web Vitals lib |
| **JS bundle size** | < 500KB gzipped (main chunk) | `pnpm build` + bundle analyzer |
| **초기 API 요청 수** | < 5 | Network tab |

### 11.1 최적화 전략

- **Route-level code splitting**: 모든 `component: () => import(...)` 동적 import (§UI-A1 §2 참조). Settings 탭/GE 허브는 lazy load.
- **Quasar tree shaking**: `quasar.config.js > framework.components` 에 실제 사용 컴포넌트만 명시
- **Pinia 선택적 구독**: 컴포넌트에서 `storeToRefs()` 로 필요한 state 만 반응
- **이미지**: 아이콘은 `@quasar/extras` SVG, 사진은 WebP + `loading="lazy"`
- **폰트**: 필요한 weight 만 로드 (400/600/700)
- **API 폴링 금지**: 실시간 업데이트는 WebSocket 으로만. 폴링은 retry 에서만
- **대용량 리스트**: `q-virtual-scroll` 또는 `q-table` 의 `virtual-scroll`
- **메모이제이션**: 계산 비용 높은 getter 는 Pinia computed

### 11.2 Regression 감지

CI 에서 `lighthouse-ci` 실행 → PR 에서 성능 점수 감소 시 경고. 구현 위치: `.github/workflows/lighthouse.yml` (QA-LOBBY-06 §CI).

---

## 12. 공통 상태 패턴 (Loading / Error / Empty)

모든 화면은 아래 3가지 상태를 일관되게 렌더링한다. `src/components/common/` 에 재사용 컴포넌트로 구현.

### 12.1 Loading 상태

**원칙**: 1초 이상 걸릴 수 있는 로드는 **스켈레톤** 으로 표시. 1초 미만은 아무것도 표시 하지 않는다 (깜빡임 방지).

```vue
<!-- src/components/common/LoadingState.vue -->
<template>
  <div v-if="loading">
    <q-skeleton v-for="i in count" :key="i" :type="type" class="q-mb-sm" />
  </div>
  <slot v-else />
</template>

<script setup lang="ts">
defineProps<{
  loading: boolean;
  type?: 'text' | 'rect' | 'circle';
  count?: number;
}>();
</script>
```

사용 예:
```vue
<LoadingState :loading="lobbyStore.loading.series" type="rect" :count="5">
  <SeriesListCards :items="lobbyStore.series" />
</LoadingState>
```

### 12.2 Error 상태

**원칙**: 에러는 화면을 대체하지 않고 상단에 배너로 표시. 재시도 버튼 필수.

```vue
<!-- src/components/common/ErrorBanner.vue -->
<template>
  <q-banner v-if="error" rounded class="bg-negative text-white q-mb-md">
    <template #avatar><q-icon name="error" /></template>
    {{ error }}
    <template #action>
      <q-btn flat :label="$t('common.retry')" @click="$emit('retry')" />
    </template>
  </q-banner>
</template>

<script setup lang="ts">
defineProps<{ error: string | null }>();
defineEmits<{ retry: [] }>();
</script>
```

### 12.3 Empty 상태

**원칙**: 비어있는 리스트는 **illustration + 메시지 + 액션 버튼** 으로 유도. 단순 "데이터 없음" 금지.

```vue
<!-- src/components/common/EmptyState.vue -->
<template>
  <div class="empty-state text-center q-pa-xl">
    <q-icon :name="icon" size="4rem" class="text-grey-5" />
    <div class="text-h6 q-mt-md">{{ title }}</div>
    <div class="text-body2 text-grey-7 q-mt-sm">{{ description }}</div>
    <q-btn
      v-if="actionLabel"
      color="primary"
      unelevated
      no-caps
      class="q-mt-md"
      :label="actionLabel"
      @click="$emit('action')"
    />
  </div>
</template>

<script setup lang="ts">
defineProps<{
  icon?: string;          // Material icon name, 기본 'inbox'
  title: string;
  description?: string;
  actionLabel?: string;   // 옵션. 있으면 버튼 렌더
}>();
defineEmits<{ action: [] }>();
</script>
```

사용 예 (Series 리스트):
```vue
<EmptyState
  v-if="!loading && series.length === 0"
  icon="event"
  :title="$t('lobby.series.empty.title')"
  :description="$t('lobby.series.empty.description')"
  :action-label="auth.isAdmin ? $t('lobby.series.create') : ''"
  @action="createSeries"
/>
```

### 12.4 상태 전이 다이어그램

각 비동기 페이지는 아래 FSM 을 따른다.

```
  idle ──fetch()──▶ loading
                     │
          ┌──────────┴──────────┐
          │                     │
       success                failure
          │                     │
          ▼                     ▼
    ┌───────────┐           ┌───────┐
    │ has data? │           │ error │
    └─────┬─────┘           └───┬───┘
          │                     │
   ┌──────┴──────┐               │
   │             │               │
   ▼             ▼               │
  data         empty             │
          ◀──────── retry ──────┘
```

구현: store 의 `status: 'idle' | 'loading' | 'success' | 'empty' | 'error'` + 페이지에서 `v-if` 분기.

---

## 13. WSOP LIVE 레이아웃 토큰

WSOP LIVE Staff Page 정렬을 위한 레이아웃 토큰 (2026-04-13 추가).

### 13.1 헤더 바

| 토큰 | 값 | 비고 |
|------|-----|------|
| `$header-bg` | `#CC0000` | WSOP 빨간 헤더 |
| `$header-height` | `56px` | 기존 48px → 56px |
| `$header-text` | `#FFFFFF` | 흰색 텍스트 |

### 13.2 좌측 사이드바

| 토큰 | 값 | 비고 |
|------|-----|------|
| `$sidebar-width` | `240px` | 사이드바 너비 |
| `$sidebar-bg` | `#1A1A2E` | 다크 배경 |
| `$sidebar-item-height` | `40px` | 메뉴 아이템 높이 |
| `$sidebar-active-bg` | `rgba(255,255,255,0.08)` | 활성 메뉴 배경 |
| `$sidebar-hover-bg` | `rgba(255,255,255,0.04)` | 호버 메뉴 배경 |

### 13.3 좌석 그리드

| 토큰 | 값 | 비고 |
|------|-----|------|
| `$seat-occupied` | `$green-4` | 착석 |
| `$seat-empty` | `$grey-2` | 빈좌석 |
| `$seat-busted` | `$red-3` | 탈락 |
| `$seat-cell-size` | `32px` | 셀 크기 |
| `$seat-cell-gap` | `2px` | 셀 간격 |

### 13.4 역할 뱃지

| 역할 | 색상 | Quasar |
|------|------|--------|
| Admin | `$red-7` | `q-badge color="red-7"` |
| Operator | `$blue-7` | `q-badge color="blue-7"` |
| Viewer | `$grey-6` | `q-badge color="grey-6"` |

---
