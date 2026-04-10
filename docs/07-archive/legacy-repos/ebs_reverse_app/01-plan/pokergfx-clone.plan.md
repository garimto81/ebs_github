# PokerGFX Clone Flutter - Architecture Plan

## 배경 (Background)

- **요청**: PokerGFX Server (.NET WinForms, 355MB, 8개 모듈, 2,887 .cs 파일)를 Flutter + Rive + NDI로 완전 재구현
- **이번 세션 범위**: 전체 스켈레톤 구조만 구현 (빈 인터페이스 + 모델 클래스 + 기본 화면)
- **해결하려는 문제**: God Class 구조 → Clean Architecture 전환, WinForms → Flutter Desktop

## 구현 범위 (Scope)

### 포함 항목
- Flutter 프로젝트 초기화 (Windows Desktop)
- 8개 모듈 디렉토리 구조 생성
- 각 모듈의 인터페이스/추상 클래스 정의
- 모델 클래스 스텁
- Riverpod Provider 스텁
- 기본 화면 (빈 Shell)
- pubspec.yaml 의존성 정의
- 시뮬레이션 모드 플래그

### 제외 항목
- RFID 실제 통신 구현
- 핸드 평가 알고리즘 구현
- NDI 네이티브 바인딩
- 네트워크 프로토콜 구현
- Rive 에셋 제작
- 게임 로직 상태 머신

## 아키텍처 결정 (Architecture Decisions)

### AD-1: Feature-First 모듈 구조

원본 8개 DLL/EXE 경계를 Flutter feature 디렉토리로 1:1 매핑한다.
각 feature는 독립된 `domain/`, `data/`, `presentation/` 레이어를 가진다.

```
  feature/
  ├── domain/       # 인터페이스, 엔티티, 유스케이스
  ├── data/         # 구현체, 리포지토리, 데이터소스
  └── presentation/ # 위젯, 컨트롤러, Provider
```

**근거**: 원본 DLL 간 결합도가 높아 God Class 문제 발생. Feature-first로 경계를 명확히 분리.

### AD-2: 의존성 방향 — 안쪽으로만

```
  +----------------------------------------------+
  |              presentation (UI)               |
  +----------------------------------------------+
           |                    |
           v                    v
  +------------------+  +------------------+
  |    application    |  |   (providers)    |
  +------------------+  +------------------+
           |
           v
  +----------------------------------------------+
  |              domain (interfaces)             |
  +----------------------------------------------+
           ^
           |
  +----------------------------------------------+
  |         data (implementations, FFI)          |
  +----------------------------------------------+
```

domain 레이어는 외부 의존성이 없다. data와 presentation은 domain에만 의존한다.

### AD-3: FFI 브릿지 패턴

NDI SDK, hidapi 같은 네이티브 라이브러리는 `data/ffi/` 하위에 격리한다.
인터페이스는 domain에, 구현체(FFI 바인딩)는 data에 위치.

```
  domain/
  └── services/
      └── ndi_service.dart          # abstract class NdiService
  data/
  └── ffi/
      ├── ndi_bindings.dart         # dart:ffi NativeFunction 정의
      └── ndi_service_impl.dart     # NdiService 구현
```

**근거**: FFI 코드를 격리하면 시뮬레이션 모드에서 Mock으로 교체 가능.

### AD-4: 시뮬레이션 모드

모든 하드웨어/네이티브 의존 서비스에 Simulation 구현체를 제공한다.
Riverpod Provider에서 환경 변수/설정으로 실제 vs 시뮬레이션을 전환한다.

```
  Provider<RfidService>(
    (ref) => isSimulation
      ? SimulatedRfidService()
      : HidapiRfidService()
  )
```

### AD-5: 이벤트 버스 (모듈 간 통신)

모듈 간 직접 참조 대신 이벤트 버스를 사용한다. Riverpod의 StreamProvider + EventBus 패턴.

```
  RFID Module ──(CardScannedEvent)──> Event Bus ──> Game Logic Module
  Game Logic  ──(HandCompleteEvent)──> Event Bus ──> Renderer Module
  Renderer    ──(FrameReadyEvent)───> Event Bus ──> NDI Output Module
```

### AD-6: 설정 시스템

원본 ConfigurationPreset (192 methods, 95 fields)를 JSON 기반으로 재설계한다.
Freezed로 불변 설정 클래스를 생성하고, FileWatcher로 핫리로드한다.

### AD-7: 데이터 흐름

```
  RFID Reader      Hand Evaluator     Game State        Renderer         NDI Output
  (USB HID)        (Bitmask)          (Riverpod)        (Rive)           (FFI)
      |                 |                  |                |                |
      |--card_uid------>|                  |                |                |
      |                 |--hand_rank------>|                |                |
      |                 |                  |--state_update->|                |
      |                 |                  |                |--frame-------->|
      |                 |                  |                |                |--ndi_send-->
```

## 프로젝트 디렉토리 구조 (Project Structure)

