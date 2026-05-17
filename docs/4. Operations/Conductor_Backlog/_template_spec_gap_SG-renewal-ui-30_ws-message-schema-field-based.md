---
id: SG-renewal-ui-30
title: "WS message schema 구현 (Field-based batch GameInfoResponse 패턴)"
type: spec_gap_contract
status: OPEN
owner: conductor
created: 2026-05-17
priority: P1
scope: contract
mirror: none
confluence-sync: none
affects_files:
  - team2-backend/app/ws/game_state_broadcaster.py
  - team3-engine/lib/protocol/game_info_response.dart
  - team4-cc/src/lib/data/models/game_info_response.dart
  - team1-frontend/lib/data/models/game_info_response.dart
related_sg: [SG-renewal-ui-29]
prd_refs:
  - Foundation §B.3 (Wire format Field-based batch, v5.0)
  - Command_Center.md Ch.6.4 (L4 Wire Protocol, v4.4)
  - docs/2. Development/2.2 Backend/APIs/Game_State_WS_Schema.md (v1.0.0 신규)
pokergfx_refs:
  - archive/.../complete.md line 1647-1684 (GameInfoResponse 75+ + PlayerInfoResponse 20 fields)
parent_plan: ~/.claude/plans/decision-report-v5-ultrathink-rewrite.md
---

# SG-renewal-ui-30 — Field-based Batch WS Schema 구현

## 공백 서술

신규 doc `Game_State_WS_Schema.md` v1.0.0 = Field-based batch 75+ fields 9 카테고리 명시. 본 SG = 4 컴포넌트 (Engine / Backend / CC / Lobby) freezed entity + WS broadcaster 구현.

## 권장 조치

### Step 1 — Engine game_info_response.dart

GameInfoResponse 75+ fields freezed entity (Dart).

### Step 2 — Backend game_state_broadcaster.py

WS push 시 envelope (event/timestamp/table_id/hand_number/changed_categories/data).

### Step 3 — CC + Lobby freezed entity

같은 schema 의 Dart 모델 (자동 생성 from JSON Schema).

### Step 4 — Delta sync 권고

`changed_fields` array 로 대역폭 최적화 (PokerGFX line 2531 패턴).

## 수락 기준

- [ ] 75+ fields 모두 정의
- [ ] 9 카테고리 분류 정합
- [ ] CC / Lobby / Overlay 모두 수신 + UI 갱신
- [ ] Backward compatibility (기존 REST + 새 WS 양립)

## 위상

- Type: B (PRD 명시 + 구현 부재)
- Scope: contract + functional
- Branch: `work/team2+team3+team4+team1/ws-game-state`
- Estimated diff: ~600-800 줄 (4 컴포넌트 분산)
- Risk: 높음 — 핵심 통신 layer
- Dependency: 없음 (Engine 우선 구현 후 cascade)
