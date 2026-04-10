# Clone PRD Wave 2: GPU 렌더링, 그래픽 요소, Skin, RFID

**Product Requirements Document - Clone Implementation**
**Version**: 1.0.0
**Date**: 2026-02-13
**Scope**: 섹션 5-8 (실시간 GPU 렌더링, 그래픽 요소, Skin 시스템, RFID 카드 리더)

---

## 5. 실시간 GPU 렌더링 (mmr.dll)

### 5.1 파이프라인 아키텍처

![GPU Pipeline Architecture](../images/mockups/gpu-pipeline.png)

mmr.dll은 DirectX 11 GPU 기반 실시간 비디오 합성 엔진이다. Medialooks MFormats SDK를 래핑하여 비디오 캡처, 믹싱, 렌더링, 녹화를 수행한다. 핵심 설계 패턴은 Producer-Consumer 멀티스레드 파이프라인이다.

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

내부 클래스 계층 (62 파일):

| Category | Classes | Description |
|----------|---------|-------------|
| **Core Engine** | `mixer`, `canvas`, `bridge`, `helper` | GPU 파이프라인 핵심 |
| **Capture** | `video_capture_device`, `audio_capture_device` | 입력 디바이스 |
| **Output** | `renderer`, `preview`, `sink` | 출력 디바이스 |
| **Graphics** | `image_element`, `text_element`, `pip_element`, `border_element` | 그래픽 레이어 |
| **Asset** | `asset`, `assets`, `bridge` | 텍스처 관리 |
| **Text** | `font`, `custom_text_renderer`, `ResourceFontLoader` | DirectWrite 텍스트 |
| **Enums** | `timeshift`, `record`, `speed`, `delay_modes`, `platform` 등 16개 | 상태 열거형 |
| **DirectShow** | `IAMCameraControl`, `IAMVideoProcAmp` 등 8개 | COM Interop |
| **Delegates** | `frame_delegate`, `error_delegate` 등 5개 | 콜백 |
| **Models** | `pip`, `size`, `msg`, `device_line` 등 | 데이터 모델 |

### 5.2 5-Thread Worker Architecture

`mixer`는 mmr.dll의 핵심 클래스로, 90+ 필드와 5개 워커 스레드를 관리한다.

| Thread | 역할 | 데이터 소스 |
|--------|------|-----------|
| `thread_worker` | 라이브 프레임 GPU 렌더링 | `BlockingCollection<MFFrame> live_frames` |
| `thread_worker_audio` | 오디오 캡처 + 믹싱 | `AutoResetEvent are_audio` |
| `thread_worker_delayed` | 딜레이 프레임 렌더링 | `BlockingCollection<MFFrame> delayed_frames` |
| `thread_worker_write` | 녹화 파일 쓰기 | `BlockingCollection<MFFrame> write_frames` |
| `thread_worker_process_delay` | 딜레이 버퍼 관리 | `AutoResetEvent are_delay` |

각 스레드의 동작 흐름:

```
thread_worker (Main Live)
├── BlockingCollection<MFFrame> live_frames에서 프레임 수신
├── canvas_live에 GPU 렌더링
├── on_frame 콜백으로 결과 전달
└── sync_frames에 동기화 프레임 푸시

thread_worker_audio
├── AutoResetEvent are_audio 대기
├── ext_audio_buffer에서 오디오 캡처
└── 오디오 믹싱 처리

thread_worker_delayed
├── BlockingCollection<MFFrame> delayed_frames에서 프레임 수신
├── MDelayClass로 타임시프트 적용
├── canvas_delayed에 GPU 렌더링
└── on_frame 콜백으로 딜레이 결과 전달

thread_worker_write
├── BlockingCollection<MFFrame> write_frames에서 프레임 수신
├── MFWriterClass로 파일 기록
└── 녹화 상태 관리 (_recording 플래그)

thread_worker_process_delay
├── MDelayClass 내부 딜레이 버퍼 처리
├── AutoResetEvent are_delay 대기
└── 딜레이 프레임 생성 → delayed_frames 큐
```

mixer 핵심 필드 (90개):

| Category | Fields | Description |
|----------|--------|-------------|
| **Delegate Callbacks** | `on_frame`, `on_frame_grab`, `media_finished`, `on_error` | 프레임 완료, 캡처, 재생 완료, 에러 콜백 |
| **Dual Canvas** | `canvas_live`, `canvas_delayed` | 라이브/딜레이 독립 캔버스 |
| **MFormats SDK** | `mf_live`, `mdelay`, `mf_preview`, `mf_factory`, `mf_renderer`, `mf_writer`, `mf_reader`, `ext_audio_buffer` | 캡처, 딜레이, 프리뷰, 팩토리, 렌더러, 녹화, 재생, 오디오 |
| **Device Lists** | `_video_capture_devices`, `_audio_capture_devices`, `_audio_output_devices`, `_previews`, `_renderers` | 입출력 디바이스 목록 |
| **PIP** | `_pips`, `_new_pips`, `pip_update` | Picture-in-Picture 관리 |
| **Frame Queues** | `live_frames`, `delayed_frames`, `write_frames`, `sync_frames` + CancellationToken 3개 | Producer-Consumer 큐 |
| **Synchronization** | `live_lock_obj`, `delay_lock_obj`, `are_delay`, `are_audio` | 스레드 동기화 |
| **State Flags** | `running`, `_delay_enabled`, `_sink_enabled`, `_recording`, `_reset_gpu`, `_force_sw_encode`, `_sync_live_delay` 등 13개 | 런타임 상태 |
| **Timing** | `_live_rate_control`, `_delayed_rate_control`, `live_fps`, `delayed_fps`, `_delay_period`, `_test_delay` | 프레임 레이트, 딜레이 시간 |
| **Media Override** | `_media_override`, `media_override_start_index`, `_media_override_start/stop/seek_to_pos` 등 8개 | 미디어 오버라이드 |
| **Configuration** | `_platform`, `_back_col`, `_volume`, `_audio_capture_delay`, `_video_sync_delay`, `_sink_live_delayed`, `_record_mode`, `_speed` 등 | 전체 설정 |

