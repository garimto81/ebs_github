---
id: SG-renewal-ui-01
title: "Flutter CC PlayerColumn 1×10 + 9-row 시각 구조 정합 검증 + 정정"
type: spec_gap_visual_structure
status: OPEN
owner: conductor
created: 2026-05-15
last-updated: 2026-05-17
priority: P0
scope: frontend_design_only
title_correction_note: "v1 (2026-05-15) 의 '7-row' 표기는 부정확. PokerGFX 정본 PlayerColumn = 9-row (Status strip + Seat# + PosBlock + Country + Name + HoleCards + Stack + Bet + LastAction). v2 (2026-05-17) 정정."
affects_files:
  - team4-cc/src/lib/features/command_center/widgets/seat_cell.dart
  - team4-cc/src/lib/features/command_center/screens/at_01_main_screen.dart (PlayerGrid 1×10 layout)
  - team4-cc/src/lib/features/command_center/widgets/position_shift_chip.dart (PosBlock 3 stacked rows)
related_sg:
  - SG-renewal-ui-00 (Visual SSOT reference 경로 갱신 — 선행)
  - SG-renewal-ui-18 (게임 클래스별 CC UI 분기 — 후속)
parent_plan: ~/.claude/plans/decision-report-v5-ultrathink-rewrite.md
prd_refs:
  - Command_Center.md Ch.4 (PlayerGrid 1×10 + 9-row)
  - Command_Center.md Ch.17.2 (verbatim PlayerColumn JSX 인용)
  - Command_Center.md Ch.6.5 (L5 Frontend Stateless Display, v4.4)
pokergfx_refs:
  - archive/.../complete.md line 113-121 (AT Stateless Input Terminal ★)
parent_audit_superseded: docs/4. Operations/Reports/2026-05-15-prototype-accurate-original-gap-audit.md (P0-4 — SUPERSEDED)
component_mapping: docs/1. Product/Prototype/component_visual_mapping.md (Part 2.2 PlayerColumn)
---

# SG-renewal-ui-01 — PlayerColumn 1×10 + 9-row 시각 구조 정합 (v2 정정)

