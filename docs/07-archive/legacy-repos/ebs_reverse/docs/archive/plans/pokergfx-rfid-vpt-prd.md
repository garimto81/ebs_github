# PRD: PokerGFX Live Poker Broadcast Graphics System

**Product Requirements Document**
**Version**: 3.0.0
**Date**: 2026-02-13
**Product**: PokerGFX Server (RFID-VPT) v3.2.985.0

---

## 1. 제품 개요

### 1.1 제품 정의

PokerGFX RFID-VPT Server는 라이브 포커 방송을 위한 실시간 그래픽 오버레이 시스템이다. RFID 카드 리더로 플레이어의 홀카드를 자동 인식하고, GPU 가속 렌더링으로 방송 화면에 그래픽을 합성하며, 네트워크를 통해 다수의 출력 장치와 동기화한다.

| 속성 | 값 |
|------|-----|
| **정식 명칭** | PokerGFX Server (내부명: RFID-VPT) |
| **버전** | v3.2.985.0 |
| **플랫폼** | Windows (.NET Framework 4.x, WinForms) |
| **바이너리 크기** | 355MB (60개 내장 DLL 포함) |
| **어셈블리** | vpt_server v3.2.985.0 |
| **Entry Point** | `vpt_server.Program.Main` |
| **개발사** | PokerGFX LLC |
| **도메인** | `pokergfx.io`, `videopokertable.net` |

### 1.2 7-Application Ecosystem

PokerGFX는 단일 서버가 아닌 7개 애플리케이션으로 구성된 생태계이다.

| 애플리케이션 | 내부 키 | 역할 | 통신 방식 |
|-------------|--------|------|----------|
| **GfxServer** | `pgfx_server` | 메인 서버 - 게임 상태 관리 + 그래픽 렌더링 | - |
| **ActionTracker** | `pgfx_action_tracker` | 딜러 터치스크린 액션 추적/분석 | Process IPC |
| **HandEvaluation** | `hand_eval_wcf` | 포커 핸드 강도 평가 WCF 서비스 | DLL 직접 호출 |
| **ActionClock** | `pgfx_action_clock` | 액션 타이머 외부 표시 | net_conn TCP |
| **StreamDeck** | `pgfx_streamdeck` | Elgato StreamDeck 하드웨어 연동 | net_conn TCP |
| **Pipcap** | `pgfx_pipcap` | 원격 서버 PIP 캡처 | net_conn TCP |
| **CommentaryBooth** | `pgfx_commentary_booth` | 해설석 전용 뷰어 | net_conn TCP |

### 1.3 대상 사용자

- 라이브 포커 방송 제작자 (TV, 온라인 스트리밍)
- 포커 토너먼트 운영팀
- 카지노/포커룸 방송 엔지니어

---

## 2. 시스템 아키텍처

### 2.1 3세대 아키텍처

시스템은 3세대 아키텍처로 구성된다.

![3세대 아키텍처 진화](../images/mockups/architecture-3gen.png)

### 2.2 모듈 구조

| 모듈 | 파일 수 | 크기 | 역할 | 핵심 기술 |
|------|:------:|------|------|----------|
| **vpt_server.exe** | 347 | 355MB | 메인 애플리케이션 | WinForms, DirectX 11, DI |
| **net_conn.dll** | 168 | 118KB | 네트워크 프로토콜 | TCP/UDP, AES-256, JSON |
| **boarssl.dll** | 102 | 207KB | TLS 암호화 | BearSSL C# 포팅, TLS 1.2 |
| **mmr.dll** | 80 | 149KB | GPU 렌더링 엔진 | DirectX 11, SharpDX, MFormats |
| **hand_eval.dll** | 52 | 330KB | 핸드 평가 | Bitmask, Lookup Table |
| **PokerGFX.Common.dll** | 50 | 566KB | 공유 라이브러리 | AES, Logging, DI |
| **RFIDv2.dll** | 26 | 57KB | RFID 카드 리더 | TCP/WiFi, USB HID |
| **analytics.dll** | 7 | 23KB | 텔레메트리 | SQLite, AWS S3 |

### 2.3 의존성 계층

![의존성 계층](../images/mockups/dependency-tree.png)

### 2.4 메타데이터 통계

| 메트릭 | 수치 |
|--------|------|
| TypeDef | 2,602 |
| MethodDef | 14,460 |
| Field | 6,793 |
| Property | 981 |
| Event | 30 |
| AssemblyRef | 36 |
| ManifestResource | 136 |
| 내장 DLL | 60개 (Costura.Fody 패키징) |

### 2.5 내장 라이브러리

60개 DLL이 Costura.Fody로 내장 패키징. 상세 목록은 **부록 B** 참조.

---

## 3. 포커 게임 엔진

### 3.1 지원 게임 (22개 변형)

| ID | 게임 | 카테고리 |
|:--:|------|---------|
| 0 | **Texas Hold'em** | Community Card |
| 1 | Short Deck 6+ (Straight > Trips) | Community Card |
| 2 | Short Deck 6+ (Trips > Straight) | Community Card |
| 3 | Pineapple | Community Card |
| 4 | Omaha (4-card) | Community Card |
| 5 | Omaha Hi/Lo | Community Card |
| 6 | 5-Card Omaha | Community Card |
| 7 | 5-Card Omaha Hi/Lo | Community Card |
| 8 | 6-Card Omaha | Community Card |
| 9 | 6-Card Omaha Hi/Lo | Community Card |
| 10 | Courchevel | Community Card |
| 11 | Courchevel Hi/Lo | Community Card |
| 12 | 5-Card Draw | Draw |
| 13 | 2-7 Single Draw | Draw |
| 14 | 2-7 Triple Draw | Draw |
| 15 | A-5 Triple Draw | Draw |
| 16 | Badugi | Draw |
| 17 | Badeucy | Draw |
| 18 | Badacey | Draw |
| 19 | 7-Card Stud | Stud |
| 20 | 7-Card Stud Hi/Lo | Stud |
| 21 | Razz | Stud |

> Short Deck(6+)는 2개 별도 variant: straight beats trips(=1)와 trips beats straight(=2)

**게임 계열 분류**: `game_class { flop=0, draw=1, stud=2 }`

### 3.2 베팅 구조

| 값 | 구조 | 설명 |
|:--:|------|------|
| 0 | **No-Limit** | 무제한 레이즈 |
| 1 | **Fixed-Limit** | 고정 베팅 단위 |
| 2 | **Pot-Limit** | 팟 크기 제한 레이즈 |

### 3.3 앤티 유형 (7종)

