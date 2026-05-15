---
title: B-Q14 — Settings 5-level scope UI 구현 (C.1 + SG-026 cascade)
owner: team1 (or conductor Mode A)
tier: internal
status: PENDING
type: backlog
linked-sg: SG-003, SG-017, SG-026
linked-decision: C.1 (SG-003+017) + B-Q5 ㉠ (Mode A) + B-Q7 ㉠ (Production-strict)
last-updated: 2026-04-27
confluence-page-id: 3834118248
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3834118248/Settings
---

## 개요

C.1 결정 (SG-003+017): Settings 5-level scope (Global/Series/Event/Table/User), Override 우선순위 User > Table > Event > Series > Global. **UI 구현** 필요. team2-backend 의 settings_kv router 기반.

## 작업 범위

### A. State Management
- Riverpod-based `SettingsScopeProvider` (이미 존재 가능, team1 자체 검토)
- 5-level resolver (User > Table > Event > Series > Global)
- WebSocket sync (변경 시 다른 클라이언트 broadcast)

### B. UI Panel (6 tabs)
1. Outputs (Global/Event scope)
2. Graphics (Event scope)
3. Display (User scope)
4. Rules (Event scope)
5. Stats (Series scope)
6. Preferences (User scope)
- 각 tab 마다 scope picker (어느 level 에 저장?)

### C. Data Layer
- team2-backend `settings_kv.py` router 연동 (이미 in-memory 4-level resolver 동작 — TODO-T2-011)
- DB session 교체 후 production 진행

### D. Validation
- twoFactorEnabled (User scope, SG-008-b14) — 2FA migration 0006 후 활성화
- fillKeyRouting (NDI 라우팅, SG-008-b15) — Hardware Out Phase 2

## 처리 옵션

| 옵션 | 의미 |
|:----:|------|
| ㉠ | team1 세션 + team2 세션 병렬 진행 (표준 Mode B) |
| ㉡ | Conductor Mode A — Conductor 가 양 팀 코드 직접 처리 |
| ㉢ | team2 backend 만 먼저 (settings_kv DB 교체) → team1 UI 후속 |

## 우선순위

P1 — Phase 0 후반 (~ 2026-11/12) 의 사용자 가시 기능. MVP 운영 필수.

## 참조

- Spec_Gap_Registry SG-003, SG-017, SG-026
- team2-backend `src/routers/settings_kv.py` (in-memory 4-level resolver — TODO-T2-011)
- Settings/Overview.md (5-level scope spec — 2026-04-27 갱신)
- team1-frontend/CLAUDE.md
- B-Q13 (Desktop 라우팅, paired)