```
  pokergfx_flutter/
  ├── pubspec.yaml
  ├── analysis_options.yaml
  ├── windows/                          # Flutter Windows runner
  │   └── runner/
  ├── assets/
  │   ├── rive/                         # Rive 애니메이션 파일 (.riv)
  │   ├── config/                       # 기본 설정 JSON
  │   │   ├── default_config.json
  │   │   ├── card_mapping.json
  │   │   └── game_presets/
  │   └── fonts/
  ├── lib/
  │   ├── main.dart                     # 앱 진입점
  │   ├── app.dart                      # MaterialApp 설정
  │   ├── core/
  │   │   ├── constants/
  │   │   │   └── app_constants.dart
  │   │   ├── errors/
  │   │   │   ├── exceptions.dart
  │   │   │   └── failures.dart
  │   │   ├── events/
  │   │   │   ├── event_bus.dart
  │   │   │   └── app_events.dart
  │   │   ├── di/
  │   │   │   └── service_locator.dart
  │   │   ├── crypto/
  │   │   │   └── aes_util.dart
  │   │   ├── logging/
  │   │   │   └── logger.dart
  │   │   └── utils/
  │   │       └── extensions.dart
  │   ├── features/
  │   │   ├── rfid/                     # M1: RFID 리더
  │   │   │   ├── domain/
  │   │   │   │   ├── entities/
  │   │   │   │   │   ├── rfid_card.dart
  │   │   │   │   │   └── antenna_config.dart
  │   │   │   │   ├── services/
  │   │   │   │   │   └── rfid_service.dart
  │   │   │   │   └── repositories/
  │   │   │   │       └── card_mapping_repository.dart
  │   │   │   ├── data/
  │   │   │   │   ├── ffi/
  │   │   │   │   │   ├── hidapi_bindings.dart
  │   │   │   │   │   └── hidapi_rfid_service.dart
  │   │   │   │   ├── tcp/
  │   │   │   │   │   └── tcp_rfid_service.dart
  │   │   │   │   ├── simulation/
  │   │   │   │   │   └── simulated_rfid_service.dart
  │   │   │   │   └── repositories/
  │   │   │   │       └── card_mapping_repository_impl.dart
  │   │   │   └── presentation/
  │   │   │       ├── providers/
  │   │   │       │   └── rfid_providers.dart
  │   │   │       └── widgets/
  │   │   │           └── rfid_status_indicator.dart
  │   │   ├── hand_eval/                # M2: 핸드 평가
  │   │   │   ├── domain/
  │   │   │   │   ├── entities/
  │   │   │   │   │   ├── poker_hand.dart
  │   │   │   │   │   ├── hand_rank.dart
  │   │   │   │   │   └── card.dart
  │   │   │   │   └── services/
  │   │   │   │       └── hand_evaluation_service.dart
  │   │   │   ├── data/
  │   │   │   │   ├── evaluators/
  │   │   │   │   │   ├── bitmask_evaluator.dart
  │   │   │   │   │   └── monte_carlo_calculator.dart
  │   │   │   │   └── simulation/
  │   │   │   │       └── simulated_hand_eval_service.dart
  │   │   │   └── presentation/
  │   │   │       ├── providers/
  │   │   │       │   └── hand_eval_providers.dart
  │   │   │       └── widgets/
  │   │   │           └── hand_display.dart
  │   │   ├── network/                  # M3: 네트워크 프로토콜
  │   │   │   ├── domain/
  │   │   │   │   ├── entities/
  │   │   │   │   │   ├── protocol_message.dart
  │   │   │   │   │   ├── client_info.dart
  │   │   │   │   │   └── command_type.dart
  │   │   │   │   ├── services/
  │   │   │   │   │   ├── discovery_service.dart
  │   │   │   │   │   └── connection_service.dart
  │   │   │   │   └── repositories/
  │   │   │   │       └── remote_registry.dart
  │   │   │   ├── data/
  │   │   │   │   ├── udp/
  │   │   │   │   │   └── udp_discovery_impl.dart
  │   │   │   │   ├── tcp/
  │   │   │   │   │   └── tcp_connection_impl.dart
  │   │   │   │   ├── codec/
  │   │   │   │   │   ├── message_encoder.dart
  │   │   │   │   │   └── message_decoder.dart
  │   │   │   │   └── simulation/
  │   │   │   │       └── simulated_connection_service.dart
  │   │   │   └── presentation/
  │   │   │       ├── providers/
  │   │   │       │   └── network_providers.dart
  │   │   │       └── widgets/
  │   │   │           └── connection_status.dart
  │   │   ├── renderer/                 # M4: 렌더링 엔진
  │   │   │   ├── domain/
  │   │   │   │   ├── entities/
  │   │   │   │   │   ├── render_layer.dart
  │   │   │   │   │   ├── skin.dart
  │   │   │   │   │   └── animation_config.dart
  │   │   │   │   └── services/
  │   │   │   │       └── renderer_service.dart
  │   │   │   ├── data/
  │   │   │   │   ├── rive/
  │   │   │   │   │   ├── rive_renderer_impl.dart
  │   │   │   │   │   └── rive_state_controller.dart
  │   │   │   │   └── skin/
  │   │   │   │       └── skin_loader.dart
  │   │   │   └── presentation/
  │   │   │       ├── providers/
  │   │   │       │   └── renderer_providers.dart
  │   │   │       ├── widgets/
  │   │   │       │   ├── game_canvas.dart
  │   │   │       │   ├── card_widget.dart
  │   │   │       │   └── player_overlay.dart
  │   │   │       └── screens/
  │   │   │           └── renderer_screen.dart
  │   │   ├── broadcast/                # M5: 방송 출력 (NDI)
  │   │   │   ├── domain/
  │   │   │   │   ├── entities/
  │   │   │   │   │   ├── frame_buffer.dart
  │   │   │   │   │   └── output_config.dart
  │   │   │   │   └── services/
  │   │   │   │       └── ndi_service.dart
  │   │   │   ├── data/
  │   │   │   │   ├── ffi/
  │   │   │   │   │   ├── ndi_bindings.dart
  │   │   │   │   │   └── ndi_service_impl.dart
  │   │   │   │   └── simulation/
  │   │   │   │       └── simulated_ndi_service.dart
  │   │   │   └── presentation/
  │   │   │       ├── providers/
  │   │   │       │   └── broadcast_providers.dart
  │   │   │       └── widgets/
  │   │   │           └── broadcast_control.dart
  │   │   ├── game/                     # M6: 게임 로직
  │   │   │   ├── domain/
  │   │   │   │   ├── entities/
  │   │   │   │   │   ├── game_state.dart
  │   │   │   │   │   ├── player.dart
  │   │   │   │   │   ├── pot.dart
  │   │   │   │   │   ├── round.dart
  │   │   │   │   │   └── game_type.dart
  │   │   │   │   ├── services/
  │   │   │   │   │   ├── game_cards_service.dart
  │   │   │   │   │   ├── game_players_service.dart
  │   │   │   │   │   ├── game_play_service.dart
  │   │   │   │   │   └── timers_service.dart
  │   │   │   │   └── repositories/
  │   │   │   │       └── game_history_repository.dart
  │   │   │   ├── data/
  │   │   │   │   ├── state_machine/
  │   │   │   │   │   └── game_state_machine.dart
  │   │   │   │   ├── database/
  │   │   │   │   │   ├── game_database.dart
  │   │   │   │   │   └── tables/
  │   │   │   │   │       ├── players_table.dart
  │   │   │   │   │       └── hands_table.dart
  │   │   │   │   └── repositories/
  │   │   │   │       └── game_history_repository_impl.dart
  │   │   │   └── presentation/
  │   │   │       ├── providers/
  │   │   │       │   └── game_providers.dart
  │   │   │       ├── widgets/
  │   │   │       │   ├── player_list.dart
  │   │   │       │   ├── pot_display.dart
  │   │   │       │   └── timer_widget.dart
  │   │   │       └── screens/
  │   │   │           ├── game_control_screen.dart
  │   │   │           └── game_setup_screen.dart
  │   │   ├── config/                   # M7: 설정/구성
  │   │   │   ├── domain/
  │   │   │   │   ├── entities/
  │   │   │   │   │   ├── app_config.dart
  │   │   │   │   │   └── game_preset.dart
  │   │   │   │   ├── services/
  │   │   │   │   │   └── config_service.dart
  │   │   │   │   └── repositories/
  │   │   │   │       └── preset_repository.dart
  │   │   │   ├── data/
  │   │   │   │   ├── json/
  │   │   │   │   │   ├── config_loader.dart
  │   │   │   │   │   └── config_watcher.dart
  │   │   │   │   └── repositories/
  │   │   │   │       └── preset_repository_impl.dart
  │   │   │   └── presentation/
  │   │   │       ├── providers/
  │   │   │       │   └── config_providers.dart
  │   │   │       ├── widgets/
  │   │   │       │   └── config_editor.dart
  │   │   │       └── screens/
  │   │   │           └── settings_screen.dart
  │   │   └── common/                   # M8: 공통 라이브러리
  │   │       ├── domain/
  │   │       │   └── services/
  │   │       │       └── plugin_service.dart
  │   │       └── data/
  │   │           └── plugins/
  │   │               └── plugin_registry.dart
  │   └── shell/
  │       ├── app_shell.dart            # 메인 레이아웃 Shell
  │       ├── navigation/
  │       │   └── app_router.dart
  │       └── screens/
  │           ├── home_screen.dart
  │           └── dashboard_screen.dart
  ├── test/
  │   ├── features/
  │   │   ├── rfid/
  │   │   │   └── domain/
  │   │   │       └── rfid_service_test.dart
  │   │   ├── hand_eval/
  │   │   │   └── domain/
  │   │   │       └── hand_evaluation_test.dart
  │   │   ├── network/
  │   │   │   └── domain/
  │   │   │       └── connection_service_test.dart
  │   │   ├── game/
  │   │   │   └── domain/
  │   │   │       └── game_play_service_test.dart
  │   │   └── config/
  │   │       └── domain/
  │   │           └── config_service_test.dart
  │   └── core/
  │       └── events/
  │           └── event_bus_test.dart
  └── native/
      ├── ndi/                          # NDI SDK 네이티브 래퍼
      │   ├── CMakeLists.txt
      │   └── ndi_wrapper.cpp
      └── hidapi/                       # hidapi 네이티브 래퍼
          ├── CMakeLists.txt
          └── hidapi_wrapper.cpp
```

