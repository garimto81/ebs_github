---
id: B-team4-002
title: TableRepository Phase C TDD — fetch / subscribe / applyServerEvent
status: DONE
source: docs/2. Development/2.4 Command Center/Backlog.md
---

# [B-team4-002] TableRepository Phase C TDD

- **등록일**: 2026-04-15
- **완료일**: 2026-04-15 (abstraction 불필요로 클로즈)

## 결론

`TableRepository` 라는 별도 저장소 레이어는 만들지 않는다. 의도된 책임이 이미 아래 세 계층에 분산되어 있다.

| 책임 | 실제 위치 |
|------|----------|
| REST fetch/mutate | `src/lib/data/remote/bo_api_client.dart` (Dio + Idempotency-Key) |
| WebSocket subscribe + seq replay | `src/lib/data/remote/bo_websocket_client.dart` |
| TableState 로컬 보관 + 이벤트 반영 | `src/lib/features/command_center/providers/{table_state,seat,hand_fsm,action_button}_provider.dart` |

Riverpod provider 들이 이벤트를 직접 소비하므로 repository 어댑터는 YAGNI 영역이다. `src/lib/repositories/table_repository.dart` (8줄, TODO 스텁) 는 참조자 0개 → 삭제.

## 부수 정리

- `src/lib/repositories/table_repository.dart` 삭제.
- `docs/2. Development/2.2 Backend/APIs/WebSocket_Events.md §3.X` (이벤트 → 로컬 state 전이 맵) 는 여전히 필요 — Riverpod provider 들이 "이 이벤트가 오면 무엇을 바꾸는가" 를 위 문서에서 읽어야 하기 때문. 별도 백로그(`B-team4-003`) 로 관리.
