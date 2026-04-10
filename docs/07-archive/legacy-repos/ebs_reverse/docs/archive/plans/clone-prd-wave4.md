# Clone PRD Wave 4: 보안, 스레드, UI, 빌드/배포

**Scope**: 섹션 13-16 + 부록 A, B, C
**Base PRD**: `pokergfx-rfid-vpt-prd.md` v3.0.0
**Analysis Sources**: `runtime_debugging_analysis.md`, `confuserex_analysis.md`, `auxiliary_modules_analysis.md`, `infra_modules_analysis.md`

---

## 13. 보안 체계

### 13.1 4-Layer DRM System

원본 시스템은 4개의 독립 인증/라이선스 계층을 중첩 적용한다. 모든 계층이 통과해야 정상 실행된다.

![4-Layer DRM System](../images/mockups/drm-4layer.png)

```
┌─────────────────────────────────────────────────────────────┐
│ Layer 4: License 시스템 (기능 제어)                          │
│   LicenseType: Basic=1, Professional=4, Enterprise=5        │
├─────────────────────────────────────────────────────────────┤
│ Layer 3: USB 동글 - KEYLOK (하드웨어 바인딩)                 │
│   DongleType: Unknown=0, Fortress=1, Keylok3=2, Keylok2=3  │
├─────────────────────────────────────────────────────────────┤
│ Layer 2: Offline Session (네트워크 장애 대비)                │
│   로컬 자격증명 캐시 + 만료일 관리                            │
├─────────────────────────────────────────────────────────────┤
│ Layer 1: Email/Password 인증 (기본)                         │
│   RemoteLogin → Token 발급                                  │
└─────────────────────────────────────────────────────────────┘
```

### 13.2 인증 흐름

```
LoginCommand(Email, Password, CurrentVersion)
    → LoginCommandValidator (FluentValidation)
    → LoginHandler (5 deps)
    → AuthenticationService.RemoteLoginRequest(Email, Password)
    → RemoteLoginResponse {Token, ExpiresIn, Email, UserType, UseName, UserId, Updates}
    → LoginResult {IsSuccess, ErrorMessage, ValidationResult, VersioningResult}
```

### 13.3 라이선스 등급

```
LicenseType: Basic=1, Professional=4, Enterprise=5
```

| 등급 | 기능 게이트 |
|------|-----------|
| Basic | 기본 그래픽 |
| Professional | 멀티카메라, SRT |
| Enterprise | MultiGFX, LiveDataExport, CaptureScreens |

`RemoteLicense`의 3개 boolean 필드(`LiveDataExport`, `LiveHandData`, `CaptureScreens`)가 라이선스 타입에 따른 기능 게이팅을 수행한다.

### 13.4 오프라인 세션

```
OfflineLoginStatus { LoginSuccess, LoginFailure, CredentialsExpired, CredentialsFound, CredentialsNotFound }
```

```
인증 시도
    ├─ 네트워크 정상 → Layer 1 인증 → 성공 시 로컬 캐시 갱신
    └─ 네트워크 장애 → 로컬 캐시 조회
         ├─ CredentialsFound + 미만료 → LoginSuccess
         ├─ CredentialsFound + 만료   → CredentialsExpired
         └─ 캐시 없음                 → CredentialsNotFound → LoginFailure
```

### 13.5 3중 AES 암호화 시스템

| 시스템 | 모듈 | 알고리즘 | 키 유도 | 용도 |
|--------|------|---------|--------|------|
| **System 1** | net_conn.dll (enc.cs) | Rijndael AES-256 | PBKDF1 | 네트워크 통신 |
| **System 2** | PokerGFX.Common | AES-256 | Base64 직접 | 설정 데이터 |
| **System 3** | vpt_server (config) | AES | SKIN_PWD+SALT | Skin 파일 |

#### System 1: net_conn.dll 네트워크 암호화

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

#### System 2: PokerGFX.Common 설정 암호화

