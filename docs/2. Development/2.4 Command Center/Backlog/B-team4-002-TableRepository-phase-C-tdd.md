---
id: B-team4-002
title: TableRepository Phase C TDD — fetch / subscribe / applyServerEvent
status: PENDING
source: docs/2. Development/2.4 Command Center/Backlog.md
---

# [B-team4-002] TableRepository Phase C TDD

- **등록일**: 2026-04-15
- **관련 기획**: `docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md` (B-team4-002 착수 전 §3.X 로컬 state 전이 맵 완성 필요)
- **블로커**: B-team4-001 과 병행 가능. 단, `WebSocket_Events.md §3.X` 신설 선행 필수.
- **현재 상태**: `src/lib/repositories/table_repository.dart` 는 `TODO Phase C TDD` 스텁
- **수락 기준**:
  - `fetchTable(id)` — `BoApiClient` 로 REST 조회, Freezed `TableState` 반환
  - `subscribeTableStream(id)` — `BoWebSocketClient` 구독, seq replay 처리 포함
  - `applyServerEvent(event)` — §3.X 매핑에 따라 state 전이. 최소 5종 이벤트 (HandStarted, ActionPerformed, StreetAdvanced, HandCompleted, SeatUpdated) 커버
  - 각 메서드 1 scenario + applyServerEvent 이벤트별 5 테스트 = 최소 8 테스트 PASS
- **관련 파일**:
  - 수정: `src/lib/repositories/table_repository.dart`
  - 신규: `src/test/repositories/table_repository_test.dart`
  - 재사용: `src/lib/data/remote/bo_api_client.dart`, `src/lib/data/remote/bo_websocket_client.dart`
