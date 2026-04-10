# PokerGFX Server Binary Analysis Report

> **분석 대상**: `C:\Program Files\PokerGFX\Server\`
> **분석 방법**: PDB 심볼 + strings 추출 + **ILSpy 전체 디컴파일**
> **분석 일자**: 2026-02-10
> **분석 도구**: ILSpy CLI (ilspycmd v9.1.0.7988), dotnet SDK 8.0.417

## Executive Summary

PokerGFX Server의 4개 바이너리를 ILSpy로 완전 디컴파일하여 **2,877개 C# 소스 파일**을 복원했다. Server.exe는 난독화되어 있으나 키워드 기반 분석으로 핵심 로직을 추출했고, Common.dll과 ActionTracker.exe는 난독화되지 않아 클린 소스를 확보했다.

| 항목 | 값 |
|------|-----|
| **내부 프로젝트명** | VPT (Video Poker Tournament) |
| **서버 버전** | v3.71.0.0 |
| **Common 라이브러리 버전** | v3.2.985.0 |
| **소스 경로** | `C:\pgfx\source\pokergfx2.0\vpt\vpt_server\` |
| **프레임워크** | .NET (WinForms + WPF), self-contained 배포 (~355MB) |
| **그래픽 엔진** | 커스텀 네이티브 렌더러 (SkiaSharp 미사용 확인) |
| **DB** | Entity Framework 6 + SQL Server + SQLite |
| **빌드 시스템** | CI at `C:\CI_WS\Ws\274459\`, Costura.Fody (어셈블리 임베딩) |
| **난독화** | ConfuserEx/Agile.NET (Server.exe만 적용) |
| **업데이트 서버** | `https://releases.pokergfx.io/` |

### 디컴파일 결과 요약

| 바이너리 | 파일 수 | 크기 | 난독화 | 주요 발견 |
|----------|:-------:|:----:|:------:|----------|
| **PokerGFX-Server.exe** | 2,242 | 372MB | **O** | Tags.cs 7,000+ LOC (RFID 핵심), gfx.cs 8,121 LOC |
| **PokerGFX.Common.dll** | 48 | - | X | 라이선스, 인증, 동글, 암호화 클린 소스 |
| **ActionTracker.exe** | 576 | - | 부분 | core.cs 25,643 LOC, 50+ 네트워크 메시지 타입 |
| **GFXUpdater.exe** | 11 | - | X | 업데이트 서버 URL, 릴리스 메커니즘 |
| **합계** | **2,877** | | | |

---

## 1. 파일 구성

| 파일 | 크기 | 역할 |
|------|------|------|
| `PokerGFX-Server.exe` | 355MB | 메인 서버 (self-contained .NET) |
| `PokerGFX-Server.pdb` | 2.1MB | 디버그 심볼 |
| `PokerGFX.Common.dll` | 553KB | 공유 라이브러리 |
| `ActionTracker.exe` | 8.8MB | WPF 방송 컨트롤 앱 |
| `ActionTracker.pdb` | 230KB | ActionTracker 디버그 심볼 |
| `GFXUpdater.exe` | 56KB | 자동 업데이트 도구 |
| `Newtonsoft.Json.dll` | 695KB | JSON 직렬화 |
| `net_conn.dll.config` | 817B | EF6 설정 (SQL Server + SQLite) |

### Costura.Fody 임베디드 라이브러리

| DLL | 버전 | 크기 | 역할 |
|-----|------|------|------|
| **RFIDv2.dll** | 1.0.0.0 | 57KB | RFID 리더 드라이버 |
| **net_conn.dll** | 1.0.0.0 | 118KB | 네트워크 통신 |
| **Interop.BMDSwitcherAPI.dll** | 1.0.0.0 | 91KB | ATEM 스위처 SDK |
| **PokerGFX.Common.dll** | 3.2.985.0 | 565KB | 공유 라이브러리 |

---

## 2. RFID 서브시스템 (디컴파일 분석)

> **핵심 파일**: `Tags.cs` (7,000+ LOC), `TagsService.cs`, `ITagsService.cs`
> **EBS Phase 1 복제의 최우선 대상**

