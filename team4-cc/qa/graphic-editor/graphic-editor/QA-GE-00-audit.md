# QA-GE-00: 테스트 품질 감사 결과

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | Graphic Editor 테스트 품질 감사 |

---

## 개요

Graphic Editor(Skin Editor) 앱(`/ebs_ui/ebs-skin-editor/`)의 기존 테스트를 감사한 결과. **품질 점수 3/10**.

> 레포: `/ebs_ui/ebs-skin-editor/` | 프레임워크: Vue 3 + Vite + Quasar | 상태관리: Pinia

---

## 감사 요약

| 항목 | 상태 |
|------|------|
| 테스트 파일 | 16건 (15 component + 1 store) |
| 테스트 프레임워크 | Vitest 3.0.9 + @vue/test-utils 2.4.6 |
| 사용자 interaction 테스트 | **0건** |
| Store 상태 변경 검증 | **최소** (초기 상태, add, select만) |
| E2E | **0건** (Playwright 1.58.2 설치됨) |
| CI/CD | **없음** |

---

## 테스트 파일 상세

| 파일 | 테스트 수 | 검증 내용 | 문제 |
|------|:--------:|----------|------|
| `AdjustColoursPanel.spec.ts` | 6 | 섹션 렌더링, RGB 라벨, 버튼 존재 | interaction 없음 |
| `AnimationPanel.spec.ts` | 4 | Duration 라벨, 타입 셀렉터 존재 | interaction 없음 |
| `EbsActionBar.spec.ts` | 5 | 버튼 아이콘, 라벨 텍스트 | 클릭 콜백 미테스트 |
| `EbsColorPicker.spec.ts` | 3 | 입력 필드, 라벨 | 색상 변경 미테스트 |
| `EbsGfxCanvas.spec.ts` | 3 | 캔버스 렌더링, 그리드 토글 | 드래그/리사이즈 미테스트 |
| `EbsNumberInput.spec.ts` | 4 | 라벨, min/max 표시 | 값 변경 미테스트 |
| `EbsPropertyRow.spec.ts` | 2 | 라벨 + slot 렌더링 | — |
| `EbsSectionHeader.spec.ts` | 3 | 제목, 아이콘, collapse 버튼 | collapse 동작 미테스트 |
| `EbsSelect.spec.ts` | 3 | 옵션 렌더링 | 선택 변경 미테스트 |
| `EbsSlider.spec.ts` | 3 | 라벨, 값 표시 | 드래그 미테스트 |
| `EbsToggle.spec.ts` | 3 | 라벨, 상태 표시 | 토글 미테스트 |
| `GfxEditorBase.spec.ts` | 4 | 패널 섹션 존재 | — |
| `GfxEditorDialog.spec.ts` | 3 | 다이얼로그 렌더링 | 확인/취소 콜백 미테스트 |
| `TextPanel.spec.ts` | 5 | 폰트/사이즈/색상 필드 존재 | 변경 미테스트 |
| `TransformPanel.spec.ts` | 4 | X/Y/W/H 필드 존재 | 값 변경 미테스트 |
| `useGfxStore.spec.ts` | 5 | 초기 상태, addElement, selectElement | remove/update/undo 미테스트 |

### 공통 패턴

```typescript
// 16개 파일 전부 이 패턴
it('renders XYZ section', () => {
  const wrapper = mountQ(Component);
  expect(wrapper.text()).toContain('Label Text');
});
```

---

## CRITICAL 미테스트 영역

| 영역 | 위험도 |
|------|:------:|
| **사용자 interaction** (클릭, 드래그, 입력) | CRITICAL |
| **Pinia store 상태 변경** 후 UI 반영 | CRITICAL |
| **Canvas 렌더링 로직** | HIGH |
| **색상 변환 계산** (HUE, RGB) | HIGH |
| **Undo/Redo** 스택 | HIGH |
| **Import/Export** 기능 | MEDIUM |
| **키보드 단축키** | MEDIUM |

---

## 긍정 요소

- **Playwright 1.58.2 설치됨** — E2E 인프라 준비 상태
- **Vitest 3.0.9 + @vue/test-utils** — 프레임워크 최신
- **mountQ 헬퍼** 공유 — Quasar+Pinia 설정 재사용
- 행동 명세는 없지만 역설계 문서 참조 가능

---

## 참조

- 역설계: `C:\claude\ebs_reverse\docs\02-design\pokergfx-reverse-engineering-complete.md`
- QA 전략: `docs/qa/graphic-editor/QA-GE-01-strategy.md`

> 주의: 이 `QA-GE-*` 접두사는 Graphic Editor용. `docs/qa/game-engine/QA-GE-*`는 Game Engine용으로 별도.
