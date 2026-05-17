---
id: SG-renewal-ui-20
title: "CC StatusBar Mixed Game Preview UI (3 모드별 라벨)"
type: spec_gap_visual
status: OPEN
owner: conductor
created: 2026-05-17
priority: P1
scope: visual
mirror: none
confluence-sync: none
affects_files:
  - team4-cc/src/lib/features/command_center/widgets/cc_status_bar.dart
  - team4-cc/src/lib/features/command_center/providers/game_cycle_provider.dart
related_sg: [SG-renewal-ui-19, SG-renewal-ui-23]
prd_refs:
  - Lobby.md 부록 D.4.4 (CC UI Preview ASCII 와이어프레임, v3.1)
  - Command_Center.md (StatusBar 우측 영역)
pokergfx_refs:
  - archive/.../complete.md line 1647-1662 (GameInfoResponse Category 4 게임)
parent_plan: ~/.claude/plans/decision-report-v5-ultrathink-rewrite.md
---

# SG-renewal-ui-20 — StatusBar Mixed Game Preview UI

## 공백 서술

Mixed Game 운영 시 운영자에게 **다음 게임 preview** 를 StatusBar 우측에 표시. 3 모드별 라벨 형식 다름.

```
   [every_hand]   ... Next: PLO
   [every_round]  ... Next: PLO • 4 hands left
   [every_level]  ... L5 NLHE / Next: L6 PLO
```

## 권장 조치

### Step 1 — game_cycle_provider 신규

`game_cycle_provider.dart` — `transition_unit` enum + 다음 게임 계산 로직.

### Step 2 — cc_status_bar.dart 우측 zone 갱신

3 모드 conditional widget — Mixed Game 비활성 시 표시 안 함.

## 수락 기준

- [ ] 3 모드 모두 정확 라벨 표시
- [ ] Single Game (mode=none) 시 라벨 숨김
- [ ] amber 톤 (CC Ch.11.5 design token) 정합
- [ ] 시각 회귀 테스트 통과 (ΔE < 5)

## 위상

- Type: B (PRD 명시 + 구현 부재)
- Scope: visual only
- Branch: `work/team4/statusbar-mixed-preview`
- Estimated diff: ~150-200 줄
- Risk: 낮음 — 신규 widget
- Dependency: SG-19 (Settings) 선행