### 2.1 안테나 아키텍처

**26개 안테나** 토폴로지:

```
Antenna 0-9:   플레이어 홀 카드 (최대 10명)
Antenna 10-11: 머크 (버린 카드)
Antenna 12-15: 보드 커뮤니티 카드 (Flop, Turn, River)
Antenna 16-25: 업 카드 (Stud 게임용)
```

```csharp
public const int MAX_ANTENNAS = 26;
public const int ANT_MUCK1 = 10;
public const int ANT_MUCK2 = 11;
public const int ANT_BOARD1 = 12;  // Flop 1
public const int ANT_BOARD2 = 13;  // Flop 2
public const int ANT_BOARD3 = 14;  // Flop 3 / Turn
public const int ANT_BOARD4 = 15;  // Turn / River
public const int ANT_UPCARD1 = 16; // Stud 업 카드
```

### 2.2 초기화 흐름

```
1. InitRFID(calibrate_callback, state_change_callback, firmware_update_callback)
2. 리더 열거 → 자동 선택(1개) 또는 UI 선택(2개+)
3. 리더 인증 (READER_PWD + READER_PUBKEY)
4. SetRFIDFreq() → 안테나별 폴링 주파수 설정
5. SetRFIDDelay() → 안테나별 읽기 딜레이 설정
6. 타임아웃 설정: 529ms
```

### 2.3 인증 크레덴셜

```csharp
private static string READER_PWD = "jkhJKHG7897586jkhgfjkhg786ti7guy";  // 32자 정적 비밀번호
private static byte[] READER_PUBKEY;  // 65바이트 (EC 521-bit 또는 RSA 512-bit)
```

**보안 평가**: 하드코딩된 크레덴셜 → 벤더 종속 시스템

### 2.4 태그 감지 프로토콜

```
Reader Hardware → OnTagEvent(List<tag> diff_tags)
    ├── Lock tag_list
    ├── UID로 saved_tag 조회
    ├── tag_list[antenna] 업데이트
    ├── 이벤트 발생:
    │   ├── CardEvent (카드 감지)
    │   ├── PlayerEvent (플레이어 태그)
    │   └── UnknownEvent (미등록 태그)
    └── LiveApi.Update()
```

**태그 데이터 구조**:
```csharp
class tag { byte antenna; string uid; DateTime timestamp; bool on; }
class saved_tag { card_type type; byte card; string name; string uid; DateTime reg_dt; }
enum card_type { unknown = 0, card = 1, player = 2 }
```

### 2.5 적응형 주파수 조정

게임 상태에 따라 안테나 폴링 주파수를 동적으로 조정:
- 핸드 진행 중: 높은 주파수 (10-15)
- 비활성 시: 낮은 주파수
- 보드 안테나: 낮은 주파수 (5)
- 플레이어/머크 안테나: 높은 주파수 (10-15)

### 2.6 중복 감지

```
⚠️ "ANTENNA INSTALLATION WARNING: The reader module has detected the same physical
card on more than one antenna at the same time. This usually indicates a problem
with the physical layout of antenna cables."
```

**해결**: 여분 케이블은 각 안테나 위에 코일링 (다른 안테나 케이블과 분리)

### 2.7 리더 연결 방식

| 연결 | 설명 |
|------|------|
| USB | 기본 연결 |
| WiFi | V2 리더 지원 |
| USB+WiFi | 하이브리드 모드 |

**펌웨어 업데이트**: OTA 지원 (`firmware_update_delegate`)

---

## 3. 그래픽 오버레이 시스템 (디컴파일 분석)

> **핵심 파일**: `gfx.cs` (8,121 LOC), `GraphicElement.cs` (4,947 LOC), `render.cs` (2,474 LOC)

### 3.1 Element 계층 구조 (17개 타입)