## 모듈별 핵심 파일 목록 (Module Files)

### M1: RFID (`features/rfid/`)

| 파일 | 핵심 클래스/인터페이스 | 메서드 시그니처 |
|------|----------------------|----------------|
| `domain/entities/rfid_card.dart` | `RfidCard` (Freezed) | `cardId`, `suit`, `rank`, `antennaIndex`, `timestamp` |
| `domain/entities/antenna_config.dart` | `AntennaConfig` (Freezed) | `antennaCount`, `pollingHz`, `vid`, `pid` |
| `domain/services/rfid_service.dart` | `abstract class RfidService` | `Stream<RfidCard> get cardStream`, `Future<void> connect()`, `Future<void> disconnect()`, `Future<List<RfidCard>> scanAll()`, `bool get isConnected` |
| `domain/repositories/card_mapping_repository.dart` | `abstract class CardMappingRepository` | `Card? mapToCard(String uid)`, `Future<void> loadMapping(String path)`, `Future<void> saveMapping(String path)` |
| `data/ffi/hidapi_bindings.dart` | `HidapiBindings` | `hid_open()`, `hid_read()`, `hid_write()`, `hid_close()` (dart:ffi NativeFunction) |
| `data/ffi/hidapi_rfid_service.dart` | `HidapiRfidService implements RfidService` | USB HID 구현 |
| `data/tcp/tcp_rfid_service.dart` | `TcpRfidService implements RfidService` | TCP/WiFi 구현 |
| `data/simulation/simulated_rfid_service.dart` | `SimulatedRfidService implements RfidService` | 랜덤 카드 생성 시뮬레이션 |

### M2: Hand Eval (`features/hand_eval/`)

