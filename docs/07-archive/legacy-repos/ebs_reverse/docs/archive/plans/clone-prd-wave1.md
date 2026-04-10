# Clone PRD: PokerGFX 라이브 포커 방송 그래픽 시스템

**Product Requirements Document - Clone Edition**
**Version**: 1.0.0
**Date**: 2026-02-13
**참조 원본**: PokerGFX Server (RFID-VPT) v3.2.985.0

---

## 0. 복제 프로젝트 개요

### 0.1 프로젝트 목표

PokerGFX RFID-VPT Server v3.2.985.0을 참조 구현으로 삼아 동등 기능의 라이브 포커 방송 그래픽 시스템을 개발한다. 원본 시스템의 전체 기능을 재현하되, 다음 세 가지 방향으로 차별화한다:

- **현대적 프레임워크 채택**: .NET Framework 4.x에서 .NET 8+ LTS로 전환하여 크로스 플랫폼 지원, 성능 향상, 장기 지원을 확보한다
- **보안 취약점 제거**: 하드코딩된 암호화 키, AWS 자격증명, 고정 IV 등 원본의 보안 문제를 근본적으로 해결한다
- **테스트 기반 품질 보증**: 원본에 존재하지 않는 자동화 테스트 체계를 처음부터 구축한다

### 0.2 원본 시스템 요약

| 속성 | 값 |
|------|-----|
| **제품명** | PokerGFX Server (내부명: RFID-VPT) |
| **버전** | v3.2.985.0 |
| **플랫폼** | Windows, .NET Framework 4.x, WinForms |
| **바이너리 크기** | 355MB (60개 내장 DLL, Costura.Fody 패키징) |
| **규모** | TypeDef 2,602개, MethodDef 14,460개, Field 6,793개 |
| **모듈 수** | 8개 핵심 모듈 (vpt_server.exe + 7개 DLL) |
| **개발사** | PokerGFX LLC |
| **도메인** | `pokergfx.io`, `videopokertable.net` |

### 0.3 기술 스택 선정