### 5.3 Dual Canvas System

mixer는 Live와 Delayed 두 개의 독립 캔버스를 동시 운영한다:

```
Video Input → [Live Canvas] → Live Output (실시간)
                    ↓
              [Delay Buffer]
                    ↓
             [Delayed Canvas] → Delayed Output (N초 지연)
```

- **Live Canvas**: 실시간 방송 출력 (카메라 + 그래픽 오버레이)
- **Delayed Canvas**: 시간차 방송 출력 (동일 그래픽, 설정 가능한 N초 지연)
- `_sync_live_delay`: Live/Delayed 프레임 동기화 옵션
- `_delay_period`: 딜레이 시간 (TimeSpan)

### 5.4 DirectX 11 Rendering

`canvas`는 DirectX 11 기반 2D 렌더링 표면이다.

- **Device**: D3D11 Device + D2D Device + DirectWrite Factory
- **Texture**: `Texture2D` 렌더 타겟 + 더블 버퍼링 (`Bitmap[2]`)
- **GPU Effects Chain**: Crop → Transform → Brightness → Alpha → ColorMatrix → HueRotation
- **Cross-GPU Texture Sharing**: `bridge` 클래스 - DXGI SharedHandle 기반

canvas 핵심 필드:

| Category | Fields | Description |
|----------|--------|-------------|
| **DirectX 11 Core** | `d3d_device`, `dxgi_device`, `d2d_device`, `dw_factory`, `dc` | D3D11, DXGI, D2D, DirectWrite, DeviceContext |
| **Rendering Resources** | `t2d`, `bm_buffer[2]`, `render_items` | 렌더 타겟 텍스처, 더블 버퍼, 렌더 아이템 큐 |
| **Graphic Layers** | `image_elements`, `text_elements`, `pip_elements`, `border_elements` | Z-order 레이어 리스트 |
| **State** | `_w`, `_h`, `_adapter_index`, `_background_colour`, `safety_lock` | 해상도, GPU 인덱스, 배경색 |

**초기화 흐름** (canvas.ctor):
1. `_background_colour = Color4(1.0, 0.0, 0.0, 0.0)` - Alpha=1, RGB=0 (투명 흑)
2. 4개 그래픽 레이어 리스트 초기화
3. `bm_buffer = new Bitmap[2]` - 더블 버퍼링
4. `init_devices()` 호출 - D3D11 Device, D2D Device 생성
5. `helper.create_dc()` 호출 - DeviceContext, Texture2D 생성

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

### 5.5 Cross-GPU Texture Sharing (bridge)

`bridge`는 두 독립 GPU 컨텍스트(canvas와 asset) 간 텍스처를 공유하는 핵심 메커니즘이다.

| Side | Fields | Description |
|------|--------|-------------|
| **Canvas측** | `canvas_d3d_device`, `canvas_d2d_context`, `canvas_d2d_bitmap` | 렌더링 대상 |
| **Asset측** | `asset_d3d_device`, `asset_d2d_context`, `asset_d2d_bitmap` | 원본 텍스처 |
| **Shared** | `_t2d` (Asset측), `t2d` (Canvas측), `prev_bitmap` | 공유 텍스처, 캐시 |

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

### 5.6 renderer / sink 출력 클래스

**renderer** - 비디오 출력 디바이스:

| Field | Description |
|-------|-------------|
| `_mf_renderer` | MFormats 렌더러 |
| `thread_worker` | 백그라운드 렌더 스레드 |
| `render_frames` | BlockingCollection 프레임 큐 |
| `_live_delayed` | Live or Delayed 선택 |
| `_enabled`, `_is_ndi`, `_background`, `_rate_control` | 렌더링 모드 플래그 |

렌더링 모드:
- **Foreground** (`_background=false`): MFRendererClass.ReceiverFramePut() 직접 호출
- **Background** (`_background=true`): MFClone → BlockingCollection → thread_render()
- **NDI**: `_is_ndi=true` 시 NDI 프로토콜 출력
- **Fill & Key**: `keying` 속성으로 external keyer 지원 (Decklink 하드웨어)

**프레임 드롭 방지**: `thread_render()`에서 큐 크기 > 30이면 오래된 프레임 일괄 폐기 (ReleaseComObject)

**sink** - MFSink STA Worker:

| Field | Description |
|-------|-------------|
| `_workQueue` | BlockingCollection<SinkWorkItem> |
| `_workerReady` | ManualResetEventSlim |
| `_workerThread` | STA 스레드 (COM 필수) |
| `mf_sink` | MFormats Sink |

STA 스레드 요구사항: MFSinkClass는 COM STA 모드 필수. `TrySetApartmentState(ApartmentState.STA)` 호출. Thread Name: `"MFSinkWorker"`, IsBackground=true.

### 5.7 그래픽 레이어 (Z-order)

| 레이어 | 요소 | 설명 |
|--------|------|------|
| 1 (최하단) | `image_element` | 이미지 오버레이 (스프라이트, 로고) |
| 2 | `text_element` | 텍스트 오버레이 (Ticker, Reveal 효과) |
| 3 | `pip_element` | Picture-in-Picture (카메라 뷰) |
| 4 (최상단) | `border_element` | 보더 프레임 |

### 5.8 출력 모드

| 모드 | 설명 |
|------|------|
| **Live** | 실시간 출력 |
| **Delayed** | 시간차 출력 |
| **Record** | 파일 녹화 (Live/Delayed/Both) |
| **NDI** | NewTek NDI 네트워크 출력 |
| **Fill & Key** | External Keyer (Decklink 하드웨어) |

**녹화 모드**: `live`, `live_no_overlay`, `delayed`, `delayed_no_overlay`
**재생 속도**: `normal`, `x2`, `x4`, `reverse_x2`, `reverse_x4`

