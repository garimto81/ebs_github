---
id: B-091
title: "Lobby Design — 누락 5개 항목 구현 (TopBar + Series 화면 + Bookmark 검증)"
status: PENDING
created: 2026-05-05
updated: 2026-05-05
owner: team1
source: "사용자 디자인 자산 (EBS Lobby.zip, 2026-04-29) cascade — 2026-05-05 기획 보강 완료"
depends-on: B-090
related-prd:
  - docs/1. Product/Lobby_PRD.md (v1.1.0 Changelog 2026-05-05)
  - docs/2. Development/2.1 Frontend/Lobby/UI.md (§공통 레이아웃 §헤더 바, §화면 1)
  - docs/2. Development/2.1 Frontend/Lobby/Overview.md (§화면 1)
  - docs/2. Development/2.1 Frontend/Lobby/References/EBS_Lobby_Design/README.md
---

# B-091 — Lobby Design 누락 5개 항목 구현

## 배경

2026-05-03 사용자가 제공한 EBS Lobby.zip 디자인 자산을 `Lobby/References/EBS_Lobby_Design/` 에 SSOT 보존. 2026-05-05 디자인 ↔ 현재 EBS 기획 매트릭스 분석 결과 **누락 5개** 식별 (AlertsScreen 폐기 후) → 기획 보강 완료. 본 backlog 는 보강된 기획의 **Flutter 구현** 을 추적한다.

## 범위

| # | 항목 | 우선순위 | 정본 SSOT |
|---|------|:--------:|----------|
| 1 | **Show Context Cluster** (TopBar 중앙) — SHOW · FLIGHT · LEVEL · NEXT 4 segment | P1 | `UI.md §공통 레이아웃 §헤더 바 §Show Context Cluster (2026-05-05 신설)` |
| 2 | **Active CC pill** (TopBar 우측) — 펄스 애니메이션 + count + 클릭 시 Active CC 패널 | P1 | `UI.md §공통 레이아웃 §헤더 바 §Active CC pill (2026-05-05 신설)` |
| 3 | **Year-grouped Series cards** + Hide completed checkbox | P2 | `UI.md §화면 1 §그룹핑 정책 (2026-05-05)` |
| 4 | **Status Badge 5-color Legend** (Running/Registering/Announced/Completed/Created) | P2 | `UI.md §화면 1 §Status Badge 5-color Legend (2026-05-05 신설)` |
| 5 | **Bookmark / star 검증** — 이미 정의됨, 디자인 자산 정합 확인 | P3 | `UI.md §화면 1 §Bookmark / Star 검증 (P3, 2026-05-05)` |

## 구현 매핑 (예상)

| Spec | Flutter 구현 위치 |
|------|-------------------|
| Show Context Cluster | `team1-frontend/lib/features/lobby/widgets/show_context_cluster.dart` (신규) |
| Active CC pill | `team1-frontend/lib/features/lobby/widgets/active_cc_pill.dart` (신규) + `cc_active_provider.dart` (신규 또는 기존 cc provider 확장) |
| Year-grouped Series cards | `team1-frontend/lib/features/lobby/screens/series_screen.dart` (B-090 신규 화면 내부 그룹핑 로직) |
| Status Badge 5-color | `team1-frontend/lib/features/lobby/widgets/status_badge.dart` (신규 또는 design tokens 확장) |
| Bookmark 검증 | `team1-frontend/lib/features/lobby/screens/series_screen.dart` 내부 + `bookmark_provider.dart` |

## API 의존성

| Endpoint | 상태 | 비고 |
|----------|:----:|------|
| `GET /api/v1/series/{active}` (SHOW segment) | ⏳ | series.code + name_short 필드 확인 필요 |
| `GET /api/v1/flights/{active}` (FLIGHT segment) | ⏳ | flight.label 필드 확인 필요 |
| API-04 `tournament.current_level` (LEVEL/NEXT) | ⏳ | Game Engine 1초 tick 정합 |
| `cc:session_changed` WebSocket | ✅ | 기존 정의 (검증 필요) |
| `POST/DELETE /Series/{id}/Bookmark` (GAP-L-016) | ✅ | 이미 정의됨 |

## 수락 기준

| # | 기준 |
|---|------|
| 1 | TopBar 에 SHOW/FLIGHT/LEVEL/NEXT 가 1초 tick 으로 갱신 표시 |
| 2 | Active CC pill 이 active count > 0 일 때 펄스 애니메이션 동작 + 클릭 시 Active CC List 드롭다운 |
| 3 | Series 화면이 연도(Year) 1차 그룹 + 시작일 내림차순 2차 정렬로 표시 |
| 4 | Series 화면 toolbar 에 5-color status legend 표시 (모든 role) |
| 5 | Series 카드의 ☆/★ 토글이 `POST/DELETE /Series/{id}/Bookmark` 호출 + 상태 보존 |
| 6 | RBAC: Active CC pill 의 Operator 본인 할당 테이블만 표시 / Viewer pill count 만 |

## 후속 의존성

- B-090 (5-screen drilldown) 화면 골격 완료 후 본 backlog 진행
- design tokens (B-089) 의 색상 토큰 (success/warning/info/muted/slate-faded) 5개 확정 후 Status Badge 적용

## 참조

- 디자인 자산: `Lobby/References/EBS_Lobby_Design/shell.jsx:43-53` (TopBar), `screens.jsx:5-90` (SeriesScreen), `data.jsx:8` (starred), `styles.css §badge`
- 기획 보강 cascade: 2026-05-05 사용자 directive — `lobby html디자인 참고하여 변경 내역 보고 → AlertsScreen 폐기, 나머지 기획확인 후 보강 진행 iteration`

## Changelog

| 날짜 | 변경 |
|------|------|
| 2026-05-05 | 신규 작성 — 기획 보강 완료 (UI.md / Overview.md / Lobby_PRD.md) 후 구현 추적용 backlog 등재 |
