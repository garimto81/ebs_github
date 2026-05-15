---
title: CR-team4-20260410-api03-hal-lifecycle
owner: conductor
tier: internal
last-updated: 2026-04-15
legacy-id: CCR-DRAFT-team4-20260410-api03-hal-lifecycle
confluence-page-id: 3832807673
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3832807673/Lifecycle
---

# CCR-DRAFT: API-03 RFID HAL 에러 복구 및 생명주기 시나리오 보강

- **제안팀**: team4
- **제안일**: 2026-04-10
- **영향팀**: [team2]
- **변경 대상 파일**: contracts/api/API-03-rfid-hal-interface.md
- **변경 유형**: modify
- **변경 근거**: 현재 API-03는 IRfidReader 인터페이스, 이벤트 카탈로그, Mock HAL 전용 API까지 프로덕션 준비 수준으로 정의되어 있으나(상세도 ⭐⭐⭐⭐⭐), **리더 생명주기 중 장애 복구 시나리오**가 빈약하다. 특히 다음 항목이 필요: (1) 시리얼 UART 연결 끊김 감지 및 자동 재연결 정책, (2) 안테나 튜닝 실패 시 재시도 절차, (3) ST25R3911B → ST25R3916 마이그레이션 경로 참조, (4) 펌웨어 버전 mismatch 감지, (5) 동시 다중 리더 시 충돌 해결. 이는 라이브 방송 환경에서 RFID 리더 장애가 **즉시 방송 중단**으로 이어질 수 있기 때문에 CRITICAL한 계약 공백이다.

## 변경 요약

API-03에 5개 섹션 추가:

1. **§시리얼 UART 연결 생명주기** — 연결/끊김/재연결 FSM
2. **§안테나 튜닝 재시도** — 튜닝 실패 시 복구
3. **§펌웨어 버전 감지** — 지원 버전 명시, mismatch 시 동작
4. **§다중 리더 충돌 해결** — 향후 확장 대비 (현재는 1 리더 전제)
5. **§ST25R3916 마이그레이션 경로** — 후속 칩 지원 정책

## 변경 내용

### 1. API-03 §시리얼 UART 연결 생명주기 (신규 섹션)

```markdown
## 시리얼 UART 연결 생명주기

### 연결 FSM

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

### 상태 정의

| 상태 | 설명 |
|------|------|
| DISCONNECTED | 초기 상태 또는 명시적 close() 후 |
| CONNECTING | open() 호출 중, 시리얼 포트 열기 시도 |
| CONNECTED | 정상 운영 상태, 이벤트 수신/명령 송신 가능 |
| CONNECTION_FAILED | 연결 실패 (포트 없음, 권한 거부, handshake 실패) |
| RECONNECTING | 자동 재연결 시도 중 |

### 이벤트

IRfidReader 인터페이스에 다음 이벤트 추가:

- `ConnectionStatusChanged { from: ReaderStatus, to: ReaderStatus, reason?: string }`
- `HandshakeComplete { firmware_version: string, chip_id: string }`
- `HandshakeFailed { error_code: int, message: string }`

### 재연결 정책

```dart
class ReaderReconnectPolicy {
  // 동일 정책을 WSOP Fatima.app SignalR과 통일 (BS-05-00 §BO 복구 참조)
  static const List<Duration> retryDelays = [
    Duration.zero,                    // 즉시
    Duration(seconds: 5),             // 5s 후
    Duration(seconds: 10),            // 이후 10s × 100회
    // ... 최종 null (중단)
  ];
  
  static const int maxRetries = 101;
}
```

### 핸드 진행 중 연결 끊김

핸드 진행 중(HandFSM != IDLE) 리더가 끊기면:

1. CC가 AT-01에 경고 배너 "RFID 리더 끊김 — 수동 입력 모드"
2. 자동으로 AT-03 Card Selector 진입 가능 상태 (수동 입력 폴백)
3. 재연결 시도 백그라운드 지속
4. 재연결 성공 시: 배너 해제, RFID 감지 재개
5. 핸드 종료까지 재연결 실패 시: 수동 입력으로 핸드 완료

### Mock 모드에서의 시뮬레이션

MockRfidReader에 다음 API 추가:

- `injectDisconnect()` — 강제 연결 끊김 시뮬레이션
- `injectReconnect()` — 재연결 시뮬레이션
- `simulateHandshakeFailure(errorCode)` — 핸드쉐이크 실패 주입
```

