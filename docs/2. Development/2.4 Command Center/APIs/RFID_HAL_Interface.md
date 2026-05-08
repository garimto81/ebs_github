---
title: RFID HAL Interface Contract
owner: team4
tier: contract
legacy-id: API-03
last-updated: 2026-04-21
reimplementability: N/A
reimplementability_checked: 2026-04-21
reimplementability_notes: "SG-011 out_of_scope_prototype 에 맞춰 N/A. 프로토타입 범위 밖 — 실제 HAL 은 하드웨어 팀 인계 후 제조사 SDK (ST25R3911B/ESP32 펌웨어 등) 기반으로 확정. Mock/single-stream spec block 은 legacy 설계 잔존이며 drift 로 간주하지 않음 (drift_ignore_rfid=true)."
out_of_scope_prototype: true
drift_ignore_rfid: true
drift_ignore_reason: "SG-011 OUT_OF_SCOPE — 프로토타입 범위 밖. single-stream spec block 은 legacy 설계안, 실제 HAL 은 개발팀이 제조사 SDK 기반으로 확정"
confluence-page-id: 3818455474
confluence-parent-id: 3811901565
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818455474/EBS+RFID+HAL+Interface+Contract
---
# API-03 RFID HAL Interface — Real/Mock RFID 교체 계약

> **역할**: 이 문서는 **엔지니어용 인터페이스 계약서** 다 (`IRfidReader` 시그니처, 이벤트 타입, 에러 코드, 리더 생명주기). 운영자 관점 동작 가이드는 `RFID_HAL.md` (BS-04-04) 를 참조한다. 두 문서는 서로를 보완하며 독립 편집된다.

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | IRfidReader 인터페이스, 이벤트 타입, Mock HAL 사양, DI 교체, 테스트 케이스 |
| 2026-04-10 | CCR-022 | §9~§13 — UART 생명주기, 안테나 튜닝 재시도, 펌웨어 감지, 다중 리더, ST25R3916 마이그레이션 |
| 2026-04-15 | 개명 | `RFID_HAL_Legacy.md` → `RFID_HAL_Interface.md`. "Legacy" 네이밍이 실제 역할(인터페이스 계약서)을 왜곡하여 정정. frontmatter title/tier 갱신 |
| 2026-05-07 | v4 cascade (derive) | 인터페이스 계약 자체는 변경 없음. derive 정합 — IRfidReader 이벤트가 CC v4.0 4 영역 위계 (StatusBar dot / PlayerGrid SeatCell 행 6 / TopStrip Community Board / Reader Panel AT-05) 에 dispatch 되는 매핑은 `RFID_HAL.md` (운영자 관점) 에 명시. SSOT: `../Command_Center_UI/Overview.md §3.0`. |

---

## 개요

이 문서는 EBS RFID HAL(Hardware Abstraction Layer)의 **인터페이스 계약 정본**이다. 상위 계층(CC, Game Engine)은 `IRfidReader` 추상 인터페이스만 참조하며, Real HAL과 Mock HAL을 DI(Dependency Injection)로 교체한다.

```
┌──────────────────────────────────────┐
│  Application Layer                   │
│  (CC UI, Game Engine)                │
│  ← IRfidReader 인터페이스만 참조     │
├──────────────────────────────────────┤
│  HAL Interface                       │
│  IRfidReader (abstract)              │
├────────────┬─────────────────────────┤
│ Real HAL   │ Mock HAL               │
│ ST25R3911B │ MockRfidReader          │
│ Serial     │ 소프트웨어 에뮬레이션   │
└────────────┴─────────────────────────┘
```

**핵심 원칙**: Mock HAL은 Real HAL과 **동일한 이벤트 스트림**을 생성한다. 상위 계층은 Real/Mock을 구분하지 않는다.

