# PokerGFX Server Architecture Overview

## 메타데이터 분석 결과

- **총 타입**: 2,602개 (vpt_server.exe)
- **총 메서드**: 14,460개
- **총 필드**: 6,793개
- **외부 참조 타입**: 866개 (TypeRef)
- **외부 메서드 참조**: 3,208개 (MemberRef)
- **ManifestResource**: 136개 (Costura 80개 추출 완료)

---

## 핵심 모듈 구조

### 1. main_form (329 methods, 398 fields) - God Class
vpt_server의 핵심. WinForms 메인 윈도우로 대부분의 로직이 집중됨.

### 2. GameType (271 methods, 35 fields) - 게임 유형 관리
```
vpt_server.GameTypes/
├── AnteType (enum: 8 values)
├── BetStructure (enum: 4 values)
├── GameType (271 methods - 핵심)
├── GameTypeConstants
├── GameTypeData (75 fields!)
└── PlayerStrength
```

### 3. GameTypes.Interfaces - 게임 서비스 인터페이스
```
IGameCardsService      (37 methods) - 카드 관리
IGamePlayersService    (48 methods) - 플레이어 관리
IGameSlaveService      (12 methods) - Slave 장치 관리
IGameVideoLiveService  (11 methods) - 라이브 비디오
IGameVideoService      (8 methods)  - 비디오 녹화
IGameGfxService        (6 methods)  - 그래픽 효과
IHandEvaluationService (3 methods)  - 핸드 평가
ITagsService           (10 methods) - RFID 태깅
ITimersService         (6 methods)  - 타이머 관리
```

### 4. GameTypes.Services - 서비스 구현
```
GameCardsService        (41 methods) → IGameCardsService
GamePlayersService      (54 methods) → IGamePlayersService
GameSlaveService        (17 methods) → IGameSlaveService
GameVideoLiveService    (19 methods) → IGameVideoLiveService
GameVideoService        (12 methods) → IGameVideoService
GameGfxService          (11 methods) → IGameGfxService
HandEvaluationService   (7 methods)  → IHandEvaluationService
TagsService             (16 methods) → ITagsService
TimersService           (10 methods) → ITimersService
GameConfigurationService(16 methods) → IGameConfigurationService
```

### 5. ConfigurationPreset (192 methods, 95 fields!)
게임 설정 프리셋. 모든 게임 파라미터를 포함하는 거대 DTO.

### 6. WCF 통신 레이어 (vpt_server.wcf)
```
Iwcf (interface, 9 methods) - Server↔Remote RPC 계약
IwcfChannel (interface)     - 채널 인터페이스
IwcfClient (17 methods)     - WCF 클라이언트 프록시
card_action (enum: 4 values)- 카드 액션 타입
client_ping (49 methods)    - Remote→Server 상태
server_ping (23 methods)    - Server→Remote 상태
skin_info (17 methods)      - 스킨 메타데이터
sw_file (23 methods)        - 소프트웨어 파일 전송
```

### 7. 라이선싱 시스템
```
vpt_server.Features.Common.Licensing/
├── ILicenseService (10 methods)
├── LicenseService (25 methods)
├── LicenseBackgroundService (10 methods, 11 fields)
├── LicensingExtensions
├── Configuration/LicenseBackgroundServiceSettings
├── Converters/ (LicenseResponseConverter, LicenseTypeConverter)
├── Enums/LicenseType (4 values: Basic, Pro, Enterprise, ?)
├── Models/ (7 types)
│   ├── DeviceData (5 fields)
│   ├── LicenseData
│   ├── LicenseResponse
│   ├── RemoteLicense
│   ├── RemoteLicenseCheckedEventArgs
│   ├── RemoteLicenseResponse
│   └── UserLicense (4 fields)
└── Testing/ (12 types - 테스트용 라이선스 목업)
```

### 8. 인증 시스템
```
vpt_server.Features.Common.Authentication/
├── IAuthenticationService (2 methods)
├── AuthenticationService (7 methods)
└── Models/
    ├── RemoteLoginRequest (3 fields)
    └── RemoteLoginResponse (8 fields)

vpt_server.Features.Login/
├── ILoginHandler
├── LoginHandler (8 methods, 6 fields)
├── Configuration/LoginConfiguration
├── Models/ (LoginCommand, LoginResult)
└── Validators/LoginCommandValidator
```

### 9. 하드웨어 인터페이스
```
Dongle (KEYLOK 동글 보호):
├── DongleService (24 methods)
├── IDongleService (14 methods)
├── DongleType (enum: 5 values)
└── KEYLOK/
    ├── KLClientCodes (18 fields - 클라이언트 코드)
    └── KeylokDongle (43 methods, 43 fields!)

RFID (카드 리더):
├── RFIDv2.dll (57KB) - 독립 DLL
├── reader_config (30 fields)
├── reader_select (9 fields)
└── firmware resource (80KB)
```

### 10. 그래픽/비디오 파이프라인
```
gfx (98 methods, 45 fields)        - 그래픽 엔진 코어
gfx_edit (65 methods, 90 fields)   - 그래픽 편집기
render (23 methods, 13 fields)     - 렌더러
video (70 methods, 21 fields)      - 비디오 녹화/재생
video_mixer (7 methods, 10 fields) - 비디오 믹싱
playback (122 methods, 118 fields) - 재생 시스템
skin_edit (75 methods, 90 fields)  - 스킨 에디터
pipcap (20 methods, 24 fields)     - PIP 캡처
```

### 11. WinForms UI (43개 form)
```
main_form, atem_form, cam_prev, cam_prop, di_pip_edit,
edit_event, flag_editor, font_picker, get_settings_pwd,
gfx_edit, lang_edit, msgbox, pip_edit, playback,
prev_pwd, preview, reader_config, reader_select,
reg_player, security_warning, settings_pwd, show_file,
skin_edit, slave_skin_prog, splash, split_settings,
test_table, ticker_edit, ticker_stats_edit, trial_form,
twitch_edit, vid_form, video_repair, www,
auto_stats_edit, AboutDialog, LoginForm, PGFXMainMenu,
LoggingSettingsForm, PopupMessage, LogWindow, FirmwareProgress,
ColorAdjustment
```

---

## 외부 서비스 연동

| 서비스 | URL/엔드포인트 | 용도 |
|--------|---------------|------|
| WCF | `http://videopokertable.net/wcf.svc` | Server↔Remote 통신 |
| Twitch OAuth | `https://id.twitch.tv/oauth2/authorize` | 트위치 연동 |
| Twitch API | `https://api.twitch.tv/kraken/channels/` | 채널 정보 |
| Twitch OAuth (app) | `http://videopokertable.net/twitch_oauth.aspx` | OAuth callback |
| Bugsnag | (내장) | 에러 리포팅 |
| AWS S3 | (AWSSDK.S3) | 클라우드 스토리지 |
| Analytics | `analytics.db` (SQLite) | 사용 분석 |

---

## 게임 타입 (421개 포커 관련 문자열)

### 지원 게임
- Texas Hold'Em (NLH)
- Short Deck Hold'Em
- 5 Card Draw
- 5/6 Card Omaha (Hi/Lo)
- 7 Card Stud (Hi/Lo)
- Bomb Pot

### 베팅 구조
- No Limit
- Pot Limit
- Fixed Limit
- Ante Types (8종): 3B Ante (3B 1st), 3B Ante (Ante 1st) 등

---

## 보안 구조

1. **KEYLOK 동글**: 하드웨어 라이선스 보호 (43 methods)
2. **RSA 암호화**: `public_key.xml` 리소스
3. **라이선스 서버**: `videopokertable.net/wcf.svc` 통신
4. **오프라인 세션**: 서버 연결 없을 때 제한 모드
5. **평가판**: `trial_form`, 워터마크 표시
6. **라이선스 등급**: Basic, Professional, Enterprise
7. **스킨 암호화**: "Do not encrypt the default PokerGFX skin!"

---

## 임베디드 DLL 60개 분류