| 파일 | 핵심 클래스/인터페이스 | 메서드 시그니처 |
|------|----------------------|----------------|
| `domain/entities/card.dart` | `Card` (Freezed) | `suit` (Suit enum), `rank` (Rank enum), `int get bitmask` |
| `domain/entities/poker_hand.dart` | `PokerHand` (Freezed) | `List<Card> cards`, `HandRank rank`, `int strength` |
| `domain/entities/hand_rank.dart` | `enum HandRank` | `highCard`, `pair`, `twoPair`, `threeOfAKind`, `straight`, `flush`, `fullHouse`, `fourOfAKind`, `straightFlush`, `royalFlush` |
| `domain/services/hand_evaluation_service.dart` | `abstract class HandEvaluationService` | `PokerHand evaluate(List<Card> cards, GameType type)`, `List<PokerHand> rankHands(List<List<Card>> hands, GameType type)`, `double calculateEquity(List<Card> hand, List<Card> board, int opponents)` |
| `data/evaluators/bitmask_evaluator.dart` | `BitmaskEvaluator implements HandEvaluationService` | Bitmask 64-bit 평가 구현 |
| `data/evaluators/monte_carlo_calculator.dart` | `MonteCarloCalculator` | `Future<double> simulate(hand, board, opponents, iterations)` |

### M3: Network (`features/network/`)

| 파일 | 핵심 클래스/인터페이스 | 메서드 시그니처 |
|------|----------------------|----------------|
| `domain/entities/protocol_message.dart` | `ProtocolMessage` (Freezed) | `CommandType command`, `Map<String, dynamic> payload`, `int sequenceId` |
| `domain/entities/client_info.dart` | `ClientInfo` (Freezed) | `String address`, `int port`, `String name`, `ClientRole role` |
| `domain/entities/command_type.dart` | `enum CommandType` | 113+ 프로토콜 명령어 (스켈레톤에서는 핵심 20개만) |
| `domain/services/discovery_service.dart` | `abstract class DiscoveryService` | `Stream<ClientInfo> discover()`, `Future<void> startBroadcast()`, `Future<void> stopBroadcast()` |
| `domain/services/connection_service.dart` | `abstract class ConnectionService` | `Future<void> connect(String host, int port)`, `Future<void> disconnect()`, `Future<ProtocolMessage> send(ProtocolMessage msg)`, `Stream<ProtocolMessage> get messageStream` |
| `domain/repositories/remote_registry.dart` | `abstract class RemoteRegistry` | `Future<void> register(ClientInfo client)`, `Future<void> unregister(String id)`, `List<ClientInfo> get connectedClients` |
| `data/codec/message_encoder.dart` | `MessageEncoder` | `Uint8List encode(ProtocolMessage msg)` |
| `data/codec/message_decoder.dart` | `MessageDecoder` | `ProtocolMessage decode(Uint8List data)` |

### M4: Renderer (`features/renderer/`)

| 파일 | 핵심 클래스/인터페이스 | 메서드 시그니처 |
|------|----------------------|----------------|
| `domain/entities/render_layer.dart` | `RenderLayer` (Freezed) | `String id`, `int zIndex`, `bool visible`, `double opacity` |
| `domain/entities/skin.dart` | `Skin` (Freezed) | `String name`, `String rivePath`, `Map<String, Color> colorScheme` |
| `domain/entities/animation_config.dart` | `AnimationConfig` (Freezed) | `Duration dealSpeed`, `Duration flipSpeed`, `Duration revealDelay` |
| `domain/services/renderer_service.dart` | `abstract class RendererService` | `Future<void> initialize(Skin skin)`, `void renderGameState(GameState state)`, `void setSkin(Skin skin)`, `Future<Uint8List> captureFrame()` |
| `data/rive/rive_renderer_impl.dart` | `RiveRendererImpl implements RendererService` | Rive StateMachine 기반 렌더링 |
| `data/rive/rive_state_controller.dart` | `RiveStateController` | Rive artboard/state machine 제어 |

### M5: Broadcast (`features/broadcast/`)

| 파일 | 핵심 클래스/인터페이스 | 메서드 시그니처 |
|------|----------------------|----------------|
| `domain/entities/frame_buffer.dart` | `FrameBuffer` (Freezed) | `Uint8List pixels`, `int width`, `int height`, `bool hasAlpha` |
| `domain/entities/output_config.dart` | `OutputConfig` (Freezed) | `int width`, `int height`, `double fps`, `String sourceName`, `bool alphaEnabled` |
| `domain/services/ndi_service.dart` | `abstract class NdiService` | `Future<void> initialize(OutputConfig config)`, `Future<void> sendFrame(FrameBuffer frame)`, `Future<void> dispose()`, `bool get isActive` |
| `data/ffi/ndi_bindings.dart` | `NdiBindings` | `NDIlib_initialize()`, `NDIlib_send_create()`, `NDIlib_send_send_video_v2()` (dart:ffi) |
| `data/ffi/ndi_service_impl.dart` | `NdiServiceImpl implements NdiService` | 네이티브 NDI SDK 래퍼 |
| `data/simulation/simulated_ndi_service.dart` | `SimulatedNdiService implements NdiService` | 프레임 카운터만 기록 |

### M6: Game (`features/game/`)