> **v2 정정 (2026-05-17)**: v1 의 "7-row" 표기는 부정확. 정본 PlayerColumn = **9-row** (Status strip + Seat# + PosBlock + Country + Name + HoleCards + Stack + Bet + LastAction). Command_Center.md Ch.17.2 PlayerColumn JSX verbatim 정합.

## 공백 서술

정본 CC 의 핵심 시각 구조는 **PlayerGrid 1×10 horizontal** + 각 좌석마다 **PlayerColumn 9-row click-to-edit** 컬럼. 이 구조가 운영자의 즉시 인지 + 즉시 편집 가능성을 결정짓는 핵심 UX. **PRD Ch.17.2 verbatim 인용 = SSOT** (정본 React ZIP 의 PlayerColumn.jsx 흡수 완료, 880줄 verbatim).

```
+------------------+ +------------------+ +------------------+ ... (10 columns)
| Status strip     | | Status strip     | | Status strip     |
| (ACTING/WAITING) | | (ACTING/WAITING) | | (ACTING/WAITING) |
+------------------+ +------------------+ +------------------+
| S1 (Seat#)       | | S2               | | S3               |
+------------------+ +------------------+ +------------------+
| PosBlock         | | PosBlock         | | PosBlock         |
| (STR/SB·BB/D)    | | ...              | | ...              |
+------------------+ +------------------+ +------------------+
| CTRY (flag)      | | ...              | | ...              |
| Player Name      | | ...              | | ...              |
+------------------+ +------------------+ +------------------+
| HoleCards (2)    | | ...              | | ...              |
+------------------+ +------------------+ +------------------+
| STACK $128,400   | | ...              | | ...              |
+------------------+ +------------------+ +------------------+
| BET —            | | BET $8,000       | | ...              |
+------------------+ +------------------+ +------------------+
| LAST —           | | LAST RAISE       | | ...              |
+------------------+ +------------------+ +------------------+
```

**검증 필요 항목** (시각 측면만, 기능은 NG7):

| 검증 항목 | 정본 명세 | Flutter 검증 결과 |
|----------|---------|------------------|
| Grid layout | 1×10 horizontal (10 컬럼 한 줄) | ⚠ 미확인 — at_01_main_screen.dart 검토 필요 |
| Status strip | ACTING / WAITING / FOLD / DELETE (preHand=true 시 DELETE) | ⚠ |
| Row 1 — Seat No | S1~S10, full-width 큰 글자 | ⚠ |
| Row 2 — PosBlock | STRADDLE / SB·BB / D 3 stacked rows + ‹/› shift arrows | ⚠ |
| Row 3a — Country | flag emoji + CTRY 라벨 | ⚠ |
| Row 3b — Name | Player name | ⚠ |
| Row 4 — HoleCards | 2 cards (back or face) | ⚠ |
| Row 5 — Stack | mono font $X,XXX | ⚠ |
| Row 6 — Bet | mono $X or "—" | ⚠ |
| Row 7 — LastAction | label or "—" | ⚠ |
| FOLD opacity | grayscale(0.85) ColorFilter (이미 구현됨 — `_kGrayscale85`) | ✅ |
| ACTING glow | --glow-action (이미 구현됨 — `ActingGlowOverlay`) | ✅ |
| Click-to-edit | 각 row 클릭 → FieldEditor 모달 (정본) ↔ at_07_player_edit_modal (Flutter) | ⚠ 시각만 검증 |

**Type**: D (drift — 시각 구조 일치 여부) + B (검증 결과에 따라 구조 보강)

## 발견 경위

- **트리거**: Renewal Plan Phase 2B.v4 (PlayerGrid 1×10 + PlayerColumn 7-row 시각 정합)
- **선행 audit**: 2026-05-15 Gap Audit 보고서 P0-4 (PlayerColumn 1×10 구조 일치 여부 미검증)
- **근거**: 정본 `PlayerColumn.jsx` (7.2 KB, 9 row 명확 구분) vs Flutter `seat_cell.dart` (구조 검증 안 됨)

## 영향받는 챕터 / 구현

| 파일 | 변경 범위 | 카테고리 |
|------|---------|:--------:|
| `team4-cc/src/lib/features/command_center/widgets/seat_cell.dart` | 7-row layout 검증, 부족하면 row 추가/재배치 | **시각** |
| `team4-cc/src/lib/features/command_center/screens/at_01_main_screen.dart` | PlayerGrid = 1×10 horizontal layout 검증 | **시각** |
| `team4-cc/src/lib/features/command_center/widgets/position_shift_chip.dart` | PosBlock 3 stacked rows (STR/SB·BB/D) 시각 | **시각** |

**수정 금지** (NG7 — 기능):
- `seat_provider.dart` (sync 필드 등)
- `hand_fsm_provider.dart` (FSM 로직)
- `action_button_provider.dart` (액션 처리)
- `at_07_player_edit_modal.dart` 의 핸들러 (시각만 OK)

## 권장 조치 (TDD-friendly)

### Step 1 — Visual baseline 캡처
```bash
cd team4-cc/src
flutter run -d chrome --dart-define=USE_MOCK=true
# 정본 ZIP 추출 후 동등 데이터로 비교
# Playwright golden file 생성 (정본 vs Flutter side-by-side)
```

### Step 2 — Row 단위 차이 표 작성
정본의 9 row (Status strip + Seat# + PosBlock + Country + Name + HoleCards + Stack + Bet + LastAction) 각각에 대해 Flutter 의 대응 시각 요소 spot-check.

### Step 3 — 차이 항목별 시각 PR
각 row 차이는 별도 commit. 다음 우선순위:
1. **1×10 horizontal grid** — 가장 중요한 layout
2. **PosBlock 3 stacked rows** — D/SB/BB/STRADDLE 운영 핵심
3. **Status strip** (ACTING / WAITING / FOLD / DELETE)
4. **나머지 row 디테일** (mono font, spacing, $ 기호 등)

### Step 4 — 시각 회귀 테스트
- Playwright golden file (SG-renewal-ui-16 와 연계)
- 또는 widget golden test (`flutter test` 의 matchesGoldenFile)

## 수락 기준

- [ ] PlayerGrid 가 1×10 horizontal layout 확인 (5×2 grid 아님)
- [ ] 각 seat_cell 이 9 row (Status strip + 8 content rows) 시각 매핑 확인
- [ ] PosBlock 3 stacked rows + ‹/› arrows 시각 일치
- [ ] FOLD opacity / ACTING glow 정본 동등 (이미 구현)
- [ ] Visual 회귀 테스트 통과 (ΔE < 5)
- [ ] 기능 코드 (provider / service / FSM / handler) 변경 = 0
- [ ] dart analyze 0 errors, flutter test 통과

## 위상

- **Type**: D (drift, 시각 구조)
- **Scope**: frontend design only — provider/service/handler 미수정
- **Branch**: `work/team4/playercolumn-visual-renewal`
- **Estimated diff**: ~200-500 라인 (seat_cell.dart + at_01_main_screen.dart layout)
- **Risk**: 중간 — 핵심 UI 변경. 시각 회귀 테스트 필수
- **Dependency**: SG-renewal-ui-00 (SSOT ref) 선행 권장. 병렬 가능

## 변경 이력

| 날짜 | 변경 | 사유 |
|------|------|------|
| 2026-05-15 | SG ticket 신규 생성 | Renewal Plan Phase 2B + Gap Audit P0-4 |