### 핵심 비즈니스 로직 (자체 개발)
| DLL | 크기 | 설명 |
|-----|------|------|
| PokerGFX.Common.dll | 566KB | 공통 라이브러리 (42 types) |
| hand_eval.dll | 330KB | 포커 핸드 평가 엔진 |
| net_conn.dll | 118KB | WCF 네트워크 통신 |
| RFIDv2.dll | 58KB | RFID 카드 리더 |
| mmr.dll | 149KB | 미디어 렌더러 |
| analytics.dll | 23KB | 사용 분석 |
| boarssl.dll | 207KB | 자체 SSL 구현 |
| ListViewEx.dll | 25KB | 확장 ListView UI |
| GFXUpdater.exe | 47KB | 자동 업데이트 |

### 그래픽 파이프라인
| DLL | 크기 | 설명 |
|-----|------|------|
| SkiaSharp.dll | 747KB | 2D 그래픽 |
| libSkiaSharp.dll | 11.4MB (x64) / 1.6MB (x86) | SkiaSharp native |
| SharpDX.dll | 568KB | DirectX 래퍼 |
| SharpDX.Direct2D1.dll | 426KB | Direct2D |
| SharpDX.Direct3D11.dll | 265KB | Direct3D 11 |
| SharpDX.DXGI.dll | 116KB | DXGI |

### 하드웨어 인터페이스
| DLL | 크기 | 설명 |
|-----|------|------|
| Interop.BMDSwitcherAPI.dll | 92KB | Blackmagic ATEM |
| Interop.MFORMATSLib.dll | 87KB | Medialooks MFormats |
| Interop.MLPROXYLib.dll | 5KB | Medialooks Proxy |
| NvAPIWrapper.dll | 468KB | NVIDIA API |
| HidLibrary.dll | 29KB | USB HID |
| kl2dll64.dll | 9.7MB | KEYLOK 동글 (x64) |

### 웹/크롬
| DLL | 크기 | 설명 |
|-----|------|------|
| EO.WebEngine.dll | 73.7MB | Chromium 엔진 |
| EO.WebBrowser.dll | 232KB | 웹브라우저 컨트롤 |
| EO.Base.dll | 3.55MB | EO 기본 라이브러리 |

### 데이터/인프라
| DLL | 크기 | 설명 |
|-----|------|------|
| EntityFramework.dll | 4.99MB | EF 6.0 |
| EntityFramework.SqlServer.dll | 592KB | EF SQL Server |
| System.Data.SQLite.dll | 450KB | SQLite ADO.NET |
| SQLite.Interop.dll | 2.0MB (x64) | SQLite native |
| Newtonsoft.Json.dll | 712KB | JSON 처리 |
| AWSSDK.Core.dll | 963KB | AWS SDK |
| AWSSDK.S3.dll | 971KB | S3 클라이언트 |
| Bugsnag.dll | 71KB | 에러 리포팅 |

---

## net_conn.dll 프로토콜 상세 (113 Commands)

Server↔ActionTracker 간 커스텀 TCP/UDP 통신 프로토콜.
**중요**: WCF가 아닌 원시 TCP 소켓 + Newtonsoft.Json 직렬화.

### 프로토콜 아키텍처
- **Discovery**: UDP 브로드캐스트로 서버 검색
- **Communication**: TCP 영속 연결, JSON 메시지, 라인 구분자
- **Encryption**: AES (RijndaelManaged) + PasswordDeriveBytes
- **Routing**: `RemoteRegistry` 싱글톤이 리플렉션으로 Command→Type 매핑

### 연결 흐름
```
1. Client UDP broadcast → Server responds (IP/identity)
2. Client TCP connect → Server accepts
3. ConnectRequest → ConnectResponse (License)
4. AuthRequest (Password, Version) → AuthResponse
5. 양방향 JSON 메시지 (TCP line delimiter)
6. KeepAlive/HeartBeat (NetworkQuality: Good/Fair/Poor)
```

### 암호화
- AES (RijndaelManaged) + PasswordDeriveBytes
- DEFAULT_PWD: `45389rgjkonlgfds90439r043rtjfewp9042390j4f`
- SALT: `dsafgfdagtds4389tytgh`
- IV: `4390fjrfvfji9043`
- `enc.init(pwd)` 메서드로 배포별 키 커스터마이징 가능
- 압축 지원: `,COMPRESS`, `,COMPRESSED` suffix

### 핵심 타입

| 타입 | 역할 |
|------|------|
| `net_conn.server` (static) | 서버: UDP 브로드캐스트 응답, TCP accept, 클라이언트 관리 |
| `net_conn.server_obj` | 클라이언트별 서버 연결: TCP 스트림, keepalive, JSON |
| `net_conn.client<T>` (generic) | 클라이언트: UDP 검색, TCP 연결 풀 |
| `net_conn.client_obj` | 단일 클라이언트 연결: TCP, keepalive, send/receive |
| `net_conn.RemoteRegistry` (singleton) | 리플렉션 기반 Command→Type 매핑 |
| `net_conn.enc` (static) | AES 암호화/복호화 (하드코딩 키) |

### IClientNetworkListener 콜백 (16개)
ActionTracker가 서버로부터 수신하는 이벤트:
```
NetworkQualityChanged, OnConnected, OnDisconnected, OnAuthReceived,
OnReaderStatusReceived, OnHeartBeatReceived, OnDelayedGameInfoReceived,
OnGameInfoReceived, OnMediaListReceived, OnCountryListReceived,
OnPlayerPictureReceived, OnGameVariantListReceived, OnPlayerInfoReceived,
OnDelayedPlayerInfoReceived, OnVideoSourcesReceived, OnSourceModeReceived
```

### 명령어 분류 (113개)

| 카테고리 | 명령어 | 설명 |
|----------|--------|------|
| **연결** (9) | AUTH, CONNECT, DISCONNECT, HEARTBEAT, KEEPALIVE, MIN_VER, STATUS, STATUS_SLAVE, STATUS_VTO | 인증/연결/상태 |
| **게임** (10) | GAME_INFO, GAME_STATE, GAME_TYPE, GAME_TITLE, GAME_VARIANT, GAME_VARIANT_LIST, GAME_CLEAR, GAME_LOG, GAMESAVE_BACK, WRITE_GAME_INFO, NIT_GAME_AMT | 게임 제어 |
| **플레이어** (21) | PLAYER_INFO, PLAYER_INFO_VTO, PLAYER_ADD/DEL/CARDS/FOLD/BET/BLIND/DEAD_BET/WIN/STACK/SWAP/SIT_OUT/COUNTRY/PIC/LONGNAME/NIT/DISCARD, PAYOUT, TRANSFER_CHIPS, RESET_VPIP | 플레이어 액션 |
| **카드/보드** (6) | BOARD_CARD, EDIT_BOARD, REMOVE_FROM_BOARD, FORCE_CARD_SCAN, CARD_VERIFY_MODE, DRAW_DONE | 보드/카드 관리 |
| **핸드** (8) | START_HAND, RESET_HAND, HAND_HISTORY, HAND_LOG, MISS_DEAL, CHOP, UNDO, RUN_IT_TIMES/INC/CLEAR_BOARD | 핸드 관리 |
| **디스플레이** (13) | SHOW_PANEL/DELAYED_PANEL/STRIP/PIP, GFX_ENABLE, ENH_MODE, FIELD_VIS/DELAYED_FIELD_VIS/FIELD_VAL, FORCE_HEADS_UP/DELAYED, ACTION_CLOCK | 그래픽 표시 |
| **미디어** (9) | MEDIA_LIST/PLAY/LOOP, GET/SET_VID_SOURCES, VID_SOURCES, VIDEO_PORT/RESET, SET/GET_SOURCE_MODE, CAM | 비디오/미디어 |
| **스킨/로고** (8) | SKIN_REQ/SKIN, BOARD_LOGO_REQ/BOARD_LOGO, PANEL_LOGO_REQ/PANEL_LOGO, STRIP_LOGO_REQ/STRIP_LOGO | 스킨 전송 |
| **데이터** (10) | AT_DL, COMM_DL, READER_STATUS, REGISTER_DECK, TAG/TAG_LIST, TICKER/TICKER_LOOP, DELAYED_GAME_INFO/DELAYED_PLAYER_INFO, COUNTRY_LIST | 데이터 전송 |
| **기타** (7) | PIPREQUEST, SLAVE_STREAMING, ID_UPD, IDTX, CAP, REGISTER_DECK | 기타 |

