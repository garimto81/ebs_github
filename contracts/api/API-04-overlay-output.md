# API-04 Overlay Output — 오버레이 출력 계약

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-14 | 경계 pointer 보강 | API-04↔API-05 상호 참조 추가. in-process vs 네트워크 관심사 분리 명시 |
| 2026-04-14 | OutputEventBuffer 구현 소유권 명시 | §3.6에 Team 4 소유 확정, Team 3 harness 역할 명시 |
| 2026-04-08 | 신규 작성 | CC→Overlay 데이터 흐름, 출력 채널, Security Delay, 해상도, 크로마키 |

---

## 개요

이 문서는 **Command Center(CC) Game Engine에서 Overlay까지의 데이터 흐름과 출력 채널 계약**을 정의한다. CC와 Overlay는 동일 Flutter 앱 내에서 실행되며, 네트워크 통신 없이 in-process Dart 함수 호출로 데이터를 전달한다.

> **참조**: Game Engine 상태는 `BS-06-00-REF-game-engine-spec.md`, 엔티티 정의는 `BS-00-definitions.md §2.2`, 출력 프리셋은 `DATA-04-db-schema.md §OutputPreset`

### 핵심 원칙

| 원칙 | 설명 |
|------|------|
| **동일 프로세스** | CC와 Overlay는 같은 Flutter 앱. 네트워크 오버헤드 없음 |
| **반응형 렌더링** | GameState 변경 → Overlay 위젯 자동 rebuild (Flutter 반응형) |
| **Security Delay** | 방송 지연 버퍼로 카드 정보 선노출 방지 |
| **다중 출력** | 동일 Overlay 데이터를 NDI/HDMI/크로마키로 동시 출력 가능 |
| **경계** | 이 계약은 **in-process 전용**. 3-앱 간 WebSocket 이벤트는 `API-05-websocket-events.md` 가 소유 |

---

## 1. 데이터 흐름

### 1.1 전체 파이프라인

```
CC Input (운영자/RFID)
     │
     ▼
Game Engine ──── GameState 업데이트
     │
     ├── Security Delay Buffer (0~120초)
     │         │
     │         ▼
     │    Delayed GameState
     │         │
     │         ▼
     └── Overlay Widget Tree ──── Rive 애니메이션
                │
                ├── NDI 출력 (flutter_ndi TBD)
                ├── HDMI 출력 (디스플레이 직결)
                └── 크로마키 출력 (배경 투명)
```

> **경계 주의**: 본 문서는 CC Flutter 앱 **프로세스 내부** 데이터 흐름만 정의한다.
> BO/Lobby 와의 네트워크 이벤트(`HandStarted`, `ActionPerformed`, `OutputStatusChanged` 등)는
> `API-05-websocket-events.md` 참조. Game Engine 이 OutputEvent 를 발행한 뒤 CC 가 WS 로 BO 에
> 재발행하는 경로는 API-05 §3.

### 1.2 데이터 전달 방식

CC와 Overlay는 같은 Flutter 앱 내에서 실행되므로, **in-process Dart 함수 호출**로 데이터를 전달한다.

| 계층 | 전달 방식 | 지연 |
|------|----------|:----:|
| CC Input → Game Engine | Dart 함수 호출 | < 1ms |
| Game Engine → Security Delay Buffer | Dart Stream/Queue | < 1ms |
| Security Delay Buffer → Overlay | 타이머 기반 GameState 방출 | 0~120초 (설정값) |
| Overlay Widget → Rive 애니메이션 | Flutter 위젯 rebuild | < 16ms (1프레임) |

### 1.3 GameState → Overlay 전달 데이터

Overlay가 렌더링에 사용하는 GameState 필드:

| 카테고리 | 필드 | 용도 |
|---------|------|------|
| **게임 상태** | `game_phase` | 현재 단계 (IDLE ~ HAND_COMPLETE) |
| **플레이어** | `players[]` — name, stack, status, hole_cards | 좌석별 플레이어 정보 |
| **보드** | `community_cards[]` | 커뮤니티 카드 (0~5장) |
| **팟** | `pots[]` — amount, eligible | 메인 팟 + 사이드 팟 |
| **블라인드** | `blinds` — sb, bb, ante | 현재 블라인드 레벨 |
| **딜러** | `dealer_seat` | 딜러 버튼 위치 |
| **액션** | `current_action` — seat, type, amount | 현재 진행 중인 액션 |
| **핸드 랭크** | `hand_rank` | 쇼다운 시 핸드 등급 |
| **확률** | `win_probability` | 실시간 승률 (RFID 모드) |
| **통계** | `player_stats` — vpip, pfr, agr | 플레이어 통계 |

