# AT Annotation Plan

## 1. 요소 통계 요약

| 화면 | 요소 수 | 주요 카테고리 | 특징 |
|------|:-------:|-------------|------|
| at-01 Setup Mode | 83 | titlebar(7), toolbar(5), card_area(10), seat(10), option(10), position(10), blind(17), game_settings(7), hand_control(6), navigation(1) | 행→개별 분리 후 83개. 고유 52개 |
| at-02 Pre-Flop Action | 41 | titlebar(1), toolbar(9), card_icon(10), seat(10), action_button(4) | 10좌석 카드+레이블 반복 구조 |
| at-03 Card Selector | 8 | chrome(1), card_grid(4), navigation(1), display(1), action(1) | 52장 카드 그리드 4행, 최소 요소 |
| at-04 Post-Flop Action | 41 | at-02 동일 구조, diff 7개 요소 | CALL->CHECK, RAISE-TO->BET |
| at-05 Statistics | 22 | table_header(7), broadcast_control(9), table_data(1) | 좌측 테이블 + 우측 방송 제어 |
| at-06 RFID Registration | 9 | titlebar(5), rfid(3), background(1) | 모달 오버레이, 최소 인터랙션 |
| **합계** | **204** | | at-01 행 분리 후 증가. at-02/04 중복 제외 시 실질 **170개**. 총 배지 134개 |

## 2. 공통 요소 (Cross-Screen)

### 타이틀바 (at-01~06 공통)

모든 화면에 윈도우 크롬 존재. at-01/06은 개별 요소(5개), at-02/03/04/05는 단일 그룹(1개)으로 기록됨.

- 윈도우 크롬: App Icon, Title Text, Minimize, Maximize, Close

### 툴바 (at-01, at-02, at-04 공통)

| 요소 | at-01 id | at-02 id | at-04 id | protocol | 기능 설명 |
|------|:--------:|:--------:|:--------:|----------|----------|
| USB Connection | 6 | 2 | 2 | ConnectToServer (CONNECT) | Server 연결/해제 토글. 연결 성공 시 아이콘 활성(초록), 실패 시 비활성(회색) |
| WiFi Signal | 7 | 3 | 3 | NetworkQualityChanged (콜백) | 네트워크 품질 실시간 표시. 지연/패킷 손실 시각화. 신호 강도 아이콘 3단계 |
| HAND 번호 | 8-9 | 5 | 5 | GameInfoResponse.HandNumber (GAME_INFO) | 현재 핸드 번호 표시. 좌우 화살표로 이전/다음 핸드 탐색. AUTO 버튼으로 자동 증가 모드 전환 |
| Camera/Video | 13 | 6 | 6 | SendVideoSources | 카메라 소스 선택. SendVideoSources(cam_num)으로 방송 카메라 번호 설정 |
| GFX | 14 | 7 | 7 | SendGfxEnable (GFX_ENABLE) | 방송 그래픽 ON/OFF 토글. 반전 전송(!enable). 빨간=활성, 회색=비활성. 키보드 `G` |
| REGISTER | -- | 8 | 8 | RegisterDeck (CARD_VERIFY) | RFID 덱 등록 모드 진입. 52장 순차 스캔 시작. at-06 화면으로 전환 |
| Fullscreen | 16 | 9 | 9 | -- | 윈도우 전체화면 토글. 로컬 UI 전용 (서버 통신 없음) |
| Close(App) | 17 | 10 | 10 | -- | ActionTracker 앱 종료. Server 연결 해제 후 프로세스 종료 |

at-01은 Snapshot 버튼(id:15)이 있고 REGISTER가 없다. at-02/04는 REGISTER가 있고 Snapshot이 없다.

### 좌석 영역 (at-01, at-02, at-04 공통)

- 카드 아이콘 10좌석: at-02/04 id 11~20 (card_icon), at-01 id 18~27 (card_area, 형태 다름)
- 좌석 레이블 10좌석: at-02/04 id 21~30 (seat), at-01 id 28 (단일 행)

### 액션 패널 (at-02, at-04 공통)

| 요소 | id | protocol | 기능 설명 |
|------|:--:|----------|----------|
| MISS DEAL | 31 | SendMissDeal (MISS_DEAL) | 미스딜 선언. 현재 핸드를 무효화하고 카드 재배분. 핸드 번호 유지 |
| TAG | 32 | SendTag → TagRequest (TAG) | 방송 핸드 라벨 태깅. SendTag(tag)로 텍스트 전송 (콤마→틸드 치환). SendClearTag()로 해제 |
| Community Cards | 33 | -- (상태 변동) | 커뮤니티 카드 영역. Flop 3장→Turn 1장→River 1장 순차 표시. RFID 자동 수신 또는 수동 입력(카드 클릭→at-03) |
| Player Info Bar | 34 | PlayerInfoResponse (PLAYER_INFO) | 현재 액션 플레이어 정보 표시. "(좌석번호) 이름 - STACK 금액" 형식. action_on 좌석과 동기화 |
| Recording | 35 | -- | 녹음/녹화 상태 표시. 빨간 ● 아이콘 = 녹화 중 |
| HIDE GFX | 36 | SendGfxEnable (GFX_ENABLE) | 방송 그래픽 임시 숨김. GFX 버튼과 동일 프로토콜이나 역방향. Undo 작업 중 방송 노출 방지용 |
| Back (Undo) | 37 | SendGameSaveBack (GAME_SAVE_BACK) | 마지막 액션 취소. History Stack Pop → GameState 복원 → 전체 클라이언트 브로드캐스트. 최대 5단계 Undo. 키보드 `U` |

## 2.5 원본 스크린샷 참조

Annotation 대상 원본 6장. 경로: `03_Reference_ngd/action_tracker/`

### at-01 Setup Mode (786×553)

> <img src="../at-01-setup-mode.png" alt="AT Setup Mode" style="max-width: 786px;">
>
> *게임 시작 전 설정. 10좌석 + 블라인드 + 게임 옵션. **83개 요소** — 가장 복잡.*

| 코드 범위 | 카테고리 | 수량 |
|-----------|---------|:----:|
| COM-TB-01~05 | 타이틀바 | 5 |
| COM-TL-01,02,04,05,07,08 | 툴바 (REGISTER 제외) | 6 |
| COM-CD-01~10 | 카드 영역 | 10 |
| COM-ST-01~10 | 좌석 라벨 | 10 |
| S01-001~006 | hand_control + Snapshot | 6 |
| S01-007~016 | Straddle 버튼 (×10) | 10 |
| S01-017~026 | Position 버튼 (×10) | 10 |
| S01-027~043 | Blind 컨트롤 + 증감 | 17 |
| S01-044~052 | Game Settings + 네비게이션 | 9 |

### at-01 Setup Mode (52개 고유)