### 5.9 GPU 벤더별 코덱 설정

| GPU | 녹화 코덱 | 스트림 코덱 | 디코더 |
|-----|----------|-----------|--------|
| NVIDIA | `n264` (NVENC) CQP qp=20 | `n264` CBR 5M low_latency | `decoder.nvidia='true'` |
| AMD | `h264_amf` 50M | `h264_amf` 10M | default |
| Intel QSV | `q264hw` CBR 50M | `q264hw` CBR 5M | `decoder.quicksync=1` |
| Software | `libopenh264` 50M | `libopenh264` 5M | default |

컨테이너: MP4 (녹화), MPEGTS (스트리밍). 오디오: AAC 192k

### 5.10 스트리밍 프로토콜

| 프로토콜 | 구현 | 설명 |
|---------|------|------|
| **SRT** | `duplex_link` (30필드, 33메서드) | `srt://?mode=listener&passphrase=` / `srt://?mode=caller` |
| **NDI** | `[NDI]_` prefix 네이밍 | `NDI_WAIT_PERIOD_MS` 타임아웃 |
| **BMD** | Blackmagic `decklink`/`blackmagic` | 하드웨어 출력 |

### 5.11 지원 입력 디바이스

| 타입 | 설명 |
|------|------|
| Decklink | Blackmagic Design 캡처 카드 |
| USB | USB 웹캠 |
| NDI | NewTek NDI 네트워크 소스 |
| URL | RTMP/RTSP/HLS 스트림 |

`video_capture_device_type`: `unknown`, `dshow`, `NDI`, `BMD`, `network`

`video_capture_device` 핵심 필드:

| Category | Fields | Description |
|----------|--------|-------------|
| **MFormats** | `_mf_live`, `_mf_reader`, `mf_factory` | 라이브 캡처, 파일 입력, 프레임 팩토리 |
| **DirectShow** | `_dshow_IAMCameraControl`, `_dshow_IAMVideoProcAmp`, `_dshow_IAMVfwCaptureDialogs` | COM Interop 카메라 제어 |
| **Frame** | `frames` (ConcurrentQueue), `thread_worker_get_frame`, `are_frame` | 캡처 프레임 큐, 스레드, 이벤트 |
| **Config** | `_id`, `_name`, `_url`, `_video_capture_device_type`, `_rotate`, `_enabled`, `_capture_audio` | 디바이스 식별, 타입, 회전, 활성화 |

### 5.12 Enum & Configuration Types

| Enum | Values | Purpose |
|------|--------|---------|
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

### 5.13 [Clone] 재구현 전략

#### SharpDX → Vortice.Windows 마이그레이션

SharpDX는 2019년 개발 중단. GPU 렌더링 래퍼를 Vortice.Windows로 마이그레이션한다.

| 항목 | 원본 | Clone |
|------|------|-------|
| **DirectX Wrapper** | SharpDX (개발 중단) | Vortice.Windows (DirectX 12 지원, 활발한 유지보수) |
| **DirectX 버전** | DirectX 11 | DirectX 12 (하위 호환 DirectX 11 유지) |
| **2D 렌더링** | SharpDX.Direct2D1 | Vortice.Direct2D1 |
| **텍스트** | SharpDX.DirectWrite | Vortice.DirectWrite |
| **DXGI** | SharpDX.DXGI | Vortice.DXGI |

Vortice.Windows는 API 구조가 SharpDX와 유사하므로 1:1 매핑이 가능하다. `Device`, `DeviceContext`, `Texture2D`, `Bitmap` 등 핵심 타입의 네임스페이스만 변경하면 된다.

#### MFormats SDK → FFmpeg.AutoGen 대체

MFormats SDK는 Medialooks 상용 라이브러리(CompanyID `13751`)로, 라이선스 없이 사용 불가하다. FFmpeg.AutoGen(MIT 라이선스)으로 대체한다.

| 기능 | MFormats SDK | FFmpeg.AutoGen |
|------|-------------|----------------|
| **비디오 캡처** | MFLiveClass | `avformat_open_input` + `avcodec_receive_frame` |
| **프레임 팩토리** | MFFactoryClass | `av_frame_alloc` + `sws_scale` |
| **파일 녹화** | MFWriterClass | `avformat_alloc_output_context2` + `avcodec_send_frame` |
| **파일 재생** | MFReaderClass | `avformat_open_input` + demux 루프 |
| **프리뷰** | MFPreviewClass | 커스텀 Direct2D 프리뷰 구현 |
| **딜레이** | MDelayClass | 커스텀 링 버퍼 기반 딜레이 구현 |
| **Sink** | MFSinkClass | `avformat_write_header` + mux 파이프라인 |
| **라이선스** | 상용 (CompanyID 필수) | MIT (완전 무료) |

#### 5-Thread Worker → Channel<T> 기반 재설계

`BlockingCollection<MFFrame>` + `Thread` 조합을 .NET 6+ `System.Threading.Channels.Channel<T>` + `Task` 기반으로 현대화한다.

| 항목 | 원본 | Clone |
|------|------|-------|
| **큐** | `BlockingCollection<MFFrame>` | `Channel<VideoFrame>` (bounded) |
| **스레드** | `new Thread(ThreadStart)` | `Task.Run` + `async/await` |
| **취소** | `CancellationTokenSource` | 동일 (CancellationToken 패턴 유지) |
| **동기화** | `AutoResetEvent`, `lock` | `SemaphoreSlim`, `Channel` 자체 backpressure |
| **프레임 드롭** | 수동 큐 크기 체크 (>30) | `BoundedChannelOptions.FullMode.DropOldest` |

5-Thread 아키텍처 자체는 검증된 설계이므로 동일 구조를 유지하되, 각 Thread를 async Task로 전환한다.

#### Dual Canvas → 동일 개념 유지