> **참조**: Mock 모드 정의는 `BS-00-definitions.md §9`, 트리거 합성 규칙은 `Triggers.md §4` (legacy-id: `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: BS-06-00-triggers))), 용어 정의는 `BS-00-definitions.md`

---

## 1. 계층 분리 원칙

### 1.1 왜 HAL이 필요한가

| 문제 | 해결 |
|------|------|
| RFID 하드웨어 없이 개발/테스트 불가 | Mock HAL로 하드웨어 독립 개발 |
| 하드웨어 변경 시 전체 코드 수정 | HAL 구현체만 교체, 상위 코드 변경 없음 |
| 테스트 재현성 없음 (하드웨어 타이밍 비결정적) | Mock HAL은 결정적 타이밍 |
| 에러 시나리오 재현 어려움 | Mock HAL 에러 주입 API |

### 1.2 계층별 책임

| 계층 | 책임 | 참조 대상 |
|------|------|----------|
| **Application** (CC, Engine) | 이벤트 스트림 구독, 비즈니스 로직 | `IRfidReader` 인터페이스만 |
| **HAL Interface** | 추상 인터페이스 정의 | 이 문서 §2 |
| **Real HAL** | 물리 하드웨어와 Serial UART 통신 | 이 문서 §5 |
| **Mock HAL** | 소프트웨어 이벤트 합성 | 이 문서 §6 |

### 1.3 금지 사항

- Application 계층에서 `RealRfidReader` 또는 `MockRfidReader` 직접 참조 금지
- HAL 구현체 내부에서 Game Engine 로직 실행 금지
- Real HAL과 Mock HAL 간 코드 공유 금지 (인터페이스만 공유)

---

## 2. IRfidReader — Dart Abstract Class

> **2026-04-20 drift 경고 (Type D3)**: 본 §2.1 의 단일 `Stream<RfidEvent> get events` 와 `team4-cc/src/lib/rfid/abstract/i_rfid_reader.dart` 의 **6개 분리 스트림**(`onCardDetected`, `onCardRemoved`, `onDeckRegistered`, `onAntennaStatusChanged`, `onError`, `onStatusChanged`) 이 일치하지 않는다. 현재 **코드 구현이 정본** (type-safe 스트림 분리 의도 명확). 본 문서는 역사적 이유로 단일 스트림 설계를 기재했으며, 후속 Revision 에서 6-스트림으로 정정 예정. 즉각 통합 작업은 `SG-011` 참조.

### 2.1 전체 인터페이스

```dart
/// RFID 리더 하드웨어 추상 인터페이스.
/// Real HAL과 Mock HAL이 이 인터페이스를 구현한다.
abstract class IRfidReader {
  /// RFID 이벤트 스트림. 카드 감지, 제거, 덱 등록, 에러 등 모든 이벤트를 발행한다.
  Stream<RfidEvent> get events;

  /// 리더 초기화. 하드웨어 연결(Real) 또는 가상 리더 생성(Mock).
  /// 실패 시 RfidInitializationException을 throw한다.
  Future<void> initialize();

  /// 리더 종료. 리소스 해제, 스트림 닫기.
  Future<void> dispose();

  /// 덱 등록 시작. 52장 카드를 스캔하여 UID-카드 매핑을 생성한다.
  /// Real: 물리 스캔 (약 3~5분), Mock: 즉시 가상 매핑.
  Future<DeckRegistrationResult> registerDeck();

  /// 현재 리더 상태.
  RfidReaderStatus get status;

  /// 리더 모드 (real 또는 mock).
  RfidReaderMode get mode;

  /// 연결된 안테나 목록.
  List<AntennaInfo> get antennas;
}
```

### 2.2 보조 타입

```dart
/// 리더 상태
enum RfidReaderStatus {
  disconnected,   // 초기 상태 또는 연결 해제
  initializing,   // 초기화 진행 중
  ready,          // 사용 가능
  scanning,       // 덱 등록 스캔 진행 중
  error,          // 오류 상태
}

/// 리더 모드
enum RfidReaderMode {
  real,           // 물리 하드웨어 연결
  mock,           // 소프트웨어 에뮬레이션
}

/// 안테나 정보
class AntennaInfo {
  final int antennaId;
  final AntennaStatus status;
  final String? label;         // 예: "Seat 0 Left", "Board Center"

  const AntennaInfo({
    required this.antennaId,
    required this.status,
    this.label,
  });
}

/// 안테나 상태
enum AntennaStatus {
  connected,      // 정상 연결
  disconnected,   // 연결 해제
  error,          // 오류
}

/// 덱 등록 결과
class DeckRegistrationResult {
  final String deckId;
  final Map<String, Card> cardMap;   // UID → Card (52장)
  final int scannedCount;
  final int failedCount;
  final DeckRegistrationStatus status;

  const DeckRegistrationResult({
    required this.deckId,
    required this.cardMap,
    required this.scannedCount,
    required this.failedCount,
    required this.status,
  });
}

/// 덱 등록 상태
enum DeckRegistrationStatus {
  success,        // 52장 전체 등록 완료
  partial,        // 일부 카드 등록 실패
  failed,         // 등록 실패
  cancelled,      // 사용자 취소
}
```

---

## 3. 이벤트 타입 — RfidEvent Sealed Class Hierarchy

> **참조**: RFID 이벤트 카탈로그는 `Triggers.md §2.2` (legacy-id: `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: BS-06-00-triggers)))