| 타입 | 설명 |
|------|------|
| `std_ante` | 표준 앤티 (모든 플레이어) |
| `button_ante` | 버튼(딜러) 앤티 |
| `bb_ante` | 빅블라인드 앤티 |
| `bb_ante_bb1st` | BB 앤티 (BB 먼저 수납) |
| `live_ante` | 라이브 앤티 |
| `tb_ante` | Third Blind 앤티 |
| `tb_ante_tb1st` | TB 앤티 (TB 먼저 수납) |

### 3.4 GameTypeData (게임 상태 DTO - 79+ 필드)

게임의 전체 상태를 담는 직렬화 가능 데이터 객체:

**게임 설정**: `_gfxMode`, `_game_variant`, `bet_structure`, `_ante_type`, `num_boards`, `hand_num`

**블라인드/베팅**: `_small`, `_big`, `_third`, `_ante`, `cap`, `bomb_pot`, `seven_deuce_amt`, `smallest_chip`, `blind_level`, `_bring_in`, `_low_limit`, `_high_limit`

**게임 상태**: `hand_in_progress`, `hand_ended`, `dist_pot_req`, `_next_hand_ok`, `_chop`, `card_scan_warning`

**플레이어 포지션**: `action_on`, `pl_dealer`, `pl_small`, `pl_big`, `pl_third`, `_first_to_act`, `last_bet_pl`, `starting_players`

**Run It**: `run_it_times`, `run_it_times_remaining`, `run_it_times_num_board_cards`

**Stud/Draw**: `stud_draw_in_progress`, `draws_completed`, `drawing_player`

**보안**: `_enh_mode`, `_dotfus_tampered` (변조 감지 플래그)

---

## 4. 핸드 평가 엔진 (hand_eval.dll)

### 4.1 Bitmask 카드 표현

64-bit `ulong` bitmask로 52장의 카드를 표현한다:

```
비트 레이아웃 (64비트 중 52비트 사용, 13비트 연속 배치):
[--- Spades ---][--- Hearts ---][--- Diamonds ---][--- Clubs ---]
 bits 39-51       bits 26-38       bits 13-25        bits 0-12

Suit Offset:
CLUB_OFFSET    = 13 * 0 = 0
DIAMOND_OFFSET = 13 * 1 = 13
HEART_OFFSET   = 13 * 2 = 26
SPADE_OFFSET   = 13 * 3 = 39

각 suit 내 (13비트):
bit 0 = 2 (최저), bit 1 = 3, ..., bit 12 = Ace (최고)
```

### 4.2 평가 알고리즘

| 평가 경로 | 알고리즘 | 대상 게임 |
|----------|----------|----------|
| **5-card** | Lookup table (O(1)) | Hold'em, Stud |
| **Omaha 4-card** | Exhaustive 조합 | Omaha |
| **Omaha 5/6-card** | Memory-mapped file | Omaha 5/6 |
| **Hi/Lo** | 별도 Lo evaluator | Hi/Lo 변형 |
| **Draw** | Rank-based | Draw 게임 |
| **Monte Carlo** | Threshold switching | 에퀴티 계산 |

### 4.3 Lookup Table 아키텍처

| 테이블 | 크기 | 용도 |
|--------|------|------|
| `nBitsTable` | 8,192 | bit count (0-13) |
| `straightTable` | 8,192 | 스트레이트 감지 |
| `topFiveCardsTable` | 8,192 | 상위 5장 선택 |
| `m_evaluatedresults` | 8,192 | 최종 핸드 값 |
| `CardMasksTable` | 52 entries | 카드→bitmask 변환 |
| `Pocket169Table` | 169 entries | 프리플롭 핸드 분류 |

**총 538개 정적 배열**

### 4.4 7-Card 평가 흐름

```
Evaluate(hand: ulong) → uint:
  1. 수트별 bitmask 분리 (13-bit shifts, 0x1FFF 마스크)
     clubs(bit 0-12), diamonds(bit 13-25), hearts(bit 26-38), spades(bit 39-51)
  2. Flush 감지: nBitsTable[suit] >= 5 → m_evaluatedresults[suit] 반환
  3. Non-flush: 전체 랭크 OR 합산 → m_evaluatedresults[ranks] 반환
```

### 4.5 핸드 랭킹 (hand_class enum)

| 값 | 핸드 |
|:--:|------|
| 0 | High Card |
| 1 | One Pair |
| 2 | Two Pair |
| 3 | Three of a Kind |
| 4 | Straight |
| 5 | Flush |
| 6 | Full House |
| 7 | Four of a Kind |
| 8 | Straight Flush |
| 9 | Royal Flush |

**HandValue 인코딩**: `uint` - bits 24-27: HandType (0-8), bits 0-23: 세부 순위 (킥커 포함)

### 4.6 핵심 API

| API | 시그니처 | 설명 |
|-----|---------|------|
| **평가** | `Evaluate(cards, numberOfCards, ignore_wheel)` → `uint` | 핸드 값 계산 |
| **파싱** | `ParseHand(hand)` → `ulong mask` | 문자열→bitmask |
| **서술** | `DescriptionFromHandValue(hv)` → `string` | 핸드 설명 |
| **확률** | `HandOdds(pockets, board, dead, wins, ties, losses, total)` | 승률 계산 |
| **아웃** | `Outs(player, board, opponents, dead, include_splits)` → `int` | 아웃츠 |
| **랜덤** | `RandomHands(shared, dead, ncards, trials)` → `IEnumerable<ulong>` | Monte Carlo |

### 4.7 카드 표기 시스템

- **값**: `2`-`9`, `t`(10), `j`(Jack), `q`(Queen), `k`(King), `a`(Ace)
- **수트**: `c`(Clubs), `d`(Diamonds), `h`(Hearts), `s`(Spades)
- **핸드**: `AKs`(suited), `AKo`(offsuit) → PocketHand169Enum (170값)
- **그룹**: GroupTypeEnum (Group1~Group8) → Sklansky 핸드 그룹핑

### 4.8 게임별 평가기

| 게임 | 평가기 클래스 |
|------|------------|
| Texas Hold'em / 6-max | `Hand` |
| Short Deck 6+ | `holdem_sixplus` (`trips_beats_straight` 파라미터) |
| Omaha 4-card (Hi/Lo) | `OmahaEvaluator` |
| Omaha 5-card (Hi/Lo) | `Omaha5Evaluator` |
| Omaha 6-card (Hi/Lo) | `Omaha6Evaluator` (Memory-Mapped File) |
| 5-Card Draw / 2-7 Draw | `draw` |
| 7-Card Stud (Hi/Lo) | `stud` |
| Razz | `Razz` (A-5 lowball) |
| Badugi | `Badugi` (flush/pair 제거) |

---

## 5. 실시간 GPU 렌더링 (mmr.dll)

### 5.1 파이프라인 아키텍처

![GPU Pipeline Architecture](../images/mockups/gpu-pipeline.png)

### 5.2 5-Thread Worker Architecture

