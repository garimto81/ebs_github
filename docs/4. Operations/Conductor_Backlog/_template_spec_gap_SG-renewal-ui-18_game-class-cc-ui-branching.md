---
id: SG-renewal-ui-18
title: "Flutter CC 게임 클래스별 UI 분기 (Flop / Draw / Stud)"
type: spec_gap_visual_structure
status: OPEN
owner: conductor
created: 2026-05-17
priority: P0
scope: visual_architecture
mirror: none
confluence-sync: none
affects_files:
  - team4-cc/src/lib/features/command_center/widgets/seat_cell.dart
  - team4-cc/src/lib/features/command_center/screens/at_01_main_screen.dart
  - team4-cc/src/lib/features/command_center/widgets/cc_status_bar.dart
related_sg: [SG-renewal-ui-01, SG-renewal-ui-22]
prd_refs:
  - Foundation §B.1 line 668-672 (22 게임 = 3 클래스)
  - Command_Center.md Ch.6.3 (게임 클래스별 FSM 분기, v4.4 신규)
pokergfx_refs:
  - archive/.../complete.md line 830-836 (game_class enum)
  - archive/.../complete.md line 879-924 (FSM 분기)
  - archive/.../complete.md line 2692-2717 (Reflection enum 카탈로그)
parent_plan: ~/.claude/plans/decision-report-v5-ultrathink-rewrite.md
---

# SG-renewal-ui-18 — 게임 클래스별 CC UI 분기

## 공백 서술

22 게임 = 3 클래스 (Flop 12 / Draw 7 / Stud 3) 의 FSM 분기는 Command_Center.md Ch.6.3 (v4.4 신규) 에 명시되었으나, **Flutter CC 가 게임 클래스에 따라 UI 를 다르게 표시하는 구현** 이 부재.

```
   클래스별 CC UI 차이
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   
   영역                 Flop          Draw          Stud
   ──────────────────  ──────────  ──────────  ──────────
   커뮤니티 카드 슬롯    5장          숨김         숨김
   좌석 카드 슬롯       2~6장        4~5장        3 down + 4 up
   ActionPanel DRAW    비활성       활성         비활성
   Phase 라벨          PRE_FLOP/.. PRE_DRAW/..  THIRD/FOURTH/..
```

**Type B (기획 공백)** + **Type D (drift)**: PRD 명시 + 구현 부재.

## 권장 조치

### Step 1 — game_class 분기 widget 추출

`seat_cell.dart` + `at_01_main_screen.dart` 에서 `game_class` 필드 (GameInfoResponse Category 4) 기반 conditional rendering 추가.

### Step 2 — Draw 클래스 신규 widget

`draw_action_panel.dart` 신규 — DRAW 버튼 + draws_completed counter UI.

### Step 3 — Stud 클래스 신규 widget

`stud_player_card.dart` 신규 — 3 down + 4 up 카드 슬롯 표시.

## 수락 기준

- [ ] `game_class` field 수신 시 CC UI 자동 분기
- [ ] Flop / Draw / Stud 각 클래스의 시각 회귀 테스트 통과
- [ ] PRD §6.3 ASCII 다이어그램과 시각 정합 (ΔE < 5)
- [ ] Flutter 기능 코드 변경 = 0 (NG7 — UI conditional rendering 만)

## 위상

- Type: B + D
- Scope: visual + architecture
- Branch: `work/team4/game-class-ui-branching`
- Estimated diff: ~300-500 줄 (3 widget 신규 + at_01_main_screen 갱신)
- Risk: 중간 — 핵심 UI 변경
- Dependency: SG-22 (Draw FSM spec) 선행 권고
