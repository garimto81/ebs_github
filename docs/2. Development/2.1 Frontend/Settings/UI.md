---
title: UI
owner: team1
tier: internal
legacy-id: UI-03
last-updated: 2026-04-15
---

# UI-03 Settings — 6탭 와이어프레임

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | Output/Overlay/Game/Statistics 4섹션 레이아웃, 탭 네비게이션, 모달 구조 |
| 2026-04-09 | 6섹션 전면 재설계 | Console PRD v9.7 기반 Outputs/GFX/Display/Rules/Stats/Preferences |
| 2026-04-10 | critic revision | §1.1 Ownership & Boundary 소섹션 추가 (Team 1 / Team 4 경계, 글로벌 설정 원칙), Rules 탭에 Blind 편집 범위 외 주석, ConfigChanged ASCII 데이터 흐름 추가 |
| 2026-04-10 | CCR-011/025 후속 반영 | Graphic Editor 소유권 Team 1 이관(CCR-011 APPLIED) → §1.1 GFX 탭 책임 확장 (rive-js 프리뷰 + GE 허브 연동), Team 4 는 Overlay 렌더링 소비자로 재정의, CCR-025(BS-03-02-gfx 시각 asset 메타) 경계 반영 |
| 2026-04-10 | UI-04 cross-link | Rules 탭 Blind 범위 외 주석에 GEM-01~25 필드 전체는 UI-04-graphic-editor.md §5 참조 1줄 추가 |

---

## 개요

Settings는 Lobby 웹 내 **6탭 페이지**로, Console의 5탭(Outputs/GFX/Display/Rules/Stats) + Preferences 다이얼로그를 통합한 구조. 오버레이 출력 파이프라인, 그래픽 배치, 수치 표시 형식, 게임 규칙, 통계/리더보드, 테이블 인증/진단/내보내기를 관리한다. Admin 전용이며, Lobby 또는 CC 어디서든 [Settings ⚙] 버튼으로 접근한다.

> 참조: BS-03-00-overview, BS-00 §1

---

## 1.1 Ownership & Boundary

Team 1 의 Settings 범위(+ Graphic Editor 허브)와 Team 4 Overlay 렌더링 경계, 그리고 "글로벌 설정" 원칙을 명확히 한다. CCR-011(GE 이관) · CCR-025(BS-03-02 확장) APPLIED 반영.

### 팀 경계

| 탭 | Team 1 책임 | Team 4 책임 |
|----|-------------|-------------|
| **Outputs** | 전체 (설정 값 CRUD + 폼 UI) | — |
| **GFX** | 전체 (Layout/Card & Player/Animation 옵션 CRUD + **rive-js 프리뷰** + Graphic Editor 허브 연동) | Overlay 실제 렌더링 소비자, BS-03-02-gfx 시각 asset 메타 정의 제공 (CCR-025) |
| **Display** | 설정 값 저장/편집 폼 (Blinds/Precision/Mode 옵션) | 오버레이 상의 실제 수치 렌더링 결과 (BS-07) |
| **Rules** | 전체 (Game Rules, Player Display) | — |
| **Stats** | 전체 (Equity/Leaderboard/Strip 옵션 CRUD) | 통계 오버레이 렌더링 결과 (BS-07) |
| **Preferences** | 전체 (Table 인증, Diagnostics, Export) | — |

**요약 (CCR-011 APPLIED 후 갱신)**:

- Team 1 은 **"어떤 값을 저장할지" + "어떻게 Import/Activate 할지"** 를 담당한다. Quasar(Vue 3) + TypeScript 폼 컴포넌트로 Settings CRUD 를 구현하고, `@rive-app/canvas` 로 GFX 프리뷰를 렌더하며, `.gfskin` 허브(`/lobby/graphic-editor`)에서 ZIP Import·메타데이터 편집·Activate·`skin_updated` WS broadcast 를 관장한다. `PUT /configs` 와 `PUT /api/v1/skins/{id}/activate` 가 주 엔드포인트.
- Team 4 는 **"값/asset 이 방송에서 어떻게 렌더링되는지"** 를 담당한다. Flutter+Rive Overlay(BS-07) 가 `skin_updated` WS 이벤트를 소비하여 리렌더하고, BS-03-02-gfx 의 시각 asset 메타(CCR-025) 를 제공한다. **Team 4 는 Graphic Editor UI 를 더 이상 소유하지 않는다.**
- **Rive 내부 편집은 Rive 공식 에디터(외부)** 가 담당한다. Transform/keyframe/color adjust 는 Team 1 / Team 4 모두 out-of-scope. Designer 는 Rive 에서 `.riv` 완성 → `.gfskin` ZIP 패키징 → Team 1 허브 업로드 순서를 따른다.

### 글로벌 설정 원칙 (CRITICAL)

**모든 Settings 값은 글로벌이다. 테이블별로 다른 값을 가지지 않는다.**

- 한 번 저장된 설정은 **모든 CC 인스턴스 / 모든 Table** 에 동일하게 적용된다.
- 테이블별 오버라이드 UI 를 만들지 않는다. 운영자가 "Table 3 만 Chipcount Mode 를 BB 로" 같은 설정을 원한다면, 이는 Settings 가 아니라 Table Management(Lobby 화면 4) 영역이며 현재 범위 밖이다.
- 이 원칙의 근거는 메모리 `feedback_settings_global.md` — "Settings 는 글로벌(모든 CC 동일), 테이블별 X, Table Mgmt 와 별개 설계".
- URL 경로가 `/settings/:tableId` 형식을 쓰더라도 `:tableId` 는 현재 어떤 테이블 컨텍스트에서 Settings 에 진입했는지를 나타내는 트래킹용이며, 저장 경로에는 반영되지 않는다.

### ConfigChanged 이벤트 데이터 흐름

Settings 변경 → BO 저장 → 모든 CC 브로드캐스트 → 다음 핸드부터 적용.

```
Admin UI (Team 1, Quasar)
  │
  │  PUT /configs  (변경된 탭 + 필드만)
  ▼
BO (Team 2, FastAPI)
  │
  │  1. DB update (configs 테이블)
  │  2. broadcast ConfigChanged(WS)
  ▼
WS ws://host/ws/cc  (모든 CC 구독)
  │
  ├──▶ CC #1 (Team 4, Flutter)
  ├──▶ CC #2 (Team 4, Flutter)
  └──▶ CC #N (Team 4, Flutter)
         │
         │  핸드 진행 중이면 버퍼링
         ▼
       다음 핸드 시작 시 적용
       (CONFIRM 분류 필드)
       또는 즉시 적용 (FREE 분류)
```

핵심 규칙:

- BO 는 변경된 설정만 DB 에 커밋한다 (탭 단위 전체 덮어쓰기 금지).
- `ConfigChanged` 페이로드에는 **변경된 key/value 쌍만** 포함한다. CC 가 전체 설정을 재로드하지 않아도 된다.
- CC 는 현재 핸드 종료 시점까지 변경을 버퍼링한다. IDLE 상태이면 즉시 적용한다.
- Preferences 탭(Table Name/Password 등) 은 예외적으로 즉시 적용된다. 해당 필드들은 핸드 진행 로직에 영향을 주지 않기 때문.

---

## 페이지 구조

Settings는 Lobby 내 독립 페이지(`/settings/:tableId`)로 렌더링된다.

```
+------------------------------------------------------------------+
| Settings                                                   [X]   |
| +----------+-------+---------+-------+-------+--------------+    |
| | Outputs  |  GFX  | Display | Rules | Stats | Preferences  |    |
| +----------+-------+---------+-------+-------+--------------+    |
|                                                                  |
|  (선택된 탭의 콘텐츠 영역)                                       |
|                                                                  |
|                                                                  |
| [Reset to Default]                      [Cancel]  [Save]         |
+------------------------------------------------------------------+
```

