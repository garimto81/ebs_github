# UI-01 Lobby — 6화면 와이어프레임

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | Login~Player 6화면 레이아웃, 데이터 바인딩, 네비게이션 |

---

## 개요

Lobby는 EBS의 테이블 관리 웹 앱이다. Series > Event > Flight > Table > Player 5계층 탐색으로 Feature Table을 찾아 Command Center로 진입한다. 6화면(Login + 5계층)으로 구성된다.

> 참조: BS-02-lobby, BS-00 §1, PRD Ch.8

---

## Breadcrumb 네비게이션

모든 화면(Login 제외)에 상단 Breadcrumb이 표시된다.

```
+-----------------------------------------------+
| EBS > Series Name > Event #1 > Day 1A > Tbl 3 |
+-----------------------------------------------+
```

| 요소 | 동작 |
|------|------|
| EBS (홈) | Series 목록으로 이동 |
| Series 이름 | 해당 Series의 Event 목록 |
| Event 이름 | 해당 Event의 Flight 목록 |
| Flight 이름 | 해당 Flight의 Table 목록 |
| Table 이름 | 해당 Table의 Player 목록 |

---

## Active CC 모니터링 패널

Lobby 헤더 우측에 활성 CC 드롭다운이 표시된다.

```
+---------------------------------------------+
| [EBS Logo]  Breadcrumb...   [CC v] [Set ⚙]  |
+---------------------------------------------+
         CC 드롭다운 펼침:
         +----------------------------------+
         | ● Table 1  Hand #42  NL Hold'em  |
         | ● Table 3  Hand #15  PLO4        |
         | ○ Table 5  IDLE                  |
         +----------------------------------+
```

| 상태 | 아이콘 | 클릭 동작 |
|------|:------:|---------|
| ● LIVE | 녹색 원 | 해당 CC로 전환 (Open) |
| ○ IDLE | 회색 원 | 해당 Table로 이동 |
| ⚠ ERROR | 빨간 삼각 | 해당 CC로 전환 + 경고 |

---

## 화면 0: Login

> 목업 참조: `docs/mockups/ebs-lobby-00-login.html`

```
+---------------------------------------------+
|                                             |
|              [EBS LOGO]                     |
|                                             |
|         +-------------------------+         |
|         |  Email                  |         |
|         +-------------------------+         |
|         |  Password          [👁] |         |
|         +-------------------------+         |
|         |  [ ] Remember me        |         |
|         +-------------------------+         |
|         |      [  LOGIN  ]        |         |
|         +-------------------------+         |
|         |  Forgot password?       |         |
|         +-------------------------+         |
|                                             |
+---------------------------------------------+
```

### 구성 요소

| 요소 | 타입 | 바인딩 |
|------|------|--------|
| Email | TextField | `auth.email` |
| Password | TextField (masked) | `auth.password` |
| Remember me | Checkbox | `auth.remember` |
| LOGIN | Button (primary) | `POST /auth/login` |
| Forgot password? | Link | 비밀번호 재설정 페이지 |

### 네비게이션

| 이벤트 | 다음 화면 |
|--------|----------|
| 로그인 성공 + 세션 없음 | 화면 1 (Series) |
| 로그인 성공 + 세션 있음 | 세션 복원 다이얼로그 |

---

## 화면 1: Series 목록

> 목업 참조: `docs/mockups/ebs-lobby-01-series.html`

```
+-------------------------------------------------+
| [EBS]                        [CC v] [Settings]  |
+-------------------------------------------------+
| EBS > Series                                    |
+-------------------------------------------------+
| [Search...                 ] [+ New Series]     |
+-------------------------------------------------+
| +-------------------+  +-------------------+    |
| | 2026 WSOP         |  | 2026 WSOPC        |   |
| | Jun 1 - Jul 15    |  | Mar 1 - Mar 20    |   |
| | Events: 95        |  | Events: 30        |   |
| | Status: ● Active  |  | Status: ○ Closed  |   |
| +-------------------+  +-------------------+    |
| +-------------------+                           |
| | 2026 WSOP Europe  |                           |
| | Oct 5 - Oct 25    |                           |
| | Events: 15        |                           |
| | Status: ● Active  |                           |
| +-------------------+                           |
+-------------------------------------------------+
```

### 구성 요소

| 요소 | 타입 | 바인딩 |
|------|------|--------|
| Search | TextField | 시리즈 이름 필터 |
| + New Series | Button | 수동 생성 다이얼로그 |
| Series Card | Card | `GET /series` |
| Series 이름 | Text (h3) | `series.name` |
| 기간 | Text (caption) | `series.start ~ end` |
| Event 수 | Text (body) | `series.event_count` |
| Status | Badge | `series.status` |