```
GraphicElement (추상 베이스)
├── PlayerElement          (6,605 LOC) ← 플레이어 이름, 스택, 카드
├── BoardElement           (2,904 LOC) ← 커뮤니티 카드 (5장 x 5보드)
├── BlindsElement          ← 블라인드 레벨
├── ActionClockElement     ← 액션 타이머
├── OutsElement            ← 아웃츠 확률
├── HistoryPanelElement    ← 핸드 히스토리
├── FieldElement           ← 텍스트 필드
├── TickerElement          ← 스크롤 티커
├── SplitScreenDividerElement ← 멀티테이블 분할
├── Panel
│   ├── PanelHeaderElement
│   ├── PanelRepeatElement
│   └── PanelFooterElement
├── Strip
│   ├── StripLogoElement
│   └── StripRepeatElement
└── Effect
```

**GraphicElement 속성**:
```csharp
public float AbsoluteX, AbsoluteY;  // 화면 좌표
public float ScaleX, ScaleY;         // 크기
public float Opacity;                // 투명도
public int ZPos;                     // Z 순서
public bool IsOnScreen;              // 화면 표시 여부
public int AnimationSequence;        // 애니메이션 ID
```

### 3.2 애니메이션 시스템 (9종, State Machine 패턴)

| 애니메이션 | 대상 | 핵심 속성 |
|-----------|------|----------|
| PlayerCardAnimation | 플레이어 카드 | ScaleX, GlintX, DeltaY, CardSide |
| BoardCardAnimation | 보드 카드 | 동일 구조 |
| CardBlinkAnimation | 카드 강조 | Opacity 토글 |
| CardUnhiliteAnimation | 강조 해제 | Fade opacity |
| OutsCardAnimation | 아웃츠 | ScaleX + GlintX |
| GlintBounceAnimation | 반짝임 | Bounce 궤적 |
| PanelImageAnimation | 패널 이미지 | Glint + Fade |
| PanelTextAnimation | 패널 텍스트 | Fade in/out |
| FlagHideAnimation | 국기 | Fade + Slide |

**AnimationState 열거형**:
```csharp
enum AnimationState {
    PreStart, FadeIn, SlideUp, SlideDownRotateBack,
    RotateBack, ResetRotateBack, ResetRotateFront, Resetting,
    GlintGrow, Glint, GlintRotateFront, GlintShrink,
    SlideAndDarken, Scale, Waiting, Stop
}
```

**카드 플립 패턴**: ScaleX 1.0 → 0.0 (CardSide 전환) → 1.0 + Glint 이펙트

### 3.3 렌더링 모드

```csharp
enum GfxMode { Live, Delay, Comm }
```

| 모드 | 설명 |
|------|------|
| **Live** | 실시간 카드 공개 |
| **Delay** | 홀 카드 숨김 (방송 딜레이) |
| **Comm** | 해설자 모드 (모든 카드 표시) |

### 3.4 렌더링 엔진

**중요 발견**: SkiaSharp가 아닌 **커스텀 네이티브 렌더러** 사용 확인.

- SkiaSharp, GDI+, WPF Graphics import 없음
- 난독화된 렌더링 함수 (`O1hkUYJdHD7fspE8lLZ.kwy8H6LpV`) 호출
- 30+ 파라미터 (위치, 크기, 변환, 투명도, Z순서, 색상 보정, 애니메이션)
- DirectX 또는 OpenGL P/Invoke 추정

### 3.5 서비스 아키텍처 (DI 컨테이너)

```csharp
// gfx.cs 생성자
_graphicElementsService = serviceProvider.GetRequiredService<IGraphicElementsService>();
_gamePlayersService = serviceProvider.GetRequiredService<IGamePlayersService>();
_gameCardsService = serviceProvider.GetRequiredService<IGameCardsService>();
_gameVideoLiveService = serviceProvider.GetRequiredService<IGameVideoLiveService>();
_effectsService = serviceProvider.GetRequiredService<IEffectsService>();
_videoMixerService = serviceProvider.GetRequiredService<IVideoMixerService>();
_transmisionEncodingService = serviceProvider.GetRequiredService<ITransmisionEncodingService>();
_handEvaluationService = serviceProvider.GetRequiredService<IHandEvaluationService>();
_licenseService = serviceProvider.GetRequiredService<ILicenseService>();
```

---

## 4. 네트워크 아키텍처 (디컴파일 분석)

