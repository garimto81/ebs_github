---
title: OutputEvent Serialization
owner: team3
tier: contract
legacy-id: API-04.1
last-updated: 2026-05-08
last-synced: 2026-05-08  # Foundation §B.1 정합 marker (S8 audit 2026-05-08, D2 awareness)
reimplementability: PASS
reimplementability_checked: 2026-04-22
reimplementability_notes: "API-04.1 OutputEvent 직렬화 계약 완결. B-332 SSOT 선언 §4.1 추가 (2026-04-22, Foundation §6.4 Engine SSOT 전파)."
audit-notes:
  - "2026-05-08 S8 audit D2: 본 파일과 Overlay_Output_Events.md §6.0 간 OE-12~21 매핑 충돌 발견. publisher (output_event.dart) 실측 정본화 후속 작업 → B-356-oe-catalog-self-inconsistency.md"
confluence-page-id: 3818914230
confluence-parent-id: 3811836049
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818914230/EBS+OutputEvent+Serialization
---
# OutputEvent JSON 직렬화 계약 (API-04.1)

> ⚠️ **Audit notice (2026-05-08, S8 D2 [HIGH])**: 본 파일의 §섹션 OE 번호 매핑이 `Overlay_Output_Events.md §6.0` (publisher 실측 정본, 2026-04-15) 과 충돌함. 자세한 정합 작업은 [`B-356-oe-catalog-self-inconsistency.md`](../Backlog/B-356-oe-catalog-self-inconsistency.md) 참조. 본 PR(s8-engine 2026-05-08) 은 충돌 인지 marker 만 추가하며, 실제 재정렬은 별도 작업.

## 개요

`Overlay_Output_Events.md §6.0` 의 OutputEvent 21종을 **JSON 페이로드** 로 직렬화하는 정규 계약이다. team3 Game Engine이 발행하고 team4 CC/Overlay(또는 WebSocket 소비자)가 수신할 때 공통으로 따른다.

> **정본 코드**: `team3-engine/ebs_game_engine/lib/core/actions/output_event.dart` (sealed class)
>
> **in-process vs 네트워크**: CC 내부(같은 Flutter 프로세스)는 Dart 객체를 직접 전달할 수도 있으나, **상호운용·로깅·재생 일관성** 을 위해 본 JSON 스키마를 1차 계약으로 쓴다.

---

## 1. 엔벨로프 (Envelope)

모든 OutputEvent 는 공통 엔벨로프를 갖는다.