### 핵심 DTO: GAME_INFO (55+ 필드)
GameInfoResponse는 전체 게임 상태를 담는 최대 DTO:
Ante, Small, Big, Dealers, Blinds, Hands, Variants, HandCount, Panel,
StatsAvailable, FieldVisible, FieldRemain, FieldTotal 등

### 스킨 청크 전송
`SKIN_REQ`/`SKIN` 명령어 쌍으로 대용량 .skn 파일 청크 전송:
Pos(오프셋), ChunkSize(크기), Crc(체크섬), Length(전체), Start(시작)

### VTO (Video Table Observer)
`STATUS_VTO`, `PLAYER_INFO_VTO` → 읽기 전용 관전 모드
Title, Blinds, Payouts, Stack, Vpip, Pfr, Agr, Wtsd, CumWin, Pos, Rank

---

## hand_eval.dll 심층 분석 (329KB)

### 난독화 수준: **없음** (이전 분석 수정)
- 명확한 클래스/메서드 이름 (evaluate_hand, calc_odds 등)
- PDB 심볼 완전 존재 (dnSpy로 소스 수준 디버깅 가능)
- 61 TypeDef, 독립 어셈블리 (mscorlib, System, System.Core만 참조)
- P/Invoke: Kernel32.dll → QueryPerformanceCounter/Frequency (랜덤 타이밍용)

### 핵심 클래스 구조

| 클래스 | 역할 | 규모 |
|--------|------|------|
| `hand_eval.core` (static) | 진입점: evaluate_hand(), calc_odds(), outs_str() | - |
| `hand_eval.Hand` | **핵심 엔진**: bitmask 카드 표현, 평가, 파싱, 서술 | 70 필드, 87 메서드 |
| `hand_eval.PocketHands` | 169개 canonical preflop 핸드, Sklansky 그룹핑 | 38 필드, 106 메서드 |
| `hand_eval.OmahaEvaluator` | Omaha 4-card (Hi/Lo) | - |
| `hand_eval.Omaha5Evaluator` | Omaha 5-card | - |
| `hand_eval.Omaha6Evaluator` | Omaha 6-card (IDisposable, MMF 사용) | - |
| `hand_eval.holdem_sixplus` | Short-deck 6+ (trips_beats_straight 파라미터) | - |
| `hand_eval.draw` | 5-Card Draw, 2-7 Draw, Badugi | - |
| `hand_eval.stud` | 7-Card Stud (Hi/Lo/HiLo/scoop) | - |
| `PokerEvaluators.IPokerEvaluator` | 평가기 인터페이스: Evaluate(Hi, Lo, Hand, Open) | - |
| `PokerEvaluators.Badugi` | Badugi 평가 (flush/pair 제거) | - |
| `PokerEvaluators.Razz` | Razz A-5 lowball | - |
| `PokerEvaluators.SevenCards` | 표준 7-card 평가 | - |

### 지원 게임 타입 (17개)

| ID | 게임 | 평가기 |
|----|------|--------|
| HOLDEM | Texas Hold'em | Hand |
| 6THOLDEM | 6-max Hold'em | Hand |
| 6PHOLDEM | Short-deck 6+ | holdem_sixplus |
| OMAHA | Omaha 4-card | OmahaEvaluator |
| OMAHA5 | Omaha 5-card | Omaha5Evaluator |
| OMAHA6 | Omaha 6-card | Omaha6Evaluator (MMF) |
| OMAHAHL | Omaha Hi-Lo | OmahaEvaluator |
| OMAHA5HL | Omaha-5 Hi-Lo | Omaha5Evaluator |
| OMAHA6HL | Omaha-6 Hi-Lo | Omaha6Evaluator |
| 7STUD | 7-Card Stud | stud |
| 7STUDHL | 7-Card Stud Hi-Lo | stud |
| RAZZ | Razz | Razz |
| 5DRAW | 5-Card Draw | draw |
| 27DRAW | 2-7 Lowball Draw | draw |
| 27TRIPLE | 2-7 Triple Draw | draw |
| A5TRIPLE | A-5 Triple Draw | draw |
| BADUGI | Badugi | Badugi |

### HandTypes enum (9값)
HighCard(0), Pair(1), TwoPair(2), Trips(3), Straight(4), Flush(5), FullHouse(6), FourOfAKind(7), StraightFlush(8)

### 핵심 API

**평가**: `Evaluate(cards, numberOfCards, ignore_wheel)` → handValue (uint)
**파싱**: `ParseHand(hand)` → ulong mask, `ValidateHand(hand)` → bool
**서술**: `DescriptionFromHandValue(hv)` → string, `MaskToString(mask)` → string
**확률**: `HandOdds(pockets, board, dead, wins, ties, losses, total)` → void
**아웃**: `Outs(player, board, opponents, dead, include_splits)` → int
**랜덤**: `RandomHands(shared, dead, ncards, trials)` → IEnumerable<ulong>

### 룩업 테이블 아키텍처 (하이브리드)

| 방식 | 내용 |
|------|------|
| **인메모리 정적 배열** | 538개 FieldRVA, 29가지 크기 (32~32768 bytes) |
| | bits, nBitsTable, straightTable, topFiveCardsTable, CardMasksTable, Pocket169Table 등 |
| **Memory-Mapped File** | `TopTables` 클래스: `topFiveCards.bin`, `topCard.bin` (스레드 안전 초기화) |
| **Omaha-6 전용** | `omaha6.vpt` 파일: BinarySearch로 사전 계산된 핸드 값 검색 |

### 카드 표기 시스템
- **값**: 2-9, t(10), j(Jack), q(Queen), k(King), a(Ace)
- **수트**: c(Clubs), d(Diamonds), h(Hearts), s(Spades)
- **핸드**: `AKs`(suited), `AKo`(offsuit) → PocketHand169Enum (170값)
- **그룹**: GroupTypeEnum (Group1~Group8) → Sklansky 핸드 그룹핑

---

## RFIDv2.dll 심층 분석 (57KB)

### 역할: 듀얼 트랜스포트 RFID 카드 리더 인터페이스
- **39 TypeDef**, **206 필드**, **351 메서드**
- 두 가지 물리적 리더 하드웨어를 통합 지원

### 듀얼 트랜스포트 아키텍처

| 모듈 | 트랜스포트 | 하드웨어 |
|------|-----------|---------|
| `v2_module` (~40 필드, ~60 메서드) | TCP/WiFi + BearSSL TLS | v2 세대 리더 |
| `skye_module` (~20 필드, ~30 메서드) | USB HID (HidLibrary) | SkyeTek 브랜드 |
| `reader_module` (Facade) | 통합 API | 양쪽 래핑 |

### Enum
| Enum | 값 |
|------|-----|
| `module_type` | skyetek, v2 |
| `connection_type` | usb, wifi |
| `reader_state` | disconnected, connected, negotiating, ok |
| `wlan_state` | off, on, connected_reset, ip_acquired, not_installed |

### 이벤트 Delegate
`state_changed_delegate`, `firmware_update_delegate`, `calibrate_delegate`,
`tag_event_delegate`, `transport_event_delegate`, `rx_delegate`

### 텍스트 명령 프로토콜 (22개)
형식: `COMMAND [ARGS]\n` → `OK COMMAND [DATA]\n`

