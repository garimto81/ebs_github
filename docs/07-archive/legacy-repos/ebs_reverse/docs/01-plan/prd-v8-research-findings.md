# PRD v8.0 리서치 결과

> **Date**: 2026-02-17
> **Source**: `docs/02-design/pokergfx-reverse-engineering-complete.md` (역공학 분석 통합 문서)
> **Purpose**: PRD v7.0.0의 팩트 검증 및 v8.0 수정 근거

---

## E-1. 22개 게임 수량 정확 검증

### game enum (Section 5.1, line 797~825)

.NET Reflection으로 추출된 정확한 22개 값:

| enum | 게임명 | 계열 |
|:----:|--------|:----:|
| 0 | Texas Hold'em | CC |
| 1 | 6+ Hold'em (Straight > Trips) | CC |
| 2 | 6+ Hold'em (Trips > Straight) | CC |
| 3 | Pineapple | CC |
| 4 | Omaha | CC |
| 5 | Omaha Hi-Lo | CC |
| 6 | Five Card Omaha | CC |
| 7 | Five Card Omaha Hi-Lo | CC |
| 8 | Six Card Omaha | CC |
| 9 | Six Card Omaha Hi-Lo | CC |
| 10 | Courchevel | CC |
| 11 | Courchevel Hi-Lo | CC |
| 12 | Five Card Draw | Draw |
| 13 | 2-7 Single Draw | Draw |
| 14 | 2-7 Triple Draw | Draw |
| 15 | A-5 Triple Draw | Draw |
| 16 | Badugi | Draw |
| 17 | Badeucy | Draw |
| 18 | Badacey | Draw |
| 19 | 7-Card Stud | Stud |
| 20 | 7-Card Stud Hi-Lo | Stud |
| 21 | Razz | Stud |

### 정확한 계열별 분류

| 계열 | enum 범위 | 실제 수 |
|------|----------|:-------:|
| Community Card (game_class=flop) | 0~11 | **12** |
| Draw (game_class=draw) | 12~18 | **7** |
| Stud (game_class=stud) | 19~21 | **3** |
| **합계** | 0~21 | **22** |

### 불일치 발견

| 위치 | Community Card | Draw | Stud | 합계 |
|------|:-:|:-:|:-:|:-:|
| 역공학 Section 1.5 (line 87) | 13 | **6** | 3 | 22 |
| 역공학 Section 5.3 헤딩 (line 840) | **13** | **6** | 3 | 22 |
| 역공학 Section 5.3 테이블 엔트리 | **12** | **7** | 3 | 22 |
| PRD v7 부록 A 헤딩 | **13** | 7 | 3 | 23(!) |
| PRD v7 부록 A 테이블 엔트리 | **12** | 7 | 3 | 22 |
| PRD v7 본문 (line 437~439) | **13** | **7** | 3 | 23(!) |

**결론**: enum 기준 정확한 분류는 **12-7-3 = 22**.

- 역공학 문서 Section 1.5와 5.3 헤딩은 "13-6-3"으로 잘못 기술 (합은 22로 맞지만 내부 분배 오류)
- PRD v7 본문과 부록 헤딩은 "13-7-3"으로 기술하여 합이 23이 되는 산술 오류
- PRD v7 부록 테이블은 12-7-3으로 정확하지만 헤딩과 불일치
- **수정 필요**: 모든 곳에서 "12-7-3"으로 통일

---

## E-2. Stud 7th Street 종료 조건

### 상태 머신 (Section 5.4, line 879~924)

```
[Stud 계열] ---> THIRD_STREET -> FOURTH -> FIFTH -> SIXTH -> SEVENTH -> SHOWDOWN
```

- 7th Street가 최종 베팅 라운드. 이후 바로 SHOWDOWN.
- 추가 라운드 없음.
- Section 5.3 테이블에서 Stud 3개 모두 "라운드 수: 5" (3rd, 4th, 5th, 6th, 7th).
- `pl_stud_first_to_act` 필드가 각 스트릿의 첫 액션 플레이어를 결정.

**결론**: PRD와 일치. 수정 불필요.

---

## E-3. Live Ante 개념 정의

### AnteType enum (Section 5.6, line 938~952)

```csharp
enum AnteType {
    std_ante = 0,        // 표준 앤티 - 모든 플레이어가 동일 금액 납부
    button_ante = 1,     // 버튼 앤티 - 딜러(버튼)만 납부
    bb_ante = 2,         // 빅블라인드 앤티 - BB 위치 플레이어가 납부
    bb_ante_bb1st = 3,   // BB 앤티 (BB 먼저) - BB가 앤티를 먼저 수납
    live_ante = 4,       // 라이브 앤티 - 팟에 라이브로 참여
    tb_ante = 5,         // Third Blind 앤티 - 서드 블라인드 위치 납부
    tb_ante_tb1st = 6    // TB 앤티 (TB 먼저) - TB가 앤티를 먼저 수납
}
```