```dart
/// RFID HAL이 발행하는 모든 이벤트의 기본 타입.
sealed class RfidEvent {
  final DateTime timestamp;
  const RfidEvent({required this.timestamp});
}
```

### 3.1 CardDetected

카드가 안테나 위에 감지되었을 때 발행.

```dart
class CardDetected extends RfidEvent {
  final int antennaId;        // 감지한 안테나 ID
  final String cardUid;       // RFID UID (16자 16진 문자열, Mock: "MOCK-{suit}{rank}")
  final int suit;             // 0=Spade, 1=Heart, 2=Diamond, 3=Club
  final int rank;             // 0=Two ~ 12=Ace
  final double confidence;    // 인식 신뢰도 (0.0~1.0, Mock: 항상 1.0)

  const CardDetected({
    required this.antennaId,
    required this.cardUid,
    required this.suit,
    required this.rank,
    required this.confidence,
    required super.timestamp,
  });
}
```

| 필드 | Real HAL | Mock HAL |
|------|----------|----------|
| `antennaId` | 실제 안테나 ID (0~23) | 0 (Mock 고정값) |
| `cardUid` | 실제 RFID UID | `"MOCK-{suit}{rank}"` 형식 |
| `suit` | 덱 등록 시 매핑된 값 | 직접 전달된 값 |
| `rank` | 덱 등록 시 매핑된 값 | 직접 전달된 값 |
| `confidence` | 0.0~1.0 (신호 강도) | 항상 1.0 |

### 3.2 CardRemoved

카드가 안테나에서 제거되었을 때 발행.

```dart
class CardRemoved extends RfidEvent {
  final int antennaId;
  final String cardUid;

  const CardRemoved({
    required this.antennaId,
    required this.cardUid,
    required super.timestamp,
  });
}
```

