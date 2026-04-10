# vpt_server.exe Supplemental Deep Analysis

**Document**: PokerGFX RFID-VPT Server - GameTypes, Features, Services, SystemMonitors, Logging
**Supplement to**: `infra_modules_analysis.md`, `architecture_overview.md`
**Analysis Date**: 2026-02-12
**Decompiler**: Custom IL Decompiler (il_decompiler.py)
**Coverage**: 이전 분석에서 누락된 vpt_server 내부 아키텍처 계층 전체

---

## Table of Contents

1. [분석 범위 및 방법론](#1-분석-범위-및-방법론)
2. [3세대 아키텍처 패턴](#2-3세대-아키텍처-패턴)
3. [GameTypes 시스템 (26 파일)](#3-gametypes-시스템-26-파일)
4. [Features 시스템 (56 파일)](#4-features-시스템-56-파일)
5. [Root Services 계층 (14 파일)](#5-root-services-계층-14-파일)
6. [SystemMonitors (5 파일)](#6-systemmonitors-5-파일)
7. [Logging 시스템 (4 파일)](#7-logging-시스템-4-파일)
8. [루트 레벨 클래스 보완 분석](#8-루트-레벨-클래스-보완-분석)
9. [Element 클래스 카탈로그](#9-element-클래스-카탈로그)
10. [Enum 및 Data Types 카탈로그](#10-enum-및-data-types-카탈로그)
11. [보안 분석 보완](#11-보안-분석-보완)
12. [전체 의존성 그래프](#12-전체-의존성-그래프)

---

## 1. 분석 범위 및 방법론

### 이전 분석 대비 변경

| 항목 | 이전 | 보완 후 |
|------|:----:|:------:|
| vpt_server 분석 파일 | 171 | **347** |
| 문서화된 시스템 | main_form, config, gfx, render, atem, slave, twitch | + GameTypes, Features, Services, Interfaces, SystemMonitors, Logging |
| 아키텍처 계층 | Phase 1 (God Class)만 | Phase 1 + **Phase 2 (Service Interfaces)** + **Phase 3 (DDD/CQRS)** |
| 라이선스 분석 | 미분석 | **완전 해체** (KEYLOK, LicenseType, Background Service) |
| 인증 분석 | 미분석 | **완전 해체** (Login CQRS, OfflineSession, Authentication) |

### ConfuserEx 난독화 영향

vpt_server의 많은 메서드가 ConfuserEx로 보호되어 있어, 디컴파일 결과에서 다음 패턴이 반복 관찰됨:

```
IL_0000: ldc.i8    7595413275715305912    // 상수 XOR 키
IL_0009: newobj    // 런타임 복호화 객체 생성
IL_0014: xor                              // XOR 복호화
IL_0039: switch    // 제어 흐름 난독화 (10-way switch)
```

이 패턴은 `slave.cs`, `ConfigurationPreset.cs` 등 보안 민감 클래스에서 집중적으로 나타남.

---

## 2. 3세대 아키텍처 패턴

vpt_server 코드베이스는 시간 경과에 따른 3단계 아키텍처 진화를 보여줌:

```
┌──────────────────────────────────────────────────────────────┐
│                    Phase 1: God Class (Legacy)                │
│  main_form.cs (150+ fields), config.cs, gfx.cs, render.cs   │
│  특징: 모든 로직이 WinForms 이벤트 핸들러에 집중             │
│  시기: 초기 버전                                              │
└──────────────────────────────────┬───────────────────────────┘
                                   │ 리팩토링
┌──────────────────────────────────▼───────────────────────────┐
│              Phase 2: Service Interface Layer                  │
│  GameTypes/ (26 files) + Services/ (7) + Interfaces/ (7)     │
│  특징: Interface 분리, DI 도입, 게임 로직 서비스화            │
│  시기: 중기 버전                                              │
└──────────────────────────────────┬───────────────────────────┘
                                   │ 모던화
┌──────────────────────────────────▼───────────────────────────┐
│            Phase 3: DDD + CQRS (Modern)                       │
│  Features/ (56 files) + SystemMonitors/ (5)                  │
│  특징: Feature 슬라이스, CQRS Command/Handler, FluentValid.  │
│  시기: 최신 버전 (Microsoft.Extensions.DI 기반)               │
└──────────────────────────────────────────────────────────────┘
```

### 공존 증거

- `GameType.cs`가 `ILicenseService` (Phase 3)를 필드로 참조
- `gfx.cs`가 Phase 2 인터페이스 (`IGamePlayersService` 등)를 필드로 보유
- `Program.cs`가 `IServiceProvider` (Microsoft DI)와 `Bugsnag.Client` 보유
- Phase 1 클래스들이 Phase 2 서비스를 DI로 주입받아 사용

---

## 3. GameTypes 시스템 (26 파일)

### 3.1 GameType God Class

**파일**: `GameTypes/GameType.cs`
**역할**: 게임 상태 머신의 핵심 - 한 테이블의 전체 게임 상태 관리

#### 필드 구조 (39+ 필드)

| 카테고리 | 필드명 | 타입 | 용도 |
|---------|--------|------|------|
| **데이터** | `data` | `GameTypeData` | 게임 상태 데이터 전체 (DTO) |
| **동기화** | `sync_object` | `object` | 스레드 동기화 락 |
| **RFID** | `RfidPurgeTimeout` | `TimeSpan` (static) | RFID 카드 퍼지 타임아웃 |
| **카드** | `_lastCardRevealLogTime` | `DateTime` (static) | 카드 공개 로그 스로틀링 |
| | `_lastCardRevealValue` | `card_reveal_type` (static) | 마지막 카드 공개 값 |
| | `_lastCardRevealCacheTime` | `DateTime` (static) | 카드 공개 캐시 시간 |
| | `_cardRevealCacheDuration` | `TimeSpan` (static) | 카드 공개 캐시 유효기간 |
| | `_lastBoardRevealStage` | `BoardRevealStage` | 보드 공개 단계 |
| | `_lockedBoardCards` | `Dict<int, HashSet<string>>` | 잠긴 보드 카드 |
| **상수** | `MAX_PLAYERS` | `int` (static) | 최대 플레이어 수 |
| | `MAX_BOARDS` | `int` (static) | 최대 보드 수 |
| **UI 요소** | `pl` | `PlayerElement[]` | 플레이어 그래픽 요소 배열 |
| | `brd` | `BoardElement` | 보드(커뮤니티 카드) 요소 |
| | `_blinds` | `BlindsElement` | 블라인드 표시 요소 |
| | `_history_panel` | `HistoryPanelElement` | 히스토리 패널 요소 |
| | `_chipCount` | `ChipCount` | 칩 카운트 요소 |
| **타이머** | `board_reset_timer` | `Timer` | 보드 리셋 타이머 |
| | `auto_stream_timer` | `Timer` | 자동 스트림 타이머 |
| **카메라** | `_boardCamAutoSwitchSuppressedUntilUtc` | `DateTime` | 보드 카메라 자동전환 억제 |
| | `_previousLeftPanelCam` | `int` | 이전 왼쪽 패널 카메라 |
| | `_previousRightPanelCam` | `int` | 이전 오른쪽 패널 카메라 |
| **프로퍼티** | `StartCardsPerPlayer` | `int` | 시작 카드 수/플레이어 |

#### 서비스 의존성 (10개 인터페이스)

```csharp
private IGameConfigurationService _gameConfigurationService;  // 게임 설정
private IGameVideoService _gameVideoService;                   // 비디오 관리
private IGamePlayersService _gamePlayersService;               // 플레이어 관리
private IGameCardsService _gameCardsService;                   // 카드 관리
private IGameGfxService _gameGfxService;                       // 그래픽 관리
private IGameSlaveService _gameSlaveService;                   // 슬레이브 연결
private IGameVideoLiveService _gameVideoLiveService;           // 라이브 비디오
private ITagsService _tagsService;                             // 핸드 태깅
private IHandEvaluationService _handEvaluationService;         // 핸드 평가
private ITimersService _timersService;                         // 타이머 관리
private ILicenseService _licenseService;                       // 라이선스 (Phase 3)
```

#### 메서드 시그니처

| 메서드 | 반환타입 | 용도 |
|--------|---------|------|
| `.ctor()` | void | 기본 생성자 |
| `.ctor(UserLicense)` | void | 라이선스 기반 생성자 |
| `GetPreviousHash()` | string | 이전 해시 조회 (무결성) |
| `MoveNext()` | void | 비동기 상태 머신 진행 |
| `set_SerialNumber(ulong)` | void | 시리얼 번호 설정 |
| `get_GlobalId()` | string | 글로벌 ID 조회 |
| `set_LiveHandData(bool)` | void | 라이브 핸드 데이터 활성화 |
| `set_LiveDataExport(bool)` | void | 라이브 데이터 내보내기 |
| `get_IsAuthenticated()` | bool | 인증 상태 (ConfuserEx 보호) |
| `get_IsProfessionalExpired()` | bool | Pro 라이선스 만료 확인 |
| `get_TypeString()` | string | 라이선스 타입 문자열 |

### 3.2 GameTypeData (게임 상태 DTO)

**파일**: `GameTypes/GameTypeData.cs`
**역할**: 게임의 전체 상태를 담는 직렬화 가능 데이터 객체 (78+ 필드)

#### 필드 카탈로그 (주요 카테고리별)

**게임 설정**:

| 필드명 | 타입 | 용도 |
|--------|------|------|
| `_gfxMode` | `GfxMode` (enum) | 그래픽 모드 |
| `_game_variant` | `game` | 게임 종류 (Holdem, Omaha 등) |
| `bet_structure` | `BetStructure` (enum) | 베팅 구조 |
| `_ante_type` | `AnteType` (enum) | 앤티 유형 |
| `num_boards` | `int` | 보드 수 (Run it twice 등) |
| `hand_num` | `int` | 현재 핸드 번호 |

**블라인드/베팅**:

| 필드명 | 타입 | 용도 |
|--------|------|------|
| `num_blinds` | `int` | 블라인드 수 |
| `_small` | `int` | 스몰 블라인드 금액 |
| `_big` | `int` | 빅 블라인드 금액 |
| `_third` | `int` | 서드 블라인드 (스트래들) |
| `_ante` | `int` | 앤티 금액 |
| `button_blind` | `int` | 버튼 블라인드 |
| `cap` | `int` | 베팅 캡 |
| `bomb_pot` | `int` | 봄팟 금액 |
| `seven_deuce_amt` | `int` | 7-2 사이드벳 금액 |
| `smallest_chip` | `int` | 최소 칩 단위 |
| `num_raises_this_street` | `int` | 현재 스트릿 레이즈 횟수 |
| `min_raise_amt` | `int` | 최소 레이즈 금액 |
| `_bring_in` | `int` | 브링인 (Stud) |
| `_low_limit` | `int` | 로우 리밋 |
| `_high_limit` | `int` | 하이 리밋 |
| `blind_level` | `int` | 블라인드 레벨 |

**게임 상태 플래그**:

| 필드명 | 타입 | 용도 |
|--------|------|------|
| `hand_in_progress` | `bool` | 핸드 진행 중 |
| `hand_ended` | `bool` | 핸드 종료됨 |
| `tag_hand` | `bool` | 핸드 태깅 |
| `dist_pot_req` | `bool` | 팟 분배 요청 |
| `_next_hand_ok` | `bool` | 다음 핸드 진행 가능 |
| `cum_win_done` | `bool` | 누적 승리 완료 |
| `resetting` | `bool` | 리셋 중 |
| `_chop` | `bool` | 찹(팟 분할) |
| `card_scan_warning` | `bool` | RFID 카드 스캔 경고 |
| `_enh_mode` | `bool` | 향상 모드 |
| `_dotfus_tampered` | `bool` | **난독화 변조 감지 플래그** |

**Stud/Draw 관련**:

| 필드명 | 타입 | 용도 |
|--------|------|------|
| `stud_draw_in_progress` | `bool` | 스터드/드로우 진행 중 |
| `stud_community_card` | `bool` | 스터드 커뮤니티 카드 |
| `stud_start_ok` | `bool` | 스터드 시작 가능 |
| `draws_completed` | `int` | 완료된 드로우 수 |
| `drawing_player` | `int` | 현재 드로우 중인 플레이어 |

**Run It 관련**:

| 필드명 | 타입 | 용도 |
|--------|------|------|
| `run_it_times` | `int` | Run It 횟수 |
| `run_it_times_remaining` | `int` | 남은 Run It 횟수 |
| `run_it_times_num_board_cards` | `int` | Run It 보드 카드 수 |

**플레이어 포지션**:

| 필드명 | 타입 | 용도 |
|--------|------|------|
| `action_on` | `int` | 현재 액션 플레이어 |
| `pl_dealer` | `int` | 딜러 위치 |
| `pl_small` | `int` | 스몰 블라인드 위치 |
| `pl_big` | `int` | 빅 블라인드 위치 |
| `pl_third` | `int` | 서드 위치 |
| `pl_stud_first_to_act` | `int` | 스터드 첫 액션 |
| `_first_to_act` | `int` | 첫 액션 플레이어 |
| `_first_to_act_preflop` | `int` | 프리플랍 첫 액션 |
| `_first_to_act_postflop` | `int` | 포스트플랍 첫 액션 |
| `last_bet_pl` | `int` | 마지막 베팅 플레이어 |
| `pl_buy` | `int` | 바이인 위치 |
| `starting_players` | `int` | 시작 플레이어 수 |

**NIT Game 관련**:

| 필드명 | 타입 | 용도 |
|--------|------|------|
| `nit_game_waiting_to_start` | `bool` | NIT 게임 대기 |
| `nit_winner_safe` | `bool` | NIT 승자 안전 |
| `nit_game_amt` | `int` | NIT 게임 금액 |
| `nit_display` (in ConfigPreset) | `nit_display_type` | NIT 표시 타입 |

### 3.3 BetStructure Enum

```csharp
public enum BetStructure {
    NoLimit,      // No-Limit (가장 일반적)
    FixedLimit,   // Fixed-Limit
    PotLimit      // Pot-Limit
}
```

### 3.4 AnteType Enum

```csharp
public enum AnteType {
    std_ante,      // 표준 앤티 (모든 플레이어)
    button_ante,   // 버튼 앤티 (딜러만)
    bb_ante,       // 빅블라인드 앤티
    bb_ante_bb1st, // BB 앤티 (BB 먼저)
    live_ante,     // 라이브 앤티
    tb_ante,       // Third Blind 앤티
    tb_ante_tb1st  // TB 앤티 (TB 먼저)
}
```

### 3.5 PlayerStrength

```csharp
internal class PlayerStrength {
    int Num;           // 플레이어 번호
    ulong Strength;    // 핸드 강도 (hand_eval의 ulong 값과 일치)
}
```

### 3.6 Service Interfaces (9개)

| Interface | 주요 메서드 | 역할 |
|-----------|-----------|------|
| `IGameCardsService` | `set_chip_count_bb`, `set_equity_show`, `set_secure_mode_unknown_cards_blink` | 카드 표시 설정, 에퀴티/아웃츠 |
| `IGamePlayersService` | `set_outs_pos`, `set_show_currency`, `set_cp_pl_stack`, `set_bet_disp` | 플레이어 표시 설정 |
| `IGameGfxService` | (빈 인터페이스) | 그래픽 서비스 마커 |
| `IGameVideoLiveService` | `set_Name` | 라이브 비디오 스트림 이름 |
| `IGameVideoService` | `set_Content` | 비디오 콘텐츠 설정 |
| `IGameSlaveService` | (난독화됨) | 슬레이브 통신 |
| `IHandEvaluationService` | `get_Strength` → `ulong` | 핸드 강도 조회 |
| `ITagsService` | `set__ante_type` | 핸드 태깅, 앤티 타입 설정 |
| `ITimersService` | (빈 인터페이스) | 타이머 관리 마커 |
| `IGameConfigurationService` | `set_UserType` | 사용자 타입 설정 |

### 3.7 Service Implementations (11개)

| Service | 특이사항 |
|---------|---------|
| `GameCardsService` | `get_DongleID`, `get_IsWriteAuthorized` - 동글 인증 관련 메서드 포함 |
| `GamePlayersService` | `KBLOCK()` - KEYLOK 동글 블록 연산 메서드 (IL 수준 난독화) |
| | `SetMaxUsers()`, `LEDOff()` - 동글 제어 메서드 |
| `GameConfigurationService` | **Mega 메서드**: `Fitphd()` - 150+ 파라미터 (전체 설정 적용) |
| | `get_IsReadAuthorized` - 읽기 인증 확인 |
| `HandEvaluationService` | `set_auto_stats_time` - 자동 통계 시간 설정 |
| `GameVideoLiveService` | `set_panel_logo`, `set_y_margin_top` - 라이브 비디오 UI |
| `GameGfxService` | `_gfxMode` 필드, `AuthorizeRead()` - GFX 모드 관리 |
| `GameSlaveService` | `set_trans_out_time`, `set_heads_up_custom_ypos` - 슬레이브 전환 |
| `GameVideoService` | `set_player_action_bounce` - 플레이어 액션 바운스 효과 |
| `TagsService` | `set_auto_stat_pfr`, `set_auto_stat_cumwin` - 자동 통계 설정 |
| `TimersService` | `set_ticker_stat_pfr`, `set_ticker_stat_cumwin` - 티커 통계 |

**주목할 발견**: `GamePlayersService`에 KEYLOK 동글의 `KBLOCK()` 연산이 직접 포함되어 있음. 이는 라이선스 검증이 게임 서비스와 밀접하게 결합되어 있음을 의미.

---

## 4. Features 시스템 (56 파일)

### 4.1 아키텍처 개요

```
Features/
├── Login/                          # CQRS 패턴 로그인
│   ├── ILoginHandler.cs           # Command Handler 인터페이스
│   ├── LoginHandler.cs            # Command Handler 구현
│   ├── Models/
│   │   ├── LoginCommand.cs        # CQRS Command 객체
│   │   └── LoginResult.cs         # 결과 DTO
│   ├── Validators/
│   │   └── LoginCommandValidator.cs  # FluentValidation
│   └── Configuration/
│       └── LoginConfiguration.cs  # 설정
│
└── Common/
    ├── Authentication/             # 원격 인증
    │   ├── IAuthenticationService.cs
    │   ├── AuthenticationService.cs
    │   └── Models/
    │       ├── RemoteLoginRequest.cs
    │       └── RemoteLoginResponse.cs
    │
    ├── Licensing/                  # 라이선스 관리 (28 파일)
    │   ├── ILicenseService.cs
    │   ├── LicenseService.cs
    │   ├── LicenseBackgroundService.cs
    │   ├── LicensingExtensions.cs
    │   ├── Configuration/
    │   │   └── LicenseBackgroundServiceSettings.cs
    │   ├── Enums/
    │   │   └── LicenseType.cs
    │   ├── Models/  (7개)
    │   ├── Converters/  (2개)
    │   └── Testing/  (11개)
    │
    ├── Dongle/                    # USB 동글 DRM
    │   ├── IDongleService.cs
    │   ├── DongleService.cs
    │   ├── Enums/DongleType.cs
    │   └── KEYLOK/
    │       ├── KeylokDongle.cs
    │       └── KLClientCodes.cs
    │
    ├── OfflineSession/            # 오프라인 로그인
    │   ├── IOfflineSessionService.cs
    │   ├── OfflineSessionService.cs
    │   ├── Enums/OfflineLoginStatus.cs
    │   ├── Models/  (3개)
    │   └── Configurations/
    │
    ├── IdentityInformationCache/  # 신원 정보 캐시
    │   ├── IIdentityInformationCacheService.cs
    │   ├── IdentityInformationCacheService.cs
    │   └── Models/IdentityInformation.cs
    │
    └── ConfigurationPresets/      # 설정 프리셋
        ├── IConfigurationPresetService.cs
        ├── ConfigurationPresetService.cs
        ├── ConfigurationPresetSettings.cs
        └── Models/
            ├── ConfigurationPreset.cs  (99+ 필드)
            └── Preset.cs
```

### 4.2 Login 시스템 (CQRS 패턴)

**파이프라인 흐름**:

```
LoginCommand (Email + Password + CurrentVersion)
       │
       ▼
LoginCommandValidator (FluentValidation)
       │ ← 검증 실패 시 ValidationResult 반환
       ▼
LoginHandler
       │ ← 의존성: IValidator, IOfflineSessionService, IAuthenticationService,
       │           IIdentityInformationCacheService, AppVersionValidationHandler
       ▼
LoginResult (IsSuccess + ErrorMessage + ValidationResult + VersioningResult)
```

**LoginCommand**:
```csharp
internal class LoginCommand {
    string Email;
    string Password;
    AppVersion CurrentVersion;  // PokerGFX.Common.Features.AppVersionValidation
}
```

**LoginResult**:
```csharp
internal class LoginResult {
    bool IsSuccess;
    string ErrorMessage;
    ValidationResult ValidationResult;     // FluentValidation
    VersioningResult VersioningResult;     // 앱 버전 검증 결과
}
```

**LoginHandler 의존성**:
```csharp
internal class LoginHandler {
    IValidator<LoginCommand> _validator;              // FluentValidation
    IOfflineSessionService _offlineSessionService;     // 오프라인 폴백
    IAuthenticationService _authenticationService;     // 원격 인증
    IIdentityInformationCacheService _identityCache;   // 신원 캐시
    AppVersionValidationHandler _appVersionHandler;    // 버전 검증
}
```

**LoginConfiguration**:
```csharp
internal class LoginConfiguration {
    string BaseWebsiteUrl;  // 로그인 API 기본 URL
}
```

### 4.3 Authentication 시스템

**RemoteLoginRequest**:
```csharp
internal class RemoteLoginRequest {
    string Email;
    string Password;
}
```

**RemoteLoginResponse**:
```csharp
internal class RemoteLoginResponse {
    string Token;           // 인증 토큰
    int ExpiresIn;          // 토큰 만료 시간 (초)
    string Email;           // 이메일
    string UserType;        // 사용자 유형
    string UseName;         // 사용자 이름
    int UserId;             // 사용자 ID
    Updates Updates;        // PokerGFX.Common.Features.AppVersions.Models.Updates
}
```

**AuthenticationService**:
```csharp
internal class AuthenticationService {
    object _baseApiUrl;     // 원격 API 기본 URL (난독화)
}
```

### 4.4 Licensing 시스템 (핵심)

#### LicenseType Enum

```csharp
internal enum LicenseType : byte {
    Basic,          // 기본 라이선스
    Professional,   // 프로 라이선스
    Enterprise      // 엔터프라이즈 라이선스
}
```

#### 라이선스 데이터 모델

**UserLicense**:
```csharp
internal class UserLicense {
    ulong SerialNumber;
    DateTime? ExpirationDate;
    Dictionary<LicenseType, DateTime?> Licenses;  // 타입별 만료일
}
```

**LicenseData**:
```csharp
internal class LicenseData {
    string GlobalId;     // 글로벌 고유 ID
    string Signature;    // 서명 검증
}
```

**LicenseResponse** (서버 응답):
```csharp
internal class LicenseResponse {
    ulong Serial;
    DateTime? ExpirationDate;
    LicenseType[] Licenses;    // 활성 라이선스 목록
}
```

**RemoteLicense** (원격 라이선스):
```csharp
internal class RemoteLicense {
    UserLicense License;
    bool IsValid;
    bool LiveDataExport;     // 라이브 데이터 내보내기 권한
    bool LiveHandData;       // 라이브 핸드 데이터 권한
    bool CaptureScreens;     // 화면 캡처 권한
}
```

**RemoteLicenseResponse**:
```csharp
internal class RemoteLicenseResponse {
    LicenseResponse Data;
    bool LiveHandData;
    bool LiveDataExport;
    bool CaptureScreens;
    string Signature;        // 서명 검증
    bool IsValid;
}
```

**DeviceData** (하드웨어 핑거프린트):
```csharp
internal class DeviceData {
    string DongleType;       // 동글 유형 문자열
    bool IsPresent;          // 동글 존재 여부
    ulong SerialNumber;      // 동글 시리얼 번호
    string GlobalId;         // 글로벌 ID
}
```

#### LicenseService

```csharp
internal class LicenseService {
    static DateTime BASE_DATE;        // 기준 날짜 (라이선스 계산)
    static object BLANK_LICENSE;      // 빈 라이선스 상수
    object _dongleService;            // 동글 서비스 참조
    object sessionService;            // 세션 서비스
    object apiSettings;               // API 설정 (URL 등)
    object logger;                    // 로거
    object _userAgent;                // HTTP User-Agent
    object _license;                  // 현재 라이선스
}
```

`ILicenseService` 인터페이스는 `get_AnimatedLogo()` → `Bitmap` 메서드를 노출 (라이선스 상태에 따른 로고 표시).

#### LicenseBackgroundService

```csharp
internal class LicenseBackgroundService {
    EventHandler<RemoteLicenseCheckedEventArgs> RemoteLicenseChecked;
    object licenseService;
    object logger;
    object settings;              // LicenseBackgroundServiceSettings
    object _timer;                // 주기적 체크 타이머
    bool _isRunning;
    bool _isChecking;             // 현재 체크 중
    int _retryCount;              // 재시도 횟수
    int _maxRetries;              // 최대 재시도
    bool _isForced;               // 강제 체크
}
```

**LicenseBackgroundServiceSettings**:
```csharp
internal class LicenseBackgroundServiceSettings {
    TimeSpan CheckInterval;       // 라이선스 체크 주기
}
```

#### 라이선스 검증 흐름

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  앱 시작     │────▶│ LicenseService   │────▶│ DongleService   │
│ Program.cs  │     │ 로컬 라이선스 조회 │     │ USB 동글 확인   │
└─────────────┘     └────────┬─────────┘     └────────┬────────┘
                             │                         │
                    ┌────────▼─────────┐     ┌────────▼────────┐
                    │ Background       │     │ KEYLOK API      │
                    │ Service 시작     │     │ P/Invoke 호출   │
                    └────────┬─────────┘     └─────────────────┘
                             │
                    ┌────────▼─────────────┐
                    │ Remote License Check │
                    │ (주기적 HTTP 호출)    │
                    │ → DeviceData 전송    │
                    │ ← RemoteLicenseResp  │
                    └────────┬─────────────┘
                             │
                    ┌────────▼─────────┐
                    │ RemoteLicenseChecked │
                    │ 이벤트 발생          │
                    │ → 라이선스 갱신      │
                    └──────────────────────┘
```

#### Testing 클래스 (11개 시나리오)

| 테스트 클래스 | 검증 시나리오 |
|-------------|-------------|
| `TestLicenseBase` | 테스트 기반 클래스 (공통 설정) |
| `TestBasic` | Basic 라이선스 기본 검증 |
| `TestBasicExpirationWarning` | Basic 만료 경고 |
| `TestPro` | Professional 라이선스 검증 |
| `TestProActivating` | Pro 활성화 과정 |
| `TestProExpiring` | Pro 만료 임박 |
| `TestProExpired` | Pro 만료됨 |
| `TestEnterprise` | Enterprise 라이선스 검증 |
| `TestEnterpriseActivating` | Enterprise 활성화 |
| `TestEnterpriseExpiring` | Enterprise 만료 임박 |
| `TestEnterpriseExpired` | Enterprise 만료됨 |
| `TestLicenseUpdate` | 라이선스 업데이트 |

### 4.5 Dongle DRM 시스템

#### DongleType Enum

```csharp
internal enum DongleType : byte {
    Unknown,    // 알 수 없음
    Fortress,   // Fortress 동글 (구형)
    Keylok3,    // KEYLOK 3세대
    Keylok2     // KEYLOK 2세대
}
```

#### DongleService

```csharp
internal class DongleService {
    DongleType Type;
    string DongleID;
    ulong SerialNumber;
    bool IsPresent;           // 동글 물리적 존재
    bool IsReadAuthorized;    // 읽기 인증됨
    bool IsWriteAuthorized;   // 쓰기 인증됨
}
```

#### KeylokDongle (KEYLOK API 래퍼)

**상수 및 코드** (47+ 필드):

```csharp
internal class KeylokDongle {
    // Anti-Debug
    static ushort LaunchAntiDebugger;
    static uint MaxSNSupported;

    // 인증 코드 (Validate)
    static ushort ValidateCode1, ValidateCode2, ValidateCode3;

    // 클라이언트 ID 코드
    static ushort ClientIDCode1, ClientIDCode2;

    // 읽기/쓰기 코드
    static ushort ReadCode1, ReadCode2, ReadCode3;
    static ushort WriteCode1, WriteCode2, WriteCode3;

    // 반환값
    static ulong ReturnValue;
    static int ReturnValue1, ReturnValue2;
    static int DongleType;

    // KEYLOK API 명령 상수
    static int TERMINATE;           // 동글 세션 종료
    static int KLCHECK;             // 동글 존재 확인
    static int READAUTH;            // 읽기 인증
    static int GETSN;               // 시리얼 번호 조회
    static int GETVARWORD;          // 변수 워드 읽기
    static int WRITEAUTH;           // 쓰기 인증
    static int WRITEVARWORD;        // 변수 워드 쓰기
    static int DECREMENTMEM;        // 메모리 감소 (사용 횟수)
    static int GETEXPDATE;          // 만료일 조회
    static int CKLEASEDATE;         // 임대 날짜 확인
    static int SETEXPDATE;          // 만료일 설정
    static int SETMAXUSERS;         // 최대 사용자 설정
    static int GETMAXUSERS;         // 최대 사용자 조회
    static int DOREMOTEUPDATE;      // 원격 업데이트
    static int SETLONGSN;           // 긴 시리얼 설정
    static int GETABSOLUTEMAXUSERS; // 절대 최대 사용자
    static int GETDONGLETYPE;       // 동글 타입 조회
    static int CKREALCLOCK;         // 실시간 시계 확인
    static uint READBLOCK;          // 블록 읽기
    static uint WRITEBLOCK;         // 블록 쓰기
    static short SELECTTARGETSN;    // 대상 시리얼 선택
    static int GETLONGSN;           // 긴 시리얼 조회
    static int LEDON;               // LED 켜기
    static int LEDOFF;              // LED 끄기
}
```

**DI 생성자** (발견된 핵심):
```csharp
void .ctor(
    BugsnagSettings,
    AssemblyAttributes,
    ILicenseService,
    IOfflineSessionService,
    IIdentityInformationCacheService
);
```

이는 KeylokDongle이 단순 하드웨어 래퍼가 아니라, 앱의 핵심 서비스들과 통합되어 있음을 보여줌.

#### KLClientCodes

```csharp
internal class KLClientCodes {
    // KeylokDongle과 동일한 코드 상수의 별도 복사본
    static ushort ValidateCode1, ValidateCode2, ValidateCode3;
    static ushort ClientIDCode1, ClientIDCode2;
    static ushort ReadCode1, ReadCode2, ReadCode3;
    static ushort WriteCode1, WriteCode2, WriteCode3;
    static ushort KLCheck, ReadAuth, GetSN, WriteAuth;
    static uint ReadBlock, WriteBlock;
}
```

### 4.6 OfflineSession 시스템

#### OfflineLoginStatus Enum

```csharp
internal enum OfflineLoginStatus {
    LoginSuccess,         // 오프라인 로그인 성공
    LoginFailure,         // 오프라인 로그인 실패
    CredentialsExpired,   // 저장된 인증정보 만료
    CredentialsFound,     // 인증정보 발견
    CredentialsNotFound   // 인증정보 없음
}
```

#### OfflineSessionService

```csharp
internal class OfflineSessionService {
    object _credentialsFileName;    // 인증정보 저장 파일명
    object _encryptionService;      // 암호화 서비스 (AES 추정)
}
```

#### OfflineLoginEntry (저장 구조)

```csharp
internal class OfflineLoginEntry {
    string Username;
    string Password;            // 암호화된 패스워드
    DateTime? ExpirationDate;   // 만료일
    int UserId;
    string AccessToken;         // 캐시된 액세스 토큰
}
```

#### OfflineLoginRequest / OfflineLoginResult

```csharp
internal class OfflineLoginRequest {
    string Username;
    string Password;
    string AccessToken;
    DateTime? ExpirationDate;
    int UserId;
}

internal class OfflineLoginResult {
    OfflineLoginStatus Status;
    DateTime? ExpirationDate;
    string Username;
    string Password;
    int UserId;
    string AccessToken;
}
```

#### OfflineSessionConfiguration

```csharp
internal class OfflineSessionConfiguration {
    string FileName;    // 인증정보 파일 경로
}
```

### 4.7 IdentityInformationCache

```csharp
internal class IdentityInformationCacheService {
    object AccessTokenCacheKey;
    int _minutesBeforeCacheExpires;    // 캐시 만료 분
    object _cache;                     // 인메모리 캐시
}

internal class IdentityInformation {
    string Token;
    string Usename;    // 주의: "Username"이 아닌 "Usename" (오타)
    int UserId;
}
```

### 4.8 ConfigurationPresets 시스템

#### ConfigurationPresetSettings

```csharp
internal class ConfigurationPresetSettings {
    bool UseEncryption;         // 프리셋 암호화 사용
    string Extension;           // 파일 확장자
    string SaveFilter;          // 저장 다이얼로그 필터
    string SaveTitle;           // 저장 다이얼로그 제목
    string LoadFilter;          // 로드 다이얼로그 필터
    string LoadTitle;           // 로드 다이얼로그 제목
    string DefaultFileName;     // 기본 파일명
}
```

#### ConfigurationPreset (99+ 필드 - 전체 UI 설정)

이 클래스는 그래픽 출력의 모든 설정을 포함하는 메가 DTO:

**레이아웃 설정**:
- `board_pos` (board_pos_type), `gfx_vertical`, `gfx_bottom_up`, `gfx_fit`
- `heads_up_layout_mode`, `heads_up_layout_direction`, `heads_up_custom_ypos`
- `x_margin`, `y_margin_top`, `y_margin_bot`

**표시 설정**:
- `at_show` (show_type), `fold_hide` (fold_hide_type), `fold_hide_period`
- `card_reveal` (card_reveal_type), `show_rank`, `show_seat_num`, `show_eliminated`
- `show_action_on_text`, `rabbit_hunt`, `dead_cards`, `indent_action`

**전환 효과**:
- `trans_in` (transition_type), `trans_in_time`
- `trans_out` (transition_type), `trans_out_time`

**통계 설정**:
- `auto_stats`, `auto_stats_time`, `auto_stats_first_hand`, `auto_stats_hand_interval`
- VPIP, PFR, AGR, WTSD, Position, CumWin, Payouts (각각 auto_stat_*, ticker_stat_*)

**칩 표시 정밀도** (8개):
- `cp_leaderboard`, `cp_pl_stack`, `cp_pl_action`, `cp_blinds`, `cp_pot`, `cp_twitch`, `cp_ticker`, `cp_strip`

**통화/금액**:
- `currency_symbol`, `show_currency`, `trailing_currency_symbol`, `divide_amts_by_100`

**로고**:
- `panel_logo` (byte[]), `board_logo` (byte[]), `strip_logo` (byte[])

**기타**: `vanity_text`, `game_name_in_vanity`, `media_path`, `action_clock_count`

#### Preset (메타데이터 래퍼)

```csharp
internal class Preset {
    string Name;
    string Description;
    string Author;
    DateTime CreatedAtUtc;
    object Content;      // ConfigurationPreset 직렬화 데이터
}
```

---

## 5. Root Services 계층 (14 파일)

### 5.1 Interface-Implementation 매핑

| Interface | Implementation | 주요 기능 |
|-----------|---------------|----------|
| `IVideoMixerService` | `VideoMixerService` | 비디오 믹싱, 녹화 상태 |
| `IActionTrackerService` | `ActionTrackerService` | 플레이어 액션 추적 |
| `IEffectsService` | `EffectsService` | 시각 효과 관리 |
| `IGraphicElementsService` | `GraphicElementsService` | 그래픽 요소 레지스트리 |
| `ITransmisionEncodingService` | `TransmisionEncodingService` | 출력 인코딩 |
| `IUpdatePlayerService` | `UpdatePlayerService` | 플레이어 레이아웃 |
| `IChipsService` | (미발견) | 칩 관리 |

### 5.2 상세 분석

#### VideoMixerService

```csharp
public class VideoMixerService {
    // IVideoMixerService: get_is_recording() → bool
    void UpdateNextHandFrame(TimeSpan);
}
```

mmr.dll의 비디오 파이프라인과 vpt_server 게임 로직 사이의 브리지.

#### ActionTrackerService

```csharp
public class ActionTrackerService {
    AssemblyAttributes assemblyAttributes;
    Process process;          // 외부 프로세스 참조
    bool isRunning;
    bool isInitialized;

    bool <ServerRx>b__6(game_variant_info);  // 서버 수신 핸들러
}
```

외부 프로세스(`Process`)를 사용하여 액션 추적을 수행. 가능성: 별도 분석 프로세스.

#### UpdatePlayerService (가장 복잡)

```csharp
internal class UpdatePlayerService {
    double _horizontalSpacingFactor;
    int _columnCount;
    double _verticalSpacingFactor;
    double positionY, positionX;

    // 의존성
    object _graphicElementsService;
    object _transmisionEncodingService;
    object _gamePlayersService;
    Func<bool, bool> _headsUpSplitCameraFunc;
    object _players;
    object _actionClock;
    object _gameType;
    Func<bool> _headsUpLayoutFunc;
    List<OutsElement> _outs;
    Func<int> _shownOutsCount;
    object _strip, _field, _panel, _ticker;
}
```

화면에 플레이어 위치를 계산하고 배치하는 레이아웃 엔진.

#### GfxHelper

유틸리티 클래스. 정적 메서드만 포함.

---

## 6. SystemMonitors (5 파일)

### 6.1 아키텍처

```
ISystemMonitor<T>                  // 제네릭 인터페이스
    ├── IPerformanceMonitor       // 마커 인터페이스
    │   └── PerformanceMonitor    // CPU/GPU 모니터링
    └── IStorageMonitor           // 마커 인터페이스
        └── StorageMonitor        // 디스크 모니터링
```

### 6.2 PerformanceMonitor

```csharp
public class PerformanceMonitor {
    notify_delegate _notifyCallback;
    TimeSpan _performanceTestDuration;
    PerformanceCounter _cpuPerformancefCounter;      // System.Diagnostics
    List<PerformanceCounter> _gpuPerformanceCounter;
    PhysicalGPU _physicalGPU;                         // NvAPIWrapper
    BackgroundWorker _backgroundWorker;

    float AverageCPU;
    float AverageGPU;
    bool Enabled;
    bool IsRunning;
    string GPUAdapterName;
}
```

**핵심 발견**:
- `NvAPIWrapper.GPU.PhysicalGPU` 사용 → NVIDIA GPU 전용 모니터링
- `PerformanceCounter` 기반 CPU/GPU 평균 수집
- `BackgroundWorker`로 비동기 모니터링
- GPU 어댑터 이름 추적

### 6.3 StorageMonitor

```csharp
internal class StorageMonitor {
    long _minimumSpaceGB;     // 최소 디스크 공간 (GB)
    object _timer;            // 주기적 체크 타이머
    bool IsRunning;
}
```

디스크 공간 부족 시 경고 시스템.

---

## 7. Logging 시스템 (4 파일)

### 7.1 구조

```
ILogger (빈 마커 인터페이스)
    └── DefaultLogger

BaseBugsnagService (PokerGFX.Common)
    └── BugsnagService (vpt_server 전용)

LoggingPreferences (로그 토픽 설정)
```

### 7.2 DefaultLogger

```csharp
internal class DefaultLogger {
    object _logWindow;              // 로그 윈도우 UI
    object _appVersion;             // 앱 버전
    object _logFileName;            // 로그 파일명
    object _logFilePath;            // 로그 파일 경로
    DateTime _lastErrorTime;        // 마지막 에러 시간
    object _lastErrorMessage;       // 마지막 에러 메시지
    bool _suppressLogWindow;        // 로그 윈도우 숨김
    object _fileLock;               // 파일 쓰기 락
    object _logWindowLock;          // UI 락
}
```

파일 + UI 윈도우 이중 출력 로거.

### 7.3 BugsnagService

```csharp
internal class BugsnagService : BaseBugsnagService {
    object assemblyAttributes;
    object licenseService;                    // 라이선스 정보 포함
    object offlineSessionService;             // 오프라인 세션 정보
    object identityInformationCacheService;   // 사용자 신원
    object bugsnag;                           // Bugsnag.Client
}
```

크래시 리포트에 라이선스, 세션, 사용자 정보를 자동으로 첨부.

### 7.4 LoggingPreferences

```csharp
internal class LoggingPreferences {
    static object SyncRoot;
    static Dictionary<LogTopic, bool> _cache;    // 토픽별 활성화 캐시
    static bool _initialized;
}
```

`PokerGFX.Common.Logging.LogTopic` 기반의 선택적 로깅 시스템.

---

## 8. 루트 레벨 클래스 보완 분석

### 8.1 Program (엔트리포인트)

```csharp
internal class Program {
    static IServiceProvider ServiceProvider;          // Microsoft DI
    static IConfiguration Configuration;               // Microsoft Configuration
    static Bugsnag.Client Bugsnag;                     // Bugsnag 글로벌
}
```

**핵심 발견**: Microsoft.Extensions.DependencyInjection + Microsoft.Extensions.Configuration 사용. 이는 .NET Core/5+ 스타일 DI 컨테이너가 WinForms 앱에 적용된 것.

### 8.2 slave (슬레이브 모드)

**34+ 필드를 가진 복잡한 클래스** (모두 `static`):

```csharp
internal class slave {
    // 연결 상태
    static bool _connected;
    static bool _authenticated;
    static bool _synced;
    static bool _passwordSent;

    // 마스터 정보
    static object _masterExtSwitcherAddress;    // ATEM 주소
    static object _masterTwitchChannel;         // Twitch 채널

    // 스킨 동기화
    static int _skinPosition;
    static int downloadSkinCrc;
    static object downloadSkinList;
    static object _slaveSkinProgress;

    // 스트리밍 상태
    static bool _isMasterStreaming;
    static bool _isAnySlaveStreaming;

    // 캐싱 (성능 최적화)
    static bool _cachedIsAnySlaveStreaming;
    static DateTime _lastSlaveStreamingCheck;
    static TimeSpan _slaveStreamingCacheDuration;
    static bool _cachedIsConnected;
    static bool _cachedIsAuthenticated;
    static DateTime _lastConnectionStatusCheck;
    static TimeSpan _connectionStatusCacheDuration;

    // 스로틀링
    static DateTime _lastGameStateUpdate;
    static TimeSpan _minUpdateInterval;
    static DateTime _lastHandLogUpdate;
    static DateTime _lastGameLogUpdate;
    static TimeSpan _minLogUpdateInterval;
    static DateTime _lastGraphicsRefresh;
    static TimeSpan _graphicsRefreshThrottle;
}
```

**ConfuserEx 보호**: slave의 메서드 대부분이 `ldc.i8 7595413275715305912` + XOR + 10-way switch 패턴으로 보호됨.

### 8.3 LiveApi

```csharp
internal class LiveApi {
    static object _remoteTcp;       // 원격 TCP 클라이언트
    static object _listenTcp;       // TCP 리스너
    static object _stream;          // 네트워크 스트림
    static object keepaliveTimer;   // Keepalive 타이머
    static int KEEPALIVE_INTERVAL;  // Keepalive 간격
    static object prev_tx_s;        // 이전 송신 문자열
    static bool enabled;            // 활성화 상태
}
```

실시간 데이터 스트리밍을 위한 TCP 서버/클라이언트 (live_export와 연관).

### 8.4 pipcap (PIP 캡처)

```csharp
public class pipcap {
    ulong licenseNum;
    Timer poll_timer;
    Timer show_timer;
    net_conn.client_obj client;       // net_conn 클라이언트 사용

    bool _show, _connected, _auto_centre;
    double _src_x, _src_y, _src_w, _src_h;    // 소스 영역
    double _dest_h, _dest_x, _dest_y;         // 대상 위치
    double _alpha;                              // 투명도
    int _interval, _max_time;                   // 타이밍
    int border_size;
    Color border_col;

    object tx_sync_object, rx_sync_object;      // 송수신 동기화
    remote_screen_delegate remote_screen;        // 원격 스크린 델리게이트
    GfxMode _gfxMode;
}
```

다른 VPT Server 인스턴스의 화면을 PIP로 표시하는 시스템. `net_conn.client_obj`를 사용하여 원격 서버에 연결.

### 8.5 VPTWebsiteService

```csharp
internal class VPTWebsiteService {
    static object encoded_cert;    // 인코딩된 인증서
    static object endpoint;        // WCF 엔드포인트
    static object binding;         // WCF 바인딩
}
```

WCF (Windows Communication Foundation) 기반의 웹서비스 클라이언트.

### 8.6 live_export

```csharp
internal class live_export {
    static bool event_timestamps;    // 이벤트 타임스탬프 활성화
}
```

---

## 9. Element 클래스 카탈로그

### 그래픽 요소 (UI 컴포넌트)

| Element | 파일 | 역할 |
|---------|------|------|
| `PlayerElement` | PlayerElement.cs | 플레이어 이름, 칩, 카드 표시 |
| `BoardElement` | BoardElement.cs | 커뮤니티 카드 표시 |
| `BlindsElement` | BlindsElement.cs | 블라인드 레벨 표시 |
| `HistoryPanelElement` | HistoryPanelElement.cs | 핸드 히스토리 패널 |
| `ChipCount` | ChipCount.cs | 칩 카운트 표시 |
| `FieldElement` | FieldElement.cs | 필드 (보드 영역) |
| `Panel` | Panel.cs | 통계 패널 |
| `Strip` | Strip.cs | 하단 스트립 (플레이어 순위) |
| `TickerElement` | TickerElement.cs | 스크롤 티커 |
| `OutsElement` | OutsElement.cs | 아웃츠 표시 |
| `ActionClockElement` | ActionClockElement.cs | 액션 타이머 |
| `SplitScreenDividerElement` | SplitScreenDividerElement.cs | 분할 화면 구분선 |
| `PanelHeaderElement` | PanelHeaderElement.cs | 패널 헤더 |
| `PanelFooterElement` | PanelFooterElement.cs | 패널 푸터 |
| `PanelRepeatElement` | PanelRepeatElement.cs | 패널 반복 행 |
| `StripLogoElement` | StripLogoElement.cs | 스트립 로고 |
| `StripRepeatElement` | StripRepeatElement.cs | 스트립 반복 요소 |
| `GraphicElement` | GraphicElement.cs | 기본 그래픽 요소 (추상) |

### 애니메이션 클래스

| Animation | 역할 |
|-----------|------|
| `AnimationState` | 애니메이션 상태 머신 |
| `BoardCardAnimation` | 보드 카드 등장 애니메이션 |
| `CardBlinkAnimation` | 카드 깜빡임 (하이라이트) |
| `CardUnhiliteAnimation` | 카드 하이라이트 해제 |
| `FlagHideAnimation` | 플래그(국기) 숨김 |
| `GlintBounceAnimation` | 반짝임 + 바운스 |
| `OutsCardAnimation` | 아웃츠 카드 애니메이션 |
| `PanelImageAnimation` | 패널 이미지 전환 |
| `PanelTextAnimation` | 패널 텍스트 전환 |
| `PlayerCardAnimation` | 플레이어 카드 등장 |

### Data 클래스 (Element ↔ Data 쌍)

| Element | Data Class | 용도 |
|---------|-----------|------|
| `PlayerElement` | `PlayerElementData` | 직렬화/전송용 |
| `BoardElement` | `BoardElementData` | 직렬화/전송용 |
| `BlindsElement` | `BlindsElementData` | 직렬화/전송용 |
| `HistoryPanelElement` | `HistoryPanelElementData` | 직렬화/전송용 |
| `ChipCount` | `ChipCountData` | 직렬화/전송용 |
| `GraphicElement` | `GraphicElementData` | 기본 직렬화 |

---

## 10. Enum 및 Data Types 카탈로그

### ConfigurationPreset에서 발견된 Enum 타입

| Enum | 사용처 | 추정 값 |
|------|--------|---------|
| `board_pos_type` | 보드 위치 | Top, Middle, Bottom |
| `show_type` | 표시 유형 | Always, OnAction, Never |
| `fold_hide_type` | 폴드 숨김 | Immediate, Delayed, Never |
| `card_reveal_type` | 카드 공개 | Manual, Auto, RFID |
| `leaderboard_pos_enum` | 리더보드 위치 | Left, Right, None |
| `transition_type` | 전환 효과 | None, Fade, Slide, Wipe |
| `heads_up_layout_mode` | 헤드업 레이아웃 | Standard, Custom |
| `heads_up_layout_direction` | 헤드업 방향 | LeftRight, TopBottom |
| `nit_display_type` | NIT 표시 | Standard, Hidden |
| `order_players_type` | 플레이어 순서 | BySeat, ByChips, ByAction |
| `equity_show_type` | 에퀴티 표시 | None, Percentage, Fraction |
| `hilite_winning_hand_type` | 승리 하이라이트 | None, Cards, Full |
| `outs_show_type` | 아웃츠 표시 | None, Count, Cards |
| `outs_pos_type` | 아웃츠 위치 | Top, Bottom, Side |
| `strip_display_type` | 스트립 표시 | Standard, Compact |
| `order_strip_type` | 스트립 정렬 | BySeat, ByChips |
| `auto_blinds_type` | 자동 블라인드 | None, OnChange, Always |
| `chipcount_precision_type` | 칩 정밀도 | Exact, Rounded, Abbreviated |
| `chipcount_disp_type` | 칩 표시 | Standard, BB, Currency |

### 기타 발견된 타입

| 타입 | 발견 위치 | 역할 |
|------|----------|------|
| `game_variant_info` | GameType, ActionTracker | 게임 변형 정보 DTO |
| `game_player_type` | gfx, GameType | 플레이어 타입 DTO |
| `_hand` | UpdatePlayerService | 핸드 데이터 |
| `state_changed_delegate` | twitch | 상태 변경 델리게이트 |
| `notify_delegate` | PerformanceMonitor | 알림 콜백 |
| `remote_screen_delegate` | pipcap | 원격 화면 콜백 |
| `download_delegate` | LoggingPreferences | 다운로드 콜백 |
| `net_conn.client_obj` | pipcap, GameConfig | 네트워크 클라이언트 객체 |
| `BoardRevealStage` | GameType | 보드 공개 단계 |
| `ItemActions` | LicenseData | 메뉴 아이템 액션 |
| `log_topic_setting` | LoggingPreferences | 로그 토픽 설정 |
| `asset_image` | slave (msgbox) | 에셋 이미지 |
| `dshow_prop` | AuthenticationService | DirectShow 프로퍼티 |

---

## 11. 보안 분석 보완

### 11.1 KEYLOK USB 동글 DRM

**위협 분석**:

| 취약점 | 심각도 | 세부사항 |
|--------|:------:|---------|
| 코드 상수 노출 | HIGH | `ValidateCode1/2/3`, `ClientIDCode1/2`, `ReadCode1/2/3` 등이 코드에 포함 |
| 정적 필드 | HIGH | 모든 KEYLOK 상수가 `static` → 메모리 패치 가능 |
| `LaunchAntiDebugger` | MEDIUM | 안티 디버깅 존재하나 정적 호출 → 패치 가능 |
| `KLClientCodes` 중복 | LOW | 동일 코드의 별도 클래스 → 일관성 공격 가능 |

### 11.2 라이선스 시스템

| 취약점 | 심각도 | 세부사항 |
|--------|:------:|---------|
| `LicenseType` byte enum | MEDIUM | 3개 값만 (Basic=0, Professional=1, Enterprise=2) → 패치 용이 |
| 오프라인 인증정보 저장 | HIGH | `_credentialsFileName`에 암호화된 인증정보 저장 → 키 추출 시 위험 |
| `_dotfus_tampered` 플래그 | HIGH | 변조 감지 플래그가 `GameTypeData`에 노출 |
| `Signature` 검증 | MEDIUM | 서명 기반 검증이지만 검증 로직 난독화 |
| Background 라이선스 체크 | LOW | 주기적 원격 검증 → 네트워크 차단 시 오프라인 모드로 폴백 |

### 11.3 ConfuserEx 난독화 패턴

**XOR 복호화 상수**: `7595413275715305912` (0x696E746572C6D538)
**switch 난독화**: 10-way switch 테이블 사용
**영향 범위**: `slave`, `ConfigurationPreset`, `Program` 등 보안 민감 클래스

### 11.4 API URL 발견

- `AuthenticationService._baseApiUrl` - 인증 API (난독화)
- `LoginConfiguration.BaseWebsiteUrl` - 웹사이트 기본 URL
- `VPTWebsiteService.endpoint` - WCF 엔드포인트
- 이전 분석에서 발견: `https://api.pokergfx.io` (analytics), `tempuri.org/Iwcf` (slave URL 패턴)

---

## 12. 전체 의존성 그래프

```
Program.cs (Entry Point)
    ├── IServiceProvider (Microsoft DI Container)
    │   ├── LoginHandler
    │   │   ├── IValidator<LoginCommand> (FluentValidation)
    │   │   ├── IAuthenticationService → AuthenticationService
    │   │   ├── IOfflineSessionService → OfflineSessionService
    │   │   ├── IIdentityInformationCacheService → IdentityInformationCacheService
    │   │   └── AppVersionValidationHandler
    │   │
    │   ├── ILicenseService → LicenseService
    │   │   ├── IDongleService → DongleService → KeylokDongle
    │   │   ├── IOfflineSessionService
    │   │   └── LicenseBackgroundService (Timer-based)
    │   │
    │   ├── GameType (게임 상태 머신)
    │   │   ├── IGameConfigurationService → GameConfigurationService
    │   │   ├── IGameCardsService → GameCardsService
    │   │   ├── IGamePlayersService → GamePlayersService
    │   │   ├── IGameGfxService → GameGfxService
    │   │   ├── IGameVideoService → GameVideoService
    │   │   ├── IGameVideoLiveService → GameVideoLiveService
    │   │   ├── IGameSlaveService → GameSlaveService
    │   │   ├── IHandEvaluationService → HandEvaluationService
    │   │   ├── ITagsService → TagsService
    │   │   ├── ITimersService → TimersService
    │   │   └── ILicenseService (cross-reference)
    │   │
    │   ├── IVideoMixerService → VideoMixerService
    │   ├── IUpdatePlayerService → UpdatePlayerService
    │   ├── IActionTrackerService → ActionTrackerService
    │   ├── IEffectsService → EffectsService
    │   ├── IGraphicElementsService → GraphicElementsService
    │   ├── ITransmisionEncodingService → TransmisionEncodingService
    │   │
    │   ├── IPerformanceMonitor → PerformanceMonitor (NvAPIWrapper)
    │   ├── IStorageMonitor → StorageMonitor
    │   │
    │   ├── ILogger → DefaultLogger
    │   └── BugsnagService (BaseBugsnagService)
    │
    ├── IConfiguration (appsettings.json)
    └── Bugsnag.Client (글로벌 크래시 리포팅)

main_form.cs (God Class - Phase 1 Legacy)
    ├── gfx (그래픽 엔진)
    │   ├── Panel, Strip, TickerElement, FieldElement, ActionClockElement
    │   ├── PlayerElement[], BoardElement, BlindsElement
    │   └── OutsElement[], SplitScreenDividerElement
    ├── render (렌더러 → mmr.dll)
    ├── config (설정 관리)
    ├── atem (ATEM 스위처)
    ├── slave (슬레이브 모드)
    ├── twitch (Twitch 채팅)
    ├── LiveApi (라이브 데이터 API)
    ├── pipcap (PIP 캡처)
    └── video, media, playback (비디오/미디어)
```

---

## 부록: 파일 목록 통계

| 디렉토리 | 파일 수 | 분석 상태 |
|----------|:------:|:--------:|
| GameTypes/ | 26 | 완료 |
| Features/Login/ | 6 | 완료 |
| Features/Common/Licensing/ | 28 | 완료 |
| Features/Common/Dongle/ | 5 | 완료 |
| Features/Common/Authentication/ | 4 | 완료 |
| Features/Common/OfflineSession/ | 7 | 완료 |
| Features/Common/ConfigurationPresets/ | 5 | 완료 |
| Features/Common/IdentityInformationCache/ | 3 | 완료 |
| Services/ | 7 | 완료 |
| Interfaces/ | 7 | 완료 |
| SystemMonitors/ | 5 | 완료 |
| Logging/ | 4 | 완료 |
| Root Elements/Animations | 28 | 카탈로그 완료 |
| Root Classes | 60+ | 핵심 6개 완료 |
| **합계** | **195+** | |