### 2. API-03 §안테나 튜닝 재시도 (신규 섹션)

```markdown
## 안테나 튜닝 재시도

### 배경

ST25R3911B(및 후속 ST25R3916)는 안테나 매칭 임피던스를 자동 튜닝한다.
금속 포커 테이블, 주변 금속 베팅 토큰 등 환경 변수로 튜닝 실패 가능.

### 튜닝 실패 감지

- `AntennaStatusChanged { tuning_quality: float, status: "tuned" | "degraded" | "failed" }`
- `tuning_quality` < 0.6이면 `degraded` (경고)
- `tuning_quality` < 0.3이면 `failed` (재시도 필요)

### 재시도 절차

```
초기 튜닝 시도
  │
  ├─ 성공 (quality >= 0.6): 정상 운영
  │
  └─ 실패 (quality < 0.3)
      │
      ├─ 재시도 1 (500ms 대기 후 재튜닝)
      ├─ 재시도 2 (1s 대기)
      ├─ 재시도 3 (2s 대기)
      │
      └─ 3회 모두 실패:
          ├─ AntennaStatusChanged { status: "failed" }
          ├─ CC 경고 배너 "안테나 튜닝 실패 — 물리 환경 점검 필요"
          └─ 운영자가 수동 재튜닝 명령 (M-01 Menu → RFID → Retune Antenna)
```

### Degraded 모드

`tuning_quality` 0.3~0.6 구간:
- 동작은 유지하되 경고 배너 표시
- 카드 감지 성공률 저하 경고 ("일부 카드가 인식되지 않을 수 있습니다")
- 운영자 재튜닝 권장
```

### 3. API-03 §펌웨어 버전 감지 (신규 섹션)

```markdown
## 펌웨어 버전 감지

### 지원 버전

| 칩 | 펌웨어 | 지원 상태 |
|----|--------|----------|
| ST25R3911B | v1.2.x | ✅ 지원 |
| ST25R3911B | v1.3.x | ✅ 지원 (권장) |
| ST25R3911B | v1.4.x | ✅ 지원 |
| ST25R3911B | v1.1.x | ⚠️ 경고 (Legacy) |
| ST25R3911B | v1.0.x | ❌ 미지원 |
| ST25R3916 | v2.0.x+ | ✅ 지원 (Phase 2) |

### Handshake 시 버전 확인

```dart
abstract class IRfidReader {
  // 연결 시 펌웨어 버전을 자동 감지하여 HandshakeComplete 이벤트로 발행
  Stream<HandshakeComplete> get onHandshakeComplete;
}

class HandshakeComplete {
  final String firmwareVersion;  // e.g., "1.3.2"
  final String chipId;            // e.g., "ST25R3911B"
  final bool isSupported;         // 지원 버전인지
  final bool isRecommended;       // 권장 버전인지
  final String? warningMessage;   // Legacy/unsupported 경고
}
```

### Mismatch 시 동작

- **미지원 버전 감지**: 
  - `HandshakeFailed` 이벤트 발행
  - CC가 경고 다이얼로그 "펌웨어 버전 X.X는 지원되지 않습니다. 업그레이드 필요"
  - 연결 거부
- **Legacy 버전 감지**:
  - `HandshakeComplete { isSupported: true, warningMessage: "Legacy 펌웨어 — 일부 기능 제한 가능" }`
  - 연결은 허용, 경고 배너 표시
```

### 4. API-03 §다중 리더 충돌 해결 (신규 섹션)