> **주의**: 카드 제거는 "정보"이지 "액션"이 아니다. 폴드는 반드시 운영자 CC 버튼으로만 실행. (`Triggers.md` (legacy-id: `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: BS-06-00-triggers)))) §3.2)

### 3.3 DeckRegistered

52장 덱 등록이 완료되었을 때 발행.

```dart
class DeckRegistered extends RfidEvent {
  final String deckId;
  final Map<String, Card> cardMap;   // UID → Card (52장)

  const DeckRegistered({
    required this.deckId,
    required this.cardMap,
    required super.timestamp,
  });
}
```

### 3.4 DeckRegistrationProgress

덱 등록 진행 상황을 보고.

```dart
class DeckRegistrationProgress extends RfidEvent {
  final int scannedCount;     // 현재까지 스캔된 카드 수
  final int totalCount;       // 전체 카드 수 (52)

  const DeckRegistrationProgress({
    required this.scannedCount,
    required this.totalCount,
    required super.timestamp,
  });
}
```

| 모드 | 동작 |
|------|------|
| Real | 카드 1장 스캔될 때마다 발행 (최대 52회) |
| Mock | 1회만 발행 (scannedCount=52, totalCount=52) |

### 3.5 AntennaStatusChanged

안테나 연결 상태가 변경되었을 때 발행.

```dart
class AntennaStatusChanged extends RfidEvent {
  final int antennaId;
  final AntennaStatus status;

  const AntennaStatusChanged({
    required this.antennaId,
    required this.status,
    required super.timestamp,
  });
}
```

### 3.6 ReaderError

RFID 하드웨어 오류가 발생했을 때 발행.

```dart
class ReaderError extends RfidEvent {
  final RfidErrorCode errorCode;
  final String message;
  final int? antennaId;       // null = 리더 전체 오류

  const ReaderError({
    required this.errorCode,
    required this.message,
    this.antennaId,
    required super.timestamp,
  });
}
```

---

## 4. 에러 코드 카탈로그

```dart
enum RfidErrorCode {
  // 연결 에러 (100번대)
  connectionLost(100, "리더 연결 끊김"),
  connectionTimeout(101, "리더 연결 타임아웃"),
  serialPortError(102, "Serial 포트 오류"),

  // 안테나 에러 (200번대)
  antennaDisconnected(200, "안테나 연결 해제"),
  antennaOverload(201, "안테나 과부하 (다수 태그 동시 감지)"),
  antennaCalibrationFailed(202, "안테나 캘리브레이션 실패"),

  // 카드 에러 (300번대)
  duplicateCard(300, "동일 카드 중복 감지"),
  unknownCard(301, "등록되지 않은 카드 UID"),
  readError(302, "카드 읽기 실패 (신호 약함)"),
  cardConflict(303, "CC 수동 입력과 RFID 감지 불일치"),

  // 덱 에러 (400번대)
  deckRegistrationFailed(400, "덱 등록 실패"),
  deckIncomplete(401, "덱 불완전 (52장 미만)"),
  deckDuplicate(402, "덱 내 중복 카드 발견"),

  // 시스템 에러 (500번대)
  firmwareError(500, "펌웨어 오류"),
  memoryOverflow(501, "메모리 초과"),
  unknownError(599, "알 수 없는 오류");

  final int code;
  final String description;
  const RfidErrorCode(this.code, this.description);
}
```

| 범위 | 분류 | 복구 가능 여부 |
|------|------|:-------------:|
| 100~199 | 연결 | 자동 재연결 시도 |
| 200~299 | 안테나 | 수동 확인 필요 |
| 300~399 | 카드 | 자동 무시 또는 운영자 확인 |
| 400~499 | 덱 | 재등록 필요 |
| 500~599 | 시스템 | 리더 재시작 필요 |

---

## 5. Real HAL 구현 힌트

### 5.1 하드웨어 사양

| 항목 | 값 |
|------|:--:|
| RFID IC | ST25R3911B |
| MCU | ESP32 |
| 통신 | Serial UART (115200 baud) |
| 프로토콜 | ISO 14443A / ISO 15693 |
| 안테나 | 테이블당 최대 24개 (좌석 10×2 + 보드 4) |

### 5.2 RealRfidReader 구현 개요

```dart
class RealRfidReader implements IRfidReader {
  final SerialPort _port;
  final StreamController<RfidEvent> _eventController;

  // Serial UART에서 바이트 스트림을 수신하여 RfidEvent로 변환
  // 프로토콜 파싱은 별도 _RfidProtocolParser 클래스에 위임
  // 안테나별 폴링 주기: 50ms
  // 카드 감지 시 confidence = RSSI 기반 0.0~1.0 변환
}
```

### 5.3 Real HAL 타이밍

| 동작 | 예상 시간 | 비고 |
|------|:--------:|------|
| 초기화 | 1~3초 | Serial 포트 열기 + 펌웨어 버전 확인 |
| 카드 감지 | 50~150ms | 안테나 폴링 주기에 의존 |
| 카드 제거 감지 | 100~300ms | 신호 소실 후 디바운스 |
| 덱 등록 (52장) | 3~5분 | 카드 1장씩 수동 스캔 |

---

## 6. Mock HAL 구현 사양

### 6.1 MockRfidReader Class

```dart
class MockRfidReader implements IRfidReader {
  final StreamController<RfidEvent> _eventController =
      StreamController<RfidEvent>.broadcast();

  @override
  Stream<RfidEvent> get events => _eventController.stream;

  @override
  RfidReaderStatus get status => _status;

  @override
  RfidReaderMode get mode => RfidReaderMode.mock;

  @override
  Future<void> initialize() async {
    _status = RfidReaderStatus.ready;
    _eventController.add(AntennaStatusChanged(
      antennaId: 0,
      status: AntennaStatus.connected,
      timestamp: DateTime.now(),
    ));
  }

  @override
  Future<void> dispose() async {
    await _eventController.close();
  }

  @override
  Future<DeckRegistrationResult> registerDeck() async {
    return autoRegisterDeck();
  }
}
```

### 6.2 Mock 전용 API

CC UI의 수동 입력을 RFID 이벤트로 합성하는 메서드.

```dart
extension MockRfidReaderApi on MockRfidReader {

  /// 카드 감지 이벤트 합성. CC에서 수동 카드 입력 시 호출.
  void injectCard(int suit, int rank, {int antennaId = 0}) {
    final uid = 'MOCK-$suit$rank';
    _eventController.add(CardDetected(
      antennaId: antennaId,
      cardUid: uid,
      suit: suit,
      rank: rank,
      confidence: 1.0,
      timestamp: DateTime.now(),
    ));
  }

  /// 카드 제거 이벤트 합성. 테스트 시나리오에서 사용.
  void injectRemoval(int suit, int rank, {int antennaId = 0}) {
    final uid = 'MOCK-$suit$rank';
    _eventController.add(CardRemoved(
      antennaId: antennaId,
      cardUid: uid,
      timestamp: DateTime.now(),
    ));
  }

  /// 52장 가상 덱 즉시 등록. "자동 등록" 버튼에서 호출.
  DeckRegistrationResult autoRegisterDeck() {
    final cardMap = <String, Card>{};
    for (int suit = 0; suit < 4; suit++) {
      for (int rank = 0; rank < 13; rank++) {
        final uid = 'MOCK-$suit$rank';
        cardMap[uid] = Card(suit: suit, rank: rank);
      }
    }

    final deckId = 'MOCK-DECK-${DateTime.now().millisecondsSinceEpoch}';

    _eventController.add(DeckRegistrationProgress(
      scannedCount: 52,
      totalCount: 52,
      timestamp: DateTime.now(),
    ));

    _eventController.add(DeckRegistered(
      deckId: deckId,
      cardMap: cardMap,
      timestamp: DateTime.now(),
    ));

    return DeckRegistrationResult(
      deckId: deckId,
      cardMap: cardMap,
      scannedCount: 52,
      failedCount: 0,
      status: DeckRegistrationStatus.success,
    );
  }

  /// 에러 이벤트 주입. 테스트용 에러 시나리오 재현.
  void injectError(RfidErrorCode errorCode, {int? antennaId}) {
    _eventController.add(ReaderError(
      errorCode: errorCode,
      message: errorCode.description,
      antennaId: antennaId,
      timestamp: DateTime.now(),
    ));
  }

  /// YAML 시나리오 파일 로드 및 재생. E2E 테스트에서 사전 정의된
  /// 이벤트 시퀀스를 결정적 타이밍으로 재생한다.
  Future<void> loadScenario(String yamlPath) async {
    // YAML 파싱 → List<ScenarioEvent> 변환
    // 각 이벤트의 delay_ms 후 순차 발행
    // 결정적 타이밍 보장 (테스트 재현성)
  }
}
```

### 6.3 결정적 타이밍 (테스트 재현성)

Mock HAL은 **결정적 타이밍**을 보장하여 테스트 재현성을 확보한다.

| 항목 | Real HAL | Mock HAL |
|------|----------|----------|
| 카드 감지 지연 | 50~150ms (하드웨어 의존) | 0ms (즉시) 또는 시나리오 지정값 |
| 덱 등록 시간 | 3~5분 | 0ms (즉시) |
| 에러 발생 | 비결정적 | 명시적 주입만 |
| 타임스탬프 | `DateTime.now()` | `DateTime.now()` 또는 시나리오 고정값 |

### 6.4 시나리오 파일 형식

> **참조**: `Triggers.md §4.3` (legacy-id: `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: BS-06-00-triggers))) 시나리오 스크립트

