# Infrastructure & Application Modules Deep Analysis

**Document**: PokerGFX RFID-VPT Server - mmr.dll, PokerGFX.Common.dll, vpt_server.exe
**Supplement to**: `architecture_overview.md`
**Analysis Date**: 2026-02-12
**Decompiler**: Custom IL Decompiler (il_decompiler.py)

---

## Table of Contents

1. [Module Overview](#1-module-overview)
2. [mmr.dll - Multimedia Rendering Engine](#2-mmrdll---multimedia-rendering-engine)
3. [PokerGFX.Common.dll - Shared Platform Library](#3-pokergfxcommondll---shared-platform-library)
4. [vpt_server.exe - Main Application](#4-vpt_serverexe---main-application)
5. [Cross-Module Integration Map](#5-cross-module-integration-map)
6. [Security Analysis](#6-security-analysis)
7. [Reconstruction Notes](#7-reconstruction-notes)

---

## 1. Module Overview

| Module | Files | Lines (est.) | Purpose |
|--------|:-----:|:------------:|---------|
| **mmr.dll** | 80 | ~12,000 | GPU rendering, video capture/mixing/recording |
| **PokerGFX.Common.dll** | 50 | ~3,000 | Shared types, logging, encryption, DI, versioning |
| **vpt_server.exe** | 347 | ~50,000+ | Main WinForms application, 3-generation architecture |
| **Total** | **477** | **~65,000** | |

> **Note**: vpt_server.exe의 GameTypes(26), Features(58), Services(14), Interfaces(7), SystemMonitors(5), Logging(4) 등 195+ 파일에 대한 상세 분석은 `vpt_server_supplemental_analysis.md` 참조.

### Dependency Hierarchy

```
vpt_server.exe (Application Layer)
    ├── mmr.dll (GPU/Video Engine)
    │   ├── SharpDX (Direct3D 11, Direct2D, DirectWrite)
    │   ├── MFORMATSLib (Medialooks MFormats SDK)
    │   └── System.Drawing (GDI+ fallback)
    ├── PokerGFX.Common.dll (Shared Platform)
    │   ├── Microsoft.Extensions.DependencyInjection
    │   ├── Microsoft.Extensions.Configuration
    │   └── System.Security.Cryptography
    ├── net_conn.dll (Network Protocol)
    ├── hand_eval.dll (Poker Hand Evaluation)
    ├── RFIDv2.dll (RFID Hardware)
    ├── analytics.dll (Statistics)
    └── boarssl.dll (TLS)
```

---

## 2. mmr.dll - Multimedia Rendering Engine

### 2.1 Architecture Overview

mmr.dll은 DirectX 11 GPU 기반 실시간 비디오 합성 엔진이다. Medialooks MFormats SDK를 래핑하여 비디오 캡처, 믹싱, 렌더링, 녹화를 수행한다.

**핵심 설계 패턴**: Producer-Consumer 멀티스레드 파이프라인

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Capture   │────▶│    Mixer    │────▶│  Renderer   │
│  (MFLive)   │     │  (canvas)   │     │  (MFSink)   │
└─────────────┘     └──────┬──────┘     └─────────────┘
                           │
                    ┌──────┴──────┐
                    │             │
               ┌────▼────┐  ┌────▼────┐
               │  Live   │  │ Delayed │
               │ Output  │  │ Output  │
               └─────────┘  └─────────┘
```

### 2.2 Class Hierarchy (62 files)

| Category | Classes | Description |
|----------|---------|-------------|
| **Core Engine** | `mixer`, `canvas`, `bridge`, `helper` | GPU 파이프라인 핵심 |
| **Capture** | `video_capture_device`, `audio_capture_device` | 입력 디바이스 |
| **Output** | `renderer`, `preview`, `sink` | 출력 디바이스 |
| **Graphics** | `image_element`, `text_element`, `pip_element`, `border_element` | 그래픽 레이어 |
| **Asset** | `asset`, `assets`, `bridge` | 텍스처 관리 |
| **Text** | `font`, `custom_text_renderer`, `ResourceFontLoader` | DirectWrite 텍스트 |
| **Enums** | `timeshift`, `record`, `speed`, `delay_modes`, `platform` 등 | 상태 열거형 |
| **DirectShow** | `dshow/IAMCameraControl`, `IAMVideoProcAmp` 등 | COM Interop |

### 2.3 mixer - Core Video Compositor

`mixer`는 mmr.dll의 핵심 클래스로, 80+ 필드와 5개 워커 스레드를 관리한다.

#### 필드 분석 (90개)

```csharp
public class mixer
{
    // === Delegate Callbacks ===
    private frame_delegate on_frame;               // 프레임 완료 콜백
    private frame_grab_delegate on_frame_grab;     // 프레임 캡처 콜백
    private media_finished_delegate media_finished; // 미디어 재생 완료
    private error_delegate on_error;               // 에러 콜백

    // === Dual Canvas (Live + Delayed) ===
    public canvas canvas_live;                     // 라이브 캔버스
    public canvas canvas_delayed;                  // 딜레이 캔버스

    // === MFormats SDK Objects ===
    private MFLiveClass mf_live;                   // 라이브 캡처
    private MDelayClass mdelay;                    // 딜레이/타임시프트
    private MFPreviewClass mf_preview;             // 프리뷰
    private MFFactoryClass mf_factory;             // 팩토리
    private MFRendererClass mf_renderer;           // 렌더러
    private MFWriterClass mf_writer;               // 파일 녹화
    private MFReaderClass mf_reader;               // 파일 재생
    private MFAudioBufferClass ext_audio_buffer;   // 외장 오디오

    // === Device Lists ===
    private List<video_capture_device> _video_capture_devices;
    private List<audio_capture_device> _audio_capture_devices;
    private List<string> _audio_output_devices;
    private List<preview> _previews;
    private List<renderer> _renderers;

    // === PIP (Picture-in-Picture) ===
    private List<pip> _pips;                       // 현재 PIP 목록
    private List<pip> _new_pips;                   // 업데이트 대기 PIP
    private bool pip_update;                       // PIP 변경 플래그

    // === Frame Queues (Producer-Consumer) ===
    private BlockingCollection<MFFrame> live_frames;
    private BlockingCollection<MFFrame> delayed_frames;
    private BlockingCollection<MFFrame> write_frames;
    private ConcurrentQueue<MFFrame> sync_frames;
    private CancellationTokenSource live_frames_token;
    private CancellationTokenSource delayed_frames_token;
    private CancellationTokenSource write_frames_token;

    // === Worker Threads (5개) ===
    private Thread thread_worker;                  // 메인 라이브 프레임 처리
    private Thread thread_worker_audio;            // 오디오 프레임 처리
    private Thread thread_worker_delayed;          // 딜레이 프레임 처리
    private Thread thread_worker_write;            // 녹화 파일 쓰기
    private Thread thread_worker_process_delay;    // 딜레이 처리

    // === Synchronization ===
    private object live_lock_obj;                  // 라이브 동기화
    private object delay_lock_obj;                 // 딜레이 동기화
    private AutoResetEvent are_delay;              // 딜레이 이벤트
    private AutoResetEvent are_audio;              // 오디오 이벤트

    // === State Flags ===
    private bool running;
    private bool _delay_enabled;
    private bool _sink_enabled;
    private bool _recording;
    private bool _media_override_loop;
    private bool _frame_grab_live;
    private bool _frame_grab_delayed;
    private bool _reset_gpu;
    private bool _force_sw_encode;
    private bool _rec_hw_encode;
    private bool _force_transparent_background_live;
    private bool _force_transparent_background_delay;
    private bool _sync_live_delay;

    // === Timing & Rate Control ===
    private rate_control_mode _live_rate_control;
    private rate_control_mode _delayed_rate_control;
    private Queue<double> live_fps;
    private Queue<double> delayed_fps;
    private TimeSpan _delay_period;
    private TimeSpan _test_delay;

    // === Media Override ===
    private media_override _media_override;
    private bool media_override_first_frame;
    private long media_override_start_index;
    private TimeSpan media_override_progress;
    private TimeSpan _media_override_start;
    private TimeSpan _media_override_stop;
    private TimeSpan _media_override_seek_to_pos;
    private bool _media_override_seek_to;

    // === Configuration ===
    private platform _platform;
    private Color _back_col;
    private double _volume;
    private double _audio_capture_delay;
    private double _video_sync_delay;
    private double _delay_start_minsec;
    private int _embedded_audio_capture_device;
    private timeshift _sink_live_delayed;
    private record _record_mode;
    private audio_source _audio_source;
    private speed _speed;
    private delay_modes _delay_mode;
    private string _recording_file_name;
    private string _delay_file_name;
}
```

#### 5-Thread Pipeline Architecture

```
thread_worker (Main Live)
├── BlockingCollection<MFFrame> live_frames 에서 프레임 수신
├── canvas_live에 GPU 렌더링
├── on_frame 콜백으로 결과 전달
└── sync_frames에 동기화 프레임 푸시

thread_worker_audio
├── AutoResetEvent are_audio 대기
├── ext_audio_buffer에서 오디오 캡처
└── 오디오 믹싱 처리

thread_worker_delayed
├── BlockingCollection<MFFrame> delayed_frames 에서 프레임 수신
├── MDelayClass로 타임시프트 적용
├── canvas_delayed에 GPU 렌더링
└── on_frame 콜백으로 딜레이 결과 전달

thread_worker_write
├── BlockingCollection<MFFrame> write_frames 에서 프레임 수신
├── MFWriterClass로 파일 기록
└── 녹화 상태 관리 (_recording 플래그)

thread_worker_process_delay
├── MDelayClass 내부 딜레이 버퍼 처리
├── AutoResetEvent are_delay 대기
└── 딜레이 프레임 생성 → delayed_frames 큐
```

#### Dual Canvas System

mixer는 Live와 Delayed 두 개의 독립 캔버스를 동시 운영한다:

```
Video Input → [Live Canvas] → Live Output (실시간)
                    ↓
              [Delay Buffer]
                    ↓
             [Delayed Canvas] → Delayed Output (N초 지연)
```

- **Live Output**: 실시간 방송용 (카메라 + 그래픽 오버레이)
- **Delayed Output**: 시간차 방송용 (동일 그래픽, N초 지연)
- `_sync_live_delay`: true이면 Live/Delayed 프레임 동기화
- `_delay_period`: 딜레이 시간 (TimeSpan)

### 2.4 canvas - DirectX 11 GPU Rendering Surface

`canvas`는 DirectX 11 기반 2D 렌더링 표면이다.

```csharp
public class canvas
{
    // === DirectX 11 Core ===
    private Device d3d_device;                     // D3D11 디바이스
    private SharpDX.DXGI.Device dxgi_device;       // DXGI 인터페이스
    private SharpDX.Direct2D1.Device d2d_device;   // D2D 디바이스
    private SharpDX.DirectWrite.Factory dw_factory; // DirectWrite 팩토리
    private SharpDX.Direct2D1.DeviceContext dc;    // 2D 렌더링 컨텍스트

    // === Rendering Resources ===
    private Texture2D t2d;                         // 렌더 타겟 텍스처
    private Bitmap[] bm_buffer;                    // 더블 버퍼 (2개)
    private List<render_item> render_items;        // 렌더 아이템 큐

    // === Graphic Layers (Z-order) ===
    private List<image_element> image_elements;    // 이미지 레이어
    private List<text_element> text_elements;      // 텍스트 레이어
    private List<pip_element> pip_elements;        // PIP 레이어
    private List<border_element> border_elements;  // 보더 레이어

    // === State ===
    private int _w, _h;                            // 해상도
    private int _adapter_index;                    // GPU 어댑터
    private Color4 _background_colour;             // 배경색 (기본: 투명 흑)
    private bool _is_disposed;
    private object safety_lock;                    // 스레드 안전 락
}
```

**초기화 흐름** (canvas.ctor):
1. `_background_colour = Color4(1.0, 0.0, 0.0, 0.0)` - Alpha=1, RGB=0 (투명 흑)
2. 4개 그래픽 레이어 리스트 초기화
3. `bm_buffer = new Bitmap[2]` - 더블 버퍼링
4. `init_devices()` 호출 → D3D11 Device, D2D Device 생성
5. `helper.create_dc()` 호출 → DeviceContext, Texture2D 생성

**렌더링 파이프라인**:
```
begin_render()
    → dc.BeginDraw()
    → dc.Clear(_background_colour)
    → 각 레이어 Z-order 순으로 렌더링:
        image_elements → text_elements → pip_elements → border_elements
    → dc.EndDraw()
    → Texture2D → MFFrame 변환
end_render()
```

### 2.5 bridge - Cross-GPU Texture Sharing

`bridge`는 두 독립 GPU 컨텍스트(canvas와 asset) 간 텍스처를 공유하는 핵심 메커니즘이다.

```csharp
internal class bridge
{
    // Canvas측 (렌더링 대상)
    internal Device canvas_d3d_device;
    internal DeviceContext canvas_d2d_context;
    internal Bitmap1 canvas_d2d_bitmap;

    // Asset측 (원본 텍스처)
    internal Device asset_d3d_device;
    internal DeviceContext asset_d2d_context;
    internal Bitmap1 asset_d2d_bitmap;

    // 공유 텍스처
    private Texture2D _t2d;     // Asset측 원본
    private Texture2D t2d;      // Canvas측 공유 핸들
    private Bitmap1 prev_bitmap; // 이전 프레임 캐시
    private bool _disposed;
}
```

**공유 메커니즘** (`create_new`):
```
1. Asset D3D Device에서 Texture2D 생성
   - Format: R8G8B8A8_UNorm (28)
   - BindFlags: ShaderResource | RenderTarget (40)
   - OptionFlags: SharedResource (2)
   - MipLevels: 1, SampleCount: 1

2. Asset Texture → DXGI Surface → Asset D2D Bitmap 생성

3. DXGI Resource → SharedHandle 추출

4. SharedHandle → Canvas D3D Device에서 OpenSharedResource
   → Canvas Texture2D 생성

5. Canvas Texture → DXGI Surface → Canvas D2D Bitmap 생성
```

**최적화**: `prev_bitmap` 캐싱으로 동일 비트맵 반복 시 bridge 재생성 방지. 크기 변경 시만 `dispose()` → `create_new()` 호출.

### 2.6 renderer - Video Output

```csharp
public class renderer
{
    internal MFRendererClass _mf_renderer;          // MFormats 렌더러
    private Thread thread_worker;                   // 백그라운드 렌더 스레드
    private BlockingCollection<MFFrame> render_frames; // 프레임 큐
    private CancellationTokenSource render_frames_token;
    private string _dev_name;
    private timeshift _live_delayed;                // Live or Delayed 선택
    private bool _enabled, _is_ndi, _background, _rate_control;
}
```

**렌더링 모드**:
- **Foreground** (`_background=false`): MFRendererClass.ReceiverFramePut() 직접 호출
- **Background** (`_background=true`): MFClone → BlockingCollection → thread_render()
- **NDI**: `_is_ndi=true`시 NDI 프로토콜 출력
- **Fill & Key**: `keying` 속성으로 external keyer 지원 (Decklink 하드웨어)

**프레임 드롭 방지**: `thread_render()`에서 큐 크기 > 30이면 오래된 프레임 일괄 폐기 (ReleaseComObject)

### 2.7 sink - MFSink STA Worker

```csharp
internal class sink
{
    private BlockingCollection<SinkWorkItem> _workQueue;
    private ManualResetEventSlim _workerReady;
    private Thread _workerThread;                   // STA 스레드
    private MFSinkClass mf_sink;                    // MFormats Sink
}
```

**STA 스레드 요구사항**: MFSinkClass는 COM STA 모드 필수. `TrySetApartmentState(ApartmentState.STA)` 호출.
Thread Name: `"MFSinkWorker"`, IsBackground=true.

### 2.8 video_capture_device - Input Device

```csharp
public class video_capture_device
{
    private MFLiveClass _mf_live;                   // MFormats 라이브 캡처
    private MFReaderClass _mf_reader;               // 파일 기반 입력
    private MFFactoryClass mf_factory;              // 프레임 팩토리

    // DirectShow COM Interop
    private IAMCameraControl _dshow_IAMCameraControl;
    private IAMVideoProcAmp _dshow_IAMVideoProcAmp;
    private IAMVfwCaptureDialogs _dshow_IAMVfwCaptureDialogs;

    private List<device_line> _device_lines;        // 디바이스 입력 라인
    private List<dshow_props> _dshow_props;         // DirectShow 속성
    private ConcurrentQueue<MFFrame> frames;        // 캡처 프레임 큐
    private Thread thread_worker_get_frame;         // 프레임 수집 스레드
    private AutoResetEvent are_frame;

    private string _id, _name, _url;
    private video_capture_device_type _video_capture_device_type;
    private rotate_type _rotate;
    private bool _enabled, _frame_grab, _force_sw_encode, _capture_audio;
}
```

**지원 디바이스 타입**: Decklink 캡처 카드, USB 웹캠, NDI 네트워크 소스, URL 스트림

### 2.9 Graphic Elements

#### image_element - 이미지 오버레이

```csharp
internal class image_element
{
    private DeviceContext _dc;
    private Device _d3d_device;
    private asset _asset;                           // 애니메이션 스프라이트
    private asset _overlay_asset;                   // 오버레이 에셋
    private bridge _bridge;                         // GPU 컨텍스트 브릿지
    private bridge _overlay_bridge;

    // Direct2D Effects Pipeline
    private Effects.Crop _effect_crop;
    private Effects.AffineTransform2D _effect_transform;
    private Effects.Brightness _effect_brightness;
    private Effects.TableTransfer _effect_alpha;
    private Effects.ColorMatrix _effect_col_matrix;
    private Effects.ColorMatrix _effect_opacity_matrix;
    private Effects.HueRotation _effect_hue;

    // Properties
    private float _opacity, _brightness, _hue;
    private float _tint_r, _tint_g, _tint_b;
    private Size2F _scale;
    private int _z_pos, _rotate_angle;
    private int _seq_num, _frame_num;               // 애니메이션 시퀀스
    private bool _visible, _flip_x, _remove_partial_alpha;
}
```

**GPU Effects Chain**: Crop → Transform → Brightness → Alpha → ColorMatrix → HueRotation
Alpha Table: `_alpha_table_remove_partial[256]` - 인덱스 < 2이면 0.0, 이상이면 1.0 (하드 알파 클리핑)

#### text_element - 텍스트 오버레이

```csharp
internal class text_element
{
    private DeviceContext _dc;
    private Factory _dw_factory;                    // DirectWrite

    // DirectWrite Objects
    private TextLayout text_layout;
    private TextFormat text_format;
    private FontCollection _font_collection;
    private FontStyle _font_style;
    private FontWeight _font_weight;

    // Brushes
    private SolidColorBrush _text_brush;
    private SolidColorBrush _shadow_brush;
    private SolidColorBrush _back_brush;

    // Effects
    private text_effect _text_effect;               // Ticker, Reveal 등
    private shadow_direction _shadow_direction;
    private text_align _text_align;
    private custom_text_renderer _custom_text_renderer;

    // Animation State
    private int _ticker_offset, _reveal_offset;
    private int _effect_speed;
    private bool ticker_finished_notified;

    // Embedded Resources
    private Bitmap1 _local_bitmap;                  // 로컬 이미지
    private Bitmap1 _embedded_bitmap;               // 임베디드 이미지
    private byte[] _font_data_hash;                 // 커스텀 폰트 해시
}
```

**텍스트 효과 타입**: Ticker (수평 스크롤), Reveal (글자별 표시), Static, Shadow

#### pip (Picture-in-Picture)

```csharp
internal class pip
{
    private Rectangle src_rect;                     // 소스 영역
    private Rectangle dst_rect;                     // 대상 영역
    private float opacity;                          // 투명도
    private int z_pos;                              // Z-order
    private int border_thickness;
    private Color border_colour;
    private bool visible;
    private int dev_index;                          // 캡처 디바이스 인덱스
    private bool cloned;
}
```

PIP는 카메라 입력을 그래픽 캔버스의 임의 위치에 배치한다. `dev_index`로 어떤 카메라를 표시할지 선택.

### 2.10 Enums & Configuration Types

| Enum | Values (Inferred) | Purpose |
|------|-------------------|---------|
| `timeshift` | Live, Delayed | 출력 소스 선택 |
| `record` | None, Live, Delayed, Both | 녹화 대상 |
| `speed` | Normal, Half, Double, ... | 재생 속도 |
| `delay_modes` | Buffer, File | 딜레이 구현 방식 |
| `platform` | DirectX, Software | 렌더링 플랫폼 |
| `rate_control_mode` | None, Fixed, Variable | 프레임 레이트 제어 |
| `audio_source` | Embedded, External, Mixed | 오디오 소스 |
| `media_override` | None, Image, Video | 미디어 오버라이드 모드 |
| `log_level` | Debug, Info, Warning, Error | 로그 레벨 |
| `video_capture_device_type` | Decklink, USB, NDI, URL | 캡처 디바이스 타입 |
| `rotate_type` | None, CW90, CW180, CW270 | 회전 |
| `shadow_direction` | None, TopLeft, BottomRight, ... | 그림자 방향 |
| `text_align` | Left, Center, Right | 텍스트 정렬 |
| `text_effect` | None, Ticker, Reveal | 텍스트 애니메이션 |
| `font_style` | Normal, Italic | 폰트 스타일 |
| `font_weight` | Normal, Bold, ... | 폰트 두께 |

---

## 3. PokerGFX.Common.dll - Shared Platform Library

### 3.1 Architecture Overview

PokerGFX.Common.dll은 .NET Core 스타일의 공유 라이브러리로, DI 컨테이너, 로깅, 암호화, 버전 관리 등 플랫폼 공통 기능을 제공한다.

```
PokerGFX.Common/
├── Configuration/
│   ├── AppConfigurationBase.cs        # 설정 기본 클래스
│   ├── PgfxApiConfiguration.cs        # API 엔드포인트 설정
│   └── WebsiteLinks.cs                # 웹사이트 링크
├── Features/
│   ├── Encryption/
│   │   ├── EncryptionService.cs       # AES 암호화 서비스
│   │   ├── IEncryptionService.cs      # 인터페이스
│   │   └── Configuration/
│   │       └── EncryptionConfiguration.cs  # 암호화 키 설정
│   ├── DownloadLinks/
│   │   ├── DownloadLinksService.cs    # 다운로드 링크 서비스
│   │   └── Models/                    # DTO
│   ├── AppVersionValidation/
│   │   ├── AppVersionValidationHandler.cs  # 버전 검증
│   │   ├── UI/                        # 업데이트 알림 UI
│   │   ├── Models/                    # DTO
│   │   └── Enums/                     # 열거형
│   ├── AppVersions/
│   │   ├── AppVersionsService.cs      # 버전 정보 서비스
│   │   └── Models/                    # DTO
│   └── AppInstallInfo/
│       ├── AppInstallInfoService.cs   # 설치 정보 서비스
│       └── IAppInstallInfoService.cs
├── Logging/
│   ├── Logger.cs                      # 정적 로거 (Singleton)
│   ├── LoggerFactory.cs               # 로거 팩토리
│   ├── FileLogger.cs                  # 파일 로거 구현
│   ├── ILogger.cs                     # 로거 인터페이스
│   ├── LogLevel.cs                    # 로그 레벨 열거형
│   ├── LogTopic.cs                    # 토픽 필터링
│   ├── LogTopicDefinition.cs          # 토픽 정의
│   ├── LogTopicMetadata.cs            # 토픽 메타데이터
│   ├── BaseBugsnagService.cs          # Bugsnag 에러 리포팅
│   ├── BugsnagException.cs
│   ├── BugsnagSettings.cs
│   └── IBugsnagService.cs
├── Utilities/
│   ├── AssemblyAttributes.cs          # 어셈블리 정보
│   └── IDictionaryExtensions.cs       # 딕셔너리 확장
├── ExtensionMethods/
│   └── ServiceCollectionExtensions.cs # DI 등록
├── Properties/
│   └── Resources.cs                   # 리소스
├── AppSettingsReader.cs               # appsettings.json 리더
└── JsonExtensions.cs                  # JSON 확장 메서드
```

### 3.2 EncryptionService - AES 암호화

**net_conn.dll의 Rijndael과 별개인 두 번째 암호화 시스템**

```csharp
// 재구성된 C# 의사코드
public class EncryptionService : IEncryptionService
{
    private string _encryptionKey;  // Base64 인코딩 키

    public EncryptionService(EncryptionConfiguration config)
    {
        _encryptionKey = config.Key;
    }

    public string Encrypt(string plainText)
    {
        using var aes = Aes.Create();
        byte[] key = Convert.FromBase64String(_encryptionKey);
        aes.Key = key;
        aes.IV = new byte[16];  // 제로 IV (⚠️ 보안 취약점)

        using var encryptor = aes.CreateEncryptor(aes.Key, aes.IV);
        using var ms = new MemoryStream();
        using var cs = new CryptoStream(ms, encryptor, CryptoStreamMode.Write);
        using var sw = new StreamWriter(cs);
        sw.Write(plainText);
        return Convert.ToBase64String(ms.ToArray());
    }

    public string Decrypt(string cipherText)
    {
        if (string.IsNullOrEmpty(cipherText)) return string.Empty;
        try
        {
            using var aes = Aes.Create();
            byte[] key = Convert.FromBase64String(_encryptionKey);
            aes.Key = key;
            aes.IV = new byte[16];  // 제로 IV

            using var decryptor = aes.CreateDecryptor(aes.Key, aes.IV);
            using var ms = new MemoryStream(Convert.FromBase64String(cipherText));
            using var cs = new CryptoStream(ms, decryptor, CryptoStreamMode.Read);
            using var sr = new StreamReader(cs);
            return sr.ReadToEnd();
        }
        catch { return string.Empty; }
    }
}
```

**하드코딩된 기본 키** (EncryptionConfiguration.ctor):
```
Key = "6fPz9r5pnJpUB0w0z1OeETXMwzF1jzU9g3z1Y5JzLxo="
     (Base64 → 32 bytes = AES-256)
```

**취약점**:
- IV가 항상 `new byte[16]` (모두 0x00) → 동일 평문 → 동일 암호문 (Deterministic)
- 키가 소스코드에 하드코딩
- net_conn.dll과 별개 암호화 체계 (이중 관리)

### 3.3 Logging System

**토픽 기반 필터링 로그 시스템**:

```csharp
public enum LogTopic
{
    General,       // 일반
    Startup,       // 시작/종료
    MultiGFX,      // 다중 GFX 인스턴스
    AutoCamera,    // 자동 카메라 전환
    Devices,       // 디바이스 관리
    RFID,          // RFID 태그
    Updater,       // 자동 업데이트
    GameState      // 게임 상태
}

public interface ILogger
{
    void Log(LogLevel level, string message, bool remote, bool popup);
    void LogDebug(string message, bool remote, bool popup);
    void LogError(string message, bool remote, bool popup);
    void LogException(Exception exception);
    void LogInformation(string message, bool remote, bool popup);
    void LogWarning(string message, bool remote, bool popup);
    void LogToDebug(string message);
    void SuppressLogWindow(bool suppress);
}
```

**Logger.Log 흐름**:
1. `_topicFilter` 체크 → 해당 토픽+레벨 허용 여부
2. `_logger.Log()` 호출 (FileLogger 또는 커스텀)
3. `remote=true`: 원격 서버로 로그 전송
4. `popup=true`: UI 팝업 표시

**Bugsnag 통합**: `BaseBugsnagService`로 프로덕션 에러 리포팅 (crashlytics)

### 3.4 Dependency Injection

```csharp
public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddCommonLayer(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        // 3개 Configuration 바인딩 (EncryptionConfiguration 등)
        // IEncryptionService → EncryptionService (Singleton)
        // IAppVersionValidationHandler → AppVersionValidationHandler
        // IAppVersionsService → AppVersionsService
        // IDownloadLinksService → DownloadLinksService
        // IAppInstallInfoService → AppInstallInfoService
        return services;
    }
}
```

**DI 패턴**: Microsoft.Extensions.DependencyInjection 사용. `AddCommonLayer()`로 Common 레이어 전체 등록.

### 3.5 Version Management

- `AppVersionValidationHandler`: 서버에서 최신 버전 조회 → 현재 버전 비교
- `ForceVersionUpdateWindow`: 필수 업데이트 알림 (차단)
- `SuggestVersionUpdateWindow`: 선택 업데이트 제안 (비차단)
- `VersioningResultStatus`: `UpToDate`, `UpdateAvailable`, `UpdateRequired`
- `PgfxApiConfiguration`: API BaseUrl + Path 설정

### 3.6 Other Utilities

| Class | Purpose |
|-------|---------|
| `AppSettingsReader` | appsettings.json 읽기 |
| `JsonExtensions` | JSON 직렬화 확장 |
| `AssemblyAttributes` | 어셈블리 버전/저작권 정보 |
| `IDictionaryExtensions` | Dictionary 편의 메서드 |
| `WebsiteLinks` | PokerGFX 웹사이트 링크 관리 |
| `DownloadLinksService` | 설치 파일 다운로드 URL 관리 |

---

## 4. vpt_server.exe - Main Application

### 4.1 Architecture Overview

vpt_server.exe는 **3-generation 아키텍처**를 가진 메인 애플리케이션이다 (347 files).

- **Phase 1 (God Class)**: main_form, gfx, config, slave 등 초기 설계
- **Phase 2 (Service Interfaces)**: GameTypes/ 26 files - Interface/Service 분리
- **Phase 3 (DDD+CQRS)**: Features/ 58 files - Domain-Driven + FluentValidation

> **상세 분석**: Phase 2, Phase 3, Services, Interfaces, SystemMonitors, Logging에 대한 심층 분석은 `vpt_server_supplemental_analysis.md` 참조.

```
vpt_server.exe (347 files)
├── main_form (God Class - Phase 1)
├── GameTypes/ (26 files - Phase 2: Service Interface)
│   ├── Interfaces/ (9 interfaces)
│   └── Services/ (11 implementations)
├── Features/ (58 files - Phase 3: DDD+CQRS)
│   ├── Licensing/ (20 files - KEYLOK DRM)
│   ├── Login/ (6 files - CQRS pattern)
│   ├── Authentication/ (4 files)
│   ├── OfflineSession/ (7 files)
│   ├── ConfigurationPresets/ (5 files)
│   └── IdentityInformationCache/ (3 files)
├── Services/ (7 files) + Interfaces/ (7 files)
├── SystemMonitors/ (5 files - GPU/CPU/Storage)
├── Logging/ (4 files - Bugsnag + file)
├── gfx, render, config, atem, slave, twitch, LiveApi
├── 18+ Element + 10+ Animation 클래스
└── 43+ UI Form 클래스
```

### 4.2 main_form - God Class Analysis

**필드 수**: 150+ (UI 컨트롤 포함 시 200+)

#### 카테고리별 분류

```csharp
internal class main_form : Form
{
    // === License Management ===
    private object _licenceTrialTimer;
    private bool _isEvaluationMode;
    private bool _shouldTriggerEvaluationMode;
    private bool _isLicenseExpired;
    private bool _licenseUIIsUpdating;
    private object _trialForm;
    private object _license;
    private DateTime _evaluationModeStartTime;
    private TimeSpan _evaluationModeDuration;
    private object licenseService;
    private object licenseBackgroundService;

    // === Service Layer (DI) ===
    private object _actionTrackerService;
    private object _performanceMonitor;
    private object _storageMonitor;
    private object offlineSessionService;
    private object identityInformationCacheService;
    private object _tagsService;
    private object serviceProvider;                // IServiceProvider
    private object configurationPresetService;

    // === Security ===
    private object _assemblyAttributes;
    private object _encryptionConfiguration;

    // === Subsystem References ===
    private object _analyticsScreenshots;
    private object _skinLoaded;
    private LogWindow _logWindow;
    private pip_edit pipEdit;
    private test_table testTable;

    // === Camera System ===
    private object _cameraPreviewWindow;
    private object _cameraPropertiesWindow;
    private object _firmwareProgress;
    public object cameraListView;
    public object virtualCameraListView;
    private int cal_current_ant;
    private int cal_max_player;
    public int adapter;

    // === RFID ===
    public static object _readerModule;
    private object usb_sync_object;
    private object _registerPlayer;

    // === Network ===
    private net_conn.client<client_obj> net_client_vcap;  // TCP 클라이언트
    public object net_client_master;                       // Master 연결
    private int _reconnectionAttempts;
    private DateTime _lastReconnectionAttempt;
    private object _connectionValidationTimer;

    // === Video ===
    public object defaultResoution;
    public bool forceStream;
    public bool IsFirmwareUpdating;
    public bool IsInitializing;
    public bool IsShuttingDown;
    public object prev_hash;
    public object installProcess;

    // === Twitch ===
    private object twitchChatbot;

    // === UI Controls (100+ WinForms controls) ===
    // TabControl: Sources, Outputs, Graphics, System, Commentary
    // 각 탭에 수십 개의 ComboBox, NumericUpDown, CheckBox, Button 등

    // === Throttle/Debounce ===
    private DateTime _lastUpdateControlsTime;
    private TimeSpan _updateControlsThrottle;
    private DateTime _lastConnectionValidationLogTime;
    private TimeSpan _connectionValidationLogThrottle;
    private DateTime _lastMultiGFXToggleTime;
    private TimeSpan _multiGFXToggleDebounce;
}
```

### 4.3 config - Configuration & Skin Encryption

```csharp
public class config
{
    // === Skin File Encryption Keys ===
    public static byte[] SKIN_HDR;                  // 스킨 파일 헤더 매직
    public static byte[] SKIN_SALT;                 // 암호화 솔트
    public static string SKIN_PWD;                  // 암호화 비밀번호

    // === Game Variants ===
    public static List<game_variant_info> games;    // 지원 게임 변형 목록

    // === Animation Timing ===
    public static int IMAGE_LOOP;                   // 이미지 루프 프레임
    public static int IMAGE_INTRO;                  // 인트로 프레임
    public static int IMAGE_OUTRO;                  // 아웃트로 프레임
    public static float ANIM_IN_FADE_START_POS;     // 페이드인 시작 위치
    public static float ANIM_IN_FADE_END_POS;       // 페이드인 종료 위치
    public static float ANIM_OUT_FADE_START_POS;    // 페이드아웃 시작 위치
    public static float ANIM_OUT_FADE_END_POS;      // 페이드아웃 종료 위치

    // === Runtime State ===
    public static config_type data;                 // 전체 설정 데이터
    public static int skin_crc;                     // 로드된 스킨 CRC
    public static byte[] serialized_skin;           // 직렬화된 스킨 데이터
    public static string save_path_user;            // 사용자 저장 경로
    public static string save_path;                 // 기본 저장 경로
    public static TimeSpan web_timeout;             // 웹 요청 타임아웃

    // === Obfuscated Methods ===
    // ConfuserEx 보호된 메서드들 (etype_0x34 시그니처)
    // → Skin 파일 로드/저장, 암호화/복호화 로직 추정
    void write_entry_txt(string, _hand, bool);      // 핸드 로그 기록
}
```

**Skin 파일 (.vpt) 구조** (추정):
```
[SKIN_HDR]         → 매직 바이트 (파일 식별)
[Encrypted Data]   → SKIN_PWD + SKIN_SALT로 AES 암호화
  └── JSON/Binary  → 그래픽 레이아웃, 색상, 폰트, 이미지 에셋
[CRC32]            → skin_crc로 무결성 검증
```

**ConfuserEx 난독화**: config의 핵심 메서드들은 `etype_0x34` 시그니처로 난독화되어 있어 정확한 복원 불가. 25개 매개변수의 비정상적 시그니처는 ConfuserEx의 메서드 프록시/리디렉션 보호 패턴.

### 4.4 gfx - Graphics Engine Wrapper

```csharp
public class gfx
{
    // === Static Lookup Tables ===
    public static string[] order_str;               // 포지션 순서 이름
    public static string[] pos_str;                 // 좌석 위치 이름
    public static string[] strip_pos_str;           // 스트립 위치 이름

    // === Graphic Elements ===
    private ActionClockElement _actionClock;         // 액션 타이머
    private GameSave _gameSave;                     // 게임 저장/복원
    private List<OutsElement> _outs;                // 아웃 카드 표시
    public Panel _panel;                            // 메인 패널
    private Strip _strip;                           // 하단 정보 바
    public TickerElement _ticker;                   // 스크롤 텍스트
    private SplitScreenDividerElement SplitScreenDivider;
    private CardBlinkAnimation CardAnimation;
    private pipcap Pipcap;                          // PIP 캡처
    private FieldElement Field;                     // 필드 표시

    // === Service Dependencies ===
    private IGraphicElementsService _graphicElementsService;
    private IGamePlayersService _gamePlayersService;
    private IGameCardsService _gameCardsService;
    private IGameVideoLiveService _gameVideoLiveService;
    private IEffectsService _effectsService;
    private IVideoMixerService _videoMixerService;
    private ITransmisionEncodingService _transmisionEncodingService;
    private IHandEvaluationService _handEvaluationService;
    private IGameConfigurationService _gameConfigurationService;
    private IUpdatePlayerService _updatePlayerService;
    private ILicenseService _licenseService;

    // === Runtime State ===
    private canvas canvas;                          // mmr.canvas 참조
    private render render;                          // 렌더 엔진 참조
    private GfxMode Mode;                           // 현재 모드
    private GfxPanelType _showPanel;                // 표시 패널 타입
    private bool Enable;
    private bool TickerLoop;
    private int _boardFrameCountMs;                 // 보드 카드 표시 시간
}
```

**gfx는 vpt_server의 그래픽 레이어 오케스트레이터**: mmr.canvas에 포커 그래픽 요소를 배치하고, 게임 상태에 따라 표시/숨김/애니메이션을 제어한다.

### 4.5 render - Rendering Pipeline

```csharp
public class render
{
    private render_type _mode;                      // 렌더링 모드
    private List<_hand> _render_hands;              // 렌더링할 핸드 목록
    private _game _render_game;                     // 현재 게임 상태
    public TimeSpan _first_render_event;            // 첫 렌더 이벤트
    public TimeSpan _last_render_event;             // 마지막 렌더 이벤트
    public long render_frame;                       // 현재 프레임 번호
    public game_event_cam_type active_cam;          // 활성 카메라

    private GfxMode _gfxMode;
    public bool running;
    public AutoResetEvent are_delayed_render;       // 딜레이 렌더 이벤트
    private Thread delayed_render_thread;           // 딜레이 렌더 스레드
    public DateTime delay_render_dt;
}
```

### 4.6 atem - Blackmagic ATEM Switcher Integration

```csharp
internal class atem
{
    // === ATEM SDK Objects ===
    private object _monitorSwitcherDiscovery;       // 스위처 발견
    private object _monitorSwitcher;                // 스위처 모니터
    private object _switcherMonitor;                // SwitcherMonitor 콜백
    private object _mixEffectBlock;                 // M/E 블록
    private object _mixEffectBlockMonitor;          // M/E 모니터

    // === Camera Management ===
    private List<InputMonitor> _inputMonitors;      // 입력 모니터 목록
    private List<camera> _cameraList;               // 카메라 목록

    // === State ===
    private state_enum _state;                      // 연결 상태
    private object _name;                           // 스위처 이름
    private object _address;                        // IP 주소
    private bool _requiresUpdInputs;                // 입력 업데이트 필요
    private object _lock;                           // 동기화 락

    // === Pending Requests ===
    private object _nameReq;                        // 이름 변경 요청
    private object _switchReq;                      // 전환 요청
    private object _inputReq;                       // 입력 요청

    // === Event ===
    private state_changed_event_handler _stateChangedEventHandler;
}
```

**ATEM 통합**: Blackmagic Design ATEM 비디오 스위처를 COM Interop으로 제어. 프로그램 전환, 입력 모니터링, Mix Effect 블록 제어.

### 4.7 slave - Master-Slave Network Architecture

```csharp
internal class slave
{
    private static bool _connected;
    private static bool _authenticated;
    private static bool _synced;
    private static bool _passwordSent;

    // === Master State Mirror ===
    private static object _masterExtSwitcherAddress;
    private static object _masterTwitchChannel;
    private static int _skinPosition;
    private static int downloadSkinCrc;
    private static object downloadSkinList;
    private static bool _isMasterStreaming;
    private static bool _isAnySlaveStreaming;

    // === Connection Management ===
    private static DateTime _connectionStartTime;
    private static TimeSpan _authenticationTimeout;
    private static int _reconnectionAttempts;       // (main_form에도 존재)

    // === Performance Throttling ===
    private static DateTime _lastGameStateUpdate;
    private static TimeSpan _minUpdateInterval;
    private static DateTime _lastHandLogUpdate;
    private static DateTime _lastGameLogUpdate;
    private static TimeSpan _minLogUpdateInterval;
    private static DateTime _lastGraphicsRefresh;
    private static TimeSpan _graphicsRefreshThrottle;

    // === Caching ===
    private static bool _cachedIsAnySlaveStreaming;
    private static DateTime _lastSlaveStreamingCheck;
    private static TimeSpan _slaveStreamingCacheDuration;
    private static bool _cachedIsConnected;
    private static bool _cachedIsAuthenticated;
    private static DateTime _lastConnectionStatusCheck;
    private static TimeSpan _connectionStatusCacheDuration;
}
```

**Master-Slave 모델**:
- **Master**: 메인 VPT 서버 (게임 상태 원본)
- **Slave**: 추가 VPT 인스턴스 (Master로부터 스킨/상태 동기화)
- `scan()`: LAN에서 Master 발견 (net_conn UDP Discovery 사용)
- 스킨 다운로드: Master에서 Slave로 .vpt 파일 전송
- 상태 미러링: 게임 상태, 핸드 로그, 그래픽 설정 실시간 동기화

**ConfuserEx 보호**: slave의 핵심 메서드들도 난독화 (etype_0x34, etype_0x56 시그니처)

### 4.8 twitch - Twitch Chatbot

```csharp
internal class twitch
{
    private object CMDS;                            // 지원 명령어 목록
    private object NOT_AVAIL_YET;                   // "아직 사용 불가" 메시지
    private object NOT_AVAIL_GAME;                  // "게임 없음" 메시지
    private bool _connected;                        // 연결 상태
    private object _channel;                        // 채널 이름
    private object _nick;                           // 봇 닉네임
    private object _token;                          // OAuth 토큰
    private object remote_tcp;                      // TcpClient
    private object _stream;                         // NetworkStream
    private object rem_sb;                          // StringBuilder (수신 버퍼)
    private object keepalive_timer;                 // PING/PONG 타이머
    private state_changed_delegate _state_changed;  // 상태 변경 콜백
}
```

**Twitch IRC 프로토콜**: 표준 IRC over TCP. PING/PONG keepalive. 시청자 채팅에서 명령어 수신 → 게임 정보 응답.

### 4.9 LiveApi - HTTP REST API

```csharp
internal class LiveApi
{
    private static object _remoteTcp;               // TCP 리스너
    private static object _listenTcp;               // 리슨 소켓
    private static object _stream;                  // 네트워크 스트림
    private static object keepaliveTimer;           // Keepalive 타이머
    private static int KEEPALIVE_INTERVAL;          // Keepalive 주기
    private static object prev_tx_s;                // 이전 전송 문자열
    public static bool enabled;                     // 활성화 여부
}
```

**LiveApi**: 외부 시스템에서 VPT 서버를 HTTP로 제어하는 인터페이스. 실시간 게임 데이터 조회 및 그래픽 제어 가능.

### 4.10 Animation System (11 classes)

| Class | Purpose |
|-------|---------|
| `AnimationState` | 애니메이션 상태 머신 |
| `BoardCardAnimation` | 보드 카드 등장 애니메이션 |
| `CardBlinkAnimation` | 카드 깜빡임 (하이라이트) |
| `CardFace` | 카드 면 전환 |
| `CardUnhiliteAnimation` | 하이라이트 해제 |
| `FlagHideAnimation` | 플래그 숨김 |
| `GlintBounceAnimation` | 반짝임 바운스 효과 |
| `OutsCardAnimation` | 아웃 카드 표시 |
| `PanelImageAnimation` | 패널 이미지 전환 |
| `PanelTextAnimation` | 패널 텍스트 전환 |
| `PlayerCardAnimation` | 플레이어 카드 등장 |

### 4.11 Graphic Element Hierarchy (15+ classes)

```
GraphicElement (Base)
├── GraphicElementData (데이터 모델)
├── PlayerElement + PlayerElementData
├── BoardElement + BoardElementData
├── BlindsElement + BlindsElementData
├── ChipCount + ChipCountData
├── HistoryPanelElement + HistoryPanelElementData
├── FieldElement
├── ActionClockElement
├── OutsElement
├── TickerElement
├── StripLogoElement
├── StripRepeatElement
├── SplitScreenDividerElement
└── PanelHeaderElement / PanelFooterElement / PanelRepeatElement
```

### 4.12 UI Forms (15+ classes)

| Form | Purpose |
|------|---------|
| `main_form` | 메인 애플리케이션 (God Class) |
| `atem_form` | ATEM 스위처 설정 |
| `skin_edit` | 스킨 편집기 |
| `pip_edit` | PIP 편집기 |
| `di_pip_edit` | DI PIP 편집기 |
| `gfx_edit` | 그래픽 편집 |
| `ticker_edit` | 티커 편집 |
| `ticker_stats_edit` | 티커 통계 편집 |
| `auto_stats_edit` | 자동 통계 편집 |
| `flag_editor` | 플래그 편집 |
| `font_picker` | 폰트 선택 |
| `lang_edit` | 언어 편집 |
| `twitch_edit` | Twitch 설정 |
| `trial_form` | 평가판 알림 |
| `security_warning` | 보안 경고 |
| `DiagnosticsForm` | 진단 정보 |
| `LogWindow` | 로그 뷰어 |

### 4.13 Supporting Classes

| Class | Purpose |
|-------|---------|
| `video` | 비디오 설정/해상도 관리 |
| `video_mixer` | mmr.mixer 래퍼 |
| `media` | 미디어 파일 관리 |
| `playback` / `PlaybackVideo` | 녹화 파일 재생 |
| `pipcap` | PIP 캡처 |
| `cam_prev` / `cam_prop` | 카메라 프리뷰/속성 |
| `reader_config` / `reader_select` | RFID 리더 설정 |
| `reg_player` | 플레이어 등록 |
| `prev_pwd` / `get_settings_pwd` / `settings_pwd` | 비밀번호 관리 |
| `live_export` | 라이브 내보내기 |
| `vcomm` | 비디오 커뮤니케이션 |
| `vlive` | 라이브 스트리밍 |
| `XSplit` | XSplit 통합 |
| `ScreenSaver` | 화면 보호기 |
| `HandEvalServiceProxy` | hand_eval.dll 프록시 |
| `VPTWebsiteService` | 웹사이트 서비스 |
| `GameSave` | 게임 상태 저장/복원 |
| `Helper` | 유틸리티 |
| `log` | 로깅 |
| `Ping` | 네트워크 핑 |
| `Winner` | 승자 판정 |
| `CardsComparer` | 카드 비교 |
| `ColorAdjustment` | 색상 조정 |
| `DPoint` | Double 정밀도 좌표 |
| `split_settings` | 분할 화면 설정 |
| `video_repair` | 비디오 복구 |

---

## 5. Cross-Module Integration Map

### 5.1 Data Flow

```
[RFID Reader] ──► [RFIDv2.dll] ──► [vpt_server.main_form]
                                         │
                  ┌──────────────────────┤
                  ▼                      ▼
          [hand_eval.dll]         [net_conn.dll]
          (핸드 평가)              (네트워크 동기화)
                  │                      │
                  ▼                      ▼
          [vpt_server.gfx]        [Slave VPT Servers]
                  │
                  ▼
           [mmr.canvas]
           (DirectX GPU)
                  │
          ┌───────┼───────┐
          ▼       ▼       ▼
      [Live]  [Delayed] [Record]
      Output   Output    File
```

### 5.2 암호화 시스템 비교

| 속성 | net_conn.dll (enc.cs) | PokerGFX.Common (EncryptionService) | config (Skin) |
|------|----------------------|-------------------------------------|---------------|
| **알고리즘** | Rijndael (AES-256) | AES (System.Security) | AES (추정) |
| **키 유도** | PasswordDeriveBytes (PBKDF1) | Base64 직접 디코딩 | ConfuserEx 난독화 |
| **IV** | 하드코딩 "4390fjrfvfji9043" | 항상 0x00 (16바이트) | 불명 (난독화) |
| **패딩** | PKCS7 (enc), None (dec) | 기본 (PKCS7) | 불명 |
| **용도** | 네트워크 통신 | 설정 데이터 | 스킨 파일 (.vpt) |
| **키** | 하드코딩 문자열 | 하드코딩 Base64 | SKIN_PWD + SKIN_SALT |

### 5.3 스레드 모델

| Module | Thread | Purpose |
|--------|--------|---------|
| mmr.mixer | thread_worker | 라이브 프레임 렌더링 |
| mmr.mixer | thread_worker_audio | 오디오 처리 |
| mmr.mixer | thread_worker_delayed | 딜레이 프레임 렌더링 |
| mmr.mixer | thread_worker_write | 녹화 파일 쓰기 |
| mmr.mixer | thread_worker_process_delay | 딜레이 버퍼 관리 |
| mmr.renderer | thread_worker | 출력 디바이스 렌더링 |
| mmr.sink | _workerThread | MFSink STA 작업 |
| mmr.video_capture_device | thread_worker_get_frame | 프레임 캡처 |
| vpt_server.render | delayed_render_thread | 딜레이 렌더 이벤트 |
| net_conn.server | TCP Accept 스레드 | 클라이언트 수락 |
| net_conn.server_obj | 수신 스레드 | 클라이언트별 TCP 수신 |
| net_conn.client | UDP 타이머 | 서버 발견 |
| net_conn.client_obj | keepalive 타이머 | 연결 유지 |
| vpt_server.twitch | (keepalive_timer) | IRC PING/PONG |
| vpt_server.LiveApi | (keepaliveTimer) | HTTP keepalive |

**총 추정 동시 스레드 수**: 15-25개 (카메라/렌더러 수에 따라 변동)

---

## 6. Security Analysis

### 6.1 하드코딩된 암호화 키 (3곳)

| Location | Key Material | Risk |
|----------|-------------|------|
| `net_conn\enc.cs` | Password: `"45389rgjkonlgfds90439r043rtjfewp9042390j4f"` | CRITICAL |
| `net_conn\enc.cs` | Salt: `"dsafgfdagtds4389tytgh"`, IV: `"4390fjrfvfji9043"` | CRITICAL |
| `PokerGFX.Common\EncryptionConfiguration.cs` | Key: `"6fPz9r5pnJpUB0w0z1OeETXMwzF1jzU9g3z1Y5JzLxo="` | HIGH |
| `vpt_server\config.cs` | SKIN_HDR, SKIN_SALT, SKIN_PWD (난독화로 값 미확인) | HIGH |

### 6.2 Zero IV 사용

PokerGFX.Common의 EncryptionService는 IV를 항상 `new byte[16]` (모두 0)으로 설정한다. 이는 동일 키+동일 평문에서 항상 동일 암호문을 생성하여 패턴 분석에 취약하다.

### 6.3 PBKDF1 사용 (Deprecated)

net_conn.dll의 `PasswordDeriveBytes`는 PBKDF1 구현으로, .NET에서도 Obsolete로 표시된 약한 키 유도 함수다. PBKDF2 (`Rfc2898DeriveBytes`) 대비 보안성이 낮다.

### 6.4 ConfuserEx 난독화

vpt_server.exe의 핵심 로직 (config, slave 등)이 ConfuserEx로 보호되어 있다. 특징:
- `etype_0x34` 형태의 비정상적 메서드 시그니처
- 25+ 매개변수의 프록시 메서드
- XOR 기반 상수 난독화 (slave.cs에서 확인)
- Switch 테이블 기반 제어 흐름 난독화

### 6.5 COM Interop 보안

mmr.dll의 MFormats SDK, ATEM SDK 모두 COM Interop을 사용한다. COM 객체의 수명 관리를 `Marshal.ReleaseComObject()`로 수동 처리하며, 실패 시 메모리 누수 가능.

---

## 7. Reconstruction Notes

### 7.1 mmr.dll 재구현 시 핵심 사항

1. **SharpDX 대체**: SharpDX는 2019년 개발 중단. Vortice.Windows 또는 Silk.NET으로 마이그레이션 필요
2. **MFormats SDK**: 상용 라이브러리. 라이선스 없이 사용 불가. FFmpeg + DirectShow로 대체 가능
3. **DirectX 11 Shared Texture**: `bridge` 패턴은 멀티 GPU 컨텍스트에서 필수. DXGI SharedHandle 기반
4. **Producer-Consumer 패턴**: `BlockingCollection<MFFrame>` + `CancellationToken` 조합은 .NET 표준
5. **STA Thread**: MFormats COM 객체는 STA 필수. `TrySetApartmentState(STA)` 호출

### 7.2 vpt_server.exe 재구현 시 핵심 사항

1. **God Class 분해**: main_form을 MVVM 또는 MVP 패턴으로 분리
2. **DI 확장**: PokerGFX.Common의 DI 패턴을 전체 서비스에 적용
3. **ConfuserEx 보호 영역**: config, slave, atem의 난독화된 메서드는 런타임 디버깅으로만 복원 가능
4. **ATEM SDK**: Blackmagic Desktop Video SDK 별도 설치 필요
5. **Twitch IRC**: 표준 IRC 프로토콜이므로 재구현 용이

### 7.3 PokerGFX.Common.dll 재구현 시 핵심 사항

1. **Microsoft.Extensions.DependencyInjection**: .NET 표준 DI 그대로 사용 가능
2. **EncryptionService**: AES-256 재구현 시 Zero IV 대신 랜덤 IV 사용 권장
3. **Bugsnag**: 선택적 (Sentry 등 대체 가능)
4. **Version Validation**: PgfxApiConfiguration의 BaseUrl 확인 필요 (PokerGFX 서버)

### 7.4 미해결 영역

| 영역 | 상태 | 원인 |
|------|------|------|
| config의 암호화 메서드 | 복원 불가 | ConfuserEx 난독화 |
| slave의 핵심 동기화 로직 | 부분 복원 | ConfuserEx 난독화 |
| SKIN_HDR, SKIN_SALT, SKIN_PWD 실제 값 | 미확인 | 정적 초기화자 난독화 |
| game_variant_info 전체 필드 | 미확인 | 별도 파일 미발견 |
| MFormats SDK 초기화 파라미터 | 부분 확인 | 상용 SDK 문서 필요 |
| GameConfigurationService.Fitphd() | 시그니처만 확인 | 150+ 매개변수 (ConfuserEx) |
| AuthenticationService 핵심 메서드 | 복원 불가 | ConfuserEx 난독화 |
| boarssl SSLEngine 상태 머신 | 80% 복원 | 복잡한 state transition |

### 7.5 보완 문서 참조

이 문서에서 다루지 못한 vpt_server의 Phase 2/Phase 3 아키텍처 (195+ files)에 대한 상세 분석:

→ **`vpt_server_supplemental_analysis.md`** (GameTypes, Features, Services, Interfaces, SystemMonitors, Logging, Element Catalog, Enum Catalog, Security Supplement, Dependency Graph)

---

## Appendix A: mmr.dll Complete File List (62 files)

### Core Engine (4)
- `mixer.cs` - 메인 비디오 합성기
- `canvas.cs` - DirectX 11 렌더링 표면
- `bridge.cs` - GPU 간 텍스처 공유
- `helper.cs` - 유틸리티 (create_dc, wait_for_gpu, dispose)

### Capture (3)
- `video_capture_device.cs` - 비디오 캡처
- `audio_capture_device.cs` - 오디오 캡처
- `client.cs` - 네트워크 입력 클라이언트

### Output (3)
- `renderer.cs` - 비디오 출력
- `preview.cs` - 프리뷰 출력
- `sink.cs` - MFSink STA 래퍼

### Graphics (5)
- `image_element.cs` - 이미지 오버레이
- `text_element.cs` - 텍스트 오버레이
- `pip_element.cs` - PIP 오버레이
- `border_element.cs` - 보더 오버레이
- `custom_text_renderer.cs` - 커스텀 텍스트 렌더러

### Asset Management (2)
- `asset.cs` - 애니메이션 스프라이트
- `assets.cs` - 에셋 매니저

### Text/Font (5)
- `font.cs` - 폰트 관리
- `ResourceFontLoader.cs` - 리소스 폰트 로더
- `ResourceFontFileStream.cs` - 리소스 폰트 스트림
- `ResourceFontFileEnumerator.cs` - 리소스 폰트 열거자
- `frame_converter.cs` - 프레임 변환

### Media (2)
- `file.cs` - 파일 I/O
- `duplex_link.cs` - 양방향 링크

### Configuration (2)
- `ml_props.cs` - MFormats 속성
- `dshow_props.cs` - DirectShow 속성

### Enums (16)
- `timeshift.cs`, `record.cs`, `speed.cs`, `delay_modes.cs`
- `platform.cs`, `rate_control_mode.cs`, `audio_source.cs`
- `media_override.cs`, `log_level.cs`, `video_capture_device_type.cs`
- `rotate_type.cs`, `shadow_direction.cs`, `text_align.cs`
- `text_effect.cs`, `font_style.cs`, `font_weight.cs`

### Delegates (5)
- `frame_delegate.cs`, `frame_grab_delegate.cs`
- `media_finished_delegate.cs`, `fill_audio_buffer_delegate.cs`
- `error_delegate.cs`

### Models (5)
- `pip.cs`, `size.cs`, `msg.cs`
- `string_col_object.cs`, `col_replace.cs`
- `device_line.cs`, `ticker_finished_callback.cs`, `log_callback.cs`

### DirectShow COM (8)
- `dshow/IAMCameraControl.cs`, `CameraControlProperty.cs`, `CameraControlFlags.cs`
- `dshow/IAMVideoProcAmp.cs`, `VideoProcAmpProperty.cs`, `VideoProcAmpFlags.cs`
- `dshow/IAMVfwCaptureDialogs.cs`, `VfwCaptureDialogs.cs`