| 파일 | 핵심 클래스/인터페이스 | 메서드 시그니처 |
|------|----------------------|----------------|
| `domain/entities/game_state.dart` | `GameState` (Freezed) | `GameType type`, `GamePhase phase`, `List<Player> players`, `List<Pot> pots`, `List<Card> board`, `int dealerIndex` |
| `domain/entities/player.dart` | `Player` (Freezed) | `String id`, `String name`, `int chips`, `List<Card> hand`, `PlayerStatus status`, `int seatIndex` |
| `domain/entities/pot.dart` | `Pot` (Freezed) | `int amount`, `List<String> eligiblePlayerIds` |
| `domain/entities/round.dart` | `Round` (Freezed) | `int number`, `List<Action> actions`, `DateTime startTime` |
| `domain/entities/game_type.dart` | `enum GameType` | `holdem`, `omaha`, `stud`, ... (22개 변형) |
| `domain/services/game_cards_service.dart` | `abstract class GameCardsService` | `void assignCard(String playerId, Card card)`, `void dealBoard(List<Card> cards)`, `void clearAll()` + 원본 37 methods 중 핵심 10개 |
| `domain/services/game_players_service.dart` | `abstract class GamePlayersService` | `void addPlayer(Player p)`, `void removePlayer(String id)`, `void updateChips(String id, int amount)` + 원본 48 methods 중 핵심 15개 |
| `domain/services/game_play_service.dart` | `abstract class GamePlayService` | `void startHand()`, `void nextPhase()`, `void endHand()`, `void fold(String playerId)`, `void bet(String playerId, int amount)` |
| `domain/services/timers_service.dart` | `abstract class TimersService` | `void startTimer(Duration duration)`, `void pauseTimer()`, `void resetTimer()`, `Stream<Duration> get timerStream` |
| `domain/repositories/game_history_repository.dart` | `abstract class GameHistoryRepository` | `Future<void> saveHand(GameState state)`, `Future<List<GameState>> getHistory(int limit)` |
| `data/state_machine/game_state_machine.dart` | `GameStateMachine` | 게임 Phase 전이 로직 |
| `data/database/game_database.dart` | `@DriftDatabase GameDatabase` | Drift SQLite 데이터베이스 |

### M7: Config (`features/config/`)

| 파일 | 핵심 클래스/인터페이스 | 메서드 시그니처 |
|------|----------------------|----------------|
| `domain/entities/app_config.dart` | `AppConfig` (Freezed) | 95개 원본 필드를 카테고리별 nested class로 분리 (`RfidConfig`, `NetworkConfig`, `RenderConfig`, `GameConfig`, `BroadcastConfig`) |
| `domain/entities/game_preset.dart` | `GamePreset` (Freezed) | `String name`, `GameType type`, `BlindsStructure blinds`, `TimerConfig timer` |
| `domain/services/config_service.dart` | `abstract class ConfigService` | `Future<AppConfig> load()`, `Future<void> save(AppConfig config)`, `Stream<AppConfig> get configStream` (핫리로드) |
| `domain/repositories/preset_repository.dart` | `abstract class PresetRepository` | `Future<List<GamePreset>> getAll()`, `Future<void> save(GamePreset preset)`, `Future<void> delete(String name)` |
| `data/json/config_loader.dart` | `ConfigLoader` | JSON 파일 파싱/직렬화 |
| `data/json/config_watcher.dart` | `ConfigWatcher` | FileSystemEntity.watch() 기반 핫리로드 |

### M8: Common (`features/common/` + `core/`)

| 파일 | 핵심 클래스/인터페이스 | 메서드 시그니처 |
|------|----------------------|----------------|
| `core/events/event_bus.dart` | `EventBus` | `void fire<T>(T event)`, `Stream<T> on<T>()` |
| `core/events/app_events.dart` | Event 클래스들 | `CardScannedEvent`, `HandCompleteEvent`, `FrameReadyEvent`, `GameStateChangedEvent`, `ConfigChangedEvent` |
| `core/crypto/aes_util.dart` | `AesUtil` | `Uint8List encrypt(Uint8List data, String key)`, `Uint8List decrypt(Uint8List data, String key)` |
| `core/logging/logger.dart` | `AppLogger` | `void debug(String msg)`, `void info(String msg)`, `void warning(String msg)`, `void error(String msg, [Object? error])` |
| `features/common/domain/services/plugin_service.dart` | `abstract class PluginService` | `Future<void> registerPlugin(Plugin plugin)`, `Future<void> unregisterPlugin(String id)`, `List<Plugin> get loadedPlugins` |
| `features/common/data/plugins/plugin_registry.dart` | `PluginRegistry implements PluginService` | 플러그인 로드/언로드 관리 |

## 의존성 목록 (Dependencies)

### pubspec.yaml dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # 상태 관리
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # 코드 생성 (Freezed)
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1

  # 데이터베이스
  drift: ^2.15.0
  sqlite3_flutter_libs: ^0.5.20

  # FFI
  ffi: ^2.1.0

  # Rive 애니메이션
  rive: ^0.13.5

  # 유틸리티
  path_provider: ^2.1.2
  path: ^1.8.3
  collection: ^1.18.0
  uuid: ^4.3.3

  # 암호화
  pointycastle: ^3.7.4
  convert: ^3.1.1

  # 로깅
  logger: ^2.0.2+1

dev_dependencies:
  flutter_test:
    sdk: flutter

  # 코드 생성
  build_runner: ^2.4.8
  freezed: ^2.4.7
  json_serializable: ^6.7.1
  riverpod_generator: ^2.4.0
  drift_dev: ^2.15.0

  # 린트
  flutter_lints: ^3.0.1

  # 테스트
  mocktail: ^1.0.3
```

### 네이티브 의존성 (별도 설치)

| 라이브러리 | 버전 | 용도 | 설치 방법 |
|-----------|------|------|----------|
| NDI SDK | 5.x | 방송 출력 | NewTek 공식 다운로드 → `windows/ndi/` |
| hidapi | 0.14+ | USB HID | vcpkg install hidapi → DLL 복사 |

### Flutter 프로젝트 설정

```yaml
# pubspec.yaml 상단
name: pokergfx
description: PokerGFX Clone - Poker broadcast graphics system
publish_to: 'none'
version: 0.1.0

environment:
  sdk: '>=3.2.0 <4.0.0'
  flutter: '>=3.16.0'
