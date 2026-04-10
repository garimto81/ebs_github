# UI-03 Settings — 6탭 와이어프레임

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | Output/Overlay/Game/Statistics 4섹션 레이아웃, 탭 네비게이션, 모달 구조 |
| 2026-04-09 | 6섹션 전면 재설계 | Console PRD v9.7 기반 Outputs/GFX/Display/Rules/Stats/Preferences |

---

## 개요

Settings는 Lobby 웹 내 **6탭 페이지**로, Console의 5탭(Outputs/GFX/Display/Rules/Stats) + Preferences 다이얼로그를 통합한 구조. 오버레이 출력 파이프라인, 그래픽 배치, 수치 표시 형식, 게임 규칙, 통계/리더보드, 테이블 인증/진단/내보내기를 관리한다. Admin 전용이며, Lobby 또는 CC 어디서든 [Settings ⚙] 버튼으로 접근한다.

> 참조: BS-03-00-overview, BS-00 §1

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
| BS-03-00 Overview | `contracts/specs/BS-03-settings/BS-03-00-overview.md` |
| BS-03-01 Outputs | `contracts/specs/BS-03-settings/BS-03-01-outputs.md` |
| BS-03-02 GFX | `contracts/specs/BS-03-settings/BS-03-02-gfx.md` |
| BS-03-03 Display | `contracts/specs/BS-03-settings/BS-03-03-display.md` |
| BS-03-04 Rules | `contracts/specs/BS-03-settings/BS-03-04-rules.md` |
| BS-03-05 Stats | `contracts/specs/BS-03-settings/BS-03-05-stats.md` |
| BS-03-06 Preferences | `contracts/specs/BS-03-settings/BS-03-06-preferences.md` |
| Foundation PRD | `docs/01-strategy/PRD-EBS_Foundation.md` |