| 명령 | 요청 | 응답 | 기능 |
|------|------|------|------|
| **TI** | `TI <poll>` | `OK TI <tags>` | Tag Inventory (스캔) |
| **TR** | `TR <addr>` | `OK TR <data>` | Tag Read (메모리 블록) |
| **TW** | `TW <addr> <data>` | `OK TW` | Tag Write |
| **AU** | `AU <token>` | `OK AU` | 리더 인증 |
| **FW** | `FW <data>` | `OK FW` | Firmware 업데이트 |
| **GM/GN/GP** | `GM/GN/GP` | 모듈 정보/이름/비밀번호 | Get 명령 |
| **SM/SN/SP** | `SM/SN/SP <값>` | 설정 확인 | Set 명령 |
| **GH/GF/GV** | - | HW 리비전/FW 버전 | 버전 조회 |
| **GO/SO** | - | WLAN 상태/설정 | WiFi 관리 |
| **GI/SI** | - | IP 설정 | 네트워크 설정 |
| **GS/SS/GW/SW** | - | SSID/비밀번호 | WiFi 자격증명 |

### 카드 인코딩
- Mifare Ultralight, Mifare 1k 지원
- UID: Hex 문자열, `" | "` 구분
- 인증 토큰: `"xxxxxxxxxxxxCCC"` (12자 + 3자 체크)
- Hex charset: `"0123456789ABCDEF"`

### TLS 보안 (BearSSL)
- Server identity: `"vpt-server"`, Client identity: `"vpt-reader"`
- `SSLClient`, `SSLEngine`, `ECPublicKey` 사용
- `SSLSessionParameters` 캐싱 (재사용)

### WLAN 상태 머신
`00`=OFF, `01`=ON(미연결, 5GHz 비호환 경고), `02`=IP 획득 중, `03`=연결됨, `04`=하드웨어 없음

---

## mmr.dll 심층 분석 (148KB) - Media Mixer Renderer

### 역할: GPU 가속 비디오 믹싱/렌더링 엔진
- **96 TypeDef**, **647 필드**, **785 메서드**, **11 AssemblyRef**
- Medialooks SDK 라이선스: `PokerGFX LLC`, CompanyID `13751`

### 아키텍처
```
                  +-----------+
                  |   mixer   |  (99 methods, 85 fields) - 중앙 오케스트레이터
                  +-----+-----+
                        |
       +----------------+----------------+
       |                |                |
 +-----+-----+   +-----+-----+   +-----+-----+
 |   canvas   |   |  renderer  |   |   client   |
 | (D2D/D3D)  |   | (NDI/BMD)  |   | (preview)  |
 +-----+-----+   +-----------+   +-----------+
       |
 +-----+-----+-----+-----+
 |     |     |     |     |
image  text  pip  border asset
elem   elem  elem  elem
```

### 핵심 타입

| 타입 | 필드 | 메서드 | 역할 |
|------|------|--------|------|
| `mixer` | 85 | 99 | 중앙 비디오 믹싱 엔진 |
| `canvas` | 25 | 45 | Direct2D 렌더링 서피스 |
| `renderer` | ~15 | ~20 | NDI/BMD 출력 관리 |
| `video_capture_device` | 29 | 36 | 입력 장치 추상화 |
| `client` | 22 | 31 | 프리뷰 윈도우 |
| `file` | 17 | 26 | 미디어 파일 재생 |
| `duplex_link` | 30 | 33 | SRT 양방향 스트리밍 |
| `image_element` | 41 | 37 | PNG 오버레이 + 애니메이션 |
| `text_element` | 52 | 39 | 텍스트 + ticker/reveal 효과 |
| `pip_element` | 12 | 24 | Picture-in-Picture |

### GPU 벤더별 코덱 설정

| GPU | 녹화 코덱 | 스트림 코덱 | 디코더 |
|-----|----------|-----------|--------|
| NVIDIA | `n264` (NVENC) CQP qp=20 | `n264` CBR 5M low_latency | `decoder.nvidia='true'` |
| AMD | `h264_amf` 50M | `h264_amf` 10M | default |
| Intel QSV | `q264hw` CBR 50M | `q264hw` CBR 5M | `decoder.quicksync=1` |
| Software | `libopenh264` 50M | `libopenh264` 5M | default |

컨테이너: MP4 (녹화), MPEGTS (스트리밍). 오디오: AAC 192k

### 스트리밍 프로토콜
- **SRT**: `srt://?mode=listener&passphrase=` / `srt://?mode=caller` (duplex_link)
- **NDI**: `[NDI]_` prefix 네이밍, `NDI_WAIT_PERIOD_MS` 타임아웃
- **BMD**: Blackmagic Design `decklink`/`blackmagic` 장치

### 미디어 처리 기능
- **Delay/Timeshift**: MDelay 클래스, 설정 가능한 버퍼, 비디오 코덱
- **녹화 모드**: live, live_no_overlay, delayed, delayed_no_overlay
- **재생 속도**: normal, x2, x4, reverse_x2, reverse_x4
- **이미지 효과**: 색상 매트릭스, HSB/대비, 틴트, 크롭, 줌, 회전, 크로마 키
- **텍스트 효과**: reveal 애니메이션, ticker 스크롤
- **커스텀 폰트**: DirectWrite ResourceFontLoader (임베디드 리소스, MD5 해시 중복 제거)

### 워커 스레드 (10+)
`thread_live`, `thread_delayed`, `thread_render`, `thread_write`,
`thread_audio`, `thread_rx`, `thread_tx`, `thread_process_delay`,
`thread_get_frame`, `thread_worker` (각각 CancellationToken + ManualResetEventSlim)

### 입력 장치 타입
`video_capture_device_type`: unknown, dshow, NDI, BMD, network

---

## analytics.dll 심층 분석 (23KB) - 텔레메트리

### 역할: 기능 추적, 세션 분석, 스크린샷 수집
- **13 TypeDef**, **70 필드**, **82 메서드**
- Store-and-forward 패턴: SQLite 로컬 큐 → HTTPS 배치 전송

### 아키텍처
```
AnalyticsService → SQLiteAnalyticsStore → analytics.db (로컬 큐)
      │
      ├──→ HTTPS POST → https://api.pokergfx.io/api/v1/analytics/batch
      │
      └──→ AnalyticsScreenshots → AWS S3 (captures.pokergfx.io)
```

### 추적 메서드

| 메서드 | 이벤트 | 수집 데이터 |
|--------|--------|-----------|
| `TrackFeature(name)` | `"feature"` | 기능명 |
| `TrackClick(button)` | `"click"` | 버튼/UI 요소명 |
| `TrackSession(name, isStart)` | `"session"` | Session_Start/End |
| `TrackDuration(name, ms)` | `"duration"` | 시간 메트릭 |
| `CaptureScreenshot()` | `"screenshot"` | JPEG + S3 링크 |

### SQLite DB 스키마
```sql
PRAGMA journal_mode = WAL;
PRAGMA synchronous = FULL;
CREATE TABLE IF NOT EXISTS AnalyticsQueue (
  Id INTEGER PRIMARY KEY AUTOINCREMENT,
  Payload TEXT NOT NULL
);
```

### AWS 자격증명 (하드코딩 - 보안 취약점!)

| 항목 | 값 |
|------|-----|
| Access Key | `AKIA***REDACTED***OH5F` |
| Secret Key | `YJPE***REDACTED***zq4u` |
| Region | `USEast1` |
| Bucket | `captures.pokergfx.io` |
| Key Prefix | `captures/` |

**보안 취약점**: DLL 추출만으로 S3 버킷 접근 가능 (키 마스킹 처리됨)

### 스크린샷 흐름
1. `CaptureScreenshot()` → JPEG 캡처
2. `EncryptFile()` → `.encrypted` 파일 생성
3. `UploadToS3()` → `captures.pokergfx.io/{prefix}{timestamp}/{filename}`
4. `SaveScreenshotToDB()` → S3 링크 기록

### 제품 식별자: `"RFID-VPT"` (RFID Video Poker Table)

---

## boarssl.dll 분석 (207KB) - BearSSL TLS 구현

### 역할: 자체 TLS/SSL 라이브러리 (BearSSL 포트)
- C#으로 작성된 BearSSL 포팅
- TLS 1.0/1.1/1.2 지원

