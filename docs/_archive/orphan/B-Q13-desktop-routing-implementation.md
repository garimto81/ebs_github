---
title: B-Q13 — 단일 Desktop 바이너리 라우팅 구현 (SG-022 cascade)
owner: team1 (or conductor Mode A)
tier: internal
status: PENDING
type: backlog
linked-sg: SG-022
linked-decision: SG-022 + B-Q5 ㉠ (Mode A 활성)
last-updated: 2026-04-27
confluence-page-id: 3818816221
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818816221/EBS+B-Q13+Desktop+SG-022+cascade
---

## 개요

SG-022 (단일 Desktop 바이너리, Lobby 포함) 결정 cascade. **Lobby + CC + Overlay 단일 Flutter Desktop 바이너리** 의 내부 라우팅 구현. Foundation §5.0 의 두 런타임 모드 (탭/슬라이딩, 다중창) 지원.

## 작업 범위

### A. 단일 라우팅 (Mode A: 탭/슬라이딩)
- go_router 기반 Lobby ↔ CC ↔ Overlay 내부 라우팅
- 단일 Flutter 프로세스, 단일 main()
- 탭/슬라이딩 UI (Material 3 NavigationRail 또는 비슷)

### B. 다중창 (Mode B: 다중 OS 프로세스)
- Flutter desktop_multi_window 또는 비슷
- Lobby/CC/Overlay 각각 독립 OS 프로세스
- IPC (state sync) — WebSocket + DB SSOT

### C. 모드 선택 UI
- Lobby Settings 의 "런타임 모드" toggle
- 변경 시 앱 재시작 필요 (또는 hot-reload)

## 처리 옵션

| 옵션 | 의미 |
|:----:|------|
| ㉠ | team1 세션 진입 후 자체 처리 (표준 Mode B 멀티세션) |
| ㉡ | Conductor Mode A 활성 — Conductor 가 직접 처리 (B-Q5 ㉠ 권한) |
| ㉢ | 단계 분할 — A 만 먼저 (단일 라우팅), B/C 후속 |

## 우선순위

P0 — Phase 0 (~ 2026-12 MVP 완성) 의 핵심 인프라. 미구현 시 모든 UI 작업 차단.

## 참조

- Spec_Gap_Registry SG-022
- Foundation §5.0 (두 런타임 모드)
- BS_Overview §1 (단일 Desktop 바이너리)
- team1-frontend/CLAUDE.md
- 관련: B-Q3 (team1 Web 빌드 자산 정리, paired)