| 속성 | 값 |
|------|-----|
| **알고리즘** | AES-256 |
| **Key** | `"6fPz9r5pnJpUB0w0z1OeETXMwzF1jzU9g3z1Y5JzLxo="` (Base64 → 32 bytes) |
| **IV** | `new byte[16]` (Zero IV) |
| **서비스** | `IEncryptionService` → `EncryptionService(EncryptionConfiguration)` |

#### System 3: vpt_server Skin 암호화

| 속성 | 값 |
|------|-----|
| **알고리즘** | AES |
| **키 구성** | `SKIN_HDR` + `SKIN_SALT` + `SKIN_PWD` |
| **CRC 검증** | `skin_crc`로 무결성 확인 |
| **초기화** | `.cctor` 정적 생성자 (ConfuserEx 보호) |

### 13.6 코드 보호

원본 시스템은 3중 보호 체계를 적용한다.

#### ConfuserEx

| 항목 | 값 |
|------|-----|
| XOR Key | `0x6969696969696968` (7595413275715305912) |
| 복호화 상수 A | `544109938` (0x206e7572) |
| 복호화 상수 B | `542330692` (0x20534f44) |
| 난독화 메서드 | 2,914개 (전체 14,460의 20.1%) |
| Switch 분기 | 10-way dispatch (기본) |
| 보호 기능 | Method body 암호화, 제어 흐름 난독화, 문자열 암호화, etype ASCII 인코딩, Proxy delegate injection |

```
┌─────────────────────────────────────────────┐
│  Layer 1: ConfuserEx                         │
│  - Method body 암호화 (XOR + switch dispatch)│
│  - 문자열 암호화 (runtime 복호화)             │
│  - etype ASCII 인코딩                        │
│  - 제어 흐름 난독화 (junk branch injection)   │
├─────────────────────────────────────────────┤
│  Layer 2: Dotfuscator                        │
│  - 변조 탐지 (_dotfus_tampered 필드)          │
│  - tampered flag → client_ping 보고          │
├─────────────────────────────────────────────┤
│  Layer 3: KEYLOK Anti-Debugger               │
│  - LaunchAntiDebugger 필드로 디버거 탐지       │
└─────────────────────────────────────────────┘
```

#### Dotfuscator

`_dotfus_tampered` 필드가 `true`로 설정되면 `client_ping` 메시지를 통해 마스터 서버에 변조 사실이 자동 보고된다. 이 필드는 `GameTypeData` 내부에 위치하여 게임 상태와 동일 수준에서 관리된다.

#### KEYLOK Anti-Debugger

`LaunchAntiDebugger` 필드를 통해 KEYLOK USB 동글 드라이버가 디버거 탐지 기능을 수행한다. P/Invoke API 23+ 명령, `KLClientCodes` 16개 인증 코드로 구성.

### 13.7 WCF 통신

| 속성 | 값 |
|------|-----|
| Endpoint | `http://videopokertable.net/wcf.svc` |
| SOAP Action | `http://tempuri.org/Iwcf/get_file_block` |
| 인증서 | X.509 Self-signed (2019-2156) |
| 용도 | Server - Remote 라이선스 RPC |

### 13.8 보안 취약점 현황

원본 시스템에서 발견된 보안상 개선이 필요한 사항:

| 심각도 | 영역 | 세부 사항 |
|--------|------|----------|
| **CRITICAL** | 인증서 검증 | `InsecureCertValidator`가 모든 인증서를 수락 (MITM 가능) |
| **CRITICAL** | 자격증명 관리 | analytics.dll의 `AwsAccessKey`, `AwsSecretKey` 정적 필드 하드코딩 |
| **CRITICAL** | 암호화 키 | net_conn.dll, PokerGFX.Common의 AES 키가 소스에 내장 |
| **HIGH** | IV 관리 | PokerGFX.Common의 Zero IV 사용 (동일 키+평문 → 동일 암호문) |
| **HIGH** | 키 유도 | PBKDF1 (구식, 보안 강도 부족) |
| **HIGH** | TLS 버전 | boarssl.dll이 TLS 1.0/1.1 지원 (POODLE, BEAST 취약점) |
| **MEDIUM** | 암호 스위트 | RC4 cipher suite (RC4 bias 공격), 3DES cipher suite (Sweet32 공격) |
| **MEDIUM** | 스크린샷 암호화 | `EncryptFile()` 미구현 (`return false` stub) |

