---
title: Lobby 리뉴얼 계획 — EBS Lobby Design SSOT 1:1 정합
owner: conductor
tier: internal
status: REVIEW
last-updated: 2026-05-06
version: 1.0.0

provenance:
  triggered_by: user_directive
  trigger_summary: "EBS Lobby Design (Anthropic Design API E0XgzTcGcMuZqV8JauH3hw) 와 코드 정합 리뉴얼 계획 요청"
  user_directive: |
    "Fetch this design file, read its readme, and implement the relevant aspects of the design.
     이게 내가 원하는 lobby 디자인이야 어떻게 리뉴얼 해야하는지 보고"
  trigger_date: 2026-05-06
  precedent_incident: |
    iteration 1 (2026-05-06) 에서 /lobby 진입점 redirect 정정 후 추가 시각 drift 검증 요청

predecessors:
  - path: ../../2. Development/2.1 Frontend/Lobby/References/EBS_Lobby_Design/
    relation: source_content
    reason: "디자인 SSOT — 사용자 제공 HTML/JSX 프로토타입 (2026-04-29)"
  - path: ../../2. Development/2.1 Frontend/Lobby/References/EBS_Lobby_Design/README.md
    relation: source_content
    reason: "디자인 ↔ 구현 매핑 매트릭스 (단, 일부 outdated)"
  - path: ../Critic_Reports/Lobby_Spec_Implementation_Drift_2026-05-06.md
    relation: derived_from
    reason: "iteration 1 의 Type C drift 진단 → 본 plan 은 시각 정합 차원 후속"

related-docs:
  - ../../../team1-frontend/lib/foundation/theme/design_tokens.dart
  - ../../../team1-frontend/lib/features/lobby/widgets/lobby_shell.dart
  - ../../../team1-frontend/lib/foundation/router/app_router.dart
  - ../../2. Development/2.1 Frontend/Lobby/UI.md
confluence-page-id: 3818586954
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818586954/EBS+Lobby+EBS+Lobby+Design+SSOT+1+1
---

# Lobby 리뉴얼 계획

> **놀랍게도 코드의 90%는 이미 디자인 SSOT 와 정합. 진짜 drift 는 Sidebar 통합 1건.**

## Edit History

| 날짜 | 버전 | 트리거 | 변경 |
|------|:----:|--------|------|
| 2026-05-06 | 1.0.0 | 사용자 directive (Anthropic Design fetch + 리뉴얼 요청) | 최초 작성 — Phase 3 단계 plan |

---

<a id="ch-anchor"></a>
<!-- FB §Anchor · Reader Anchor -->

## 이 계획이 데려가는 곳

<table role="presentation" width="100%">
<tr>
<td width="50%" valign="middle" align="left">

**입구 (지금 상태)**

iteration 1 의 router redirect 후 진입 첫 화면은 명세 정합. 그러나 사용자 navigation 경험은 두 chrome (LobbyShell + _AppShell) 분리로 끊김. 사용자가 본 "디자인과 다름" 의 본질.

</td>
<td width="50%" valign="middle" align="left">

**출구 (이 계획을 끝까지 읽은 후)**

진짜 drift 가 1건이라는 것을 안다. Phase 3 의 우선순위 + 각 Phase 의 자율 처리 가능 범위 + backend 의존 항목을 안다. 자율 iteration 으로 어디까지 갈 수 있는지 안다.

</td>
</tr>
</table>

---

## 1. Act 1 — 디자인 SSOT 인벤토리 (Setup)

```
  +------------------------------------------------------+
  |  EBS_Lobby_Design/                                    |
  +------------------------------------------------------+
  |  EBS Lobby.html      bootstrap (React 18 CDN)         |
  |  styles.css     734  OKLCH tokens + chrome layout     |
  |  shell.jsx      129  TopBar + Rail + Breadcrumb       |
  |  screens.jsx    466  Series/Events/Flights/Tables/    |
  |                      Players/Login (6 screens)        |
  |  screens-extra  --   Hand History/Alerts/Settings     |
  |  app.jsx        113  Routing                          |
  |  data.jsx       --   8 series × N events seed         |
  +------------------------------------------------------+
  |  visual/screenshots/ (정본 시각 SSOT)                 |
  |  ├─ ebs-lobby-01-series.png      → Year-grouped grid  |
  |  ├─ ebs-lobby-02-events.png      → Status tabs        |
  |  ├─ ebs-lobby-03-flights.png     → Drill-down         |
  |  ├─ ebs-lobby-04-tables.png      → KPI + Levels Strip |
  |  ├─ ebs-lobby-05-players.png     → 918 players list   |
  |  ├─ ebs-lobby-06-hands.png       → Hand History       |
  |  └─ ebs-lobby-07-settings.png    → Settings 6 tabs    |
  +------------------------------------------------------+
```