Live/Delayed 이중 캔버스 아키텍처는 포커 방송의 핵심 요구사항이므로 동일 개념을 유지한다. 각 캔버스는 독립 `DeviceContext`와 `Texture2D`를 가진다.

#### GPU Effects Chain → ComputeShader 활용

현재 Direct2D Effects(Crop, Transform, Brightness, Alpha, ColorMatrix, HueRotation) 체인은 유지하되, 고성능이 필요한 효과에 DirectX 12 ComputeShader를 활용한다.

#### Cross-GPU Texture Sharing

bridge 클래스의 DXGI SharedHandle 기반 텍스처 공유 패턴은 DirectX 12에서도 동일하게 지원된다. `ID3D12Resource::CreateSharedHandle` → `OpenSharedHandle`로 마이그레이션한다.

---

## 6. 그래픽 요소 시스템

### 6.1 Element Hierarchy

![GraphicElement Class Hierarchy](../images/mockups/element-hierarchy.png)

그래픽 요소 시스템은 mmr.dll의 4개 기본 요소와 vpt_server의 15+ 상위 요소로 구성된다.

#### mmr.dll 기본 요소 (GPU 렌더링 레벨)

**image_element** - 이미지 오버레이:

| Category | Fields | Description |
|----------|--------|-------------|
| **DirectX** | `_dc`, `_d3d_device` | DeviceContext, D3D Device |
| **Asset** | `_asset`, `_overlay_asset` | 애니메이션 스프라이트, 오버레이 에셋 |
| **Bridge** | `_bridge`, `_overlay_bridge` | GPU 컨텍스트 브릿지 (Cross-GPU Sharing) |
| **Effects Pipeline** | `_effect_crop`, `_effect_transform`, `_effect_brightness`, `_effect_alpha`, `_effect_col_matrix`, `_effect_opacity_matrix`, `_effect_hue` | Direct2D Effects 7개 체인 |
| **Properties** | `_opacity`, `_brightness`, `_hue`, `_tint_r/g/b`, `_scale`, `_z_pos`, `_rotate_angle` | 시각 속성 |
| **Animation** | `_seq_num`, `_frame_num` | 스프라이트 시퀀스 |
| **Flags** | `_visible`, `_flip_x`, `_remove_partial_alpha` | 가시성, 반전, 알파 클리핑 |

GPU Effects Chain: `Crop → Transform → Brightness → Alpha → ColorMatrix → HueRotation`
Alpha Table: `_alpha_table_remove_partial[256]` - 인덱스 < 2이면 0.0, 이상이면 1.0 (하드 알파 클리핑)

**text_element** - 텍스트 오버레이:

| Category | Fields | Description |
|----------|--------|-------------|
| **DirectWrite** | `text_layout`, `text_format`, `_font_collection`, `_font_style`, `_font_weight` | 레이아웃, 포맷, 폰트 컬렉션 |
| **Brushes** | `_text_brush`, `_shadow_brush`, `_back_brush` | 텍스트, 그림자, 배경 브러시 |
| **Effects** | `_text_effect`, `_shadow_direction`, `_text_align`, `_custom_text_renderer` | Ticker, Reveal, 그림자, 정렬 |
| **Animation** | `_ticker_offset`, `_reveal_offset`, `_effect_speed`, `ticker_finished_notified` | 스크롤/표시 오프셋, 속도 |
| **Resources** | `_local_bitmap`, `_embedded_bitmap`, `_font_data_hash` | 로컬/임베디드 이미지, 커스텀 폰트 |

텍스트 효과 타입: Ticker (수평 스크롤), Reveal (글자별 표시), Static, Shadow

**pip (Picture-in-Picture)**:

| Field | Description |
|-------|-------------|
| `src_rect`, `dst_rect` | 소스/대상 영역 (Rectangle) |
| `opacity` | 투명도 (float) |
| `z_pos` | Z-order |
| `border_thickness`, `border_colour` | 테두리 두께, 색상 |
| `visible`, `dev_index`, `cloned` | 가시성, 캡처 디바이스 인덱스, 복제 여부 |

PIP는 카메라 입력을 그래픽 캔버스의 임의 위치에 배치한다. `dev_index`로 어떤 카메라를 표시할지 선택.

#### vpt_server 상위 요소 (비즈니스 로직 레벨)

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
| `CardFace` | 카드 | 면 전환 (앞/뒤) |
| `AnimationState` | 전체 | 상태 머신 |

#### AnimationState enum (16 states)

```
FadeIn=0, Glint=1, GlintGrow=2, GlintRotateFront=3,
GlintShrink=4, PreStart=5, ResetRotateBack=6, ResetRotateFront=7,
Resetting=8, RotateBack=9, Scale=10, SlideAndDarken=11,
SlideDownRotateBack=12, SlideUp=13, Stop=14, Waiting=15
```

#### Animation Timing 설정 (config 클래스)

| Field | Description |
|-------|-------------|
| `IMAGE_LOOP` | 이미지 루프 프레임 수 |
| `IMAGE_INTRO` | 인트로 프레임 수 |
| `IMAGE_OUTRO` | 아웃트로 프레임 수 |
| `ANIM_IN_FADE_START_POS` | 페이드인 시작 위치 (float) |
| `ANIM_IN_FADE_END_POS` | 페이드인 종료 위치 (float) |
| `ANIM_OUT_FADE_START_POS` | 페이드아웃 시작 위치 (float) |
| `ANIM_OUT_FADE_END_POS` | 페이드아웃 종료 위치 (float) |

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

### 6.4 [Clone] 재구현 전략

#### Element → 추상 base class + 인터페이스 기반 설계

원본은 `image_element`, `text_element` 등이 독립적으로 존재한다. Clone에서는 공통 인터페이스를 정의하여 일관된 렌더링 파이프라인을 구성한다.