> 전체 GameState 필드: `BS-06-00-REF-game-engine-spec.md Ch.2`

---

## 2. 출력 채널

### 2.1 채널 유형

| 채널 | 기술 | 용도 | Phase |
|------|------|------|:-----:|
| **HDMI** | Flutter 윈도우 직결 디스플레이 | 현장 모니터, 캡처 카드 입력 | 1 |
| **NDI** | `flutter_ndi` (TBD) 네트워크 스트림 | vMix/OBS 등 프로덕션 소프트웨어 입력 | 2 |
| **크로마키** | 배경 투명 렌더링 | 방송 합성용 오버레이 레이어 | 1 |

### 2.2 HDMI 출력

CC Flutter 앱의 Overlay 화면을 **별도 윈도우 또는 전체 화면 모드**로 출력한다. 캡처 카드(AJA, Blackmagic 등)를 통해 프로덕션 시스템에 입력한다.

| 항목 | 값 |
|------|------|
| 출력 방식 | Flutter 윈도우 → 운영 체제 디스플레이 출력 |
| 해상도 | 운영 체제 디스플레이 설정에 따름 |
| 프레임레이트 | 운영 체제 수직 동기화(VSync)에 따름 |
| 크로마키 | 윈도우 배경 단색(Green/Blue) 설정으로 대체 |

### 2.3 NDI 출력 (Phase 2)

Flutter 렌더링 텍스처를 캡처하여 NDI 네트워크 스트림으로 전송한다.

| 항목 | 값 |
|------|------|
| 라이브러리 | `flutter_ndi` (TBD — 커뮤니티 패키지 또는 자체 FFI 바인딩) |
| 프로토콜 | NDI 5.x (NewTek/Vizrt) |
| 전송 방식 | 텍스처 캡처 → RGBA 프레임 → NDI SDK → 네트워크 |
| 수신자 | vMix, OBS (NDI 플러그인), Vizrt 등 |
| 알파 채널 | 지원 (크로마키 불필요, NDI 자체 알파) |
| 지연 | < 1프레임 (네트워크 지연 별도) |

**NDI 스트림 설정:**

| 설정 | 기본값 | 범위 |
|------|:------:|------|
| Stream Name | `EBS-Table-{id}` | 자유 문자열 |
| Width | 1920 | 1280~3840 |
| Height | 1080 | 720~2160 |
| Framerate | 60 | 30/60 |
| Color Format | RGBA | RGBA/BGRA |

### 2.4 동시 출력

1개 CC 인스턴스에서 **HDMI + NDI 동시 출력**이 가능하다.

| 조합 | 지원 | 비고 |
|------|:----:|------|
| HDMI만 | O | Phase 1 기본 |
| NDI만 | O | Phase 2 |
| HDMI + NDI 동시 | O | 동일 GameState, 동일 렌더링 |
| NDI 다중 스트림 | — | Phase 3+ (메인 + PIP 등) |

---

## 3. Security Delay

### 3.1 목적

RFID로 인식된 홀카드 정보가 방송 화면에 **즉시 노출되면 부정행위 가능**. Security Delay는 GameState를 지정 시간만큼 버퍼링하여 지연 출력한다.

### 3.2 동작 원리

```
GameState(t=0) ──┐
GameState(t=1) ──┤
GameState(t=2) ──┤── Delay Buffer (FIFO Queue)
GameState(t=3) ──┤        │
   ...           │        │ delay_seconds 경과 후
                 │        ▼
                 └── Overlay에 GameState(t=0) 방출
```

| 항목 | 값 |
|------|------|
| 범위 | 0~120초 (테이블별 설정) |
| 기본값 | 0초 (지연 없음) |
| 설정 위치 | `tables.delay_seconds` (DB) |
| 설정 주체 | Lobby Admin (테이블 설정) |
| 변경 시점 | 핸드 사이에만 변경 권장. 핸드 중 변경 시 즉시 적용 |

### 3.3 지연 대상 vs 비지연 대상

| 데이터 | 지연 적용 | 이유 |
|--------|:--------:|------|
| 홀카드 (`hole_cards`) | **O** | 부정행위 방지 핵심 |
| 커뮤니티 카드 (`community_cards`) | **O** | 일관된 게임 상태 |
| 플레이어 액션 (Bet/Fold/Raise) | **O** | 홀카드와 동기 유지 |
| 팟 금액 | **O** | 액션과 동기 유지 |
| 승률 (`win_probability`) | **O** | 홀카드 기반 계산 |
| 핸드 랭크 | **O** | 카드 정보 기반 |
| 플레이어 이름/국적 | X | 공개 정보 |
| 블라인드 레벨 | X | 공개 정보 |
| 칩 수량 (스택) | **O** | 액션과 동기 유지 |