### 13.9 [Clone] 보안 강화 설계

복제 시스템은 원본의 보안 요구사항을 분석하여 다음과 같이 재설계한다.

#### 보안 요구사항

| # | 요구사항 | 원본 문제 | 목표 설계 |
|---|---------|----------|----------|
| 1 | 키 관리 | 모든 암호화 키 소스 내장 | 외부 Key Vault 또는 설정 파일로 이동 (하드코딩 제거) |
| 2 | 키 유도 | PBKDF1 사용 | Argon2id 또는 PBKDF2 (최소 100,000 iterations) |
| 3 | 인증서 검증 | InsecureCertValidator 존재 | 정상 CA 검증 체인 적용, System.Net.Security 사용 |
| 4 | IV 관리 | Zero IV 사용 | 매 암호화마다 `RandomNumberGenerator`로 랜덤 IV 생성 |
| 5 | 자격증명 | AWS 키 하드코딩 | IAM Role 또는 환경변수 기반 자격증명 |
| 6 | DRM | KEYLOK 하드웨어 동글 의존 | 소프트웨어 라이선스 시스템 (온라인 인증 + 오프라인 토큰) |
| 7 | 코드 보호 | ConfuserEx + Dotfuscator 난독화 | .NET 8 ReadyToRun + NativeAOT (난독화 대신 네이티브 컴파일) |

#### 4-Layer DRM → 3-Layer 재설계

KEYLOK 하드웨어 동글을 제거하고 소프트웨어 기반 라이선스로 대체한다.

| Layer | 원본 | 복제 시스템 |
|:-----:|------|-----------|
| 1 | Email/Password → Token | **Online Authentication** (JWT + Refresh Token) |
| 2 | Offline Session (캐시) | **Offline Token** (시간 제한 로컬 캐시, 서명된 JWT) |
| 3 | KEYLOK USB Dongle | ~~제거~~ |
| 4 | Remote License | **Remote License Server** (주기적 검증, gRPC 기반) |

```
┌─────────────────────────────────────────────────────────────┐
│ Layer 3: Remote License Server (주기적 검증)                 │
│   gRPC 기반, 라이선스 타입별 기능 게이팅                       │
├─────────────────────────────────────────────────────────────┤
│ Layer 2: Offline Token (시간 제한 로컬 캐시)                 │
│   서명된 JWT, 만료일 관리, 최대 7일 오프라인                   │
├─────────────────────────────────────────────────────────────┤
│ Layer 1: Online Authentication (JWT + Refresh Token)        │
│   Email/Password → Access Token + Refresh Token              │
└─────────────────────────────────────────────────────────────┘
```

#### 암호화 시스템 개선

| 시스템 | 원본 | 복제 시스템 |
|--------|------|-----------|
| 네트워크 통신 | Rijndael + PBKDF1 + 하드코딩 키 | TLS 1.3 (System.Net.Security) + AEAD (ChaCha20-Poly1305 또는 AES-GCM) |
| 설정 데이터 | AES-256 + Zero IV + 하드코딩 키 | AES-256-GCM + 랜덤 IV + Key Vault에서 키 로딩 |
| Skin 파일 | AES + SKIN_PWD/SALT | AES-256-GCM + 외부 키 설정 + CRC → HMAC-SHA256 |

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

### 14.2 동기화 메커니즘 (6종)

