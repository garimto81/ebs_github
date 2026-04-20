---
id: SG-011
title: "Spec Drift: RFID_HAL_Interface §2.1 single-stream vs code 6-stream"
type: spec_gap
sub_type: spec_drift
status: out_of_scope_prototype  # 2026-04-20 재마킹. 프로토타입 범위 밖
owner: team4  # decision_owner (publisher)
conductor_escalation: false
created: 2026-04-20
redefined: 2026-04-20
affects_chapter:
  - docs/2. Development/2.4 Command Center/APIs/RFID_HAL_Interface.md §2.1
  - team4-cc/src/lib/rfid/abstract/i_rfid_reader.dart
protocol: Spec_Gap_Triage §7 (Type D1 / D3)
---

# SG-011 — RFID_HAL_Interface §2.1 single-stream vs code 6-stream

> ## ⚠️ [TBD — 개발팀 인계] 본 drift 는 프로토타입 범위 밖
>
> **본 drift 해소는 실제 개발팀 인계 후 과제**. 제조사 SDK(ST25R3911B / ESP32 펌웨어 등) 와 구체 요구사항(빈도, QoS, 오류 복구, 멀티 리더 조정) 이 확정된 뒤에야 최종 HAL 이 결정된다. 기획서 프로토타입 단계에서는 본 drift 를 강제로 해소하지 않는다.
>
> **프로토타입 상태**: `MockRfidReader` 로 충분. 현재 6-stream 코드 구조는 Mock 구현의 편의이지 HAL 계약 확정본이 아니다. 실제 HAL 인터페이스는 제조사 SDK 에 종속되어 바뀔 가능성이 높다.
>
> **인계 시점 결정 owner**: 하드웨어 팀 + team4 (소비자) 공동. Conductor 는 인계 체크리스트만 유지.

## 공백 서술

`RFID_HAL_Interface.md §2.1` 의 `IRfidReader` 선언은 단일 통합 스트림:

```dart
abstract class IRfidReader {
  Stream<RfidEvent> get events;   // ← 단일 스트림
}
```

실제 `team4-cc/src/lib/rfid/abstract/i_rfid_reader.dart` 는 **6개 type-safe 분리 스트림**:

```dart
abstract class IRfidReader {
  Stream<CardDetectedEvent> get onCardDetected;
  Stream<CardRemovedEvent> get onCardRemoved;
  Stream<DeckRegisteredEvent> get onDeckRegistered;
  Stream<AntennaStatusChangedEvent> get onAntennaStatusChanged;
  Stream<ReaderErrorEvent> get onError;
  Stream<RfidReaderStatus> get onStatusChanged;
  ...
}
```

## 진실 판정 (재정의)

프로토타입 단계에서는 **어느 쪽도 정본으로 확정하지 않는다**. 단일 vs 6분리 는 실제 HAL 구현 결정이 이뤄지기 전까지 설계 자유도 영역. 사용자 재정의에 따르면 (2026-04-20):

> "이 판단은 실제 HW SDK 와 요구사항이 나올 때 개발팀이 최종 확정."

Mock 구현의 6-stream 편의는 "type-safe 소비자 listener" 라는 장점이 있으나, 실제 HAL 이 벤더 SDK 의 callback 구조에 따라 결정되면 다시 바뀔 수 있다.

## 발견 경위

- 2026-04-20 `spec_drift_check.py --rfid` D3 감지 (문서에 stream 이름 없음)
- 초기 판정: "코드가 정본" (v1)
- 재정의(v2, 2026-04-20): 프로토타입 범위 밖, TBD 처리

## 개발팀 인계 체크리스트

실제 개발팀이 HAL 을 확정할 때 확인해야 할 사항:

| 항목 | 결정 필요 |
|------|----------|
| 벤더 SDK 확정 | ST25R3911B + ESP32 펌웨어의 native callback 구조 |
| 스트림 분리 vs 통합 | 6-stream 유지 / 단일 events 스트림 / 하이브리드 |
| 이벤트 타입 | CardDetected/CardRemoved/DeckRegistered/AntennaStatusChanged/ReaderError/StatusChanged 각각의 payload 재확정 |
| 에러 복구 정책 | 펌웨어 reconnect/timeout 동작에 따른 소비자 측 복구 계약 |
| 다중 리더 동기화 | 테이블당 안테나 개수 × N 테이블 시 이벤트 정렬 규칙 |
| Backpressure | 초당 수십 카드 이벤트가 발생할 때 소비자 측 drop/queue 정책 |
| Mock ↔ Real 호환 | 테스트용 MockRfidReader 와 RealRfidReader 가 공유할 인터페이스 수준 |

위 결정이 완료되면 본 SG 를 새 SG (예: SG-011-v2) 로 승격하여 해소.

## 프로토타입 단계 조치 (유지)

- `RFID_HAL_Interface.md §2.1` 은 현재 서술 유지 (single-stream 표기). 상단 경고로 "실제 HAL 은 개발팀 확정" 명시.
- `MockRfidReader` 6-stream 구현은 **테스트 편의로 유지**. Real HAL 강제 정합 요구 안 함.
- `tools/spec_drift_check.py --rfid` 의 D3 결과는 프로토타입 단계에서 **무시**. 본 SG 가 OUT_OF_SCOPE 인 동안은 Registry §4.4 에서 pending 으로 표기하지 않는다.

## 수락 기준 (원래 안은 개발팀 인계 시점으로 연기)

**프로토타입 단계에서는 아래만 충족하면 본 SG closed 로 간주:**

- [x] 본 문서 상단에 "TBD 개발팀 인계" 경고 박스 부착
- [x] `Spec_Gap_Registry.md §4.4` 에서 상태 `OUT_OF_SCOPE` 로 갱신
- [x] `Roadmap.md` RFID 관련 행에 본 SG status 반영
- [ ] (개발팀 인계 시점) 본 SG 를 SG-011-v2 로 분기하여 재착수

## Changelog

| 날짜 | 변경 | 비고 |
|------|------|------|
| 2026-04-20 | v1.0 — "코드가 정본" | 6-stream 코드를 문서에 반영하는 플랜 |
| 2026-04-20 | **v2.0 — OUT_OF_SCOPE 재마킹** | 프로토타입 범위 밖. 실제 HAL 은 개발팀 + 제조사 SDK 확정 후 결정. 인계 체크리스트만 유지 |
