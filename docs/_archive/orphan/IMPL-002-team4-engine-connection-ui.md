---
id: IMPL-002
title: "구현: team4 Engine Connection UI — router guard + manual reconnect"
type: implementation
status: PENDING
owner: team4
created: 2026-04-20
spec_ready: true
blocking_spec_gaps: []
implements_chapters:
  - docs/4. Operations/Conductor_Backlog/SG-002-engine-dependency-contract.md
  - docs/1. Product/Foundation.md §Ch.7
related_code:
  - team4-cc/src/lib/features/command_center/providers/engine_connection_provider.dart
---

# IMPL-002 — team4 Engine Connection UI

## 배경

SG-002 에서 engine 의존 계약 (ENGINE_URL + 3-stage graceful + fallback) 이 확정되었고, Conductor 세션이 `engine_connection_provider.dart` 에 state machine + health check + stub bridge 까지 구현했다. 남은 2개 TODO 마커는 **UI/라우팅 영역** 이므로 team4 세션이 실제 구현해야 한다.

## 구현 대상

### TODO-T4-006 — AppRouter redirect guards

`engineConnectionProvider.stage` 상태에 따라 go_router redirect:

| Stage | 허용 라우트 | 차단/리다이렉트 |
|-------|------------|-----------------|
| `connecting` | splash screen 전용 | 다른 모든 경로 → `/splash` |
| `degraded` | 전체 UI + Demo Mode 배너 | — (배너만 표시) |
| `offline` | 전체 UI + 고정 배너 | — (배너만 표시) |
| `online` | 전체 UI | — |

구현 위치 제안: `src/lib/foundation/router/app_router.dart` 의 redirect 함수.

### TODO-T4-008 — 수동 재연결 UI

Offline stage 일 때 상단 고정 배너에 "재연결" 버튼. 클릭 시 `engineConnectionController.manualReconnect()` 호출.

구현 위치 제안:
- 배너 위젯: `src/lib/features/command_center/widgets/engine_connection_banner.dart` (신규)
- CommandCenter scaffold 상단에 mount

## 수락 기준

- [ ] `connecting` stage 에서 모든 route 가 splash 로 redirect
- [ ] `degraded` / `offline` stage 에서 상단 배너 표시 (문구 구분)
- [ ] `offline` 배너에 "재연결" 버튼 존재 + `manualReconnect()` 호출
- [ ] 배너 dismissible 아님 (Offline 동안 계속 표시)
- [ ] `online` 으로 복귀 시 배너 자동 숨김

## 관련 테스트

- widget test: 각 stage 별 UI 상태
- integration: engine 미기동 → splash → degraded(배너) → offline(재연결 버튼) 전이

## 구현 메모

현재 `engine_connection_provider.dart` 에는 `reset()` / `setStage()` test-only API 가 있어 widget test 에서 stage 강제 전환 가능.
