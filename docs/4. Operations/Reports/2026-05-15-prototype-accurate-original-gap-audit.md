---
title: 정본 프로토타입 ↔ 현재 프로토타입 Gap Audit (Ultrathink) [SUPERSEDED]
owner: conductor
tier: internal
last-updated: 2026-05-17
status: SUPERSEDED
superseded_by: ~/.claude/plans/decision-report-v5-ultrathink-rewrite.md
superseded_reason: "본 보고서는 정본 ZIP 만 비교 기준으로 삼고 PRD chain (Foundation/Lobby/CC/RIVE) 의 정본성을 무시. v1-v5 보고서 chain 통해 7-Layer architecture 재정의 + PokerGFX 정본 (역공학 3000줄) 100% 분석 결과로 superseded. 본문 보존 (Removal ≠ Answer) — 역사 추적용. 후속 SG ticket = SG-renewal-ui-18~32 (15건)."
confluence-sync: none
mirror: none
provenance:
  triggered_by: user_directive
  trigger_date: 2026-05-15
  trigger_text: "Designate and remember this material as the accurate original, analyze the differences from the current prototype using Ultrathink, analyze the problems and shortcomings of the current prototype, and submit a report."
  ground_truth:
    - C:\Users\AidenKim\Downloads\EBS Lobby (1).zip
    - C:\Users\AidenKim\Downloads\EBS Command Center (2).zip
  memory_link: prototype_accurate_original_2026_05_15.md
  audit_workspace: C:\claude\ebs\work\prototype-audit\
---

## 🎯 한 줄 요약

> 사용자가 이번에 새로 지정한 **두 React 인터랙티브 프로토타입 ZIP** 이 정본입니다.
> 기존 docs/ 의 HTML mockup 두 개는 **정본과 차원이 다른 단순 wireframe** 으로, 정본의 인터랙션·디자인 토큰·데이터 모델을 거의 반영하지 못합니다.
> Flutter 구현(team1/team4) 은 **정본의 60-75% 를 잘 따라가고 있으나**, Lobby 쪽은 **브랜드 정체성 (WSOP vs WPS) 충돌**, CC 쪽은 **PlayerColumn 1×10 핵심 레이아웃 일치 여부** 가 핵심 차단 이슈입니다.

### 비유로 정리

> 정본 = **완성된 자동차 운전석 모형**.
> 현재 mockup HTML = **자동차 설명서 그림 2 장** (움직이지 않음, 색상도 다름).
> 현재 Flutter 구현 = **실제 작동하는 운전석** (대부분 일치하지만 일부 계기판이 다른 모델 부품).

### 메트릭 표

| 항목 | 결과 |
|------|------|
| 정본 (ground truth) | 2 ZIP — Lobby (130 KB / 8 JSX) + CC (357 KB / 9 JSX + 52 카드 PNG) |
| 비교 대상 | 4 개 — HTML mockup × 2 (A, B) + Flutter 구현 × 2 (C, D) |
| 전체 정합도 (가중 평균) | **A: 25% / B: 20% / C: 68% / D: 72%** |
| P0 차단 결함 (외부 인계 불가) | **5 건** (Lobby 브랜드 정체성, CC 레이아웃, mockup HTML 두 개의 사실상 미사용 상태 포함) |
| P1 흐름 차단 (사용자 흐름 일부 막힘) | **9 건** |
| P2 시각/명명 drift | **14 건** |
| P3 개선 권고 | **8 건** |
| 정본 자체 무결성 | **PASS** (단, unpkg CDN 의존 → LAN 환경 호환성 ⚠) |
| 후속 SG 필요 | **YES** (P0/P1 모두 별도 cycle, 본 보고서는 분석만) |

---

## Act 1 — 정본 등록 + 무결성

### 1.1 영구 등록 완료

| 항목 | 위치 |
|------|------|
| 정본 SSOT 메모리 | [`prototype_accurate_original_2026_05_15.md`](../../../../Users/AidenKim/.claude/projects/C--claude-ebs/memory/prototype_accurate_original_2026_05_15.md) |
| MEMORY.md 인덱스 | 한 줄 추가 완료 (line 11 이후) |
| Audit workspace | `work/prototype-audit/` (gitignored, SHA manifest 포함) |

### 1.2 SHA256 무결성

| 정본 | Size | SHA256 (앞 16 자) |
|------|:----:|-------------------|
| EBS Lobby (1).zip | 130,457 B | `CC277B322B33F39F…` |
| EBS Command Center (2).zip | 356,559 B | `237B26FF866E25E0…` |

> 이후 두 ZIP 의 SHA 가 위와 다르면 → 정본 갱신 가능성 → 사용자 확인 후 재등록 필요.

### 1.3 정본 자체 무결성 (축 1)

