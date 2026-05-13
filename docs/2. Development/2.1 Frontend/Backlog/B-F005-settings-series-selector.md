---
id: B-F005
title: "Settings 화면에 Series selector UI 도입"
backlog-status: open
priority: medium
source: docs/2. Development/2.1 Frontend/Backlog.md
mirror: none
---

# B-F005 — Settings BlindStructure/PayoutStructure 탭에 Series 선택 UI

## 배경

B-084에서 BlindStructure/PayoutStructure Repository를 series-nested로 전환하면서 화면 측에서는 `seriesId=1` 하드코딩으로 처리. 실제 운영에서는 복수 Series(2026 WSOP, 2026 WSOPC Seoul 등) 간 전환 UI 필요.

## 요구사항

- `blind_structure_screen.dart` 상단에 Series 드롭다운
- `prize_structure_screen.dart` 동일 패턴
- 선택한 seriesId를 provider family 인자로 전달
- 선택 상태는 Settings 탭 간 공유 (혹은 Lobby의 선택과 동기화)

## 구현 위치

- `lib/features/settings/providers/` — selectedSeriesIdProvider (StateNotifier or simple Provider)
- `lib/features/settings/screens/blind_structure_screen.dart` + `prize_structure_screen.dart`
- Lobby Dashboard의 Series 드롭다운과 provider 공유 고려

## 임시 처리 중인 곳

```dart
static const int _defaultSeriesId = 1;   // ← 이 상수를 provider 기반으로 교체
```

## DoD

- Settings 진입 시 첫 Series 자동 선택
- Series 변경 시 Blind/Payout Structure 목록 자동 갱신
- Lobby Series 선택과 독립 또는 동기 (UX 검토 필요)