**디자인 미학** (styles.css `:root`):
- Bloomberg-terminal broadcast operations console
- Warm-neutral background (oklch ~80° hue) — `#FBFAF7` (warm white)
- Rail = always-dark (`oklch 0.16` → `#211E18`)
- Functional accents: live-green / amber / danger / info / gold (featured)
- Type: Inter (UI) + JetBrains Mono (numerics, IDs, timecodes)

---

## 2. Act 2 — 진짜 drift 매트릭스 (Incident)

### 2-A. 코드 정합 자가 점검 (8축)

| # | 디자인 SSOT 요소 | 코드 위치 | 정합 |
|:-:|------------------|----------|:----:|
| 1 | OKLCH color tokens (35종) | `design_tokens.dart` | ✅ 정합 (oklch→sRGB pinned) |
| 2 | TopBar (brand · cluster · cc-pill · clock · user) | `lobby_top_bar.dart` | ✅ 정합 |
| 3 | Series 화면 year-grouped cards | `series_screen.dart` | ✅ 정합 |
| 4 | Status badge 5-color | `lobby_status_badge.dart` | ✅ 정합 |
| 5 | Event/Flight/Table drilldown 라우팅 | `app_router.dart` ShellRoute | ✅ 정합 |
| 6 | Density preset (compact/standard/cozy) | `design_tokens.dart` LobbyDensityX | ✅ 정합 |
| 7 | Levels Strip (NOW · NEXT · countdown) | `levels_strip.dart` | ⚠️ hardcoded mock |
| 8 | Sidebar 통합 (Navigate + WPS + Tools 3 그룹) | LobbyShell + _AppShell **분리** | ❌ **drift** |

### 2-B. 진짜 drift = #8 한 가지

```
  디자인 SSOT (shell.jsx)              코드 (현재)
  +-------------------------+         +-------------------------+
  | TopBar                  |         | LobbyShell              |
  +-------------+-----------+         +---------+---------------+
  | Sidebar     | Body      |         | LobbySide| Body         |
  | Navigate    |           |         | Series   |              |
  |  Series  4 |           |         | Events   |              |
  |             |           |         | Flights  |              |
  | WPS·EU 2026 |           |         | Tables   |              |
  |  Events 95 |           |         | Players  |              |
  |  Flights 8 |           |         |          |              |
  |  Tables 124|           |         | (Tools 그룹 부재)        |
  |  Players918|           |         +---------+---------------+
  |             |           |
  | Tools       |           |         _AppShell (분리됨)
  |  Hand H 142|           |         +---------+---------------+
  |  Alerts 4  |           |         |Navigation|              |
  |  Settings  |           |         |Rail      | Body         |
  +-------------+-----------+         | Lobby    |              |
                                      | Players  |              |
                                      | Staff    |              |
                                      | Settings |              |
                                      | GFX      |              |
                                      | Reports  |              |
                                      +---------+---------------+
```

**문제**: 사용자가 `/lobby/series` → drilldown 진입 시 LobbyShell. Settings 같은 메타 화면 진입 시 _AppShell. 둘이 시각적으로 다르고 navigation 결합 안 됨. **디자인 SSOT 는 단일 sidebar 가 모든 화면 공통.**

### 2-C. 부수적 drift (P2/P3)

| # | 항목 | 현재 | 디자인 |
|:-:|------|------|--------|
| 9 | TopBar cluster 칸 수 | SHOW/EVENT/TABLE (3, dynamic) | SHOW/FLIGHT/LEVEL/NEXT (4, fixed) |
| 10 | Sidebar badge (count) | 일부 미구현 | Series 4 / Events 95 / Flights 8 / Tables 124 / Players 918 |
| 11 | Sidebar collapsed brand label | 구현 ✅ | E mark only |
| 12 | Levels Strip dynamic 데이터 | hardcoded "L17 · 6,000/12,000 · 22:48" | API 연결 필요 |
| 13 | Active CC pill dynamic count | hardcoded 3 | WebSocket /ws/lobby 의 active CC 수 |

---

## 3. Act 3 — Phase 3 단계 리뉴얼 plan (Build)

### Phase 1 — Sidebar 통합 (P1, 4-6h, 자율 가능)

