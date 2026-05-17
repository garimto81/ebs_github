---
id: SG-renewal-ui-24
title: "Foundation §B.1 게임 수 12/7/3 검증 + 정합 확인"
type: spec_gap_verification
status: OPEN
owner: conductor
created: 2026-05-17
priority: P2
scope: documentation
mirror: none
confluence-sync: none
affects_files:
  - docs/1. Product/Foundation.md (§B.1 22 게임 표)
  - docs/1. Product/Game_Rules/Flop_Games.md
  - docs/1. Product/Game_Rules/Seven_Card_Games.md
related_sg: []
prd_refs:
  - Foundation §B.1 (line 648-652) — "12 / 7 / 3"
pokergfx_refs:
  - archive/.../complete.md line 87 (3 계열 카운트 — doc 자체 모순 6/7)
  - archive/.../complete.md line 802-825 (game enum 22 values)
  - archive/.../complete.md line 2692-2717 (Reflection 검증 enum 카탈로그) ★
parent_plan: ~/.claude/plans/decision-report-v5-ultrathink-rewrite.md
---

# SG-renewal-ui-24 — Foundation §B.1 게임 수 검증

## 공백 서술

PokerGFX 정본 doc 자체 카운트 모순 (line 87 "Draw 6" vs line 2708-2714 표 7행). Reflection API 검증 = **12 flop + 7 draw + 3 stud = 22** (line 2692-2717).

Foundation §B.1 = 이미 "12 / 7 / 3" 정합 (v4.5 시점). 본 SG = **검증 확인 + Game_Rules sub-folder 정합 cascade**.

## 권장 조치

### Step 1 — Foundation §B.1 정합 재확인

이미 "12 / 7 / 3" 인지 확인 (Phase 1 검증 결과 = OK).

### Step 2 — Game_Rules sub-folder cascade

- `Flop_Games.md` 가 12 게임 명시?
- `Seven_Card_Games.md` 가 3 Stud 게임 명시?
- Draw 게임 별도 docs 필요?

## 수락 기준

- [ ] Foundation §B.1 = 12/7/3 정합
- [ ] Game_Rules sub-folder = 정합
- [ ] PokerGFX Reflection 검증 인용 명시

## 위상

- Type: B (doc 자체 검증)
- Scope: documentation
- Branch: `work/conductor/game-count-verify`
- Estimated diff: ~50 줄
- Risk: 매우 낮음
- Dependency: 없음