```yaml
# scenarios/holdem-basic.yaml
scenario: "Basic Hold'em Hand"
description: "2인 헤즈업, 프리플롭 올인, 보드 5장 공개"
events:
  - type: DeckRegistered
    delay_ms: 0

  # 플레이어 1 홀카드
  - type: CardDetected
    delay_ms: 100
    payload:
      antenna_id: 0
      suit: 3        # Club
      rank: 12       # Ace → Ac
  - type: CardDetected
    delay_ms: 100
    payload:
      antenna_id: 0
      suit: 2        # Diamond
      rank: 11       # King → Kd

  # 플레이어 2 홀카드
  - type: CardDetected
    delay_ms: 100
    payload:
      antenna_id: 1
      suit: 0        # Spade
      rank: 10       # Queen → Qs
  - type: CardDetected
    delay_ms: 100
    payload:
      antenna_id: 1
      suit: 1        # Heart
      rank: 9        # Jack → Jh

  # Flop (보드 카드 3장)
  - type: CardDetected
    delay_ms: 500
    payload:
      antenna_id: 20
      suit: 0
      rank: 7        # 9s
  - type: CardDetected
    delay_ms: 50
    payload:
      antenna_id: 21
      suit: 1
      rank: 4        # 6h
  - type: CardDetected
    delay_ms: 50
    payload:
      antenna_id: 22
      suit: 2
      rank: 1        # 3d

  # Turn
  - type: CardDetected
    delay_ms: 300
    payload:
      antenna_id: 23
      suit: 3
      rank: 0        # 2c

  # River
  - type: CardDetected
    delay_ms: 300
    payload:
      antenna_id: 23
      suit: 0
      rank: 12       # As
```

---

## 7. DI 교체 메커니즘 — Riverpod Provider

### 7.1 Provider 정의

