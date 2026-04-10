# QA-GE-02: Graphic Editor QA 체크리스트 (BS-07 + 컴포넌트 기반)

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | BS-07 + 역설계 문서 기반 QA 체크리스트 + 구현 대조 |

## 개요

BS-07 행동 명세 및 컴포넌트 분석에서 추출한 요구사항을 구현 코드와 대조한 결과.

> 레포: `/ebs_ui/ebs-skin-editor/` | 프레임워크: Vue 3 + Quasar + Pinia

---

## GE-01: Overlay Display Elements (10항목)

오버레이 화면에 렌더링되어야 하는 그래픽 요소의 구현 상태.

| ID | 항목 | 상태 | 비고 |
|----|------|:----:|------|
| GE-01-01 | 홀카드 렌더링 (좌석별 2장) | ⚠️ | board 모드 요소만 정의, player 모드 미완성 |
| GE-01-02 | 커뮤니티 보드 카드 (Flop 3 + Turn 1 + River 1) | ⚠️ | BOARD_DEFAULT_ELEMENTS에 card1-5 정의됨 |
| GE-01-03 | 플레이어 이름/국기/사진 | ⚠️ | player 모드 캔버스 크기 정의됨, 기본 요소 미정의 |
| GE-01-04 | 칩 스택 (금액/BB/둘다) | ⚠️ | 동일 |
| GE-01-05 | 팟 합계 (메인+사이드) | ✅ | BOARD_DEFAULT_ELEMENTS에 pot, amount 포함 |
| GE-01-06 | Equity bar (%) | ❌ | 미정의 |
| GE-01-07 | 핸드 랭크 라벨 | ⚠️ | hand 요소 존재하나 로직 없음 |
| GE-01-08 | 액션 뱃지 (CHECK/FOLD/BET 등) | ❌ | 미정의 |
| GE-01-09 | 딜러 버튼 (D) | ❌ | 미정의 |
| GE-01-10 | 하단 자막 (블라인드/팟/커스텀) | ⚠️ | blinds, blindsValue 요소 있음 |

**요약**: 10항목 중 ✅ 1 / ⚠️ 5 / ❌ 4

---

## GE-02: Animation System (6항목)

오버레이 전환 및 상태 변경 시 애니메이션 시스템의 구현 상태.

| ID | 항목 | 상태 | 비고 |
|----|------|:----:|------|
| GE-02-01 | FadeIn 애니메이션 (~300ms) | ⚠️ | entryType/entryDuration 속성 있으나 실제 재생 없음 |
| GE-02-02 | SlideUp 애니메이션 (~300ms) | ⚠️ | 동일 |
| GE-02-03 | Fold SlideAndDarken (~400ms) | ❌ | 미구현 |
| GE-02-04 | Winner glint 시퀀스 | ❌ | 미구현 |
| GE-02-05 | Reset 애니메이션 | ❌ | 미구현 |
| GE-02-06 | 4종 전환 (fade/slide/pop/expand) | ⚠️ | AnimationPanel에 옵션 존재, 실제 적용 없음 |

**요약**: 6항목 중 ✅ 0 / ⚠️ 3 / ❌ 3

---

## GE-03: Skin System (7항목)

스킨 파일 로딩, 에셋 관리, 전환 효과 등 스킨 시스템 전반의 구현 상태.

| ID | 항목 | 상태 | 비고 |
|----|------|:----:|------|
| GE-03-01 | .skin.json 로딩 | ❌ | TODO stub: console.log only |
| GE-03-02 | Rive .riv 파일 로딩 | ❌ | Import 버튼 있으나 처리 없음 |
| GE-03-03 | 카드 이미지 에셋 (52장+back) | ❌ | 미구현 |
| GE-03-04 | 스킨 전환 효과 | ❌ | 미구현 |
| GE-03-05 | fallback 스킨 ("ebs-default") | ❌ | 미구현 |
| GE-03-06 | 스킨 JSON 검증 | ❌ | 미구현 |
| GE-03-07 | 애니메이션 속도 오버라이드 | ❌ | 미구현 |

**요약**: 7항목 중 ✅ 0 / ⚠️ 0 / ❌ 7

---

## GE-08: UI Editor (7항목)

에디터 UI 패널 및 캔버스 프리뷰의 구현 상태.

| ID | 항목 | 상태 | 비고 |
|----|------|:----:|------|
| GE-08-01 | Canvas 프리뷰 (가변 크기) | ✅ | EbsGfxCanvas.vue 완전 구현 |
| GE-08-02 | Transform 패널 (x/y/w/h/rotation/opacity) | ✅ | TransformPanel.vue 12개 속성 |
| GE-08-03 | Z-order/margin/cornerRadius/anchor | ✅ | TransformPanel.vue에 포함 |
| GE-08-04 | Text 속성 (font/size/color/shadow/outline) | ✅ | TextPanel.vue 완전 구현 |
| GE-08-05 | Animation 패널 (entry/exit/duration/Rive) | ✅ | AnimationPanel.vue 완전 구현 |
| GE-08-06 | Colour 조정 (HUE/RGB + 3규칙 교체) | ✅ | AdjustColoursPanel.vue 완전 구현 |
| GE-08-07 | Background 이미지 업로드 | ✅ | EbsGfxCanvas.vue에 포함 |

