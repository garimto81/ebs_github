---
id: SG-renewal-ui-27
title: "Ticker 시스템 PRD spec 구현 (자막/통계 ticker)"
type: spec_gap_visual_functional
status: OPEN
owner: conductor
created: 2026-05-17
priority: P2
scope: visual_functional
mirror: none
confluence-sync: none
affects_files:
  - team4-cc/src/lib/features/overlay/widgets/ticker_widget.dart
  - team4-cc/src/lib/features/overlay/providers/ticker_provider.dart
  - team1-frontend/lib/features/settings/screens/graphic_settings_screen.dart (ticker 토글)
related_sg: [SG-renewal-ui-25, SG-renewal-ui-26]
prd_refs:
  - RIVE_Standards.md Ch.23 (Ticker 시스템 PRD 명세, v0.9 신규)
pokergfx_refs:
  - archive/.../complete.md line 2245-2252 (auto_stat_* 11 fields)
  - archive/.../complete.md line 2573 (ticker_edit / ticker_stats_edit WinForms)
parent_plan: ~/.claude/plans/decision-report-v5-ultrathink-rewrite.md
---

# SG-renewal-ui-27 — Ticker 시스템 구현

## 공백 서술

PokerGFX 정본의 Ticker 시스템 (auto_stat_* 11 fields + ticker_* widgets) 이 EBS RIVE_Standards Ch.23 에 PRD 명세화됨 (v0.9 신규). 본 SG = 구현.

## 권장 조치

### Step 1 — ticker_widget.dart 신규

화면 하단 횡스크롤 Ticker. Brand 메시지 + 통계 5종 순환.

### Step 2 — ticker_provider.dart

데이터 소스 매핑:
- VPIP/PFR/AGR/Wtsd/CumWin Ticker (EBS DB)
- Brand Ticker (Brand Pack)
- ITM / FT 카운트 (Engine)

### Step 3 — Settings 토글

Lobby Settings → Graphic 탭 → Ticker 활성/비활성 + 스크롤 속도.

## 수락 기준

- [ ] Ticker = 시청자 노출 (PGM 채널)
- [ ] Operator Marks (Ch.22) 와 명확히 분리
- [ ] 5 통계 (SG-25) 정합

## 위상

- Type: B
- Scope: visual + functional
- Branch: `work/team4+team1/ticker-system`
- Estimated diff: ~300-500 줄
- Risk: 낮음
- Dependency: SG-25 (Wtsd/CumWin) 선행