### 페이지 공통 요소

| 요소 | 동작 |
|------|------|
| [X] | 페이지 닫기 (미저장 변경 있으면 확인) |
| 6탭 바 | Outputs / GFX / Display / Rules / Stats / Preferences |
| [Reset to Default] | 해당 탭 기본값 초기화 (확인 필수) |
| [Cancel] | 변경 폐기, 마지막 저장 상태로 복원 |
| [Save] | BO DB 저장, `ConfigChanged` 발행 |

### 변경 전파

| CC 상태 | 적용 시점 |
|--------|:---------:|
| IDLE (핸드 미진행) | 즉시 |
| 핸드 진행 중 | 다음 핸드 시작 시 (CONFIRM 분류) |

> Preferences 탭은 예외: 즉시 적용 (Table Name/Password만 Update 버튼 커밋)

---

## 탭 1: Outputs

송출 파이프라인 — 해상도, 프레임레이트, NDI/RTMP/SRT/DIRECT, Fill & Key.

```
+------------------------------------------------------------------+
| [Outputs]  GFX  Display  Rules  Stats  Preferences               |
+------------------------------------------------------------------+
|                                                                  |
| * Resolution                                                     |
| +------------------+------------------+------------------+       |
| | Video Size       | Frame Rate       | 9:16 Vertical    |       |
| | [1080p       v]  | [60fps       v]  | [Switch]         |       |
| +------------------+------------------+------------------+       |
|                                                                  |
| * Live Pipeline                                                  |
| +---------------+---------------+---------------+----------+     |
| | NDI Output    | RTMP Stream   | SRT Output    | DIRECT   |     |
| | [Switch]      | [Switch]      | [Switch]      | [Switch] |     |
| | (inline form) | (inline form) | (inline form) | (inline) |     |
| +---------------+---------------+---------------+----------+     |
|                                                                  |
| * Output Mode                                                    |
| +------------------+------------------+------------------+       |
| | Fill & Key       | Alpha / Luma     | Invert Key       |       |
| | [Switch]         | [RadioGroup]     | [Switch]         |       |
| +------------------+------------------+------------------+       |
|                                                                  |
+------------------------------------------------------------------+
```

### 구성 요소 (13 컨트롤)

| 서브그룹 | 요소 | 타입 | 바인딩 |
|---------|------|------|--------|
| Resolution | Video Size | Select | `output.video_size` (720p/1080p/4K) |
| Resolution | 9:16 Vertical | Switch | `output.vertical_mode` |
| Resolution | Frame Rate | Select + NumberInput | `output.frame_rate` (24/25/30/50/60 + 수동 1~120) |
| Live Pipeline | NDI Output | Switch + inline form | `output.ndi_enabled` |
| Live Pipeline | RTMP Stream | Switch + inline form | `output.rtmp_enabled` |
| Live Pipeline | SRT Output | Switch + inline form | `output.srt_enabled` |
| Live Pipeline | DIRECT Output | Switch + inline form | `output.direct_enabled` |
| Output Mode | Fill & Key Output | Switch | `output.fill_key_enabled` |
| Output Mode | Alpha Channel | RadioGroup | `output.key_type` (alpha) |
| Output Mode | Luma Key | RadioGroup | `output.key_type` (luma) |
| Output Mode | Invert Key | Switch | `output.invert_key` |

> NDI/RTMP/SRT/DIRECT 토글 ON 시 프로토콜별 설정 폼이 인라인 확장. 상세: BS-03-01

---

## 탭 2: GFX

그래픽 배치, 카드 공개/폴드, 애니메이션 + Skin Editor 진입.

