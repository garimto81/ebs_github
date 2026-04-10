# QA-GE-01: QA 전략 및 구현 가이드

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | Graphic Editor QA 전략, 테스트 항목, 구현 순서 |

---

## 개요

QA-GE-00 감사 결과를 기반으로 Graphic Editor 앱의 테스트 전략을 정의한다.

> 레포: `/ebs_ui/ebs-skin-editor/` | 프레임워크: Vue 3 + Quasar | 행동 명세: 없음 (역설계 문서 참조)

---

## Invariant

| Invariant | 검증 방법 |
|----------|----------|
| Element 수 보존 | add/remove 후 elements.length 정합성 |

---

## 사전 작업

```bash
cd /c/claude/ebs_ui/ebs-skin-editor
npm install   # Playwright 이미 설치됨
```

---

## Unit 테스트 (P0)

| # | 대상 | 파일 | 테스트 항목 | 우선순위 |
|---|------|------|-----------|:-------:|
| G-U01 | useGfxStore | `tests/stores/useGfxStore.spec.ts` | addElement → elements 증가 | P0 |
| G-U02 | useGfxStore | 상동 | removeElement → elements 감소, 선택 해제 | P0 |
| G-U03 | useGfxStore | 상동 | updateElement → 속성 변경 반영 | P0 |
| G-U04 | useGfxStore | 상동 | selectElement → selectedId 변경 | P1 |
| G-U05 | useGfxStore | 상동 | undo/redo 스택 검증 | P1 |
| G-U06 | 색상 계산 | `tests/utils/color_test.spec.ts` | RGB↔HEX 변환, HUE 회전 | P2 |

---

## Component 테스트 — Interaction 추가 (P1)

기존 16개 spec은 렌더링만 검증. **사용자 interaction 테스트** 추가:

| # | 컴포넌트 | 테스트 항목 | 우선순위 |
|---|---------|-----------|:-------:|
| G-C01 | EbsColorPicker | 색상 입력 → store 업데이트 | P1 |
| G-C02 | EbsNumberInput | 값 변경 → store 반영 + min/max 클램핑 | P1 |
| G-C03 | EbsSlider | 드래그 → 값 변경 → store 반영 | P1 |
| G-C04 | TransformPanel | X/Y/W/H 변경 → 선택 요소 위치/크기 변경 | P0 |
| G-C05 | TextPanel | 폰트/사이즈 변경 → 선택 텍스트 요소 업데이트 | P1 |
| G-C06 | AdjustColoursPanel | 색상 교체 규칙 추가/삭제 | P1 |
| G-C07 | EbsActionBar | 버튼 클릭 → 해당 액션 실행 (add, delete, duplicate) | P0 |
| G-C08 | GfxEditorDialog | 열기/닫기 + 확인 콜백 | P2 |

---

## E2E 테스트 — Playwright (P2)

| # | 시나리오 | 검증 |
|---|---------|------|
| G-E01 | 앱 로드 → 요소 추가 → 속성 편집 → 저장 | 기본 워크플로우 |
| G-E02 | 텍스트 요소 추가 → 폰트 변경 → 색상 변경 | 텍스트 편집 |
| G-E03 | 다수 요소 → 선택 → 삭제 → Undo | 실행 취소 |

---

## 커버리지 목표

| 계층 | Phase 1 | 최종 |
|------|:-------:|:----:|
| Unit (store) | ≥70% | ≥90% |
| Component | interaction 8건 | 전체 컴포넌트 |
| E2E | 3 시나리오 | 전체 워크플로우 |

---

## 구현 순서

| Phase | 항목 | 범위 |
|:-----:|------|------|
| 1 | G-U01~G-U04 + G-C04, G-C07 | store + P0 interaction |
| 2 | G-U05~G-U06 + G-C01~G-C06, G-C08 | P1 unit + component |
| 3 | G-E01~G-E03 + CI/CD | Playwright E2E + 자동화 |

---

## 참조

- 감사 결과: `docs/qa/graphic-editor/QA-GE-00-audit.md`
- 역설계: `C:\claude\ebs_reverse\docs\02-design\pokergfx-reverse-engineering-complete.md`
- 상위 전략: `docs/testing/TEST-01-test-plan.md`
