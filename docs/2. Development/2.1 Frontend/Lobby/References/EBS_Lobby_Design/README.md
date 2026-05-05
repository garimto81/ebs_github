---
title: EBS Lobby Reference Design (HTML/JSX prototype, 2026-04-29)
owner: team1 (consumer)
tier: reference
last-updated: 2026-05-03
source: "Downloads/EBS Lobby.zip (사용자 제공, 2026-04-29)"
linked-docs:
  - ../UI.md
  - ../Overview.md
  - ../../README.md
---

# EBS Lobby Reference Design

본 폴더는 **사용자가 제공한 HTML/JSX 프로토타입** (Downloads/EBS Lobby.zip, 2026-04-29) 의
원본 자산을 보존하여 team1 Lobby 기획·구현의 design SSOT 로 활용한다.

## 자산 목록

| 파일 | 내용 |
|------|------|
| `EBS Lobby.html` | 부트 HTML (window.EBS_UI ↔ JSX 묶음) |
| `app.jsx` | App shell + 화면 라우팅 |
| `data.jsx` | 샘플 데이터 (8 series + N events) — seed_demo_data.py 의 정렬 기준 |
| `screens.jsx` | 6 main screens — Series / Events / Flights / Tables / Players / Login |
| `screens-extra.jsx` | 3 extra screens — Hand History / Alerts / Settings |
| `shell.jsx` | TopBar (brand + show context + clock + Active CC pill + user pill) + Sidebar (5 nav) + Icons |
| `styles.css` | OKLCH 컬러 + 토큰 + 레이아웃 |
| `tweaks-panel.jsx` | 디자인 개발용 tweak 패널 (production 미포함) |
| `screenshots/` | alerts-check.png, settings-rebuilt.png |

## 디자인 ↔ 현재 EBS Lobby 매핑

| 디자인 element | 현재 EBS 구현 (`team1-frontend/lib/features/lobby/`) | 상태 |
|---------------|-----------------------------------------------------|:----:|
| **TopBar**: brand + SHOW/FLIGHT/LEVEL/NEXT clock + Active CC pill + user pill | 기획: `UI.md §공통 레이아웃 §헤더 바` ✅ (2026-05-05 보강) / 구현: B-091 PENDING | 📝 spec ✅ / 🔨 impl ⏳ |
| **Sidebar**: Series / Events / Flights / Tables / Players (5 items + WPS section) | go_router 경로별 화면 | ⏳ 부분 (Players 별도 feature) |
| **SeriesScreen**: year-grouped cards + status badge + bookmark + filter | 기획: `UI.md §화면 1` ✅ (2026-05-05 보강 — year-grouped + 5-color legend + bookmark 검증) / 구현: B-091 PENDING | 📝 spec ✅ / 🔨 impl ⏳ |
| **EventsScreen**: table view (no/time/name/buy-in/game/mode/entries/status/featured) | events 화면 | ⏳ |
| **FlightsScreen**: drill-down per event | flight 화면 | ⏳ |
| **TablesScreen**: tables list + onLaunch (CC) + waitlist | `table_detail_screen.dart` (`_handleLaunchCc` 구현됨, SG-008-b11 v1.3) | ✅ |
| **PlayersScreen**: 918 players sample, search | `lib/features/players/` | ⏳ |
| **HandHistoryScreen** | `lib/features/reports/` (Hand History 통합?) | ⏳ |
| ~~**AlertsScreen**~~ | **폐기 (2026-05-05 사용자 결정)** — EBS scope 외, screens-extra.jsx 자산은 보존하되 구현 대상 아님 | 🚫 |
| **SettingsScreen** | `lib/features/settings/` (6탭 — SG-003 DONE) | ✅ |

## Status badge 패턴

```jsx
const STATUS_LABEL = {
  running: "Running",
  announced: "Announced",
  registering: "Registering",
  completed: "Completed",
  created: "Created",
};
```

이 5 enum 은 EBS 의 `EventFSM` (`team2-backend/src/db/enums.py`) 와 정합:
- `created` → 미시작
- `announced` → 등록 전 공지
- `registering` → 등록 중
- `running` → 진행 중
- `completed` → 종료

