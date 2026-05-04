---
id: B-LOBBY-SERIES-002
title: "Series 화면 — 그룹 모드 / Hide completed 토글 영속화"
status: PENDING
priority: P3
source: B-LOBBY-SERIES-001 §"후속 task (영속화)"
related:
  - team1-frontend/lib/features/lobby/screens/series_screen.dart
  - team1-frontend/pubspec.yaml
---

# B-LOBBY-SERIES-002 — Series 화면 토글 상태 영속화

## 배경

B-LOBBY-SERIES-001 (2026-05-04 Conductor Mode A 자율 구현) 가 Month/Year 그룹 토글 + Hide completed 필터를 추가했으나, 토글 상태는 **in-memory only** (앱 재실행 시 초기화). 이유: Conductor 자율 사이클은 pubspec.yaml 패키지 추가 + `flutter pub get` 환경 의존을 회피.

본 task = 영속화 후속.

## 패키지 결정 (수락 기준 #1)

| 옵션 | 장점 | 단점 |
|------|------|------|
| `shared_preferences` | cross-platform (Web + Desktop), Flutter 공식 | 추가 패키지 1개 |
| `dart:html localStorage` | 패키지 추가 불필요 | Web only — Desktop 빌드 시 conditional import 필요 |
| `flutter_secure_storage` | 이미 다른 곳에서 사용? | 본 use case (단순 UI 토글) 에 over-engineered (encryption 불필요) |

> 권고: **`shared_preferences`** — Lobby 가 정규 Web 배포 + 개발자 디버깅 Desktop 양쪽 지원, EBS 의 다른 UI preference (예: 향후 Dark mode, Density) 도 동일 패키지로 통일.

## 수락 기준

- [ ] `pubspec.yaml` 에 `shared_preferences: ^2.x` 추가 + `flutter pub get`
- [ ] `series_screen.dart` State 에서 SharedPreferences 인스턴스 캐싱 (initState 에서 load + 토글 변경 시 save)
- [ ] keys: `ebs.lobby.series.groupMode` (string: "year" / "month") + `ebs.lobby.series.hideCompleted` (bool)
- [ ] 위젯 테스트 추가 — SharedPreferences mock 으로 load + save 검증
- [ ] 통합 테스트: 앱 재시작 시 토글 상태 복원 (Patrol 또는 integration_test)
- [ ] 다른 화면 (Settings, Players 등) 의 향후 UI preference 도 동일 키 prefix `ebs.lobby.<screen>.` 권고 (확장성)

## 우선순위 / 추정

- P3 (UX 편의, 운영 영향 낮음)
- 추정: 패키지 추가 30분 + 코드 1h + 테스트 1h = 2.5h

## 의존성

- 없음 (B-LOBBY-SERIES-001 코어는 이미 구현)
