---
id: SG-renewal-ui-00
title: "Visual SSOT reference 경로 갱신: docs/mockups/EBS Command Center/ → docs/1. Product/Prototype/originals/EBS Command Center (2).zip"
type: spec_gap_reference_update
status: OPEN
owner: conductor
created: 2026-05-15
priority: P0
scope: frontend_design_only
affects_files:
  - team4-cc/src/lib/foundation/theme/ebs_oklch.dart (line 3 comment)
  - team4-cc/src/lib/foundation/theme/ebs_typography.dart (line 3 comment)
  - team4-cc/src/lib/features/command_center/widgets/action_panel.dart (line 10-12 comment)
  - team4-cc/src/lib/features/command_center/widgets/seat_cell.dart (line 12 comment — already refers to U3 / OKLCH token)
  - 기타 OKLCH 토큰 참조하는 모든 widget 파일의 "Visual SSOT:" 주석 라인
related_sg:
  - SG-renewal-ui-01 (PlayerColumn 1×10 시각 구조 — 후속)
  - SG-renewal-ui-02 (전 화면 OKLCH 토큰 적용 audit)
  - SG-renewal-ui-18~32 (v5 ultrathink cascade)
protocol: Spec_Gap_Reference_Update
parent_plan: ~/.claude/plans/decision-report-v5-ultrathink-rewrite.md (v5 ultrathink, supersedes 2026-05-15 renewal-plan)
prd_refs:
  - Foundation.md §A.1-A.4 (Lobby 진입 시점 + Rive Manager + Hole Card Visibility)
  - Command_Center.md Ch.17 (verbatim 흡수 880줄 — 시각 SSOT 통합본)
  - RIVE_Standards.md Ch.5.5 (INTEGRATED vs MODULAR Skin)
pokergfx_refs:
  - archive/.../complete.md line 2138-2349 (ConfigurationPreset 99+ fields)
parent_audit_superseded: docs/4. Operations/Reports/2026-05-15-prototype-accurate-original-gap-audit.md (SUPERSEDED)
component_mapping: docs/1. Product/Prototype/component_visual_mapping.md
---

# SG-renewal-ui-00 — Visual SSOT reference 경로 갱신

## 공백 서술

사용자가 2026-05-15 에 두 React 인터랙티브 ZIP 을 **"accurate original" (정확한 원본)** 으로 명시 지정했다. 그러나 현재 Flutter 코드의 여러 widget 이 **deprecated 경로** (`docs/mockups/EBS Command Center/`) 를 Visual SSOT 로 가리키고 있다.

```
+----------------------------+--------------------------------------------------+
| 현재 reference (deprecated) | 정본 (SSOT, 2026-05-15 등록)                      |
+----------------------------+--------------------------------------------------+
| docs/mockups/EBS Command   | docs/1. Product/Prototype/originals/             |
| Center/tokens.css          | EBS Command Center (2).zip → tokens.css          |
| docs/mockups/EBS Command   | docs/1. Product/Prototype/originals/             |
| Center/app.css             | EBS Command Center (2).zip → app.css             |
+----------------------------+--------------------------------------------------+
```

**Type B (기획 공백)**: Flutter 코드 주석의 SSOT reference 가 deprecated. 다음 작업자가 잘못된 경로를 보고 mockup HTML 을 참조할 위험.

## 발견 경위

- **트리거**: Renewal Plan Phase 2 spot-check (2026-05-15)
- **근거**: 
  - `team4-cc/src/lib/foundation/theme/ebs_oklch.dart` line 3 — `// SSOT: docs/mockups/EBS Command Center/tokens.css`
  - `team4-cc/src/lib/foundation/theme/ebs_typography.dart` line 3 — `// SSOT: docs/mockups/EBS Command Center/tokens.css`
  - `team4-cc/src/lib/features/command_center/widgets/action_panel.dart` line 10-12 — `// Visual SSOT: docs/mockups/EBS Command Center/app.css`