```

## 구현 체크리스트 (Implementation Checklist)

### Phase 1: 프로젝트 초기화
- [ ] `flutter create --platforms=windows --project-name=pokergfx pokergfx_flutter`
- [ ] pubspec.yaml 의존성 추가
- [ ] analysis_options.yaml 설정
- [ ] 디렉토리 구조 생성 (features/, core/, shell/, assets/, native/)

### Phase 2: Core 레이어
- [ ] `core/events/event_bus.dart` — EventBus 구현
- [ ] `core/events/app_events.dart` — 이벤트 클래스 정의
- [ ] `core/errors/exceptions.dart` — 커스텀 Exception 정의
- [ ] `core/errors/failures.dart` — Failure 클래스 정의
- [ ] `core/crypto/aes_util.dart` — AES-256 유틸 스텁
- [ ] `core/logging/logger.dart` — AppLogger 스텁
- [ ] `core/constants/app_constants.dart` — 상수 정의
- [ ] `core/di/service_locator.dart` — Riverpod ProviderScope 설정

### Phase 3: Domain 레이어 (인터페이스 + 엔티티)
- [ ] M1 RFID: `rfid_card.dart`, `antenna_config.dart`, `rfid_service.dart`, `card_mapping_repository.dart`
- [ ] M2 Hand Eval: `card.dart`, `poker_hand.dart`, `hand_rank.dart`, `hand_evaluation_service.dart`
- [ ] M3 Network: `protocol_message.dart`, `client_info.dart`, `command_type.dart`, `discovery_service.dart`, `connection_service.dart`, `remote_registry.dart`
- [ ] M4 Renderer: `render_layer.dart`, `skin.dart`, `animation_config.dart`, `renderer_service.dart`
- [ ] M5 Broadcast: `frame_buffer.dart`, `output_config.dart`, `ndi_service.dart`
- [ ] M6 Game: `game_state.dart`, `player.dart`, `pot.dart`, `round.dart`, `game_type.dart`, 4개 서비스 인터페이스, `game_history_repository.dart`
- [ ] M7 Config: `app_config.dart`, `game_preset.dart`, `config_service.dart`, `preset_repository.dart`
- [ ] M8 Common: `plugin_service.dart`

### Phase 4: Data 레이어 (스텁 구현체)
- [ ] M1 RFID: `simulated_rfid_service.dart`, `card_mapping_repository_impl.dart`
- [ ] M2 Hand Eval: `bitmask_evaluator.dart` (스텁), `simulated_hand_eval_service.dart`
- [ ] M3 Network: `simulated_connection_service.dart`, `message_encoder.dart` (스텁), `message_decoder.dart` (스텁)
- [ ] M4 Renderer: `rive_renderer_impl.dart` (스텁), `rive_state_controller.dart` (스텁)
- [ ] M5 Broadcast: `simulated_ndi_service.dart`
- [ ] M6 Game: `game_state_machine.dart` (스텁), `game_database.dart` (Drift 스켈레톤)
- [ ] M7 Config: `config_loader.dart`, `config_watcher.dart`, `preset_repository_impl.dart`
- [ ] M8 Common: `plugin_registry.dart`

### Phase 5: Presentation 레이어 (빈 Shell)
- [ ] `shell/app_shell.dart` — 메인 레이아웃 (사이드바 + 콘텐츠 영역)
- [ ] `shell/navigation/app_router.dart` — 화면 라우팅
- [ ] `shell/screens/home_screen.dart` — 대시보드
- [ ] 각 모듈 `providers/` 파일 — Riverpod Provider 선언
- [ ] 각 모듈 핵심 위젯 스텁 (빈 Container + 모듈명 표시)
- [ ] `main.dart` — ProviderScope + AppShell

### Phase 6: 설정 파일
- [ ] `assets/config/default_config.json` — 기본 설정 JSON
- [ ] `assets/config/card_mapping.json` — 카드 매핑 테이블

### Phase 7: 빌드 검증
- [ ] `flutter pub get` 성공
- [ ] `flutter analyze` 오류 0건
- [ ] `flutter build windows` 성공
- [ ] 앱 실행 시 빈 Shell 표시

## 영향 파일 목록 (Affected Files)

모든 파일은 신규 생성. 프로젝트 루트: `C:\claude\ebs_reverse_app\pokergfx_flutter\`

### 프로젝트 설정 (3 files)
- `pubspec.yaml`
- `analysis_options.yaml`
- `lib/main.dart`

### Core (8 files)
- `lib/core/constants/app_constants.dart`
- `lib/core/errors/exceptions.dart`
- `lib/core/errors/failures.dart`
- `lib/core/events/event_bus.dart`
- `lib/core/events/app_events.dart`
- `lib/core/di/service_locator.dart`
- `lib/core/crypto/aes_util.dart`
- `lib/core/logging/logger.dart`

### Shell (4 files)
- `lib/app.dart`
- `lib/shell/app_shell.dart`
- `lib/shell/navigation/app_router.dart`
- `lib/shell/screens/home_screen.dart`

### M1 RFID (10 files)
- `lib/features/rfid/domain/entities/rfid_card.dart`
- `lib/features/rfid/domain/entities/antenna_config.dart`
- `lib/features/rfid/domain/services/rfid_service.dart`
- `lib/features/rfid/domain/repositories/card_mapping_repository.dart`
- `lib/features/rfid/data/ffi/hidapi_bindings.dart`
- `lib/features/rfid/data/ffi/hidapi_rfid_service.dart`
- `lib/features/rfid/data/tcp/tcp_rfid_service.dart`
- `lib/features/rfid/data/simulation/simulated_rfid_service.dart`
- `lib/features/rfid/data/repositories/card_mapping_repository_impl.dart`
- `lib/features/rfid/presentation/providers/rfid_providers.dart`

### M2 Hand Eval (7 files)
- `lib/features/hand_eval/domain/entities/card.dart`
- `lib/features/hand_eval/domain/entities/poker_hand.dart`
- `lib/features/hand_eval/domain/entities/hand_rank.dart`
- `lib/features/hand_eval/domain/services/hand_evaluation_service.dart`
- `lib/features/hand_eval/data/evaluators/bitmask_evaluator.dart`
- `lib/features/hand_eval/data/evaluators/monte_carlo_calculator.dart`
- `lib/features/hand_eval/presentation/providers/hand_eval_providers.dart`

### M3 Network (10 files)
- `lib/features/network/domain/entities/protocol_message.dart`
- `lib/features/network/domain/entities/client_info.dart`
- `lib/features/network/domain/entities/command_type.dart`
- `lib/features/network/domain/services/discovery_service.dart`
- `lib/features/network/domain/services/connection_service.dart`
- `lib/features/network/domain/repositories/remote_registry.dart`
- `lib/features/network/data/udp/udp_discovery_impl.dart`
- `lib/features/network/data/tcp/tcp_connection_impl.dart`
- `lib/features/network/data/codec/message_encoder.dart`
- `lib/features/network/data/codec/message_decoder.dart`
- `lib/features/network/data/simulation/simulated_connection_service.dart`
- `lib/features/network/presentation/providers/network_providers.dart`

### M4 Renderer (8 files)
- `lib/features/renderer/domain/entities/render_layer.dart`
- `lib/features/renderer/domain/entities/skin.dart`
- `lib/features/renderer/domain/entities/animation_config.dart`
- `lib/features/renderer/domain/services/renderer_service.dart`
- `lib/features/renderer/data/rive/rive_renderer_impl.dart`
- `lib/features/renderer/data/rive/rive_state_controller.dart`
- `lib/features/renderer/data/skin/skin_loader.dart`
- `lib/features/renderer/presentation/providers/renderer_providers.dart`

### M5 Broadcast (6 files)
- `lib/features/broadcast/domain/entities/frame_buffer.dart`
- `lib/features/broadcast/domain/entities/output_config.dart`
- `lib/features/broadcast/domain/services/ndi_service.dart`
- `lib/features/broadcast/data/ffi/ndi_bindings.dart`
- `lib/features/broadcast/data/ffi/ndi_service_impl.dart`
- `lib/features/broadcast/data/simulation/simulated_ndi_service.dart`
- `lib/features/broadcast/presentation/providers/broadcast_providers.dart`

### M6 Game (16 files)
- `lib/features/game/domain/entities/game_state.dart`
- `lib/features/game/domain/entities/player.dart`
- `lib/features/game/domain/entities/pot.dart`
- `lib/features/game/domain/entities/round.dart`
- `lib/features/game/domain/entities/game_type.dart`
- `lib/features/game/domain/services/game_cards_service.dart`
- `lib/features/game/domain/services/game_players_service.dart`
- `lib/features/game/domain/services/game_play_service.dart`
- `lib/features/game/domain/services/timers_service.dart`
- `lib/features/game/domain/repositories/game_history_repository.dart`
- `lib/features/game/data/state_machine/game_state_machine.dart`
- `lib/features/game/data/database/game_database.dart`
- `lib/features/game/data/database/tables/players_table.dart`
- `lib/features/game/data/database/tables/hands_table.dart`
- `lib/features/game/data/repositories/game_history_repository_impl.dart`
- `lib/features/game/presentation/providers/game_providers.dart`

### M7 Config (7 files)
- `lib/features/config/domain/entities/app_config.dart`
- `lib/features/config/domain/entities/game_preset.dart`
- `lib/features/config/domain/services/config_service.dart`
- `lib/features/config/domain/repositories/preset_repository.dart`
- `lib/features/config/data/json/config_loader.dart`
- `lib/features/config/data/json/config_watcher.dart`
- `lib/features/config/data/repositories/preset_repository_impl.dart`
- `lib/features/config/presentation/providers/config_providers.dart`

### M8 Common (2 files)
- `lib/features/common/domain/services/plugin_service.dart`
- `lib/features/common/data/plugins/plugin_registry.dart`

### Assets (2 files)
- `assets/config/default_config.json`
- `assets/config/card_mapping.json`

### 총계: 약 90 파일 (신규 생성)

## 위험 요소 (Risks)

### Risk-1: Freezed 코드 생성 실패
- **설명**: Freezed 어노테이션이 있는 엔티티 클래스가 40개 이상. `build_runner`가 상호 참조 문제로 생성 실패할 수 있다.
- **완화**: 엔티티 간 순환 참조를 금지하고, 각 모듈의 entities는 자기 모듈 내부만 참조. 모듈 간 참조가 필요하면 core/에 공유 타입을 정의.
- **영향**: 높음 (빌드 자체가 실패)

### Risk-2: NDI SDK Windows 바인딩 호환성
- **설명**: NDI SDK 5.x의 C 헤더를 dart:ffi로 바인딩할 때, 구조체 정렬 문제 또는 콜백 함수 포인터 처리가 복잡하다.
- **완화**: 스켈레톤 단계에서는 SimulatedNdiService만 사용. 실제 바인딩은 후속 세션에서 `ffigen`으로 자동 생성.
- **영향**: 중간 (스켈레톤에서는 시뮬레이션으로 우회)

### Risk-3: hidapi DLL 로드 실패
- **설명**: Windows에서 hidapi.dll 경로를 찾지 못하거나, 32/64bit 불일치가 발생할 수 있다.
- **완화**: `windows/` 하위에 DLL을 번들링하고, `DynamicLibrary.open()`에 절대 경로 사용. 스켈레톤에서는 시뮬레이션 모드 기본값.
- **영향**: 중간

### Risk-4: Drift 데이터베이스 스키마 변경 시 마이그레이션
- **설명**: 스켈레톤에서 테이블 구조를 확정한 후, 실제 구현에서 스키마 변경이 필요하면 마이그레이션 코드가 필요하다.
- **완화**: 스켈레톤에서는 최소 스키마만 정의. `schemaVersion: 1`으로 시작하고, 변경 시 stepByStep 마이그레이션 패턴 사용.
- **영향**: 낮음

### Risk-5: 90개 파일 생성 시 구현 누락
- **설명**: 파일 수가 많아 일부 파일 생성이 누락되거나, import 경로가 잘못될 수 있다.
- **완화**: 체크리스트 기반으로 Phase별 순차 구현. 각 Phase 완료 후 `flutter analyze` 실행. 누락 파일은 빌드 오류로 즉시 감지.
- **영향**: 중간

### Edge Cases

1. **카드 매핑 충돌**: 동일 RFID UID가 두 개의 카드에 매핑되는 경우 → `CardMappingRepository`에서 중복 검증 로직 필요 (후속 세션)
2. **게임 타입 22개 변형의 인터페이스 통합**: 모든 게임 타입이 동일 `GamePlayService` 인터페이스를 공유하나, 실제 규칙이 크게 다름 → Strategy 패턴으로 게임 타입별 구현체 분리 필요
3. **동시 RFID 스캔**: 여러 안테나에서 동시에 카드가 감지되면 이벤트 순서 보장이 필요 → Stream에 시간 기반 정렬 필요 (후속 세션)
4. **설정 핫리로드 중 게임 진행**: 게임 도중 설정 변경이 현재 게임 상태에 영향을 주면 안 됨 → 설정 변경은 다음 핸드부터 적용되도록 설계

## 태스크 목록 (Tasks)

### Task 1: Flutter 프로젝트 초기화
- **설명**: `flutter create` 실행 후 pubspec.yaml 의존성 추가, 디렉토리 구조 생성
- **수행 방법**: `flutter create --platforms=windows --project-name=pokergfx pokergfx_flutter` → pubspec.yaml 편집 → `flutter pub get` → 디렉토리 생성
- **Acceptance Criteria**: `flutter pub get` 성공, 디렉토리 구조 존재 확인

### Task 2: Core 레이어 구현
- **설명**: EventBus, AppEvents, Exception/Failure, AesUtil, Logger, Constants 구현
- **수행 방법**: `lib/core/` 하위 8개 파일 작성. EventBus는 StreamController 기반, Logger는 logger 패키지 래퍼
- **Acceptance Criteria**: `flutter analyze` 에서 core/ 관련 오류 0건

### Task 3: Domain 레이어 — 엔티티 + 인터페이스 (M1-M8)
- **설명**: 8개 모듈의 domain/ 하위 엔티티 (Freezed) + 서비스 인터페이스 (abstract class) + 리포지토리 인터페이스
- **수행 방법**: 모듈별 핵심 파일 목록 섹션의 domain 파일 전부 생성. Freezed 어노테이션은 `@freezed`만 선언하고 `part` 파일 지정
- **Acceptance Criteria**: 모든 domain 파일이 존재하고, abstract class에 메서드 시그니처가 모두 선언됨. `build_runner` 실행 전이므로 `.g.dart`/`.freezed.dart` 미존재 허용

### Task 4: Data 레이어 — Simulation 구현체
- **설명**: 각 모듈의 시뮬레이션 구현체 + 최소 구현체 스텁 작성
- **수행 방법**: `data/simulation/` 하위에 시뮬레이션 클래스 작성. 메서드는 더미 데이터 반환 또는 `throw UnimplementedError()`
- **Acceptance Criteria**: 모든 서비스 인터페이스에 대해 최소 1개의 구현체 (시뮬레이션) 존재

### Task 5: Data 레이어 — FFI/네이티브 스텁
- **설명**: hidapi_bindings, ndi_bindings, Drift 데이터베이스 스켈레톤
- **수행 방법**: dart:ffi 함수 시그니처만 선언 (`lookUpFunction` 호출부는 `// TODO` 주석). Drift 테이블 2개 정의
- **Acceptance Criteria**: FFI 바인딩 파일이 존재하고, 함수 시그니처가 원본 C 헤더와 일치