### 핵심 구현
| 모듈 | 설명 |
|------|------|
| ChaCha20 | ChaCha20 스트림 암호 |
| CBCEncrypt/Decrypt | AES-CBC |
| CTRRun | AES-CTR |
| BigInt | 큰 정수 연산 |
| ECPublicKey | ECDSA 공개키 |
| AsnElt/AsnIO/AsnOID | ASN.1 파서 |
| AlgorithmIdentifier | X.509 알고리즘 |

### TLS 프로토콜 상수
- `CLIENT_HELLO`, `CLIENT_KEY_EXCHANGE` - TLS 핸드셰이크
- `CHANGE_CIPHER_SPEC` - 암호 전환
- `CERTIFICATE_REQUEST`, `CERTIFICATE_VERIFY` - 인증서 검증
- `CLOSE_NOTIFY` - 연결 종료

### 인증서 필드
- `COMMON_NAME`, `COUNTRY` - X.509 Subject

---

## PokerGFX.Common.dll 심층 분석 (v3.2.985.0)

### 어셈블리 정보
- **73 TypeDef** (52개 유의미 타입), **453 메서드**, **242 필드**, **116 프로퍼티**
- **7개 네임스페이스** (EF6/WCF 참조 없음 - 이들은 메인 서버 EXE에 존재)
- DI: `Microsoft.Extensions.DependencyInjection` 9.0 (레거시 .NET 4.x에 백포트)

### 7-Application 생태계 (ApplicationType enum)

| 앱 | 내부 키 | 설명 |
|----|---------|------|
| GfxServer | `pgfx_server` | 메인 그래픽 서버 |
| ActionTracker | `pgfx_action_tracker` | 딜러 터치스크린 |
| HandEvaluation | `hand_eval_wcf` | 핸드 평가 WCF 서비스 |
| ActionClock | `pgfx_action_clock` | 액션 타이머 |
| StreamDeck | `pgfx_streamdeck` | Elgato Stream Deck 통합 |
| Pipcap | `pgfx_pipcap` | PIP 캡처 |
| CommentaryBooth | `pgfx_commentary_booth` | 해설 부스 |

**핵심**: `hand_eval_wcf` 키로 hand_eval이 별도 WCF 서비스로 실행됨을 확인

### 임베디드 appsettings.json (3,203 bytes)

| 섹션 | 값 |
|------|-----|
| Environment | `production` |
| Bugsnag API Key | `0fb8047d1ed879251865331a8cc44572` |
| PgfxApi BaseUrl | `https://api.pokergfx.io` |
| PgfxApi Path | `/api/v1/` |
| WCF Endpoint | `http://videopokertable.net/wcf.svc` |
| WCF Certificate | X.509 self-signed, `videopokertable.net`, 2019-08-16 ~ 2156-07-08 |
| AES-256 Key 1 | `K7tA4fJBLO61xwgydYA7wVajG/EU75MJb/CRd9q/JGo=` (32 bytes) |
| AES-256 Key 2 | `6fPz9r5pnJpUB0w0z1OeETXMwzF1jzU9g3z1Y5JzLxo=` |
| Download URL | `https://videopokertable.net/Download.aspx` |
| Login URL | `https://www.pokergfx.io` |
| License Check | 5분 간격 (`00:05:00`) |
| Config Extension | `.pgfxconfig` |

### 로깅 시스템 (LogTopic 8개)

| Topic | 설명 |
|-------|------|
| General | 서버 핵심 운영, UI 상호작용 |
| Startup | 초기화, 하드웨어 체크, 타이머, 성능 측정 |
| **MultiGFX** | Primary/Secondary 동기화, 라이선스 검증 (멀티테이블) |
| AutoCamera | 자동 카메라 전환, 순환, 보드 팔로우 |
| Devices | Stream Deck, Action Tracker, 해설 부스 연결 |
| RFID | 리더 모듈, 태그 감지, 중복 모니터링, 캘리브레이션 |
| Updater | 업데이트 부트스트랩, 설치 관리 |
| GameState | 게임 저장/복원, 평가 폴백, 테이블 상태 전환 |

### 암호화 서비스
- `IEncryptionService` → `EncryptionService` (AES-256, `CryptoStream`)
- 키: `EncryptionConfiguration.Key` (appsettings.json에서 로드)

### 버전 관리
- 2단계 업데이트: Suggested (건너뛰기 가능) / Forced (강제)
- 오프라인 폴백: `offline_app_versions.json`, `downloadLinks.json`
- `ForceVersionUpdateWindow` / `SuggestVersionUpdateWindow` WinForms

### DI 등록 진입점
`ServiceCollectionExtensions.AddCommonLayer(IServiceCollection, IConfiguration)`
→ 3개 서비스 등록 (IEncryptionService, IDownloadLinksService, IAppVersionsService)

### 레지스트리 경로
- 64-bit: `HKLM\Software\PokerGFX\Server` (Path, Environment)
- 32-bit: `HKLM\Software\WOW6432Node\PokerGFX\Server`

---

## 발견된 모든 자격증명 및 키 요약

### 암호화 키

| 출처 | 용도 | 키 |
|------|------|-----|
| net_conn.dll | AES IV | `4390fjrfvfji9043` |
| net_conn.dll | AES DEFAULT_PWD | `45389rgjkonlgfds90439r043rtjfewp9042390j4f` |
| net_conn.dll | AES SALT | `dsafgfdagtds4389tytgh` |
| Common.dll appsettings | AES-256 키 1 | `K7tA4fJBLO61xwgydYA7wVajG/EU75MJb/CRd9q/JGo=` |
| Common.dll #US | AES-256 키 2 | `6fPz9r5pnJpUB0w0z1OeETXMwzF1jzU9g3z1Y5JzLxo=` |

### AWS 자격증명 (하드코딩!)

| 항목 | 값 |
|------|-----|
| Access Key | `AKIA***REDACTED***OH5F` |
| Secret Key | `YJPE***REDACTED***zq4u` |
| Region | `USEast1` |
| Bucket | `captures.pokergfx.io` |

### 서비스 키 (마스킹 처리)

| 출처 | 키 |
|------|-----|
| Bugsnag API Key | `0fb8047d1ed879251865331a8cc44572` |
| Medialooks SDK License | `PokerGFX LLC`, CompanyID `13751` |

### TLS 인증서
- WCF: X.509 self-signed, `videopokertable.net`, 2019-08-16 ~ 2156-07-08
- RFID: BearSSL, Server `vpt-server` / Client `vpt-reader`

## 발견된 모든 API 엔드포인트 요약

| 서비스 | URL | 용도 |
|--------|-----|------|
| PokerGFX API | `https://api.pokergfx.io/api/v1/` | 버전 체크, 다운로드, 분석 |
| Analytics Batch | `https://api.pokergfx.io/api/v1/analytics/batch` | 텔레메트리 배치 전송 |
| S3 Screenshots | `https://captures.pokergfx.io/captures/` | 스크린샷 S3 업로드 |
| WCF Service | `http://videopokertable.net/wcf.svc` | Server↔Remote 통신 |
| Download | `https://videopokertable.net/Download.aspx` | 업데이트 다운로드 |
| Login | `https://www.pokergfx.io` | 로그인/인증 |
| Twitch OAuth | `https://id.twitch.tv/oauth2/authorize` | 트위치 연동 |
| Twitch API | `https://api.twitch.tv/kraken/channels/` | 채널 정보 |
| Twitch Callback | `http://videopokertable.net/twitch_oauth.aspx` | OAuth 콜백 |
| Bugsnag | `https://notify.bugsnag.com` | 에러 리포팅 |

---

## 크로스 모듈 데이터 흐름

```
RFID Reader Hardware
       |
       | (USB HID / TCP+BearSSL)
       v
  RFIDv2.dll ──────► Tag events ──────► vpt_server.exe (main_form)
                                              |
                                              v
                                        mmr.dll (mixer)
                                              |
                                 +────────────+────────────+
                                 |            |            |
                              canvas      renderer      file
                              (D2D)     (NDI/BMD/SRT)  (MP4)
                                 |
                            image/text/pip/border elements
                                 |
  analytics.dll ◄── 이벤트 ─────┘
       |
       ├──► SQLite queue ──► api.pokergfx.io/analytics/batch
       └──► S3 captures ──► captures.pokergfx.io
```

