---
id: B-090
title: "Lobby Design — 5-screen drilldown 재구조화 (Phase 2)"
status: IN_PROGRESS
created: 2026-04-29
updated: 2026-04-29
owner: team1
source: Anthropic Design API handoff (skI1cZio_-fe4N4Hgcr0Tw, EBS Lobby.html)
depends-on: B-089
mirror: none
---

# B-090 — Lobby Design Phase 2: 5-Screen Drilldown

## 배경

B-089 (Phase 1) 에서 visual foundation (tokens / chrome 위젯) 이식. 본 백로그는 화면 구조를 디자인 의도(5 단계 drilldown) 로 재구조화한다.

현재: 단일 dashboard (Series selector + Events DataTable + Tables DataTable 한 화면)
목표: Series → Events → Flights → Tables → Players 5-screen drilldown

## 범위 (예상)

| # | 변경 | 내용 |
|---|------|------|
| 1 | `go_router` 라우트 분리 | `/series` `/events/:eventId` `/flights/:flightId` `/tables/:flightId` `/players/:flightId` |
| 2 | `lib/features/lobby/screens/series_screen.dart` (신규) | Year-grouped card grid with banner accent |
| 3 | `lib/features/lobby/screens/events_screen.dart` (신규) | KPI strip + status tabs + dense table (EBS-only Game Mode column) |
| 4 | `lib/features/lobby/screens/flights_screen.dart` (신규) | KPI strip + 8-flight dense table |
| 5 | `lib/features/lobby/screens/tables_screen.dart` (재설계) | KPI + Levels strip + Toolbar + Tables grid + 240px Waitlist |
| 6 | `lib/features/lobby/screens/players_screen.dart` (재설계) | KPI strip + state filter + chips bar + EBS stats columns |
| 7 | `lib/features/lobby/widgets/kpi_strip.dart` (신규) | KPI 카드 strip 공용 위젯 |
| 8 | `lib/features/lobby/widgets/levels_strip.dart` (신규) | Now/Next/After + countdown clock |
| 9 | `lib/features/lobby/widgets/dense_table.dart` (신규) | 32px row 기준 dense table cell/row 위젯 |
| 10 | `lib/features/lobby/widgets/waitlist_drawer.dart` (신규) | 240px right-docked drawer |
| 11 | `lib/features/lobby/widgets/seat_cells.dart` (재설계) | 22x22 seat states (a/e/r/d/w) |
| 12 | `lib/features/lobby/screens/lobby_dashboard_screen.dart` | deprecate or redirect |

## 후속 의존성

- 디자인의 KPI/Levels/Waitlist 데이터를 위해 추가 provider/repository 필요할 수 있음 (조사 단계 필요)
- 기존 `event_provider`, `flight_provider`, `table_provider`, `player_provider` 호환성 검증 필요
- i18n 키 추가 (5 screen titles, KPI labels, status labels)

## 추가 후속 (별도 Backlog)

- `pubspec.yaml` `google_fonts` 추가 (Inter / JetBrains Mono 실제 로드) — Phase 1 에서는 fontFamily 만 명시, 실제 폰트 ttf 적재는 별도 작업
- Density toggle UI (Settings 또는 user pref)
- Light/Dark theme 사용자 토글 UI

## 수락 기준 (예상)

- [ ] go_router 가 5 라우트로 분리됨
- [ ] 각 screen 이 디자인의 KPI / 테이블 / 부속 위젯과 1:1 매칭
- [ ] 기존 데이터 provider 와 호환 (mock 데이터 흐름 유지)
- [ ] `flutter analyze` 0 error / `flutter test` 통과

## 참조

- B-089 — Foundation visual system (선행)
- 디자인 번들: `.scratch/design-fetch/`

## Changelog

| 날짜 | 변경 |
|------|------|
| 2026-04-29 | 최초 작성 (B-089 후속 분리) |