**요약**: 7항목 중 ✅ 7 / ⚠️ 0 / ❌ 0

---

## GE-09: Element Management (4항목)

요소 관리(모드 전환, 선택, 가시성, 뷰포트 제약)의 구현 상태.

| ID | 항목 | 상태 | 비고 |
|----|------|:----:|------|
| GE-09-01 | 8종 모드 전환 (board/player/blinds/outs/...) | ✅ | useGfxStore.setMode() |
| GE-09-02 | 요소 선택 + 속성 동기화 | ✅ | useGfxStore.selectElement() |
| GE-09-03 | 요소 가시성 토글 | ✅ | useGfxStore.toggleElementVisibility() |
| GE-09-04 | 뷰포트 크기 제약 | ✅ | CSS overflow hidden + 퍼센트 기반 |

**요약**: 4항목 중 ✅ 4 / ⚠️ 0 / ❌ 0

---

## GE-10: File Format (3항목)

.gfskin 파일 형식 정의, 로드, 내보내기 기능의 구현 상태.

| ID | 항목 | 상태 | 비고 |
|----|------|:----:|------|
| GE-10-01 | .gfskin 형식 정의 | ❌ | 미정의 |
| GE-10-02 | .gfskin 로드 | ❌ | stub: console.log only |
| GE-10-03 | .gfskin 내보내기 | ❌ | stub: console.log only |

**요약**: 3항목 중 ✅ 0 / ⚠️ 0 / ❌ 3

---

## GE-11: Data Integrity (3항목)

데이터 무결성 관리(dirty 추적, 리셋, 스키마 검증)의 구현 상태.

| ID | 항목 | 상태 | 비고 |
|----|------|:----:|------|
| GE-11-01 | isDirty 상태 추적 | ✅ | useSkinStore.isDirty |
| GE-11-02 | 기본값 리셋 | ✅ | useSkinStore.resetToDefault() |
| GE-11-03 | 스키마 검증 | ❌ | 미구현 |

**요약**: 3항목 중 ✅ 2 / ⚠️ 0 / ❌ 1

---

## 전체 구현 현황 요약

| 카테고리 | 전체 | ✅ | ⚠️ | ❌ |
|----------|:----:|:--:|:--:|:--:|
| GE-01 Overlay Display | 10 | 1 | 5 | 4 |
| GE-02 Animation | 6 | 0 | 3 | 3 |
| GE-03 Skin System | 7 | 0 | 0 | 7 |
| GE-08 UI Editor | 7 | 7 | 0 | 0 |
| GE-09 Element Mgmt | 4 | 4 | 0 | 0 |
| GE-10 File Format | 3 | 0 | 0 | 3 |
| GE-11 Data Integrity | 3 | 2 | 0 | 1 |
| **합계** | **40** | **14** | **8** | **18** |

---

## Gap Analysis

| 심각도 | 항목 | 설명 |
|:------:|------|------|
| CRITICAL | Skin 로딩/저장 (.gfskin) | stub만 존재. 파일 I/O 전무 |
| CRITICAL | Rive 애니메이션 통합 | Import 버튼만 존재, 실제 로딩/재생 없음 |
| HIGH | Overlay 요소 (player/equity/action) | board 모드만 기본 요소 있음. 8개 모드 중 1개만 구현 |
| HIGH | 카드 에셋 관리 | 52장 이미지 로딩 없음 |
| MEDIUM | 애니메이션 재생 | 속성 정의됨 (type/duration) but 실제 재생 없음 |
| LOW | 스키마 검증 | 런타임 검증 없음 |

---

## 현재 상태 판정

**UI 에디터(GE-08, GE-09)는 완성**. 속성 편집, 요소 관리, 캔버스 프리뷰 동작.

**Skin 시스템(GE-03, GE-10)은 미구현**. 파일 I/O가 stub 상태.

**Overlay 렌더링(GE-01, GE-02)은 부분 구현**. board 요소만 정의.

BS-07 명세 기준 **구현율 약 40%** (에디터 UI 완성 but 렌더링/파일 시스템 미완).

---

## 참조

- 역설계: `C:\claude\ebs_reverse\docs\02-design\pokergfx-reverse-engineering-complete.md`
- 감사 결과: `docs/qa/graphic-editor/QA-GE-00-audit.md`
- 행동 명세: `contracts/specs/BS-07-overlay/` (4파일)
