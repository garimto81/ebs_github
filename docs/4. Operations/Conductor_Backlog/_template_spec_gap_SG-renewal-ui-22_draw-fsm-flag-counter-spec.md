---
id: SG-renewal-ui-22
title: "Draw FSM Flag/Counter Spec (state 가 아닌 field-based 분기)"
type: spec_gap_functional
status: OPEN
owner: conductor
created: 2026-05-17
priority: P1
scope: functional
mirror: none
confluence-sync: none
affects_files:
  - team3-engine/lib/game/draw_cycle.dart
  - team4-cc/src/lib/features/command_center/widgets/seat_cell.dart
related_sg: [SG-renewal-ui-18]
prd_refs:
  - Command_Center.md Ch.6.3 (Draw flag/counter 모델, v4.4)
pokergfx_refs:
  - archive/.../complete.md line 716-720 (stud_draw_in_progress / draws_completed / drawing_player fields)
  - archive/.../complete.md line 922 (Draw 분기 의사코드)
parent_plan: ~/.claude/plans/decision-report-v5-ultrathink-rewrite.md
---

# SG-renewal-ui-22 — Draw FSM Flag/Counter Spec

## 공백 서술

PokerGFX 정본 검증: Draw FSM 은 별도 state enum 이 아닌 **3 field 분기**:
- `stud_draw_in_progress: bool`
- `draws_completed: int`
- `drawing_player: int`

Triple Draw 게임 (2-7/A-5/Badugi/Badeucy/Badacey) = max_draws=3 반복.

## 권장 조치

### Step 1 — draw_cycle.dart 신규

3 field 기반 카드 교환 cycle 로직 — state enum 신설 X.

### Step 2 — seat_cell.dart 갱신

`stud_draw_in_progress=true` 시 카드 교환 슬롯 UI.

## 수락 기준

- [ ] 7 Draw 게임 모두 정확 동작 (1 draw / 3 draws 분기)
- [ ] CC UI 가 drawing_player 좌석 강조
- [ ] PRD CC Ch.6.3 와 정합

## 위상

- Type: B + D
- Scope: functional
- Branch: `work/team3/draw-cycle`
- Estimated diff: ~250-400 줄
- Risk: 중간
- Dependency: SG-18 (game class branching) 선행