### 네비게이션

| 이벤트 | 다음 화면 |
|--------|----------|
| Series Card 클릭 | 화면 2 (Events) |

---

## 화면 2: Event 목록

> 목업 참조: `docs/mockups/ebs-lobby-02-events.html`

```
+-------------------------------------------------+
| EBS > 2026 WSOP                  [CC v] [Set ⚙] |
+-------------------------------------------------+
| [Search...    ] [Filter: All v] [+ New Event]   |
+-------------------------------------------------+
| # | Event Name           | Game    | Status    |
|---|----------------------|---------|-----------|
| 1 | $10K NL Hold'em      | HOLDEM  | ● Active  |
| 2 | $1,500 PLO           | PLO4    | ○ Pending |
| 3 | $50K PPC             | MIX     | ● Active  |
| 4 | $1K NL Hold'em       | HOLDEM  | ✓ Done    |
+-------------------------------------------------+
| Showing 4 of 95 events           [< 1 2 3 ... >]|
+-------------------------------------------------+
```

### 구성 요소

| 요소 | 타입 | 바인딩 |
|------|------|--------|
| Search | TextField | 이벤트명 필터 |
| Filter | Dropdown | 상태 필터 (All/Active/Pending/Done) |
| + New Event | Button | 수동 생성 다이얼로그 |
| Event Table | DataTable | `GET /series/{id}/events` |
| Event # | Text | `event.number` |
| Event Name | Text (link) | `event.name` |
| Game | Badge | `event.game_type` |
| Status | Badge | `event.status` |

### 네비게이션

| 이벤트 | 다음 화면 |
|--------|----------|
| Event 행 클릭 | 비밀번호 입력 → 화면 3 |

---

## 화면 3: Flight 목록

> 목업 참조: `docs/mockups/ebs-lobby-03-flights.html`

```
+-------------------------------------------------+
| EBS > 2026 WSOP > Event #1      [CC v] [Set ⚙] |
+-------------------------------------------------+
| Event #1: $10K NL Hold'em Championship         |
| Game: HOLDEM | Blinds: 100/200 | Players: 1,200|
+-------------------------------------------------+
| Flight     | Tables | Players | Status          |
|------------|--------|---------|-----------------|
| Day 1A     |   25   |   300   | ● Running       |
| Day 1B     |   20   |   250   | ○ Pending       |
| Day 1C     |    0   |     0   | ○ Pending       |
| Day 2      |   12   |   150   | ○ Pending       |
+-------------------------------------------------+
| [+ New Flight]                                  |
+-------------------------------------------------+
```

### 구성 요소

| 요소 | 타입 | 바인딩 |
|------|------|--------|
| Event 요약 | InfoPanel | `event.name`, `game_type`, `blinds` |
| Flight Table | DataTable | `GET /events/{id}/flights` |
| Flight 이름 | Text | `flight.name` |
| Tables 수 | Number | `flight.table_count` |
| Players 수 | Number | `flight.player_count` |
| Status | Badge | `flight.status` |
| + New Flight | Button | 수동 생성 다이얼로그 |

### 네비게이션

| 이벤트 | 다음 화면 |
|--------|----------|
| Flight 행 클릭 | 화면 4 (Tables) |

---

## 화면 4: Table 관리

> 목업 참조: `docs/mockups/ebs-lobby-04-tables.html`

```
+-------------------------------------------------+
| EBS > 2026 WSOP > #1 > Day 1A   [CC v] [Set ⚙] |
+-------------------------------------------------+
| [Search...  ] [Filter: All v]  [+ New Table]    |
+-------------------------------------------------+
| +---------------------+ +---------------------+ |
| | Table 1 (Feature)   | | Table 2             | |
| | ● LIVE   Hand #42   | | ● LIVE   Hand #28   | |
| | NL Hold'em 100/200  | | NL Hold'em 100/200  | |
| | Players: 8/10       | | Players: 9/10       | |
| | RFID: ● Online      | | RFID: ○ N/A         | |
| | NDI: ● Active       | | NDI: —              | |
| | Op: J.Smith         | | Op: K.Park          | |
| | [Launch] [Settings] | | [Launch] [Settings] | |
| +---------------------+ +---------------------+ |
| +---------------------+ +---------------------+ |
| | Table 3             | | Table 4             | |
| | ○ SETUP             | | ○ EMPTY             | |
| | —                   | | —                   | |
| | Players: 0/10       | | Players: 0/10       | |
| | [Edit]   [Delete]   | | [Edit]   [Delete]   | |
| +---------------------+ +---------------------+ |
+-------------------------------------------------+
```

