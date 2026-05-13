---
title: UI
owner: team4
tier: internal
legacy-id: UI-02
last-updated: 2026-05-13
confluence-page-id: 3819209336
confluence-parent-id: 3811901565
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819209336/EBS+UI+1565
---

# UI-02 Command Center — 7화면 와이어프레임

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | CC 8화면 레이아웃, 전환 플로우, 터치 최적화 |
| 2026-04-13 | Critic 수정 | 좌석 대칭화, 화면 2 제거(인라인 편집), 카드 합성선택, 금액 단순화, Undo 무제한, History loser 추가 |
| 2026-04-14 | 좌석 번호 재정의 | S1~S10 시계방향(D 왼쪽=S1, D 오른쪽=S10), SB/BB 언급 제거(포지션은 로테이션 개념으로 분리), HTML 목업 캡처 삽입 |
| 2026-04-14 | 화면 4 단순화 | 키패드 0 옆에 000 인접 배치, ALL-IN을 BET 상단에 우측 세로 버튼 스택으로 이동, C 버튼 제거(← 롱프레스로 전체 삭제 대체) |
| 2026-05-06 | **§Visual Uplift 신설** (B-team4-011) | React 디자인 시안 critic 판정 결과 시각 자산 7종 (V1~V7) 흡수 결정. StatusBar 통합 / MiniDiagram / SeatCell 7행 / ACTING glow 정책 추가. SSOT: `docs/4. Operations/CC_Design_Prototype_Critic_2026_05_06.md`. D7 / 통신 / HandFSM 가드 4개 강제. |
| 2026-05-07 | **v4 정체성 정합** | CC_PRD v4.0 cascade — 1×10 그리드 + 6 키 + 4 영역 위계 + 5-Act 시퀀스 반영. §"v4.0 정체성" 신설. 구 §"CC 레이아웃 3영역"/§"화면 1: 메인 화면"/§"화면 4: 금액 입력" 의 v1.x 타원형/8 버튼 기술은 layout/structure 만 archive 마킹 (색상은 무시 — Lobby B&W refined minimal 톤이 최종). SSOT: `docs/1. Product/Command_Center.md` v4.0. |
| 2026-05-13 | **OKLCH 톤 채택** | PRD v4.3 cascade (#409/#410) — v4.0 "색상 무시 — Lobby B&W refined minimal 톤" 폐기. Broadcast Dark Amber OKLCH 채택. §v4.0 정체성 내 색상 언급 정정. SSOT: `tokens.css`. |

---

## 개요

Command Center(CC)는 운영자가 포커 핸드를 실시간 진행하는 Flutter 앱이다. 테이블당 1개 인스턴스로 동작하며, 운영자 주의력의 85%가 집중되는 핵심 화면이다.

### 문서 독립성 (docs v10)

이 폴더(`docs/2. Development/2.4 Command Center/Command_Center_UI/`)는 CC UI 의 **SSOT**이다. 과거 `team4-cc/specs/` (L1 파생) / `contracts/` (L0 계약) 의 2계층 구분은 v10 에서 폐지되었으며, 이 폴더와 자매 폴더만 참조한다.

| 구분 | 위치 | 역할 |
|------|------|------|
| **UI 상세 (이 폴더)** | `Command_Center_UI/*.md` | 와이어프레임 · 화면별 행위 · 단축키 · 좌석 · 액션 버튼 등 |
| **외부 계약 (consume only)** | `docs/2. Development/2.2 Backend/APIs/*.md` | BO REST · WebSocket · Auth (team2 publisher) |
| **외부 계약 (consume only)** | `docs/2. Development/2.3 Game Engine/APIs/Overlay_Output_Events.md` | Overlay 이벤트 (team3 publisher) |
| **CC 자체 publisher** | `docs/2. Development/2.4 Command Center/APIs/RFID_HAL.md` | RFID 계약 (team4 publisher) |

이 폴더 내부 문서 간 관계는 아래 §"자매 문서 참조 맵" 에서 제공한다.

> 참조: 상위 섹션 `2.4 Command Center.md`, `Command_Center_UI/Overview.md`

---

## v4.0 정체성 (2026-05-07 신설, SSOT)

> **트리거**: `docs/1. Product/Command_Center.md` v4.0 cascade. 본 §이 *layout / structure / interaction* 측면에서 아래 §"CC 레이아웃 3영역" 이하 v1.x 와이어프레임을 *override* 한다. **색상도 포함** — PRD v4.3 재결정 (2026-05-13): EBS 최종은 Broadcast Dark Amber OKLCH 톤 (`tokens.css` SSOT). 이전 "Lobby B&W refined minimal 톤" 지침은 v4.3 에서 폐기됨.

### 4 영역 위계 (StatusBar / TopStrip / PlayerGrid / ActionPanel)

```
+-------------------------------------------------+
|  StatusBar  (52px)                              |
|  - ●BO ●RFID ●Engine | Op | Table || Hand #    |
|  - PHASE | Blinds | Lvl | Players ratio        |
+-------------------------------------------------+
|  TopStrip   (158px)                             |
|  - 좌(MiniDiagram + POT) | 중(Community Board)  |
|  - 우(ACTING / SHOWDOWN / HAND OVER 박스)       |
|  - 하단 32px: KeyboardHintBar (6 키 칩)         |
+-------------------------------------------------+
|  PlayerGrid (가변 1fr, 1×10 가로 그리드) ★      |
|  - 선수 10명을 가로 한 줄에 정렬                 |
|  - 각 셀 = 9 행 stacked                         |
|    (Acting / S# / Pos / Flag / Name /          |
|     HoleCards face-down / Stack / Bet / Last)  |
|  - 타원형 테이블 폐기                           |
+-------------------------------------------------+
|  ActionPanel (124px)                            |
|  [N] [F] [C] [B] [A] [M]  + Numpad slide-up    |
|  - 6 키 동적 매핑 (phase 별 의미 자동 전환)      |
+-------------------------------------------------+
```

### 1×10 가로 그리드 (PlayerGrid)

```
S1   S2   S3   S4   S5   S6   S7   S8   S9   S10
─────────────────────────────────────────────────
[셀] [셀] [셀] [셀] [셀] [셀] [셀] [셀] [셀] [셀]
 ↑ 9 행 stacked 구조 — 한 셀 = 한 사람의 전체 상태

각 셀의 9 행 (위 → 아래):
 1. ACTING / WAITING / FOLD / DELETE strip
 2. Seat # (S1~S10, 큰 글씨)
 3. Position (STRADDLE / SB·BB / D + ‹ › shift 화살표)
 4. Country flag
 5. Player name
 6. Hole cards 2장 (face-down `?` — D7 강제, 값 비노출)
 7. Stack ($)
 8. Bet ($)
 9. Last action (FOLD / CALL / BET / RAISE / ALL-IN)
```

> **공간 관계 회복**: 1×10 그리드로 잃은 oval 공간 관계는 TopStrip 좌측 MiniDiagram (V3) + Position Shift Arrows (V4) 로 보강.

### 6 키 의미 카탈로그 (N · F · C · B · A · M)

| 키 | 명칭 | IDLE | PRE_FLOP / FLOP / TURN / RIVER | SHOWDOWN / HAND_COMPLETE |
|:--:|------|:----:|:------------------------------:|:------------------------:|
| **N** | Next / Finish | START HAND | (disabled) | FINISH HAND |
| **F** | Fold | (disabled) | FOLD | (disabled) |
| **C** | Call / Check | (disabled) | CHECK *or* CALL (auto-switch) | (disabled) |
| **B** | Bet / Raise | (disabled) | BET *or* RAISE (auto-switch) | (disabled) |
| **A** | All-in | (disabled) | ALL-IN | (disabled) |
| **M** | Menu / Manual (Miss Deal) | (disabled) | Miss Deal | (disabled) |

**자동 전환 룰 (C/B 키)**:
- `biggestBet == playerBet` → **CHECK**
- `biggestBet > playerBet` → **CALL**
- `biggestBet == 0` → **BET**
- `biggestBet > 0` → **RAISE**

Numpad (BET/RAISE 입력) 은 **B 키** 누르면 화면 하단에 슬라이드 업. 0 / 000 / `<-` 인접 배치 (천 단위 빠른 입력).

### 5-Act 시퀀스 (HandFSM 9-state 의 의미 묶음)

| Act | 단계 | 9-state | CC 화면 변화 | 6 키 활성 |
|:---:|------|---------|--------------|-----------|
| 1 | IDLE | IDLE | StatusBar PHASE = "IDLE", PlayerGrid 정적 | N |
| 2 | PreFlop | SETUP_HAND → PRE_FLOP | 블라인드 수거 → 홀카드 분배 → action_on 펄스 | F·C·B·A·M |
| 3 | Flop / Turn / River | FLOP → TURN → RIVER | Community Board 슬롯 채움, 폴드 반투명 | F·C·B·A·M |
| 4 | Showdown | SHOWDOWN | 승자 강조, 핸드 공개 | (viewing) |
| 5 | Settlement | HAND_COMPLETE | 팟 분배 애니메이션, 스택 갱신 | N (FINISH HAND) |

> **참조**: PRD §Ch.6 (HandFSM lifecycle), `Hand_Lifecycle.md` (5-Act ↔ 9-state 정합).

### v1.x ↔ v4.0 변경 매트릭스

| 항목 | v1.x (archive) | v4.0 (current) |
|------|---------------|----------------|
| 좌석 배치 | 타원형 360° 분포 | **1×10 가로 그리드** |
| ActionPanel | 8 분리 버튼 (NEW/DEAL/FOLD/CHECK/BET/CALL/RAISE/ALL-IN) | **6 키 동적 매핑** (N·F·C·B·A·M) |
| 단축키 | 8 키 (N·D·F·C·B·R·A·Ctrl+Z) | **6 키 + Ctrl+Z** (D 키 폐기, R 키 → B 통합) |
| 영역 수 | 3 영역 (StatusBar / Table / Action) | **4 영역** (StatusBar / TopStrip / PlayerGrid / ActionPanel) |
| 공간 관계 | oval 시각으로 직접 | **MiniDiagram (V3) + Position Shift (V4) 보강** |
| Phase 전이 | 9-state 직접 노출 | **5-Act 추상화** (UI level) |

---

## [archive — v1.x] CC 레이아웃 3영역

> ⚠️ **Archive (v1.x)**: 본 §은 v4.0 §"4 영역 위계" (StatusBar 52px / TopStrip 158px / PlayerGrid 가변 / ActionPanel 124px) 으로 *override* 됨. 인용 금지.

모든 화면에서 상단 바는 고정이다. 중앙 영역만 화면별로 변경된다.

```
+-------------------------------------------------+
| [Status Bar] Game | Hand # | RFID | BO    48px |
+-------------------------------------------------+
|                                                 |
|              [Content Area]                     |
|             (화면별 변경)                        |
|                                                 |
+-------------------------------------------------+
| [Action Panel] 8 Buttons + UNDO            80px |
+-------------------------------------------------+
```

---

## 상단 바 (공통)

```
+-------------------------------------------------+
| ● BO  ● RFID | HOLDEM | Hand #42 | SB/BB/Ante [⚙]|
+-------------------------------------------------+
```

| 항목 | 위치 | 바인딩 |
|------|------|--------|
| BO 연결 | 좌측 | ● 녹색 / ○ 빨간색 |
| RFID 상태 | 좌측 | ● 녹색 / ○ 회색 / ⚠ 빨간색 |
| Game Type | 중앙좌 | `game_type` enum |
| Hand # | 중앙 | `hand_number` 자동 증가 |
| Blinds | 중앙우 | `SB/BB/Ante` (예: 100/200/25) |
| [Settings ⚙] | 우측 | Admin 전용 |

---

## [archive — v1.x] 화면 1: 메인 화면 (테이블 + 액션)

> ⚠️ **Archive (v1.x)**: 본 §은 v4.0 §"4 영역 위계" + §"1×10 가로 그리드" + §"6 키 의미 카탈로그" 로 *override* 됨. 좌석 배치는 oval 360° 분포가 아닌 **1×10 가로 그리드** (PlayerGrid). 액션 패널은 8 분리 버튼이 아닌 **6 키 동적 매핑** (N·F·C·B·A·M).

CC의 기본 화면. 핸드 진행의 모든 것이 여기에 표시된다.

### 좌석 배치 — S1~S10 시계방향, 좌우 완벽 대칭

> 자산 미생성 (TBD — team4 디자인 작업) · HTML 목업: `ui-design/reference/action-tracker/mockups/seat-layout-symmetric.html`

```
        [S4]  [S5]  [S6]  [S7]
   [S3]                       [S8]
   [S2]       [Board Area]    [S9]
        [S1]              [S10]
                  [D]
```

**배치 규칙** (물리 좌석 번호, 불변):
- **D(Dealer)**: 하단 중앙 고정. 관찰자 시점 기준.
- **S1**: D 바로 **왼쪽** 하단 / **S10**: D 바로 **오른쪽** 하단.
- S1에서 시작하여 **시계방향**으로 연속 번호 S1 → S2 → ... → S10.
- 왼쪽 체인 (아래→위): S1 → S2 → S3 → S4
- 상단 체인 (왼쪽→오른쪽): S4 → S5 → S6 → S7
- 오른쪽 체인 (위→아래): S7 → S8 → S9 → S10
- **좌우 완벽 대칭** (D 수직 중심축 기준): S1↔S10, S2↔S9, S3↔S8, S4↔S7, S5↔S6

**포지션 뱃지와의 관계**:
- D / SB / BB / STR 등 포지션은 **핸드마다 로테이션**되는 유동 속성이며, 좌석 번호와 독립이다.
- 좌석 위젯의 포지션 뱃지는 `seat.position_badge` 필드로 별도 관리된다 (BS-05-03 §1.1 참조).
- 좌석 번호 서술 시 SB/BB/D를 특정 좌석에 고정해 설명하지 않는다.

### 전체 레이아웃

```
+-------------------------------------------------+
| ● BO  ● RFID | HOLDEM | Hand #42 | 100/200/25[⚙]|
+-------------------------------------------------+
|        [S4]  [S5]  [S6]  [S7]                   |
|   [S3]                       [S8]               |
|   [S2]       [Board Area]    [S9]               |
|              [POT: 2,400]                       |
|        [S1]              [S10]                  |
|                  [D]                            |
+-------------------------------------------------+
| NEW  DEAL FOLD CHECK BET CALL RAISE ALL-IN      |
| [N]  [D]  [F]  [C]   [B] [C]  [R]   [A]  UNDO |
+-------------------------------------------------+
```

### 좌석 위젯 (SeatWidget) 상세

각 좌석 [S1]~[S10]은 다음을 표시한다:

```
+---------------------------+
| 🇰🇷 John Doe         [SB] |
| Stack: 125,000            |
| [Ah] [Kd]   CHECK        |
|              82%          |
+---------------------------+
```

| 요소 | 바인딩 | 비고 |
|------|--------|------|
| 국기 | `seat.player.country_code` → Flag emoji/icon | ISO 3166-1 alpha-2 |
| 이름 | `seat.player.name` | 글자 수 초과 시 말줄임 |
| 포지션 뱃지 | D / SB / BB / STR | 해당 포지션에만 표시 |
| Stack | `seat.player.stack` | Roboto Mono, 콤마 포맷 |
| 홀카드 2장 | `seat.cards[0,1]` | RFID 감지 또는 수동 |
| 액션 배지 | `seat.last_action` | CHECK/FOLD/BET/CALL/RAISE/ALL-IN |
| Equity | `seat.equity` | **'%' 숫자만** (프로그레스 바 제거) |

### 인라인 편집 (화면 2 대체)

> **좌석 위젯의 각 요소를 직접 탭하여 수정한다.

| 탭 대상 | 동작 | 비고 |
|---------|------|------|
| **이름** | 이름 편집 다이얼로그 | IDLE에서만 |
| **국기** | 국가 선택 피커 | IDLE에서만 |
| **Stack** | 칩 수동 조정 다이얼로그 | 항상 가능 |
| **홀카드** | 화면 3 (카드 입력) 진입 | 해당 슬롯 선택 상태 |
| **포지션** | 포지션 재지정 메뉴 | IDLE에서만 |
| **좌석 전체 롱프레스** | 컨텍스트 메뉴: Move / Swap / Remove / Sit Out | 핸드 중 Move/Remove 불가 |

### 수동 편집 우선 원칙

> **수작업 우선**: 운영자가 수동으로 수정한 값은 DB/WebSocket에서 들어오는 값보다 우선한다.

- 수동 편집 후 DB 동기화 시 옵션 표시:
  - **"수동 값 유지"** (기본) — DB 업데이트 무시
  - **"DB 값으로 갱신"** — 수동 편집 폐기
- 옵션은 좌석 위젯 우상단 동기화 아이콘 (🔄) 탭으로 제어
- 핸드 종료 시 자동 동기화 (수동 편집 상태 리셋)

### action_on 표시

현재 액션 대상 좌석은 **glow 효과**(0.8s pulse, SeatColors SSOT)로 강조. 나머지 좌석은 일반 상태.

### Board Area

```
+-----------------------------------+
| [Flop1] [Flop2] [Flop3] [T] [R]  |
+-----------------------------------+
```

- 카드 슬롯 5개 (비어있으면 회색 placeholder)
- 각 슬롯 탭 → 화면 3 (카드 입력) 진입
- Flop: 3장 동시 공개 / Turn: 4번째 / River: 5번째

---

## 화면 3: 카드 입력 (수동 / Mock)

RFID 미사용 또는 수동 폴백 시 카드를 직접 선택하는 화면.

> **변경**: 기존 4×13(수트×랭크 분리)에서 **합성 카드 선택** 방식으로 변경. 숫자와 모양이 합쳐진 카드 이미지를 직접 탭.

```
+-------------------------------------------------+
| Card Input — Seat 3 (Hole Card 1/2)             |
+-------------------------------------------------+
| [A♠][K♠][Q♠][J♠][T♠][9♠][8♠][7♠][6♠][5♠][4♠][3♠][2♠] |
| [A♥][K♥][Q♥][J♥][T♥][9♥][8♥][7♥][6♥][5♥][4♥][3♥][2♥] |
| [A♦][K♦][Q♦][J♦][T♦][9♦][8♦][7♦][6♦][5♦][4♦][3♦][2♦] |
| [A♣][K♣][Q♣][J♣][T♣][9♣][8♣][7♣][6♣][5♣][4♣][3♣][2♣] |
+-------------------------------------------------+
| Selected: [A♠]  Remaining: 1                    |
| [Cancel]                          [Confirm]     |
+-------------------------------------------------+
```

### 합성 카드 방식

| 요소 | 설명 |
|------|------|
| 카드 셀 | **랭크+수트 합성 이미지/텍스트** (예: `A♠`, `K♥`) |
| 셀 크기 | 60×72px (터치 최적화, 기존 48×56보다 확대) |
| 사용된 카드 | 비활성 (opacity 0.3 + ✕ 표시) |
| 선택 | 1탭으로 즉시 선택, 선택된 카드에 파란 테두리 |
| Confirm | 선택 확정 → `CardDetected` 이벤트 합성 |

### 차이점 (기존 대비)

| 항목 | 기존 | 변경 |
|------|------|------|
| 셀 표시 | 수트 행 + 랭크 열 분리 | **합성**: 셀 자체가 카드 |
| 시각 식별 | 수트와 랭크를 교차점에서 추론 | **즉시 식별**: "A♠" 자체가 카드 |
| 터치 정확도 | 교차점 탭 → 오선택 빈번 | 카드 셀 탭 → 직관적 |

---

## 화면 4: 금액 입력 (BET / RAISE)

BET 또는 RAISE 시 슬라이드업되는 금액 입력 패널.

> **변경**: Quick preset, 슬라이더 **제거**. 키패드 3×4 + 우측 액션 버튼 스택으로 단순화. 0과 000 인접, ALL-IN은 BET 상단.

```
+-------------------------------------------------+
|                  [메인 화면]                     |
+-------------------------------------------------+
| +---------------------------------------------+ |
| | BET Amount                    Min: 200      | |
| |---------------------------------------------| |
| |                                             | |
| |    +------------------+                     | |
| |    |          2,400   |    [   ALL-IN   ]   | |
| |    +------------------+    [     BET     ]  | |
| |                            [    Cancel    ] | |
| |    [ 1 ] [ 2 ] [ 3 ]                        | |
| |    [ 4 ] [ 5 ] [ 6 ]                        | |
| |    [ 7 ] [ 8 ] [ 9 ]                        | |
| |    [ 0 ] [000] [ <- ]                       | |
| |                                             | |
| +---------------------------------------------+ |
+-------------------------------------------------+
```

### 구성 요소

| 요소 | 타입 | 설명 |
|------|------|------|
| Amount Field | TextField (mono) | 직접 입력, Roboto Mono. 우측 액션 버튼 스택과 수평 정렬 |
| Numpad | 3×4 그리드 | 행 1~3: `1~9`, 행 4: `0 / 000 / <-`. **0과 000 인접** (천 단위 빠른 입력 동선) |
| `<-` (Backspace) | Button | 단일 탭 — 마지막 자리 삭제. **롱프레스 500ms — 전체 삭제** (C 버튼 대체) |
| [ALL-IN] | Button (danger) | 우측 스택 **최상단**. stack 전액 베팅 |
| [BET] / [RAISE] | Button (primary) | 우측 스택 중앙. 금액 확정, 이벤트 전송 |
| [Cancel] | Button (neutral) | 우측 스택 **최하단**. 입력 취소, 메인 복귀 |
| 키패드 연동 | 하드웨어 키패드 | USB 숫자 키패드 입력 시 Amount Field에 직접 반영 |

### 금액 검증

| 입력값 | 반응 |
|--------|------|
| < min_bet | 경고 "최소 {min_bet}" + 재입력 |
| > max_bet (player.stack 이하) | **에러: "입력 실수. 최대 {max_bet}"** → 재입력 |
| > player.stack | **에러: "스택 초과. ALL-IN 버튼을 사용하세요"** → 재입력 |
| == 0 | 경고 "0 베팅 불가" |

> **제거된 항목**: Quick Preset(MIN/1/2 POT/POT), 슬라이더, `> player.stack` 자동 ALL-IN 전환, `C`(전체 초기화) 버튼.
> **올인**: ALL-IN 버튼을 명시적으로 클릭해야만 가능. 금액 입력에서 max 초과는 항상 입력 실수로 간주.
> **전체 삭제**: `<-` 버튼을 500ms 이상 롱프레스 (C 버튼 제거에 따른 대체 동작).

---

## 화면 5: Undo 히스토리

현재 핸드의 **모든 이전 액션**을 undo할 수 있는 화면.

> **변경**: 5단계 제한 → **무제한 undo**. 10개씩 페이지네이션.

```
+-------------------------------------------------+
| Undo History — Hand #42           Page 1 of 2   |
+-------------------------------------------------+
| #  | Time   | Event              | Player      |
|----|--------|--------------------|-------------|
| 10 | 14:35  | RAISE 2,400        | Seat 2      |
| 9  | 14:34  | CALL 1,200         | Seat 10     |
| 8  | 14:34  | CALL 1,200         | Seat 1      |
| 7  | 14:33  | RAISE 1,200        | Seat 5      |
| 6  | 14:32  | CALL 400           | Seat 3      |
| 5  | 14:32  | BET 400            | Seat 9      |
| 4  | 14:31  | CHECK              | Seat 8      |
| 3  | 14:31  | CHECK              | Seat 7      |
| 2  | 14:30  | DEAL               | System      |
| 1  | 14:30  | NEW HAND           | System      |
+-------------------------------------------------+
| [UNDO Last] (Ctrl+Z)                           |
| [< Prev] Page 1 of 2 [Next >]       [Close]   |
+-------------------------------------------------+
```

### 구성 요소

| 요소 | 바인딩 | 비고 |
|------|--------|------|
| Event Log | `hand.events[]` | 최신 이벤트 상단, **전체 이벤트** |
| [UNDO Last] | Button | **무제한** 되돌리기 (현재 핸드 내) |
| 페이지네이션 | 10개/페이지 | [Prev] / [Next] |
| 단축키 | Ctrl+Z | UNDO Last와 동일 |

### Undo 규칙

- **Undo 가능**: 현재 핸드 내 모든 액션 (제한 없음)
- **Undo 불가**: HandCompleted 이후 (핸드 결과 확정 후)
- **Event Sourcing**: 되돌린 이벤트는 스택에서 제거, GameState 복원

---

## 화면 6: Hand History

과거 핸드 목록 조회. **10핸드씩 페이지네이션**.

> **변경**: Winner 좌석 번호만 → 번호+이름+카드. Loser 정보 추가. Winner와 동일한 요소 표시.

```
+-------------------------------------------------+
| Hand History — Table 1            Page 1 of 5   |
+-------------------------------------------------+
| Hand | Result   | Name    | Cards    | Pot      |
|------|----------|---------|----------|----------|
| #42  | WIN  S1  | J.Doe   | [Ah][Kd] |  2,400   |
|      | LOSE S3  | T.Lee   | [7h][7d] |          |
|      | LOSE S5  | A.Park  | [Qc][Jc] |          |
|------|----------|---------|----------|----------|
| #41  | WIN  S5  | A.Park  | —        |  1,800   |
|      | (All folded pre-flop)          |          |
|------|----------|---------|----------|----------|
| #40  | WIN  S3  | T.Lee   | [Td][8d] |  5,200   |
|      | WIN  S7  | K.Choi  | [Jd][Qs] | (chop)   |
|      | LOSE S1  | J.Doe   | [9s][2c] |          |
+-------------------------------------------------+
| Board: [Ah] [Kd] [7c] [3s] [9h]               |
+-------------------------------------------------+
| [< Prev]  Page 1 of 5  [Next >]     [Close]    |
+-------------------------------------------------+
```

### 구성 요소

| 요소 | 바인딩 | 비고 |
|------|--------|------|
| Hand 번호 | `hand.number` | 숫자만 (Seat 제거) |
| Result | WIN / LOSE | 결과 구분 |
| Seat 번호 | 숫자만 | "S1", "S3" 등 |
| Name | `player.name` | 해당 시점의 이름 |
| Cards | `player.hole_cards` | 카드 이미지/텍스트 (없으면 "—") |
| Pot | `hand.total_pot` | 콤마 포맷 |
| Board | `hand.board_cards` | 핸드 클릭 시 하단에 표시 |
| 페이지네이션 | **10핸드/페이지** | [Prev] / [Next] |

### Winner와 Loser 동일 표시 요소

WIN 행과 LOSE 행 모두 동일하게: `Seat 번호 / 이름 / 카드 / Pot(해당 시)` 표시.
Chop(Split pot)은 여러 WIN 행으로 표시.

---

## 화면 7: 통계 패널

플레이어 통계 오버뷰.

> **변경**: 이번 세션 핸드 수 / 전체 핸드수 추가.

```
+-------------------------------------------------+
| Player Statistics — Table 1                     |
+-------------------------------------------------+
| Seat | Player     | VPIP | PFR | AGR  | WTSD  |
|------|------------|------|-----|------|-------|
|  1   | J.Doe      | 28%  | 18% | 2.3  | 30%   |
|  2   | S.Kim      | 35%  | 22% | 1.8  | 25%   |
|  3   | T.Lee      | 42%  | 12% | 1.2  | 35%   |
|  5   | A.Park     | 22%  | 20% | 3.1  | 22%   |
+-------------------------------------------------+
| Session: 42 hands | Total: 1,247 hands          |
| Avg Pot: 2,100                         [Close]  |
+-------------------------------------------------+
```

### 구성 요소

| 요소 | 바인딩 | 비고 |
|------|--------|------|
| Stats Table | `GET /tables/{id}/stats` | 활성 좌석만 |
| VPIP | `player.stats.vpip` | % 소수점 없음 |
| PFR | `player.stats.pfr` | Pre-Flop Raise % |
| AGR | `player.stats.aggression` | 소수점 1자리 |
| WTSD | `player.stats.wtsd` | Went To Showdown % |
| **Session Hands** | `table.session_hands` | **이번 세션 핸드 수** |
| **Total Hands** | `table.total_hands` | **전체 누적 핸드 수** |
| Avg Pot | `table.avg_pot` | 콤마 포맷 |

---

## 화면 8: Settings 접근

CC에서 [Settings ⚙]를 누르면 Settings 모달이 열린다.

```
+-------------------------------------------------+
| CC 메인 화면 (딤 처리)                          |
+-------------------------------------------------+
| +---------------------------------------------+ |
| | Settings                              [X]   | |
| | [Output] [Overlay] [Game] [Statistics]      | |
| |---------------------------------------------| |
| |  (Settings 다이얼로그 내용)                  | |
| |  BS-03-settings 참조                         | |
| +---------------------------------------------+ |
+-------------------------------------------------+
```

> Admin 전용. Operator/Viewer에게는 [Settings ⚙] 버튼이 표시되지 않는다.

---

## 화면 전환 플로우

> 화면 2(좌석 상세 패널)가 제거되어 7화면 구조로 변경됨.

```
  메인(1)
  |  |  \----→ 카드 입력(3) ← 좌석 위젯 카드 탭 또는 Board 슬롯 탭
  |  |  \----→ 금액 입력(4) ← BET/RAISE 버튼
  |  |
  |  +--→ [좌석 위젯 인라인 편집] (화면 전환 없음, 다이얼로그)
  |
  +----→ Undo 히스토리(5) ← UNDO 버튼 또는 Ctrl+Z
  +----→ Hand History(6) ← 메뉴 > Hand History
  +----→ 통계 패널(7) ← 메뉴 > Statistics
  +----→ Settings(8) ← [⚙] 버튼
```

| 전환 | 트리거 | 복귀 |
|------|--------|------|
| 메인 → 카드 입력 | 좌석 카드 탭 / Board 슬롯 탭 / DEAL (Mock) | [Confirm] / [Cancel] |
| 메인 → 금액 입력 | BET / RAISE 버튼 | [BET] / [Cancel] |
| 메인 → 좌석 인라인 편집 | 좌석 위젯 요소 탭 | 다이얼로그 닫기 (화면 전환 아님) |
| 메인 → Undo | UNDO 버튼 또는 Ctrl+Z | [Close] |
| 메인 → History | 메뉴 > Hand History | [Close] |
| 메인 → 통계 | 메뉴 > Statistics | [Close] |
| 메인 → Settings | [Settings ⚙] | [X] 닫기 |

---

## 터치스크린 최적화 원칙

| 원칙 | 기준 |
|------|------|
| 최소 터치 타겟 | 48 x 48 px |
| 액션 버튼 크기 | 64 x 48 px (가로 넓게) |
| 좌석 위젯 탭 영역 | 120 x 100 px |
| 카드 합성 셀 | **60 x 72 px** (기존 48x56에서 확대) |
| 금액 키패드 셀 | 64 x 56 px |
| 롱 프레스 | 좌석 롱 프레스 → 컨텍스트 메뉴 (Move/Swap/Remove/Sit Out) |
| 더블 탭 | 팟 영역 더블 탭 → 팟 상세 (사이드 팟) |

---

## 키보드 단축키 요약

| 키 | 동작 | 조건 |
|:--:|------|------|
| N | NEW HAND | IDLE |
| D | DEAL | SETUP_HAND |
| F | FOLD | 베팅 라운드 중 |
| C | CHECK / CALL | biggest_bet 기준 전환 |
| B | BET | biggest_bet == 0 |
| R | RAISE | biggest_bet > 0 |
| A | ALL-IN | 베팅 라운드 중 |
| Ctrl+Z | UNDO | 항상 |
| 0~9 | 좌석 선택 | 항상 |
| Esc | 패널 닫기 | 서브 화면 열려있을 때 |

---

## Contracts 차이 (CCR 필요 항목)

UI-02 변경에 따라 contracts/specs/BS-05-command-center/ 와 다음 차이가 발생:

| 항목 | BS-05 현재 | UI-02 변경 | CCR 필요 |
|------|-----------|-----------|:-------:|
| Undo 단계 | 최대 5단계 (BS-05-05) | **무제한** (현재 핸드 내) | ✅ |
| 카드 입력 | 4×13 수트×랭크 그리드 (BS-05-04) | **합성 카드 선택** | ✅ |
| 금액 프리셋 | MIN/1/2 POT/POT/ALL-IN (BS-05-02) | **제거** (키패드만) | ✅ |
| 금액 슬라이더 | BetSlider (BS-05-02) | **제거** | ✅ |
| > stack 자동 ALL-IN | 자동 전환 (BS-05-02) | **에러 처리** (올인 버튼 분리) | ✅ |
| 좌석 상세 패널 | 별도 화면 | **제거** (인라인 편집) | ✅ |
| 좌석 위젯 국기 | 미정의 | **국기 추가** | ✅ |
| Equity 표시 | 프로그레스 바 | **'%' 숫자만** | ✅ |
| 좌석 번호 | S0~S9 | **S1~S10** | ✅ |
| Hand History loser | Winner만 | **Winner + Loser** (동일 요소) | ✅ |
| 수동 편집 우선 | 미정의 | **수작업 우선 + DB 무시 옵션** | ✅ |
| 통계 세션/전체 핸드 | 미정의 | **session_hands + total_hands** | ✅ |

> 위 12건은 모두 본 UI.md 와 자매 문서에 이미 반영되었다 (v10 자유 편집 정책). 과거 L0/L1 2계층 구분 및 CCR draft 경로는 폐지 — 수정이 필요하면 관련 문서를 직접 편집하고, 타팀 소유(`2.2 Backend/APIs/`, `2.3 Game Engine/APIs/`) 변경은 해당 팀 `decision_owner` 에 notify 한다.

---

## 자매 문서 참조 맵

`Command_Center_UI/` 내부 문서 간 관계표. CC UI 작업 시 편집 파급 범위 확인용.

| 본 문서 변경 시 함께 확인 | 이유 |
|---------------------------|------|
| `Action_Buttons.md` | 화면 4(액션 입력) 버튼 · 라벨 · 키패드 레이아웃. UI.md §화면 4 와 동기 필수 |
| `Seat_Management.md` | S1~S10 번호, 좌석 상태 색상, action-glow 애니메이션 — UI.md 좌석 레이아웃 전반 |
| `Manual_Card_Input.md` | 화면 3(카드 선택) 행동. UI.md §화면 3 와 동기 필수 |
| `Hand_Lifecycle.md` | 핸드 단계 전이(PRE_FLOP → FLOP → …) — UI.md 상단 바 phase 표시와 동기 |
| `Keyboard_Shortcuts.md` | 터치 우선 화면이지만 DEV/QA 모드 단축키. UI.md 화면 전환 단축키와 동기 |
| `Game_Settings_Modal.md` | 화면 6(설정) 모달. UI.md §화면 6 와 동기 |
| `Player_Edit_Modal.md` | 좌석 인라인 편집. UI.md 좌석 탭→편집 플로우와 동기 |
| `Statistics.md` | 화면 5(통계) 필드. UI.md §화면 5 와 동기 |
| `Multi_Table_Operations.md` | 1 CC = 1 table 원칙 재확인. UI.md 개요부와 동기 |
| `Undo_Recovery.md` | 전역 Undo 스택 정책. UI.md 각 화면의 Undo 버튼 동작과 동기 |
| `Overview.md` | CC 전체 개요. UI.md 개요부와 동기 |

---

## Visual Uplift (B-team4-011, 2026-05-06)

> **트리거**: 2026-05-05 디자이너 React 시안 critic 판정 결과 — 시안은 production 부적격 (D7 위반 등 12 결함) 이나 시각 자산 7종은 우월. SSOT: `docs/4. Operations/CC_Design_Prototype_Critic_2026_05_06.md`.
>
> **가드 (HARD)**: hole card 값 노출 금지 / CDN 의존 금지 / 통신 모델 변경 금지 / HandFSM 9-state 변경 금지.

### V1 — KeyboardHintBar (구현 완료)

상단 InfoBar 아래 32px 슬림 바. F·C·B·A·N·M 6 칩 + Ctrl+L 디버그 칩. `actionButtonProvider` 매트릭스에 동기 — 비활성 키는 opacity 45%. 상세 정책: `Keyboard_Shortcuts.md §5`.

### V2 — StatusBar 통합 (예정)

기존 분산된 BO/RFID/Engine 상태 표시 (Toolbar dot + EngineConnectionBanner + RfidStatusBanner) 를 **단일 한 줄 StatusBar (40px)** 로 통합. 좌측 그룹 = 연결 상태 dot 3종, 중앙 = Hand# / Phase / GameType / Blinds, 우측 = Players ratio + 아이콘.

레이아웃:
```
+-------------------------------------------------------------+
| ●BO ●RFID ●Engine | Op aiden | Table F1 || Hand #42 PRE-FLOP|
|                                            NLH 100/200/25 Lvl12|
|                                            6/8 [🏷][👁][⚙] |
+-------------------------------------------------------------+
```

오류 상태 (Engine offline 등) 는 StatusBar 위에 separate banner 로 떠오름 — banner ↔ StatusBar 책임 분리.

### V3 — MiniDiagram (예정)

Toolbar 좌측 또는 InfoBar 영역에 120×120px 미니 oval 테이블. 10좌석 점 + D/SB/BB 뱃지 + ACTING 펄스. POT 카드 인접 표시. CustomPaint 기반 — SVG/외부 라이브러리 의존 없음.

용도: 운영자가 SeatArea 의 큰 oval 외에도 "테이블 전체 흐름" 을 한눈에 파악. Multi-Table 모드 (1:N) 에서 다른 테이블 미니맵 비교 시 유리.

### V5 — Seat Cell 7행 보강 (예정)

기존 §"좌석 배치" 의 Seat Cell (3-4행) 을 **7행 컬럼 레이아웃**으로 재구성. 행 구성 (위 → 아래):

```
 1행: ACTING / WAITING / FOLD / DELETE strip (상태별 색상)
 2행: S번호 (대형, full-width)
 3행: Position (STRADDLE / SB·BB / D — 3 sub-rows, ‹ › shift 화살표)
 4행: Country (flag) + Name (인라인 편집)
 5행: Hole cards — 뒷면만 (D7 강제, face-up 절대 금지)
 6행: STACK $128,400 (mono, 인라인 편집)
 7행: BET / LAST action
```

기존 좌석 배치 (`§"좌석 배치"`) 는 oval 360° 분포를 유지. 컬럼 7행 보강은 **각 SeatCell 내부 정보 밀도** 만 변경.

### V6 — ACTING 펄스 글로우 강화 (예정)

기존 `_glowController` (1.2s repeat, 0.4 → 1.0 alpha) 를 디자인 시안의 `oklch(0.78 0.16)` accent + dual-ring SVG 영감 받아 강화. 외부 ring (radius 1.5×) 추가, 0.6 → 0 opacity 1.2s 페이드. 가독성 + 시각 강조 동시 확보.

§7 글로우 색상 팔레트 (§7.1) / 주기 0.8초 (§7.3) **변경 없음** — V6 은 ring shape 만 보강.

### V7 — Tweaks Panel (예정, debug 한정)

디자인 시안의 `tweaks-panel.jsx` 영감 — accent hue / felt hue / engine state / display 옵션 토글. **Release 빌드 미포함** — `kDebugMode || kProfileMode` 시에만 노출. 카지노 조명/스튜디오 환경별 hue 조절 시연용.

위치: `lib/features/command_center/widgets/tweaks_panel.dart` (예정).

### 진행 추적

| ID | 위젯 | 상태 |
|:--:|------|:----:|
| V1 | KeyboardHintBar | ✅ 2026-05-06 |
| V2 | cc_status_bar | ⏳ |
| V3 | mini_table_diagram | ⏳ |
| V4 | position_shift_chip | ⏳ |
| V5 | SeatCell 7행 | ⏳ |
| V6 | ACTING glow ring | ⏳ |
| V7 | tweaks_panel | ⏳ |

상세: `Backlog/B-team4-011-cc-visual-uplift-from-design-prototype.md`
