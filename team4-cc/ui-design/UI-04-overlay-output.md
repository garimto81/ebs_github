# UI-04 Overlay Output — 10개 요소 배치

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 10개 오버레이 요소 배치, 1080p/4K 대응, 크로마키/풀 배경 |

---

## 개요

Overlay는 시청자용 방송 그래픽을 렌더링하는 Flutter + Rive 앱이다. CC와 1:1 대응하며, CC에서 입력된 게임 데이터를 10개 오버레이 요소로 시각화한다.

> 참조: BS-07-01-elements, BS-00 §1

> **28종 vs 10개 해소**: Foundation PRD Ch.6의 "방송 그래픽 28종"은 Layer 1(8종) + Layer 2(12종) + Layer 3(8종)의 전체 카탈로그다. 이 문서의 "10개 오버레이 요소"는 Layer 1(8종) + 보조 요소(2종)으로, EBS Overlay 앱이 직접 렌더링하는 실시간 요소만 다룬다. Layer 2/3는 방송 스위처(vMix/OBS)에서 합성하므로 이 문서의 범위 밖이다.

---

## 전체 배치 와이어프레임 (1080p)

10개 오버레이 요소의 기본 배치:

```
+-------------------------------------------------+
| [Hand #42]  [NL Hold'em]  [Blinds 100/200]      |
|                                                 |
|        [S6]      [S7]      [S8]                 |
|     Name|Stack  Name|Stack Name|Stack           |
|     [c][c] 45%  [c][c] 12% [c][c] 8%           |
|                                                 |
|  [S5]                            [S9]           |
|  Name|Stack                    Name|Stack       |
|  [c][c] 20%                   [c][c] 15%        |
|                                                 |
|            [F1] [F2] [F3] [T] [R]               |
|                                                 |
|  [S4]          [D]               [S0]           |
|  Name|Stack                    Name|Stack       |
|  FOLD                          [c][c] BET 400   |
|                                                 |
|     [S3]      [S2]      [S1]                    |
|     Name|Stack Name|Stack Name|Stack            |
|     [c][c] CHECK [c][c] CALL [c][c] ALL-IN      |
|                                                 |
+-------------------------------------------------+
| [POT: 2,400]  |  BLINDS: 100/200  |  WSOP 2026 |
+-------------------------------------------------+
```

---

## 좌석 배치 — 타원형 10석

### 좌석 좌표 (1080p: 1920x1080)

| 좌석 | 위치 | X (px) | Y (px) |
|:----:|------|:------:|:------:|
| S0 | 우측 중앙 | 1560 | 540 |
| S1 | 우하단 | 1400 | 780 |
| S2 | 하단 중앙 | 960 | 840 |
| S3 | 좌하단 | 520 | 780 |
| S4 | 좌측 중앙 | 360 | 540 |
| S5 | 좌상단 | 520 | 300 |
| S6 | 상단 좌 | 700 | 180 |
| S7 | 상단 중앙 | 960 | 150 |
| S8 | 상단 우 | 1220 | 180 |
| S9 | 우상단 | 1400 | 300 |

### 좌석 위젯 레이아웃

각 좌석은 다음 요소를 포함한다:

```
+---------------------------+
| John Doe            [D]  |  Player Name + Position
| 125,000                  |  Chip Stack
| [Ah] [Kd]               |  Hole Cards (2장)
| CHECK                    |  Action Badge
| ████████░░ 82%           |  Equity Bar
+---------------------------+
```

| 요소 | 크기 (1080p) | 데이터 소스 |
|------|:-----------:|-----------|
| Player Name | 14px, max 120px width | BO Player DB |
| Position Badge | 20x20px | Game Engine (D/SB/BB/STR) |
| Chip Stack | 14px, Roboto Mono | Game Engine |
| Hole Cards | 48x67px x 2장 | RFID HAL / Manual |
| Action Badge | 12px, 60x24px | CC 액션 입력 |
| Equity Bar | 120x8px | Game Engine (Monte Carlo/LUT) |
| Hand Rank Label | 11px | Hand Evaluator |

---

## 중앙 영역 — Board + Pot

### Board 카드 5장

```
+---+ +---+ +---+   +---+   +---+
| A | | K | | 7 |   | 3 |   | 9 |
| ♠ | | ♦ | | ♣ |   | ♠ |   | ♥ |
+---+ +---+ +---+   +---+   +---+
 Flop  Flop  Flop    Turn   River
```

| 속성 | 값 (1080p) |
|------|:---------:|
| 카드 크기 | 72 x 101 px |
| 카드 간격 | 8px |
| Flop-Turn 간격 | 16px |
| Turn-River 간격 | 16px |
| 중앙 X | 960px |
| 중앙 Y | 480px |
| Board Position | `board_pos_type`: left(0), centre(1), right(2) |

### Pot Display

```
+-----------------------------+
|     POT: 2,400              |
| Side Pot 1: 800 (Seat 3,5) |
+-----------------------------+
```