| 카테고리 | 요소 | 수량 |
|----------|------|:----:|
| hand_control | Hand Number Box, HAND Label, Back/Forward Arrow, AUTO, Hand Input, SINGLE BOARD | 6 |
| option | Straddle 버튼 (10좌석 × 개별) | 10 |
| position | Position 버튼 - D/SB/BB (10좌석 × 개별) | 10 |
| blind | CAP, ANTE, BTN BLIND, DEALER, SB, BB, 3B 컨트롤 + 각 증감 버튼 | 17 |
| game_settings | MIN CHIP, 7 DEUCE, BOMB POT, # BOARDS, HIT GAME, HOLDEM | 6 |
| navigation | SETTINGS 버튼 | 1 |

**hand_control (6개)**:

| 요소 | 기능 설명 |
|------|----------|
| Hand Number Box | 현재 핸드 번호 표시 영역. 직접 입력으로 특정 핸드로 이동 가능 |
| HAND Label | "HAND" 텍스트 라벨 |
| Back/Forward Arrow | 이전/다음 핸드 탐색. SendResetHand(next:false) / SendNextHand(next:true) |
| AUTO | 자동 핸드 번호 증가 모드 토글. 활성 시 StartHand 호출마다 HandNumber 자동 +1 |
| Hand Input | 핸드 번호 직접 입력 필드. 숫자 입력 후 Enter로 확정 |
| SINGLE BOARD | 단일/복수 보드 전환. Run It Twice 등 멀티보드 비활성화 시 사용 |

**option (1개 — Straddle Buttons Row)**: 10좌석 각각에 Straddle 토글 버튼. 활성 좌석은 골든 배경. 블라인드 구조에 추가 강제 베팅 설정.

**position (1개 — Position Buttons Row)**: 10좌석 D(Dealer)/SB(Small Blind)/BB(Big Blind) 3포지션 토글. 노란 배경으로 활성 표시. 마우스 클릭으로 순환 설정.

**blind (17개)**:

| 요소 | 기능 설명 |
|------|----------|
| CAP | 베팅 캡 설정. 라운드당 최대 레이즈 횟수 제한 (예: Cap 4 = 최대 4번 레이즈) |
| ANTE | 앤티 금액 설정. ante_type enum 7가지: 표준/버튼/BB/BB_BB1st/라이브/TB/TB_TB1st |
| BTN BLIND | 버튼 블라인드 금액. 딜러 포지션 강제 베팅 (특수 게임 구조) |
| DEALER | 딜러 앤티 금액 설정 |
| SB | Small Blind 금액. 증감 화살표(`<` `>`)로 MIN_CHIP 단위 조정 |
| BB | Big Blind 금액. 증감 화살표(`<` `>`)로 조정. 일반적으로 SB의 2배 |
| 3B (3rd Blind) | 3번째 블라인드 (UTG Straddle). 선택적 활성화 |
| 각 증감 버튼 (10개) | 위 7개 블라인드 각각에 대한 `<` `>` 증감 화살표. MIN_CHIP 단위로 값 변경. WriteGameInfo()로 서버 전송 |

**game_settings (6개)**:

| 요소 | 기능 설명 |
|------|----------|
| MIN CHIP | 최소 칩 단위 설정. 모든 베팅/블라인드 금액의 기본 단위 (예: 25, 50, 100). WriteGameInfo의 smallest_chip 필드 |
| 7 DEUCE | 7-2 게임 토글. 7-2 오프수트로 승리 시 보너스 규칙 활성화 |
| BOMB POT | 봄팟 모드 토글. 모든 플레이어가 동일 금액 강제 투입 후 Flop부터 시작 |
| # BOARDS | 보드 수 설정 (1~3). Run It Twice/Thrice 지원. SendRunItTimes()로 보드 추가 |
| HIT GAME | Hit & Run 방지 규칙 토글 |
| HOLDEM | 게임 타입 선택. SendGameType(gametype: 0~3 순환). Hold'em/Omaha/Stud 등. SendGameVariant로 세부 변형 선택 |

**navigation (1개 — SETTINGS 버튼)**: 게임 설정 팝업 열기. 블라인드 구조, 타이머, 토너먼트 설정 등 상세 옵션 접근.

### at-02 Pre-Flop Action (786×553)

> <img src="../at-02-action-preflop.png" alt="AT Pre-Flop" style="max-width: 786px;">
>
> *프리플롭 액션. SEAT 1 빨간(현재턴), FOLD/CALL/RAISE-TO/ALL IN. **41개 요소.***

| 코드 범위 | 카테고리 | 수량 |
|-----------|---------|:----:|
| COM-TB | 타이틀바 (그룹) | 1 |
| COM-TL-01~08 | 툴바 (REGISTER 포함) | 8 |
| COM-CD-01~10 | 카드 아이콘 | 10 |
| COM-ST-01~10 | 좌석 라벨 | 10 |
| COM-AP-01~07 | 액션 패널 (MISS DEAL~Undo) | 7 |
| S02-001~005 | 입력 필드 + 액션 버튼 4종 | 5 |

### at-02 Pre-Flop (4개 고유 액션 버튼)

| 요소 | id | 기능 설명 | 키보드 |
|------|:--:|----------|:------:|
| FOLD | 38 | 핸드 포기. SendPlayerFold(player). 좌석 회색 전환 + 카드 아이콘 어두운으로 변경 | `F` |
| CALL | 39 | 콜 (현재 베팅 매칭). SendPlayerCheckCall(player, biggest_bet_amt). Pre-Flop에서 BB 이상 베팅 존재 시 표시 | `C` |
| RAISE-TO | 40 | 레이즈 (베팅 증가). SendPlayerBet(player, amount). 금액 입력 NumPad 활성화. Post-Flop에서는 BET으로 변경 | `B` |
| ALL IN | 41 | 올인 (전체 스택 투입). SendPlayerBet(player, stack). 잔여 스택 0으로 설정 | `A` |

### at-03 Card Selector (786×460)

> <img src="../at-03-card-selector.png" alt="AT Card Selector" style="max-width: 786px;">
>
> *수동 카드 입력. 4 Suit × 13 Rank 그리드. 골든 브라운(♠♣) / 빨간(♥♦). **8개 요소** — 가장 단순.*

| 코드 범위 | 카테고리 | 수량 |
|-----------|---------|:----:|
| COM-TB | 타이틀바 (그룹) | 1 |
| S03-001~007 | Back, Display, OK, 카드 그리드 4행 | 7 |

### at-03 Card Selector (7개 고유)

| 요소 | 기능 설명 |
|------|----------|
| Back Button | 이전 화면(at-02/04)으로 복귀. 카드 선택 취소 |
| Selected Card Display | 현재 선택된 카드 미리보기. Suit 색상 적용 (♠♣ 골든브라운, ♥♦ 빨간) |
| OK Button | 카드 선택 확정. SendCardEnter(tag, cards)로 서버 전송. tag: P=플레이어 홀카드, B=보드, E=보드 수정 |
| Spade Row | ♠ 13장 (A~K). 골든브라운 배경. 클릭으로 선택/해제 토글 |
| Heart Row | ♥ 13장. 빨간 배경 |
| Diamond Row | ♦ 13장. 빨간 배경 |
| Club Row | ♣ 13장. 골든브라운 배경 |

### at-04 Post-Flop Action (786×553)