| 메커니즘 | 사용처 |
|---------|--------|
| `BlockingCollection<T>` | mmr frame queues (Producer-Consumer) |
| `ConcurrentQueue<T>` | sync_frames, video capture frames |
| `AutoResetEvent` | are_delay, are_audio, init_done_event |
| `ManualResetEventSlim` | sink._workerReady |
| `CancellationTokenSource` | live/delayed/write frame tokens |
| `lock` (object) | live_lock_obj, delay_lock_obj, safety_lock |

### 14.3 [Clone] 동시성 모델 개선

원본의 스레드 직접 생성 + 동기 프리미티브 패턴을 현대적 비동기 패턴으로 재설계한다.

| 원본 메커니즘 | 복제 시스템 | 개선 효과 |
|-------------|-----------|----------|
| `BlockingCollection<T>` | `Channel<T>` (Bounded/Unbounded) | 비동기 Producer-Consumer, 배압 지원 |
| `lock` (object) | `SemaphoreSlim` 또는 lock-free 구조 | async 호환, 교착 위험 감소 |
| `AutoResetEvent` | `TaskCompletionSource` | async/await 통합 |
| `ManualResetEventSlim` | `TaskCompletionSource` (재사용) | async/await 통합 |
| 스레드 직접 생성 (`new Thread`) | `Task.Run` + `async/await` | ThreadPool 활용, 리소스 효율 |
| `CancellationTokenSource` | `CancellationTokenSource` (유지) | 이미 현대적 패턴 |
| `BackgroundWorker` | `IHostedService` 또는 `PeriodicTimer` | .NET 8 표준 패턴 |
| `System.Threading.Timer` | `PeriodicTimer` + `async` | async 타이머, 중복 실행 방지 |

#### Channel 기반 프레임 파이프라인

```
[캡처 스레드] → Channel<MFFrame> → [렌더링 스레드] → Channel<MFFrame> → [녹화 스레드]
                 (Bounded, 60fps)                     (Bounded, 30fps)
```

`Channel<T>`의 `BoundedChannelOptions`로 배압을 제어하고, `ChannelReader.ReadAllAsync()`로 비동기 열거를 구현한다.

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

`main_form`은 120개 이상의 UI 컨트롤을 직접 관리하는 WinForms God Class이다. 329개 메서드와 150+ 필드가 단일 클래스에 집중되어 있으며, 그 중 296개 메서드가 ConfuserEx로 보호되어 있다.

### 15.4 [Clone] UI 프레임워크 전환

#### 프레임워크 선정

| 옵션 | 장점 | 단점 | 권장 |
|------|------|------|:----:|
| **WPF** | XAML, 풍부한 에코시스템, Windows 네이티브 | Windows 전용 | Windows 전용 배포 시 |
| **Avalonia** | 크로스플랫폼 (Win/Mac/Linux), XAML 호환 | 생태계 상대적 미성숙 | 크로스플랫폼 필요 시 |
| **MAUI** | MS 공식 크로스플랫폼 | 데스크톱 지원 미성숙 | ❌ 비권장 |