```csharp
// Clone 설계
public interface IGraphicElement
{
    int ZOrder { get; }
    bool Visible { get; }
    RectangleF Bounds { get; }
    void Render(DeviceContext dc);
    void Update(TimeSpan elapsed);
    void Dispose();
}

public abstract class GraphicElementBase : IGraphicElement, IDisposable
{
    protected DeviceContext _dc;
    protected float _opacity;
    protected bool _visible;
    // 공통 GPU Effects Chain
    protected EffectsPipeline _effects;
}

public class ImageElement : GraphicElementBase { }
public class TextElement : GraphicElementBase { }
public class PipElement : GraphicElementBase { }
public class BorderElement : GraphicElementBase { }
```

#### 11개 Animation → State Machine 패턴 재설계

원본의 AnimationState enum(16 states)은 유지하되, 각 Animation 클래스를 State Machine 패턴으로 통합한다.

```csharp
// Clone 설계
public interface IAnimation
{
    AnimationState CurrentState { get; }
    bool IsComplete { get; }
    void Start();
    void Update(TimeSpan elapsed);
    void Reset();
}

public class AnimationStateMachine
{
    private readonly Dictionary<AnimationState, IAnimationHandler> _handlers;
    private AnimationState _current;

    public void Transition(AnimationState next) { }
    public void Update(TimeSpan elapsed) { }
}
```

#### ConfigurationPreset 99+ 필드 → 도메인별 분할

99+ 필드의 메가 DTO를 도메인별로 분할한다:

| Domain | Class | Fields | Description |
|--------|-------|:------:|-------------|
| **Layout** | `LayoutConfig` | ~15 | board_pos, gfx_vertical, gfx_bottom_up, margins 등 |
| **Display** | `DisplayConfig` | ~10 | at_show, fold_hide, card_reveal, show_rank 등 |
| **Transition** | `TransitionConfig` | ~6 | trans_in/out type + time |
| **Stats** | `StatsConfig` | ~20 | auto_stat_*, ticker_stat_* |
| **ChipPrecision** | `ChipPrecisionConfig` | ~8 | 8개 영역별 정밀도 |
| **Currency** | `CurrencyConfig` | ~4 | currency_symbol, show_currency 등 |
| **Logo** | `LogoConfig` | ~3 | panel_logo, board_logo, strip_logo |
| **Composite** | `GraphicsPreset` | - | 위 7개 Config 통합 |

#### Transition 효과 → GPU Shader 기반 구현

Direct2D Effects 기반 전환 효과를 유지하되, 커스텀 전환 효과에 ComputeShader를 활용한다.

---

## 7. Skin 시스템

기존 PRD에서는 섹션 6.4에 포함되어 있던 Skin 시스템을 별도 섹션으로 승격한다. Skin은 그래픽 외관 전체를 결정하는 핵심 자산이며, 별도 파일 포맷, 암호화, 에디터, 라이선스 인증 체계를 갖추고 있다.

### 7.1 Skin 파일 (.vpt / .skn)

| 속성 | 값 |
|------|-----|
| **기본 스킨** | `vpt_server.Skins.default.skn` (내장 리소스) |
| **파일 확장자** | `.vpt`, `.skn` |
| **저장 경로** | `%APPDATA%\RFID-VPT` |

### 7.2 Skin 파일 구조

```
[SKIN_HDR]         → 매직 바이트 (파일 식별)
[Encrypted Data]   → SKIN_PWD + SKIN_SALT로 AES 암호화
  └── JSON/Binary  → 그래픽 레이아웃, 색상, 폰트, 이미지 에셋
[CRC32]            → skin_crc로 무결성 검증
```

### 7.3 AES 암호화

| 속성 | 값 |
|------|-----|
| **알고리즘** | AES (System.Security.Cryptography) |
| **키 재료** | `SKIN_HDR` (헤더 매직) + `SKIN_SALT` (솔트) + `SKIN_PWD` (비밀번호) |
| **무결성** | CRC32 검증 (`skin_crc`) |
| **런타임 상태** | `config.serialized_skin` (직렬화된 스킨 데이터 byte[]) |

config 클래스의 Skin 관련 필드:

| Field | Type | Description |
|-------|------|-------------|
| `SKIN_HDR` | `static byte[]` | 스킨 파일 헤더 매직 바이트 |
| `SKIN_SALT` | `static byte[]` | 암호화 솔트 |
| `SKIN_PWD` | `static string` | 암호화 비밀번호 |
| `skin_crc` | `static int` | 로드된 스킨 CRC |
| `serialized_skin` | `static byte[]` | 직렬화된 스킨 데이터 |
| `save_path_user` | `static string` | 사용자 저장 경로 |
| `save_path` | `static string` | 기본 저장 경로 |

### 7.4 Skin 인증

```
skin_auth_result { no_network=0, permit=1, deny=2 }
```

마스터 서버를 통해 스킨 인증을 수행한다. 네트워크 장애 시 `no_network`로 기존 스킨 지속 사용을 허용한다.

### 7.5 Master-Slave 스킨 동기화

Slave 인스턴스는 Master에서 스킨을 다운로드한다.

| Field | Description |
|-------|-------------|
| `_skinPosition` | 스킨 다운로드 진행 위치 |
| `downloadSkinCrc` | 다운로드 대상 스킨 CRC |
| `downloadSkinList` | 다운로드 스킨 목록 |

동기화 항목: 스킨 파일 (.vpt), 그래픽 설정, 관련 에셋

### 7.6 Skin Editor

`skin_edit` Form으로 시각적 편집:
- 그래픽 요소 위치/크기 조정
- 색상, 폰트, 투명도 설정
- 프리뷰 + 실시간 반영

관련 UI Forms:

| Form | 역할 |
|------|------|
| `skin_edit` | 스킨 편집 메인 |
| `gfx_edit` | 그래픽 요소 편집 |
| `font_picker` | 폰트 선택 |
| `flag_editor` | 국기 편집 |
| `ticker_edit` | 티커 편집 |
| `ticker_stats_edit` | 티커 통계 편집 |