> <img src="../at-04-action-postflop.png" alt="AT Post-Flop" style="max-width: 786px;">
>
> *포스트플롭 액션. 7♥ 6♠ 4♥ Flop 표시, CHECK/BET. **at-02 대비 7개 diff** (id: 11,21,22,33,34,39,40). §4 Diff 분석 참조.*

| 코드 범위 | 카테고리 | 수량 |
|-----------|---------|:----:|
| COM-TB | 타이틀바 (그룹) | 1 |
| COM-TL-01~08 | 툴바 | 8 |
| COM-CD-01~10 | 카드 아이콘 | 10 |
| COM-ST-01~10 | 좌석 라벨 | 10 |
| COM-AP-01~07 | 액션 패널 | 7 |
| S04-001~005 | 입력 필드 + CHECK/BET/FOLD/ALL IN | 5 |

### at-05 Statistics / Register (786×553)

> <img src="../at-05-statistics-register.png" alt="AT Statistics" style="max-width: 786px;">
>
> *좌측 82% 통계 테이블 + 우측 18% 방송 제어. VPIP/PFR/AGRFq/WTSD/WIN. **22개 요소.***

| 코드 범위 | 카테고리 | 수량 |
|-----------|---------|:----:|
| COM-TB | 타이틀바 (그룹) | 1 |
| S05-001~007 | 테이블 헤더 7열 | 7 |
| S05-008 | 데이터 행 (SEAT 1-10) | 1 |
| S05-009~010 | Expand, Close | 2 |
| S05-011~021 | 방송 제어 패널 11종 | 11 |

### at-05 Statistics (21개 고유)

**테이블 헤더 (7)**:

| 요소 | 기능 설명 |
|------|----------|
| SEAT | 좌석 번호 (1~10). 활성/비활성 행 구분 |
| STACK | 현재 칩 스택. PlayerInfoResponse.Stack |
| VPIP% | Voluntarily Put $ In Pot. 자발적 팟 참여 비율. 프리플롭에서 콜/레이즈 비율 (블라인드 제외) |
| PFR% | Pre-Flop Raise. 프리플롭 레이즈 비율. 공격적 플레이 지표 |
| AGRFq% | Aggression Frequency. (베팅+레이즈) / (베팅+레이즈+콜+폴드). 포스트플롭 공격성 |
| WTSD% | Went To ShowDown. 쇼다운 진행 비율. 콜링 스테이션 판별 지표 |
| WIN | 누적 수익 (CumWin). 세션 동안의 총 손익 |

**테이블 데이터 (1)**: SEAT 1-10 통계 행 (활성/비활성 구분)

**방송 제어 (11)**:

| 요소 | 기능 설명 | 프로토콜 |
|------|----------|----------|
| LIVE | 방송 라이브 상태 토글. 빨간=라이브, 회색=대기 | -- (로컬 UI) |
| GFX | 방송 GFX 활성/비활성. SendGfxEnable | GFX_ENABLE |
| HAND | 핸드 정보 방송 표시 토글 | GAME_INFO |
| Input | 방송 패널 값 선택. SendPanelValue(value). enum: none/chipcount/vpip/pfr/blinds/agr/wtsd/position/cum_win/payouts 등 | PANEL_VALUE |
| FIELD | 참가자 수 표시. SendFieldVisibility(visible) + SendFieldValue(remain, total) | FIELD_VISIBILITY |
| REMAIN | 잔여 참가자 수 표시. 오버레이에 "XX players remain" 형태 | FIELD_VALUE |
| TOTAL | 전체 참가자 수 표시. REMAIN과 쌍으로 "12/45 players" 형태 | FIELD_VALUE |
| STRIP STACK | 스트립 표시 모드: 칩 스택. SendShowStrip(visible:1) | SHOW_STRIP |
| STRIP WIN | 스트립 표시 모드: 누적 수익. SendCumwinStrip(mode:2) | SHOW_STRIP |
| TICKER | 하단 스크롤 텍스트. SendTicker(ticker) + SendTickerLoop(active) — 반전 전송(!active) | TICKER |
| Arrow (확장) | 방송 제어 패널 확장/축소 토글 | -- (로컬 UI) |

**액션 (2)**:

| 요소 | 기능 설명 |
|------|----------|
| Expand | 통계 테이블 확장 (전체 화면) |
| Close | 통계 화면 닫기, at-02/04 액션 화면으로 복귀 |

### at-06 RFID Registration (786×553)

> <img src="../at-06-rfid-registration.png" alt="AT RFID Registration" style="max-width: 786px;">
>
> *모달 오버레이. "PLACE THIS CARD ON ANY ANTENNA" + A♠ 카드 + CANCEL. **9개 요소.***

| 코드 범위 | 카테고리 | 수량 |
|-----------|---------|:----:|
| COM-TB-01~05 | 타이틀바 | 5 |
| S06-001~004 | 배경, 안내, 카드, CANCEL | 4 |

### at-06 RFID Registration (4개 고유)

| 요소 | 기능 설명 |
|------|----------|
| Black Background | 모달 오버레이 배경. 뒤 화면 조작 차단 |
| Instruction Label | "PLACE THIS CARD ON ANY ANTENNA" — RFID 리더에 카드 배치 지시 메시지 |
| Card Image | 현재 등록 대기 중인 카드 표시 (예: A♠). 52장 순차 등록 중 현재 카드. 등록 완료 시 다음 카드로 자동 전환 |
| CANCEL Button | 덱 등록 취소. SendRegisterDeckCancel(register:false). at-02/04 화면으로 복귀 |

## 2.6 GGP-GFX 보조 스크린샷 (설계 문서 참조용)

설계 문서(`PokerGFX-UI-Design-ActionTracker.md`)에서 사용되는 GGP-GFX Story 스크린샷 7장. 경로: `images/actiontracker/`

Annotation 대상 6장(§2.5)과 **별개** — 이들은 다른 해상도/상태의 보조 참조 자료.

### AT 화면 상태별 (5장)

> <img src="../../../../../images/actiontracker/ggp-gfx-at-initial-setup.png" alt="AT 초기 빈 좌석" style="max-width: 786px;">
>
> *초기 설정. 10인 빈 좌석 + FEATURE 버튼 + TRACK THE ACTION. HOLDEM 게임 타입.*

**at-01 대비 차이점**: GO 버튼 대신 `TRACK THE ACTION` + `RESET HAND` 2버튼 구성. 블라인드/게임 옵션 영역 미표시.

| 영역 | 요소 | 상태/위치 | at-01 대비 |
|------|------|----------|-----------|
| 툴바 좌측 | USB, WiFi, 빈 아이콘 4개 | 상단 좌측 행 | 동일 |
| 툴바 우측 | Camera, Video, GFX(빨간), 카드아이콘, Fullscreen, X | 상단 우측 행 | 동일 |
| 좌측 버튼 | **FEATURE** | 좌측 상단, 흰색 배경 | at-01에 없음 |
| 게임 타입 | **HOLDEM** 배지 | 우측 상단, 골든 배경 | at-01은 하단 배치 |
| 카드 영역 | 10좌석 × 2행 카드 아이콘 | 중앙, 모두 어두운(비활성) | 동일 |
| 좌석 레이블 | SEAT 1~SEAT 10 | 빨간 배경, 기본 번호만 | 동일 |
| 중앙 | 빈 입력 필드 (CCC 위치) | 카드행 아래 | at-01은 블라인드 영역 |
| 우측 | **HIDE GFX** 버튼 | 중앙 우측 | 동일 |
| 하단 좌측 | **RESET HAND** 버튼 | 빨간 배경 | at-01에 없음 (GO 위치) |
| 하단 중앙 | **TRACK THE ACTION** 버튼 | 큰 빨간 배경, 하단 전폭 | at-01은 **GO** 버튼 |