| Step | 작업 | 영향 |
|:----:|------|------|
| 1.1 | LobbySideRail 에 "Tools" 그룹 추가 (Hand History, Settings, GFX, Reports) | LobbyShell 단일 chrome |
| 1.2 | Sidebar item id ↔ 라우트 매핑 확장 (`/reports`, `/settings`, `/graphic-editor`, `/staff`) | Sidebar 클릭 → context.go |
| 1.3 | _AppShell 폐기 + 모든 라우트를 LobbyShell ShellRoute 안으로 이동 | router 단일 ShellRoute |
| 1.4 | NavigationRail import 제거 + _AppShell 클래스 제거 | 죽은 코드 정리 |
| 1.5 | flutter analyze + build web + docker rebuild + curl 검증 | iteration 검증 |

**완료 시점**: 사용자가 어느 화면 진입하든 동일한 TopBar + Sidebar. 디자인 SSOT 와 1:1 시각 정합.

### Phase 2 — TopBar Cluster 4칸 + Sidebar badge (P2, 2-3h, 자율 가능)

| Step | 작업 |
|:----:|------|
| 2.1 | TopBar cluster 를 SHOW/FLIGHT/LEVEL/NEXT 4칸 fixed 로 변경 (LEVEL/NEXT 는 미연결 시 "—") |
| 2.2 | LobbySideRail item 에 badge 필드 추가 + Series/Events 등 count provider 연동 |
| 2.3 | Sidebar Tools 그룹 badge (Hand History 142, Alerts 폐기) |
| 2.4 | analyze + build + docker + verify |

### Phase 3 — Dynamic 데이터 (P3, backend 의존, team2 협조)

| Step | 작업 | 의존 |
|:----:|------|:----:|
| 3.1 | Levels Strip 의 NOW/NEXT/countdown 을 flight metadata 에서 가져오기 | API-01 GET /flights/:id/levels |
| 3.2 | Active CC pill count 를 WebSocket /ws/lobby 의 cc_session_count 이벤트 구독 | API-05 WS event |
| 3.3 | Sidebar Series/Events/Flights/Tables/Players badge 를 list provider count 로 동적 | provider 직접 |

> Phase 3 는 `team2-backend/src/api/` 변경 동반. autonomous iteration 으로 진행 시 team2 publisher 권한 필요 (Mode A Conductor 단일 세션 시 가능).

---

## 4. Act 4 — 자율 iteration plan (Resolution)

### 4-A. 자율 진행 가능 범위

```
  +-------------------------------------------------------+
  | Iter 2 = Phase 1 (Sidebar 통합)        ← 자율 가능   |
  | Iter 3 = Phase 2 (Cluster 4칸 + badge)  ← 자율 가능   |
  | Iter 4 = Phase 3.1 (Levels Strip)       ← team2 협조  |
  | Iter 5 = Phase 3.2/3.3 (WS + badge)     ← team2 협조  |
  +-------------------------------------------------------+
```

### 4-B. 사용자 인텐트 영역 (자율 결정 보류)

| 항목 | 이유 |
|------|------|
| `LobbyDashboardScreen` 코드 보존 vs 제거 | 명세 외 단일-페이지 dashboard, 의도가 모호 |
| Alerts 화면 폐기 결정 (README 2026-05-05 = 이미 폐기) | 재확인만 — 결정은 이미 됨 |
| Phase 3 의 backend 협조 범위 | team2 publisher 권한 행사 여부 |

### 4-C. 외부 인계 PRD 영향

| PRD | 영향 |
|-----|------|
| `Lobby.md` v2.0.1 (external) | 메타포 ("관제탑") 추상화로 영향 없음 |
| `Overview.md` / `UI.md` (internal) | Sidebar 그룹 정의 보강 필요 (Phase 1 완료 후) |
| `team1-frontend/CLAUDE.md` | LobbyShell 단일 chrome 명시 (Phase 1 완료 후) |

---

## 5. 결론

```
  +-------------------------------------------------------+
  |  현재 정합도   :  코드 90% (8축 중 7축 ✅)             |
  |  진짜 drift    :  Sidebar 통합 1건 (P1)                |
  |  부수 drift    :  TopBar Cluster + badge (P2)         |
  |  backend 의존  :  Levels/Active CC/badge dynamic (P3)|
  |  자율 가능     :  Phase 1 + Phase 2 (Iter 2-3)        |
  |  team2 협조    :  Phase 3 (Iter 4-5)                  |
  +-------------------------------------------------------+
```

**리뉴얼 핵심 메시지**: "이미 거의 다 됐다. Sidebar 통합 한 가지만 끝나면 디자인 SSOT 와 1:1." 사용자가 본 "디자인과 다름" 의 90% 는 두 chrome 분리에서 오는 navigation 단절 때문.

다음 iteration trigger 시 Phase 1 자율 진행.