```markdown
## 다중 리더 충돌 해결

### 현재 (Phase 1)

테이블당 1 리더 전제. 다중 리더는 미지원.

### 향후 (Phase 2+)

동일 테이블에서 2개 이상의 리더 사용 시:

- **좌석 그룹핑**: 리더 A가 Seat 1~5 담당, 리더 B가 Seat 6~10 담당
- **동일 카드 다중 감지**: 같은 카드 UID가 두 리더에서 동시 감지되면 `TimestampBasedResolver`가 먼저 감지한 쪽 우선
- **충돌 이벤트**: `MultiReaderConflict { uid, reader_ids: [string], resolved_by: string }`

### Mock 모드

- `MockRfidReaderPool` 클래스로 다중 리더 시뮬레이션 (Phase 2)
- 현재는 단일 MockRfidReader만 지원
```

### 5. API-03 §ST25R3916 마이그레이션 경로 (신규 섹션)

```markdown
## ST25R3916 마이그레이션 경로

### 배경

ST25R3911B는 2024년 기준 여전히 널리 사용되는 검증된 칩이나,
ST25R3916(후속 모델, 2024년 출시)이 다음을 개선:

- EMC 성능 향상
- 저전력 소비 (배터리 구동 리더 가능)
- 안테나 튜닝 알고리즘 개선

### 마이그레이션 전략

IRfidReader 인터페이스는 **칩 독립적(chip-agnostic)**으로 설계됨:

- ST25R3911BReader (현재 구현)
- ST25R3916Reader (Phase 2 추가)
- 동일 IRfidReader 구현

### 전환 방법

1. ST25R3916 펌웨어 작성 (ESP32 + ST 공식 라이브러리)
2. Dart 측 `ST25R3916Reader` 클래스 구현 (SPI 통신 프로토콜 차이 반영)
3. Riverpod DI Provider에서 칩 자동 감지 후 적절한 구현체 주입:

```dart
final rfidReaderProvider = Provider<IRfidReader>((ref) {
  final config = ref.watch(hardwareConfigProvider);
  switch (config.chipType) {
    case ChipType.st25r3911b:
      return ST25R3911BReader(config.serialPort);
    case ChipType.st25r3916:
      return ST25R3916Reader(config.serialPort);
    case ChipType.mock:
      return MockRfidReader();
  }
});
```

### 호환성 정책

- ST25R3916 도입 시에도 ST25R3911B를 계속 지원 (최소 1년)
- 매장별로 다른 칩 운영 가능 (설정 기반)
- 계약 레벨에서는 이 전환이 **완전히 투명** (CC/Overlay 코드 변경 없음)
```

## Diff 초안

```diff
 # API-03-rfid-hal-interface.md

 ## 기존 섹션들...

+## 시리얼 UART 연결 생명주기
+
+### 연결 FSM
+DISCONNECTED → CONNECTING → CONNECTED
+                ↓              ↓
+            CONNECTION_FAILED  RECONNECTING
+
+### 재연결 정책
+- 0ms → 5s → 10s × 100회 → 중단 (BS-05-00 §BO 복구와 동일)
+
+### 핸드 진행 중 끊김 대응
+- CC 경고 배너 + 자동 AT-03 Card Selector 진입 가능

+## 안테나 튜닝 재시도
+
+### 튜닝 품질 단계
+- quality >= 0.6: 정상
+- 0.3 <= quality < 0.6: degraded (경고)
+- quality < 0.3: failed (재시도)
+
+### 재시도 절차: 500ms → 1s → 2s (3회)

+## 펌웨어 버전 감지
+
+| 칩 | 펌웨어 | 상태 |
+|----|--------|------|
+| ST25R3911B | v1.3.x | 권장 |
+| ST25R3911B | v1.0.x | 미지원 |
+| ST25R3916 | v2.0.x+ | Phase 2 |
+
+Handshake 시 HandshakeComplete/HandshakeFailed 이벤트로 전달.

+## 다중 리더 충돌 해결
+
+Phase 1: 1 리더 전제. Phase 2+에서 다중 리더 + TimestampBasedResolver.

+## ST25R3916 마이그레이션 경로
+
+IRfidReader 인터페이스는 chip-agnostic. Riverpod DI로 구현체 교체.
+ST25R3911B와 ST25R3916 병행 지원 (최소 1년).
```

