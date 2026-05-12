---
id: SG-037
title: "기획 공백: CC PRD ↔ HTML mockup state model drift (TWEAKS / seats.sync / 1600×900 canvas 등)"
type: spec_gap
status: IN_PROGRESS
owner: conductor
created: 2026-05-12
affects_chapter:
  - docs/1. Product/Command_Center.md §Ch.11 (디자인 톤) + §Ch.12.1 (화면 크기) + §Ch.15 (V7 TweaksPanel)
  - docs/2. Development/2.4 Command Center/Command_Center_UI/Overview.md §3 (레이아웃)
protocol: Spec_Gap_Triage
---

# SG-037 — CC PRD ↔ HTML mockup state model drift

## 공백 서술

`docs/mockups/EBS Command Center/` 의 13 개 React 시안 소스 파일이 보유한 **운영 상태 모델 / 디자인 토큰 / 캔버스 정책** 약 11 개 항목이 `Command_Center.md` v4.0.0 (2026-05-07) 에 **미문서화 또는 모순 기록** 되어 있다. 본 PRD 는 mockup 을 "React 시안" 으로 인용했으나 다음의 운영 단위 상태값들을 챕터 본문에 끌어오지 않았다.

| # | 항목 | mockup 위치 | PRD 현황 | gap 유형 |
|:-:|------|------------|---------|---------|
| 1 | `TWEAKS` 객체 (accentHue / feltHue / engineState / layout / showEquity / showKbdHints / showBetChips) | `App.jsx:4-12`, `data.js:54-58` | Ch.15 V7 "TweaksPanel (debug only)" 한 줄 | Type B (공백) |
| 2 | `seats[].sync` 필드 (`"AUTO"｜"MANUAL_OVERRIDE"｜"CONFLICT"` + ✋/⚠ 아이콘 렌더링) | `data.js:42-51`, `Seat.jsx:26-30` | 언급 없음 | Type B (공백) |
| 3 | `engineState` 3-state UI (online/degraded/offline + Reconnect 배너) | `App.jsx:314-320` | Ch.2.2 dot 색상만, offline mode UI 누락 | Type B (공백) |
| 4 | `NEXT_STREET` phase 전환 맵 + `advanceStreetIfClosed` 자동 진입 로직 | `App.jsx:14, 152-169` | Ch.6 mermaid 흐름도만, 명시 맵/closure 룰 누락 | Type B (공백) |
| 5 | `ctx` 7-필드 액션 가능성 객체 도출 로직 | `App.jsx:98-111` | Ch.5.1 auto-switch 룰 4 개만, 도출 의사코드 누락 | Type B (공백) |
| 6 | 1600×900 고정 디자인 캔버스 + scale-fit | `App.jsx:46-78`, `tokens.css:70-84` | Ch.12.1 "화면 크기 — Auto-fluid 720px+" | Type C (모순) |
| 7 | Design tokens 전체 catalog (oklch 32 token) | `tokens.css:1-54` | Ch.11.1 oklch 표기 3 줄 발췌만 | Type B (공백) |
| 8 | `shiftPosSlot` heads-up 룰 (2 명 = D=SB 동일 좌석) + 3-handed auto chain + SB↔BB overlap 차단 | `FieldEditor.jsx:363-407` | Ch.4.5 화살표 표시만, HU/SB·BB 룰 누락 | Type B (공백) |
| 9 | `FieldEditor` 9 가지 edit kind 카탈로그 (name/stack/bet/pos/lastAction/occupy/addPlayer/flag/seatNo) + COUNTRY_OPTIONS 23 개 | `FieldEditor.jsx:30-104, 3-27` | Ch.4.1 "tap → FieldEditor" 만, kind 분기 미명세 | Type B (공백) |
| 10 | `CardPicker` dealtKeys 룰 (`dealtKeys.has(k) && !isCurrent`) + Legend 3-bucket | `CardPicker.jsx:21-83` | Ch.7.3 "이미 사용된 카드는 disabled" 한 줄 | Type B (공백) |
| 11 | `MissDealModal` 3 stat 표시 + Enter/Esc 매핑 | `MissDealModal.jsx:1-36` | Ch.8.2 단순 호출 언급만 | Type B (공백) |

## 발견 경위

- 사용자 (conductor) 가 2026-05-12 cycle 10 에서 본 PRD 와 mockup 의 불일치를 비판. "mockup 이 정확" — 따라서 PRD 가 mockup 을 따라가야 한다.
- 본 PR (S10-W) 에서 13 개 mockup 파일 (App.jsx, data.js, tokens.css, CardPicker.jsx, Numpad.jsx, MissDealModal.jsx, PlayerColumn.jsx, Seat.jsx, FieldEditor.jsx, tweaks-panel.jsx, MiniDiagram.jsx, app.css, EBS Command Center.html) 정밀 read 후 위 11 개 drift 항목 식별.
- 실패 분류: 10 건 Type B (공백) + 1 건 Type C (모순 — 화면 크기). 빌드/테스트 실패 신호 아닌 *문서 vs 시안 정합 점검* 으로 발견.