### 3.4 delay_seconds = 0

Security Delay 0초 설정 시 지연 버퍼 없이 **실시간 출력**한다. 비 Feature Table이나 데모/테스트 시 사용.

### 3.5 이중 출력 (Backstage / Broadcast) — CCR-036

Overlay는 두 개의 NDI 스트림을 **동시에** 제공한다:

| Stream | 용도 | Delay |
|--------|------|:-----:|
| **Backstage** (NDI 채널 1) | 운영진 / 감독용 | 없음 (즉시) |
| **Broadcast** (NDI 채널 2) | 시청자 방송용 | `delay_seconds` 지연 |

두 스트림은 동일 내용이며 시간차로만 분리된다. 운영진이 실시간(Backstage)을 보면서 방송(Broadcast) 지연 상태를 모니터링.

### 3.6 OutputEventBuffer 구조

> **구현 소유팀 (CCR-056 확정)**: **Team 4 (CC Flutter 앱)** 가 OutputEventBuffer 를 구현한다. 근거: §1.2 "CC 와 Overlay 는 동일 Flutter 앱, in-process 통신" + §3.5 "Backstage 는 buffer 우회 즉시 송출" — Backstage/Broadcast 분기는 Flutter 앱 프로세스 내부에서 자연스럽다. Team 3 harness 는 OutputEvent 를 즉시 emit 하며 buffer 미보유(Pure Dart 계산 엔진 원칙 유지). GAP-GE-009 RESOLVED.

| 항목 | 소유팀 | 위치 (예상) |
|------|--------|-------------|
| OutputEventBuffer 클래스 구현 | **Team 4** | `team4-cc/lib/overlay/output_event_buffer.dart` |
| Security Delay 파라미터 적용 | **Team 4** | 동일 |
| Backstage / Broadcast 분기 | **Team 4** | 동일 (Flutter 프로세스 내부) |
| OutputEvent emit (buffer 없음) | **Team 3** | harness `lib/core/actions/output_event.dart` |

```dart
class OutputEventBuffer {
  final Queue<DelayedEvent> _buffer = Queue();
  final Duration delay;

  void enqueue(OutputEvent event) {
    _buffer.add(DelayedEvent(
      event: event,
      releaseAt: DateTime.now().add(delay),
    ));
    _scheduleRelease();
  }
}
```

- 각 OutputEvent는 `releaseAt` 시점이 되면 Broadcast Output으로 방출
- Backstage는 buffer를 우회하고 즉시 송출
- 자세한 설정 변경 시 규칙(중간 delay 조정, 크래시 처리, 방송 종료 flush)은 `contracts/specs/BS-07-overlay/BS-07-07-security-delay.md` 참조

### 3.7 `delay_holecards_only` 옵션 (CCR-036)

`delay_holecards_only == true`로 설정하면 **홀카드만 지연**되고 다른 요소(액션 배지, Pot 변화 등)는 즉시 송출된다. 시청자 경험을 개선하면서 부정행위 방지 핵심(홀카드)은 유지하는 절충안.

---

## 4. 해상도 대응

### 4.1 지원 해상도

| 해상도 | 크기 (px) | 용도 |
|--------|----------|------|
| **1080p** (FHD) | 1920 x 1080 | 표준 방송 출력 |
| **4K** (UHD) | 3840 x 2160 | 고해상도 방송 출력 |
| **720p** (HD) | 1280 x 720 | 미리보기, 저대역폭 |

### 4.2 스케일링 규칙

Overlay UI는 **1080p 기준으로 설계**하고, 4K는 2배 스케일링으로 대응한다.

| 항목 | 1080p | 4K |
|------|:-----:|:--:|
| 레이아웃 | 기준 | 2x 스케일 |
| 폰트 | 기준 크기 | 2x 크기 |
| Rive 애니메이션 | 기준 | 벡터 → 무손실 스케일 |
| 이미지 에셋 | @1x | @2x (별도 에셋) |

**Flutter 구현:**

```dart
// OutputPreset에서 해상도를 읽어 MediaQuery 오버라이드
MediaQuery(
  data: MediaQueryData(size: Size(preset.width, preset.height)),
  child: OverlayRoot(),
)
```

### 4.3 프레임레이트

| 설정 | 값 | 용도 |
|------|:--:|------|
| 30fps | 30 | 저부하 환경, 녹화 |
| **60fps** | 60 | 표준 방송 (기본값) |

---

## 5. 크로마키 모드

### 5.1 목적