#### MVVM 패턴 적용

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│    View      │ ──► │  ViewModel   │ ──► │    Model     │
│  (XAML/UI)   │     │  (Command,   │     │  (Service,   │
│              │ ◄── │   Property)  │ ◄── │   Domain)    │
└──────────────┘     └──────────────┘     └──────────────┘
```

#### 43+ Forms → 30개 이하 View 통합

| 원본 Forms | 통합 View | 전략 |
|-----------|----------|------|
| `main_form` (God Class) | `MainView` + 탭별 `UserControl` | ViewModel 분리 |
| `skin_edit` + `gfx_edit` | `EditorView` (AvalonDock 활용) | WYSIWYG 통합 에디터 |
| `pip_edit` + `di_pip_edit` | `PipEditorView` | 단일 View로 통합 |
| `ticker_edit` + `ticker_stats_edit` + `auto_stats_edit` | `StatsEditorView` | 통계 편집 통합 |
| `reader_config` + `reader_select` | `ReaderSettingsView` | 설정 통합 |
| `cam_prev` + `cam_prop` | `CameraView` | 카메라 프리뷰/속성 통합 |
| `trial_form` + `security_warning` | `AlertDialog` (공통) | 다이얼로그 통합 |
| `ForceVersionUpdateWindow` + `SuggestVersionUpdateWindow` | `UpdateDialog` | 업데이트 통합 |

#### main_form God Class 분해

```
main_form (329 methods, 150+ fields)
    │
    ▼ MVVM 분해
    │
    ├── MainViewModel          # 탭 전환, 전역 상태
    ├── SourcesViewModel       # Sources 탭 (입력 소스)
    ├── OutputsViewModel       # Outputs 탭 (출력 디바이스)
    ├── GraphicsViewModel      # Graphics 탭 (오버레이)
    ├── SystemViewModel        # System 탭 (라이선스, 설정)
    ├── CommentaryViewModel    # Commentary 탭 (해설석)
    └── Services (DI 주입)
        ├── ILicenseService
        ├── ITagsService
        ├── IPerformanceMonitor
        └── IStorageMonitor
```

#### Skin Editor 개선

- WinForms `skin_edit` Form → WPF/Avalonia WYSIWYG 에디터
- AvalonDock으로 도킹 가능한 패널 레이아웃
- 실시간 프리뷰 (ViewModel 바인딩으로 즉시 반영)
- 그래픽 요소 위치/크기 드래그 앤 드롭

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

### 16.7 [Clone] 현대적 빌드/배포

#### CI/CD 파이프라인

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Commit    │ ──► │    Build    │ ──► │    Test     │ ──► │   Deploy    │
│  (GitHub)   │     │  (Actions)  │     │ (xUnit+E2E) │     │ (MSIX/CDN)  │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

| 항목 | 원본 | 복제 시스템 |
|------|------|-----------|
| **CI/CD** | 수동 빌드 (CI_WS) | GitHub Actions (빌드/테스트/배포 자동화) |
| **패키징** | Costura.Fody (60개 DLL 내장) | .NET 8 Single-file publish 또는 MSIX |
| **코드 보호** | ConfuserEx + Dotfuscator | .NET 8 ReadyToRun + NativeAOT |
| **업데이터** | GFXUpdater.exe (커스텀) | Squirrel.Windows 또는 MSIX auto-update |
| **컨테이너** | 없음 | Docker Windows (CI/테스트용) |

#### 텔레메트리 개선

| 원본 | 복제 시스템 |
|------|-----------|
| 커스텀 analytics.dll + SQLite + AWS S3 | OpenTelemetry SDK → Application Insights 또는 Seq |
| AWS 키 하드코딩 | Managed Identity 또는 환경변수 |
| `EncryptFile()` 미구현 stub | OpenTelemetry OTLP Exporter (자동 TLS 암호화) |
| Bugsnag 크래시 리포팅 | Sentry 또는 Application Insights Exception Tracking |

#### 로깅 개선

| 원본 | 복제 시스템 |
|------|-----------|
| 커스텀 Logger (Topic 8종, 4 채널) | Serilog + structured logging |
| FileLogger + LogWindow + remote + popup | Serilog.Sinks.File + Serilog.Sinks.Seq + UI sink |
| 8개 Topic 하드코딩 | `ILogger<T>` 카테고리 기반 (자동 Topic) |

```csharp
// Serilog 설정 예시
Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .WriteTo.File("logs/pokergfx-.log", rollingInterval: RollingInterval.Day)
    .WriteTo.Seq("http://localhost:5341")
    .Enrich.WithProperty("Application", "PokerGFX.Clone")
    .CreateLogger();
