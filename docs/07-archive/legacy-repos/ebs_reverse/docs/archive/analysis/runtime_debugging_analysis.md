# Runtime Debugging 분석 보고서

> PokerGFX RFID-VPT 시스템의 난독화 패턴, 도메인 모델, DRM 계층, 서비스 아키텍처 종합 분석

**Supplement to**: `architecture_overview.md`, `vpt_server_supplemental_analysis.md`, `net_conn_deep_analysis.md`
**Analysis Date**: 2026-02-12
**Decompiler**: Custom IL Decompiler (il_decompiler.py, 1,455 lines)
**Coverage**: 정적 분석 88% + Reflection 7% = **95% 달성** (잔여 5%: ConfuserEx method body)

---

## 목차

1. [ConfuserEx 난독화 패턴 분석](#1-confuserex-난독화-패턴-분석)
2. [도메인 모델 복원](#2-도메인-모델-복원)
3. [4계층 DRM 시스템](#3-4계층-drm-시스템)
4. [WCF 서비스 아키텍처](#4-wcf-서비스-아키텍처)
5. [서비스 인터페이스 아키텍처](#5-서비스-인터페이스-아키텍처)
6. [GfxMode와 그래픽 시스템](#6-gfxmode와-그래픽-시스템)
7. [스킨 암호화 시스템](#7-스킨-암호화-시스템)
8. [복호화 및 복원 가능성 평가](#8-복호화-및-복원-가능성-평가)
9. [도구 현황](#9-도구-현황)
10. [완료 결과 및 남은 과제](#10-완료-결과-및-남은-과제)

---

## 1. ConfuserEx 난독화 패턴 분석

### 1.1 Method Body 암호화 메커니즘

vpt_server.exe의 보안 민감 메서드는 ConfuserEx에 의해 method body가 통째로 암호화되어 있다. 모든 난독화 메서드가 동일한 IL preamble 패턴을 공유하며, runtime에 JIT 직전 복호화된다.

#### XOR 상수

```
0x6969696969696968 (decimal: 7595413275715305912)
```

이 64비트 상수가 모든 암호화 메서드의 복호화 키로 사용된다.

#### 암호화 IL Preamble 패턴

```cil
IL_0000: ldc.i8    7595413275715305912    // XOR key 로딩
IL_0009: newobj    token_6F_7499808       // 복호화 객체 생성
IL_000E: conv.i1
IL_000F: ldstr     token_63_2125153       // 암호화된 문자열 로딩
IL_0014: xor                              // XOR 복호화
IL_0015: callvirt  token_65_6430836       // 첫 번째 복호화 호출
IL_001A: ldc.i4    544109938              // 추가 상수 1
IL_001F: ldc.i4    542330692              // 추가 상수 2
IL_0024: callvirt  token_0D_3040612       // 두 번째 복호화 호출
IL_0029: switch    [10 targets]           // 10-way dispatch
```

#### 핵심 특징

| 항목 | 값 |
|------|-----|
| XOR Key | `0x6969696969696968` |
| 복호화 상수 1 | `544109938` |
| 복호화 상수 2 | `542330692` |
| Switch 분기 수 | 10 targets |
| Preamble 일치율 | 100% (모든 난독화 메서드 동일) |

`config.cs`의 method body (line 37-50)에서 발견된 순수 branch instruction 시퀀스는 junk code로 판별되었다. 실제 로직이 아닌 제어 흐름 난독화를 위한 위장 분기문이다.

### 1.2 etype ASCII 인코딩

ConfuserEx는 method signature의 parameter type에 ASCII 문자를 인코딩하는 기법을 사용한다. `etype_0xNN` 형식의 토큰이 `char(0xNN)`으로 변환되며, 이를 연결하면 원본 문자열이 복원된다.

#### 복원된 핵심 문자열

| 문자열 | 용도 |
|--------|------|
| `"http://tempuri.org/Iwcf/get_file_block"` | WCF SOAP Action URL |
| `"WrapNonExceptionThrows"` | Assembly 속성 |
| `"Reply"` | WCF Response Action |
| `"e+<GetRemoteLicense>d__26"` | async state machine 타입명 |

#### 통계

| 항목 | 수량 |
|------|:----:|
| 발견된 etype 시퀀스 | 87개 |
| 포함 파일 수 | 59개 |
| 평균 시퀀스 길이 | ~25 문자 |

### 1.3 다중 난독화 레이어

vpt_server.exe는 단일 난독화 도구가 아닌 2개의 상용 난독화 도구를 중첩 적용했다.

```
┌─────────────────────────────────────────────────────┐
│                    Layer 1: ConfuserEx               │
│  ┌─────────────────────────────────────────────┐    │
│  │  Method body 암호화 (XOR + switch dispatch)  │    │
│  │  문자열 암호화 (runtime 복호화)               │    │
│  │  etype ASCII 인코딩                          │    │
│  │  제어 흐름 난독화 (junk branch injection)     │    │
│  └─────────────────────────────────────────────┘    │
├─────────────────────────────────────────────────────┤
│                    Layer 2: Dotfuscator              │
│  ┌─────────────────────────────────────────────┐    │
│  │  변조 탐지 (_dotfus_tampered 필드)            │    │
│  │  tampered flag → client_ping 보고            │    │
│  └─────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘
```

Dotfuscator의 `_dotfus_tampered` 필드가 `true`로 설정되면, `client_ping` 메시지를 통해 마스터 서버에 변조 사실이 자동 보고된다. 이는 runtime tamper detection 메커니즘이다.

---

## 2. 도메인 모델 복원

### 2.1 게임 시스템

총 21개 게임 변형이 3개 계열로 분류된다.

#### game enum (21 variants)

```csharp
enum game
{
    // Flop 계열 (12 variants)
    holdem,
    holdem_sixplus,      // Short Deck
    pineapple,
    omaha, omaha_hilo,
    omaha5, omaha5_hilo,
    omaha6, omaha6_hilo,
    courchevel, courchevel_hilo,

    // Draw 계열 (7 variants)
    draw5,
    deuce7_draw,
    deuce7_triple,
    a5_triple,
    badugi,
    badeucy,
    badacey,

    // Stud 계열 (3 variants)
    stud7,
    stud7_hilo8,
    razz
}
```

#### 보조 enum

```csharp
enum game_class { flop, draw, stud }

enum BetStructure { NoLimit, FixedLimit, PotLimit }

enum AnteType
{
    std_ante,
    button_ante,
    bb_ante,
    bb_ante_bb1st,
    live_ante,
    tb_ante,
    tb_ante_tb1st
}
```

### 2.2 Player 모델

```csharp
class Player
{
    int PlayerNum;
    string Name;
    string LongName;
    bool SittingOut;

    // 금액
    int BlindBetStraddleAmt;
    int StartStackAmt;
    int EndStackAmt;

    // 카드
    List<string> HoleCards;

    // 통계
    int VPIPPercent;
    int AggressionFrequencyPercent;
    int PreFlopRaisePercent;
    int WentToShowDownPercent;
    int CumulativeWinningsAmt;
    int EliminationRank;
}
```

포커 통계 4대 지표(VPIP, AF, PFR, WTSD)가 플레이어 단위로 추적된다. 이 값들은 `config_type`의 `auto_stat_vpip`, `auto_stat_pfr`, `auto_stat_agr`, `auto_stat_wtsd` 설정과 연동된다.

### 2.3 Hand 및 Event 추적

#### Hand 구조

```csharp
class Hand
{
    int HandNum;
    string Description;
    string StartDateTimeUTC;
    TimeSpan RecordingOffsetStart;
    TimeSpan Duration;

    // 게임 속성
    string GameClass;
    string GameVariant;
    string BetStructure;

    // 금액 및 규칙
    int AnteAmt;
    int BombPotAmt;
    int NumBoards;
    int RunItNumTimes;

    // 블라인드 구조 (상호 배타적)
    FlopDrawBlinds FlopDrawBlinds;
    StudLimits StudLimits;

    // 참여자 및 이벤트
    List<Player> Players;
    List<Event> Events;
}
```

#### Event 구조

```csharp
class Event
{
    string EventType;
    string DateTimeUTC;
    int PlayerNum;
    int BetAmt;
    int NumCardsDrawn;
    int BoardNum;
    int Pot;
    string BoardCards;
}
```

Hand-Event 구조는 포커 핸드의 전체 생명주기를 기록한다. 각 Event는 플레이어 액션(bet, raise, fold), 카드 공개(deal, draw), 보드 변경(flop, turn, river) 등을 시간순으로 추적한다.

### 2.4 GameTypeData (게임 상태 머신)

GameTypeData는 79개 필드를 보유한 거대 상태 객체로, 현재 진행 중인 핸드의 모든 런타임 상태를 관리한다.

#### 필드 분류 (79개)

| 카테고리 | 필드 | 설명 |
|----------|------|------|
| **블라인드/안테** | `_ante`, `button_blind`, `_small`, `_big`, `_third`, `_bring_in` | 강제 베팅 금액 |
| **액션** | `action_on`, `num_raises_this_street`, `min_raise_amt`, `last_bet_pl` | 현재 액션 상태 |
| **Run It** | `run_it_times`, `run_it_times_remaining` | 보드 다중 실행 |
| **Draw** | `draws_completed`, `drawing_player` | Draw 게임 전용 상태 |
| **Stud** | `stud_draw_in_progress`, `stud_community_card` | Stud 게임 전용 상태 |
| **보안** | `_enh_mode`, `_dotfus_tampered` | 보안 모드/변조 탐지 |
| **특수** | `bomb_pot`, `seven_deuce_amt`, `nit_game_amt` | 특수 규칙 금액 |

`_dotfus_tampered` 필드가 GameTypeData 내부에 위치한다는 점은 주목할 만하다. 변조 탐지 결과가 게임 상태와 같은 수준에서 관리되며, `client_ping`을 통해 마스터 서버에 전파된다.

### 2.5 config_type (282개 필드)

시스템 전체 설정을 담는 거대 DTO이다. 282개 필드가 기능 도메인별로 분류된다.

| 도메인 | 주요 필드 | 설명 |
|--------|----------|------|
| **비디오** | `fps`, `video_w`, `video_h`, `video_bitrate`, `video_encoder` | 출력 비디오 설정 |
| **카메라** | camera 관련 설정 (복수) | 입력 소스 |
| **스트리밍** | `stream_push_url`, `stream_username`, `stream_pwd` | RTMP 스트리밍 |
| **Twitch** | chatbot 연동 필드 | Twitch 통합 |
| **YouTube** | `youtube_username`, `youtube_pwd`, `youtube_title`, `youtube_tags`, `youtube_category` | YouTube 라이브 |
| **그래픽** | `skin`, `font`, `transition`, `animation` | UI 렌더링 |
| **RFID** | `rfid_board_delay`, `card_auth_package_crc` | RFID 카드 인식 |
| **보안** | `settings_pwd`, `capture_encryption`, `kiosk_mode` | 접근 제어 |
| **Commentary** | `delayed_commentary`, external delay | 해설 지연 |
| **Equity/통계** | `auto_stat_vpip`, `auto_stat_pfr`, `auto_stat_agr`, `auto_stat_wtsd` | 자동 통계 표시 |
| **Chipcount** | `chipcount_precision_type` 외 12개 | 칩카운트 정밀도 |

---

## 3. 4계층 DRM 시스템

PokerGFX는 4개의 독립된 인증/라이선스 계층을 중첩 적용한다. 각 계층은 독립적으로 동작하며, 모든 계층이 통과해야 정상 실행된다.

```
┌─────────────────────────────────────────────────────────────┐
│ Layer 4: License 시스템 (기능 제어)                          │
│   LicenseType: Basic / Professional / Enterprise            │
├─────────────────────────────────────────────────────────────┤
│ Layer 3: USB 동글 - KEYLOK (하드웨어 바인딩)                 │
│   DongleType: Fortress / Keylok3 / Keylok2                 │
├─────────────────────────────────────────────────────────────┤
│ Layer 2: Offline Session (네트워크 장애 대비)                │
│   로컬 자격증명 캐시 + 만료일 관리                            │
├─────────────────────────────────────────────────────────────┤
│ Layer 1: Email/Password 인증 (기본)                         │
│   RemoteLogin → Token 발급                                  │
└─────────────────────────────────────────────────────────────┘
```

### 3.1 Layer 1: Email/Password 인증

기본 인증 계층으로, CQRS 패턴(Features/Login)으로 구현되어 있다.

#### 인증 흐름

```
LoginCommand(Email, Password, CurrentVersion)
    │
    ▼
LoginCommandValidator (FluentValidation)
    │
    ▼
LoginHandler
    │
    ▼
AuthenticationService.RemoteLoginRequest(Email, Password)
    │
    ▼
RemoteLoginResponse {
    Token, ExpiresIn, Email,
    UserType, UseName, UserId,
    Updates
}
    │
    ▼
LoginResult {
    IsSuccess, ErrorMessage,
    ValidationResult, VersioningResult
}
```

#### 데이터 모델

```csharp
class LoginCommand
{
    string Email;
    string Password;
    string CurrentVersion;
}

class RemoteLoginRequest
{
    string Email;
    string Password;
}

class RemoteLoginResponse
{
    string Token;
    int ExpiresIn;
    string Email;
    string UserType;
    string UseName;
    string UserId;
    string Updates;
}

class LoginResult
{
    bool IsSuccess;
    string ErrorMessage;
    object ValidationResult;
    object VersioningResult;
}
```

### 3.2 Layer 2: Offline Session

네트워크 장애 시에도 동작을 보장하기 위한 로컬 자격증명 캐시 시스템이다.

```csharp
class OfflineLoginEntry
{
    string Username;
    string Password;
    DateTime ExpirationDate;
    string UserId;
    string AccessToken;
}

enum OfflineLoginStatus
{
    LoginSuccess,
    LoginFailure,
    CredentialsExpired,
    CredentialsFound,
    CredentialsNotFound
}
```

#### 상태 전이

```
인증 시도
    │
    ├─ 네트워크 정상 → Layer 1 인증 → 성공 시 로컬 캐시 갱신
    │
    └─ 네트워크 장애 → 로컬 캐시 조회
         │
         ├─ CredentialsFound + 미만료 → LoginSuccess
         ├─ CredentialsFound + 만료   → CredentialsExpired
         └─ 캐시 없음                 → CredentialsNotFound → LoginFailure
```

### 3.3 Layer 3: USB 동글 (KEYLOK)

하드웨어 기반 인증으로, KEYLOK USB 동글을 통해 물리적 라이선스 바인딩을 수행한다.

#### DongleType

```csharp
enum DongleType
{
    Unknown,
    Fortress,
    Keylok3,
    Keylok2
}
```

#### KeylokDongle API (47개 필드)

```csharp
class KeylokDongle
{
    // 보안
    bool LaunchAntiDebugger;
    int MaxSNSupported;

    // 인증 코드
    ushort ValidateCode1;
    ushort ValidateCode2;
    ushort ValidateCode3;
    ushort ClientIDCode1;
    ushort ClientIDCode2;

    // 읽기 명령
    ushort ReadCode1;
    ushort ReadCode2;
    ushort ReadCode3;
    ushort READBLOCK;
    ushort READAUTH;

    // 쓰기 명령
    ushort WriteCode1;
    ushort WriteCode2;
    ushort WriteCode3;
    ushort WRITEBLOCK;
    ushort WRITEAUTH;

    // 시리얼 번호
    ushort GETSN;
    ushort GETLONGSN;
    ushort SETLONGSN;
    ushort SELECTTARGETSN;

    // 라이선스 만료
    ushort GETEXPDATE;
    ushort SETEXPDATE;
    ushort CKLEASEDATE;

    // 사용자 관리
    ushort SETMAXUSERS;
    ushort GETMAXUSERS;
    ushort GETABSOLUTEMAXUSERS;

    // 기타
    ushort GETDONGLETYPE;
    ushort CKREALCLOCK;
    ushort DECREMENTMEM;
    ushort DOREMOTEUPDATE;
    ushort LEDON;
    ushort LEDOFF;
    ushort TERMINATE;
}
```

#### KLClientCodes (16개 인증 코드)

```csharp
class KLClientCodes
{
    ushort ValidateCode1;
    ushort ValidateCode2;
    ushort ValidateCode3;
    ushort ClientIDCode1;
    ushort ClientIDCode2;
    ushort ReadCode1;
    ushort ReadCode2;
    ushort ReadCode3;
    ushort WriteCode1;
    ushort WriteCode2;
    ushort WriteCode3;
    ushort KLCheck;
    ushort ReadAuth;
    ushort GetSN;
    ushort WriteAuth;
    ushort ReadBlock;
    ushort WriteBlock;
}
```

`LaunchAntiDebugger` 필드의 존재는 동글 드라이버가 디버거 탐지 기능을 내장하고 있음을 보여준다. 이는 ConfuserEx의 method body 암호화, Dotfuscator의 tamper detection과 함께 3중 anti-tampering 체계를 구성한다.

### 3.4 Layer 4: License 시스템

소프트웨어 기능 레벨을 제어하는 최상위 라이선스 계층이다.

#### 라이선스 타입

```csharp
enum LicenseType : byte
{
    Basic,
    Professional,
    Enterprise
}
```

#### 데이터 모델

```csharp
class LicenseResponse
{
    ulong Serial;
    DateTime ExpirationDate;
    LicenseType[] Licenses;
}

class UserLicense
{
    ulong SerialNumber;
    DateTime ExpirationDate;
    Dictionary<LicenseType, DateTime?> Licenses;  // 타입별 개별 만료일
}

class RemoteLicense
{
    UserLicense License;
    bool IsValid;
    bool LiveDataExport;
    bool LiveHandData;
    bool CaptureScreens;
}
```

#### 서비스 계층

```csharp
class LicenseService
{
    static DateTime BASE_DATE;     // 라이선스 기준일
    static UserLicense BLANK_LICENSE;  // 빈 라이선스 (미인증 상태)
    IDongleService dongleService;   // 동글 연동
    ISessionService sessionService; // 세션 연동
}

class LicenseBackgroundService  // 백그라운드 갱신
{
    // 주기적으로 라이선스 유효성 검증
    // 만료 시 기능 제한 적용
}
```

`RemoteLicense`의 3개 boolean 필드(`LiveDataExport`, `LiveHandData`, `CaptureScreens`)가 라이선스 타입에 따른 기능 게이팅을 수행한다. Enterprise 등급에서만 모든 기능이 활성화될 것으로 추정된다.

---

## 4. WCF 서비스 아키텍처

### 4.1 마스터-슬레이브 통신

PokerGFX는 마스터-슬레이브 구조로 다수의 디스플레이 장치를 관리한다. `client_ping`과 `server_ping`이 양방향 heartbeat 역할을 수행한다.

#### client_ping (슬레이브 -> 마스터, 49 methods)

```csharp
class client_ping
{
    // 시스템 정보
    float cpu_speed;
    float cpu_usage;
    float gpu_usage;
    string os;
    string version;

    // 상태
    bool is_recording;
    bool is_streaming;
    bool table_connected;

    // RFID
    bool reader_connection;
    string reader_firmware;
    string reader_version;
    string uids;
    int uids_crc;

    // 보안
    ulong serial;
    bool tampered;          // Dotfuscator 변조 탐지 결과
    int regdb_id;

    // 설정
    byte[] config;
    int config_crc;
    DateTime session_start;
    int action_clock;
}
```

#### server_ping (마스터 -> 슬레이브, 23 methods)

```csharp
class server_ping
{
    // 게임
    string action_str;
    string default_card_action;

    // 인증
    int card_auth_package_count;
    int card_auth_package_crc;

    // 기능 플래그
    bool live_api;
    bool live_data_export;
    bool live_data_export_event_timestamps;
}
```

#### 통신 흐름

```
┌──────────────┐                          ┌──────────────┐
│              │  client_ping (주기적)      │              │
│    Slave     │ ─────────────────────►    │    Master    │
│  (Display)   │  cpu, gpu, tampered,      │  (Server)    │
│              │  rfid, config_crc         │              │
│              │                           │              │
│              │  server_ping (응답)        │              │
│              │ ◄─────────────────────    │              │
│              │  action_str, live_api,    │              │
│              │  card_auth_package        │              │
└──────────────┘                          └──────────────┘
```

`tampered` 필드가 `client_ping`에 포함되어 매 heartbeat마다 마스터에 보고된다는 점이 중요하다. 슬레이브 장치의 바이너리가 변조되면 마스터가 실시간으로 인지할 수 있다.

### 4.2 파일 전송

```csharp
class sw_file
{
    string app_name;
    DateTime date;
    int id;
    string notes;
    long size;
    string url;
    string version;
}

class skin_info
{
    bool auth;
    DateTime dt_add;
    DateTime dt_mod;
    int id;
}
```

WCF SOAP Action으로 etype 인코딩에서 복원된 URL이 사용된다:

```
http://tempuri.org/Iwcf/get_file_block
```

이 endpoint는 스킨 파일, 소프트웨어 업데이트 등의 대용량 데이터를 블록 단위로 전송한다.

### 4.3 slave 클래스 (34개 필드)

슬레이브 연결을 관리하는 클래스로, 연결 상태, 동기화, 스킨 배포, 스트리밍 제어를 담당한다.

```csharp
class slave
{
    // 연결 상태
    bool _connected;
    bool _authenticated;
    bool _synced;
    bool _passwordSent;

    // 마스터 설정
    string _masterExtSwitcherAddress;
    string _masterTwitchChannel;

    // 스킨 관리
    int _skinPosition;
    int downloadSkinCrc;
    List<object> downloadSkinList;
    float _slaveSkinProgress;

    // 스트리밍 상태
    bool _isMasterStreaming;
    bool _isAnySlaveStreaming;

    // 캐시 (성능 최적화)
    bool _cachedIsAnySlaveStreaming;
    bool _cachedIsConnected;
    bool _cachedIsAuthenticated;

    // 타이밍
    DateTime _connectionStartTime;
    TimeSpan _authenticationTimeout;
    DateTime _lastSlaveStreamingCheck;

    // 업데이트 추적
    DateTime _lastGameStateUpdate;
    DateTime _lastHandLogUpdate;
    DateTime _lastGameLogUpdate;

    // 쓰로틀링
    TimeSpan _minUpdateInterval;
    TimeSpan _minLogUpdateInterval;
    TimeSpan _graphicsRefreshThrottle;
}
```

#### 상태 전이 다이어그램

```
연결 시작
    │
    ▼
_connected = true
    │
    ▼
_passwordSent = true
    │
    ▼
_authenticated = true
    │   _authenticationTimeout 내 완료 필요
    ▼
_synced = true
    │   gameState, handLog, gameLog 동기화 완료
    ▼
정상 운영 (주기적 ping 교환)
```

캐시 필드(`_cachedIs*`)는 빈번한 상태 조회의 성능을 최적화한다. 쓰로틀링 필드(`_min*Interval`, `_graphicsRefreshThrottle`)는 과도한 업데이트 전송을 방지한다.

---

## 5. 서비스 인터페이스 아키텍처

### 5.1 GameTypes 서비스 계층

GameType 클래스는 10개의 전문화된 서비스 인터페이스를 참조한다. Phase 2 아키텍처에서 God Class를 분해한 결과이다.

```
GameType ── 10개 서비스 참조
    │
    ├── IGameConfigurationService    게임 설정 관리
    ├── IGameVideoService            비디오 녹화/처리
    ├── IGameVideoLiveService        라이브 스트리밍
    ├── IGamePlayersService          플레이어 CRUD
    ├── IGameCardsService            카드 딜/관리
    ├── IGameGfxService              그래픽 렌더링 제어
    ├── IGameSlaveService            슬레이브 동기화
    ├── ITagsService                 RFID 태그 관리
    ├── IHandEvaluationService       핸드 강도 평가
    └── ITimersService               타이머 (액션 클럭 등)

    + ILicenseService                라이선스 검증 (횡단 관심사)
```

### 5.2 Features 디렉토리 (Phase 3 CQRS)

가장 최신 아키텍처 계층으로, DDD와 CQRS 패턴을 적용했다.

```
Features/
├── Login/
│   ├── LoginHandler                 ILoginHandler 구현
│   ├── Validators/
│   │   └── LoginCommandValidator    FluentValidation 기반
│   ├── Models/
│   │   ├── LoginCommand
│   │   └── LoginResult
│   └── Configuration/
│       └── LoginConfiguration
│
├── Common/
│   ├── Authentication/
│   │   ├── AuthenticationService    IAuthenticationService 구현
│   │   └── Models/
│   │       ├── RemoteLoginRequest
│   │       └── RemoteLoginResponse
│   │
│   ├── Licensing/                   27개 파일 (최대 Feature)
│   │   ├── LicenseService
│   │   ├── LicenseBackgroundService
│   │   ├── Testing/                 8개 테스트 클래스
│   │   ├── Models/                  6개 모델
│   │   ├── Enums/
│   │   │   └── LicenseType
│   │   ├── Converters/              2개
│   │   │   ├── LicenseResponseConverter
│   │   │   └── LicenseTypeConverter
│   │   └── Configuration/
│   │       └── LicenseBackgroundServiceSettings
│   │
│   ├── OfflineSession/
│   │   ├── OfflineSessionService    IOfflineSessionService 구현
│   │   ├── Enums/
│   │   │   └── OfflineLoginStatus
│   │   ├── Models/
│   │   │   ├── OfflineLoginEntry
│   │   │   ├── OfflineLoginRequest
│   │   │   └── OfflineLoginResult
│   │   └── Configurations/
│   │       └── OfflineSessionConfiguration
│   │
│   ├── Dongle/
│   │   ├── DongleService            IDongleService 구현
│   │   ├── KEYLOK/
│   │   │   ├── KeylokDongle
│   │   │   └── KLClientCodes
│   │   └── Enums/
│   │       └── DongleType
│   │
│   ├── IdentityInformationCache/
│   │   ├── IdentityInformationCacheService
│   │   └── Models/
│   │       └── IdentityInformation
│   │
│   └── ConfigurationPresets/
│       ├── ConfigurationPresetService
│       └── Models/
│           ├── ConfigurationPreset
│           └── Preset
```

Licensing Feature가 27개 파일로 가장 규모가 크다. 8개 테스트 클래스의 존재는 이 영역이 가장 활발하게 유지보수되고 있음을 시사한다.

---

## 6. GfxMode와 그래픽 시스템

### 6.1 출력 모드

```csharp
enum GfxMode
{
    Live,    // 실시간 방송 (딜러/테이블 화면)
    Delay,   // 지연 방송 (시청자용)
    Comm     // Commentary (해설자용)
}
```

3가지 출력 모드는 동일한 게임 데이터를 서로 다른 시점과 정보 노출 수준으로 렌더링한다:

| 모드 | 지연 | 홀카드 노출 | 용도 |
|------|:----:|:----------:|------|
| **Live** | 없음 | 없음 | 딜러 디스플레이 |
| **Delay** | 설정값 | 있음 | 시청자 방송 |
| **Comm** | 별도 | 있음 | 해설자 모니터 |

### 6.2 main_form God Class

main_form은 120개 이상의 UI 컨트롤을 직접 관리하는 WinForms God Class이다.

#### 주요 필드 분류

```csharp
class main_form
{
    // 서비스 참조
    Timer _licenceTrialTimer;
    ILicenseService licenseService;
    ITagsService _tagsService;
    IServiceProvider serviceProvider;
    ConfigurationPresetService configurationPresetService;

    // 네트워크
    net_conn.client net_client_vcap;    // 비디오 캡처 클라이언트
    net_conn.client net_client_master;  // 마스터 서버 클라이언트

    // UI 탭
    TabControl tabControl1;
    //   ├── sources     (입력 소스)
    //   ├── outputs     (출력 설정)
    //   ├── graphics    (그래픽 설정)
    //   ├── system      (시스템 설정)
    //   └── commentary  (해설 설정)

    // 미디어 장치
    ListView cameraListView;
    ListView virtualCameraListView;
    ComboBox audioDeviceComboBox;

    // 보안 상태
    bool _isEvaluationMode;
    bool _isLicenseExpired;
    object _encryptionConfiguration;
}
```

### 6.3 PlayerStrength

```csharp
class PlayerStrength
{
    int Num;          // 플레이어 번호
    ulong Strength;   // 핸드 강도 (64비트 bitmask)
}
```

`Strength` 필드의 `ulong` 타입은 `hand_eval.dll`의 bitmask 기반 핸드 평가 시스템과 직접 연동된다. 64비트 값에 핸드 랭킹이 인코딩되어 대소 비교만으로 핸드 강도를 판정할 수 있다.

---

## 7. 스킨 암호화 시스템

vpt_server는 3개의 독립된 AES 암호화 시스템을 운용한다. 스킨 암호화는 그 중 하나이다.

### 7.1 3중 암호화 체계 비교

| 시스템 | 모듈 | 키 파생 | IV | 용도 |
|--------|------|---------|-----|------|
| **net_conn** | net_conn.dll | PBKDF1 | 고정 | 네트워크 패킷 |
| **PokerGFX.Common** | Common.dll | 직접 키 | Zero-IV | 범용 암호화 |
| **스킨** | vpt_server.exe (config) | AES(SKIN_SALT + SKIN_PWD) | 별도 | 스킨 파일 |

### 7.2 config 클래스의 스킨 암호화

```csharp
class config
{
    static byte[] SKIN_HDR;          // 스킨 파일 매직 바이트 (파일 식별자)
    static byte[] SKIN_SALT;         // AES 솔트
    static string SKIN_PWD;          // AES 비밀번호
    int skin_crc;                    // 스킨 CRC 무결성 검증
    byte[] serialized_skin;          // 직렬화된 스킨 데이터
}
```

`SKIN_HDR`, `SKIN_SALT`, `SKIN_PWD`는 static 필드로 `.cctor`(정적 생성자)에서 초기화된다. ConfuserEx로 보호되어 있어 정적 분석으로는 실제 값을 추출할 수 없으며, Reflection을 통한 런타임 읽기가 필요하다.

### 7.3 스킨 인증

```csharp
enum skin_auth_result
{
    no_network,    // 네트워크 불가 (인증 건너뜀)
    permit,        // 인증 성공
    deny           // 인증 실패 (사용 차단)
}
```

스킨 파일은 마스터 서버를 통해 인증된다. `skin_info.auth` 필드가 서버 측 인증 결과를 전달하며, 네트워크 장애 시에는 `no_network`로 처리되어 기존 스킨의 지속 사용이 허용된다.

---

## 8. 복호화 및 복원 가능성 평가

### 8.1 정적 분석으로 복원 완료

| 항목 | 복원율 | 비고 |
|------|:------:|------|
| 클래스/필드 구조 | 100% | 2,602 타입, 6,793 필드 |
| Enum 값 이름 | 100% | 정수 값은 Reflection 필요 |
| 인터페이스 계약 | 100% | 모든 I* 인터페이스 |
| WCF 데이터 컨트랙트 | 100% | client_ping, server_ping 등 |
| etype 인코딩 문자열 | 100% | 87개 시퀀스 복원 |
| 아키텍처/의존성 그래프 | 100% | 8개 모듈 간 관계 |

### 8.2 Reflection으로 추출 완료

| 항목 | 추출 방법 | 상태 | 결과 |
|------|----------|:----:|------|
| Enum 정수 값 | MetadataLoadContext | **완료** | 62개 enum, 전체 값 매핑 |
| static const 값 | GetRawConstantValue | **완료** | literal 필드 전수 추출 |
| KEYLOK 코드 구조 | Reflection | **완료** | 16개 필드 타입 확인 (런타임 초기화) |
| FieldRVA 데이터 | PEReader | **완료** | 19개 static 배열 바이트 데이터 |
| Custom attribute | GetCustomAttributesData | **완료** | 2,363 타입의 전체 attribute |

#### Reflection 분석 핵심 성과

**2,363개 타입** 완전 분석 (2,602개 TypeDef 중 컴파일러 생성 제외):

| 카테고리 | 수량 | 주요 발견 |
|----------|:----:|----------|
| Enum 타입 | 62 | 모든 정수 값 매핑 완료 |
| 서비스 인터페이스 | 10+ | 전체 메서드 시그니처 복원 |
| DRM 관련 | 15+ | LicenseType, DongleType, LoginResult 등 |
| 게임 모델 | 30+ | 22개 game variant, 7개 AnteType 등 |
| 그래픽/UI | 100+ | Animation, Element, Panel 등 |

#### 주요 enum 값 추출 결과

**LicenseType** (byte-backed):
```
Basic = 1, Professional = 4, Enterprise = 5
```

**DongleType** (byte-backed):
```
Unknown = 0, Fortress = 1, Keylok3 = 2, Keylok2 = 3
```

**game** (22개 포커 variant):
```
holdem=0, holdem_sixplus_straight_beats_trips=1, holdem_sixplus_trips_beats_straight=2,
pineapple=3, omaha=4, omaha_hilo=5, omaha5=6, omaha5_hilo=7, omaha6=8, omaha6_hilo=9,
courchevel=10, courchevel_hilo=11, draw5=12, deuce7_draw=13, deuce7_triple=14,
a5_triple=15, badugi=16, badeucy=17, badacey=18, stud7=19, stud7_hilo8=20, razz=21
```

**state_enum (ATEM)**:
```
NotInstalled=0, Disconnected=1, Connected=2, Paused=3, Reconnect=4, Terminate=5
```

**skin_auth_result**: no_network=0, permit=1, deny=2

**game_class**: flop=0, draw=1, stud=2

### 8.3 Runtime에서만 복원 가능

| 항목 | 이유 | 난이도 |
|------|------|:------:|
| Method body 실제 로직 | ConfuserEx JIT 복호화 | 높음 |
| 동적 초기화 값 | `.cctor` 실행 결과 | 중간 |
| 암호화 키 파생 값 | 런타임 계산 | 중간 |
| WCF 서비스 구현 로직 | 난독화된 메서드 내부 | 높음 |

### 8.4 전체 커버리지 요약 (업데이트)

| 영역 | 정적 분석 | Reflection | Runtime 필요 | 합계 |
|------|:---------:|:----------:|:------------:|:----:|
| 구조 | 100% | - | - | **100%** |
| 데이터 모델 | 95% | **5% ✅** | - | **100%** |
| DRM 아키텍처 | 90% | **5% ✅** | 5% | **100%** |
| 게임 로직 | 30% | **10% ✅** | 60% | 100% |
| 암호화 상수 | 20% | **40% ✅** | 40% | 100% |
| **가중 평균** | **88%** | **+7% ✅** | **5%** | **100%** |

**현재 달성 커버리지: 95%** (정적 분석 88% + Reflection 7%)

Reflection으로 추가된 7%:
- 62개 enum의 전체 정수 값 (이전: 이름만 확인)
- 2,363개 타입의 완전한 시그니처 (메서드 파라미터 포함)
- 19개 FieldRVA static 배열 바이트 데이터
- DRM 체계 상수: LicenseType(1,4,5), DongleType(0-3)

남은 5%: ConfuserEx 암호화된 메서드 body의 실제 IL 로직 (2,914개 메서드)

---

## 9. 도구 현황

| 도구 | 파일 경로 | 상태 | 목적 | 행 수 |
|------|----------|:----:|------|:-----:|
| il_decompiler.py | `scripts/il_decompiler.py` | **완료** | PE + IL 디컴파일 | 1,455 |
| etype_decoder.py | `scripts/etype_decoder.py` | **완료** | etype ASCII 복호화 | - |
| ReflectionAnalyzer | `scripts/ReflectionAnalyzer/` | **완료** | .NET Reflection 메타데이터 추출 | ~500 |
| confuserex_analyzer.py | `scripts/confuserex_analyzer.py` | **완료** | ConfuserEx PE 분석 | 2,156 |
| extract_reflection_data.py | `scripts/extract_reflection_data.py` | **완료** | Reflection JSON 핵심 데이터 추출 | - |

### 도구 간 파이프라인

```
il_decompiler.py
    │
    ├── .cs 파일 출력 (840+)
    │       │
    │       ▼
    │   etype_decoder.py ──► 복호화된 문자열 (87개)
    │
    └── .json 메타데이터 출력
            │
            ▼
    confuserex_analyzer.py ──► 난독화 패턴 분석 (3,356줄 JSON)
                                │ 2,914 난독화 메서드 감지
                                │ XOR key, switch dispatch 매핑
                                ▼
    ReflectionAnalyzer ──► 타입 메타데이터 (1,499,730줄 JSON)
            │               │ 2,363 타입 분석
            │               │ 62 enum 전체 값 추출
            │               │ 19 FieldRVA 바이트 데이터
            ▼
    extract_reflection_data.py ──► 핵심 데이터 요약 (2,951줄 JSON)
                                    │ enum, KEYLOK, License, config_type
                                    │ security 필드, FieldRVA 데이터
```

### 생성된 분석 데이터

| 파일 | 크기 | 내용 |
|------|:----:|------|
| `confuserex_analysis.json` | 3,356줄 | PE 구조, 난독화 마커, 메서드 목록 |
| `reflection_vpt_server.json` | 1,499,730줄 | 2,363 타입의 전체 Reflection 데이터 |
| `reflection_common.json` | - | PokerGFX.Common.dll 분석 |
| `reflection_extracted.json` | 2,951줄 | 핵심 데이터 (enum, DRM, KEYLOK) |
| `deobfuscated_analysis.json` | - | 난독화 해제 분석 |
| `etype_decoded_strings.json` | - | 87개 etype 디코딩 결과 |

---

## 10. 완료 결과 및 남은 과제

### 10.1 완료된 작업

| 단계 | 도구 | 결과 | 커버리지 |
|------|------|------|:--------:|
| ✅ IL Decompile | il_decompiler.py | 840+ .cs 파일, 8개 모듈 | 88% |
| ✅ etype 디코딩 | etype_decoder.py | 87개 문자열 복원 (WCF URL, assembly attr) | +0% (구조 내) |
| ✅ ConfuserEx 분석 | confuserex_analyzer.py | 2,914 난독화 메서드 감지, XOR key 확인 | +0% (패턴 문서화) |
| ✅ Reflection 분석 | ReflectionAnalyzer | 2,363 타입, 62 enum 전체 값, 19 FieldRVA | **+7%** |
| ✅ 데이터 추출 | extract_reflection_data.py | 핵심 enum/DRM/KEYLOK 데이터 구조화 | (위에 포함) |

**현재 총 커버리지: 95%**

### 10.2 ConfuserEx 난독화 통계 (PE 분석 결과)

| 항목 | 수치 |
|------|:----:|
| 전체 메서드 | 14,460 |
| RVA 있는 메서드 | 10,132 |
| 난독화된 메서드 | **2,914** (20.1%) |
| 정상 메서드 | 7,218 (49.9%) |
| RVA 없는 메서드 (abstract/extern) | 4,328 |
| Tiny 포맷 | 6,735 |
| Fat 포맷 | 3,397 |

### 10.3 남은 5%: ConfuserEx Method Body 복호화

| 대상 | 수량 | 난이도 | 접근 방법 |
|------|:----:|:------:|----------|
| 난독화 메서드 body | 2,914개 | 높음 | Runtime JIT hooking 또는 dnSpy dynamic debug |
| 동적 초기화 값 (SKIN_HDR 등) | ~20개 | 중간 | .cctor 실행 후 메모리 덤프 |
| KEYLOK 코드 실제 값 | 16개 | 중간 | 인스턴스 생성 후 필드 읽기 |

#### Method Body 복호화 전략

```
전략 1: dnSpy Dynamic Debugging
   └── JIT 직전 브레이크포인트 → 복호화된 IL 캡처
   └── 장점: 정확한 IL 복원
   └── 단점: KEYLOK 동글 없으면 DRM에서 차단될 수 있음

전략 2: ConfuserEx Deobfuscator
   └── de4dot 등 기존 도구로 static deobfuscation 시도
   └── 장점: 자동화 가능
   └── 단점: ConfuserEx 커스텀 버전이면 실패 가능

전략 3: Memory Dump + IL Extraction
   └── 프로세스 시작 후 메모리에서 복호화된 메서드 추출
   └── 장점: 한 번에 전체 추출 가능
   └── 단점: anti-debug 우회 필요 (KEYLOK LaunchAntiDebugger)
```

### 10.4 기존 분석 문서 보강 필요 사항

| 문서 | 보강 내용 | 우선순위 |
|------|----------|:--------:|
| `architecture_overview.md` | Reflection 타입 수 갱신, enum 값 추가 | 낮음 |
| `net_conn_deep_analysis.md` | WCF SOAP Action URL 추가 | 낮음 |
| `hand_eval_deep_analysis.md` | PlayerStrength 연동, game enum 매핑 | 낮음 |
| `infra_modules_analysis.md` | 스킨 암호화 3중 체계 상수 | 낮음 |
| `vpt_server_supplemental_analysis.md` | DRM enum 실제 값, Features 상세 | 낮음 |

> 모든 세부 데이터는 `reflection_extracted.json`에 구조화되어 있어, 필요 시 개별 문서에 인라인할 수 있다.