```dart
/// RFID 리더 모드 설정. BO Config에서 로드.
final rfidModeProvider = StateProvider<RfidReaderMode>((ref) {
  // BO Config에서 RFID 모드를 읽어 반환
  // 기본값: RfidReaderMode.mock (개발 환경)
  return RfidReaderMode.mock;
});

/// RFID 리더 인스턴스. 모드에 따라 Real 또는 Mock을 생성.
final rfidReaderProvider = Provider<IRfidReader>((ref) {
  final mode = ref.watch(rfidModeProvider);
  switch (mode) {
    case RfidReaderMode.real:
      return RealRfidReader(port: ref.read(serialPortProvider));
    case RfidReaderMode.mock:
      return MockRfidReader();
  }
});

/// RFID 이벤트 스트림. 모든 상위 위젯/서비스가 이 Provider를 구독.
final rfidEventsProvider = StreamProvider<RfidEvent>((ref) {
  final reader = ref.watch(rfidReaderProvider);
  return reader.events;
});
```

### 7.2 교체 시점

| 시점 | 동작 | 주의 |
|------|------|------|
| 앱 시작 시 | BO Config에서 `rfid_mode` 읽기 → Provider 초기화 | 기본값: mock |
| 런타임 변경 | `rfidModeProvider` 값 변경 → 자동으로 새 구현체 생성 | 현재 핸드 종료 후 적용 |
| 테스트 | `ProviderScope(overrides: [...])` 로 Mock 강제 주입 | 항상 MockRfidReader |

### 7.3 교체 흐름

```
BO Config (rfid_mode: "mock")
    │
    ▼
rfidModeProvider → RfidReaderMode.mock
    │
    ▼
rfidReaderProvider → MockRfidReader()
    │
    ▼
rfidEventsProvider → Stream<RfidEvent>
    │
    ▼
CC UI / Game Engine (구현체 무관하게 이벤트 소비)
```

---

## 8. 테스트 케이스 목록

### 8.1 인터페이스 계약 테스트 (Real/Mock 공통)

| ID | 테스트 | 기대 결과 |
|----|--------|----------|
| T-01 | `initialize()` 호출 → status 확인 | `RfidReaderStatus.ready` |
| T-02 | `initialize()` 후 `events` 스트림 구독 | 스트림 활성화, 에러 없음 |
| T-03 | `dispose()` 호출 → 스트림 종료 확인 | 스트림 `done` 이벤트 수신 |
| T-04 | `registerDeck()` → 결과 확인 | 52장 매핑, status=success |
| T-05 | `registerDeck()` 중 progress 이벤트 수신 | `DeckRegistrationProgress` 1회 이상 |

### 8.2 CardDetected 테스트

| ID | 테스트 | 기대 결과 |
|----|--------|----------|
| T-10 | 카드 1장 감지 → 이벤트 수신 | `CardDetected` 이벤트, suit/rank 정확 |
| T-11 | 동일 카드 2회 감지 | 두 번째 이벤트 수신 (중복 처리는 Engine 책임) |
| T-12 | suit=0~3, rank=0~12 전 범위 | 52장 모두 정상 이벤트 |
| T-13 | confidence 값 범위 확인 | 0.0 ~ 1.0 (Mock: 항상 1.0) |

### 8.3 CardRemoved 테스트

| ID | 테스트 | 기대 결과 |
|----|--------|----------|
| T-20 | 감지된 카드 제거 → 이벤트 수신 | `CardRemoved` 이벤트, cardUid 일치 |
| T-21 | 감지되지 않은 카드 제거 | `unknownCard` 에러 또는 무시 |

### 8.4 DeckRegistered 테스트

| ID | 테스트 | 기대 결과 |
|----|--------|----------|
| T-30 | 52장 완전 등록 | `DeckRegistered`, cardMap 크기 52 |
| T-31 | 등록 중 에러 (Real: 카드 불량) | `deckIncomplete` 에러, partial 결과 |
| T-32 | 중복 카드 스캔 | `deckDuplicate` 에러 |

### 8.5 에러 시나리오 테스트

| ID | 테스트 | 기대 결과 |
|----|--------|----------|
| T-40 | 연결 끊김 시뮬레이션 | `ReaderError(connectionLost)` |
| T-41 | 안테나 해제 시뮬레이션 | `AntennaStatusChanged(disconnected)` + `ReaderError` |
| T-42 | 에러 주입 후 복구 | 에러 이벤트 → 재초기화 → ready 상태 |

### 8.6 Mock 전용 테스트