### 7.7 [Clone] 재구현 전략

#### .vpt/.skn 호환 모드 vs 신규 포맷

두 가지 접근 방식을 동시에 지원한다:

| 모드 | 포맷 | 용도 |
|------|------|------|
| **호환 모드** | `.vpt` / `.skn` (기존 포맷) | 기존 스킨 자산 활용 |
| **신규 포맷** | `.pgfxskin` (JSON + ZIP) | 새 스킨 개발 |

**신규 포맷 설계**:
```
skin-name.pgfxskin (ZIP archive)
├── manifest.json       → 스킨 메타데이터 (이름, 버전, 작성자)
├── layout.json         → 그래픽 요소 배치 정보
├── styles.json         → 색상, 폰트, 투명도 설정
├── assets/             → 이미지, 스프라이트 리소스
│   ├── cards/
│   ├── backgrounds/
│   └── icons/
└── preview.png         → 스킨 미리보기 이미지
```

#### 스킨 에디터 → WPF/Avalonia 기반 WYSIWYG

원본 WinForms 기반 `skin_edit`를 WPF 또는 Avalonia UI로 재구현한다.

| 기능 | 원본 (WinForms) | Clone (WPF/Avalonia) |
|------|----------------|---------------------|
| **드래그 앤 드롭** | 제한적 | 네이티브 지원 |
| **실시간 프리뷰** | 별도 패널 | DirectX 통합 렌더링 |
| **Undo/Redo** | 미지원 (추정) | Command 패턴 기반 |
| **속성 편집** | NumericUpDown, ColorDialog | PropertyGrid + 바인딩 |
| **크로스 플랫폼** | Windows Only | Avalonia 시 Linux/macOS 가능 |

#### 암호화 → AES-GCM 또는 단순 서명 검증

원본의 AES 암호화 + CRC 검증 체계를 현대화한다:

| 항목 | 원본 | Clone |
|------|------|-------|
| **암호화** | AES (SKIN_PWD + SKIN_SALT) | AES-GCM (인증 암호화) 또는 비암호화 |
| **무결성** | CRC32 | SHA-256 HMAC 서명 |
| **키 관리** | 하드코딩 (ConfuserEx 난독화) | 환경 변수 또는 키 파일 |
| **인증** | `skin_auth_result` (서버 기반) | 로컬 서명 검증 (오프라인 우선) |

---

## 8. RFID 카드 리더 (RFIDv2.dll)

### 8.1 Dual Transport Architecture

![RFID Dual Transport Architecture](../images/mockups/rfid-dual-transport.png)

RFIDv2.dll은 26개 타입(57KB)으로 구성된 RFID 카드 리더 통신 모듈이다. SkyeTek(구형)과 v2(신형) 두 세대의 리더 모듈을 통합 관리한다.

```
reader_module (통합 관리)
    ├── skye_module (SkyeTek 구형)
    │   └── USB HID only
    └── v2_module (Rev2 신형)
        ├── TCP/WiFi (네트워크)
        │   └── BearSSL TLS 1.2
        └── USB (폴백)
```

파일 구조 (26 types):

| Category | Files | Description |
|----------|-------|-------------|
| **Core** | `reader_module`, `v2_module`, `skye_module`, `modules` | 리더 통합 관리, Rev2, SkyeTek, 팩토리 |
| **Network** | `net`, `client_obj`, `module_stream`, `_config_net`, `state` | TCP 통신, 클라이언트, 스트림, 설정, 상태 |
| **Data** | `tag`, `tag_info`, `poll_node`, `TagEventTelemetry` | 태그 데이터, 메타데이터, 폴링, 진단 |
| **Enums** | `reader_state`, `connection_type`, `module_type`, `wlan_state`, `rx_type`, `config_type`, `transport_event_type` | 상태 열거형 7개 |
| **Delegates** | `tag_event_delegate`, `calibrate_delegate`, `state_changed_delegate`, `firmware_update_delegate`, `rx_delegate`, `transport_event_delegate` | 콜백 6개 |

### 8.2 하드웨어 지원

| 모듈 | 연결 | 보안 | 안테나 |
|------|------|------|--------|
| **SkyeTek** (구형) | USB HID | 없음 | 단일 |
| **v2 Rev1** | TCP/WiFi + USB | TLS 1.2 (BearSSL) | REV1_MAX_PHYS + REV1_MAX_VIRT |
| **v2 Rev2** | TCP/WiFi + USB | TLS 1.2 (BearSSL) | REV2_MAX_PHYS + REV2_MAX_VIRT |

하드웨어 리비전별 안테나:

| 리비전 | 물리 안테나 | 가상 안테나 | 기본 칼리브레이션 맵 |
|--------|-----------|-----------|---------------------|
| Rev1 | `REV1_MAX_PHYS_ANTENNAS` | `REV1_MAX_VIRT_ANTENNAS` | `REV1_DEFAULT_CAL_MAP` |
| Rev2 | `REV2_MAX_PHYS_ANTENNAS` | `REV2_MAX_VIRT_ANTENNAS` | `REV2_DEFAULT_CAL_MAP` |

### 8.3 Reader State Machine

![Reader State Machine](../images/mockups/reader-state-machine.png)

**reader_state:**

| 값 | 이름 | 설명 |
|:--:|------|------|
| 0 | `disconnected` | 연결 해제 |
| 1 | `connected` | TCP 연결됨 |
| 2 | `negotiating` | TLS 핸드셰이크 중 |
| 3 | `ok` | 정상 동작 |

**wlan_state:**

| 값 | 이름 | 설명 |
|:--:|------|------|
| 0 | `off` | WiFi 꺼짐 |
| 1 | `on` | WiFi 켜짐 |
| 2 | `connected_reset` | 연결 후 리셋 |
| 3 | `ip_acquired` | IP 획득 완료 |
| 4 | `not_installed` | WiFi 미설치 |

**module_type:** `skyetek=0`, `v2=1`
**connection_type:** `usb=0`, `wifi=1`