| 속성 | 값 |
|------|-----|
| 위치 | Board 카드 하단 중앙 |
| 메인 팟 | 항상 표시, bold |
| 사이드 팟 | 0~N개, 생성 시 순차 표시 |
| 숫자 포맷 | 콤마 구분, Roboto Mono |

---

## 상단 정보 영역

```
+-------------------------------------------------+
| Hand #42 | NL Hold'em | Blinds: 100/200 (Lv.5) |
+-------------------------------------------------+
```

| 요소 | 위치 | 바인딩 |
|------|------|--------|
| Hand # | 우상단 좌 | `hand_number` |
| Game Type | 우상단 중 | `game_type` |
| Blind Level | 우상단 우 | `SB/BB (Level N)` |

---

## 하단 정보 영역 (Lower Third)

```
+-------------------------------------------------+
| BLINDS: 100/200 | POT: 2,400 | 2026 WSOP       |
+-------------------------------------------------+
```

| 요소 | 바인딩 | 설정 |
|------|--------|------|
| Blinds | `blind_structure.current` | 항상 표시 |
| Pot | `pot.total` | 항상 표시 |
| Custom Text | `lower_third_text` | Admin 수동 입력 |
| Ticker Stats | `strip_display_type` | chipcount/vpip/pfr/agr/wtsd |

---

## 딜러 버튼 (Dealer Button)

```
  +---+
  | D |  (좌석 옆, 딜러 위치에만)
  +---+
```

| 속성 | 값 |
|------|-----|
| 크기 | 28x28px |
| 위치 | 딜러 좌석 좌표 기준 오프셋 (+40px 우측) |
| 이동 | `StartHand` 이벤트 시 새 딜러 위치로 슬라이드 |
| 스킨 | 이미지 재정의 가능 |

---

## 1080p vs 4K 해상도 대응

### 좌표 스케일링

| 속성 | 1080p (1920x1080) | 4K (3840x2160) | 스케일 |
|------|:-----------------:|:--------------:|:------:|
| 카드 크기 | 48x67 (홀카드), 72x101 (보드) | 96x134, 144x202 | 2x |
| 폰트 크기 | 14px (이름), 12px (배지) | 28px, 24px | 2x |
| 좌석 좌표 | 위 테이블 참조 | 전체 x2 | 2x |
| Equity 바 | 120x8px | 240x16px | 2x |
| 딜러 버튼 | 28x28px | 56x56px | 2x |

### 해상도 전환

Settings > Output > Resolution에서 선택. 전환 시 모든 좌표/크기가 스케일 팩터로 자동 조정.

---

## 크로마키 모드 vs 풀 배경 모드

### 크로마키 모드

```
+-------------------------------------------------+
| (녹색/파란색 단색 배경)                          |
|                                                 |
|   오버레이 요소만 렌더링                         |
|   배경 = 크로마키 색상                           |
|   방송 믹서에서 배경 제거 후 합성                 |
|                                                 |
+-------------------------------------------------+
```

| 속성 | 값 |
|------|-----|
| Green | `#00FF00` |
| Blue | `#0000FF` |
| Spill Reduction | 0~100% (Settings > Output) |

### 풀 배경 모드

```
+-------------------------------------------------+
| (스킨 정의 배경 이미지/색상)                     |
|                                                 |
|   포커 테이블 이미지 + 오버레이 요소              |
|   독립 그래픽으로 사용 가능                       |
|   NDI로 직접 송출                                |
|                                                 |
+-------------------------------------------------+
```

| 속성 | 값 |
|------|-----|
| 배경 | 스킨 JSON `background_image` 또는 `background_color` |
| 테이블 이미지 | 스킨 JSON `table_image` |
| 테두리 | 스킨 정의 |

---

## 10개 요소 가시성 토글

모든 오버레이 요소는 Settings에서 개별 ON/OFF 가능.

| # | 요소 | 설정 키 | 기본값 |
|:-:|------|---------|:------:|
| 1 | Hole Cards | `show_holecards` | ON |
| 2 | Board (커뮤니티 카드) | `show_board` | ON |
| 3 | Player Name | `show_player_name` | ON |
| 4 | Chip Stack | `show_chip_stack` | ON |
| 5 | Pot Display | `show_pot` | ON |
| 6 | Equity Bar | `show_equity` | ON |
| 7 | Hand Rank Label | `show_rank` | ON |
| 8 | Action Badge | `show_action_badge` | ON |
| 9 | Dealer Button | `show_dealer_button` | ON |
| 10 | Lower Third | `show_lower_third` | ON |

> 가시성 토글은 Overlay 렌더링에만 영향. Game Engine 로직에는 영향 없음.

---

## 영향 받는 문서

| 문서 | 관계 |
|------|------|
| BS-07-01-elements | 10개 요소 트리거/갱신/데이터 소스 |
| BS-07-02-animations | 요소별 애니메이션 상세 |
| UI-00-design-system | 포커 전용 토큰 (수트, 카드, 배지) |
| UI-03-settings | Output/Overlay 탭 설정 |
