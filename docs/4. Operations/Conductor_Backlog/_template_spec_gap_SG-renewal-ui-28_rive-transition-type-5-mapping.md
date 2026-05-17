---
id: SG-renewal-ui-28
title: "Rive transition_type 5종 매핑 (fade/slide/pop/expand/global)"
type: spec_gap_reference
status: OPEN
owner: conductor
created: 2026-05-17
priority: P2
scope: reference_design
mirror: none
confluence-sync: none
affects_files:
  - docs/1. Product/RIVE_Standards.md (Ch.26.5)
  - team4-cc/src/lib/features/overlay/rive_transitions/*.riv (Rive asset)
related_sg: [SG-renewal-ui-26]
prd_refs:
  - RIVE_Standards.md Ch.26.5 (transition_type 5종 매핑, v0.9 신규)
pokergfx_refs:
  - archive/.../complete.md line 2231-2235 (trans_in / trans_out 4 fields)
  - archive/.../complete.md line 2812 (skin_transition_type enum 5종)
parent_plan: ~/.claude/plans/decision-report-v5-ultrathink-rewrite.md
---

# SG-renewal-ui-28 — Rive transition_type 매핑

## 공백 서술

PokerGFX `skin_transition_type` enum 5종 (global/fade/slide/pop/expand) ↔ Rive Timeline 패턴 매핑. RIVE_Standards Ch.26.5 PRD 명세화됨 (v0.9). 본 SG = Rive 자산 작성.

## 권장 조치

5 Rive 자산 작성:
- `transition_fade.riv` (Opacity Timeline)
- `transition_slide.riv` (Translation Timeline)
- `transition_pop.riv` (Scale 탄성)
- `transition_expand.riv` (Scale + Opacity)
- `transition_global.riv` (Project default 적용 helper)

## 수락 기준

- [ ] 5 Rive 자산 정상 렌더링
- [ ] trans_in_time / trans_out_time (ms) 매개변수화
- [ ] 외부 디자이너 인계 시 매핑표 정합

## 위상

- Type: B
- Scope: design + reference
- Branch: `work/designer/rive-transitions`
- Estimated diff: 5 Rive 자산 (binary)
- Risk: 매우 낮음
- Dependency: 외부 디자이너 작업