| Thread | 역할 | 데이터 소스 |
|--------|------|-----------|
| `thread_worker` | 라이브 프레임 GPU 렌더링 | `BlockingCollection<MFFrame> live_frames` |
| `thread_worker_audio` | 오디오 캡처 + 믹싱 | `AutoResetEvent are_audio` |
| `thread_worker_delayed` | 딜레이 프레임 렌더링 | `BlockingCollection<MFFrame> delayed_frames` |
| `thread_worker_write` | 녹화 파일 쓰기 | `BlockingCollection<MFFrame> write_frames` |
| `thread_worker_process_delay` | 딜레이 버퍼 관리 | `AutoResetEvent are_delay` |

### 5.3 Dual Canvas System

- **Live Canvas**: 실시간 방송 출력 (카메라 + 그래픽 오버레이)
- **Delayed Canvas**: 시간차 방송 출력 (동일 그래픽, 설정 가능한 N초 지연)
- `_sync_live_delay`: Live/Delayed 프레임 동기화 옵션
- `_delay_period`: 딜레이 시간 (TimeSpan)

### 5.4 DirectX 11 Rendering

- **Device**: D3D11 Device + D2D Device + DirectWrite Factory
- **Texture**: `Texture2D` 렌더 타겟 + 더블 버퍼링 (`Bitmap[2]`)
- **GPU Effects Chain**: Crop → Transform → Brightness → Alpha → ColorMatrix → HueRotation
- **Cross-GPU Texture Sharing**: `bridge` 클래스 - DXGI SharedHandle 기반

### 5.5 그래픽 레이어 (Z-order)

| 레이어 | 요소 | 설명 |
|--------|------|------|
| 1 (최하단) | `image_element` | 이미지 오버레이 (스프라이트, 로고) |
| 2 | `text_element` | 텍스트 오버레이 (Ticker, Reveal 효과) |
| 3 | `pip_element` | Picture-in-Picture (카메라 뷰) |
| 4 (최상단) | `border_element` | 보더 프레임 |

### 5.6 출력 모드

| 모드 | 설명 |
|------|------|
| **Live** | 실시간 출력 |
| **Delayed** | 시간차 출력 |
| **Record** | 파일 녹화 (Live/Delayed/Both) |
| **NDI** | NewTek NDI 네트워크 출력 |
| **Fill & Key** | External Keyer (Decklink 하드웨어) |

**녹화 모드**: `live`, `live_no_overlay`, `delayed`, `delayed_no_overlay`
**재생 속도**: `normal`, `x2`, `x4`, `reverse_x2`, `reverse_x4`

### 5.7 GPU 벤더별 코덱 설정

| GPU | 녹화 코덱 | 스트림 코덱 | 디코더 |
|-----|----------|-----------|--------|
| NVIDIA | `n264` (NVENC) CQP qp=20 | `n264` CBR 5M low_latency | `decoder.nvidia='true'` |
| AMD | `h264_amf` 50M | `h264_amf` 10M | default |
| Intel QSV | `q264hw` CBR 50M | `q264hw` CBR 5M | `decoder.quicksync=1` |
| Software | `libopenh264` 50M | `libopenh264` 5M | default |

컨테이너: MP4 (녹화), MPEGTS (스트리밍). 오디오: AAC 192k

### 5.8 스트리밍 프로토콜

| 프로토콜 | 구현 | 설명 |
|---------|------|------|
| **SRT** | `duplex_link` (30필드, 33메서드) | `srt://?mode=listener&passphrase=` / `srt://?mode=caller` |
| **NDI** | `[NDI]_` prefix 네이밍 | `NDI_WAIT_PERIOD_MS` 타임아웃 |
| **BMD** | Blackmagic `decklink`/`blackmagic` | 하드웨어 출력 |

### 5.9 지원 입력 디바이스

| 타입 | 설명 |
|------|------|
| Decklink | Blackmagic Design 캡처 카드 |
| USB | USB 웹캠 |
| NDI | NewTek NDI 네트워크 소스 |
| URL | RTMP/RTSP/HLS 스트림 |

`video_capture_device_type`: `unknown`, `dshow`, `NDI`, `BMD`, `network`

---

## 6. 그래픽 요소 시스템

### 6.1 Element Hierarchy

![GraphicElement Class Hierarchy](../images/mockups/element-hierarchy.png)

### 6.2 Animation System (11 classes)

| 애니메이션 | 대상 | 효과 |
|-----------|------|------|
| `BoardCardAnimation` | 보드 카드 | 등장 애니메이션 |
| `PlayerCardAnimation` | 플레이어 카드 | 등장 애니메이션 |
| `CardBlinkAnimation` | 카드 | 깜빡임 하이라이트 |
| `CardUnhiliteAnimation` | 카드 | 하이라이트 해제 |
| `GlintBounceAnimation` | 그래픽 | 반짝임 + 바운스 |
| `OutsCardAnimation` | 아웃츠 | 카드 등장 |
| `PanelImageAnimation` | 패널 | 이미지 전환 |
| `PanelTextAnimation` | 패널 | 텍스트 전환 |
| `FlagHideAnimation` | 국기 | 숨김 효과 |

#### AnimationState enum (16 states)

```
FadeIn=0, Glint=1, GlintGrow=2, GlintRotateFront=3,
GlintShrink=4, PreStart=5, ResetRotateBack=6, ResetRotateFront=7,
Resetting=8, RotateBack=9, Scale=10, SlideAndDarken=11,
SlideDownRotateBack=12, SlideUp=13, Stop=14, Waiting=15
```

### 6.3 ConfigurationPreset (99+ 필드)

모든 그래픽 출력 설정을 포함하는 메가 DTO:

| 카테고리 | 주요 필드 |
|---------|----------|
| **레이아웃** | `board_pos`, `gfx_vertical`, `gfx_bottom_up`, `gfx_fit`, `heads_up_layout_mode`, margins |
| **표시** | `at_show`, `fold_hide`, `card_reveal`, `show_rank`, `show_seat_num`, `rabbit_hunt`, `dead_cards` |
| **전환 효과** | `trans_in`/`trans_out` (type + time) |
| **통계** | VPIP, PFR, AGR, WTSD, Position, CumWin, Payouts (`auto_stat_*`, `ticker_stat_*`) |
| **칩 정밀도** | 8개 영역: leaderboard, pl_stack, pl_action, blinds, pot, twitch, ticker, strip |
| **통화** | `currency_symbol`, `show_currency`, `trailing_currency_symbol`, `divide_amts_by_100` |
| **로고** | `panel_logo`, `board_logo`, `strip_logo` (`byte[]`) |

### 6.4 Skin 시스템

#### 6.4.1 Skin 파일 (.vpt / .skn)