- **검증**: `docs/mockups/EBS Command Center/` 경로 자체는 git 추적 안 됨 (deprecated mockup HTML 은 `docs/1. Product/visual/` 와 `docs/1. Product/References/foundation-visual/` 에 위치, 본 cycle Phase 1 에서 deprecated 표식 완료).

## 영향받는 챕터 / 구현

| 영역 | 파일 (예시, 전수 조사 필요) | 변경 |
|------|--------------------------|------|
| team4-cc | `lib/foundation/theme/ebs_oklch.dart` | 주석 1 줄 갱신 |
| team4-cc | `lib/foundation/theme/ebs_typography.dart` | 주석 1 줄 갱신 |
| team4-cc | `lib/features/command_center/widgets/action_panel.dart` | 주석 2-3 줄 갱신 |
| team4-cc | `lib/features/command_center/widgets/seat_cell.dart` | 이미 OKLCH 토큰 사용 — SSOT 주석 정합 확인 |
| team4-cc | 기타 widget 의 `// Visual SSOT:` / `// HTML SSOT:` 주석 라인 | grep + 일괄 갱신 |
| team1-frontend | 동일 패턴 grep + 갱신 | (없을 가능성, 확인 필요) |

## 권장 조치

### Step 1 — grep 전수 조사
```bash
cd C:/claude/ebs
grep -rn "docs/mockups/EBS Command Center" team4-cc/src/lib/ team1-frontend/lib/
grep -rn "docs/mockups/EBS Lobby" team4-cc/src/lib/ team1-frontend/lib/
grep -rn "Visual SSOT:" team4-cc/src/lib/ team1-frontend/lib/
grep -rn "HTML SSOT:" team4-cc/src/lib/ team1-frontend/lib/
```

### Step 2 — 정본 경로로 일괄 치환

| 옛 reference | 새 reference (정본) |
|-------------|--------------------|
| `docs/mockups/EBS Command Center/tokens.css` | `docs/1. Product/Prototype/originals/EBS Command Center (2).zip → tokens.css (after extract)` |
| `docs/mockups/EBS Command Center/app.css` | `docs/1. Product/Prototype/originals/EBS Command Center (2).zip → app.css` |
| `docs/mockups/EBS Command Center/` | `docs/1. Product/Prototype/originals/EBS Command Center (2).zip` |
| `docs/mockups/EBS Lobby/` | `docs/1. Product/Prototype/originals/EBS Lobby (1).zip` |

### Step 3 — Spec 문서 (Overview.md §13) 도 동일 갱신

| 파일 | 변경 |
|------|------|
| `docs/2. Development/2.4 Command Center/Command_Center_UI/Overview.md` §13.1 OKLCH conversion table 의 "SSOT:" 라인 | 정본 ZIP 경로로 갱신 |
| `docs/2. Development/2.1 Frontend/Lobby/Overview.md` 동일 패턴 | 정본 ZIP 경로 |

## 수락 기준

- [ ] team4-cc/src/lib/ 의 모든 `docs/mockups/EBS Command Center` 라인 = 0
- [ ] team1-frontend/lib/ 의 모든 `docs/mockups/EBS Lobby` 라인 = 0
- [ ] 정본 ZIP 경로 reference 가 정확히 명시 (`docs/1. Product/Prototype/originals/...`)
- [ ] 관련 Overview.md / PRD 문서의 SSOT reference 도 동일 갱신
- [ ] dart analyze + flutter test 통과 (시각 변경 없음, 주석만)

## 위상

- **Type**: B (기획 공백 — Visual SSOT 명시화 누락)
- **Scope**: frontend design reference only (시각 변경 0, 기능 변경 0)
- **Branch**: `work/team4/ssot-ref-update` + `work/team1/ssot-ref-update` (병렬 가능)
- **Estimated diff**: ~10-30 라인 (주석만)
- **Risk**: 매우 낮음 (주석 변경만, 컴파일 영향 없음)
- **Dependency**: 없음 — 즉시 진행 가능

## 변경 이력

| 날짜 | 변경 | 사유 |
|------|------|------|
| 2026-05-15 | SG ticket 신규 생성 | Renewal Plan Phase 2 spot-check 결과 |