## 영향 분석

### Team 2 (Backend)
- **영향**: 
  - 최소 영향. API-03은 Team 4가 publish하는 계약이므로 Team 2는 소비만 함
  - 단, `ReaderStatusChanged` WebSocket 이벤트가 CC → BO → Lobby로 전파되는지 API-05에 반영 필요 (별도 Cross-reference CCR 가능)
- **예상 리뷰 시간**: 0.5시간

### Team 4 (self)
- **영향**: 
  - `team4-cc/src/lib/features/rfid/services/reader_lifecycle.dart` 구현
  - 연결 FSM + 재연결 백오프 구현
  - 펌웨어 버전 감지 및 경고 UI (AT-01 배너)
  - 안테나 튜닝 재시도 로직
  - Mock HAL에 장애 주입 API 확장
- **예상 작업 시간**:
  - 연결 FSM: 6시간
  - 재연결 정책: 4시간
  - 펌웨어/튜닝 재시도: 6시간
  - Mock 장애 주입: 4시간
  - 통합 테스트: 6시간
  - 총 26시간

### 마이그레이션
- 없음 (계약 보강)

## 대안 검토

### Option 1: 현재 API-03 유지 (장애 복구 미정의)
- **단점**: 
  - 라이브 방송 중 리더 장애 시 CC 동작 불명확 → 구현자별 상이
  - Mock/Real 모드 장애 시나리오 테스트 불가
  - PokerGFX 대비 안정성 열세
- **채택**: ❌

### Option 2: API-03에 5개 섹션 추가 (본 제안)
- **장점**: 
  - 라이브 방송 안정성 보장
  - Mock 모드에서 장애 시나리오 E2E 검증 가능
  - ST25R3916 미래 전환 경로 문서화
- **단점**: API-03 분량 증가
- **채택**: ✅

### Option 3: 별도 API-03-lifecycle.md 신설
- **장점**: 파일 분리로 가독성
- **단점**: 
  - API-03 (RFID HAL 단일 계약) 분할 → SSOT 약화
  - Cross-reference 유지 비용
- **채택**: ❌

## 검증 방법

### 1. 연결 FSM 단위 테스트
- [ ] MockRfidReader로 DISCONNECTED → CONNECTING → CONNECTED 정상 경로
- [ ] handshake 실패 주입 → CONNECTION_FAILED → 재시도 → RECONNECTING 확인
- [ ] close() → DISCONNECTED 전이

### 2. 재연결 백오프
- [ ] 첫 재시도 즉시 (0ms)
- [ ] 두 번째 5s 대기
- [ ] 이후 10s 간격 × 최대 100회
- [ ] 101회 후 중단 및 에러

### 3. 핸드 진행 중 장애
- [ ] PRE_FLOP 상태에서 injectDisconnect() 호출
- [ ] CC AT-01에 경고 배너 표시 확인
- [ ] 수동 카드 입력(AT-03)으로 폴백 가능 확인
- [ ] injectReconnect() 호출 → 배너 해제 + RFID 감지 재개

### 4. 안테나 튜닝
- [ ] quality 0.7 → 정상 동작
- [ ] quality 0.5 → degraded 경고 배너
- [ ] quality 0.2 → 3회 재시도 후 failed → 수동 재튜닝 요구

### 5. 펌웨어 버전
- [ ] v1.3.2 → 정상 연결 + "권장 버전" 표시
- [ ] v1.0.5 → 연결 거부 + 업그레이드 경고
- [ ] v1.1.0 → Legacy 경고 + 제한 동작

## 승인 요청

- [ ] Conductor 승인
- [ ] Team 2 기술 검토 (ReaderStatusChanged WebSocket 전파)
- [ ] Team 4 기술 검토 (FSM 구현, Mock 장애 주입)