### Live Ante의 의미

| 속성 | Standard Ante (std_ante=0) | Live Ante (live_ante=4) |
|------|---------------------------|------------------------|
| 성격 | Dead Money | Live Money |
| 프리플롭 베팅 포함 | 아니오 | 예 |
| BB 옵션 | 앤티와 별개로 BB만 체크 가능 | 앤티 금액이 베팅으로 카운트 |
| 레이즈 미발생 시 | BB가 추가 베팅 없이 진행 | 앤티 = 자신의 베팅이므로 추가 베팅 불필요 |
| 주 사용처 | 캐시 게임 | 토너먼트 후반부 |

- `GameTypeData._ante_type`에 저장, `TagsService.set__ante_type()`으로 설정
- `FlopDrawBlinds` 구조에서 `AnteType` 필드로 현재 핸드의 앤티 규칙 저장
- `net_conn` 프로토콜의 `GAME_INFO` 명령으로 ActionTracker에 전달

---

## B-4. Pipcap 개념 정의

### 역공학 근거

| 위치 | 내부 키 | 설명 |
|------|---------|------|
| Section 3.6 (line 461) | `pgfx_pipcap` | "원격 서버 PIP 캡처" |
| Section 13.5 (line 2655) | `pgfx_pipcap` | "다른 VPT 인스턴스 PIP 캡처" |
| 통신 | net_conn TCP | 원격 GfxServer에 TCP로 연결 |

### PIP(Picture-in-Picture) 시스템

Section 7.7 (line 1409~1411): `pip_element`는 카메라 입력을 그래픽 캔버스의 임의 위치에 배치.

```
pip_element 구성:
- src_rect: 소스 영역
- dst_rect: 대상 영역 (캔버스 위 위치/크기)
- opacity: 투명도
- z_pos: Z-order
- dev_index: 캡처 디바이스 인덱스
```

### Pipcap의 정체

**Pipcap = 다른 PokerGFX(VPT) 서버 인스턴스의 출력을 캡처하여 현재 서버의 PIP로 삽입하는 클라이언트 애플리케이션**

용도: 멀티테이블 환경에서 한 테이블의 방송 화면을 다른 테이블 방송에 PIP 창으로 삽입.
예: WSOP 메인 이벤트 결승에서 다른 테이블 상황을 작은 화면으로 동시 표시.

---

## B-7. 카메라 전환 방식

### 확인된 3가지 카메라 전환 메커니즘

#### 1. 외부 하드웨어: ATEM Switcher (Section 12.1, line 2357~2389)

- Blackmagic ATEM SDK COM Interop (`Interop.BMDSwitcherAPI.dll`, 92KB)
- `atem` 클래스: `_cameraList: List<camera>`, `_inputMonitors: List<InputMonitor>`
- 6개 상태: NotInstalled(0), Disconnected(1), Connected(2), Paused(3), Reconnect(4), Terminate(5)
- 3개 이벤트: State(0), NameChange(1), InputChange(2)
- Master-Slave 전파: `slave._masterExtSwitcherAddress`

#### 2. 내부 소프트웨어 카메라 전환: 프로토콜 명령 (Section 8.5, line 1627~1629)

| 명령 | 기능 |
|------|------|
| `CAM` | 카메라 전환 |
| `PIP` | PIP 설정 |
| `SOURCE_MODE` | 소스 모드 변경 |
| `GET_VIDEO_SOURCES` / `VIDEO_SOURCES` | 비디오 소스 조회/응답 |
| `CAP` | 화면 캡처 |

#### 3. 자동 카메라 전환: AutoCamera (Section 4.7, line 783)

- LogTopic `AutoCamera`: "자동 카메라 전환, 순환, 보드 팔로우"
- ATEM 입력 전환과 연동: "보드 카드 공개, 플레이어 액션 등에 따라 카메라가 자동 전환"

**결론**: ATEM 없이도 소프트웨어 전환 가능. ATEM이 있으면 하드웨어 스위칭과 소프트웨어가 연동. `tab_sources` (Section 4.1, line 521)에서 카메라/비디오 소스 관리.

---

## G-4. 113+ 명령어 상세 카운트

### 역공학 문서 명시적 목록 (Section 8.5, line 1574~1645)

#### 연결 관리 (7개)