---

## vpt_server.exe 메인 분석 (2,602 타입)

### 제품 식별
- **제품명**: PokerGFX Server (Video Poker Table)
- **내부명**: `RFID-VPT` (RFID Video Poker Table)
- **개발사**: PokerGFX LLC
- **공식 도메인**: `pokergfx.io`, `videopokertable.net`
- **빌드**: .NET Framework 4.x, WinForms, x86/x64, Costura.Fody 패키징
- **난독화**: Eazfuscator.NET (메서드 body), 필드/타입명은 대부분 보존

### God Class: main_form (329 methods, 398 fields)

main_form은 WinForms Form을 상속한 메인 윈도우로, 거의 모든 비즈니스 로직이 집중된 God class.

**주요 서비스 참조:**
| 필드 | 타입 | 역할 |
|------|------|------|
| `licenseService` | ILicenseService | 라이선스 검증 |
| `_tagsService` | ITagsService | RFID 태그 관리 |
| `serviceProvider` | IServiceProvider | DI 컨테이너 |
| `configurationPresetService` | IConfigurationPresetService | 설정 프리셋 |
| `_analyticsScreenshots` | AnalyticsScreenshots | 스크린샷 수집 |
| `_performanceMonitor` | PerformanceMonitor | 성능 모니터링 |
| `offlineSessionService` | OfflineSessionService | 오프라인 세션 |
| `_storageMonitor` | StorageMonitor | 디스크 공간 |

**네트워크 클라이언트:**
| 필드 | 타입 | 역할 |
|------|------|------|
| `net_client_vcap` | `client<client_obj>` | net_conn TCP/UDP 클라이언트 |
| `net_client_master` | object | 마스터 서버 연결 |
| `twitchChatbot` | object | Twitch IRC 봇 |

**UI 탭 구조:**
| 탭 | 필드명 | 기능 |
|----|--------|------|
| Sources | `tab_sources` | 카메라/비디오 소스 |
| Outputs | `outputsTabPage` | NDI/BMD/SRT 출력 |
| Graphics | `tab_graphics` | 스킨/애니메이션 |
| System | `tab_system` | 라이선스/네트워크 |
| Commentary | `tab_commentary` | 해설 부스 |

**핵심 상태 필드:**
| 필드 | 타입 | 의미 |
|------|------|------|
| `_isEvaluationMode` | bool | 평가판 모드 |
| `_isLicenseExpired` | bool | 라이선스 만료 |
| `IsInitializing` | bool | 초기화 중 |
| `IsShuttingDown` | bool | 종료 중 |
| `IsFirmwareUpdating` | bool | 펌웨어 업데이트 중 |
| `forceStream` | bool | 강제 스트리밍 |
| `adapter` | int | GPU 어댑터 인덱스 |

### 7-Application 생태계

PokerGFX는 단일 제품이 아니라 7개 연동 앱으로 구성:

```
                    ┌─────────────────────────┐
                    │     GfxServer           │ ← 메인 (이 EXE)
                    │  (main_form, 329 meth)  │
                    └────────┬────────────────┘
                             │ WCF/TCP
          ┌──────────────────┼──────────────────┐
          │                  │                  │
   ┌──────┴──────┐   ┌──────┴──────┐   ┌──────┴──────┐
   │ActionTracker│   │ HandEval    │   │ ActionClock │
   │(딜러 터치)  │   │ (WCF 서비스)│   │ (타이머)    │
   └─────────────┘   └─────────────┘   └─────────────┘
          │                                     │
   ┌──────┴──────┐                       ┌──────┴──────┐
   │ StreamDeck  │                       │Commentary   │
   │(Elgato 통합)│                       │Booth(해설)  │
   └─────────────┘                       └─────────────┘
          │
   ┌──────┴──────┐
   │   Pipcap    │
   │ (PIP 캡처)  │
   └─────────────┘
```

### 지원 게임 Enum (21개 variant)

```csharp
enum game {
    holdem,                              // Texas Hold'em
    holdem_sixplus_straight_beats_trips, // Short Deck (Straight > Trips)
    holdem_sixplus_trips_beats_straight, // Short Deck (Trips > Straight)
    pineapple,                           // Crazy Pineapple
    omaha, omaha_hilo,                   // 4-card Omaha
    omaha5, omaha5_hilo,                 // 5-card Omaha
    omaha6, omaha6_hilo,                 // 6-card Omaha
    courchevel, courchevel_hilo,         // Courchevel (5-card, 1st board card open)
    draw5,                               // 5-Card Draw
    deuce7_draw, deuce7_triple,          // 2-7 Lowball
    a5_triple,                           // A-5 Triple Draw
    badugi, badeucy, badacey,            // Badugi variants
    stud7, stud7_hilo8,                  // 7-Card Stud
    razz                                 // Razz (A-5 Lowball Stud)
}

enum game_class { flop, draw, stud }
```

### 게임 상태 데이터 모델

```csharp
class Hand {
    int HandNum;
    string Description;
    string StartDateTimeUTC;
    TimeSpan RecordingOffsetStart;
    TimeSpan Duration;
    string GameClass;            // "flop", "draw", "stud"
    string GameVariant;          // "holdem", "omaha" 등
    string BetStructure;         // "NL", "PL", "FL"
    int AnteAmt, BombPotAmt;
    int NumBoards, RunItNumTimes;
    FlopDrawBlinds FlopDrawBlinds;
    StudLimits StudLimits;
    List<Player> Players;
    List<Event> Events;
}

class Player {
    int PlayerNum;
    string Name, LongName;
    bool SittingOut;
    int BlindBetStraddleAmt;
    int StartStackAmt, EndStackAmt;
    List<string> HoleCards;
    int VPIPPercent, AggressionFrequencyPercent;
    int PreFlopRaisePercent, WentToShowDownPercent;
    int CumulativeWinningsAmt, EliminationRank;
}

class Event {
    string EventType;            // "FOLD", "BET", "CALL", "RAISE", "CHECK" 등
    int PlayerNum;
    int BetAmt;
    int NumCardsDrawn;
    int BoardNum;
    string BoardCards;           // "AhKdQc" 형식
    int Pot;
    string DateTimeUTC;
}

class FlopDrawBlinds {
    int BlindLevel;
    string AnteType;             // 8종 Ante 유형
    int SmallBlindAmt, BigBlindAmt, ThirdBlindAmt;
    int ButtonPlayerNum, SmallBlindPlayerNum;
    int BigBlindPlayerNum, ThirdBlindPlayerNum;
}
```

### Blackmagic ATEM 통합

```csharp
class atem {
    state_changed_event_handler _stateChangedEventHandler;
    state_enum _state;           // 연결 상태
    List<InputMonitor> _inputMonitors;
    List<camera> _cameraList;
    // BMDSwitcherAPI COM Interop
    // SwitcherMonitor, MixEffectBlockMonitor
}

enum event_type { connected, disconnected, input_changed }
enum state_enum { disconnected, connecting, connected }
```

### 스킨 시스템

```csharp
class config {
    static byte[] SKIN_HDR;      // 스킨 파일 헤더
    static byte[] SKIN_SALT;     // 스킨 암호화 salt
    static string SKIN_PWD;      // 스킨 비밀번호
    static int skin_crc;         // CRC 체크섬
    static byte[] serialized_skin;
    static string save_path;     // %APPDATA%\RFID-VPT
}

enum skin_auth_result { no_network, permit, deny }
```

---

## net_conn.dll 프로토콜 Wire Format 상세

### CSV 직렬화 규칙

모든 메시지는 CSV 형식: `COMMAND,field1,field2,...\n`

**이스케이프 규칙:**
- 필드 내 쉼표(`,`, char 44) → 틸데(`~`, char 126)로 치환
- bool → `"1"`(true) / `"0"`(false)
- int → `Int32.ToString()`
- null string → 빈 문자열