```

#### 모니터링 개선

| 원본 | 복제 시스템 |
|------|-----------|
| PerformanceMonitor (NvAPIWrapper + PerformanceCounter) | Prometheus metrics (System.Diagnostics.Metrics) |
| StorageMonitor (커스텀) | Prometheus gauge + alert rules |
| BackgroundWorker 기반 | `IHostedService` + `PeriodicTimer` |
| 로컬 모니터링만 | Grafana 대시보드 (원격 모니터링) |

#### 버전 관리 개선

| 원본 | 복제 시스템 |
|------|-----------|
| `AppVersionValidationHandler` (커스텀) | SemVer 2.0 + GitHub Releases API |
| `offline_app_versions.json` 폴백 | 로컬 캐시 + 오프라인 정책 동일 유지 |
| WCF `get_file_block` 파일 전송 | gRPC streaming 또는 CDN 다운로드 |

---

## 부록 A: 소스 디렉토리 구조

### 원본 프로젝트 구조 (참조용)

![소스 디렉토리 구조](../images/mockups/source-directory.png)

원본 소스는 `C:\pgfx\source\pokergfx2.0\vpt\vpt_server\` 경로에 위치하며, CI 빌드는 `C:\CI_WS\Ws\274459\Source\`에서 수행된다. PDB 분석 결과 50개 소스 파일 경로가 확인되었으며, Features 디렉토리는 DDD/CQRS 패턴(Phase 3 아키텍처)으로 구성되어 있다.

### [Clone] 목표 프로젝트 구조

```
PokerGFX.Clone/
├── src/
│   ├── PokerGFX.Core/              # 게임 엔진, 핸드 평가
│   │   ├── Engine/                 # GameType, BetStructure, 게임 로직
│   │   ├── HandEval/               # Bitmask 핸드 평가, Lookup Table
│   │   ├── Models/                 # Player, Hand, Event, GameTypeData
│   │   └── Enums/                  # 62+ enum 타입 정의
│   │
│   ├── PokerGFX.Network/           # 프로토콜, Master-Slave
│   │   ├── Protocol/               # 113+ 명령어, JSON 직렬화
│   │   ├── Discovery/              # UDP 서버 발견
│   │   ├── MasterSlave/            # Master-Slave 동기화
│   │   └── Security/               # AES-GCM 암호화, TLS
│   │
│   ├── PokerGFX.Rendering/         # GPU 렌더링, 그래픽 요소
│   │   ├── Pipeline/               # DirectX 12 렌더링 파이프라인
│   │   ├── Elements/               # image, text, pip, border elements
│   │   ├── Animation/              # 11개 애니메이션 클래스
│   │   ├── Skin/                   # 스킨 로딩/편집
│   │   └── Video/                  # 캡처, 인코딩, 스트리밍
│   │
│   ├── PokerGFX.Hardware/          # RFID, ATEM
│   │   ├── RFID/                   # v2 TCP/WiFi + USB 리더
│   │   ├── ATEM/                   # Blackmagic 스위처
│   │   └── Capture/                # Decklink, NDI, DirectShow
│   │
│   ├── PokerGFX.Services/          # 비즈니스 로직 서비스
│   │   ├── GameTypes/              # 10개 서비스 인터페이스
│   │   ├── Features/               # Login, License, Offline, Dongle (CQRS)
│   │   └── Integration/            # Twitch, LiveApi, Analytics
│   │
│   ├── PokerGFX.UI/                # WPF/Avalonia UI
│   │   ├── Views/                  # 30개 이하 View (XAML)
│   │   ├── ViewModels/             # MVVM ViewModel
│   │   ├── Controls/               # 커스텀 UserControl
│   │   └── Converters/             # 값 변환기
│   │
│   └── PokerGFX.Host/              # 호스트 애플리케이션
│       ├── Program.cs              # Entry Point
│       ├── Startup.cs              # DI 등록, 서비스 구성
│       └── appsettings.json        # 설정
│
├── tests/
│   ├── PokerGFX.Core.Tests/        # 게임 엔진 단위 테스트
│   ├── PokerGFX.Network.Tests/     # 프로토콜 테스트
│   ├── PokerGFX.Rendering.Tests/   # 렌더링 테스트
│   ├── PokerGFX.Services.Tests/    # 서비스 통합 테스트
│   └── PokerGFX.E2E.Tests/         # E2E 테스트 (Playwright)
│
├── docs/                           # 문서
│   ├── PRD/                        # 요구사항
│   ├── Architecture/               # 아키텍처 설계
│   └── API/                        # API 문서
│
└── tools/                          # 빌드/배포 도구
    ├── ci/                         # GitHub Actions 워크플로우
    └── scripts/                    # 빌드 스크립트