> **핵심 파일**: `Iwcf.cs`, `IwcfClient.cs`, `atem.cs` (2,300 LOC)

### 4.1 이중 프로토콜 설계

| 프로토콜 | 용도 | 빈도 |
|---------|------|------|
| **WCF (NetTcp)** | 설정 동기화, 라이선스, 파일 전송 | 저빈도 |
| **커스텀 TCP** | 실시간 게임 이벤트 (ActionTracker) | 고빈도 (10-100 msg/s) |

### 4.2 WCF Master-Slave 프로토콜

```csharp
[ServiceContract]
interface Iwcf {
    server_ping do_ping2(client_ping p, int token);     // Heartbeat + 상태 동기화
    byte[] get_file_block(int id, int serial, int start, int length);  // 파일 전송
    int get_saved_config_crc(int serial, int token);    // 설정 CRC 확인
    int get_saved_uid_crc(int serial, int token);       // UID 매핑 CRC
    byte[] get_card_status_block(int serial, int token); // 카드 인증 패키지
    string get_license(ulong serial);                   // 라이선스 검증
    void log(string msg, int serial, int token);        // 원격 로깅
}
```

**client_ping 구조**: `serial_number`, `machine_name`, `token`, `tampered`, 설정 CRC 등
**server_ping 구조**: 게임 상태, 플레이어 정보, 카드 데이터 등

### 4.3 ActionTracker 메시지 (50+ 타입)

**Client → Server**:

| 카테고리 | 메시지 |
|---------|--------|
| 게임 흐름 | StartHand, ResetHand, NextHand, GameClear |
| 플레이어 액션 | PlayerBet, PlayerFold, PlayerWin, PlayerCheckCall |
| 플레이어 관리 | PlayerAdd, PlayerSwap, PlayerSitOut, DeletePlayer |
| 스택/블라인드 | PlayerStack, PlayerBlind, PlayerCountry |
| 그래픽 제어 | GfxEnable, ShowStrip, PanelValue, FieldValue |
| 비디오 제어 | VideoSources, SourceMode |
| 텍스트/티커 | Ticker, TickerLoop, GameTitle, Tag |
| 특수 게임 | NitGame, Payout, Chop, MissDeal, RunItTimes |
| 카드 | CardEnter, CardClear, ForceCardScan, RegisterDeck, VerifyDeck |
| 시스템 | Auth, ReaderStatus, HeartBeat |

### 4.4 ATEM 스위처 통합

```
PokerGFX Server ─── BMDSwitcherAPI (COM) ─── Blackmagic ATEM (Port 9910)
     │
     ├── SwitcherMonitor (연결/해제 감지)
     ├── MixEffectBlockMonitor (Program/Preview 변경)
     └── InputMonitor (입력 상태 변경)
```

**가상 카메라 매핑**: `ATEM Input N → ATEM_VIRT_N`
**Graceful Degradation**: ATEM 미연결 시 핵심 기능 유지

### 4.5 전체 네트워크 토폴로지

```
┌──────────────┐     커스텀 TCP     ┌──────────────────────┐
│ ActionTracker │────────────────────│   PokerGFX Server    │
│  (원격 제어)  │    50+ msg types   │     (Master)         │
└──────────────┘                    │                      │
                                    │  WCF NetTcp          │
                    ┌───────────────│  Slave 동기화        │
                    │               │                      │
              ┌─────▼──────┐        │  BMDSwitcherAPI      │
              │ Slave Server│       │  ATEM 제어           │
              └────────────┘        └──────────────────────┘
                                              │
                                    ┌─────────▼──────────┐
                                    │  Blackmagic ATEM    │
                                    │  Video Switcher     │
                                    └────────────────────┘
```

---

## 5. 게임 로직 + 라이선스 (디컴파일 분석)

> **핵심 파일**: `GameCardsService.cs` (2,033 LOC), `HandEvaluationService.cs`, `LicenseService.cs`

### 5.1 카드 관리

**카드 문자열 형식**: `{Rank}{Suit}` (예: `As`, `Kh`, `7c`, `Td`)
- Ranks: `2-9`, `T`(10), `J`, `Q`, `K`, `A`
- Suits: `c`(clubs), `d`(diamonds), `h`(hearts), `s`(spades)