### 핵심 프로토콜 메시지 Wire Format

**1. 인증 흐름**
```
→ CONNECT                           # 연결 요청
← CONNECT,{license_json}            # 라이선스 정보 응답

→ AUTH,{password},{version}          # 인증 (버전은 선택)
← AUTH,{result}                      # 인증 결과
```

**2. 게임 상태**
```
← GAME_STATE,{GameType},{InitialSync}
  예: GAME_STATE,holdem,1            # Hold'em, 초기 동기화
```

**3. 플레이어 정보 (20필드)**
```
← PLAYER_INFO,{Player},{Name},{HasCards},{Folded},{AllIn},{Bet},
   {Stack},{Vpip},{Pfr},{SitOut},{Agr},{Wtsd},{CumWin},
   {Country},{HasExtraCards},{HasPic},{DeadBet},{NitGame},{LongName}

필드 인덱스:
[0]  Command     = "PLAYER_INFO"
[1]  Player      = int (좌석 번호)
[2]  Name        = string (쉼표→틸데)
[3]  HasCards    = "1"/"0"
[4]  Folded      = "1"/"0"
[5]  AllIn       = "1"/"0"
[6]  Bet         = int
[7]  Stack       = int (칩 스택)
[8]  Vpip        = int (VPIP %)
[9]  Pfr         = int (PFR %)
[10] SitOut      = "1"/"0"
[11] Agr         = int (공격성 %)
[12] Wtsd        = int (쇼다운 도달 %)
[13] CumWin      = int (누적 수익)
[14] Country     = string (쉼표→틸데)
[15] HasExtraCards = "1"/"0"
[16] HasPic      = "1"/"0"
[17] DeadBet     = int
[18] NitGame     = int
[19] LongName    = string (쉼표→틸데)
```

**4. 플레이어 카드**
```
← PLAYER_CARDS,{Player},{Cards}
  예: PLAYER_CARDS,3,AhKd             # 3번 좌석, A♥K♦
```

**5. 보드 카드**
```
← BOARD_CARD,{Position},{Card},{IsFaceUp}
  예: BOARD_CARD,1,Qc,1               # Flop 1번째, Q♣, 앞면
```

**6. 하트비트**
```
↔ HEARTBEAT,{timestamp}
← HEARTBEAT,{timestamp},{NetworkQuality}
  NetworkQuality: "Good" / "Fair" / "Poor"
```

**7. 스킨 청크 전송**
```
→ SKIN_REQ,{Pos},{ChunkSize}
← SKIN,{Pos},{ChunkSize},{Crc},{Length},{Start},{Data_base64}
```

### 압축 지원
메시지 끝에 `,COMPRESS` 또는 `,COMPRESSED` suffix가 붙으면 GZip 압축 적용

---

## 라이선싱 및 DRM 시스템

### 다층 보호 구조

```
Layer 1: KEYLOK USB 동글 (하드웨어)
    │
    ├── 43 메서드, 43 필드 (KeylokDongle)
    ├── DongleType: { Basic, Pro, Enterprise, ... }
    ├── KLClientCodes: 18개 클라이언트 코드
    └── IDongleService (14 methods)

Layer 2: 온라인 라이선스 서버
    │
    ├── WCF: http://videopokertable.net/wcf.svc
    ├── HTTPS: https://api.pokergfx.io/api/v1/
    ├── 5분 간격 체크 (LicenseBackgroundService)
    └── X.509 self-signed cert (2019~2156)

Layer 3: 오프라인 세션 관리
    │
    ├── OfflineSessionService
    ├── offline_app_versions.json (캐시)
    └── 제한 모드 운영

Layer 4: 평가판 모드
    │
    ├── _isEvaluationMode = true
    ├── _evaluationModeDuration (시간 제한)
    ├── trial_form (워터마크 표시)
    └── _licenceTrialTimer (타이머)
```

### 라이선스 등급

| 등급 | enum값 | 기능 |
|------|--------|------|
| Basic | 0 | 기본 그래픽 |
| Professional | 1 | 멀티카메라, SRT |
| Enterprise | 2 | MultiGFX, 풀 기능 |

### 인증 흐름

```
1. 앱 시작 → KEYLOK 동글 감지
2. 동글 검증 → 클라이언트 코드 확인
3. 온라인: WCF → videopokertable.net/wcf.svc → RemoteLicense 응답
4. 오프라인: 캐시된 offline_app_versions.json 확인
5. 실패: trial_form 표시 → 평가판 모드 진입
6. 5분 간격 백그라운드 재검증 (LicenseBackgroundService)
```

---

## 난독화 분석 요약

### 모듈별 난독화 수준

| 모듈 | 난독화 도구 | 수준 | 디컴파일 결과 |
|------|------------|------|--------------|
| **vpt_server.exe** | Eazfuscator.NET | **높음** | 필드/타입명 보존, 메서드 body 암호화, 일부 시그니처 변조 |
| **hand_eval.dll** | 없음 | **없음** | 완전 디컴파일 (PDB 존재) |
| **net_conn.dll** | 없음 | **없음** | 완전 디컴파일 (모든 모델 클래스 해독) |
| **analytics.dll** | 없음 | **없음** | 완전 디컴파일 |
| **RFIDv2.dll** | 없음 | **낮음** | 대부분 디컴파일, 일부 시그니처 복잡 |
| **mmr.dll** | 없음 | **낮음** | 대부분 디컴파일 |
| **boarssl.dll** | 없음 | **없음** | BearSSL C# 포트, 완전 디컴파일 |
| **PokerGFX.Common.dll** | 없음 | **없음** | 완전 디컴파일 |

### Eazfuscator.NET 특징 (vpt_server.exe)

1. **메서드 body 암호화**: IL 코드가 런타임에 복호화됨 → 정적 분석 시 `[extern/abstract]` 표시
2. **시그니처 변조**: 파라미터 타입이 `etype_0x...` 형태로 난독화
3. **제어 흐름 변환**: `bgt.un.s`, `ble.un.s` 등 비정상적 분기 패턴
4. **필드명 보존**: 대부분의 필드/프로퍼티 이름은 원본 유지
5. **타입명 보존**: 클래스명, enum값 등 원본 유지

**우회 전략**: 필드 구조 + net_conn 모델 + enum값으로 로직 추론 가능

---

## 핵심 SevenCards 평가 알고리즘 (hand_eval.dll)

### Bitmask 카드 표현

52장의 카드를 `ulong` (64-bit) bitmask로 표현:

```
bit 0-12:  Clubs     (2c=bit0, 3c=bit1, ..., Ac=bit12)
bit 13-25: Diamonds  (2d=bit13, 3d=bit14, ..., Ad=bit25)
bit 26-38: Hearts    (2h=bit26, 3h=bit27, ..., Ah=bit38)
bit 39-51: Spades    (2s=bit39, 3s=bit40, ..., As=bit51)
```

### 7-Card 평가 흐름

```csharp
// SevenCards.Evaluate(ulong hand)
static uint Evaluate(ulong hand) {
    // 1. 수트별 bitmask 분리 (13-bit shifts)
    uint clubs    = (uint)(hand & 0x1FFF);         // bit 0-12
    uint diamonds = (uint)((hand >> 13) & 0x1FFF); // bit 13-25
    uint hearts   = (uint)((hand >> 26) & 0x1FFF); // bit 26-38
    uint spades   = (uint)((hand >> 39) & 0x1FFF); // bit 39-51

    // 2. Flush 감지 (bitcount >= 5)
    uint flushSuit = 0;
    if (nBitsTable[clubs] >= 5)    flushSuit = clubs;
    if (nBitsTable[diamonds] >= 5) flushSuit = diamonds;
    if (nBitsTable[hearts] >= 5)   flushSuit = hearts;
    if (nBitsTable[spades] >= 5)   flushSuit = spades;

    // 3. Flush가 있으면 → 8192-entry 룩업 테이블
    if (flushSuit != 0) {
        return m_evaluatedresults[flushSuit]; // 사전계산된 결과
    }

    // 4. Non-flush → 전체 랭크 합산 후 룩업
    uint ranks = clubs | diamonds | hearts | spades;
    return m_evaluatedresults[ranks]; // 페어/스트레이트 등
}
```