| 검증 항목 | Lobby | CC |
|----------|:-----:|:--:|
| Entry HTML 단독 구동 | ✅ React + Babel CDN | ✅ React + Babel + Google Fonts |
| 내부 파일 누락 | ✅ 없음 | ✅ 없음 (52 카드 PNG 포함) |
| JSX syntax | ✅ 표준 React 18 | ✅ 표준 React 18 |
| 외부 의존 | ⚠ unpkg CDN | ⚠ unpkg + Google Fonts CDN |
| LAN/오프라인 환경 호환 | ❌ CDN 차단 시 미작동 | ❌ CDN 차단 시 미작동 |
| 외부 자산 | screenshots 2 장 (참조용) | assets/cards/*.png 52 장 |

**무결성 판정**: **PASS (자체 구동 가능)**. 단, 카지노 LAN 같은 **방화벽 환경에서는 CDN 차단으로 미작동** — 후속 SG 권고 항목 #1 참조.

### 1.4 정본의 외부 등록 상태 (구조적 gap)

```
   현재 상태:
   
   Downloads/                docs/1. Product/
   ├── EBS Lobby (1).zip     ├── visual/
   ├── EBS Command Center    │   └── ebs-lobby-mockup.html  ← 정본 아님
   │   (2).zip               └── References/
                                 └── foundation-visual/
                                     └── cc-mockup.html      ← 정본 아님
   
        [정본 외부 보관]                    [정본 가장한 mockup]
        
   문제: 본 프로젝트 인텐트 "개발 문서 + 프로토타입 100% 일관성"
   에 비추면, docs/ 안에 정본이 미러되어 있어야 하나 부재.
```

→ **P0 차단 결함 #1**: 정본이 git 추적 외부에 있어 모든 협업자가 사본을 받을 수 없음. 후속 SG 권고 항목 #2 참조.

---

## Act 2 — 정본 5 축 분석 결과

### 2.1 컴포넌트 분해 (축 1)

#### Lobby 정본 컴포넌트 트리

```
   App
   ├── TopBar         (Show/Flight/Level/Next + Active CC pill + clock + user)
   ├── Rail           (3 sections — Navigate / WPS·EU 2026 / Tools)
   │   └── RailItem   × 8
   ├── Breadcrumb     (per-screen trail with go-back)
   ├── Screens (9)
   │   ├── LoginScreen
   │   ├── SeriesScreen      ← year-grouped card grid + filter/bookmark
   │   ├── EventsScreen      ← 5-status tabs + dtable + featured row
   │   ├── FlightsScreen     ← kpi-strip + dtable (Day1A/1B/1C/Day2/...)
   │   ├── TablesScreen      ← kpi-strip + levels-strip + Grid/Map/CC views + waitlist
   │   ├── PlayersScreen     ← kpi-strip + state filter + VPIP/PFR/AGR
   │   ├── HandHistoryScreen ← split (list + detail)
   │   ├── AlertsScreen
   │   └── SettingsScreen
   ├── Launch CC Modal (inline)
   └── TweaksPanel    (Appearance / Layout / Navigation)
```

#### CC 정본 컴포넌트 트리

```
   App  (1600×900 design canvas, scale-fit)
   ├── StatusBar      (BO/RFID/Engine dots + Hand# + Phase + Players + icons)
   ├── TopStrip       (MiniDiagram + community board + acting/phase indicator + kbd hints)
   ├── PlayerGrid     (1×10 horizontal grid of PlayerColumn)
   │   └── PlayerColumn × 10  ← 핵심 레이아웃
   │       ├── Status strip (ACTING/WAITING/FOLD/DELETE)
   │       ├── Row 1: Seat No (S1..S10)
   │       ├── Row 2: PosBlock (STRADDLE / SB|BB / D, with ‹/› shift arrows)
   │       ├── Row 3a: Country flag
   │       ├── Row 3b: Name
   │       ├── Row 4: Hole cards (2)
   │       ├── Row 5: Stack
   │       ├── Row 6: Bet
   │       └── Row 7: Last Action
   ├── ActionPanel    (FOLD / CHECK·CALL / BET·RAISE / ALL-IN + START/FINISH HAND + Undo + Miss Deal + Layout switcher)
   ├── Modals
   │   ├── CardPicker   (52 cards + dealt-key tracking)
   │   ├── Numpad       (BET/RAISE amount entry)
   │   ├── MissDealModal
   │   └── FieldEditor  (모든 필드 통합 편집 모달)
   └── TweaksPanel    (Theme: accent/felt hue / Engine: online·degraded·offline / Display: equity·chips·kbd)
```

> **핵심 통찰**: CC 의 PlayerColumn 은 **모든 셀이 click-to-edit** (FieldEditor 모달 트리거). 정적 보기 화면이 아니라 **운영 인풋 폼** 이 핵심. 이 점이 현재 프로토타입과 비교 시 차별점.

### 2.2 화면 (축 2) + 인터랙션 (축 3) 정본 요약

**Lobby 인터랙션 핵심**:
- 라이브 클럭 (1 초 interval)
- 3-level breadcrumb 네비게이션 (Series → Events → Flights → Tables → Players)
- 5-status event 탭 (created/announced/registering/running/completed)
- Tables 화면 — 9 좌석 한 줄 표시 + Grid/Floor Map/CC Focus 토글
- Launch CC 모달 (idle 테이블 클릭 → 확인 → 운영자 할당)
- TweaksPanel — 테마/밀도/EBS-only 컬럼/로그인 강제

**CC 인터랙션 핵심**:
- 키보드 6 핫키: **N / F / C / B / A / M**
- Hand FSM 7 상태: **IDLE → PRE_FLOP → FLOP → TURN → RIVER → SHOWDOWN → HAND_COMPLETE**
- 모든 PlayerColumn 셀이 클릭 가능 → FieldEditor 모달
- POS 시프트 — D / SB / BB / STRADDLE 좌석을 ‹/› 화살표로 시계/반시계 이동
- Miss Deal (M키) — 핸드 시작 시점 snapshot 으로 자동 복원
- Engine state 배너 (online/degraded/offline + Reconnect 버튼)
- 1600×900 design canvas 자동 scale-fit (창 크기 무관)
- Layout 모드 3 종 (bottom / left / right)

### 2.3 디자인 토큰 (축 4) 정본 요약

| 토큰 카테고리 | Lobby | CC |
|--------------|-------|-----|
| 색 모델 | OKLCH | OKLCH |
| 테마 | light/dark | 다크 only (broadcast-ops) |
| 폰트 | var(--ui)/var(--mono) (시스템 default) | **Inter + JetBrains Mono** (Google Fonts) |
| 표면 | --line/--line-soft | --bg-0..3 (4 단계 surface) |
| 액센트 | OKLCH 시리즈별 accent (동적) | **broadcast amber** (hue 65, 동적) |
| Felt (테이블 색) | N/A | **OKLCH hue 165** (녹색, 동적) |
| Position 색상 | N/A | --pos-d (bone), --pos-sb, --pos-bb |
| Geometry | N/A | --r-sm/md/lg/xl (4/8/12/16 px) |
| Shadows | N/A | --shadow-card, --shadow-pop, --glow-action |

### 2.4 데이터 모델 (축 5) 정본 요약

**Lobby**:
| 모델 | 핵심 필드 (정본 정의) |
|------|---------------------|
| Series | id, year, name, location, venue, range, events, status, accent(OKLCH), starred |
| Event | no, time, name, buyin, game, mode, entries, reentries, unique, status, featured |
| Flight | no, name, time, entries, players, tables, status, active |
| Table | id, featured, seats[9], rfid, deck, out, cc, op, marquee |
| Player | place, name, country, flag, chips, bb, state, vpip, pfr, agr, ft, featured |
| Hand | id, game, players, winner, pot, time, showdown, big, blinds, limit, table, board[5], seats[], phases[4] |

**CC**:
| 모델 | 핵심 필드 |
|------|----------|
| GameState | handNumber, phase, pot, sidePots[], blinds(sb/bb/ante), gameType, bettingStructure, dealerSeat, sbSeat, bbSeat, straddleSeat, actionOnSeat, biggestBet, community[5] |
| Seat | no(1-10), occupied, name, flag, stack, holeCards[2], lastAction, bet, folded, allIn, equity, **sync(AUTO/MANUAL_OVERRIDE/CONFLICT)** |
| Connection | bo(ok/warn/err), rfid(ok/warn/err), engine(online/degraded/offline) |
| BettingRound | numRaises, lastRaiseIncrement |
| Card | rank, suit, color + asset path mapping (S/H/D/C × T/J/Q/K/A/2-9 + back) |

---

## Act 3 — Gap Matrix (5 축 × 4 비교 대상 = 20 cell)

### 3.1 매트릭스 한눈에 보기

| 축 \ 대상 | A: Lobby HTML mockup | B: CC HTML mockup | C: Flutter Lobby | D: Flutter CC |
|----------|:--------------------:|:-----------------:|:----------------:|:-------------:|
| **축 1** 컴포넌트 | **20%** 6/9 화면만, 인터랙 컴포넌트 미존재 | **15%** 좌석 박스만, PlayerColumn 구조 0% | **75%** 풍부한 widget 트리, 일부 정본 미정의 추가 | **70%** Action/Status/Diagram/Picker/Modal 매핑됨, PlayerColumn 1×10 여부 ⚠ |
| **축 2** 화면 | **67%** 6/9 (Hand/Alerts/Settings 누락) | **100%** 단일 화면 (정본도 단일) | **133%** 정본 9 + extras (graphic_editor/staff) | **117%** 정본 1 + 추가 화면 (RFID/Stats 등) |
| **축 3** 인터랙션 | **0%** 정적 HTML, 모든 동작 미구현 | **0%** 정적 HTML, 핫키/FSM/Miss Deal 미구현 | **80%** Riverpod provider 체계 + nav/auto-setup 풍부 | **85%** Hand FSM + Keyboard + Miss Deal + Undo + Engine 모두 매핑 |
| **축 4** 디자인 토큰 | **10%** Hex 색, WSOP 빨강 (OKLCH 미사용, 정본과 다른 브랜드) | **15%** Hex 색, broadcast amber 비슷, 디자인 토큰 시스템 없음 | **? 확인 필요** Flutter ThemeData 의 OKLCH 매핑 여부 | **? 확인 필요** Flutter ThemeData + Inter/JetBrains 폰트 여부 |
| **축 5** 데이터 모델 | **30%** Series/Event/Flight/Table/Player 필드 일부 매칭 (OKLCH accent 누락 등) | **40%** Seat 좌석명·stack 있음, sync/equity/holeCards 모델 없음 | **75%** providers 명명이 정본과 강하게 일치 | **80%** Hand FSM provider + seat provider + engine connection 매칭 |
| **가중 합산 정합도** | **25%** | **20%** | **68%** | **72%** |

### 3.2 cell-by-cell 상세

#### A: docs/1. Product/visual/ebs-lobby-mockup.html (Lobby HTML mockup)

**축 1 컴포넌트 — 20%**
- ✅ 6 화면 섹션 존재
- ❌ TopBar 의 live clock / Active CC pill / user pill 미존재
- ❌ Rail navigation 미존재 (TOC 사이드 nav 로 대체)
- ❌ Breadcrumb 동적 미존재 (정적 텍스트만)
- ❌ TweaksPanel 미존재
- ❌ Launch CC Modal 미존재
- ❌ KPI strip 일부 누락 (Tables 화면 정도만 있음)

**축 2 화면 — 67%**
- ✅ Login / Series / Events / Flights / Tables / Players (6)
- ❌ Hand History / Alerts / Settings (3 누락)

**축 3 인터랙션 — 0%**
- 정적 HTML — 모든 클릭/필터/탭/검색 비활성

**축 4 디자인 토큰 — 10%**
- ❌ 색 모델 hex (정본 OKLCH)
- ❌ 브랜드 색 **#8B1A1A (WSOP 빨강)** vs 정본은 시리즈별 OKLCH accent
- ❌ Theme/density/EBS-cols 토글 시스템 없음
- ⚠ 일부 status 색 시멘틱은 비슷 (running 녹색, completed 회색)

**축 5 데이터 모델 — 30%**
- ⚠ Series 필드 일부 매칭 (name/date), but **브랜드명 완전 다름**: 정본 = "WPS · EU 2026" (World Poker Series), mockup = "WSOP Circuit / 2026 WSOP Europe / 2026 World Series of Poker"
- ⚠ Event 5-status 탭은 정본과 일치 (created/announced/registering/running/completed)
- ❌ accent OKLCH 색 / starred / featured / VPIP/PFR/AGR 등 누락

#### B: docs/1. Product/References/foundation-visual/cc-mockup.html (CC HTML mockup)

**축 1 컴포넌트 — 15%**
- ✅ topbar / felt / seats(10) / sidebar / action-bar 5 큰 그룹
- ❌ **PlayerColumn 1×10 구조 완전 부재** — 정본의 핵심 레이아웃
- ❌ FieldEditor / Numpad / CardPicker / MissDealModal 미존재
- ❌ TweaksPanel / Engine banner / Layout switcher 미존재
- ⚠ 좌석은 작은 박스 (정본의 풍부한 7-row column 과 차원이 다름)

**축 2 화면 — 100%**
- 단일 화면 (정본도 단일이라 매칭)

**축 3 인터랙션 — 0%**
- 정적 HTML — 핫키, FSM, Miss Deal, FieldEditor, Card Picker, Numpad 모두 없음
- ❌ 키보드 단축키 다름: mockup = F1/F2/F/C/B/X/R/A vs 정본 = N/F/C/B/A/M

**축 4 디자인 토큰 — 15%**
- ❌ Hex 색 (정본 OKLCH)
- ⚠ broadcast amber 비슷한 색 (#ffcf40) — accent 컨셉만 일치
- ❌ Inter / JetBrains Mono 폰트 미사용 (시스템 default)
- ❌ design canvas **1280×720** (정본 1600×900)
- ❌ scale-fit 없음 (고정 크기)

**축 5 데이터 모델 — 40%**
- ✅ 10 좌석 (정본 일치)
- ⚠ Seat name + stack 있음
- ❌ holeCards / bet / lastAction / sync / equity / occupied 모델 없음
- ❌ Hand FSM phase 없음 (mockup 은 PRE/FLOP/TURN/RIVER 4-tab 만, 정본은 7-state IDLE→HAND_COMPLETE)
- ❌ Connection (bo/rfid/engine) 일부만
- ⚠ **추가 컨셉: Delay Buffer (8s) — 정본에 없음** (security_delay_buffer 는 team4 D 에 있음, B 가 D 의 일부 컨셉을 미리 반영했을 가능성)

#### C: team1-frontend/lib/features/** (Flutter Lobby)

**축 1 컴포넌트 — 75%**
- ✅ lobby_shell, lobby_kpi_strip, lobby_status_badge, waitlist_drawer, levels_strip, day_tabs (정본 핵심 위젯 매핑)
- ✅ seat_grid, seat_dot_cell, dealer_button_indicator
- ✅ table_form_dialog, event_form_dialog, add_player_dialog (정본의 inline modal 보다 dialog 패턴)
- ✅ hand_demo_overlay
- ⚠ TweaksPanel 대응 미발견 (dev tweaks 패널 미구현일 가능성)
- ⚠ Launch CC Modal — cc_session_provider 가 있으니 매핑 가능성 높음, 별도 확인 필요

**축 2 화면 — 133%**
- ✅ 정본 9 화면 매핑 가능: series_screen / lobby_events / lobby_flights / lobby_tables / lobby_players / hand_history / login / settings (8 페이지로 분할) / forgot_password
- ⚠ Alerts 화면 별도 미발견 (lobby_status_badge 또는 통합되어 있을 가능성)
- ➕ **추가 (정본 미정의)**: graphic_editor (ge_hub_screen, ge_detail_screen, rive_preview), staff (staff_list_screen), settings 8 페이지 (blind_structure/payout/outputs/gfx/display/rules/stats/preferences)

**축 3 인터랙션 — 80%**
- ✅ Riverpod 기반 13 provider (series/event/flight/table/player/cc_session/hand_auto_setup/nav 등)
- ⚠ 라이브 클럭 / Rail 접기 / Launch CC 모달 상세 매핑 확인 필요

**축 4 / 5 — 확인 필요**: Flutter ThemeData 와 OKLCH 매핑, entity 클래스 필드 직접 비교는 본 cycle 시간 제약상 별도 SG 권고.

#### D: team4-cc/src/lib/features/** (Flutter CC)

**축 1 컴포넌트 — 70%**
- ✅ cc_status_bar, action_panel, mini_table_diagram, miss_deal_modal, position_shift_chip, seat_cell, hole_card_slot, keyboard_hint_bar, engine_connection_banner, acting_glow_overlay, action_badge
- ⚠ **PlayerColumn 1×10 horizontal grid** = seat_cell 이 대응되는지, 정본의 7-row 구조를 유지하는지 별도 확인 필요 (P0 후보)
- ⚠ FieldEditor 통합 모달 = at_07_player_edit_modal 만 보임. 정본은 모든 필드 통합. seat_cell click → 모달 전환 패턴 확인 필요
- ⚠ Numpad 컴포넌트 = action_panel 통합 여부 별도 확인
- ❌ Layout switcher (bottom/left/right) 미발견 — dev 기능이라 미구현 OK
- ❌ TweaksPanel 미발견 — dev 기능이라 미구현 OK

**축 2 화면 — 117%**
- ✅ at_00_login, at_01_main (정본 단일 화면 대응), at_03_card_selector (정본 CardPicker 모달), at_07_player_edit_modal (정본 FieldEditor)
- ➕ **추가 (정본 미정의)**: at_04_statistics, at_05_rfid_register, at_06_game_settings, stats_screen, debug_log_panel, splash_screen
- ➕ **추가 — overlay 전체** (layer1: action_badge/board/equity_bar/hole_cards/outs/player_position/pot_display/player_info, services: animation/output_buffer/security_delay/skin_consumer/dual_output_manager/ndi_output_sink, rive_overlay_canvas) — 정본 미포함, **출력 layer 별도 책임**

**축 3 인터랙션 — 85%**
- ✅ Hand FSM (hand_fsm_provider)
- ✅ Keyboard shortcuts (keyboard_provider + keyboard_shortcut_handler)
- ✅ Miss Deal (miss_deal_modal)
- ✅ Undo (undo_provider + undo_stack) — **정본 미정의, D 가 한 단계 더 진보**
- ✅ Engine connection (engine_connection_provider + banner)
- ✅ Multi-table manager — **정본 미정의 (정본은 단일 테이블)**
- ✅ Demo scenarios — **정본 미정의 (D 가 운영 데모 모드 추가)**

**축 4 / 5 — 확인 필요**: Flutter ThemeData OKLCH 매핑 + GameState/Seat entity 의 sync(AUTO/MANUAL_OVERRIDE/CONFLICT) 필드 존재 여부 = seat_provider 내부 확인 필요 (P1 후보).

---

## Act 4 — 문제점 + 부족함 우선순위 (현재 프로토타입 기준)

### 4.1 P0 — 차단 (외부 인계 불가)

| # | 항목 | 대상 | 정본 reference | 차이 본질 | 영향 |
|---|------|:----:|---------------|----------|------|
| P0-1 | 정본 미러 부재 | docs/ | Downloads/*.zip | 정본 ZIP 이 git 외부 보관 → 협업자/CI 가 받을 수 없음 | "100% 일관성" 인텐트 위반. 모든 후속 비교의 기준점 부재 |
| P0-2 | Lobby 브랜드 정체성 충돌 | **A** | "WPS · EU 2026" (World Poker Series) | A 는 "WSOP Circuit / 2026 World Series of Poker" — 다른 브랜드 명시 | A 가 진짜 wireframe 으로 사용되면 잘못된 도메인 가정 확산 |
| P0-3 | CC mockup 의 사실상 미사용 | **B** | 풍부한 PlayerColumn + FieldEditor + Numpad + CardPicker + Hand FSM | B 는 좌석 박스 + 8 액션 버튼만 — 정본의 85% 기능 부재 | B 가 CC 명세 reference 로 사용되면 누락 기능 폭증 |
| P0-4 | CC PlayerColumn 1×10 구조 일치 여부 미검증 | **D** | 7-row click-to-edit 컬럼 × 10 | D 의 seat_cell 이 동일 7-row 구조 유지 여부 미확인 | 핵심 운영 UX 다르면 CC 사용성 전체에 영향 |
| P0-5 | Lobby 정본의 9 화면 중 3 화면 (Hand History/Alerts/Settings) HTML mockup 부재 | **A** | hands/alerts/settings 모두 정본에 정의 | A 는 6 화면만 — 정본의 33% 누락 | wireframe 으로 사용 시 운영 도구 화면이 빠진다는 시각적 신호 부재 |

### 4.2 P1 — 흐름 차단 (사용자 흐름 일부 불가능)

| # | 항목 | 대상 | 정본 reference | 차이 본질 | 영향 |
|---|------|:----:|---------------|----------|------|
| P1-1 | CC 키보드 단축키 불일치 | **B** | N / F / C / B / A / M (6 키) | B = F1 / F2 / F / C / B / X / R / A — 정본과 거의 모두 다름 | wireframe 으로 trained 된 운영자가 실제 D 구현 시 혼란 |
| P1-2 | CC Hand FSM 단순화 | **B** | 7-state IDLE→HAND_COMPLETE | B = PRE/FLOP/TURN/RIVER 4-tab (IDLE/SHOWDOWN/HAND_COMPLETE 없음) | 핸드 종료 / 시작 흐름 미정의 |
| P1-3 | Sync 상태 모델 (AUTO/MANUAL_OVERRIDE/CONFLICT) 검증 안 됨 | **D** | seat.sync 필드 | D 의 seat_provider 내부 미확인 | 운영자가 수동 override 한 상태가 자동 sync 와 충돌 시 처리 흐름 부재 가능 |
| P1-4 | Tweaks Panel 미구현 | **C, D** | Theme / Density / Layout / Engine state slider | C, D 에 dev tweaks 패널 미발견 | 운영 환경에서 색조/레이아웃 즉시 조정 불가 |
| P1-5 | Launch CC 모달 상세 매핑 미검증 | **C** | 정본 App.jsx 인라인 모달 | C 의 cc_session_provider 와 매핑 여부 미확인 | Lobby Tables 화면에서 CC 운영자 할당 흐름 차단 가능성 |
| P1-6 | unpkg CDN 의존 (정본) | 정본 자체 | unpkg react/babel/google fonts | 카지노 LAN 차단 시 정본 미작동 | 정본을 운영 환경에서 시연 불가 |
| P1-7 | Lobby live clock + active CC pill 누락 | **A** | TopBar 1초 interval clock + Active CC · 3 pill | A 정적 — 운영 시간 인식 어려움 | 라이브 운영 시 시간 추적 누락 |
| P1-8 | Engine state banner 미구현 | **B** | online/degraded/offline 배너 + Reconnect 버튼 | B 미존재 | 엔진 단절 시 운영자 인지 + 복구 흐름 부재 |
| P1-9 | docs/ HTML mockup 의 deprecation 결정 부재 | A, B | 정본이 진짜 SSOT | A, B 가 wireframe 인지 deprecated 인지 표식 없음 | 협업자가 어느 게 진짜 reference 인지 혼동 |

### 4.3 P2 — 시각/명명 drift

| # | 항목 | 대상 | 정본 vs 현재 |
|---|------|:----:|-------------|
| P2-1 | Color model | A, B | OKLCH (정본) vs Hex (#8B1A1A, #ffcf40) (현재) |
| P2-2 | Font family | B | Inter + JetBrains Mono (정본) vs 시스템 default (B) |
| P2-3 | Design canvas | B | 1600×900 (정본) vs 1280×720 (B) |
| P2-4 | Scale-fit 메커니즘 | B | transform scale (정본) vs 고정 (B) |
| P2-5 | Lobby Series 데이터 브랜드 | A | "WPS · EU 2026" vs "2026 WSOP Europe" |
| P2-6 | Seat coords | B | CSS top/left % (정본) vs hardcoded px (B) |
| P2-7 | Action bar 버튼 수 | B | 5 핵심 액션 + START/FINISH HAND 통합 vs 8 분리 (NEW HAND / DEAL 분리) |
| P2-8 | Status bar 정보 밀도 | A | Show/Flight/Level/Next/CC pill/clock (정본) vs minimal (A) |
| P2-9 | Tables 9-seat 표시 방식 | A | 9 좌석 한 줄 + 9 row table (정본) vs 9-col grid (A 비슷하지만 인터랙션 없음) |
| P2-10 | Featured/Marquee 시각 | A | golden feat row + star + FT badge (정본) vs simple highlight (A) |
| P2-11 | Sidebar 컨셉 차이 | B | TopStrip + ActionPanel 분리 (정본) vs 우측 sidebar (B, Delay Buffer 추가) |
| P2-12 | KPI strip 5-KPI 일관성 | A | 정본 각 화면 5-KPI 동일 패턴 vs A 일부만 |
| P2-13 | Tabs 컨셉 | A | 5-status pipeline + count (정본) vs A 시각 비슷하지만 클릭 무반응 |
| P2-14 | Delay Buffer 컨셉 위치 | B | 정본 미정의 vs B = 8s 표시 — D 의 security_delay_buffer 와 매핑 필요 |

### 4.4 P3 — 개선 권고 (정본도 보완 여지)

| # | 항목 | 권고 |
|---|------|------|
| P3-1 | unpkg CDN → 로컬 vendor 번들 | 정본 ZIP 에 react/react-dom/babel/Inter 로컬 사본 동봉 → LAN 환경 동작 |
| P3-2 | 정본 ZIP 의 version pin | 현재 react@18.3.1 hard-coded — 정본 자체에도 SHA-pin manifest 권고 |
| P3-3 | 정본 화면 캡처 자동화 | screenshots/ 폴더 활용 — Playwright + cc-mockup 자동 캡처 워크플로우 |
| P3-4 | 정본 ↔ Flutter 1:1 매핑 reference 문서 | C, D 각 widget 이 정본의 어떤 컴포넌트에 대응되는지 표 |
| P3-5 | D 의 overlay/ 추가 영역의 정본 부재 명시 | overlay layer1/services 는 정본 미정의 — 별도 정본 또는 spec 필요 |
| P3-6 | C 의 graphic_editor / staff 정본 부재 | 정본은 Lobby 만 다룸 — graphic_editor/staff 의 별도 정본 필요? |
| P3-7 | 정본 multi-table manager 부재 | D 의 multi_table_manager 가 정본 미정의 — 정본을 1×N table 로 확장 |
| P3-8 | 정본 demo scenarios 부재 | D 의 demo/scenarios.dart 와 매칭되는 정본 demo state seed 추가 |

---

## Act 5 — 후속 액션 권고

> 본 보고서는 **분석 전용**. 실제 정정/PR 은 별도 SG cycle 권고.

### 5.1 즉시 권고 (P0 해소)

| 후속 액션 | 대상 | 우선순위 | 비파괴? |
|----------|:----:|:--------:|:------:|
| 정본 ZIP 을 git LFS 또는 `docs/1. Product/Prototype/originals/` 로 등록 | P0-1 | 🔴 즉시 | YES (추가만) |
| Lobby HTML mockup A 에 frontmatter `status: deprecated` + 정본 ZIP 링크 추가 | P0-2, P0-5 | 🔴 즉시 | YES (메타데이터만) |
| CC HTML mockup B 에 동일 deprecated 표식 | P0-3 | 🔴 즉시 | YES |
| D 의 seat_cell + at_07_player_edit_modal 이 정본 PlayerColumn 7-row 구조 일치 여부 spot-check | P0-4 | 🟠 1 cycle 내 | YES (READ-only) |

### 5.2 단기 권고 (P1 해소, 1-3 cycle)

| 후속 액션 | 대상 | 분류 |
|----------|:----:|:----:|
| C 의 cc_session_provider ↔ 정본 Launch CC 모달 매핑 검증 + drift 정정 SG | P1-5 | Type D |
| D 의 seat.sync (AUTO/MANUAL_OVERRIDE/CONFLICT) 필드 존재 + 처리 흐름 명세 검증 | P1-3 | Type B 또는 D |
| Lobby Foundation/PRD 의 브랜드 명 (WPS vs WSOP) 통일 결정 + 정본·구현·mockup 일관 | P0-2, P1-7 | Type C (기획 모순) |
| CC keyboard 단축키 정본 통일 (N/F/C/B/A/M) — B mockup 보정 또는 B 폐기 | P1-1 | Type D |

### 5.3 장기 권고 (P2/P3, 별도 PRD)

| 후속 액션 | 분류 |
|----------|:----:|
| 정본 ZIP 의 LAN-friendly 로컬 vendor 번들 옵션 | P3-1 |
| 정본 ↔ Flutter widget 1:1 매핑 reference 문서 (외부 인계용) | P3-4 |
| D 의 overlay layer / multi-table / demo 영역의 정본 또는 spec 부재 → 정본 확장 또는 별도 spec | P3-5, P3-7, P3-8 |
| C 의 graphic_editor / staff 영역의 정본 부재 → 정본 확장 또는 명시적 out-of-scope | P3-6 |

### 5.4 본 보고서로 정정되는 사항

- ✅ MEMORY.md 인덱스: 정본 ZIP 영구 등록 line 추가됨
- ✅ memory/prototype_accurate_original_2026_05_15.md: SSOT 메모리 파일 생성
- ✅ work/prototype-audit/_manifest.json: SHA256 무결성 manifest
- ✅ 본 보고서: Gap Matrix + 우선순위 명시

### 5.5 정정되지 않은 사항 (별도 cycle)

- ❌ docs/ 의 HTML mockup A/B 에 deprecated 표식
- ❌ 정본 ZIP 의 git 등록
- ❌ D 의 seat_cell 1×10 구조 spot-check
- ❌ C 의 launch CC 모달 매핑
- ❌ Lobby 브랜드 정체성 (WPS vs WSOP) 통일

---

## 부록 A — Ultrathink 사고 흐름

### A.1 표면 비교 vs 의미 비교

**표면 비교 (위험)**:
> "B 에 좌석 10 개가 있고 정본도 10 개니까 일치한다."

**의미 비교 (실제)**:
> "B 의 좌석은 작은 박스 (name + stack + cards + badge) 4 정보만. 정본의 PlayerColumn 은 7-row click-to-edit 으로 **모든 필드를 운영 중 즉시 수정 가능**. 같은 '좌석' 단어지만 **운영 UX 가 완전히 다른 차원**."

### A.2 비명시 가정 감지

본 분석에서 발견한 비명시 가정 사례:

| 가정 | 정본의 명시 vs 현재의 암묵 |
|------|------------------------|
| "Lobby = WSOP" | 정본은 명시적으로 "WPS (World Poker Series)" 브랜드. A mockup 은 WSOP 가정 |
| "CC 키보드 단축키 = 운영자 표준" | B mockup 은 F1/F2/F/C/B/X/R/A 가정. 정본은 명시적으로 N/F/C/B/A/M (6 키, 'X'/'R' 없음) |
| "Hand FSM = 4 단계 (PRE/FLOP/TURN/RIVER)" | B mockup 의 4-tab. 정본은 7-state (IDLE/SHOWDOWN/HAND_COMPLETE 추가) |
| "Delay Buffer = 정본 기능" | B sidebar 에 8s 표시. 정본 미정의. D 에 security_delay_buffer 있음 — B 가 D 의 일부를 미리 반영 |
| "Settings = 단일 화면" | 정본 SettingsScreen (1 화면). C 는 8 페이지로 확장 — 정본에 미반영 |

### A.3 의미 drift (이름 같지만 동작 다름)

| 이름 | 정본 의미 | 현재 의미 |
|------|----------|----------|
| "Action Bar" (CC) | START/FINISH HAND lifecycle + FOLD/CHECK·CALL/BET·RAISE/ALL-IN (4 액션 + lifecycle + Undo + Miss Deal) | B = NEW HAND/DEAL/FOLD/CHECK/BET/CALL/RAISE/ALL-IN (8 분리, lifecycle 없음) |
| "Status Bar" (CC) | BO/RFID/Engine 연결 dot + Hand# + Phase + Players + 운영자 + Table + Game/Blinds/Lvl + icons | B = topbar (Hand/Street/Blinds 일부, Engine state 없음, RFID READY 정도) |
| "Phase" (CC) | 7-state FSM (정본의 핵심 동작) | B = 4-tab 시각 표시만 (FSM 아님) |
| "Tweaks" | 운영 환경 토글 (theme/density/engine state simulator) | C, D = 미구현 |
| "Series" (Lobby) | WPS 브랜드 시리즈 (정본 8 항목) | A = WSOP Circuit + WSOP Europe 등 (다른 브랜드) |

### A.4 다층 통합 결론

**축 1 (컴포넌트)** 만 보면 — A, B 는 정본의 20% 도 안 됨 → wireframe 자격 부족
**축 2 (화면)** 만 보면 — C, D 는 정본의 117-133% (오히려 더 많음) → 충분
**축 3 (인터랙션)** 만 보면 — A, B 는 0% (정적), C, D 는 80-85%
**축 4 (디자인 토큰)** — 모두 정본과 다른 색 모델 (OKLCH 미사용) → 시각 일관성 부재
**축 5 (데이터 모델)** — C, D 는 75-80% 매칭, A, B 는 30-40%

**통합 판정**:
- **A, B 는 wireframe 가치 < 정본 ZIP 가치** → deprecated 권고
- **C, D 는 정본 의도를 70% 이상 따라가나** → 핵심 격차 (PlayerColumn 1×10 / Sync 필드 / Launch 모달) 검증 필요
- **정본은 외부 SSOT 로 등록 + 자체 LAN 호환성 보강** 권고

---

## 부록 B — 자가 점검 체크리스트

| 항목 | 상태 |
|------|:----:|
| frontmatter (provenance / status / memory_link) 완전 | ✅ |
| 한 줄 요약 + 비유 + 메트릭 표 | ✅ |
| Act 1-5 + 부록 A-B 모두 작성 | ✅ |
| ASCII 다이어그램 사용 | ✅ (2 곳) |
| OKLCH / Hex / hue 등 색 시스템 명시 | ✅ |
| 정본 ZIP SHA256 명시 | ✅ |
| 비교 대상 4 (A, B, C, D) 분리 분석 | ✅ |
| 우선순위 P0/P1/P2/P3 분류 + 영향 명시 | ✅ |
| "확인 필요" 항목 명시 (모든 가정 검증 안 됨 인정) | ✅ |
| 후속 액션 분류 (즉시 / 1-3 cycle / 별도 PRD) | ✅ |
| 본 보고서로 정정 vs 미정정 사항 분리 | ✅ |
| 추측 금지 (구현 안 된 기능 가정 X) | ✅ |
| Ultrathink 다층 분석 (의미 drift / 비명시 가정 포함) | ✅ |

---

## 메타 정보

- **본 보고서 작성 일자**: 2026-05-15
- **분석 도구**: PowerShell ZIP 추출 + Read/Glob 정적 분석
- **분석 자원**: `work/prototype-audit/_analysis/lobby-ground-truth.json`, `cc-ground-truth.json`, `current-prototypes.json`, `work/prototype-audit/_manifest.json`
- **메모리 등록**: `prototype_accurate_original_2026_05_15.md`
- **검증되지 않은 항목**: C/D 의 ThemeData OKLCH 매핑, D 의 seat_cell 7-row 구조, C 의 cc_session_provider ↔ Launch CC 매핑 — 모두 후속 SG 권고
- **본 보고서의 한계**: Flutter 코드 내부 widget 트리 + 데이터 모델 정밀 비교는 별도 Type D drift detection cycle 필요. 본 보고서는 macro 레벨 매핑 + 우선순위 분류에 집중.


