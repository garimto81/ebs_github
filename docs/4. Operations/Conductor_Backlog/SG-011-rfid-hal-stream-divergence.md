---
id: SG-011
title: "Spec Drift: RFID_HAL_Interface §2.1 single-stream vs code 6-stream"
type: spec_gap
sub_type: spec_drift
status: PENDING
owner: team4  # decision_owner (publisher)
conductor_escalation: false
created: 2026-04-20
affects_chapter:
  - docs/2. Development/2.4 Command Center/APIs/RFID_HAL_Interface.md §2.1
  - team4-cc/src/lib/rfid/abstract/i_rfid_reader.dart
protocol: Spec_Gap_Triage §7 (Type D1 / D3)
---

# SG-011 — RFID_HAL_Interface §2.1 single-stream vs code 6-stream

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

## 진실 판정

**코드가 정본**. 구현이 type-safe 방식으로 분리되었고, 이는 소비자 측에서 이벤트 타입별 listener 를 편하게 붙일 수 있는 의도적 설계이다.

## 발견 경위

- 2026-04-20 `spec_drift_check.py --rfid` D3 감지 (문서에 stream 이름 없음)
- 수동 확인 시 사실은 설계 divergence — 단일 vs 분리

## 조치

이번 커밋에서는 §2.1 상단에 drift 경고 note 만 추가. 실제 문서 정정 PR 은 team4 세션에서:

1. §2.1 `Stream<RfidEvent> get events` 를 6개 분리 스트림으로 교체
2. §3 RfidEvent Sealed Class Hierarchy 는 각 스트림의 payload 타입 정의로 전환
3. Real HAL / Mock HAL 구현 (§5, §6) 도 6-stream 기준으로 교정

## 수락 기준

- [ ] RFID_HAL_Interface.md §2.1 가 실제 Dart 코드와 1:1 일치
- [ ] `python tools/spec_drift_check.py --rfid` D3 = 0
- [ ] 기존 `Stream<RfidEvent> get events` 언급 제거 또는 "legacy alias" 명시