```
+------------------------------------------------------------------+
| Outputs  [GFX]  Display  Rules  Stats  Preferences               |
+------------------------------------------------------------------+
|                                                                  |
| * Layout                                                         |
| +------------+------------+--------+--------+--------+--------+  |
| | Board      | Player     | X      | Top    | Bot    | LB     |  |
| | Position   | Layout     | Margin | Margin | Margin | Pos    |  |
| | [Select v] | [Select v] | [Sldr] | [Sldr] | [Sldr] | [Sel v]|  |
| +------------+------------+--------+--------+--------+--------+  |
|                                                                  |
| * Card & Player                                                  |
| +---------------+---------------+---------------+-------------+  |
| | Reveal        | How to Show   | Reveal Cards  | Show        |  |
| | Players       | Fold          |               | Leaderboard |  |
| | [Select v]    | [Select v]    | [Select v]    | [Switch]    |  |
| +---------------+---------------+---------------+-------------+  |
|                                                                  |
| * Animation                                                      |
| +---------------+---------------+---------------+-------------+  |
| | Transition In | Transition    | Indent Action | Bounce      |  |
| | [Select v]    | Out           | Player        | Action      |  |
| | [Slider 0.3s] | [Select v]   | [Switch]      | Player      |  |
| |               | [Slider 0.3s] |               | [Switch]    |  |
| +---------------+---------------+---------------+-------------+  |
|                                                                  |
+------------------------------------------------------------------+
```

### 구성 요소 (14 컨트롤)

| 서브그룹 | 요소 | 타입 | 바인딩 |
|---------|------|------|--------|
| Layout | Board Position | Select | `gfx.board_position` (Left/Centre/Right/Top) |
| Layout | Player Layout | Select | `gfx.player_layout` (5개 옵션) |
| Layout | X Margin | Slider | `gfx.x_margin` (0.0~1.0) |
| Layout | Top Margin | Slider | `gfx.top_margin` (0.0~1.0) |
| Layout | Bot Margin | Slider | `gfx.bot_margin` (0.0~1.0) |
| Layout | Leaderboard Position | Select | `gfx.lb_position` (Off/Centre/Left/Right) |
| Card & Player | Reveal Players | Select | `gfx.reveal_players` (4개 옵션) |
| Card & Player | How to Show Fold | Select + NumberInput | `gfx.fold_display` + `gfx.fold_delay` |
| Card & Player | Reveal Cards | Select | `gfx.reveal_cards` (6개 옵션) |
| Card & Player | Show Leaderboard | Switch + Settings | `gfx.show_leaderboard` + auto_stats 4설정 |
| Animation | Transition In | Select + Slider | `gfx.transition_in_type` + `gfx.transition_in_duration` |
| Animation | Transition Out | Select + Slider | `gfx.transition_out_type` + `gfx.transition_out_duration` |
| Animation | Indent Action Player | Switch | `gfx.indent_action` |
| Animation | Bounce Action Player | Switch | `gfx.bounce_action` |

> Skin Editor는 Info Bar의 Load Skin 버튼(M-16)으로 접근. 상세: BS-03-02

---

## 탭 3: Display

수치 표시 형식 — 블라인드 표시, 통화, 영역별 정밀도, Amount/BB 모드.