```json
{
  "type": "StateChanged",
  "oeCode": "OE-01",
  "version": 1,
  "timestamp": "2026-04-16T12:34:56.789Z",
  "sessionId": "abc123",
  "seqNo": 42,
  "payload": { ... }
}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `type` | string | sealed class 이름 (`StateChanged`, `ActionProcessed` 등). 대소문자 유지. **discriminator** |
| `oeCode` | string | `OE-01` ~ `OE-21` 식별자. `Overlay_Output_Events.md §6.0` 와 일치 |
| `version` | int | 스키마 버전. 현재 `1`. breaking change 시 증가 |
| `timestamp` | ISO-8601 string | 엔진 발행 시각 (UTC) |
| `sessionId` | string | Harness Session ID |
| `seqNo` | int | 세션 내 연속 시퀀스 (중복 탐지용) |
| `payload` | object | 이벤트별 필드 (아래 §2 참조) |

---

## 2. 이벤트별 페이로드 스키마 (21종)

### OE-01 StateChanged

```json
{
  "fromState": "PRE_FLOP",
  "toState": "FLOP"
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `fromState` | string | ✓ | 이전 Street enum 이름 |
| `toState` | string | ✓ | 이후 Street enum 이름 |

### OE-02 ActionProcessed

```json
{ "seatIndex": 3, "actionType": "raise", "amount": 200 }
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `seatIndex` | int | ✓ | 0-based seat 인덱스 |
| `actionType` | string | ✓ | `fold` / `check` / `call` / `bet` / `raise` / `allin` |
| `amount` | int? | | Fold/Check 는 null, 나머지는 확정 금액 |

### OE-03 / OE-19 PotUpdated

```json
{ "mainPot": 450, "sidePots": [120, 80], "displayToPlayers": true }
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `mainPot` | int | ✓ | 메인 팟 금액 |
| `sidePots` | int[] | ✓ | 사이드 팟 배열 (빈 배열 허용) |
| `displayToPlayers` | bool | ✓ | WSOP Rule 101 — Spread Limit 시 false (플레이어에게 숨김) |

### OE-04 BoardUpdated

```json
{ "cardCount": 3 }
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `cardCount` | int | ✓ | 보드 카드 누적 장수 (0~5) |

### OE-05 ActionOnChanged

```json
{ "seatIndex": 4 }
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `seatIndex` | int | ✓ | 다음 액션 seat 인덱스 |

### OE-06 WinnerDetermined

```json
{ "awards": { "3": 500, "5": 120 } }
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `awards` | map<string,int> | ✓ | seatIndex(string 키) → 수령 금액 |

### OE-07 Rejected

```json
{ "reason": "Raise below minimum (Rule 96)" }
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `reason` | string | ✓ | 사람이 읽을 수 있는 거부 사유 |

### OE-08 UndoApplied

```json
{ "stepsUndone": 1 }
```

### OE-09 HandCompleted

```json
{ "handNumber": 42 }
```

### OE-10 EquityUpdated

```json
{ "equities": { "0": 0.68, "3": 0.21, "5": 0.11 } }
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `equities` | map<string,double> | ✓ | seatIndex → 승률 (0.0~1.0) |

### OE CardRevealed

```json
{ "seatIndex": 3, "cardCodes": ["As", "Kh"], "visibility": "broadcast" }
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `seatIndex` | int | ✓ | 대상 seat |
| `cardCodes` | string[] | ✓ | 카드 코드 (예: `As` = Ace of Spades) |
| `visibility` | string | ✓ | `all` / `broadcast` / `none` |

### OE CardMismatchDetected

```json
{ "expected": "Ah", "detected": "As" }
```

### OE SevenDeuceBonusAwarded

```json
{ "seatIndex": 3, "bonusAmount": 50 }
```

### OE-11 HandTabled

```json
{ "seatIndex": 3, "cards": ["As", "Kh"] }
```

> WSOP Rule 71 — 플레이어가 자발적 공개.

### OE-12 HandRetrieved

```json
{ "seatIndex": 3, "managerRationale": "Rule 110 review" }
```

### OE-13 HandKilled

```json
{ "seatIndex": 3, "managerRationale": "Premature muck" }
```

### OE-14 MuckRetrieved

```json
{ "seatIndex": 3, "cards": ["As", "Kh"], "rationale": "Rule 109 re-evaluation" }
```

### OE-15 FlopRecovered

```json
{
  "originalCards": ["As", "Kh", "Qd", "Jc"],
  "newFlop": ["7h", "8d", "9c"],
  "reservedBurn": "Ts"
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `originalCards` | string[] | ✓ | 오염된 4-card flop (WSOP Rule 89) |
| `newFlop` | string[] | ✓ | 재추출된 3-card flop |
| `reservedBurn` | string? | | 예약된 번카드 (옵션) |

### OE-16 DeckIntegrityWarning

```json
{ "failureCount": 3, "suggestedAction": "deck_change" }
```

### OE-17 DeckChangeStarted

```json
{ "reason": "Rule 78 integrity check", "requestedBy": "floor" }
```

### OE-18 GameTransitioned

```json
{ "fromGame": "nlh", "toGame": "plh", "buttonFrozen": false }
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `fromGame` | string | ✓ | 이전 variant 이름 |
| `toGame` | string | ✓ | 이후 variant 이름 |
| `buttonFrozen` | bool | ✓ | HORSE rotation 중 버튼 고정 여부 |

---

## 3. 직렬화·역직렬화 규칙

### Dart (team3 / team4 공통)

```dart
// Encoding (team3 harness 발행):
Map<String, dynamic> outputEventToJson(OutputEvent ev, {
  required String sessionId,
  required int seqNo,
}) => {
  'type': ev.runtimeType.toString(),
  'oeCode': _oeCodeOf(ev),     // OE-01 ~ OE-21
  'version': 1,
  'timestamp': DateTime.now().toUtc().toIso8601String(),
  'sessionId': sessionId,
  'seqNo': seqNo,
  'payload': _payloadOf(ev),
};

// Decoding (team4 소비):
OutputEvent outputEventFromJson(Map<String, dynamic> json) {
  final type = json['type'] as String;
  final payload = json['payload'] as Map<String, dynamic>;
  return switch (type) {
    'StateChanged' => StateChanged(
        fromState: payload['fromState'] as String,
        toState: payload['toState'] as String),
    'ActionProcessed' => ActionProcessed(
        seatIndex: payload['seatIndex'] as int,
        actionType: payload['actionType'] as String,
        amount: payload['amount'] as int?),
    // ... 나머지 19개
    _ => throw FormatException('Unknown OutputEvent type: $type'),
  };
}
```

### 규칙

1. **discriminator 우선**: 소비자는 `type` 필드로 분기한다. `oeCode` 는 보조 (사람 읽기용).
2. **unknown type 무시 금지**: 모르는 `type` 을 받으면 버리지 말고 로그 + Rejected 처리.
3. **누락 필드**: 필수 필드 누락 시 역직렬화 예외. 선택 필드는 null/기본값.
4. **Map 키 타입**: JSON Object 키는 항상 string. `seatIndex: int` map 은 `{"0": 500}` 로 직렬화되며 소비자가 `int.parse` 로 복원.
5. **카드 코드**: 랭크(`2-9,T,J,Q,K,A`) + 수트(`s,h,d,c`). 예: `As`, `Td`, `2c`.
6. **Street enum**: `setupHand / preflop / flop / turn / river / showdown / runItMultiple` (카멜케이스 유지).

### 버전 관리

- `version: 1` 부터 시작. 필드 추가만 하는 하위호환 변경은 version 유지.
- 필드 제거·의미 변경은 `version: 2` 로 bump. 엔진이 클라이언트 버전 네고(negotiation) 로 호환성 관리.

---

## 4. 경계 및 소비 모델

- **발행 주체**: team3 Engine.applyFull() → ReduceResult.outputEvents[]
- **Harness 서비스**: 각 REST 응답(`Session.toJson()`) 에 `outputEvents[]` 배열 포함. 또는 향후 WebSocket stream 으로 점진 푸시.
- **소비 주체**: team4 OutputEventBuffer (`Overlay_Output_Events.md §3.6`). Security Delay 적용 여부는 소비자 결정.
- **로깅**: `sessionId + seqNo` 로 중복·순서 검증. Replay/Debug 시 동일 seqNo 재생성 보장 (Engine 결정론성).

### 4.1 SSOT 선언 (B-332, Foundation §6.3 §1.1.1 / §6.4)

- **Engine OutputEvent 가 게임 상태 변경의 최종 정본이다.** Engine.applyFull() → ReduceResult 가 발행한 시퀀스가 SSOT.
- CC 가 BO WS (`/ws/cc`) 로 수신하는 `ActionAck` · `outputEventBroadcast` 등은 **audit 참고값** — BO 가 Engine 발행본을 재전파하는 것이며, 직접 소비 우선순위가 아니다. BO 실패 시 warn-only.
- 동일 `correlation_id` 로 BO / Engine 병행 dispatch 한 경우, Engine 응답의 `outputEvents[]` 만 Overlay 렌더 트리거에 사용한다.
- 정본 근거: Foundation.md §6.3 §1.1.1 (시나리오 A/B) · §6.4 (Engine SSOT).

---

## 5. 연관 문서

- `Overlay_Output_Events.md` (API-04) — OutputEvent 카탈로그 §6.0, Security Delay §3
- `Harness_REST_API.md` (API-04.2) — Session JSON 에 포함되는 outputEvents 배열
- `OutputEventBuffer_Boundary.md` (API-04.3) — team3/team4 구현 경계
- 정본 코드: `team3-engine/ebs_game_engine/lib/core/actions/output_event.dart`