## Sample data 정렬 (`data.jsx` ↔ `seed_demo_data.py`)

| Series id_hint | data.jsx | seed_demo_data.py |
|---------------|:---------:|:-----------------:|
| wps26 | ✅ | ✅ |
| wpse26 | ✅ | ✅ |
| circ-syd | ✅ | ✅ |
| circ-bra | ✅ | ✅ |
| wps25 | ✅ | ✅ |
| wpse25 | ✅ | ✅ |
| circ-ind | ✅ | ✅ |
| circ-atl | ✅ | ✅ |

→ **8/8 정합**. seed 실행 시 디자인 prototype 의 8 series 동일하게 BO DB 에 생성.

## 주요 디자인 누락분 (현재 Lobby 에서 보강 필요)

> **2026-05-05 cascade 결과**: 기획(spec) 보강 완료. 구현(impl) 은 `B-091` backlog 추적.

| 항목 | 출처 | 우선순위 | 기획 (spec) | 구현 (impl) |
|------|------|:--------:|:-----------:|:-----------:|
| 1. **Active CC pill** (TopBar) — `<button class="cc-pill">● Active CC · {n}</button>` | shell.jsx:53 | P1 | ✅ `UI.md §헤더 바 §Active CC pill` | ⏳ B-091 |
| 2. **SHOW/FLIGHT/LEVEL/NEXT clock** (TopBar) | shell.jsx:43-51 | P1 | ✅ `UI.md §헤더 바 §Show Context Cluster` | ⏳ B-091 |
| 3. **Year-grouped Series cards** + Hide completed checkbox | screens.jsx:18-50 | P2 | ✅ `UI.md §화면 1 §그룹핑 정책` + `Overview.md` 정합 | ⏳ B-091 |
| 4. **Status badge 5-color legend** (Running/Registering/Announced/Completed/Created) | screens.jsx:5-14, 49-54 + styles.css | P2 | ✅ `UI.md §화면 1 §Status Badge 5-color Legend` | ⏳ B-091 |
| 5. **Bookmark/star** 기능 (series.starred) | data.jsx:8, screens.jsx:70 | P3 | ✅ 이미 정의 (line 505/509) + 디자인 정합 검증 | ⏳ B-091 (검증) |
| ~~6. AlertsScreen~~ | ~~screens-extra.jsx~~ | 🚫 **폐기 (2026-05-05 사용자 결정)** | — | — |
| 7. **Tables onLaunch hook** + 5-status legend | screens.jsx (TablesScreen) | ✅ DONE | ✅ | ✅ SG-008-b11 v1.3 |

## 적용 범위 (R8 cascade)

본 문서는 **reference SSOT** — Lobby 화면 구현 결정 시 이 디자인 자산이 1차 참조. 단:
- OKLCH 색상값 / 폰트 / animation 은 Phase 1 production 에서 Material Design 3 (Flutter 기본) 와 절충
- React JSX 구조는 Flutter widget 트리로 1:1 매핑 안 됨 — semantic 만 보존
- 누락된 Alerts 화면은 SG-022/B-201 같은 별도 cascade 로 등재 (본 문서는 식별만)

## Changelog

| 날짜 | 변경 |
|------|------|
| 2026-05-05 | 누락 5개 항목 **기획 보강 완료** (P1 TopBar Show Context Cluster + Active CC pill / P2 Year-grouped + Status Badge 5-color Legend / P3 Bookmark 검증). 정본 변경: `UI.md §공통 레이아웃 §헤더 바` + `§화면 1` + `Overview.md §화면 1` + `Lobby_PRD.md v1.1.0 Changelog`. 후속 구현: `B-091`. 매트릭스를 spec ✅ / impl ⏳ 2축으로 갱신. |
| 2026-05-05 | AlertsScreen 폐기 (사용자 결정) — 매트릭스 행 strikethrough + 누락 항목 6번 strikethrough. 디자인 자산 (screens-extra.jsx) 은 자연 보존 |
| 2026-05-03 | 사용자 제공 자산 보존 + Lobby 매핑/누락 분석 (R8 신설) |
