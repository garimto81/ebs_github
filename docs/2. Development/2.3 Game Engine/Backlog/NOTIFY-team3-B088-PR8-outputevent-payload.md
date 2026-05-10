---
id: NOTIFY-team3-B088-PR8
title: "B-088 PR-8 — Engine OutputEvent payload 필드 camelCase"
status: OPEN
created: 2026-04-21
from: team1 (B-088 PR-5 선행 알림)
target: team3
priority: P2
mirror: none
---

# NOTIFY → team3: B-088 OutputEvent payload 정렬

team1 이 B-088 PR-5 (Freezed JSON 필드 camelCase 전환) 선행 완료. team3 는 OutputEvent 21종 payload 필드 camelCase 정렬 필요.

## 현재 상태

- team3 OutputEvent sealed class: `team3-engine/ebs_game_engine/lib/core/actions/output_event.dart`
- team4 consumer: `team4-cc/src/lib/features/overlay/services/output_event_buffer.dart`
- 계약 문서: `docs/2. Development/2.3 Game Engine/APIs/Overlay_Output_Events.md`

## 수정 대상

### Engine 내부 (Dart class)
OutputEvent Dart field 이름은 **camelCase** 이미 맞음 (Dart 관행):
```dart
class StateChanged extends OutputEvent {
  final String previousState;  // camelCase ✅
  final String newState;       // camelCase ✅
}
```

하지만 **JSON 직렬화 형식** 이 WS payload 로 전달되거나 API-04 계약에 기록되면 camelCase 로 일치해야 함 (Dart class 필드와 동일).

### 확인 필요
1. OutputEvent `toJson()` 구현이 `@JsonKey(name: 'snake_case')` 로 snake_case 직렬화하는지 확인
2. 만약 snake_case 직렬화면 → camelCase 로 전환
3. `Overlay_Output_Events.md` 문서 payload JSON 예시 camelCase 로 교체

### 수락 기준

- [ ] OutputEvent 21종 toJson() 출력이 camelCase 인지 확인 (또는 정정)
- [ ] `Overlay_Output_Events.md` 문서 JSON 예시 camelCase
- [ ] team4 CC consumer 가 camelCase 기준 파싱 확인 (team4 PR-7 연동)

## 영향 범위 (크지 않음)

- Engine 은 in-process Dart call 이 주 경로 — JSON 은 debug/replay 용도
- PascalCase event type 은 본 작업 scope 외 (`StateChanged`, `ActionProcessed` 등은 이미 PascalCase class 이름, event 디스크리미네이터도 동일)

## 관련

- SSOT: `docs/2. Development/2.5 Shared/Naming_Conventions.md` v2
- Master: `docs/4. Operations/Conductor_Backlog/B-088-naming-convention-camelcase-migration.md`