- **기본 스킨**: `vpt_server.Skins.default.skn` (내장 리소스)
- **암호화**: `SKIN_HDR` + `SKIN_SALT` + `SKIN_PWD`로 AES 암호화
- **CRC 검증**: `skin_crc`로 무결성 확인
- **Master-Slave 동기화**: Slave는 Master에서 스킨 다운로드

#### 6.4.2 Skin 인증

```
skin_auth_result { no_network=0, permit=1, deny=2 }
```

마스터 서버를 통해 스킨 인증. 네트워크 장애 시 `no_network`로 기존 스킨 지속 사용 허용.

#### 6.4.3 Skin Editor

`skin_edit` Form으로 시각적 편집:
- 그래픽 요소 위치/크기 조정
- 색상, 폰트, 투명도 설정
- 프리뷰 + 실시간 반영

---

## 7. 네트워크 프로토콜 (net_conn.dll)

### 7.1 프로토콜 스택

![4-Layer Protocol Stack](../images/mockups/protocol-stack.png)

**직렬화 이중성** (프로토콜 마이그레이션 과도기):
- **현재 (v2.0+)**: `Newtonsoft.Json.JsonConvert.SerializeObject()` → JSON
- **레거시 (v1.x)**: CSV 기반 `ToString()` + `string[] cmd` 생성자 공존
- 대부분 Model 클래스에 CSV/JSON 양쪽 직렬화 코드가 공존

### 7.2 서버 발견 (UDP Discovery)

1. Client → Broadcast UDP (port 9000)
2. Server → Unicast UDP Response (서버 정보)
3. Client → TCP Connect (port 9001)
4. AES 암호화 세션 수립

### 7.3 암호화 상세

| 속성 | 값 |
|------|-----|
| **알고리즘** | Rijndael (AES-256) |
| **키 유도** | PasswordDeriveBytes (PBKDF1) |
| **Password** | `"45389rgjkonlgfds90439r043rtjfewp9042390j4f"` |
| **Salt** | `"dsafgfdagtds4389tytgh"` (UTF-8 → bytes) |
| **IV** | `"4390fjrfvfji9043"` (UTF-8 → 16 bytes) |
| **패딩** | 암호화: PKCS7, 복호화: None (수동 패딩 제거) |
| **Wire Format** | `AES(JSON_bytes) + SOH(0x01)` |
| **커스텀 키** | `enc.init(pwd)`로 배포별 키 설정 가능 |

### 7.4 RemoteRegistry (Command Routing)

- Singleton 인스턴스
- Reflection 기반 `Command → Type` 매핑
- 수신 JSON의 `Command` 필드로 역직렬화 타입 결정

### 7.5 프로토콜 명령어 (113+ 카테고리별)

| 카테고리 | 명령 수 | 예시 |
|---------|:------:|------|
| **연결** | 9 | AUTH, CONNECT, DISCONNECT, HEARTBEAT, KEEPALIVE, STATUS |
| **게임** | 10+ | GAME_INFO, GAME_STATE, GAME_TYPE, GAME_VARIANT |
| **플레이어** | 21+ | PLAYER_INFO, PLAYER_ADD/DEL/CARDS/FOLD/BET/BLIND/WIN/STACK |
| **카드/보드** | 6 | BOARD_CARD, EDIT_BOARD, FORCE_CARD_SCAN, DRAW_DONE |
| **핸드** | 8 | START_HAND, RESET_HAND, HAND_HISTORY, RUN_IT_TIMES |
| **디스플레이** | 13 | SHOW_PANEL, GFX_ENABLE, FIELD_VIS, ACTION_CLOCK |
| **미디어** | 9 | MEDIA_LIST/PLAY/LOOP, VID_SOURCES, VIDEO_PORT |
| **스킨/로고** | 8 | SKIN_REQ/SKIN, BOARD_LOGO_REQ/BOARD_LOGO, PANEL_LOGO, STRIP_LOGO |
| **데이터** | 10 | TAG/TAG_LIST, TICKER, COUNTRY_LIST, READER_STATUS |
| **기타** | 7+ | PIPREQUEST, SLAVE_STREAMING, CAP, REGISTER_DECK |

### 7.6 CSV Wire Format 규칙

형식: `COMMAND,field1,field2,...\n` (이스케이프: `,` → `~`, bool → `"1"`/`"0"`, 압축: GZip suffix)

### 7.7 IClientNetworkListener 콜백 (16개)

`NetworkQualityChanged`, `OnConnected`, `OnDisconnected`, `OnAuthReceived`, `OnReaderStatusReceived`, `OnHeartBeatReceived`, `OnDelayedGameInfoReceived`, `OnGameInfoReceived`, `OnMediaListReceived`, `OnCountryListReceived`, `OnPlayerPictureReceived`, `OnGameVariantListReceived`, `OnPlayerInfoReceived`, `OnDelayedPlayerInfoReceived`, `OnVideoSourcesReceived`, `OnSourceModeReceived`

### 7.8 Master-Slave Architecture

![Master-Slave Network Topology](../images/mockups/master-slave.png)

**동기화 항목**: 게임 상태 (실시간), 핸드 로그, 스킨 파일 (.vpt), 그래픽 설정, ATEM 스위처 주소, Twitch 채널

**slave 클래스** (34개 필드): 연결 상태 (`_connected`, `_authenticated`, `_synced`), 마스터 설정, 스킨 관리/배포, 스트리밍 상태, 캐시 (`_cachedIsAnySlaveStreaming`), 쓰로틀링 (`_minUpdateInterval`, `_graphicsRefreshThrottle`)

---

## 8. RFID 카드 리더 (RFIDv2.dll)

### 8.1 Dual Transport Architecture

![RFID Dual Transport Architecture](../images/mockups/rfid-dual-transport.png)

### 8.2 하드웨어 지원

| 모듈 | 연결 | 보안 | 안테나 |
|------|------|------|--------|
| **SkyeTek** (구형) | USB HID | 없음 | 단일 |
| **v2 Rev1** | TCP/WiFi + USB | TLS 1.2 (BearSSL) | REV1_MAX_PHYS + REV1_MAX_VIRT |
| **v2 Rev2** | TCP/WiFi + USB | TLS 1.2 (BearSSL) | REV2_MAX_PHYS + REV2_MAX_VIRT |

### 8.3 Reader State Machine

![Reader State Machine](../images/mockups/reader-state-machine.png)

`reader_state { disconnected, connected, negotiating, ok }`
`wlan_state { off, on, connected_reset, ip_acquired, not_installed }`

### 8.4 Text Command Protocol (22개)

형식: `COMMAND [ARGS]\n` → `OK COMMAND [DATA]\n`