| # | 명령 | 방향 | 주요 필드 |
|:-:|------|------|----------|
| 1 | CONNECT | Req/Resp | License(ulong) |
| 2 | DISCONNECT | Req/Resp | - |
| 3 | AUTH | Req/Resp | Password, Version |
| 4 | KEEPALIVE | Req | - |
| 5 | IDTX | Req/Resp | IdTx(string) |
| 6 | HEARTBEAT | Req/Resp | - |
| 7 | IDUP | Resp | - |

#### 게임 상태 (9개)

| # | 명령 | 방향 | 주요 필드 |
|:-:|------|------|----------|
| 1 | GAME_STATE | Resp | GameType, InitialSync |
| 2 | GAME_INFO | Req/Resp | 75+ 필드 |
| 3 | GAME_TYPE | Req | GameType |
| 4 | GAME_VARIANT | Req | Variant |
| 5 | GAME_VARIANT_LIST | Req/Resp | - |
| 6 | GAME_CLEAR | Req | - |
| 7 | GAME_TITLE | Req | Title |
| 8 | GAME_SAVE_BACK | Req | - |
| 9 | NIT_GAME | Req | Amount |

#### 플레이어 관리 (10개)

| # | 명령 | 방향 | 주요 필드 |
|:-:|------|------|----------|
| 1 | PLAYER_INFO | Req/Resp | Player, Name, Stack, Stats (20 필드) |
| 2 | PLAYER_CARDS | Req/Resp | Player, Cards(string) |
| 3 | PLAYER_BET | Req/Resp | Player, Amount |
| 4 | PLAYER_BLIND | Req | Player, Amount |
| 5 | PLAYER_ADD | Req | Seat, Name |
| 6 | PLAYER_DELETE | Req | Seat |
| 7 | PLAYER_COUNTRY | Req | Player, Country |
| 8 | PLAYER_DEAD_BET | Req | Player, Amount |
| 9 | PLAYER_PICTURE | Resp | Player, Picture |
| 10 | DELAYED_PLAYER_INFO | Req/Resp | - |

#### 카드/보드 (5개)

BOARD_CARD, CARD_VERIFY, FORCE_CARD_SCAN, DRAW_DONE, EDIT_BOARD

#### 디스플레이/UI (11개)

FIELD_VISIBILITY, FIELD_VAL, GFX_ENABLE, ENH_MODE, SHOW_PANEL, STRIP_DISPLAY, BOARD_LOGO, PANEL_LOGO, ACTION_CLOCK, DELAYED_FIELD_VISIBILITY, DELAYED_GAME_INFO

#### 미디어/카메라 (9개)

MEDIA_LIST, MEDIA_PLAY, MEDIA_LOOP, CAM, PIP, CAP, GET_VIDEO_SOURCES, VIDEO_SOURCES, SOURCE_MODE

#### 베팅/재무 (5개)

PAYOUT, MISS_DEAL, CHOP, FORCE_HEADS_UP, FORCE_HEADS_UP_DELAYED

#### 데이터 전송 (4개)

SKIN_CHUNK, COMM_DL, AT_DL, VTO

#### 기록/로그 (4개)

HAND_HISTORY, HAND_LOG, GAME_LOG, COUNTRY_LIST

#### RFID (1개)

READER_STATUS

### 카운트 비교

| 카테고리 | 역공학 명시 | PRD v7 수 | 차이 원인 |
|---------|:---------:|:---------:|----------|
| 연결 관리 | 7 | 9 | PRD가 GAME_STATE, GAME_VARIANT_LIST, COUNTRY_LIST를 여기 포함 |
| 게임 상태 | 9 | 10 | PRD가 NEW_HAND, END_HAND 추가, GAME_STATE를 Connection으로 이동 |
| 플레이어 관리 | 10 | 21 | PRD가 PLAYER_STATUS, ACTION, STACK, POSITION, STATS + 6개 추가 |
| 카드/보드 | 5 | 6 | PRD가 CARD_REVEAL 추가 |
| 디스플레이/UI | 11 | 13 | PRD가 SHOW_ANIMATION, HIDE_ANIMATION 추가 |
| 미디어/카메라 | 9 | 9 | 일치 |
| 베팅/재무 | 5 | 5 | 일치 |
| 데이터 전송 | 4 | 4 | 일치 |
| 기록/로그+RFID | 5 | 5 | PRD가 COUNTRY_LIST를 Connection으로 이동, History&RFID로 합침 |
| **합계** | **65** | **82+** | PRD가 역공학 미명시 명령 추가 |