```

---

## 부록 B: 내장 DLL 목록 (60개, Costura.Fody)

### 원본 참조용

원본 시스템은 Costura.Fody로 60개 DLL을 단일 실행 파일에 내장 패키징한다.

#### 핵심 비즈니스 로직

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

#### 그래픽 파이프라인

| DLL | 크기 | 설명 |
|-----|------|------|
| SkiaSharp.dll | 747KB | 2D 그래픽 |
| libSkiaSharp.dll | 11.4MB | SkiaSharp Native |
| SharpDX.dll | 568KB | DirectX 래퍼 |
| SharpDX.Direct2D1.dll | 426KB | Direct2D |
| SharpDX.Direct3D11.dll | 265KB | Direct3D 11 |
| SharpDX.DXGI.dll | 116KB | DXGI |

#### 하드웨어 인터페이스

| DLL | 크기 | 설명 |
|-----|------|------|
| Interop.BMDSwitcherAPI.dll | 92KB | Blackmagic ATEM |
| Interop.MFORMATSLib.dll | 87KB | Medialooks MFormats |
| NvAPIWrapper.dll | 468KB | NVIDIA API |
| HidLibrary.dll | 29KB | USB HID |
| kl2dll64.dll | 9.7MB | KEYLOK 동글 |

#### 웹/데이터

| DLL | 크기 | 설명 |
|-----|------|------|
| EO.WebEngine.dll | 73.7MB | Chromium 엔진 |
| EntityFramework.dll | 4.99MB | EF 6.0 |
| System.Data.SQLite.dll | 450KB | SQLite ADO.NET |
| Newtonsoft.Json.dll | 712KB | JSON |
| AWSSDK.Core/S3.dll | ~2MB | AWS SDK |
| Bugsnag.dll | 71KB | 에러 리포팅 |
| FluentValidation.dll | - | 입력 검증 |

### [Clone] NuGet 패키지 관리

.NET 8에서는 Costura.Fody가 불필요하다. 모든 의존성은 NuGet 패키지로 관리하며, `dotnet publish`의 Single-file 또는 Self-contained 배포를 사용한다.

| 원본 DLL | NuGet 대체 | 비고 |
|----------|-----------|------|
| SharpDX.* | `Vortice.Windows` 또는 `Silk.NET` | SharpDX deprecated |
| Interop.MFORMATSLib | `FFmpeg.AutoGen` 또는 `LibVLCSharp` | 오픈소스 대안 |
| EO.WebEngine.dll (73.7MB) | `Microsoft.Web.WebView2` | 경량 WebView |
| EntityFramework 6.0 | `Microsoft.EntityFrameworkCore` 8.x | EF Core |
| Newtonsoft.Json | `System.Text.Json` | .NET 내장 |
| boarssl.dll | `System.Net.Security` | .NET 내장 TLS |
| kl2dll64.dll (9.7MB) | 제거 (소프트웨어 라이선스 대체) | KEYLOK 불필요 |
| AWSSDK.Core/S3 | OpenTelemetry SDK | 텔레메트리 변경 |
| Bugsnag | `Sentry.AspNetCore` 또는 Application Insights | 대안 |
| Costura.Fody | 제거 | `dotnet publish --self-contained` |

---

## 부록 C: 구현 로드맵

### Phase 1: Core Engine (4주)

| 주차 | 작업 | 산출물 |
|:----:|------|--------|
| 1 | 프로젝트 세팅 + 데이터 모델 | 솔루션 구조, 62+ Enum/DTO 정의, DI 컨테이너 |
| 2 | 핸드 평가 엔진 (Bitmask + Lookup) | hand_eval 포팅 (538개 정적 배열), 단위 테스트 |
| 3 | 게임 엔진 (Hold'em + Omaha) | 22개 GameType 중 상위 6개, 베팅 로직, GameTypeData |
| 4 | Service Layer + DI | 10개 서비스 인터페이스 구현, CQRS 기반 Features |

### Phase 2: Network (3주)

| 주차 | 작업 | 산출물 |
|:----:|------|--------|
| 5 | gRPC 프로토콜 정의 | .proto 파일 (113+ 명령어 매핑), 코드 생성 |
| 6 | TCP/TLS 통신 + 암호화 | AES-GCM 기반 클라이언트-서버 통신, UDP Discovery |
| 7 | Master-Slave + Discovery | 다중 인스턴스 동기화, slave 클래스 (34개 필드), 쓰로틀링 |

### Phase 3: Rendering (4주)

| 주차 | 작업 | 산출물 |
|:----:|------|--------|
| 8 | DirectX 12 초기화 + Texture | 기본 렌더링 파이프라인, Vortice.Windows 통합 |
| 9 | 그래픽 요소 시스템 | 4개 Element (image, text, pip, border) + 11개 Animation |
| 10 | FFmpeg 비디오 캡처/출력 | 입력 소스 → Channel 파이프라인 → 출력 디바이스 |
| 11 | Dual Canvas + Skin | Live/Delayed 캔버스 + Skin 로딩/편집 |

### Phase 4: Hardware & Integration (3주)

| 주차 | 작업 | 산출물 |
|:----:|------|--------|
| 12 | RFID 인터페이스 | v2 TCP/WiFi + USB 리더, 22개 Text Command, TLS 1.2 |
| 13 | ATEM + 외부 서비스 | Blackmagic 스위처, Twitch EventSub, LiveApi |
| 14 | 라이선스 + 보안 | 3-Layer 소프트웨어 라이선스, Key Vault 통합, JWT 인증 |

### Phase 5: Polish (2주)

| 주차 | 작업 | 산출물 |
|:----:|------|--------|
| 15 | WPF/Avalonia UI + MVVM | 43 Forms → 30 Views, MainViewModel + 기능별 ViewModel |
| 16 | CI/CD + 배포 + QA | GitHub Actions, MSIX 패키징, E2E 테스트, 성능 벤치마크 |

### 팀 구성 권장

| 역할 | 인원 | 담당 Phase |
|------|:----:|-----------|
| 리드 개발자 | 1 | 전체 아키텍처, Phase 1 |
| 백엔드 개발자 | 1-2 | Phase 1, 2 |
| 그래픽 개발자 | 1 | Phase 3 |
| 시스템 개발자 | 1 | Phase 4 |
| UI 개발자 | 1 | Phase 5 |
| QA | 1 | Phase 2-5 |

### 기술 부채 관리

| 활동 | 주기 | 목적 |
|------|------|------|
| 코드 리뷰 | 매 PR | 코드 품질 유지, 지식 공유 |
| 아키텍처 검토 | 월간 | 설계 일관성, 기술 부채 조기 발견 |
| 테스트 커버리지 | 지속 | 80% 이상 유지 (Core/Network는 90%+) |
| 의존성 업데이트 | 분기별 | NuGet 패키지 보안 패치, 호환성 |
| 성능 벤치마크 | Phase별 | 렌더링 60fps, 네트워크 지연 < 50ms |

---

*PokerGFX Clone PRD - Wave 4 (보안, 스레드, UI, 빌드/배포)*