| ID | 테스트 | 기대 결과 |
|----|--------|----------|
| T-50 | `injectCard(3, 12)` | `CardDetected(suit=3, rank=12, uid="MOCK-312")` |
| T-51 | `injectRemoval(3, 12)` | `CardRemoved(uid="MOCK-312")` |
| T-52 | `autoRegisterDeck()` | 52장 매핑 즉시 완료 |
| T-53 | `injectError(connectionLost)` | `ReaderError(connectionLost)` |
| T-54 | `loadScenario("holdem-basic.yaml")` | 시나리오 순서대로 이벤트 발행 |
| T-55 | 결정적 타이밍 검증 | 동일 시나리오 2회 재생 시 이벤트 순서 동일 |

### 8.7 DI 교체 테스트

| ID | 테스트 | 기대 결과 |
|----|--------|----------|
| T-60 | `rfidModeProvider = mock` → 인스턴스 확인 | `MockRfidReader` |
| T-61 | `rfidModeProvider = real` → 인스턴스 확인 | `RealRfidReader` |
| T-62 | 런타임 모드 변경 → 이벤트 스트림 재구독 | 새 구현체의 스트림으로 전환 |
| T-63 | 테스트 오버라이드 | `ProviderScope(overrides)` 로 Mock 강제 주입 확인 |

---

## 9. 시리얼 UART 연결 생명주기 (CCR-022)

### 9.1 연결 FSM

```
DISCONNECTED ──open()──▶ CONNECTING ──handshake OK──▶ CONNECTED
      ▲                        │                        │
      │                        │ handshake fail         │
      │                        ▼                        │
      │                    CONNECTION_FAILED            │
      │                        │                        │
      │                        │ backoff                │
      │                        ▼                        │
      └────── close() ◀── RECONNECTING ◀──disconnect────┘
```

| 상태 | 설명 |
|------|------|
| `DISCONNECTED` | 초기 상태 또는 명시적 `close()` 후 |
| `CONNECTING` | `open()` 호출 중, 시리얼 포트 열기 시도 |
| `CONNECTED` | 정상 운영, 이벤트 수신/명령 송신 가능 |
| `CONNECTION_FAILED` | 포트 없음, 권한 거부, handshake 실패 |
| `RECONNECTING` | 자동 재연결 시도 중 |

### 9.2 이벤트 (IRfidReader 추가)

- `ConnectionStatusChanged { from: ReaderStatus, to: ReaderStatus, reason?: string }`
- `HandshakeComplete { firmware_version: string, chip_id: string, is_supported: bool, is_recommended: bool, warning_message?: string }`
- `HandshakeFailed { error_code: int, message: string }`

### 9.3 재연결 정책

```dart
class ReaderReconnectPolicy {
  // WSOP Fatima.app SignalR 정책과 통일 (BS-05-00 §BO 복구 참조)
  //
  // 시도 인덱스 | 대기 ms  | 의미
  //    0       |      0   | 즉시 1차 재시도 (RECONNECT_INITIAL_DELAY_MS)
  //    1       |   5 000  | 짧은 회복 대기 (RECONNECT_BACKOFF_SHORT_MS)
  //    2..100  |  10 000  | 장기 backoff 구간 (RECONNECT_BACKOFF_LONG_MS × 99회)
  static const int reconnectInitialDelayMs = 0;
  static const int reconnectBackoffShortMs = 5000;
  static const int reconnectBackoffLongMs = 10000;
  static const int reconnectLongAttempts = 99;   // 2..100번째 시도

  static const List<Duration> retryDelays = [
    Duration(milliseconds: reconnectInitialDelayMs),
    Duration(milliseconds: reconnectBackoffShortMs),
    Duration(milliseconds: reconnectBackoffLongMs),
  ];
  static const int maxRetries = 101;   // 1 + 1 + 99
}
```

### 9.4 핸드 진행 중 연결 끊김

`HandFSM != IDLE` 중 리더가 끊기면:

1. CC가 AT-01에 경고 배너: "RFID 리더 끊김 — 수동 입력 모드"
2. AT-03 Card Selector 진입 가능 (수동 입력 폴백)
3. 재연결 시도 백그라운드 지속
4. 재연결 성공: 배너 해제, RFID 감지 재개
5. 핸드 종료까지 재연결 실패: 수동 입력으로 핸드 완료

### 9.5 Mock 시뮬레이션 API

```dart
abstract class IMockRfidReader implements IRfidReader {
  void injectDisconnect();
  void injectReconnect();
  void simulateHandshakeFailure(int errorCode);
}
```

---

## 10. 안테나 튜닝 재시도 (CCR-022)

### 10.1 배경

ST25R3911B(후속 ST25R3916)는 안테나 매칭 임피던스를 자동 튜닝한다. 금속 포커 테이블, 주변 베팅 토큰 등 환경 변수로 튜닝이 실패할 수 있다.

