---
id: SG-renewal-ui-19
title: "Lobby Settings Mixed Game Transition Unit (every_hand/every_round/new_level)"
type: spec_gap_functional
status: OPEN
owner: conductor
created: 2026-05-17
priority: P1
scope: functional_visual
mirror: none
confluence-sync: none
affects_files:
  - team1-frontend/lib/features/settings/screens/rules_settings_screen.dart
  - team2-backend/app/api/v1/settings.py
  - team3-engine/lib/game/mixed_game_cycle.dart
related_sg: [SG-renewal-ui-20, SG-renewal-ui-23]
prd_refs:
  - Foundation §B.1 footnote (Mixed Game 4 primitives composition, v5.0)
  - Lobby.md 부록 D.4 (Mixed Game Settings, v3.1 신규)
pokergfx_refs:
  - archive/.../complete.md line 2872 (auto_blinds_type enum)
  - archive/.../complete.md line 1596 (SendGameVariant command)
  - archive/.../complete.md line 1598 (GAME_VARIANT_LIST command)
  - archive/.../complete.md line 686 (pl_dealer field — round detection)
parent_plan: ~/.claude/plans/decision-report-v5-ultrathink-rewrite.md
---

# SG-renewal-ui-19 — Mixed Game Transition Unit Settings

## 공백 서술

사용자 결정 (2026-05-17): Mixed Game 전환 단위 = round / level / hand 3 옵션 모두 지원. Lobby Settings 부록 D.4 (v3.1) 에 명세는 추가되었으나, **Flutter Lobby UI + Backend API + Engine cycle 메커니즘** 부재.

## 권장 조치

### Step 1 — Lobby Settings UI

`team1-frontend/lib/features/settings/screens/rules_settings_screen.dart` 의 Rules 탭에 신규 sub-section:
- `mixed_game_mode` dropdown (none/HORSE/8_game/custom)
- `mixed_game_variants` multi-select (game enum)
- `mixed_game_transition` radio (every_hand/every_round/new_level)

### Step 2 — Backend API

`team2-backend/app/api/v1/settings.py` 에 `mixed_game_settings` 신규 endpoint (CRUD).

### Step 3 — Engine cycle

`team3-engine/lib/game/mixed_game_cycle.dart` 신규 — 4 primitives composition:
- HAND_COMPLETE event → `transition_unit` 검사 → SendGameVariant trigger

## 수락 기준

- [ ] 3 옵션 모두 운영 시 게임 변경 정확 (HORSE 5종, 8-Game 8종)
- [ ] every_round = pl_dealer rotation 검출 정확
- [ ] new_level = blind_level increment 검출 정확
- [ ] PRD Lobby 부록 D.4 와 UI 정합
- [ ] LOCK / CONFIRM / FREE 분류 적용 (mode = LOCK, transition = CONFIRM)

## 위상

- Type: B (PRD 명시 + 구현 부재)
- Scope: functional + visual
- Branch: `work/team1+team2+team3/mixed-game-cycle`
- Estimated diff: ~400-600 줄 (3 컴포넌트 분산)
- Risk: 높음 — 핵심 운영 기능
- Dependency: SG-20 (StatusBar preview), SG-23 (enum 명명) 선행 권고