```
+------------------------------------------------------------------+
| Outputs  GFX  [Display]  Rules  Stats  Preferences               |
+------------------------------------------------------------------+
|                                                                  |
| * Blinds                                                         |
| +-----------+-----------+-----------+-----------+-----------+    |
| | Show      | Show      | Currency  | Trailing  | Divide    |    |
| | Blinds    | Hand #    | Symbol    | Currency  | by 100    |    |
| | [Sel v]   | [Switch]  | [Input $] | [Switch]  | [Switch]  |    |
| +-----------+-----------+-----------+-----------+-----------+    |
|                                                                  |
| * Precision                                                      |
| +-----------+-----------+-----------+-----------+-----------+    |
| | Leaderbd  | Player    | Player    | Blinds    | Pot       |    |
| | Precision | Stack     | Action    | Precision | Precision |    |
| | [Sel v]   | [Sel v]   | [Sel v]   | [Sel v]   | [Sel v]   |    |
| +-----------+-----------+-----------+-----------+-----------+    |
|                                                                  |
| * Mode                                                           |
| +-----------+-----------+-----------+-----------+                |
| | Chipcount | Pot Mode  | Bets Mode | Display   |                |
| | Mode      |           |           | Side Pot  |                |
| | [Sel v]   | [Sel v]   | [Sel v]   | [Switch]  |                |
| +-----------+-----------+-----------+-----------+                |
|                                                                  |
+------------------------------------------------------------------+
```

### 구성 요소 (17 컨트롤)

| 서브그룹 | 요소 | 타입 | 바인딩 |
|---------|------|------|--------|
| Blinds | Show Blinds | Select | `display.show_blinds` (Always/When Changed/Never) |
| Blinds | Show Hand # | Switch | `display.show_hand_num` |
| Blinds | Currency Symbol | Input | `display.currency_symbol` |
| Blinds | Trailing Currency | Switch | `display.trailing_currency` |
| Blinds | Divide by 100 | Switch | `display.divide_by_100` |
| Precision | Leaderboard Precision | Select | `display.lb_precision` |
| Precision | Player Stack Precision | Select | `display.stack_precision` |
| Precision | Player Action Precision | Select | `display.action_precision` |
| Precision | Blinds Precision | Select | `display.blinds_precision` |
| Precision | Pot Precision | Select | `display.pot_precision` |
| Mode | Chipcounts Mode | Select | `display.chipcount_mode` (Amount/BB) |
| Mode | Pot Mode | Select | `display.pot_mode` (Amount/BB) |
| Mode | Bets Mode | Select | `display.bets_mode` (Amount/BB) |
| Mode | Display Side Pot | Switch | `display.show_side_pot` |

> Precision 옵션: Exact Amount / Smart k-M / Smart Amount / Divide. 상세: BS-03-03

---

## 탭 4: Rules

게임 규칙 + 플레이어 표시 — Bomb Pot, Straddle, 좌석 번호, 정렬, 강조.

```
+------------------------------------------------------------------+
| Outputs  GFX  Display  [Rules]  Stats  Preferences               |
+------------------------------------------------------------------+
|                                                                  |
| * Game Rules                                                     |
| +---------------+---------------+---------------+-------------+  |
| | Move Button   | Limit Raises  | Straddle      | Sleeper     |  |
| | Bomb Pot      |               | Sleeper       | Final Act   |  |
| | [Switch]      | [Switch]      | [Select v]    | [Select v]  |  |
| +---------------+---------------+---------------+-------------+  |
|                                                                  |
| * Player Display                                                 |
| +----------+----------+----------+----------+----------+------+  |
| | Add      | Show as  | Clear    | Order    | Hilite   |      |  |
| | Seat #   | Elim'd   | Prev Act | Players  | Winning  |      |  |
| | [Switch] | [Switch] | [Sel v]  | [Sel v]  | [Sel v]  |      |  |
| +----------+----------+----------+----------+----------+------+  |
|                                                                  |
+------------------------------------------------------------------+
```

### 구성 요소 (11 컨트롤)

| 서브그룹 | 요소 | 타입 | 바인딩 |
|---------|------|------|--------|
| Game Rules | Move Button Bomb Pot | Switch | `rules.move_btn_bombpot` |
| Game Rules | Limit Raises | Switch | `rules.limit_raises` |
| Game Rules | Straddle Sleeper | Select | `rules.straddle_sleeper` (UTG Only/Any/With Sleeper) |
| Game Rules | Sleeper Final Action | Select | `rules.sleeper_final_action` (BB Rule/Normal) |
| Player Display | Add Seat # | Switch | `rules.add_seat_num` |
| Player Display | Show as Eliminated | Switch | `rules.show_eliminated` |
| Player Display | Clear Previous Action | Select | `rules.clear_prev_action` (On Street Change/On Action/Never) |
| Player Display | Order Players | Select | `rules.order_players` (Seat Order/Stack Size/Alphabetical) |
| Player Display | Hilite Winning Hand | Select | `rules.hilite_winning` (Immediately/After Delay/Never) |