> <img src="../../../../../images/actiontracker/ggp-gfx-at-prestart-players.png" alt="AT Pre-Start 플레이어 설정" style="max-width: 786px;">
>
> *Pre-Start 완료. BLAKE~LEON 8명 등록, DLR/SML/BIG 포지션, 칩 스택 5,000~12,000.*

| 영역 | 요소 | 상태/값 |
|------|------|--------|
| 툴바 | HAND 1, **AUTO** 버튼, **GAME SETTINGS** 버튼 | 상단 행 — at-01에 없는 AUTO/GAME SETTINGS |
| 플레이어명 | BLAKE, GAVIN, ANDY, JONESY, MATT, BRYAN, STEVE, TRAVIS, LEON | 8명 등록 (SEAT 10은 번호만) |
| 포지션 | **DLR** (SEAT 1), **SML** (SEAT 2), **BIG** (SEAT 3) | 노란 배경, 나머지 빈 |
| 칩 스택 | 5000, 8000, 12000, 1000, 7000, 2000, 3000, 10000 | 각 좌석 아래 노란 배경 |
| 블라인드 | MIN CHIP, ANTE, DEALER, SMALL BLIND, BIG BLIND, 3RD BLIND | 하단 블라인드 설정 행 |
| 블라인드 값 | MIN CHIP=25, ANTE=100, SB=800, BB=1600 | 증감 화살표(`<` `>`) 포함 |
| 하단 우측 | **GO** 버튼 | 큰 초록 배경 |

> <img src="../../../../../images/actiontracker/ggp-gfx-at-full-setup.png" alt="AT 전체 설정 뷰 (라벨 포함)" style="max-width: 786px;">
>
> *전체 설정 + 영역 라벨 (Hole Card / Player Name / Position / Chip Stack). GO 버튼.*

4개 행에 대한 **영역 라벨 화살표**가 좌측에 오버레이됨 — 이 이미지만의 고유 주석.

| 행 | 라벨 | 내용 예시 |
|----|------|----------|
| 1행 | **Hole Card** | 카드 아이콘 2장 × 10좌석 |
| 2행 | **Player Name** | name1~name9 + SEAT 10 |
| 3행 | **Position** | DLR, SML, BIG + STRAIGHT × 6 |
| 4행 | **Chip Stack** | 100,000 ~ 30,000 |

| 영역 | 요소 | 비고 |
|------|------|------|
| 툴바 | **CCC** 입력 필드 (빈 상태) | at-01의 빈 필드와 동일 위치 |
| 블라인드 | CAP, ANTE, BTN BLIND, DEALER, SB, BB, 3B | 7개 컨트롤 + 증감 화살표 |
| 블라인드 값 | SB=500, BB=1,000 | at-02(prestart)과 다른 값 |
| 게임 옵션 | MIN CHIP, 7 DEUCE, BOMB POT, # BOARDS, HIT GAME, HOLDEM | 6개 설정 버튼 |
| 하단 | SINGLE BOARD, SETTINGS, GO | 3개 네비게이션 |

### Player Edit Popup (at-01~06에 없는 유일한 팝업)

> <img src="../../../../../images/actiontracker/ggp-gfx-at-player-edit-popup.png" alt="플레이어 상세 편집 팝업" style="max-width: 786px;">
>
> *플레이어 편집 팝업. NAME, LEADERBOARD NAME, COUNTRY, WINNINGS + 사진. DELETE/MOVE SEAT/SIT OUT.*

**6개 주요 화면(at-01~06)에서 발견되지 않는 유일한 모달 팝업.**
좌석 클릭 시 표시되며, 플레이어 상세 정보를 편집한다.

| 영역 | 요소 | 상세 |
|------|------|------|
| 헤더 | **Seat 1** 라벨 | 좌석 번호 표시 |
| 헤더 버튼 | **DELETE** | 흰 배경, 플레이어 삭제 |
| 헤더 버튼 | **MOVE SEAT** | 골든 배경, 좌석 이동 |
| 헤더 버튼 | **SIT OUT** | 골든 배경, 일시 제외 |
| 닫기 | **X** 버튼 | 우측 상단 빨간 배경 |
| 입력 필드 1 | **NAME** 라벨 + 입력란 | 값: "Name 1" |
| 입력 필드 2 | **LEADERBOARD NAME** 라벨 + 입력란 | 값: "Name 1" |
| 입력 필드 3 | **COUNTRY** 라벨 + 드롭다운 | 체크마크(✓) 표시 |
| 입력 필드 4 | **WINNINGS** 라벨 + 입력란 | 빈 상태 |
| 사진 영역 | **No Photo** 텍스트 + 카메라 아이콘 | 우측, 정사각형 영역 |
| 배경 | **Background Image** 라벨 | 팝업 뒤 배경 설정 (별도 기능) |

**프로토콜 매핑**: `PlayerInfoResponse` (조회) / `SendPlayerInfo` (저장). DELETE → `SendRemovePlayer`, MOVE SEAT → `SendMoveSeat`, SIT OUT → `SendSitOut`.

> <img src="../../../../../images/actiontracker/ggp-gfx-at-during-hand.png" alt="AT During Hand" style="max-width: 786px;">
>
> *핸드 진행 중. 10♣ 9♣ 8♣ 커뮤니티 카드, MATT 턴, FOLD/CHECK/BET/ALL IN.*

| 영역 | 요소 | 상태 |
|------|------|------|
| 툴바 | FEATURE, HAND 1 | 좌측 상단, at-01에 없는 FEATURE |
| 게임 타입 | **HOLDEM** 배지 | 우측 상단, 골든 배경 |
| 카드 아이콘 | 10좌석, SEAT 5(MATT) 파란 활성 | 나머지 어두운 |
| 좌석 레이블 | BLAKE, GAVIN, ANDY, JONESY, **MATT**(빨간), BRYAN, STEVE, TRAVIS, LEON | MATT=현재 턴 |
| 좌석 10 | 번호만 (10), 비활성 | 플레이어 미등록 |
| MISS DEAL | 좌측 중앙, 빨간 배경 | 핸드 무효화 버튼 |
| 커뮤니티 카드 | **10♣ 9♣ 8♣** | Flop 3장 표시, 검정 배경 |
| TAG | 별 아이콘 (★) | 골든 배경, 우측 |
| HIDE GFX | 우측 중앙 | 회색 배경 |
| 플레이어 정보 | **(5) MATT - STACK 5,300** | 정보 바, 녹색 |
| 녹음 | 녹음 아이콘 (●) | 정보 바 우측 |
| Undo | ← 화살표 | 하단 좌측 |
| 액션 버튼 | **FOLD / CHECK / BET / ALL IN** | 4버튼, 초록 배경 |