```csharp
// GameCardsService 주요 메서드
void AddCardsToPlayer(PlayerElement player, string cardsToAdd);
void RemoveCardsFromPlayer(PlayerElement player, string cardsToRemove);
int NumberOfCards(byte antenna);
string GetCard(byte antenna, byte index);
void Purge(int antenna);
bool ForceClearAllTags(TimeSpan timeout);
int PlayerAntennasWithCards(int maxPlayers);
```

### 5.2 핸드 평가

```csharp
// HandEvaluationService - 외부 네이티브 프록시로 위임
interface IHandEvaluationService {
    HandRank Evaluate(string[] cards);
}

// HandEvalServiceProxy - P/Invoke로 네이티브 라이브러리 호출
class HandEvalServiceProxy : IHandEvaluationService { ... }
```

**중요**: 핸드 평가 알고리즘은 네이티브 바이너리에 숨겨져 있어 직접 복제 불가 → 오픈소스 대체 필요

### 5.3 라이선스 3계층

| 등급 | 값 | 포함 관계 |
|------|:--:|----------|
| **Basic** | 1 | 기본 기능 |
| **Professional** | 3 | Basic 포함 |
| **Enterprise** | 5 | Pro + Basic 포함 |

**DRM 보호 레이어**:

| 레이어 | 기술 | 우회 난이도 |
|--------|------|:----------:|
| 하드웨어 | KEYLOK USB 동글 (KL2DLL64.DLL) | 매우 높음 |
| 펌웨어 | 동글 내부 메모리 읽기/쓰기 | 매우 높음 |
| 네트워크 | 원격 라이선스 서버 (RSA 서명 검증) | 높음 |
| 코드 | ConfuserEx/Agile.NET 난독화 | 보통 |

**KEYLOK P/Invoke**:
```csharp
[DllImport("KL2DLL64.DLL")] static extern uint KFUNC(int, int, int, int);
[DllImport("KL2DLL64.DLL")] static extern uint KBLOCK(uint, uint, uint, ushort[]);
[DllImport("KL2DLL64.DLL")] public static extern void KGETGUSN(IntPtr);
```

### 5.4 오프라인 세션

`OfflineSessionService`: 라이선스 서버 미연결 시 Grace Period 동안 운영 가능

---

## 6. ActionTracker 전체 분석 (디컴파일)

> **핵심 파일**: `core.cs` (25,643 LOC), `ClientNetworkService.cs` (~6,400 LOC)

### 6.1 역할

ActionTracker는 **방송 컨트롤 앱**:
- 서버에서 실시간 게임 데이터 수신
- 디렉터가 카메라/오버레이 제어
- 서버로 액션 커맨드 전송 (수동 오버라이드)
- 그래픽 자체 생성 안 함 (서버가 생성)

### 6.2 핵심 구조

| 파일 | LOC | 역할 |
|------|:---:|------|
| core.cs | 25,643 | 게임 상태 관리, 네트워크 이벤트 처리 |
| comm.cs | 3,821 | 네트워크 연결 설정 UI |
| director_win.cs | 2,344 | 카메라/비디오 소스 관리 (8소스) |
| payout_win.cs | 1,389 | 토너먼트 페이아웃 설정 |
| Window1.cs | 1,356 | 메인 윈도우 (800x532 캔버스) |
| camera.cs | 474 | WPFMediaKit 카메라 제어 |

### 6.3 게임 상태 (core.cs 핵심 정적 필드)

```csharp
// 게임 타입
public static int game_class;  // 0=Flop, 1=Draw, 2=Stud
public static bool hand_in_progress;
public static int hand_count;

// 포지션
public static int pl_dealer, pl_small, pl_big, pl_third;
public static int action_on;

// 블라인드/앤티
public static int ante, button_blind, cap;
public static int small, big, third;
public static int bring_in;

// 카드
public static int _cards_per_player;
public static int _extra_cards_per_player;

// 디스플레이
public static panel_type show_panel;
public static strip_display_type strip_display;
public static bool enh_mode;

// RFID
public static ReaderState _reader_state;
```