### 8.4 v2_module 핵심 필드

| Field | Type | Description |
|-------|------|-------------|
| `on_tag_event` | `tag_event_delegate` | 카드 감지 콜백 |
| `on_calibrate` | `calibrate_delegate` | 칼리브레이션 콜백 |
| `on_state_changed` | `state_changed_delegate` | 상태 변경 콜백 |
| `on_firmware_update_event` | `firmware_update_delegate` | 펌웨어 업데이트 콜백 |
| `BASE32` | `List<char>` | Base32 인코딩 문자셋 |
| `KEEPALIVE_INTERVAL` | `static int` | Keepalive 간격 |
| `NEGOTIATE_INTERVAL` | `static int` | 협상 타임아웃 |
| `HW_REV` | `protected int` | 하드웨어 리비전 |
| `_antenna` | `protected byte` | 현재 안테나 번호 |
| `_tag_type` | `protected int` | 태그 타입 |
| `_config` | `protected config_type` | 설정 타입 |
| `_firmware_version` | `protected int` | 펌웨어 버전 |
| `_state` | `reader_state` | 현재 상태 |
| `_pwd` | `internal string` | 인증 비밀번호 |
| `_pubkey` | `internal byte[]` | 공개키 (ED25519) |
| `ms` | `module_stream` | 통신 스트림 |
| `cs` | `Stream` | 암호화 스트림 (TLS) |
| `tls_session_parameters` | `SSLSessionParameters` | TLS 세션 재개용 |
| `tag_list` | `List<List<tag>>` | 안테나별 태그 목록 |
| `init_done_event` | `AutoResetEvent` | 초기화 완료 이벤트 |

### 8.5 Text Command Protocol (22개)

형식: `COMMAND [ARGS]\n` → `OK COMMAND [DATA]\n`

**기존 PRD 프로토콜 명령:**

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

**분석 문서에서 확인된 추가 명령 코드:**

| 코드 | 기능 | 방향 |
|------|------|------|
| 01 | 상태 조회 | → Reader |
| 02 | 버전 조회 | → Reader |
| 03 | 설정 조회 | → Reader |
| 08 | 안테나 선택 | → Reader |
| 09 | 안테나 상태 | ← Reader |
| 0A | 카드 읽기 | → Reader |
| 0B | 카드 쓰기 | → Reader |
| 0C | 칼리브레이션 시작 | → Reader |
| 0D | 칼리브레이션 결과 | ← Reader |
| 20-26 | WiFi 관련 (SSID, 비밀번호, 연결, 해제, 상태, IP, 스캔) | ↔ |

### 8.6 TLS 인증 흐름

```
1. TCP 연결 (WiFi 또는 유선)
   → reader_state.connected
2. TLS 핸드셰이크 (BearSSL)
   → reader_state.negotiating
   → Password (_pwd) + Public key (_pubkey) 인증
   → SSLSessionParameters 저장 (세션 재개 지원)
3. 정상 동작
   → reader_state.ok
4. Keepalive 유지
   → keepalive_timer (KEEPALIVE_INTERVAL 간격)
```

### 8.7 카드 인코딩

- Mifare Ultralight, Mifare 1k 지원
- UID: Hex 문자열, `" | "` 구분
- 인증 토큰: `"xxxxxxxxxxxxCCC"` (12자 + 3자 체크)
- Hex charset: `"0123456789ABCDEF"`

### 8.8 TLS 보안 (BearSSL / boarssl.dll)

boarssl.dll은 BearSSL C 라이브러리의 C# 포팅이다 (102 types, 207KB).

- Server identity: `"vpt-server"`, Client identity: `"vpt-reader"`
- `SSLClient`, `SSLEngine`, `ECPublicKey` 사용
- `SSLSessionParameters` 캐싱 (세션 재개 지원)
- Keepalive 유지 (`KEEPALIVE_INTERVAL`)

**boarssl 내부 구조:**

| Category | Files | Description |
|----------|:-----:|-------------|
| **SSLTLS** | 33 | TLS 프로토콜 엔진 (SSLEngine, SSLClient, SSLServer, InputRecord, OutputRecord) |
| **Crypto** | 37 | 암호화 알고리즘 (AES, ChaCha20, Poly1305, GHASH, RSA, ECDSA, SHA2, HMAC) |
| **Asn1** | 5 | ASN.1 파서 (AsnElt, AsnIO, AsnOID, PEMObject) |
| **X500** | 2 | X.500 이름 (X500Name, DNPart) |
| **XKeys** | 1 | 키 파서 (PEM/DER) |
| **Utility** | 24 | 유틸리티, 정적 배열, BigInt, ModInt |

**지원 버전:** SSL 3.0 (deprecated), TLS 1.0, TLS 1.1, TLS 1.2

**지원 Cipher Suites:**
- RSA: `RSA_WITH_AES_128/256_CBC_SHA/SHA256`
- ECDHE: `ECDHE_ECDSA/RSA_WITH_AES_128/256_CBC/GCM_SHA256/SHA384`
- ChaCha20: `ECDHE_RSA/ECDSA_WITH_CHACHA20_POLY1305_SHA256`

**레코드 암호화:**

| 클래스 | 알고리즘 | 용도 |
|--------|----------|------|
| `RecordEncryptPlain` / `RecordDecryptPlain` | 없음 | 핸드셰이크 초기 |
| `RecordEncryptCBC` / `RecordDecryptCBC` | AES-CBC + HMAC | 레거시 TLS |
| `RecordEncryptGCM` / `RecordDecryptGCM` | AES-GCM | 현대 TLS |
| `RecordEncryptChaPol` / `RecordDecryptChaPol` | ChaCha20-Poly1305 | AEAD |

**타원 곡선:** NIST P-256, P-384, P-521, Curve25519

### 8.9 RFID 카드 읽기 통합 시나리오