| 영역 | 원본 기술 | 목표 기술 | 근거 |
|------|----------|----------|------|
| 프레임워크 | .NET Framework 4.x | .NET 8+ | LTS, 크로스 플랫폼, 성능 |
| UI | WinForms (43+ Forms) | WPF 또는 Avalonia | MVVM, 현대적 UI, 데이터 바인딩 |
| 렌더링 | SharpDX (DirectX 11) | Vortice.Windows (DirectX 12) | SharpDX deprecated, 성능 향상 |
| 비디오 | MFormats SDK (상용, CompanyID `13751`) | FFmpeg.AutoGen | 오픈소스, 라이선스 자유 |
| 네트워크 | 커스텀 TCP + WCF + CSV/JSON 이중 직렬화 | gRPC + ASP.NET Core | 현대적 RPC, 성능, 코드 생성 |
| 직렬화 | Newtonsoft.Json + CSV (`ToString()` + `string[] cmd`) | System.Text.Json + Protobuf | 성능, 내장, 타입 안전 |
| DI | MS.Extensions.DI | MS.Extensions.DI | 유지 (이미 현대적) |
| DB | EF6 + SQLite (WAL 모드) | EF Core 8 + SQLite | 성능, LINQ 개선 |
| TLS | BearSSL (C# 포팅, TLS 1.0-1.2) | System.Net.Security | .NET 내장 TLS 1.3 |
| 로깅 | 커스텀 Logger (8 LogTopic, 4 출력 채널) | Serilog + Seq | 구조화 로깅, 산업 표준 |
| 테스트 | 없음 | xUnit + FluentAssertions + Moq | TDD 필수 |
| 패키징 | Costura.Fody (60개 DLL 내장) | Single-file publish (.NET 8) | 네이티브 지원 |
| 크래시 리포팅 | Bugsnag (API Key 하드코딩) | Sentry 또는 자체 구현 | 오픈소스, 유연한 배포 |
| 모니터링 | NvAPIWrapper + PerformanceCounter | .NET Diagnostics + OpenTelemetry | 표준화, 벤더 중립 |

### 0.4 구현 Phase 로드맵

| Phase | 이름 | 핵심 모듈 | 우선순위 | 예상 기간 |
|:-----:|------|----------|:--------:|---------|
| 1 | Core Engine | 게임 엔진 + 핸드 평가 + 데이터 모델 | P0 | 4주 |
| 2 | Network | 프로토콜 스택 + Master-Slave + Skin 시스템 | P0 | 3주 |
| 3 | Rendering | GPU 파이프라인 + 그래픽 요소 + 애니메이션 | P1 | 4주 |
| 4 | Hardware | RFID + ATEM + 외부 서비스 | P2 | 3주 |
| 5 | Polish | UI + 보안 강화 + CI/CD | P3 | 2주 |

### 0.5 구현 범위 정의

#### MVP (Phase 1-2)

- GfxServer 단독 구현 (7-Application Ecosystem 중 핵심 1개)
- Texas Hold'em + Omaha (22개 게임 변형 중 2개)
- TCP 프로토콜 (Master-Slave 기본 통신)
- 기본 GPU 렌더링 (Live Canvas 단일 출력)
- 핸드 평가 엔진 전체 (Bitmask + Lookup Table 재구축)

#### Full Product (Phase 3-5)

- 22개 포커 게임 변형 전체
- 7-Application Ecosystem 전체 (ActionTracker, ActionClock, StreamDeck, Pipcap, CommentaryBooth, HandEvaluation)
- RFID 카드 리더 하드웨어 연동 (v2 Rev1/Rev2 + SkyeTek)
- ATEM 스위처 통합 (Blackmagic COM Interop)
- Dual Canvas System (Live + Delayed)
- SRT/NDI/BMD 스트리밍 프로토콜
- Twitch/YouTube 통합
- 완전한 Skin Editor + 암호화 스킨 시스템

---

## 1. 제품 정의

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

### [Clone] 1.4 구현 범위

| Phase | 구현 대상 | 비고 |
|:-----:|----------|------|
| MVP | **GfxServer** 단독 | 핵심 게임 엔진 + 렌더링 + 네트워크 |
| Phase 3 | + ActionTracker, ActionClock | 딜러 인터페이스 + 타이머 |
| Phase 4 | + StreamDeck, Pipcap, CommentaryBooth | 보조 장치 연동 |
| Full | 7개 애플리케이션 전체 | HandEvaluation은 WCF 대신 gRPC 서비스로 재설계 |

**WCF 대체 전략**: 원본의 `hand_eval_wcf` WCF 서비스는 gRPC로 재구현한다. `Iwcf` 인터페이스의 9개 메서드(`ConnectToPrimaryServer`, `SendPing`, `GetServerPing` 등)를 Protobuf 메시지로 정의한다.

---

## 2. 시스템 아키텍처

### 2.1 3세대 아키텍처

시스템은 3세대 아키텍처로 구성된다.

![3세대 아키텍처 진화](../images/mockups/architecture-3gen.png)

원본 시스템의 아키텍처는 세 세대에 걸쳐 진화했다:

- **1세대**: 모놀리식 WinForms 애플리케이션. CSV 기반 직렬화, 단일 스레드 렌더링
- **2세대**: 서비스 레이어 도입 (10개 인터페이스 + 11개 구현). JSON 직렬화 병행, DI 컨테이너 적용
- **3세대**: Features 레이어 (DDD/CQRS 패턴). Login CQRS 파이프라인, 라이선스 서비스 분리. 그러나 `main_form` God Class(329 메서드, 398 필드)가 여전히 핵심 허브 역할

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

### [Clone] 2.6 As-Is vs To-Be 아키텍처

| 영역 | As-Is (원본) | To-Be (Clone) | 변경 근거 |
|------|-------------|---------------|----------|
| **애플리케이션 구조** | God Class `main_form` (329 메서드) | Clean Architecture (4 레이어) | 단일 책임 원칙, 테스트 용이성 |
| **서비스 레이어** | 10 인터페이스 + 11 구현 (Phase 2) | Domain Services + Application Services 분리 | DDD 적용, 도메인 격리 |
| **직렬화** | CSV + JSON 이중 공존 | Protobuf (네트워크) + System.Text.Json (설정) | 단일 경로, 타입 안전 |
| **DI** | MS.Extensions.DI (v9.0 백포트) | MS.Extensions.DI (.NET 8 네이티브) | 백포트 불필요 |
| **모듈 경계** | 8개 DLL (Costura.Fody 내장) | NuGet 패키지 + 프로젝트 참조 | 빌드 시간 최적화, 독립 배포 |
| **Features** | DDD/CQRS (Login만 적용) | MediatR 기반 CQRS 전체 적용 | 일관된 패턴 |
| **구성 관리** | `appsettings.json` 내장 리소스 + 레지스트리 | `appsettings.json` 외부 + Azure Key Vault | 보안, 환경 분리 |

### [Clone] 2.7 Clean Architecture 도입 계획

```
Clone.Domain/              ← 핵심 비즈니스 로직 (엔티티, 값 객체, 도메인 서비스)
├── Entities/              GameState, Player, Hand, Card
├── ValueObjects/          CardMask, HandValue, BetAmount
├── Enums/                 GameVariant (22값), BetStructure (3값), AnteType (7값)
├── Services/              IHandEvaluator, IGameEngine
└── Events/                HandStarted, CardDealt, PlayerActed

Clone.Application/         ← 유스케이스 (CQRS Commands/Queries)
├── Commands/              StartHandCommand, DealCardCommand, PlayerBetCommand
├── Queries/               GetGameStateQuery, GetHandStrengthQuery
├── Handlers/              각 Command/Query의 Handler
└── Interfaces/            INetworkService, IRenderService, IRfidService

Clone.Infrastructure/      ← 외부 의존 구현
├── Network/               gRPC 서버/클라이언트, TCP 프로토콜
├── Rendering/             Vortice.Windows DirectX 12 파이프라인
├── Hardware/              RFID 리더, ATEM 스위처
├── Persistence/           EF Core 8 + SQLite
└── Security/              .NET 내장 TLS 1.3, AES-GCM

Clone.Presentation/        ← UI 레이어
├── ViewModels/            MVVM ViewModel (main_form 329 메서드를 30+ VM으로 분해)
├── Views/                 WPF/Avalonia XAML
└── Converters/            값 변환기
```

**main_form 분해 전략**: 원본의 `main_form`(329 메서드, 398 필드)은 다음 ViewModel으로 분해한다:

| ViewModel | 원본 탭/기능 | 예상 메서드 수 |
|-----------|------------|:------------:|
| `SourcesViewModel` | `tab_sources` (카메라/비디오 소스) | ~25 |
| `OutputsViewModel` | `outputsTabPage` (NDI/BMD/SRT 출력) | ~20 |
| `GraphicsViewModel` | `tab_graphics` (스킨/애니메이션) | ~30 |
| `SystemViewModel` | `tab_system` (라이선스/네트워크) | ~20 |
| `CommentaryViewModel` | `tab_commentary` (해설석) | ~15 |
| `GameStateViewModel` | 게임 상태 관리 | ~40 |
| `PlayerViewModel` | 플레이어 관리 | ~35 |
| `NetworkViewModel` | Master-Slave 통신 | ~25 |

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

### [Clone] 3.5 22개 게임 구현 우선순위

| 우선순위 | 게임 ID | 게임명 | 카테고리 | Phase | 근거 |
|:--------:|:------:|--------|---------|:-----:|------|
| **P0** | 0 | Texas Hold'em | Community Card | 1 | 가장 보편적, 핵심 엔진 검증 |
| **P0** | 4 | Omaha (4-card) | Community Card | 1 | Omaha 계열 기반, 조합 평가 검증 |
| **P0** | 5 | Omaha Hi/Lo | Community Card | 1 | Hi/Lo 로직 검증 |
| **P1** | 1 | Short Deck 6+ (S>T) | Community Card | 2 | Hold'em 변형, 랭킹 교환 로직 |
| **P1** | 2 | Short Deck 6+ (T>S) | Community Card | 2 | Dead cards 상수 `8247343964175` 적용 |
| **P1** | 3 | Pineapple | Community Card | 2 | Hold'em과 동일 평가기 사용 |
| **P1** | 6 | 5-Card Omaha | Community Card | 2 | C(52,5) = 2,598,960 조합 사전 계산 |
| **P1** | 7 | 5-Card Omaha Hi/Lo | Community Card | 2 | 5-Card + Hi/Lo 결합 |
| **P1** | 8 | 6-Card Omaha | Community Card | 2 | Memory-Mapped File 필수 (`omaha6.vpt`) |
| **P1** | 9 | 6-Card Omaha Hi/Lo | Community Card | 2 | 6-Card + Hi/Lo 결합 |
| **P2** | 10 | Courchevel | Community Card | 3 | Omaha5Evaluator 재사용 |
| **P2** | 11 | Courchevel Hi/Lo | Community Card | 3 | Courchevel + Hi/Lo |
| **P2** | 12 | 5-Card Draw | Draw | 3 | Draw 계열 기반 |
| **P2** | 13 | 2-7 Single Draw | Draw | 3 | Lowball 변형 (`seven_deuce_lowball=true`) |
| **P2** | 14 | 2-7 Triple Draw | Draw | 3 | 다중 드로우 라운드 |
| **P2** | 15 | A-5 Triple Draw | Draw | 3 | A-5 Lowball, Razz evaluator 사용 |
| **P2** | 16 | Badugi | Draw | 3 | 고유 평가 로직 (flush/pair 제거) |
| **P2** | 17 | Badeucy | Draw | 3 | Badugi evaluator 재사용 |
| **P2** | 18 | Badacey | Draw | 3 | Badugi evaluator 재사용 |
| **P3** | 19 | 7-Card Stud | Stud | 4 | Stud 계열 기반, SevenCards evaluator |
| **P3** | 20 | 7-Card Stud Hi/Lo | Stud | 4 | Stud + Hi/Lo (`lo=true`) |
| **P3** | 21 | Razz | Stud | 4 | A-5 Lowball Stud, King high 리맵 |

### [Clone] 3.6 GameTypeData 재설계 방향

원본의 `GameTypeData`(79+ 필드, 271 메서드)는 God Object 패턴이다. 다음과 같이 Record 기반 타입 안전 구조로 재설계한다:

```csharp
// As-Is: 79+ 필드가 단일 클래스에 평탄화
class GameTypeData {
    int _gfxMode;
    int _game_variant;
    int bet_structure;
    int _ante_type;
    // ... 75+ 추가 필드
}

// To-Be: 도메인별 Record로 분해
record GameConfiguration(
    GfxMode Mode,           // enum: Live=0, Delay=1, Comm=2
    GameVariant Variant,    // enum: 22값
    BetStructure Betting,   // enum: NoLimit=0, FixedLimit=1, PotLimit=2
    AnteType Ante,          // enum: 7값
    int NumBoards,
    int HandNum);

record BlindStructure(
    int SmallBlind,
    int BigBlind,
    int ThirdBlind,
    int Ante,
    int Cap,
    bool BombPot,
    int SevenDeuceAmt,
    int SmallestChip,
    int BlindLevel,
    int BringIn,
    int LowLimit,
    int HighLimit);

record GameState(
    bool HandInProgress,
    bool HandEnded,
    bool DistPotReq,
    bool NextHandOk,
    bool Chop,
    bool CardScanWarning);

record PositionState(
    int ActionOn,
    int Dealer,
    int SmallBlind,
    int BigBlind,
    int ThirdBlind,
    int FirstToAct,
    int LastBetPlayer,
    int StartingPlayers);

record RunItState(
    int Times,
    int Remaining,
    int NumBoardCards);

record StudDrawState(
    bool InProgress,
    int DrawsCompleted,
    int DrawingPlayer);
```

**마이그레이션 전략**: 기존 79+ 필드를 6개 Record로 분해하되, 네트워크 직렬화 시에는 원본과 동일한 평탄화 구조를 유지하여 호환성을 보장한다.

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

**카드 마스크 공식**: `mask |= (1UL << (rank + suit * 13))`

### 4.2 평가 알고리즘

| 평가 경로 | 알고리즘 | 대상 게임 |
|----------|----------|----------|
| **5-card** | Lookup table (O(1)) | Hold'em, Stud |
| **Omaha 4-card** | Exhaustive 조합 (C(4,2)=6) | Omaha |
| **Omaha 5/6-card** | Memory-mapped file | Omaha 5/6 |
| **Hi/Lo** | 별도 Lo evaluator | Hi/Lo 변형 |
| **Draw** | Rank-based | Draw 게임 |
| **Monte Carlo** | Threshold switching | 에퀴티 계산 |

**핵심 알고리즘 기법** (분석 문서에서 보강):

- **XOR 기반 중복 감지**: `clubs XOR diamonds XOR hearts XOR spades`로 홀수 번 등장 랭크 마스크 생성. `singles = ranks XOR (c XOR d XOR h XOR s)`로 페어 랭크 추출
- **AND 연산 Quads 감지**: `clubs AND diamonds AND hearts AND spades`로 4개 suit 모두 등장하는 랭크(Four of a Kind) 즉시 감지
- **Trips 감지**: `(c AND d) OR (h AND s) OR (c AND h) OR (d AND s)`로 3+ suit 등장 랭크 추출
- **적응형 열거**: 열거 수 > `MC_NUM` 임계값이면 전수 조사에서 Monte Carlo로 자동 전환. Hold'em: 100,000, Omaha 4/5: 10,000, Omaha 6: 1,000

### 4.3 Lookup Table 아키텍처

| 테이블 | 크기 | 용도 |
|--------|------|------|
| `nBitsTable` | 8,192 | bit count (0-13) |
| `straightTable` | 8,192 | 스트레이트 감지 |
| `topFiveCardsTable` | 8,192 | 상위 5장 선택 |
| `topCardTable` | 8,192 | 최상위 비트 랭크 |
| `m_evaluatedresults` | 8,192 | 최종 핸드 값 |
| `m_topthree` | 8,192 | 상위 3장 (SevenCards evaluator) |
| `nBitsAndStrTable` | 8,192 | bitcount + straight 결합 정보 |
| `CardMasksTable` | 52 entries | 카드→bitmask 변환 |
| `Pocket169Table` | 169 entries | 프리플롭 핸드 분류 |
| `bits` | 256 | 바이트 popcount |

**총 538개 정적 배열** (29가지 크기, 32~32,768 바이트)

**Memory-Mapped File 최적화** (분석 문서에서 보강):
- `TopTables` 클래스: `topFiveCards.bin`, `topCard.bin`을 memory-mapped file로 로드 가능
- 각 엔트리는 `uint`(4바이트) 또는 `ushort`(2바이트)로 직접 읽기
- 파일 없거나 인덱스 범위 초과 시 인메모리 배열로 fallback
- Double-checked locking으로 thread-safe lazy 초기화

### 4.4 7-Card 평가 흐름

```
Evaluate(hand: ulong) → uint:
  1. 수트별 bitmask 분리 (13-bit shifts, 0x1FFF 마스크)
     clubs(bit 0-12), diamonds(bit 13-25), hearts(bit 26-38), spades(bit 39-51)
  2. Flush 감지: nBitsTable[suit] >= 5 → Straight Flush 우선 체크 → m_evaluatedresults[suit] 반환
  3. Non-flush: 전체 랭크 OR 합산 → straightTable로 Straight 체크
  4. 중복 수(duplicates = numberOfCards - uniqueRanks)에 따라 분기:
     - 0: High Card (TopFive)
     - 1: One Pair (XOR 기반 페어 감지 + 킥커)
     - 2: Two Pair 또는 Trips (XOR + AND 조합)
     - 3+: Four of a Kind 또는 Full House (4-suit AND + 복합 판정)
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

**HandValue 인코딩**: `uint` - bits 24-27: HandType (0-8), bits 0-23: 세부 순위 (킥커 포함). 직접 `uint` 비교로 핸드 강도 판정이 가능하다.

### 4.6 핵심 API

| API | 시그니처 | 설명 |
|-----|---------|------|
| **평가** | `Evaluate(cards, numberOfCards, ignore_wheel)` → `uint` | 핸드 값 계산 |
| **파싱** | `ParseHand(hand)` → `ulong mask` | 문자열→bitmask |
| **검증** | `ValidateHand(hand)` → `bool` | 핸드 유효성 검증 |
| **서술** | `DescriptionFromHandValue(hv)` → `string` | 핸드 설명 |
| **확률** | `HandOdds(pockets, board, dead, wins, ties, losses, total)` | 승률 계산 |
| **아웃** | `Outs(player, board, opponents, dead, include_splits)` → `int` | 아웃츠 |
| **랜덤** | `RandomHands(shared, dead, ncards, trials)` → `IEnumerable<ulong>` | Monte Carlo |

**게임별 디스패처** (분석 문서에서 보강): `core.evaluate_hand(cards, board, game)` 메서드가 게임 타입 문자열에 따라 적절한 evaluator로 라우팅한다. Pineapple은 Hold'em evaluator를 그대로 사용하며, Courchevel은 Omaha5Evaluator를 재사용한다.

### 4.7 카드 표기 시스템

- **값**: `2`-`9`, `t`(10), `j`(Jack), `q`(Queen), `k`(King), `a`(Ace)
- **수트**: `c`(Clubs), `d`(Diamonds), `h`(Hearts), `s`(Spades)
- **핸드**: `AKs`(suited), `AKo`(offsuit) → PocketHand169Enum (170값, None=0 포함)
- **그룹**: GroupTypeEnum (Group1~Group8) → Sklansky 핸드 그룹핑

### 4.8 게임별 평가기

| 게임 | 평가기 클래스 | 비고 |
|------|------------|------|
| Texas Hold'em / 6-max | `Hand` | 핵심 엔진 (87 메서드, 70 필드) |
| Pineapple | `Hand` | Hold'em과 동일 평가 |
| Short Deck 6+ | `holdem_sixplus` (`trips_beats_straight` 파라미터) | Dead cards: `8247343964175`, Wheel: A-6-7-8-9 (bitmask 4336) |
| Omaha 4-card (Hi/Lo) | `OmahaEvaluator` | C(52,4) = 270,725 조합 사전 계산, Binary Search |
| Omaha 5-card (Hi/Lo) | `Omaha5Evaluator` | C(52,5) = 2,598,960 조합 인메모리 |
| Omaha 6-card (Hi/Lo) | `Omaha6Evaluator` (IDisposable, MMF 사용) | C(52,6) = 20,358,520 조합, `omaha6.vpt` MMF, 레코드 128바이트 |
| 5-Card Draw / 2-7 Draw | `draw` | `seven_deuce_lowball` 파라미터 |
| A-5 Triple Draw | `draw.a5_HandOdds` | Razz evaluator 재사용 |
| 7-Card Stud (Hi/Lo) | `stud` | SevenCards evaluator, `m_evaluatedresults[8192]` 사전 계산 |
| Razz | `Razz` (A-5 lowball) | King high 리맵 (`shl 1` + `shr 12`) |
| Badugi / Badeucy / Badacey | `Badugi` (flush/pair 제거) | Base 값: 4-card=9,007,199,254,740,992 ~ 1-card=72,057,594,037,927,936 |

### 4.9 Preflop Lookup (분석 문서에서 보강)

프리플롭(board 0장) 상황에서는 사전 계산된 fast path를 사용한다:

- `PreCalcPlayerOdds[169][9]`: 169개 canonical pocket 타입별 핸드 타입 확률 (플레이어)
- `PreCalcOppOdds[169][9]`: 169개 canonical pocket 타입별 핸드 타입 확률 (상대)
- `PocketHand169Type(cards)`로 인덱싱

### 4.10 IPokerEvaluator 인터페이스 (분석 문서에서 보강)

```csharp
interface IPokerEvaluator
{
    void Evaluate(ref ulong HiResult, ref short LowResult, ulong Hand, ulong OpenCards);
    bool IsHighLow { get; }
}
```

구현체: `SevenCards` (7-Card Stud), `Razz` (A-5 lowball), `Badugi` (4-card lowball)

### [Clone] 4.11 Bitmask 카드 표현 재현 전략

원본의 64-bit `ulong` bitmask 카드 표현을 그대로 재현한다. 이 표현은 핸드 평가 성능의 핵심이며, XOR/AND 비트 연산을 통한 O(1) 패턴 감지가 가능하다.

```csharp
// 동일한 비트 레이아웃 유지
public readonly record struct CardMask(ulong Value)
{
    public const int CLUB_OFFSET    = 0;
    public const int DIAMOND_OFFSET = 13;
    public const int HEART_OFFSET   = 26;
    public const int SPADE_OFFSET   = 39;
    public const ulong RANK_MASK    = 0x1FFF;  // 13비트

    public int Clubs    => (int)(Value & RANK_MASK);
    public int Diamonds => (int)((Value >> DIAMOND_OFFSET) & RANK_MASK);
    public int Hearts   => (int)((Value >> HEART_OFFSET) & RANK_MASK);
    public int Spades   => (int)((Value >> SPADE_OFFSET) & RANK_MASK);

    public static CardMask FromCard(int rank, int suit)
        => new(1UL << (rank + suit * 13));

    public static CardMask operator |(CardMask a, CardMask b)
        => new(a.Value | b.Value);
}
```

### [Clone] 4.12 Lookup Table 재구축 전략

538개 정적 배열을 소스 생성기(Source Generator)로 빌드 타임에 재구축한다:

| 원본 방식 | Clone 방식 | 장점 |
|----------|-----------|------|
| FieldRVA (IL 임베딩) | `[ModuleInitializer]` + `ReadOnlySpan<T>` | 메모리 최적화, GC 압력 제거 |
| `static readonly` 배열 | Source Generator 생성 | 빌드 타임 검증, 코드 생성 |
| Memory-Mapped File (TopTables) | `MemoryMappedFile` (.NET 8) | API 동일, 크로스 플랫폼 |

**538개 정적 배열 → `ReadOnlySpan<T>` 활용**:

```csharp
// As-Is: GC 힙 할당, 수정 가능
static readonly ushort[] nBitsTable = new ushort[8192] { ... };

// To-Be: 스택/데이터 영역 직접 참조, 수정 불가
static ReadOnlySpan<ushort> NBitsTable => new ushort[8192] { ... };
```

### [Clone] 4.13 Monte Carlo 가속화 전략

원본의 Monte Carlo 에퀴티 계산을 Task Parallel Library + SIMD로 가속화한다:

| 기법 | 적용 대상 | 예상 향상 |
|------|----------|----------|
| `Parallel.ForEach` (TPL) | `HandOdds()` 보드 열거 | 4-8x (코어 수) |
| `Vector<ulong>` (SIMD) | Bitmask AND/OR/XOR 연산 | 2-4x (256/512비트 레인) |
| `System.Numerics.BitOperations.PopCount` | `nBitsTable` 대체 가능 | 하드웨어 POPCNT |
| `MemoryMappedFile` + `Span<T>` | Omaha6 Binary Search | 무복사 접근 |

**P/Invoke 제거**: 원본은 `Kernel32.dll` → `QueryPerformanceCounter/Frequency`를 랜덤 시드용으로 P/Invoke 호출한다. Clone에서는 `System.Security.Cryptography.RandomNumberGenerator`로 대체한다.

---

*Clone PRD Wave 1 - 섹션 0-4 완료*
*Wave 2 (섹션 5-9), Wave 3 (섹션 10-16, 부록)은 후속 작성 예정*