## 영향받는 챕터 / 구현

| 챕터 | 결정 비어있는 부분 / 상충 |
|------|--------------------------|
| Command_Center.md §Ch.2.2 (dot 색상) | engineState 3-state 매핑 + Reconnect 배너 UI 누락 |
| Command_Center.md §Ch.4.1 (PlayerColumn 9 행) | seats[].sync 필드 어느 행에 표시할지 미정 + FieldEditor 9 kind 분기 |
| Command_Center.md §Ch.4.5 (Position Shift Arrows) | HU/3-handed/SB·BB overlap 룰 미명세 |
| Command_Center.md §Ch.5.1 (Phase-aware buttons) | ctx 7-필드 도출 로직 미문서 — 외부 개발팀이 자체 도출 시 R4 위반 |
| Command_Center.md §Ch.6 (HandFSM 9-state) | NEXT_STREET 7-state 맵 vs EBS 9-state 의 자동 전환 closure 룰 분리 명시 필요 |
| Command_Center.md §Ch.7.3 (CardPicker) | dealtKeys 룰 "현재 슬롯 자기 자신은 enabled" 명시 누락 |
| Command_Center.md §Ch.8.2 (Miss Deal) | Modal 정확한 stat 3 필드 + Enter/Esc 매핑 누락 |
| Command_Center.md §Ch.11 (디자인 톤) | tokens.css 전체 catalog 미문서 — Flutter 개발팀이 30+ token 을 *추측* 으로 매핑 |
| Command_Center.md §Ch.12.1 (화면 크기) | 모순 — "Auto-fluid 720px+" vs mockup "1600×900 fixed canvas + scale-fit" |
| Command_Center.md §Ch.15 (시각 자산 17 종) | V7 TweaksPanel 의 7 tweak field 와 V18 sync icon (NEW) 누락 |
| Overview.md §3 (레이아웃) | derivative PRD 가 1600×900 캔버스로 갱신되면 정본도 canvas 정책 명시 필요 |

## 결정 방안 후보

| 대안 | 장점 | 단점 | WSOP LIVE 패턴 정렬 |
|------|------|------|---------------------|
| 1. PRD additive — Ch.16 "Mockup State Model 정합" 추가 + Ch.12.1 정정 | v4.0 Reader Panel 합격본 보존, drift 단일 챕터로 격리, 외부 개발팀 신규 챕터만 추가 읽으면 완료 | Ch.16 이 정본보다 깊이 들어가면 SSOT 경계 모호화 | ✅ |
| 2. 전 챕터 in-place 보강 | 본문 흐름 안에서 자연스러운 통합 | v4.0 Reader Panel critic 재실행 필요 | △ |
| 3. 정본 먼저 갱신 + PRD 는 derivative 자동 cascade | 정본 우선 원칙 정합 | 단일 PR scope 초과 | △ |
| 4. SUPERSEDE: mockup 측 수정 | PRD 본문 변경 0 | "mockup 이 정확" 사용자 결정 정면 충돌 | ❌ |

## 결정

- 채택: 대안 1 (PRD additive Ch.16 + Ch.12.1 모순 정정)
- 이유: 사용자가 "mockup 이 정확" 명시 → mockup 측 변경 불가. v4.0 Reader Panel 합격본을 보존하면서 11 개 drift 만 단일 챕터로 격리. 정본 Overview.md §3 cascade 는 별 PR (SG-037-b 후속) 으로 분리. Type C 1 건 (화면 크기) 만 본문 in-place 정정.
- 영향 챕터 업데이트 PR: 본 PR (S10-W cycle 10) — branch `work/s10-w/2026-05-12-cycle-10-product-rename`
- 후속 구현 Backlog 이전: `Implementation/B-CC-MOCKUP-SYNC.md` (Flutter widget tree 정합 — team4 인계)

## 결정 후 follow-up

| 후속 항목 | 담당 stream | 우선순위 |
|----------|------------|:-------:|
| Overview.md §3 정본 cascade (1600×900 canvas + engineState 3-state + seats.sync) | conductor | P1 |
| team4-cc 의 widget inventory 정합 — `cc_engine_state_banner.dart` / `seat_sync_icon.dart` 신규 + `cc_design_canvas.dart` scaler | team4 (S2/S3) | P2 |
| Flutter ThemeData 의 30+ token catalog 매핑 | team4 / designer | P2 |
| TWEAKS panel: production 빌드 제거 vs Admin-only flag 결정 | conductor | P3 |