```
[vpt_server] main_form
    │
    ├── [RFIDv2] reader_module.start()
    │       │
    │       ├── v2_module: TCP 연결 (WiFi)
    │       │       │
    │       │       └── [boarssl] SSLClient: TLS 1.2 핸드셰이크
    │       │               ├── Password + ED25519 공개키 인증
    │       │               ├── ECDHE_ECDSA_WITH_AES_128_GCM (추정)
    │       │               └── 세션 파라미터 캐시
    │       │
    │       ├── 카드 감지: tx("0A" + antenna)
    │       │       └── [boarssl] RecordEncryptGCM → TLS record
    │       │
    │       └── 응답 수신: rx()
    │               └── [boarssl] RecordDecryptGCM → 평문
    │
    ├── on_tag_event 콜백 → main_form 처리
    │
    └── [analytics] AnalyticsService.TrackFeature("card_read", data)
```

### 8.10 [Clone] 재구현 전략

#### SkyeTek 레거시 → v2만 지원

SkyeTek은 구형 모듈이며, 보안(TLS 없음)과 기능(단일 안테나, USB HID only)이 제한적이다. Clone에서는 v2 모듈만 지원한다.

| 항목 | 원본 | Clone |
|------|------|-------|
| **SkyeTek (구형)** | 지원 (USB HID) | 지원 제외 |
| **v2 Rev1** | 지원 | 지원 |
| **v2 Rev2** | 지원 | 지원 (주력) |
| **연결** | USB HID + TCP/WiFi | USB HID + TCP/WiFi (동일) |

reader_module에서 skye_module 분기를 제거하고, v2_module 중심으로 단순화한다.

#### BearSSL → System.Net.Security 마이그레이션

boarssl.dll(102 types, 207KB)은 BearSSL C 라이브러리의 C# 수동 포팅이다. .NET의 `System.Net.Security.SslStream`으로 대체하여 유지보수 부담을 제거한다.

| 항목 | 원본 (boarssl.dll) | Clone (System.Net.Security) |
|------|--------------------|-----------------------------|
| **구현** | BearSSL C# 포팅 (102 types) | .NET 내장 SslStream |
| **TLS 버전** | TLS 1.0 ~ 1.2 | TLS 1.2, 1.3 (TLS 1.3 추가 지원) |
| **인증서** | 수동 파싱 (AsnElt, X500Name) | System.Security.Cryptography.X509Certificates |
| **Cipher Suites** | 수동 구현 (AES, ChaCha20, ECDSA) | OS 관리 (최신 스위트 자동 지원) |
| **세션 재개** | SSLSessionParameters 수동 관리 | SslStream 자동 처리 |
| **인증서 검증** | InsecureCertValidator 존재 (MITM 취약) | SslStream + 커스텀 RemoteCertificateValidationCallback |
| **코드량** | 102 타입, 207KB | ~50줄 (SslStream 래퍼) |
| **유지보수** | 수동 (패치 불가) | .NET 런타임 자동 업데이트 |

```csharp
// Clone 설계: BearSSL → SslStream
public class TlsReaderTransport : IDisposable
{
    private SslStream _sslStream;
    private X509Certificate2 _clientCert;

    public async Task ConnectAsync(string host, int port, CancellationToken ct)
    {
        var tcp = new TcpClient();
        await tcp.ConnectAsync(host, port, ct);

        _sslStream = new SslStream(tcp.GetStream(), false, ValidateServerCert);

        var options = new SslClientAuthenticationOptions
        {
            TargetHost = "vpt-server",
            ClientCertificates = new X509CertificateCollection { _clientCert },
            EnabledSslProtocols = SslProtocols.Tls12 | SslProtocols.Tls13,
        };

        await _sslStream.AuthenticateAsClientAsync(options, ct);
    }
}
```

#### Text Command Protocol → 동일 프로토콜 유지

Text Command Protocol은 하드웨어 리더 펌웨어에 구현되어 있으므로, 호환성을 위해 동일 프로토콜을 유지해야 한다.

| 항목 | 원본 | Clone |
|------|------|-------|
| **프로토콜 형식** | `COMMAND [ARGS]\n` → `OK COMMAND [DATA]\n` | 동일 |
| **명령 코드** | 22개 (TI, TR, TW, AU, FW 등) | 동일 (하드웨어 호환) |
| **카드 인코딩** | Mifare Ultralight/1k, UID Hex, 인증 토큰 | 동일 |
| **구현** | 동기 Stream 읽기/쓰기 | async Stream + ReadLineAsync |

#### State Machine → C# 9+ pattern matching

원본의 `reader_state` 전이를 C# pattern matching으로 표현한다:

```csharp
// Clone 설계: Pattern Matching State Machine
public reader_state HandleEvent(reader_state current, ReaderEvent evt)
    => (current, evt) switch
    {
        (reader_state.disconnected, ReaderEvent.TcpConnected)
            => reader_state.connected,
        (reader_state.connected, ReaderEvent.TlsStarted)
            => reader_state.negotiating,
        (reader_state.negotiating, ReaderEvent.TlsComplete)
            => reader_state.ok,
        (reader_state.ok, ReaderEvent.Disconnected)
            => reader_state.disconnected,
        (_, ReaderEvent.Error)
            => reader_state.disconnected,
        _ => current
    };
```

wlan_state도 동일 패턴 적용:

```csharp
public wlan_state HandleWlanEvent(wlan_state current, WlanEvent evt)
    => (current, evt) switch
    {
        (wlan_state.off, WlanEvent.Enabled) => wlan_state.on,
        (wlan_state.on, WlanEvent.Connected) => wlan_state.connected_reset,
        (wlan_state.connected_reset, WlanEvent.IpAcquired) => wlan_state.ip_acquired,
        (_, WlanEvent.Disabled) => wlan_state.off,
        _ => current
    };
```

---

*PokerGFX Clone PRD Wave 2 - GPU Rendering, Graphics Elements, Skin System, RFID Card Reader*
