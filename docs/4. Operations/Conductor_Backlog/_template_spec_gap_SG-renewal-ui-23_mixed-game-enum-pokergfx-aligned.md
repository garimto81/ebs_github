---
id: SG-renewal-ui-23
title: "Mixed Game enum 명명 PokerGFX-aligned (every_hand/every_round/new_level)"
type: spec_gap_naming
status: OPEN
owner: conductor
created: 2026-05-17
priority: P2
scope: contract
mirror: none
confluence-sync: none
affects_files:
  - team1-frontend/lib/data/models/mixed_game_settings.dart
  - team2-backend/app/schemas/mixed_game.py
  - team3-engine/lib/game/mixed_game_cycle.dart
  - docs/2. Development/2.5 Shared/Naming_Conventions.md (cross-ref 추가)
related_sg: [SG-renewal-ui-19]
prd_refs:
  - Foundation §B.1 footnote (4 primitives, v5.0)
  - Lobby.md 부록 D.4.2 (transition unit 의미, v3.1)
pokergfx_refs:
  - archive/.../complete.md line 2872 (auto_blinds_type enum)
parent_plan: ~/.claude/plans/decision-report-v5-ultrathink-rewrite.md
---

# SG-renewal-ui-23 — Mixed Game enum PokerGFX-aligned 명명

## 공백 서술

EBS Mixed Game cycle enum = PokerGFX `auto_blinds_type` (every_hand=1, new_level=2, with_strip=3) 와 명명 패턴 일치.

EBS 채택 명명: `every_hand` / `every_round` / `new_level`

## 권장 조치

3 컴포넌트 (Flutter / Backend / Engine) 의 enum 통일 + Naming_Conventions.md cross-ref 추가.

## 수락 기준

- [ ] 3 컴포넌트 enum 명명 일치
- [ ] PokerGFX 패턴 cross-ref 명시 (PRD Foundation footnote)

## 위상

- Type: B (PRD 명시 + 구현 명명 결정)
- Scope: contract
- Branch: `work/team1+team2+team3/mixed-game-enum`
- Estimated diff: ~50-100 줄
- Risk: 매우 낮음
- Dependency: SG-19 (Settings) 선행