### 구성 요소

| 요소 | 타입 | 바인딩 |
|------|------|--------|
| Table Card | Card | `GET /flights/{id}/tables` |
| Table 이름 | Text (h3) | `table.name` |
| (Feature) | Badge | `table.is_feature` |
| Status | Badge | `table.status` (TableFSM) |
| Hand # | Text | WebSocket `hand_started` |
| Game/Blinds | Text | `table.game_type`, `blinds` |
| Players | Text | `seated / max_seats` |
| RFID | StatusIndicator | `table.rfid_status` |
| NDI | StatusIndicator | `table.output_status` |
| Operator | Text | `table.operator_name` |
| [Launch] | Button (primary) | CC 인스턴스 생성 |
| [Settings] | Button | Settings 다이얼로그 |
| [Edit] | Button | 테이블 수정 다이얼로그 |
| [Delete] | Button (danger) | 확인 후 삭제 |

### LOCK/CONFIRM/FREE (CC LIVE 상태)

CC가 LIVE일 때 Lobby에서의 설정 변경 가능 여부:

| 분류 | 변경 가능 | 예시 |
|:----:|:---------:|------|
| **LOCK** | 불가 (비활성) | Game Type, Max Players |
| **CONFIRM** | 확인 후 다음 핸드 적용 | Blinds, Output |
| **FREE** | 즉시 변경 | Overlay, Display |

### 네비게이션

| 이벤트 | 다음 화면 |
|--------|----------|
| Table Card 클릭 | 화면 5 (Players) |
| [Launch] 클릭 | CC Flutter 앱 실행 |

---

## 화면 5: Player 관리

> 목업 참조: `docs/mockups/ebs-lobby-05-players.html`

```
+-------------------------------------------------+
| EBS > WSOP > #1 > Day 1A > Tbl 1 [CC v] [⚙]    |
+-------------------------------------------------+
| Table 1 (Feature) — NL Hold'em 100/200          |
| Status: ● LIVE | Hand #42 | Op: J.Smith         |
+-------------------------------------------------+
|           [ 6 ]   [ 7 ]   [ 8 ]                |
|        [ 5 ]                  [ 9 ]             |
|        [ 4 ]      [POT]      [ 0 ]             |
|           [ 3 ]   [ 2 ]   [ 1 ]                |
+-------------------------------------------------+
| Seat | Player        | Stack    | Status        |
|------|---------------|----------|---------------|
|  0   | Mike Johnson  | 125,000  | ● Active      |
|  1   | Sarah Kim     |  98,500  | ● Active      |
|  2   | (empty)       |     —    | ○ Vacant      |
|  3   | Tom Lee       |  45,200  | ● Active      |
| ...  | ...           | ...      | ...           |
+-------------------------------------------------+
| [+ Add Player] [Auto Seat Draw] [Enter CC]      |
+-------------------------------------------------+
```

### 구성 요소

| 요소 | 타입 | 바인딩 |
|------|------|--------|
| Table 요약 | InfoPanel | `table.*` |
| 테이블 시각화 | SeatGrid (타원) | `seats[0..9]` |
| Seat 번호 | SeatWidget | `seat.index` |
| Player Table | DataTable | `GET /tables/{id}/seats` |
| Player 이름 | Text | `seat.player.name` |
| Stack | Number (mono) | `seat.player.stack` |
| Status | Badge | `seat.status` (SeatFSM) |
| + Add Player | Button | 플레이어 검색/등록 다이얼로그 |
| Auto Seat Draw | Button | 자동 좌석 배치 |
| Enter CC | Button (primary) | CC 전환 (이미 Launch된 경우) |

### 네비게이션

| 이벤트 | 다음 화면 |
|--------|----------|
| [Enter CC] 클릭 | CC 앱 전환 |
| Seat 클릭 | 플레이어 상세/배치 다이얼로그 |

---

## 화면 간 네비게이션 요약

```
Login ──→ Series ──→ Events ──→ Flights
                                   |
              CC ←── Players ←── Tables
```

| 전환 | 방향 | 트리거 |
|------|:----:|--------|
| Login → Series | 단방향 | 로그인 성공 |
| Series → Events | 양방향 | 카드 클릭 / Breadcrumb |
| Events → Flights | 양방향 | 행 클릭 / Breadcrumb |
| Flights → Tables | 양방향 | 행 클릭 / Breadcrumb |
| Tables → Players | 양방향 | 카드 클릭 / Breadcrumb |
| Players → CC | 단방향 | [Enter CC] / [Launch] |