### 10.2 이벤트 및 판정

- `AntennaStatusChanged { tuning_quality: float, status: "tuned" | "degraded" | "failed" }`
- `tuning_quality >= 0.6` → `tuned` (정상)
- `0.3 <= tuning_quality < 0.6` → `degraded` (경고)
- `tuning_quality < 0.3` → `failed` (재시도 필요)

### 10.3 재시도 절차

```dart
class AntennaTuningPolicy {
  // Exponential backoff (factor 2x) over 3 retries.
  static const int tuningRetryDelay1Ms = 500;
  static const int tuningRetryDelay2Ms = 1000;
  static const int tuningRetryDelay3Ms = 2000;
  static const int tuningMaxRetries = 3;

  static const List<Duration> retryDelays = [
    Duration(milliseconds: tuningRetryDelay1Ms),
    Duration(milliseconds: tuningRetryDelay2Ms),
    Duration(milliseconds: tuningRetryDelay3Ms),
  ];
}
```

```
초기 튜닝 시도
  │
  ├─ 성공 (quality >= 0.6) → 정상 운영
  │
  └─ 실패 (quality < 0.3)
      │
      ├─ 재시도 1 (AntennaTuningPolicy.tuningRetryDelay1Ms 대기)
      ├─ 재시도 2 (AntennaTuningPolicy.tuningRetryDelay2Ms 대기)
      ├─ 재시도 3 (AntennaTuningPolicy.tuningRetryDelay3Ms 대기)
      │
      └─ AntennaTuningPolicy.tuningMaxRetries 모두 실패:
          ├─ AntennaStatusChanged { status: "failed" }
          ├─ CC 경고 배너 "안테나 튜닝 실패 — 물리 환경 점검 필요"
          └─ 운영자 수동 재튜닝 (M-01 Menu → RFID → Retune Antenna)
```

### 10.4 Degraded 모드

`0.3 ~ 0.6` 구간에서는 동작을 유지하되 경고 배너 표시. "일부 카드가 인식되지 않을 수 있습니다" 메시지 + 운영자에게 재튜닝 권장.

---

## 11. 펌웨어 버전 감지 (CCR-022)

### 11.1 지원 버전

| 칩 | 펌웨어 | 상태 |
|----|--------|------|
| ST25R3911B | v1.2.x | 지원 |
| ST25R3911B | v1.3.x | 지원 (권장) |
| ST25R3911B | v1.4.x | 지원 |
| ST25R3911B | v1.1.x | 경고 (Legacy) |
| ST25R3911B | v1.0.x | 미지원 |
| ST25R3916 | v2.0.x+ | 지원 (Phase 2) |

### 11.2 Handshake 동작

연결 시 펌웨어 버전을 자동 감지하여 `HandshakeComplete` 이벤트를 발행한다.

- **미지원 버전**: `HandshakeFailed` → 연결 거부, CC 경고 다이얼로그 "펌웨어 버전 X.X는 지원되지 않습니다. 업그레이드 필요"
- **Legacy 버전**: `HandshakeComplete { is_supported: true, warning_message: "Legacy 펌웨어 — 일부 기능 제한" }`, 연결 허용 + 경고 배너

---

## 12. 다중 리더 충돌 해결 (CCR-022)

### 12.1 Phase 1 (현재)

테이블당 1 리더 전제. 다중 리더는 미지원.

### 12.2 Phase 2+ (향후 확장)

- **좌석 그룹핑**: 리더 A = Seat 1~5, 리더 B = Seat 6~10
- **동일 카드 다중 감지**: `TimestampBasedResolver` — 먼저 감지한 쪽 우선
- **충돌 이벤트**: `MultiReaderConflict { uid, reader_ids: [string], resolved_by: string }`
- **Mock API**: `injectMultiReaderConflict(readers, uid)` 로 시뮬레이션

---

## 13. ST25R3911B → ST25R3916 마이그레이션 경로 (CCR-022)

후속 칩 ST25R3916은 개선된 감도·저전력·다중 안테나 지원을 제공한다. Phase 2에서 마이그레이션하며 본 계약은 다음을 보장한다:

- `IRfidReader` 인터페이스는 **변경 없음** — 구현체만 교체
- `HandshakeComplete.chip_id` 값으로 런타임 식별
- 양쪽 칩 모두 `v1.2+`/`v2.0+` 펌웨어에서 동일 이벤트 스트림 제공
- Phase 2 전환 시 `rfidModeProvider` DI만 업데이트