**"113+"의 근거**: RemoteRegistry가 Reflection으로 현재 AppDomain의 모든 어셈블리를 스캔하여 `IRemoteRequest`/`IRemoteResponse` 구현 타입을 자동 등록 (Section 8.5, line 1576). 코드에서 발견된 총 타입 수가 113+이며, 문서 명시 목록은 부분 집합.

**PRD 누락**: IDUP 명령 (역공학 문서에는 있으나 PRD 부록 B에 없음)

---

## G-5. GameInfoResponse 75+ 필드

### 역공학 문서 명시 필드 (Section 8.6, line 1647~1661)

| 카테고리 | 필드 | 수 |
|---------|------|:-:|
| 블라인드 | Ante, Small, Big, Third, ButtonBlind, BringIn, BlindLevel, NumBlinds | 8 |
| 좌석 | PlDealer, PlSmall, PlBig, PlThird, ActionOn, NumSeats, NumActivePlayers | 7 |
| 베팅 | BiggestBet, SmallestChip, BetStructure, Cap, MinRaiseAmt, PredictiveBet | 6 |
| 게임 | GameClass, GameType, GameVariant, GameTitle | 4 |
| 보드 | OldBoardCards, CardsOnTable, NumBoards, CardsPerPlayer, ExtraCardsPerPlayer | 5 |
| 상태 | HandInProgress, EnhMode, GfxEnabled, Streaming, Recording, ProVersion | 6 |
| 디스플레이 | ShowPanel, StripDisplay, TickerVisible, FieldVisible, PlayerPicW, PlayerPicH | 6 |
| 특수 | RunItTimes, RunItTimesRemaining, BombPot, SevenDeude, CanChop, IsChopped | 6 |
| 드로우 | DrawCompleted, DrawingPlayer, StudDrawInProgress, AnteType | 4 |
| **명시 합계** | | **52** |

### "75+"의 근거

Section 8.6은 "주요 필드"만 나열한 요약. 실제 전체 필드 수의 근거:
- `GameTypeData` (Section 4.4, line 644~731)가 79개 필드를 보유
- GameInfoResponse는 GameTypeData의 네트워크 직렬화 버전
- 79개 + 네트워크 전용 추가 필드 = 75+ 이상은 타당한 추정
- 정확한 전체 필드 목록은 역공학 문서에 없음

---

## F-1~2. Lookup Table DB 구조

### 8개 핵심 테이블 (Section 6.4, line 1080~1097)

| 테이블 | 타입 | 크기 | 설명 |
|--------|------|:----:|------|
| `nBitsTable[8192]` | ushort[] | 8192 | 13비트 값의 popcount |
| `straightTable[8192]` | ushort[] | 8192 | Straight 포함 시 최고 카드 랭크, 없으면 0 |
| `topFiveCardsTable[8192]` | uint[] | 8192 | 상위 5개 비트 packed 표현 |
| `topCardTable[8192]` | ushort[] | 8192 | 최상위 비트 랭크 |
| `nBitsAndStrTable[8192]` | ushort[] | 8192 | bitcount + straight 결합 정보 |
| `bits[256]` | byte[] | 256 | 바이트 popcount |
| `CardMasksTable[52]` | ulong[] | 52 | 단일 카드 bitmask |
| `CardTable[52]` | string[] | 52 | 카드 이름 문자열 |

### 538개 정적 배열

- 총 538개 정적 배열이 `.cctor`(static constructor)에서 초기화 (line 1095)
- 메모리 사용량: 약 2.1MB
- 위 8개는 핵심 테이블, 나머지 530개는:
  - 17개 게임별 Evaluator의 사전계산 배열
  - Omaha 조합 테이블 (C(52,4), C(52,5) 등)
  - PocketHand169 preflop 확률 테이블 (`PreCalcPlayerOdds[169][9]`, `PreCalcOppOdds[169][9]`)
  - Short Deck dead cards 상수, Wheel bitmask 등
- 총 수는 Reflection으로 확인된 정확한 값

### Memory-mapped 파일

| 파일 | 로드 클래스 | 설명 |
|------|-----------|------|
| `topFiveCards.bin` | TopTables.cs | 상위 5카드 lookup (line 1097) |
| `topCard.bin` | TopTables.cs | 최상위 카드 lookup |
| `omaha6.vpt` | Omaha6Evaluator | 6-card Omaha 조합, 각 레코드 128바이트, C(52,6)=20,358,520개 (line 1125) |

- 파일 부재 시 인메모리 배열로 fallback
- Double-checked locking으로 thread-safe lazy 초기화

### 암호화 여부