| 코드 | 기능 | 방향 |
|------|------|------|
| TI | Tag Inventory (스캔) | → Reader |
| TR | Tag Read (메모리 블록) | → Reader |
| TW | Tag Write | → Reader |
| AU | 리더 인증 | → Reader |
| FW | Firmware 업데이트 | → Reader |
| GM/GN/GP | 모듈 정보/이름/비밀번호 Get | → Reader |
| SM/SN/SP | 모듈 정보/이름/비밀번호 Set | → Reader |
| GH/GF/GV | HW 리비전/FW 버전 조회 | → Reader |
| GO/SO | WLAN 상태/설정 | ↔ |
| GI/SI | IP 설정 | ↔ |
| GS/SS/GW/SW | SSID/비밀번호 | ↔ |

### 8.5 카드 인코딩

- Mifare Ultralight, Mifare 1k 지원
- UID: Hex 문자열, `" | "` 구분
- 인증 토큰: `"xxxxxxxxxxxxCCC"` (12자 + 3자 체크)
- Hex charset: `"0123456789ABCDEF"`

### 8.6 TLS 보안 (BearSSL)

- Server identity: `"vpt-server"`, Client identity: `"vpt-reader"`
- `SSLClient`, `SSLEngine`, `ECPublicKey` 사용
- `SSLSessionParameters` 캐싱 (세션 재개 지원)
- Keepalive 유지 (`KEEPALIVE_INTERVAL`)

---

## 9. 보안 체계

### 9.1 4-Layer DRM System

![4-Layer DRM System](../images/mockups/drm-4layer.png)

### 9.2 인증 흐름

`LoginCommand(Email, Password, CurrentVersion) → LoginCommandValidator → LoginHandler(5 deps) → AuthenticationService → RemoteLoginResponse {Token, ExpiresIn, Email, UserType, UseName, UserId, Updates} → LoginResult {IsSuccess, ErrorMessage, ValidationResult, VersioningResult}`

### 9.3 라이선스 등급

```
LicenseType: Basic=1, Professional=4, Enterprise=5
```

| 등급 | 기능 게이트 |
|------|-----------|
| Basic | 기본 그래픽 |
| Professional | 멀티카메라, SRT |
| Enterprise | MultiGFX, LiveDataExport, CaptureScreens |

### 9.4 오프라인 세션

```
OfflineLoginStatus { LoginSuccess, LoginFailure, CredentialsExpired, CredentialsFound, CredentialsNotFound }
```

네트워크 장애 시 로컬 캐시 자격증명으로 인증. 만료일 관리.

### 9.5 3중 AES 암호화 시스템

| 시스템 | 모듈 | 알고리즘 | 키 유도 | 용도 |
|--------|------|---------|--------|------|
| **System 1** | net_conn.dll (enc.cs) | Rijndael AES-256 | PBKDF1 | 네트워크 통신 |
| **System 2** | PokerGFX.Common | AES-256 | Base64 직접 | 설정 데이터 |
| **System 3** | vpt_server (config) | AES | SKIN_PWD+SALT | Skin 파일 |

### 9.6 코드 보호

- **ConfuserEx**: method body 암호화, 제어 흐름 난독화, 문자열 암호화
- **Dotfuscator**: `_dotfus_tampered` 변조 감지 → `client_ping`으로 마스터 서버에 자동 보고
- **KEYLOK Anti-Debugger**: `LaunchAntiDebugger` 필드로 디버거 탐지

### 9.7 WCF 통신

- Endpoint: `http://videopokertable.net/wcf.svc`
- SOAP Action: `http://tempuri.org/Iwcf/get_file_block`
- 인증서: X.509 Self-signed (2019-2156)
- 용도: Server ↔ Remote 라이선스 RPC

---

## 10. 하드웨어 인터페이스

### 10.1 RFID 카드 리더

RFID 하드웨어 상세는 **섹션 8** 참조. 지원 모듈: SkyeTek (구형, USB HID) + v2 (Rev1/Rev2, TCP/WiFi + USB, TLS 1.2).

### 10.2 KEYLOK USB Dongle

DRM Layer 3 하드웨어 동글. 상세는 **섹션 9.1** 참조.

- 3세대 지원: `DongleType { Unknown=0, Fortress=1, Keylok3=2, Keylok2=3 }`
- P/Invoke API: 23+ 명령
- KLClientCodes (16개): ValidateCode1-3, ClientIDCode1-2, ReadCode1-3, WriteCode1-3, KLCheck, ReadAuth, GetSN, WriteAuth, ReadBlock, WriteBlock

### 10.3 Blackmagic ATEM Switcher

- COM Interop (Blackmagic Desktop Video SDK)
- 프로그램/프리뷰 전환, Mix Effect 블록 제어
- 입력 모니터링, 카메라 자동 전환 (게임 이벤트 연동)
- `state_enum { NotInstalled=0, Disconnected=1, Connected=2, Paused=3, Reconnect=4, Terminate=5 }`

### 10.4 비디오 캡처 장치

- Decklink 캡처 카드 (SDI/HDMI), DirectShow COM Interop
- NDI 네트워크 소스, URL 스트림 (RTMP/RTSP/HLS)

---

## 11. 외부 서비스 통합

### 11.1 API Endpoints

| 서비스 | URL | 용도 |
|--------|-----|------|
| **PokerGFX API** | `https://api.pokergfx.io/api/v1/` | 버전 체크, 다운로드, 텔레메트리 |
| **Analytics Batch** | `https://api.pokergfx.io/api/v1/analytics/batch` | 텔레메트리 배치 전송 |
| **WCF Service** | `http://videopokertable.net/wcf.svc` | 라이선스 RPC |
| **Download** | `https://videopokertable.net/Download.aspx` | 업데이트 다운로드 |
| **Login** | `https://www.pokergfx.io` | 로그인/인증 |
| **Twitch OAuth** | `https://id.twitch.tv/oauth2/authorize` | Twitch 인증 |
| **Twitch API** | `https://api.twitch.tv/kraken/channels/` | 채널 정보 |
| **Twitch Validate** | `https://id.twitch.tv/oauth2/validate` | 토큰 검증 |
| **Twitch Callback** | `http://videopokertable.net/twitch_oauth.aspx` | OAuth 콜백 |
| **AWS S3** | `captures.pokergfx.io` | 스크린샷 업로드 |
| **Bugsnag** | `https://notify.bugsnag.com` | 크래시 리포팅 |

### 11.2 Twitch Integration

IRC 프로토콜 기반 채팅봇 (`irc.chat.twitch.tv:6667`). OAuth 인증 → JOIN → PRIVMSG 파싱, PING/PONG keepalive, 시청자 채팅 명령어 → 게임 정보 응답.

### 11.3 LiveApi (HTTP REST)

TCP 기반 HTTP 인터페이스. 외부 시스템에서 VPT 서버 제어, 실시간 게임 데이터 조회, Keepalive 유지.