### 방송 오버레이 (2장)

> <img src="../../../../../images/actiontracker/ggp-gfx-broadcast-player-overlay.png" alt="Player Overlay 요소" style="max-width: 786px;">
>
> *방송 Player Element. 카드+이름+액션+Equity(%). UG/+2/D 포지션 배지.*

**GFX 렌더링 출력** — AT에서 입력된 데이터가 방송 화면에 어떻게 표시되는지 보여주는 레퍼런스.

| 요소 | 위치 | 상세 | 프로토콜 |
|------|------|------|----------|
| 홀카드 2장 | 좌측 | 8♣7♣ / 9♠9♥ / A♠K♠ | `SendCards` |
| 플레이어명 | 중앙 | NAME4, NAME6, NAME1 | `PlayerInfoResponse` |
| **Equity %** | 우측 | 14%, 44%, 42% | `SendEquity` |
| 액션 텍스트 | 하단 좌측 | ALL IN 50K / ALL IN 30K / ALL IN 100K | `SendAction` |
| 경고 아이콘 | 하단 중앙 | 삼각형 ⚠ | 위험 표시 |
| **포지션 배지** | 하단 우측 | **UG** / **+2** / **D** | `SendPosition` |
| 점선 주석 | 우측 상단 | "Equity" 라벨 + 빨간 점선 영역 | — |

**Player Element 구조** (각 플레이어 1행):
```
[카드2장] [이름 ──── Equity%]
[액션텍스트  ⚠  포지션]
```

> <img src="../../../../../images/actiontracker/ggp-gfx-broadcast-board-element.png" alt="Board Overlay 요소" style="max-width: 786px;">
>
> *방송 Board Element. POT 13.5K / 블라인드 1K/2K / Vanity Text.*

| 요소 | 위치 | 상세 | 프로토콜 |
|------|------|------|----------|
| **POT** 라벨 | 1행 좌측 | "POT" 텍스트 | `SendPotUpdate` |
| **POT 크기** | 1행 우측 | **13.5K** | `SendPotUpdate` |
| 블라인드 레벨 | 2행 | **1K / 2K** (SB/BB) | `GameInfoResponse` |
| **Vanity Text** | 3행 | **VIDEOPOKERTABLE.NET** | `SendVanityText` |
| "Pot Size" 주석 | 우측 하단 | 화살표로 POT 값 지시 | — |
| "Vanity Text" 주석 | 좌측 하단 | 화살표로 3행 지시 | — |

**Board Element 구조** (방송 화면 상단 고정):
```
[POT ──────── 13.5K]
[    1K / 2K       ]
[VIDEOPOKERTABLE.NET]
```

---

## 3. 색상 상태 체계

### 좌석 레이블 배경색

| 색상 | 의미 | 예시 | PlayerInfoResponse 조건 |
|------|------|------|------------------------|
| 빨간 | 현재 액션 차례 | at-02 SEAT 1, at-04 SEAT 2 | `ActionOn == seat` |
| 흰색 | 등록된 활성 플레이어 | at-02 SEAT 2-3, at-04 SEAT 3 | `!Folded && !SitOut && !AllIn` |
| 회색 | 폴드 또는 액션 완료 | at-04 SEAT 1 | `Folded == true` |
| 어두운 | 빈 좌석 (비활성) | at-02/04 SEAT 4-10 | 플레이어 없음 |
| TBD | AllIn 상태 | (AT 좌석 색상 미확인 — wireframe에 allin CSS 미정의. 방송 GFX는 "강렬한 색상 변경" 기획서 line 694) | `AllIn == true` |
| 반투명 | SitOut 상태 | (반투명 처리 — GGP-GFX 기획서 line 564 "Sitting Out 시 반투명 처리") | `SitOut == true` |

### 카드 아이콘 배경색

| 색상 | 의미 |
|------|------|
| 노란 | 홀카드 입력됨 |
| 어두운 | 카드 미입력 |
| 회색 | 폴드/비활성 |

### 기타 색상