### Task 6: Presentation 레이어 — Provider + Shell
- **설명**: 각 모듈의 Riverpod Provider 선언 + AppShell + 라우팅 + 기본 화면
- **수행 방법**: Provider 파일에서 시뮬레이션 구현체를 기본값으로 주입. AppShell은 NavigationRail + body 구조
- **Acceptance Criteria**: 앱 실행 시 빈 Shell이 표시되고, 네비게이션으로 각 모듈 화면 전환 가능

### Task 7: 설정 파일 + build_runner
- **설명**: default_config.json, card_mapping.json 작성 + `dart run build_runner build`
- **수행 방법**: JSON 파일 작성 → pubspec.yaml에 assets 등록 → build_runner 실행
- **Acceptance Criteria**: `.freezed.dart`, `.g.dart` 파일 생성 성공, `flutter analyze` 오류 0건

### Task 8: 빌드 검증
- **설명**: 전체 빌드 + 실행 테스트
- **수행 방법**: `flutter analyze` → `flutter build windows` → 실행 확인
- **Acceptance Criteria**: 빌드 성공, 앱 실행 시 Shell 표시, 콘솔에 치명적 오류 없음

## 커밋 전략 (Commit Strategy)

| 순서 | 커밋 메시지 | Task |
|:----:|-----------|:----:|
| 1 | `feat(init): Flutter 프로젝트 초기화 + 의존성 설정` | T1 |
| 2 | `feat(core): EventBus, 로깅, 암호화, 에러 처리 기반 구현` | T2 |
| 3 | `feat(domain): 8개 모듈 엔티티 + 서비스 인터페이스 정의` | T3 |
| 4 | `feat(data): 시뮬레이션 구현체 + FFI 스텁 + Drift 스켈레톤` | T4, T5 |
| 5 | `feat(ui): AppShell + 라우팅 + Riverpod Provider 연결` | T6 |
| 6 | `feat(config): 기본 설정 JSON + Freezed 코드 생성` | T7 |
| 7 | `chore(build): 빌드 검증 + 분석 오류 수정` | T8 |