> Sleeper Final Action은 Straddle Sleeper가 "With Sleeper"일 때만 활성. 상세: BS-03-04

> **⚠️ Blind 레벨/타이머 편집은 Settings 범위 밖**
> Rules 탭은 **게임 규칙 옵션** (Bomb Pot, Straddle, Player Display 등)만 다룬다.
> **Blind 레벨 구조(레벨별 SB/BB/Ante/Duration), Blind 타이머 편집, BlindDetailType(`Blind`/`Break`/`DinnerBreak`/`HalfBlind`/`HalfBreak`) 편집 UI 는 Settings 가 아니라 Lobby 의 Flight 생성/편집 플로우가 소유한다** (UI-01 §화면 3 Flight 참조).
> 이 원칙은 "Settings = 글로벌, Flight = Event 단위"라는 책임 분리에서 온다. Blind 구조는 Event/Flight 마다 다르므로 글로벌 Settings 에 들어갈 수 없다.
> `BlindDetailType` 5 타입 enum(`Blind`/`Break`/`DinnerBreak`/`HalfBlind`/`HalfBreak`) 은 **CCR-017 APPLIED** 로 `../specs/BS-03-settings/BS-03-04-rules.md` 에 이미 추가되었다 (UI-01 §9.3 참조).
>
> **GFX 탭의 시각 자산 메타데이터 (GEM-01~25)** 는 Settings 직접 편집이 아니라 `/lobby/graphic-editor` 허브에서 처리한다. GEM 필드 전체 목록, Upload Dropzone, rive-js 프리뷰, Activate 흐름 등 상세는 **`UI-04-graphic-editor.md §5`** 참조. Settings GFX 탭은 현재 활성화된 스킨의 메타데이터를 **읽기 전용**으로 노출하고, 편집은 [Graphic Editor 열기] 버튼으로 허브로 이동한다 (CCR-011 + CCR-025 APPLIED).

---

## 탭 5: Stats

Equity, Outs, Rabbit Hunting, Leaderboard, Score Strip.

```
+------------------------------------------------------------------+
| Outputs  GFX  Display  Rules  [Stats]  Preferences               |
+------------------------------------------------------------------+
|                                                                  |
| * Equity & Statistics                                            |
| +----------+----------+----------+----------+----------+------+  |
| | Show Hand| Show     | True     | Outs     | Allow    | Ign  |  |
| | Equities | Outs     | Outs     | Position | Rabbit   | Split|  |
| | [Sel v]  | [Sel v]  | [Switch] | [Sel v]  | [Switch] | [Sw] |  |
| +----------+----------+----------+----------+----------+------+  |
|                                                                  |
| * Leaderboard & Strip                                            |
| +--------+--------+--------+--------+--------+--------+------+  |
| | KO     | Chip   | Show   | Cumul  | Hide   | Max BB |      |  |
| | Rank   | cnt %  | Elim   | Winng  | LB on  | Multi  |      |  |
| | [Sw]   | [Sw]   | [Sw]   | [Sw]   | [Sw]   | [Num]  |      |  |
| +--------+--------+--------+--------+--------+--------+------+  |
| +---------------+---------------+---------------+                |
| | Score Strip   | Show Elim     | Order Strip   |                |
| |               | in Strip      | By            |                |
| | [Select v]    | [Switch]      | [Select v]    |                |
| +---------------+---------------+---------------+                |
|                                                                  |
+------------------------------------------------------------------+
```