### 11.4 Third-Party SDK/Library

| 라이브러리 | 용도 | 참조 |
|-----------|------|------|
| **SharpDX** | DirectX 11 래퍼 | 섹션 5 |
| **MFormats SDK** (Medialooks) | 비디오 캡처/렌더링 (상용, CompanyID `13751`) | 섹션 5 |
| **BearSSL** (C# port) | TLS 1.0-1.2 | 섹션 8 |
| **Costura.Fody** | 어셈블리 내장 패키징 (60개 DLL) | 부록 B |
| **Newtonsoft.Json** | JSON 직렬화 | - |
| **FluentValidation** | 입력 검증 (Phase 3) | - |
| **EO.WebEngine** | 내장 Chromium (OAuth 웹 뷰) | - |
| **EntityFramework 6.0** | SQL Server 데이터 저장소 | - |

---

## 12. 데이터 모델

### 12.1 핵심 Enum 카탈로그 (62+ 타입)

#### game enum (22개 변형)

```
holdem=0, holdem_sixplus_straight_beats_trips=1,
holdem_sixplus_trips_beats_straight=2, pineapple=3,
omaha=4, omaha_hilo=5, omaha5=6, omaha5_hilo=7,
omaha6=8, omaha6_hilo=9, courchevel=10, courchevel_hilo=11,
draw5=12, deuce7_draw=13, deuce7_triple=14, a5_triple=15,
badugi=16, badeucy=17, badacey=18, stud7=19, stud7_hilo8=20, razz=21
```

#### GfxMode enum

| 값 | 모드 | 설명 |
|:--:|------|------|
| 0 | Live | 실시간 방송 (딜러/테이블 화면, 홀카드 미노출) |
| 1 | Delay | 시간차 방송 (시청자용, 홀카드 노출) |
| 2 | Comm | 해설석 모드 (해설자 모니터, 홀카드 노출) |

#### LicenseType enum

```
Basic=1, Professional=4, Enterprise=5
```

#### DongleType enum

```
Unknown=0, Fortress=1, Keylok3=2, Keylok2=3
```

#### lang_enum (130개 UI 표시 라벨)

```
check=0, all_in=1, call=2, raise_to=3, bet=4, stack=5, pot=6, fold=7,
dealer=8, bb=9, sb=10, straddle=11, ante=12,
player_of_the_year=13, ...
(총 130개 - strip_pfr=129까지)
```

#### 기타 핵심 Enum

| Enum | 값 | 용도 |
|------|-----|------|
| `game_class` | flop=0, draw=1, stud=2 | 게임 계열 |
| `hand_class` | HighCard=0 ~ RoyalFlush=9 | 핸드 등급 |
| `card_type` | 53값 | 카드 종류 |
| `skin_auth_result` | no_network=0, permit=1, deny=2 | 스킨 인증 |
| `state_enum` (ATEM) | NotInstalled=0 ~ Terminate=5 | ATEM 연결 |
| `reader_state` | disconnected, connected, negotiating, ok | RFID 상태 |
| `wlan_state` | off, on, connected_reset, ip_acquired, not_installed | WiFi 상태 |
| `module_type` | skyetek, v2 | RFID 모듈 |
| `connection_type` | usb, wifi | 연결 타입 |
| `BetStructure` | NoLimit=0, FixedLimit=1, PotLimit=2 | 베팅 구조 |
| `AnteType` | std_ante ~ tb_ante_tb1st (7값) | 앤티 유형 |
| `OfflineLoginStatus` | LoginSuccess ~ CredentialsNotFound (5값) | 오프라인 상태 |
| `board_pos_type` | 3값 | 보드 위치 |
| `show_type` | 3값 | 표시 유형 |
| `transition_type` | 4+값 | 전환 효과 |
| `chipcount_precision_type` | 3값 | 칩 정밀도 |
| `timeshift` | Live, Delayed | 시간 이동 |
| `record` | 4값 | 녹화 대상 |
| `platform` | 2값 | 렌더링 플랫폼 |
| `AnimationState` | FadeIn=0 ~ Waiting=15 (16값) | 애니메이션 |

### 12.2 config_type (282 필드)

전체 시스템 설정을 담는 거대 DTO.

| 도메인 | 주요 필드 | 설명 |
|--------|----------|------|
| **비디오** | `fps`, `video_w`, `video_h`, `video_bitrate`, `video_encoder` | 출력 비디오 |
| **카메라** | camera 관련 (복수) | 입력 소스 |
| **스트리밍** | `stream_push_url`, `stream_username`, `stream_pwd` | RTMP 스트리밍 |
| **Twitch** | chatbot 연동 필드 | Twitch 통합 |
| **YouTube** | `youtube_username`, `youtube_pwd`, `youtube_title`, `youtube_tags`, `youtube_category` | YouTube 라이브 |
| **그래픽** | `skin`, `font`, `transition`, `animation` | UI 렌더링 |
| **RFID** | `rfid_board_delay`, `card_auth_package_crc` | 카드 인식 |
| **보안** | `settings_pwd`, `capture_encryption`, `kiosk_mode` | 접근 제어 |
| **Commentary** | `delayed_commentary`, external delay | 해설 지연 |
| **통계** | `auto_stat_vpip`, `auto_stat_pfr`, `auto_stat_agr`, `auto_stat_wtsd` | 자동 통계 |
| **Chipcount** | `chipcount_precision_type` 외 12개 | 칩카운트 정밀도 |

저장 경로: `%APPDATA%\RFID-VPT`, 파일 확장자: `.pgfxconfig`

### 12.3 Player 데이터 모델

| 필드 | 타입 | 설명 |
|------|------|------|
| PlayerNum | int | 좌석 번호 |
| Name | string | 플레이어 이름 |
| LongName | string | 긴 이름 |
| Country | string | 국가 코드 |
| Stack | int | 칩 스택 |
| Cards | card[] | 홀카드 |
| SittingOut | bool | 자리비움 |
| VPIPPercent | int | VPIP 통계 |
| AggressionFrequencyPercent | int | 공격성 통계 |
| PreFlopRaisePercent | int | PFR 통계 |
| WentToShowDownPercent | int | WTSD 통계 |
| CumulativeWinningsAmt | int | 누적 수익 |
| EliminationRank | int | 탈락 순위 |

### 12.4 Hand 데이터 모델

**Hand**: HandNum, Description, StartDateTimeUTC, RecordingOffsetStart, Duration, GameClass, GameVariant, BetStructure, AnteAmt, BombPotAmt, NumBoards, RunItNumTimes, FlopDrawBlinds, StudLimits, `List<Player>`, `List<Event>`

**Event**: EventType, DateTimeUTC, PlayerNum, BetAmt, NumCardsDrawn, BoardNum, Pot, BoardCards

**FlopDrawBlinds**: BlindLevel, AnteType, SmallBlindAmt, BigBlindAmt, ThirdBlindAmt, ButtonPlayerNum, SmallBlindPlayerNum, BigBlindPlayerNum, ThirdBlindPlayerNum

### 12.5 PlayerStrength

`PlayerStrength { Num: int, Strength: ulong }` - 핸드 강도 (64비트 bitmask, hand_eval 연동)

### 12.6 WCF DTO

| DTO | 방향 | Methods | 주요 필드 |
|-----|------|:-------:|----------|
| **client_ping** | Slave → Master | 49 | 시스템 성능 (cpu/gpu), 미디어 상태, RFID 연결, 라이선스 시리얼, 변조 감지, 설정 동기화 |
| **server_ping** | Master → Slave | 23 | 현재 액션, 카드 인증 패키지, 기능 플래그 (live_api, live_data_export) |

---

## 13. Service Architecture

### 13.1 GameTypes Service Layer (Phase 2)

10개 인터페이스 + 11개 구현:

| Interface | Implementation | Methods | 역할 |
|-----------|---------------|:-------:|------|
| `IGameConfigurationService` | `GameConfigurationService` | 16 | 게임 설정 (Fitphd: 150+ params) |
| `IGameCardsService` | `GameCardsService` | 41 | 카드 표시, 에퀴티, 아웃츠 |
| `IGamePlayersService` | `GamePlayersService` | 54 | 플레이어 표시, KEYLOK 연동 |
| `IGameGfxService` | `GameGfxService` | 11 | GFX 모드 관리 |
| `IGameVideoService` | `GameVideoService` | 12 | 비디오 녹화 |
| `IGameVideoLiveService` | `GameVideoLiveService` | 19 | 라이브 비디오 스트림 |
| `IGameSlaveService` | `GameSlaveService` | 17 | Slave 통신 |
| `IHandEvaluationService` | `HandEvaluationService` | 7 | 핸드 강도 조회 |
| `ITagsService` | `TagsService` | 16 | 핸드 태깅, 통계 |
| `ITimersService` | `TimersService` | 10 | 타이머 관리 |

### 13.2 Root Services Layer

| Interface | Implementation | 역할 |
|-----------|---------------|------|
| `IVideoMixerService` | `VideoMixerService` | mmr.dll 브리지, 녹화 |
| `IUpdatePlayerService` | `UpdatePlayerService` | 플레이어 레이아웃 엔진 |
| `IActionTrackerService` | `ActionTrackerService` | 외부 프로세스 액션 추적 |
| `IEffectsService` | `EffectsService` | 시각 효과 |
| `IGraphicElementsService` | `GraphicElementsService` | 그래픽 요소 레지스트리 |
| `ITransmisionEncodingService` | `TransmisionEncodingService` | 출력 인코딩 |

### 13.3 Features Layer (Phase 3 - DDD/CQRS)

![Features 디렉토리 구조](../images/mockups/features-directory.png)

Login CQRS: `LoginCommand → LoginCommandValidator → LoginHandler(5 deps) → LoginResult`
License 서비스 상세: **섹션 9.1** Layer 3-4 참조.

### 13.4 DI 등록

`ServiceCollectionExtensions.AddCommonLayer(IServiceCollection, IConfiguration)`
→ IEncryptionService, IDownloadLinksService, IAppVersionsService 등록

---

## 14. 스레드 모델

### 14.1 전체 스레드 맵 (15-25개 동시)

| Module | Thread | Purpose |
|--------|--------|---------|
| mmr.mixer | thread_worker | 라이브 프레임 렌더링 |
| mmr.mixer | thread_worker_audio | 오디오 처리 |
| mmr.mixer | thread_worker_delayed | 딜레이 프레임 렌더링 |
| mmr.mixer | thread_worker_write | 녹화 파일 쓰기 |
| mmr.mixer | thread_worker_process_delay | 딜레이 버퍼 관리 |
| mmr.renderer | thread_worker (N개) | 출력 디바이스별 렌더링 |
| mmr.sink | _workerThread | MFSink STA 작업 |
| mmr.video_capture_device | thread_worker_get_frame (N개) | 입력 디바이스별 캡처 |
| vpt_server.render | delayed_render_thread | 딜레이 렌더 이벤트 |
| net_conn.server | TCP Accept | 클라이언트 수락 |
| net_conn.server_obj | 수신 스레드 (N개) | 클라이언트별 TCP 수신 |
| net_conn.client | UDP 타이머 | 서버 발견 |
| vpt_server.twitch | keepalive_timer | IRC PING/PONG |
| vpt_server.LiveApi | keepaliveTimer | HTTP keepalive |
| analytics | ProcessQueueLoop | 텔레메트리 업로드 |
| PerformanceMonitor | BackgroundWorker | CPU/GPU 모니터링 |
| LicenseBackgroundService | _timer | 라이선스 체크 |
| AnalyticsScreenshots | _screenshotTimer | 15분 스크린샷 |

### 14.2 동기화 메커니즘

| 메커니즘 | 사용처 |
|---------|--------|
| `BlockingCollection<T>` | mmr frame queues (Producer-Consumer) |
| `ConcurrentQueue<T>` | sync_frames, video capture frames |
| `AutoResetEvent` | are_delay, are_audio, init_done_event |
| `ManualResetEventSlim` | sink._workerReady |
| `CancellationTokenSource` | live/delayed/write frame tokens |
| `lock` (object) | live_lock_obj, delay_lock_obj, safety_lock |

---

## 15. UI 시스템

### 15.1 WinForms (43+ Forms)

| Form | 역할 |
|------|------|
| `main_form` | 메인 애플리케이션 (329 methods, 150+ fields) |
| `skin_edit` | 스킨 편집기 |
| `gfx_edit` | 그래픽 편집 |
| `pip_edit` / `di_pip_edit` | PIP 편집 |
| `ticker_edit` / `ticker_stats_edit` | 티커 편집 |
| `auto_stats_edit` | 자동 통계 편집 |
| `flag_editor` | 국기 편집 |
| `font_picker` | 폰트 선택 |
| `lang_edit` | 언어 편집 |
| `twitch_edit` | Twitch 설정 |
| `atem_form` | ATEM 스위처 설정 |
| `reader_config` / `reader_select` | RFID 리더 설정 |
| `reg_player` | 플레이어 등록 |
| `trial_form` | 평가판 알림 |
| `security_warning` | 보안 경고 |
| `DiagnosticsForm` | 진단 정보 |
| `LogWindow` | 로그 뷰어 |
| `cam_prev` / `cam_prop` | 카메라 프리뷰/속성 |
| `test_table` | 테스트 테이블 |
| `LoginForm` | 로그인 화면 |
| `AboutDialog` | 제품 정보 |
| `ForceVersionUpdateWindow` | 필수 업데이트 알림 |
| `SuggestVersionUpdateWindow` | 선택 업데이트 제안 |

### 15.2 main_form 탭 구조

| 탭 | 필드명 | 기능 |
|----|--------|------|
| Sources | `tab_sources` | 비디오 입력 소스 관리 |
| Outputs | `outputsTabPage` | 출력 디바이스 설정 |
| Graphics | `tab_graphics` | 그래픽 오버레이 설정 |
| System | `tab_system` | 시스템 설정, 라이선스 |
| Commentary | `tab_commentary` | 해설석 설정 |

### 15.3 main_form 주요 서비스 참조

`ILicenseService`, `ITagsService`, `IServiceProvider` (DI), `ConfigurationPresetService`, `AnalyticsScreenshots`, `PerformanceMonitor`, `StorageMonitor`

---

## 16. 빌드/배포 및 운영

### 16.1 빌드 환경

| 항목 | 값 |
|------|-----|
| **소스 경로** | `C:\pgfx\source\pokergfx2.0\vpt\vpt_server\` |
| **CI 경로** | `C:\CI_WS\Ws\274459\Source\` |
| **Framework** | .NET Framework 4.x |
| **패키징** | Costura.Fody (60개 DLL 내장) |
| **코드 보호** | ConfuserEx + Dotfuscator |
| **업데이터** | `GFXUpdater.exe` |
| **레지스트리** | `HKLM\Software\PokerGFX\Server` (Path, Environment) |

### 16.2 버전 관리

- `AppVersionValidationHandler`: 서버 최신 버전 조회 → 비교
- `VersioningResultStatus`: UpToDate, UpdateAvailable, UpdateRequired
- `ForceVersionUpdateWindow`: 필수 업데이트 차단 UI
- `SuggestVersionUpdateWindow`: 선택 업데이트 제안 UI
- 오프라인 폴백: `offline_app_versions.json`, `downloadLinks.json`

### 16.3 appsettings.json 주요 설정

| 섹션 | 값 |
|------|-----|
| Environment | `production` |
| PgfxApi BaseUrl | `https://api.pokergfx.io` |
| PgfxApi Path | `/api/v1/` |
| WCF Endpoint | `http://videopokertable.net/wcf.svc` |
| License Check Interval | `00:05:00` (5분) |
| Config Extension | `.pgfxconfig` |
| Download URL | `https://videopokertable.net/Download.aspx` |
| Login URL | `https://www.pokergfx.io` |

### 16.4 텔레메트리 (analytics.dll)

Store-and-Forward: `Track() → SQLite Queue → Background Loop → POST /api/v1/analytics/batch`

| 메서드 | Type | 용도 |
|--------|------|------|
| `TrackFeature(name)` | `"feature"` | 기능 사용 추적 |
| `TrackClick(button)` | `"click"` | 버튼 클릭 |
| `TrackSession(name, isStart)` | `"session"` | Session Start/End |
| `TrackDuration(name, ms)` | `"duration"` | 작업 소요 시간 |

SQLite: WAL 모드, `AnalyticsQueue(Id, Payload)` 테이블. 스크린샷: 15분 간격 AWS S3 업로드.

### 16.5 시스템 모니터링

- **PerformanceMonitor**: NVIDIA GPU (`NvAPIWrapper`) + CPU (`PerformanceCounter`), BackgroundWorker 비동기
- **StorageMonitor**: 디스크 공간 주기적 체크, 최소 공간 미만 시 경고

### 16.6 로깅

| Topic | 설명 |
|-------|------|
| General | 일반 로그 |
| Startup | 시작/종료 |
| MultiGFX | 다중 GFX 인스턴스, 라이선스 검증 |
| AutoCamera | 자동 카메라 전환 |
| Devices | 디바이스 관리 |
| RFID | RFID 태그 이벤트 |
| Updater | 자동 업데이트 |
| GameState | 게임 상태 변경 |

출력 채널: FileLogger (파일), LogWindow (UI), `remote=true` (원격), `popup=true` (팝업)

**Bugsnag**: API Key `0fb8047d1ed879251865331a8cc44572`, 크래시 리포트 (라이선스/세션/신원/버전 첨부)

---

## 부록 A: 소스 디렉토리 구조

![소스 디렉토리 구조](../images/mockups/source-directory.png)

## 부록 B: 내장 DLL 목록 (60개, Costura.Fody)

### 핵심 비즈니스 로직

| DLL | 크기 | 설명 |
|-----|------|------|
| PokerGFX.Common.dll | 566KB | 공통 라이브러리 |
| hand_eval.dll | 330KB | 포커 핸드 평가 |
| net_conn.dll | 118KB | 네트워크 통신 |
| RFIDv2.dll | 58KB | RFID 카드 리더 |
| mmr.dll | 149KB | 미디어 렌더러 |
| analytics.dll | 23KB | 텔레메트리 |
| boarssl.dll | 207KB | TLS 구현 |
| GFXUpdater.exe | 47KB | 자동 업데이트 |

### 그래픽 파이프라인

| DLL | 크기 | 설명 |
|-----|------|------|
| SkiaSharp.dll | 747KB | 2D 그래픽 |
| libSkiaSharp.dll | 11.4MB | SkiaSharp Native |
| SharpDX.dll | 568KB | DirectX 래퍼 |
| SharpDX.Direct2D1.dll | 426KB | Direct2D |
| SharpDX.Direct3D11.dll | 265KB | Direct3D 11 |
| SharpDX.DXGI.dll | 116KB | DXGI |

### 하드웨어 인터페이스

| DLL | 크기 | 설명 |
|-----|------|------|
| Interop.BMDSwitcherAPI.dll | 92KB | Blackmagic ATEM |
| Interop.MFORMATSLib.dll | 87KB | Medialooks MFormats |
| NvAPIWrapper.dll | 468KB | NVIDIA API |
| HidLibrary.dll | 29KB | USB HID |
| kl2dll64.dll | 9.7MB | KEYLOK 동글 |

### 웹/데이터

| DLL | 크기 | 설명 |
|-----|------|------|
| EO.WebEngine.dll | 73.7MB | Chromium 엔진 |
| EntityFramework.dll | 4.99MB | EF 6.0 |
| System.Data.SQLite.dll | 450KB | SQLite ADO.NET |
| Newtonsoft.Json.dll | 712KB | JSON |
| AWSSDK.Core/S3.dll | ~2MB | AWS SDK |
| Bugsnag.dll | 71KB | 에러 리포팅 |
| FluentValidation.dll | - | 입력 검증 |

---

*PokerGFX RFID-VPT Server v3.2.985.0 Product Requirements Document*
