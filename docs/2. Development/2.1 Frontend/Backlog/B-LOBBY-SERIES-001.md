---
id: B-LOBBY-SERIES-001
title: "Series 화면 — 년도/월 그룹 토글 + Hide completed 필터"
status: IN_PROGRESS  # 코어 구현 완료 (2026-05-04, in-memory). 영속 후속 task 분리.
priority: P2
source: docs/4. Operations/Lobby_Modification_Plan_2026-05-04.md §F5
implementation:
  date: 2026-05-04
  author: Conductor (Mode A 자율)
  files:
    - team1-frontend/lib/features/lobby/screens/series_screen.dart (modified)
    - team1-frontend/test/features/lobby/series_screen_grouping_test.dart (new, 4/4 PASS)
  flutter_analyze: PASS (3.1s)
  flutter_test: 4/4 PASS
  scope: in-memory state only (영속 보류 — shared_preferences 패키지 미설치)
related:
  - docs/2. Development/2.1 Frontend/Lobby/UI.md §"그룹핑 — 월별 (default) vs 년도별 (design SSOT 신규)"
  - docs/2. Development/2.1 Frontend/Lobby/References/EBS_Lobby_Design/screens.jsx (lines 18-50)
  - team1-frontend/lib/features/lobby/screens/series_screen.dart
---

# B-LOBBY-SERIES-001 — Series 그룹 토글 + Hide completed

## 배경

design SSOT (`screens.jsx:18-50`) 는 Series 카드를 **년도별 그룹핑** + **Hide completed** 토글 + Bookmark/Filter 버튼으로 표시. 현재 Flutter `series_screen.dart` 는 단일 grid (그룹핑 없음으로 추정 — 검증 필요). UI.md 의 기존 spec 은 "March / April" 월별 그룹핑 (WSOP LIVE 정렬). UI.md 보강 (2026-05-04 §F5) 으로 두 모드 통합.

## 수락 기준

- [x] `series_screen.dart` toolbar 우측에 `SegmentedButton(segments: [Month, Year])` 추가 (✅ 2026-05-04)
- [x] toolbar 좌측에 `Checkbox(Hide completed)` 추가 (design SSOT screens.jsx:42 와 동일) (✅ 기존 구현 유지)
- [ ] 그룹 모드 = `localStorage` 영속 (또는 SharedPreferences) — **후속 task: B-LOBBY-SERIES-002 (영속화)** 로 분리
- [x] 월별 그룹: "March 2026" / "April 2026", 시작일 desc (✅ DateFormat.MMMM)
- [x] 년도별 그룹: "2026" / "2025", year desc + 그룹 내부 시작일 desc (✅)
- [x] 각 그룹 밴드에 `{N} series` 카운트 표시 (design SSOT 와 동일) (✅ `_GroupBandHeader`)
- [x] Hide completed = `series.isCompleted == true` 카드 필터아웃 (✅ 기존 구현 유지)
- [x] 위젯 테스트 (2 모드 × completed 토글 = 4 상태) (✅ 4/4 PASS)

## 후속 task (영속화)

영속화 (group mode + Hide completed 토글) 는 본 cascade 에서 분리:
- 의존 패키지 결정: `shared_preferences` (cross-platform 안전) vs `dart:html localStorage` (Web only) vs `flutter_secure_storage`
- `pubspec.yaml` 추가 + `flutter pub get` 후 `_groupMode` / `_hideCompleted` initState 에서 load + onChange 시 save
- 별도 PR / Backlog (B-LOBBY-SERIES-002 신규 등재 권고)

## 우선순위 / 추정

- P2 (UX 개선, blocking 없음)
- 추정: ~~2~4h~~ → 실제 2026-05-04 코어 구현 1.5h 소요 (Conductor Mode A 자율)