### 6.4 네트워크 이벤트 핸들러

**Server → ActionTracker (수신)**:
- `OnGameInfoReceived` - 실시간 게임 상태
- `OnDelayedGameInfoReceived` - 딜레이 방송 데이터
- `OnPlayerInfoReceived` - 플레이어 업데이트
- `OnReaderStatusReceived` - RFID 리더 상태
- `OnVideoSourcesReceived` - 카메라/비디오 소스
- 총 14개 이벤트 핸들러

### 6.5 특수 기능

| 기능 | 설명 |
|------|------|
| **NIT Game** | Not In Tournament 사이드 게임 추적 |
| **Delayed Audio** | 부정행위 방지 방송 딜레이 |
| **Run It Twice** | 보드 멀티 런 |
| **Kiosk Mode** | `/kiosk` 잠금 모드 |
| **Touch UI** | `touch_form` 커스텀 터치 프레임워크 |

---

## 7. GFXUpdater 분석 (디컴파일)

> **파일**: 11개 C# 파일 (클린 소스)

### 7.1 업데이트 서버

```
Development: https://releases.pokergfx.io/development/latest.json
Production:  https://releases.pokergfx.io/production/latest.json
```

### 7.2 업데이트 메커니즘

```
1. latest.json 다운로드 (ReleaseInfo)
2. .exe 파일만 필터링
3. 각 파일 다운로드 (임시 디렉토리)
4. 버전 번호 제거 (예: App-1.2.3.exe → App.exe)
5. 실행 중인 프로세스 대기
6. 기존 파일 교체 (Delete + Move)
```

**설정**: 30분 HTTP 타임아웃, 8KB 다운로드 버퍼, 재시도 3회

---

## 8. 난독화 분석

### 8.1 적용 현황

| 바이너리 | 난독화 | 기법 |
|---------|:------:|------|
| Server.exe | **O** | 제어 흐름 + 이름 + 문자열 + 데드 코드 |
| Common.dll | **X** | 클린 네임스페이스 |
| ActionTracker.exe | **부분** | 제어 흐름 + 문자열 (클래스명은 보존) |
| GFXUpdater.exe | **X** | 완전 클린 |

### 8.2 난독화 기법

| 기법 | 예시 | 영향 |
|------|------|------|
| 제어 흐름 | `switch(num2) { case 0: ... case 1: ... }` | 로직 추적 난이도 |
| 이름 맹글링 | `kwy8H6LpV()`, `Hg2daT3SkHVxraSyDBC` | 메서드 목적 불명 |
| 문자열 암호화 | `Kusbq8F7xd8hvTfPmi.grulUC7Fy(0x5AC1822A)` | 설정값 은닉 |
| 데드 코드 | 항상 false인 조건 삽입 | 분석 방해 |

### 8.3 읽을 수 있는 부분

난독화에도 불구하고 명확한 요소:
- 안테나 상수 (`ANT_BOARD1`, `ANT_MUCK1` 등)
- 이벤트 delegate 시그니처
- 클래스/구조체 이름 (`Tags`, `saved_tag`, `tag_data`)
- 로그 메시지
- 설정 파라미터

---

## 9. EBS 복제 관점에서의 시사점

### 9.1 복제 필수 영역

| 우선순위 | 영역 | PokerGFX 구현 | EBS 전략 |
|:--------:|------|-------------|----------|
| **P0** | RFID 카드 읽기 | RFIDv2.dll (독점) + 26안테나 | 자체 개발 (JSON over Serial) |
| **P0** | 카드 관리 | GameCardsService (UID↔카드 매핑) | SQLite + WebSocket |
| **P0** | 오버레이 렌더링 | 커스텀 네이티브 렌더러 + 17 Element | Flutter + Rive |
| **P1** | 카드 애니메이션 | 9종 State Machine | Rive State Machine |
| **P1** | 핸드 평가 | 네이티브 프록시 (비공개) | 오픈소스 (PokerHandEvaluator) |
| **P2** | 네트워크 | WCF + 커스텀 TCP | WebSocket (JSON/MessagePack) |
| **P2** | 비디오 믹싱 | VideoMixerService | NDI/OBS WebSocket |
| **P3** | ATEM 통합 | BMDSwitcherAPI (COM) | OBS WebSocket API |

