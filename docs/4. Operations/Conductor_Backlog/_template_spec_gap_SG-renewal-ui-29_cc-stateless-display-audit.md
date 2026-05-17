---
id: SG-renewal-ui-29
title: "Flutter CC Stateless Display 정합 audit (game logic 흔적 검출)"
type: spec_gap_architecture
status: OPEN
owner: conductor
created: 2026-05-17
priority: P1
scope: architecture
mirror: none
confluence-sync: none
affects_files:
  - team4-cc/src/lib/features/command_center/**/*.dart (전체 audit)
related_sg: [SG-renewal-ui-30]
prd_refs:
  - Foundation Ch.4 Scene 3 (7-Layer L5 Stateless, v5.0)
  - Command_Center.md Ch.6.5 (L5 Frontend Stateless Display, v4.4)
pokergfx_refs:
  - archive/.../complete.md line 113-121 (AT Stateless Input Terminal ★)
parent_plan: ~/.claude/plans/decision-report-v5-ultrathink-rewrite.md
---

# SG-renewal-ui-29 — CC Stateless Display Audit

## 공백 서술

Foundation v5.0 + CC v4.4 = CC = L5 Frontend Stateless Display 명시 (PokerGFX AT 패턴 차용). 본 SG = 현재 Flutter CC 코드의 game logic 흔적 검출 + 정합 확인.

## 권장 조치

### Step 1 — Audit checklist

`team4-cc/src/lib/features/command_center/` 전체 디렉토리 grep:
- 게임 상태 계산 로직 (pot / equity / hand strength 등) → Engine 위임 필요
- 자체 state machine → Engine GameState 응답 따라가기
- biggest_bet 계산 → Engine 제공

### Step 2 — Refactor 권고

발견된 game logic = Engine 으로 이전 또는 Engine response 기반 단순 표시 변환.

### Step 3 — 정적 가드 도입

`tools/check_cc_stateless.py` 신규 — CC 디렉토리 내 금지 패턴 검출 (예: 산술 계산, FSM transition 등).

## 수락 기준

- [ ] CC 코드 내 game logic = 0
- [ ] 모든 state 변경 = Engine GameInfoResponse 따라가기
- [ ] 정적 가드 CI 통합

## 위상

- Type: D (drift — 의도된 architecture vs 현재 구현)
- Scope: architecture
- Branch: `work/team4/stateless-audit`
- Estimated diff: ~variable (audit 결과에 따름)
- Risk: 중간 — 발견된 game logic 양에 따라
- Dependency: SG-30 (WS schema) 선행 권고