### 룩업 테이블 (538개 FieldRVA)

| 테이블 | 크기 | 용도 |
|--------|------|------|
| `nBitsTable` | 8192 | bit count (0-13) |
| `straightTable` | 8192 | 스트레이트 감지 |
| `topFiveCardsTable` | 8192 | 상위 5장 선택 |
| `m_evaluatedresults` | 8192 | 최종 핸드 값 |
| `m_topthree` | 8192 | 상위 3장 |
| `CardMasksTable` | 52 entries | 카드→bitmask 변환 |
| `Pocket169Table` | 169 entries | 프리플롭 핸드 분류 |

### HandValue 인코딩

```
uint handValue:
  bits 24-27: HandType (0=HighCard ~ 8=StraightFlush)
  bits 0-23:  세부 순위 (킥커 포함)
```

---

## net_conn.dll AES 암호화 상세 (enc 클래스)

### 알고리즘 파라미터

```csharp
static class enc {
    // 하드코딩된 기본값
    static string DEFAULT_PWD = "45389rgjkonlgfds90439r043rtjfewp9042390j4f";
    static byte[] SALT = Encoding.ASCII.GetBytes("dsafgfdagtds4389tytgh");
    static byte[] IV   = Encoding.ASCII.GetBytes("4390fjrfvfji9043"); // 16 bytes

    // 파생 키 생성
    static byte[] key = new PasswordDeriveBytes(pwd, SALT).GetBytes(32); // 256-bit

    // RijndaelManaged 설정
    static RijndaelManaged aes = new RijndaelManaged {
        KeySize = 256,
        BlockSize = 128,
        Key = key,
        IV = IV,
        Padding = PaddingMode.PKCS7  // 암호화 시
        // Padding = PaddingMode.Zeros  // 복호화 시
    };
}
```

**보안 취약점:**
1. `PasswordDeriveBytes`는 PBKDF1 기반 (deprecated, Rfc2898DeriveBytes 권장)
2. IV가 고정 (nonce/IV 재사용)
3. 암호화/복호화 패딩 불일치 (PKCS7 vs Zeros)
4. 키 자체가 DLL에 하드코딩
5. `enc.init(pwd)` 메서드로 커스텀 키 설정 가능하나 기본값 사용 시 공통 키

### 스레드 안전

```csharp
// Monitor.Enter/Exit 패턴 (IL에서 확인)
static string Encrypt(string plainText) {
    Monitor.Enter(lockObject);
    try {
        // AES 암호화
        return Convert.ToBase64String(encrypted);
    } finally {
        Monitor.Exit(lockObject);
    }
}
```

---

## WCF 원격 통신 인터페이스

### Iwcf 인터페이스 (Server↔Remote RPC)

```csharp
interface Iwcf {
    // 9개 메서드
    CrcInfo ConnectToPrimaryServer(/*email, password, token, ...*/);
    void Disconnect();
    sw_file GetSoftwareUpdate();
    skin_info GetSkinInfo();
    byte[] GetSkinChunk(int offset, int size);
    void SendPing(client_ping ping);
    server_ping GetServerPing();
    void SendConfig(byte[] config);
    byte[] GetConfig();
}
```

### CrcInfo (연결 검증)
```csharp
class CrcInfo {
    int config_crc;  // 설정 CRC
    int uid_crc;     // 고유 ID CRC
}
```

### 상태 동기화 DTO

```csharp
class client_ping {  // Remote → Server (49 methods)
    // ActionTracker 상태 전체를 직렬화
}

class server_ping {  // Server → Remote (23 methods)
    // 서버 상태를 직렬화하여 Remote에 전달
}

class skin_info {    // 스킨 메타데이터 (17 methods)
    // 스킨 파일 정보, CRC, 크기
}

class sw_file {      // 소프트웨어 업데이트 파일 (23 methods)
    // 파일 청크, 버전, 크기
}
```

---

## 디컴파일 통계 요약

### 총 산출물

| 항목 | 수량 |
|------|------|
| 디컴파일된 모듈 | 8개 |
| 추출된 타입 | 3,083개 |
| 추출된 .cs 파일 | 500+ |
| 해독된 메서드 body | 2,000+ |
| 프로토콜 커맨드 | 113개 |
| 발견된 자격증명 | 7개 세트 |
| API 엔드포인트 | 10개 |

### 모듈별 디컴파일 성공률

| 모듈 | 타입 | 메서드 성공률 | 비고 |
|------|------|-------------|------|
| hand_eval.dll | 52 | **95%+** | PDB 존재, 거의 완전 |
| net_conn.dll | 169 | **98%+** | 모든 모델 완전 해독 |
| analytics.dll | 7 | **90%** | 핵심 로직 해독 |
| RFIDv2.dll | 27 | **85%** | 프로토콜/enum 완전, 일부 복잡 시그니처 |
| mmr.dll | 80 | **80%** | 설정/enum 완전, GPU 코덱 로직 해독 |
| boarssl.dll | 102 | **90%** | BearSSL 포트, 암호 알고리즘 해독 |
| PokerGFX.Common.dll | 50 | **95%** | appsettings 완전 추출 |
| vpt_server.exe | 2,602 | **40%** (메서드) / **95%** (구조) | Eazfuscator 난독화, 필드/타입 구조는 완전 |

### 역설계 커버리지 평가

| 영역 | 커버리지 | 설명 |
|------|---------|------|
| **프로토콜** | **100%** | 113 커맨드 모두 해독, wire format 확인 |
| **암호화** | **100%** | AES 키, IV, salt, 알고리즘 모두 추출 |
| **자격증명** | **100%** | AWS, Bugsnag, 암호화 키 모두 추출 |
| **게임 엔진** | **95%** | 핸드 평가, 확률 계산, 모든 게임 타입 |
| **RFID 하드웨어** | **90%** | 듀얼 트랜스포트, 22개 명령어, TLS |
| **비디오 파이프라인** | **85%** | 코덱 설정, 스트리밍, 녹화 흐름 |
| **UI/메인 로직** | **40%** | Eazfuscator로 메서드 body 암호화 |
| **라이선싱/DRM** | **75%** | 구조 파악, 동글 인터페이스 확인, 세부 로직은 난독화 |

---

## 역설계 방법론

### 사용 도구

| 도구 | 용도 |
|------|------|
| `il_decompiler.py` (자체 개발) | Python 기반 .NET IL 디컴파일러 |
| `pefile` (Python) | PE 헤더/섹션 파싱 |
| `struct` (Python 표준) | 바이너리 데이터 언패킹 |
| ECMA-335 Partition III | IL opcode 참조 |

### il_decompiler.py 스펙

- **입력**: .NET PE 파일 (.dll, .exe)
- **파싱**: CLI 헤더 → BSJB 시그니처 → #~ 스트림 → 8개 메타데이터 테이블
- **디코딩**: Method body (tiny/fat) → IL opcode → token 해석
- **출력**: C# 의사코드 (.cs 파일)
- **CLI 옵션**: `--stats`, `--types`, `--type <name>`, `--namespace <ns>`, `--all`, `--output <dir>`
- **해결한 버그**: MethodDef 테이블 Flags 컬럼 누락 (14→12 바이트 오류), genericinst 바운드 체크, 배열 시그니처 파싱

### 분석 접근법

1. **Phase 1**: Costura.Fody 리소스에서 80개 DLL 추출
2. **Phase 2**: PE 메타데이터 (TypeDef, MemberRef, UserString) 정적 분석
3. **Phase 3**: 커스텀 IL 디컴파일러 개발 → 전체 소스 코드 수준 추출
4. **Phase 4**: 모듈별 심층 분석 (알고리즘, 프로토콜, 암호화)
5. **Phase 5**: 크로스 모듈 통합 분석 (데이터 흐름, 인증 흐름)
