---
id: SG-renewal-ui-25
title: "Lobby Players 화면 통계 5종 (Wtsd / CumWin 추가)"
type: spec_gap_data_visual
status: OPEN
owner: conductor
created: 2026-05-17
priority: P2
scope: data_visual
mirror: none
confluence-sync: none
affects_files:
  - team1-frontend/lib/features/lobby/screens/lobby_players_screen.dart
  - team1-frontend/lib/data/models/player_stats.dart
  - team2-backend/app/api/v1/players.py
  - team3-engine/lib/stats/player_stats_tracker.dart
related_sg: [SG-renewal-ui-27]
prd_refs:
  - Lobby.md Ch.7 통계 표 (VPIP / PFR / AGR / Wtsd / CumWin, v3.1)
pokergfx_refs:
  - archive/.../complete.md line 1663-1684 (PlayerInfoResponse 20 fields, Wtsd + CumWin 포함)
parent_plan: ~/.claude/plans/decision-report-v5-ultrathink-rewrite.md
---

# SG-renewal-ui-25 — Lobby Wtsd/CumWin 통계 추가

## 공백 서술

PokerGFX 정본 PlayerInfoResponse = **5 통계** (VPIP/PFR/AGR/Wtsd/CumWin). EBS Lobby Ch.7 가 3종만 → v3.1 에서 5종 추가됨. 본 SG = Flutter + Backend + Engine 구현 cascade.

## 권장 조치

### Step 1 — Engine player_stats_tracker.dart

매 핸드 종료 시 Wtsd / CumWin 자동 갱신 로직.

### Step 2 — Backend API

`/api/v1/players/{id}/stats` 응답에 Wtsd / CumWin 필드 추가.

### Step 3 — Flutter UI

`lobby_players_screen.dart` 의 통계 컬럼 갱신 (3 → 5).

## 수락 기준

- [ ] Wtsd = 쇼다운 진행률 정확 계산
- [ ] CumWin = 누적 수익 정확 계산
- [ ] PRD Lobby Ch.7 통계 표와 정합
- [ ] Ticker 시스템 (SG-27) 에 노출 가능

## 위상

- Type: B (PRD 명시 + 데이터 모델 cascade)
- Scope: data + visual
- Branch: `work/team1+team2+team3/wtsd-cumwin-stats`
- Estimated diff: ~200-300 줄
- Risk: 낮음
- Dependency: 없음