**Lookup table 자체는 암호화 없음.** 순수 수학적 사전계산 결과.
- ConfuserEx가 실행 파일 레벨(메서드 body IL 암호화, XOR key `0x6969696969696968`)에서 보호
- 런타임 복호화 후 배열 데이터 자체는 평문
- `.cctor` 정적 생성자에서 수학적 계산으로 생성되므로 별도 암호화 불필요

---

## C-1. Dual Canvas 역공학 근거

### mixer 클래스 핵심 필드 (Section 7.1, line 1172~1231)

```csharp
public class mixer
{
    // Dual Canvas (Live + Delayed)
    public canvas canvas_live;
    public canvas canvas_delayed;

    // Frame Queues (Producer-Consumer)
    private BlockingCollection<MFFrame> live_frames;
    private BlockingCollection<MFFrame> delayed_frames;
    private BlockingCollection<MFFrame> write_frames;
    private ConcurrentQueue<MFFrame> sync_frames;

    // Worker Threads (5개)
    private Thread thread_worker;                  // 메인 라이브 프레임 처리
    private Thread thread_worker_audio;            // 오디오 프레임 처리
    private Thread thread_worker_delayed;          // 딜레이 프레임 처리
    private Thread thread_worker_write;            // 녹화 파일 쓰기
    private Thread thread_worker_process_delay;    // 딜레이 처리

    // Synchronization
    private bool _sync_live_delay;                 // Live/Delayed 프레임 동기화
    private TimeSpan _delay_period;                // 딜레이 시간
    private bool _delay_enabled;                   // 딜레이 활성화

    // 각 캔버스 독립 투명 배경
    private bool _force_transparent_background_live;
    private bool _force_transparent_background_delay;
}
```

### 데이터 흐름 (Section 7.2~7.3, line 1234~1282)

```
Video Input
    │
    ├──► [live_frames queue] ──► thread_worker ──► canvas_live ──► Live Output (실시간)
    │                                                   │
    │                                              [sync_frames]
    │                                                   │
    └──► [MDelayClass 버퍼] ──► thread_worker_process_delay
                                        │
                                  [delayed_frames queue]
                                        │
                                  thread_worker_delayed
                                        │
                                  canvas_delayed ──► Delayed Output (N초 지연)
```

### 핵심 특성

| 속성 | Live Canvas | Delayed Canvas |
|------|------------|---------------|
| 인스턴스 | `canvas_live` | `canvas_delayed` |
| 프레임 큐 | `live_frames` (BlockingCollection) | `delayed_frames` (BlockingCollection) |
| 워커 스레드 | `thread_worker` | `thread_worker_delayed` |
| 투명 배경 | `_force_transparent_background_live` | `_force_transparent_background_delay` |
| Rate Control | `_live_rate_control` | `_delayed_rate_control` |

- `_sync_live_delay = true`: Live/Delayed 프레임 동기화 활성
- `_delay_period`: TimeSpan으로 딜레이 시간 설정
- MFormats SDK의 `MDelayClass`가 실제 타임시프트 수행
- 각 캔버스는 독립된 BlockingCollection, Thread, canvas 인스턴스 → 완전 병렬 처리

**결론**: Dual Canvas는 추정이 아닌 정확한 역공학 결과. mixer 클래스의 코드 구조에서 직접 확인됨.

---

## 전체 불일치 요약

| # | 항목 | 불일치 | 심각도 | 수정 방향 |
|:-:|------|--------|:------:|----------|
| 1 | 게임 계열 분류 | 역공학 "13-6-3", PRD "13-7-3", 실제 "12-7-3" | **높음** | 모든 곳에서 12-7-3으로 통일 |
| 2 | 역공학 Draw 헤딩 | "Draw 6개" 헤딩이나 테이블은 7개 | 중간 | 역공학 문서 수정 (PRD 수정 불필요) |
| 3 | PRD Connection 분류 | PRD 9개 vs 역공학 7개 | 낮음 | 분류 기준 명시 (PRD 자체는 일관성 있음) |
| 4 | IDUP 누락 | 역공학에 있으나 PRD에 없음 | 낮음 | PRD 부록 B에 IDUP 추가 |
| 5 | 명령어 총 수 | 명시적 65개 vs 82개, 둘 다 "113+" 표기 | 중간 | "113+"의 근거 명확화 (Reflection 타입 수) |
| 6 | GameInfoResponse | 명시 52개, "75+" 표기 | 낮음 | GameTypeData 79필드 참조로 근거 보강 |
| 7 | PRD Game 카테고리 | NEW_HAND, END_HAND가 역공학에 없음 | 중간 | 역공학 미명시이나 존재 확실 (게임 흐름상 필수) |