### 9.2 PokerGFX에서 채택할 패턴

| 패턴 | 설명 | 적용 방법 |
|------|------|----------|
| **26안테나 토폴로지** | 검증된 레이아웃 | 동일 구조 채택 |
| **이벤트 기반 RFID** | 태그 감지 → 콜백 → 상태 갱신 | Event-Driven 아키텍처 |
| **Element 계층 구조** | 17개 GraphicElement 타입 | Flutter Widget 트리 |
| **Animation State Machine** | 16개 상태 전이 | Rive State Machine |
| **Dirty Flag 최적화** | 변경된 Element만 재렌더 | Flutter shouldRepaint |
| **서비스 DI 패턴** | 인터페이스 기반 서비스 | GetIt/Riverpod |
| **CRC 동기화** | 설정/UID 차등 동기화 | Etag/Last-Modified |
| **Dual 프로토콜** | 저빈도(설정) + 고빈도(게임) 분리 | REST + WebSocket |

### 9.3 PokerGFX에서 피할 것

| PokerGFX 방식 | EBS 개선 방향 |
|-------------|-------------|
| 하드코딩된 RFID 크레덴셜 | 펌웨어 레벨 인증 불필요 (Server-side 검증) |
| 독점 RFID 프로토콜 | 오픈 JSON/Serial 프로토콜 |
| 프레임 기반 애니메이션 | 시간 기반 (Duration) |
| 난독화된 코드 | 클린 + 문서화 |
| Windows 전용 (WinForms + COM) | Cross-platform (Flutter) |
| 하드웨어 동글 DRM | JWT 기반 라이선스 |
| Singleton + Static State | DI + Immutable State |

### 9.4 EBS RFID 프로토콜 제안

PokerGFX의 바이너리 프로토콜 대신 JSON over Serial:

```json
// MCU → Server
{ "type": "tag_detected", "antenna": 0, "uid": "E0040150A1B2C3D4", "ts": "2026-02-10T14:30:00.123Z" }
{ "type": "tag_removed", "antenna": 0, "uid": "E0040150A1B2C3D4", "ts": "2026-02-10T14:30:05.456Z" }

// Server → Flutter (WebSocket)
{ "type": "card_read", "seat": 1, "card": { "rank": "A", "suit": "s" }, "position": "hole1" }
{ "type": "board_card", "position": "flop1", "card": { "rank": "K", "suit": "h" } }
```

### 9.5 EBS 안테나 레이아웃 제안

```
Player Antennas:  0-8  (9명, WSOP 표준)
Muck Antennas:    9-10 (버린 카드)
Board Antennas:   11-15 (Flop x3, Turn, River)
Reserved:         16-25 (Stud/확장)
```

---

## 10. 미확인 사항

난독화 및 독점 컴포넌트로 인한 미확인 영역:

| 항목 | 상태 | 대안 |
|------|------|------|
| RFID 바이너리 프로토콜 (바이트 레벨) | 난독화 | USB 패킷 캡처 |
| 데이터 전송 암호화 여부 | 불명 | 네트워크 스니핑 |
| 리더 하드웨어 IC 칩 종류 | 불명 | 하드웨어 분해 |
| RF 주파수 (13.56MHz vs 125kHz) | 불명 | 스펙 문의 |
| 안테나 유효 읽기 거리 | 불명 | 실측 테스트 |
| 안티콜리전 메커니즘 | 불명 | 리더 SDK 확인 |
| 태그 타입 (Passive/Active) | 불명 | 물리 분석 |

---

## 변경 이력

| 버전 | 일자 | 내용 |
|------|------|------|
| 1.0.0 | 2026-02-10 | 초기 분석 (PDB + strings) |
| **2.0.0** | **2026-02-10** | **ILSpy 전체 디컴파일 (2,877 파일), 5개 서브시스템 심층 분석** |

---
**Version**: 2.0.0 | **Updated**: 2026-02-10