| 색상 | 의미 | 적용 |
|------|------|------|
| 골든 (#B8860B) | 활성 강조 | at-05 GFX 버튼, STACK 헤더 |
| 진한 초록 | 액션 버튼 | FOLD, CALL, CHECK, BET, RAISE-TO, ALL IN |
| 골든 브라운 (#8B6914) | Spade/Club suit | at-03 카드 그리드 |
| 빨간 (#8B0000) | Heart/Diamond suit | at-03 카드 그리드 |

## 4. at-02 / at-04 Diff 분석

7개 변경 요소 (`changed_element_ids: [11, 21, 22, 33, 34, 39, 40]`):

| id | 요소 | at-02 (Pre-Flop) | at-04 (Post-Flop) | 변경 유형 |
|:--:|------|-----------------|-------------------|----------|
| 11 | SEAT 1 카드 아이콘 | 노란 배경 (카드 입력됨) | 어두운 회색 (폴드/완료) | 색상 |
| 21 | SEAT 1 레이블 | 빨간 배경 (현재 턴) | 회색 배경 (비활성) | 색상 |
| 22 | SEAT 2 레이블 | 흰 배경 (활성) | 빨간 배경 (현재 턴) | 색상 |
| 33 | 커뮤니티 카드 | 빈 검정 영역 | 7H 6S 4H Flop 3장 | 콘텐츠 |
| 34 | 플레이어 정보 | (1) SEAT 1 / 1,000,000 | (2) SEAT 2 / 995,000 | 콘텐츠 |
| 39 | 액션 버튼 2 | CALL (SendAction call) | CHECK (SendAction check) | 텍스트+프로토콜 |
| 40 | 액션 버튼 3 | RAISE-TO (SendAction raise) | BET (SendAction bet) | 텍스트+프로토콜 |

## 5. Annotation 전략

### 접근 방식
- 순수 HTML+CSS 레이아웃 재설계 (Quasar 미사용)
- Playwright 캡처 -> PNG 생성
- 스크린샷 오버레이 방식 폐기 (좌표 부정확)

### 배지 규칙
- 공통 요소: 파란 원형 배지
- 고유 요소: 빨간 원형 배지
- Diff 요소 (at-04): 주황 원형 배지 + 점선 보더

### HTML 파일 계획

| 화면 | 파일명 | 요소 수 | 우선순위 | 비고 |
|------|--------|:-------:|:-------:|------|
| at-01 | at-01-setup-annotated.html | 83 | P1 | 가장 복잡, 블라인드 영역 밀도 높음 |
| at-02 | at-02-action-annotated.html | 41 | P1 | 핵심 액션 화면 |
| at-03 | at-03-card-selector-annotated.html | 8 | P3 | 단순 그리드 |
| at-04 | at-02 통합 | 7 (diff) | P2 | at-02 HTML 재사용 |
| at-05 | at-05-statistics-annotated.html | 22 | P2 | 테이블+사이드 패널 |
| at-06 | at-06-rfid-annotated.html | 9 | P3 | 모달 오버레이 |

### at-02/at-04 통합 전략

at-04는 at-02와 7개 요소만 차이. 단일 HTML로 통합하되 diff 영역 표시:
- 상단에 `[Pre-Flop] / [Post-Flop]` 탭 스위치 배치
- diff 영역(id 11, 21, 22, 33, 34, 39, 40)에 주황 배지 + 점선 보더
- 탭 전환 시 해당 요소만 콘텐츠/색상 변경

## 6. 번호 체계

| 범위 | 접두사 | 용도 | 수량 |
|------|--------|------|:----:|
| 1~5 | COM-TB | 공통 타이틀바 (Icon, Title, Min, Max, Close) | 5 |
| 10~17 | COM-TL | 공통 툴바 (USB, WiFi, HAND, Camera, GFX, Fullscreen, Close, Register) | 8 |
| 20~29 | COM-CD | 공통 카드 아이콘 (SEAT 1~10) | 10 |
| 30~39 | COM-ST | 공통 좌석 레이블 (SEAT 1~10) | 10 |
| 40~46 | COM-AP | 공통 액션 패널 (MISS DEAL, TAG, Community, Info, Rec, HIDE GFX, Undo) | 7 |
| 100~152 | S01-xxx | at-01 고유 (hand_control, option, position, blind, game_settings, navigation) | 52 |
| 200~204 | S02-xxx | at-02 고유 (입력 필드, FOLD, CALL, RAISE-TO, ALL IN) | 5 |
| 300~306 | S03-xxx | at-03 고유 (Back, Display, OK, Spade/Heart/Diamond/Club Row) | 7 |
| 400~404 | S04-xxx | at-04 고유 (입력 필드, CHECK, BET, FOLD, ALL IN) | 5 |
| 500~521 | S05-xxx | at-05 고유 (headers, data, broadcast controls) | 21 |
| 600~603 | S06-xxx | at-06 고유 (background, instruction, card, cancel) | 4 |

**총 annotation 배지**: 공통 40 + 고유 94 = **134개**

## 7. 프로토콜-UI 매핑

역설계 문서 §8.5 기준. AT가 Server와 교환하는 프로토콜 명령과 UI 요소의 매핑.

### 방향 정의

- **Req** (Request): AT → Server. 사용자가 UI 요소를 조작하면 AT가 Server로 송신.
- **Resp** (Response): Server → AT. Server가 상태 변경을 AT에 통지.
- **콜백**: 네트워크/시스템 이벤트로 자동 발생.

### 프로토콜 매핑 테이블

| UI 요소 | C# 래퍼명 | 프로토콜 ID | 방향 | 화면 |
|---------|----------|------------|:----:|------|
| USB Connection | ConnectToServer | `CONNECT` | Req | 공통 툴바 |
| GFX 버튼 | SendGfxEnable | `GFX_ENABLE` | Req | 공통 툴바 |
| HIDE GFX | SendGfxEnable(!enable) | `GFX_ENABLE` | Req | at-02/04 |
| REGISTER | RegisterDeck | `CARD_VERIFY` / `FORCE_CARD_SCAN` | Req | at-02/04 툴바 |
| MISS DEAL | SendMissDeal | `MISS_DEAL` | Req | at-02/04 |
| TAG | SendTag / SendClearTag | `TAG` (TagRequest) | Req | at-02/04 |
| Undo | SendGameSaveBack | `GAME_SAVE_BACK` (GameSaveBackRequest) | Req | at-02/04 |
| FOLD/CALL/RAISE-TO/ALL IN | SendAction | `PLAYER_ACTION` | Req | at-02/04 |
| CHECK/BET | SendAction | `PLAYER_ACTION` | Req | at-04 |
| GO 버튼 | SendStartHand | `START_HAND` | Req | at-01 |
| Camera/Video | SendVideoSources | `VIDEO_SOURCES` | Req | 공통 툴바 |
| DELETE (Player Edit) | SendRemovePlayer | `REMOVE_PLAYER` | Req | Player Edit Popup |
| MOVE SEAT (Player Edit) | SendMoveSeat | `MOVE_SEAT` | Req | Player Edit Popup |
| SIT OUT (Player Edit) | SendSitOut | `SIT_OUT` | Req | Player Edit Popup |
| WiFi Signal | NetworkQualityChanged | `IClientNetworkListener` 콜백 | Resp | 공통 툴바 |
| HAND 번호 | GameInfoResponse.HandNumber | `GAME_INFO` | Resp | 공통 툴바 |
| 좌석 레이블/상태 | PlayerInfoResponse | `PLAYER_INFO` | Resp | at-01/02/04 |
| 블라인드 값 | GameInfoResponse.Ante/Small/Big | `GAME_INFO` | Resp | at-01 |

### 교차 검증 노트

TAG(§6.9-6.10)와 Undo(§5.6)는 Protocol Spec에 표준 정의 확인됨. 초기 "AT 커스텀" 분류는 오류.

| 항목 | 프로토콜 명세 | 상세 |
|------|-------------|------|
| TAG | `SendTag` → `TagRequest` (tag: string, 콤마→틸드 치환) | 방송 핸드 라벨. `SendClearTag`로 해제 |
| Undo | `SendGameSaveBack` → `GameSaveBackRequest` (파라미터 없음) | History Stack Pop → GameState 복원 → 브로드캐스트. 키보드 `U` (AT-014). Undo 중 [Hide GFX]로 방송 임시 숨김 (기획서 line 657) |
| SitOut 반전 | `SendPlayerSitOut` → 와이어 `!sitOut` 반전 전송 | GfxEnable, TickerLoop도 동일 반전 패턴 |
| SitOut 시각화 | **반투명 처리** (GGP-GFX 기획서 line 564) | TBD 해소. `PlayerStatus.SITTING_OUT` (기획서 line 217) |
| AllIn AT 좌석 | core.cs 난독화 — AT 좌석 RGB 추출 불가 | wireframe에 4상태만 정의. 방송 GFX는 "강렬한 색상 변경" (기획서 line 694) |

출처: `04_Protocol_Spec/actiontracker-messages.md`, `PokerGFX-Feature-Checklist.md` AT-014, `GGP-GFX 개발 기획서.md` line 217/564/651-657/694

## 8. GameInfoResponse / PlayerInfoResponse 필드-UI 매핑

역설계 문서 §8.6의 75+ 필드 중 AT UI에 표시되는 필드만 매핑.

### GameInfoResponse 필드

| 필드 | AT UI 요소 | 화면 | 비고 |
|------|-----------|------|------|
| Ante | ANTE 컨트롤 (증감 화살표) | at-01 | blind 영역 |
| Small | SB 컨트롤 (증감 화살표) | at-01 | blind 영역 |
| Big | BB 컨트롤 (증감 화살표) | at-01 | blind 영역 |
| Third | 3B 컨트롤 (증감 화살표) | at-01 | blind 영역 |
| ButtonBlind | BTN BLIND 컨트롤 | at-01 | blind 영역 |
| BlindLevel | Blind Level 표시 (SB/BB 점선 영역) | at-01 | §2.6 blind-level-annotated 참조 |
| Cap | CAP 컨트롤 | at-01 | blind 영역 |
| PlDealer | DLR 포지션 (노란 배경) | at-01 | position 행 |
| PlSmall | SML 포지션 (노란 배경) | at-01 | position 행 |
| PlBig | BIG 포지션 (노란 배경) | at-01 | position 행 |
| ActionOn | 빨간 좌석 하이라이트 | at-02/04 | §3 색상 체계 참조 |
| GameType | HOLDEM 배지 (골든 배경) | at-01 | game_settings |
| GameVariant | 게임 변형 표시 | at-01 | game_settings |
| HandInProgress | GO ↔ TRACK THE ACTION 전환 | at-01 | false=GO, true=TRACK THE ACTION |
| HandNumber | HAND 번호 (툴바) | 공통 | 공통 툴바 |
| GfxEnabled | GFX 버튼 색상 (빨간=활성) | 공통 | 공통 툴바 |
| BombPot | BOMB POT 버튼 상태 | at-01 | game_settings |
| SevenDeuce | 7 DEUCE 버튼 상태 | at-01 | game_settings |
| NumBoards | # BOARDS 값 | at-01 | game_settings |
| SmallestChip | MIN CHIP 값 | at-01 | game_settings |
| ShowPanel | 방송 패널 표시 여부 | at-05 | broadcast_control |
| StripDisplay | STRIP STACK / STRIP WIN 전환 | at-05 | broadcast_control |
| TickerVisible | TICKER 표시 여부 | at-05 | broadcast_control |
| FieldVisible | FIELD 표시 여부 | at-05 | broadcast_control |

### PlayerInfoResponse 필드

| 필드 | AT UI 요소 | 화면 | 비고 |
|------|-----------|------|------|
| Name | 좌석 레이블 텍스트 | at-01/02/04 | 이름 또는 "SEAT N" |
| Stack | 칩 스택 값 (노란 배경) | at-01 | 좌석 아래 표시 |
| Stack | 플레이어 정보 바 스택 값 | at-02/04 | "(N) NAME - STACK X" |
| Folded | 회색 좌석 레이블 | at-02/04 | §3 색상 체계 참조 |
| AllIn | AllIn 상태 표시 | at-02/04 | 색상 TBD |
| SitOut | SitOut 상태 표시 | at-02/04 | 색상 TBD |
| HasCards | 노란 카드 아이콘 | at-02/04 | 카드 입력됨 표시 |
| Vpip | VPIP% 컬럼 | at-05 | 통계 테이블 |
| Pfr | PFR% 컬럼 | at-05 | 통계 테이블 |
| Agr | AGRFq% 컬럼 | at-05 | 통계 테이블 |
| Wtsd | WTSD% 컬럼 | at-05 | 통계 테이블 |
| CumWin | WIN 컬럼 | at-05 | 통계 테이블 |
| Country | COUNTRY 드롭다운 | Player Edit Popup | 국가 선택 |
| HasPic | No Photo / 사진 영역 | Player Edit Popup | 카메라 아이콘 |
| LeaderboardName | LEADERBOARD NAME 입력란 | Player Edit Popup | 별도 표시명 |
| Winnings | WINNINGS 입력란 | Player Edit Popup | 누적 상금 |
| LongName | (=LeaderboardName 동일 필드 가능성) | Player Edit Popup | 풀 네임 |
| Bet | (AT UI 미표시 — 서버 상태 전용) | -- | 현재 베팅액 |
| DeadBet | (AT UI 미표시 — 서버 상태 전용) | -- | 블라인드 미스 후 포스트 금액 |
| NitGame | (AT UI 미표시 — 서버 상태 전용) | -- | nit_game_enum 상태 |

## 9. AT 범위 한정 선언

### 포함 범위

- **6개 주요 화면**: at-01 Setup Mode, at-02 Pre-Flop Action, at-03 Card Selector, at-04 Post-Flop Action, at-05 Statistics, at-06 RFID Registration
- **1개 팝업**: Player Edit Popup (좌석 클릭 시 표시)
- **2개 방송 오버레이**: Player Element, Board Element
- **게임 타입**: Holdem 기준 (Texas Hold'em No Limit)

### 제외 범위

| 제외 항목 | 이유 |
|----------|------|
| Draw/Stud 계열 22개 게임 변형의 UI 차이 | Phase 2 이후. Holdem 복제 우선 |
| SETTINGS 팝업 내부 | 설정 화면 상세 분석 미완료 |
| RFID reader_config / reader_select 화면 | 하드웨어 종속 설정. EBS 자체 구현 시 재설계 |
| GAME SETTINGS 팝업 (at-01 SETTINGS 버튼) | 내부 구조 미분석 |
| AUTO 모드 동작 상세 | 동작 로직은 프로토콜 스펙에서 별도 다룸 |

### 근거

Phase 1 목표는 **Holdem 기준 PokerGFX 동일 복제**. 다른 게임 변형(PLO, Short Deck, Draw 등)은 핵심 구조가 동일하고 필드 표시 차이만 존재하므로, Holdem 복제 완료 후 GameVariant 분기로 확장한다.


## 10. 스크린샷-JSON 교차 검증 결과

### 10.1 프로토콜명 보정 이력

텍스트 교차 검증을 통해 JSON과 annotation-plan §7 프로토콜명의 불일치를 발견하고 보정함.

| 파일 | 요소 id | 보정 전 | 보정 후 | 근거 |
|------|:-------:|---------|---------|------|
| at-02 | 37 (← 뒤로가기) | `UndoLastAction` | `SendGameSaveBack` | §7 Undo 매핑: `SendGameSaveBack → GAME_SAVE_BACK` |
| at-02 | 32 (TAG) | `SendTagHand` | `SendTag` | §7 TAG 매핑: `SendTag → TagRequest` |
| at-04 | 37 (← 뒤로가기) | `UndoLastAction` | `SendGameSaveBack` | at-02와 동일 |
| at-04 | 32 (TAG) | `SendTagHand` | `SendTag` | at-02와 동일 |
| at-05 | 16 (FIELD) | `SendFieldGraphic` | `SendFieldVisibility` | §7: `SendFieldVisibility(visible)` |
| at-05 | 17 (REMAIN) | `SendRemainGraphic` | `SendFieldValue` | §7: `SendFieldValue(remain, total)` |
| at-05 | 18 (TOTAL) | `SendTotalGraphic` | `SendFieldValue` | §7: REMAIN과 동일 프로토콜, 파라미터 차이 |
| at-06 | 9 (CANCEL) | `RegisterDeck` | `SendRegisterDeckCancel` | at-06 고유: `SendRegisterDeckCancel(register:false)` |

### 10.2 at-01 구조 보정

| 원본 id | 원본 name | 보정 내용 |
|:-------:|-----------|----------|
| 28 | Seat Labels Row | 10개 개별 요소로 분리 (COM-ST-01 ~ COM-ST-10) |
| 29 | Straddle Buttons Row | 10개 개별 요소로 분리 (S01-007 ~ S01-016) |
| 30 | Position Buttons Row | 10개 개별 요소로 분리 (S01-017 ~ S01-026) |

분리 근거: 각 좌석별로 독립적인 클릭 대상이며, annotation 배지를 개별 배치해야 함.

GO 버튼: 현재 스크린샷(Setup Mode 초기 상태)에는 미표시. 플레이어 등록 후 하단에 표시됨.

### 10.3 화면별 이슈 요약

| 심각도 | 수량 | 대표 사례 |
|:------:|:----:|----------|
| HIGH | 3 | 프로토콜명 불일치 (UndoLastAction, SendTagHand, SendFieldGraphic) |
| MEDIUM | 7 | at-01 행 요소 미분리, at-05 프로토콜 3건, at-06 CANCEL 프로토콜 |
| LOW | 5 | at-05 타이틀바 버전 차이, 카테고리명 불일치 (chrome vs titlebar) |

### 10.4 at-05 타이틀바 버전 차이

at-05의 타이틀바에 표시된 copyright:
- at-01/02/03/04/06: `PokerGFX Action Tracker © 2026`
- at-05: `PokerGFX Action Tracker © 2011-24 videopokertable.net`

이는 at-05 스크린샷이 구버전 빌드에서 캡처된 것으로 추정. 기능 분석에는 영향 없으나 버전 차이로 기록.

### 10.5 annotation_text 필드 추가

모든 6개 JSON 파일의 전체 요소에 `annotation_text` 필드 추가 완료.
번호 체계: §6 기준 (COM-TB, COM-TL, COM-CD, COM-ST, COM-AP, S01~S06).
형식: `[CODE] 한줄 설명`

## 11. UI 레이아웃 추출 완전성 검증

PokerGFX의 모든 UI 레이아웃이 추출/분석되었는지 정량 평가.

### 11.1 ActionTracker (7개 화면)

| 화면 | 요소 수 | 요소 JSON | annotation_text | 스크린샷 | 상태 |
|------|:-------:|:---------:|:---------------:|:--------:|:----:|
| at-01 Setup Mode | 83 | OK | OK | OK | **완료** |
| at-02 Pre-Flop Action | 41 | OK | OK | OK | **완료** |
| at-03 Card Selector | 8 | OK | OK | OK | **완료** |
| at-04 Post-Flop Action | 41 | OK | OK | OK | **완료** |
| at-05 Statistics/Broadcast | 22 | OK | OK | OK | **완료** |
| at-06 RFID Registration | 9 | OK | OK | OK | **완료** |
| Player Edit Popup | ~10 | 없음 | 없음 | OK | **부분** |

JSON 파일 위치: `03_Reference_ngd/action_tracker/analysis/at-*.json` (6개)

### 11.2 Server (11개 화면)

| 화면 | Annotated PNG | OCR JSON | 요소 JSON | 상태 |
|------|:------------:|:--------:|:---------:|:----:|
| 01 Main Window | OK | OK | 없음 | **부분** |
| 02 Sources Tab | OK | OK | 없음 | **부분** |
| 03 Outputs Tab | OK | OK | 없음 | **부분** |
| 04 GFX 1 Tab | OK | OK | 없음 | **부분** |
| 05 GFX 2 Tab | OK | OK | 없음 | **부분** |
| 06 GFX 3 Tab | OK | OK | 없음 | **부분** |
| 07 Commentary Tab | OK | OK | 없음 | **DROP** |
| 08 System Tab | OK | OK | 없음 | **부분** |
| 09 Skin Editor | OK | OK | 없음 | **부분** |
| 10 Graphic Editor (Board) | OK | OK | 없음 | **부분** |
| 11 Graphic Editor (Player) | OK | OK | 없음 | **부분** |

OCR JSON 위치: `02_Annotated_ngd/*-ocr.json` (11개)
일부 화면은 calibrated JSON도 존재 (sources, outputs, gfx, system)

**Commentary Tab DROP 사유**: EBS에서 사용하지 않는 기능 (SV-021, SV-022 배제 확정)

### 11.3 방송 오버레이 (5개)

| 오버레이 | PokerGFX 스크린샷 | 분석 | EBS 설계 mockup | 상태 |
|---------|:-----------------:|:----:|:---------------:|:----:|
| Player Element | OK (§2.6) | OK | OK (`ebs-player-graphic`) | **완료** |
| Board Element | OK (§2.6) | OK | OK (`ebs-board-graphic`) | **완료** |
| Leaderboard | 없음 | 없음 | OK (`ebs-leaderboard`) | **미추출** |
| Stats Panel / Strip | 없음 | 없음 | OK (`ebs-strip`) | **미추출** |
| Ticker | 없음 | 없음 | OK (`ebs-ticker`) | **미추출** |

Leaderboard/Strip/Ticker는 EBS 설계 mockup(`docs/02-design/mockups/v3/`)은 있으나 PokerGFX 원본 스크린샷/분석이 부재.

### 11.4 Gap 요약

| 영역 | 총 화면 | 완료 | 부분 | 미추출 | Drop |
|------|:------:|:----:|:----:|:-----:|:----:|
| ActionTracker | 7 | 6 | 1 | 0 | 0 |
| Server | 11 | 0 | 10 | 0 | 1 |
| 방송 오버레이 | 5 | 2 | 0 | 3 | 0 |
| **합계** | **23** | **8** | **11** | **3** | **1** |

**완료율**: 8/22 (Drop 제외) = **36%**

### 11.5 Gap 상세

| # | Gap | 설명 | 영향 |
|:-:|-----|------|------|
| G1 | Server 10개 화면 요소 JSON 부재 | PNG+OCR은 있으나 AT처럼 요소별 JSON(bbox, protocol, annotation_text)이 없음 | Phase 1 복제 시 UI 요소 1:1 대응 불가 |
| G2 | Player Edit Popup JSON 부재 | §2.6에 테이블 기술만 존재, 별도 JSON 미생성 | 요소 수 ~10개로 소규모 |
| G3 | Leaderboard 오버레이 미추출 | 기능 체크리스트에 언급되나 PokerGFX 원본 미확보 | EBS 설계 mockup으로 대체 가능 |
| G4 | Stats Panel / Strip 오버레이 미추출 | at-05 방송 제어에서 STRIP STACK/WIN 전송하는 대상 | EBS 설계 mockup으로 대체 가능 |
| G5 | Ticker 오버레이 미추출 | at-05 TICKER 컨트롤의 방송 출력 대상 | EBS 설계 mockup으로 대체 가능 |

### 11.6 Server 화면 분석 우선순위 (제안)

Phase 1 복제 대상 기준:

| 우선순위 | 화면 | 근거 |
|:--------:|------|------|
| **P1** | Sources Tab, Outputs Tab, System Tab | 핵심 인프라 — 입출력 설정 + 시스템 관리 |
| **P2** | GFX 1 Tab, GFX 3 Tab | 방송 제어 — 그래픽 렌더링 설정 |
| **P3** | Main Window, GFX 2 Tab | 메인 윈도우 + 추가 GFX 설정 |
| **P4** | Skin Editor, Graphic Editor (Board/Player) | 고급 설정 — Phase 1 후순위 |

---
**Version**: 1.10.0 | **Updated**: 2026-03-16