### 구성 요소 (15 컨트롤)

| 서브그룹 | 요소 | 타입 | 바인딩 |
|---------|------|------|--------|
| Equity | Show Hand Equities | Select | `stats.show_equities` (Never/Immediately/At showdown or winner All In/At showdown) |
| Equity | Show Outs | Select | `stats.show_outs` (Off/Right/Left) |
| Equity | True Outs | Switch | `stats.true_outs` |
| Equity | Outs Position | Select | `stats.outs_position` (Off/Stack/Winnings) |
| Equity | Allow Rabbit Hunting | Switch | `stats.allow_rabbit` |
| Equity | Ignore Split Pots | Switch | `stats.ignore_split_pots` |
| Leaderboard | Show Knockout Rank | Switch | `stats.show_ko_rank` |
| Leaderboard | Show Chipcount % | Switch | `stats.show_chipcount_pct` |
| Leaderboard | Show Eliminated in Stats | Switch | `stats.show_eliminated_stats` |
| Leaderboard | Show Cumulative Winnings | Switch | `stats.show_cumul_winnings` |
| Leaderboard | Hide LB When Hand Starts | Switch | `stats.hide_lb_hand_start` |
| Leaderboard | Max BB Multiple in LB | NumberInput | `stats.max_bb_multiple` (1~9999) |
| Strip | Score Strip | Select | `stats.score_strip` (Never/Heads Up or All In Showdown/All In Showdown) |
| Strip | Show Eliminated in Strip | Switch | `stats.show_eliminated_strip` |
| Strip | Order Strip By | Select | `stats.order_strip` (Seating/Chip Count) |

> Show Outs는 헤즈업 전용 (3인+ 시 동작 안 함). 상세: BS-03-05

---

## 탭 6: Preferences

테이블 인증, 시스템 진단, 데이터 내보내기.

```
+------------------------------------------------------------------+
| Outputs  GFX  Display  Rules  Stats  [Preferences]               |
+------------------------------------------------------------------+
|                                                                  |
| * Table                                                          |
| +------------------+------------------+------------------+       |
| | Table Name       | Table Password   | PASS / Reset     |       |
| | [Input        ]  | [*****        ]  | [PASS] [Reset]   |       |
| | [Update]         | [Update]         |                  |       |
| +------------------+------------------+------------------+       |
|                                                                  |
| * Diagnostics                                                    |
| +------------------+------------------+------------------+       |
| | PC Specs         | Table            | System Log       |       |
| | CPU: ...         | Diagnostics      |                  |       |
| | GPU: ...         | [Open]           | [Open]           |       |
| | RAM: ...         |                  |                  |       |
| +------------------+------------------+------------------+       |
|                                                                  |
| * Export                                                         |
| +------------------+------------------+------------------+       |
| | Hand History     | Export Logs      | API DB Export    |       |
| | Folder           | Folder           | Folder           |       |
| | [./exports/  ] o | [./logs/     ] o | [./db_exp/   ] o |       |
| +------------------+------------------+------------------+       |
|                                                                  |
+------------------------------------------------------------------+
```

### 구성 요소 (9 컨트롤)

| 서브그룹 | 요소 | 타입 | 바인딩 |
|---------|------|------|--------|
| Table | Table Name | Input + Button | `pref.table_name` |
| Table | Table Password | Input (마스킹) + Button | `pref.table_password` |
| Table | PASS / Reset | Button x2 | — (비밀번호/전체 초기화) |
| Diagnostics | PC Specs | ReadOnly | 시스템 자동 감지 |
| Diagnostics | Table Diagnostics | Button | — (별도 창 600x400px) |
| Diagnostics | System Log | Button | — (별도 창 800x500px) |
| Export | Hand History Folder | FolderPicker | `pref.hand_history_folder` |
| Export | Export Logs Folder | FolderPicker | `pref.export_logs_folder` |
| Export | API DB Export Folder | FolderPicker | `pref.api_db_export_folder` |

