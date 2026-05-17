---
id: SG-renewal-ui-21
title: "RUN_IT_TWICE FSM 보강 + CC UI 시각 디자인"
type: spec_gap_visual_functional
status: OPEN
owner: conductor
created: 2026-05-17
priority: P1
scope: visual_functional
mirror: none
confluence-sync: none
affects_files:
  - team4-cc/src/lib/features/command_center/providers/hand_fsm_provider.dart
  - team4-cc/src/lib/features/command_center/widgets/cc_status_bar.dart
  - team4-cc/src/lib/features/command_center/widgets/action_panel.dart
  - team3-engine/lib/game/hand_fsm.dart
related_sg: [SG-renewal-ui-18]
prd_refs:
  - Foundation Ch.6 (All-in Run It Twice 옵션, v5.0 신규)
  - Command_Center.md Ch.6 (10-state FSM, v4.4)
pokergfx_refs:
  - archive/.../complete.md line 905-918 (RUN_IT_TWICE 분기)
  - archive/.../complete.md line 713-715 (run_it_times / run_it_times_remaining / run_it_times_num_board_cards)
parent_plan: ~/.claude/plans/decision-report-v5-ultrathink-rewrite.md
---

# SG-renewal-ui-21 — RUN_IT_TWICE FSM + UI

## 공백 서술

PokerGFX 정본 검증 결과 = RIVER 와 SHOWDOWN 사이에 **RUN_IT_TWICE state** 가 시청자 인기 시나리오 (All-in 시 보드 2회 분배). Command_Center Ch.6 가 10-state 로 갱신되었으나, **Flutter Engine FSM + CC UI 시각 디자인** 부재.

## 권장 조치

### Step 1 — Engine hand_fsm.dart 보강

RIVER → RUN_IT_TWICE → SHOWDOWN 분기 추가. `run_it_times` field 가 1 보다 클 때 활성.

### Step 2 — CC StatusBar 라벨

"RUN IT TWICE" phase 표시 + 추가 보드 카드 슬롯 UI.

### Step 3 — ActionPanel "Run It Twice" 옵션 버튼

All-in 상황 직후 modal 또는 dropdown 으로 운영자 선택.

## 수락 기준

- [ ] All-in 시 운영자가 옵션 선택 가능
- [ ] 추가 보드 5장 정확 분배
- [ ] 별도 팟 정확 계산
- [ ] PRD CC Ch.6 mermaid 와 정합

## 위상

- Type: B (PRD 명시 + 구현 부재)
- Scope: visual + functional (시청자 인기 기능)
- Branch: `work/team3+team4/run-it-twice`
- Estimated diff: ~400-600 줄
- Risk: 중간 — All-in edge case 다수
- Dependency: 없음 (병렬 가능)