오버레이 요소만 방송 화면에 합성하기 위해 **배경을 투명(또는 단색)**으로 렌더링한다.

### 5.2 모드별 동작

| 모드 | 배경 | 출력 대상 | 합성 방식 |
|------|------|----------|----------|
| **크로마키 OFF** | 스킨 배경 이미지 | HDMI 전체 화면 | 직접 출력 (합성 불필요) |
| **크로마키 ON (Green)** | `#00FF00` 단색 | HDMI → 캡처 카드 | 프로덕션 SW에서 Green 제거 |
| **크로마키 ON (Blue)** | `#0000FF` 단색 | HDMI → 캡처 카드 | 프로덕션 SW에서 Blue 제거 |
| **NDI 알파** | 투명 (Alpha=0) | NDI 스트림 | NDI 자체 알파 채널 |

### 5.3 크로마키 모드에서 렌더링되는 요소

| 요소 | 렌더링 | 비고 |
|------|:------:|------|
| 플레이어 네임태그 | O | 이름, 국적, 칩 |
| 홀카드 | O | RFID 인식 시 |
| 커뮤니티 카드 | O | 보드 카드 |
| 팟 금액 | O | 메인 + 사이드 |
| 액션 표시 (Bet, Raise 등) | O | 애니메이션 포함 |
| 블라인드 레벨 | O | SB/BB/Ante |
| 승률 바 | O | 확률 표시 |
| 딜러 버튼 | O | 위치 표시 |
| 배경 이미지 | **X** | 크로마키 색상 또는 투명 |
| 테이블 펠트 | **X** | 크로마키 색상 또는 투명 |

### 5.4 설정

| 설정 | DB 위치 | 값 |
|------|---------|------|
| 크로마키 활성화 | `output_presets.chroma_key` | `true` / `false` |
| 크로마키 색상 | Config `output.chroma_color` | `green` / `blue` |
| NDI 알파 | NDI 출력 시 자동 | — |

---

## 6. 씬 업데이트 이벤트

### 6.1 Overlay 위젯 rebuild 트리거

GameState가 변경되면 Overlay 위젯 트리가 자동으로 rebuild된다. Flutter의 반응형 렌더링(ChangeNotifier/Provider/Riverpod)을 활용한다.

| GameState 변경 | Overlay 반응 | 애니메이션 |
|---------------|-------------|----------|
| `game_phase` 변경 | 씬 전환 (예: FLOP → 카드 공개) | Rive 카드 플립 |
| `players[].hole_cards` 변경 | 홀카드 표시/숨김 | Rive 카드 딜 |
| `community_cards` 추가 | 보드 카드 공개 | Rive 카드 슬라이드 |
| `current_action` 변경 | 액션 텍스트 표시 | 페이드 인/아웃 |
| `pots[].amount` 변경 | 팟 금액 업데이트 | 숫자 롤링 |
| `players[].stack` 변경 | 칩 수량 업데이트 | 숫자 롤링 |
| `dealer_seat` 변경 | 딜러 버튼 이동 | 슬라이드 |
| `win_probability` 변경 | 승률 바 업데이트 | 바 애니메이션 |
| `hand_rank` 설정 | 핸드 랭크 텍스트 표시 | 페이드 인 |
| 핸드 종료 (`HAND_COMPLETE`) | 승자 하이라이트 | Rive 축하 |

### 6.2 애니메이션 타이밍

| 애니메이션 | 지속 시간 | 이징 |
|-----------|:---------:|------|
| 카드 딜 | 300ms | ease-out |
| 카드 플립 | 400ms | ease-in-out |
| 액션 텍스트 | 200ms in, 1500ms 유지, 200ms out | linear |
| 숫자 롤링 (칩/팟) | 500ms | ease-out |
| 딜러 버튼 이동 | 400ms | ease-in-out |
| 승률 바 | 300ms | linear |
| 씬 전환 | 500ms | ease-in-out |

> 애니메이션 타이밍은 스킨 설정으로 오버라이드 가능.

---

## 7. 에러 처리

| 에러 | 증상 | 대응 |
|------|------|------|
| GameState null | Overlay 빈 화면 | IDLE 화면(로고/대기) 표시 |
| NDI 전송 실패 | 스트림 끊김 | 자동 재연결 (3초 간격, 최대 10회) |
| 렌더링 프레임 드롭 | 끊김 | Rive 애니메이션 품질 자동 저하 |
| Security Delay 버퍼 오버플로 | 메모리 증가 | 최대 버퍼 크기 제한 (120초 × 60fps = 7,200 스냅샷) |
| 해상도 변경 | 화면 깨짐 | 핸드 사이에만 변경 허용. 즉시 resize → rebuild |