> Table Name/Password만 [Update] 버튼 커밋. 나머지 즉시 적용. 상세: BS-03-06

---

## Settings 접근 권한 요약

| 역할 | [Settings ⚙] 표시 | 변경 가능 |
|------|:-----------------:|:---------:|
| **Admin** | O | 전체 |
| **Operator** | X | 없음 |
| **Viewer** | X | 없음 |

---

## 비활성 조건

| 조건 | 영향 |
|------|------|
| Admin이 아닌 역할 | [Settings ⚙] 버튼 미표시 |
| BO 서버 미실행 | 읽기 전용 (변경 불가) |
| 네트워크 단절 | 로컬 캐시 표시, 변경 불가 |
| CC LIVE + LOCK 필드 | 해당 필드 비활성 (회색) |

---

## 참조 관계

| 참조 문서 | 경로 |
|----------|------|
| BS-03-00 Overview | `../specs/BS-03-settings/BS-03-00-overview.md` |
| BS-03-01 Outputs | `../specs/BS-03-settings/BS-03-01-outputs.md` |
| BS-03-02 GFX | `../specs/BS-03-settings/BS-03-02-gfx.md` |
| BS-03-03 Display | `../specs/BS-03-settings/BS-03-03-display.md` |
| BS-03-04 Rules | `../specs/BS-03-settings/BS-03-04-rules.md` |
| BS-03-05 Stats | `../specs/BS-03-settings/BS-03-05-stats.md` |
| BS-03-06 Preferences | `../specs/BS-03-settings/BS-03-06-preferences.md` |
| Foundation PRD | `docs/01-strategy/PRD-EBS_Foundation.md` |

---

## 관련 CCR

본 문서 §1.1 Ownership & Boundary, GFX 탭 (Team 1 rive-js 프리뷰 + GE 허브 연동), Rules 탭 Blind 범위 외 처리의 근거가 된 CCR 목록. 모두 **APPLIED** 상태 (2026-04-10).

| CCR | 상태 | 변경 대상 | 관련 섹션 |
|-----|------|----------|----------|
| **CCR-017** wsop-parity (BlindDetailType 5타입 enum, dayIndex, isPause, Bit Flag RBAC 등) | ✅ APPLIED | `../specs/BS-03-settings/BS-03-04-rules.md` 외 4개 | Rules 탭 Blind 편집 범위 외 주석, ConfigChanged 흐름 (간접) |
| **CCR-016** tech-stack-ssot (Lobby Quasar 확정 + BS-00 SSOT 문장 신설) | ✅ APPLIED | `contracts/specs/BS-00-definitions.md` | §1.1 Ownership & Boundary (Team 1 Quasar 기술 근거) |
| **CCR-011** ge-ownership-move (Graphic Editor Team 4 → Team 1 Lobby 허브 이관) | ✅ APPLIED | `../specs/BS-08-graphic-editor/BS-08-00~04`, `BS-00-definitions.md` | §1.1 GFX 탭 책임 확장 (rive-js 프리뷰 + GE 허브), Team 4 Overlay 렌더링 소비자 재정의 |
| **CCR-025** bs03-graphic-settings-tab (BS-03-02-gfx 시각 asset 메타 확장) | ✅ APPLIED | `../specs/BS-03-settings/BS-03-02-gfx.md` | §1.1 GFX 탭 Team 4 기여 필드 (BS-03-02 메타 참조) |

CCR 경로: `docs/05-plans/ccr-inbox/promoting/CCR-{011,016,017,025}-*.md`
원본 drafts: `docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team1-20260410-{wsop-parity,tech-stack-ssot}.md`, `CCR-DRAFT-conductor-20260410-ge-ownership-move.md`, `CCR-DRAFT-team4-20260410-bs03-graphic-settings-tab.md`
