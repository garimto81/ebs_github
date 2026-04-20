---
title: OutputEventBuffer 구현 경계
owner: team3
tier: contract
legacy-id: API-04.3
last-updated: 2026-04-16
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "API-04.3 버퍼 경계 계약 완결"
---
# OutputEventBuffer 구현 경계 (API-04.3)

## 개요

`Overlay_Output_Events.md §3.6` 이 **"team4 가 OutputEventBuffer 를 구현한다"** 고 명시했으나, **team3 Harness 와의 경계·인터페이스 시그니처가 불명확**한 상태였다. 본 문서는 두 팀의 책임을 정확히 분할한다.

> **핵심 원칙**: team3 엔진은 **buffer-less emitter**. Security Delay 는 **team4 소비자가 적용**. 같은 Flutter 프로세스 안이면 Dart Stream, 프로세스 분리면 WebSocket 경유.

---

## 1. 책임 분할 매트릭스

| 책임 | team3 Engine | team3 Harness | team4 OutputEventBuffer |
|------|:-----------:|:-------------:|:-----------------------:|
| OutputEvent 생성 (Dart 객체) | ✓ | | |
| JSON 직렬화 | | ✓ (`API-04.1` 계약) | |
| HTTP REST 노출 | | ✓ (`API-04.2`) | |
| WebSocket 푸시 (미래) | | ✓ (`API-05`) | |
| 이벤트 순서 보장 (seqNo) | ✓ | ✓ | |
| **Security Delay 버퍼링** | | | ✓ |
| Backstage / Broadcast 분기 | | | ✓ |
| Rive 애니메이션 트리거 | | | ✓ |
| Flutter 위젯 rebuild | | | ✓ |

---

## 2. Dart Stream 인터페이스 (in-process)

CC + Overlay + Engine 이 같은 Flutter 앱 내에서 실행되는 경우 (Phase 1 기본):

### team3 Engine 측

```dart
// ebs_game_engine/lib/engine.dart
class Engine {
  /// 엔진은 단일 적용마다 ReduceResult 를 반환.
  /// outputEvents 는 Dart 객체 리스트 (buffer 없음).
  ReduceResult applyFull(GameState state, Event event) {
    // ... 내부 처리
    return ReduceResult(
      newState: ...,
      outputEvents: [StateChanged(...), ActionProcessed(...)],
    );
  }
}
```

### team3 Harness 측 (Stream adapter 예시)

```dart
// ebs_game_engine/lib/harness/session.dart
class Session {
  final _controller = StreamController<OutputEvent>.broadcast();
  Stream<OutputEvent> get outputEventStream => _controller.stream;

  void addEvent(Event event) {
    final result = engine.applyFull(currentState, event);
    _currentState = result.newState;
    for (final oe in result.outputEvents) {
      _controller.add(oe);   // buffer 없음, 즉시 방출
    }
  }
}
```

### team4 OutputEventBuffer 측

```dart
// team4-cc/lib/overlay/output_event_buffer.dart
class OutputEventBuffer {
  final Duration delay;
  final Queue<DelayedEvent> _queue = Queue();
  final _backstage = StreamController<OutputEvent>.broadcast();
  final _broadcast = StreamController<OutputEvent>.broadcast();

  OutputEventBuffer({required this.delay, required Stream<OutputEvent> source}) {
    source.listen((event) {
      _backstage.add(event);     // 즉시 Backstage 송출
      _queue.add(DelayedEvent(event, DateTime.now().add(delay)));
      _scheduleRelease();
    });
  }

  Stream<OutputEvent> get backstageStream => _backstage.stream;
  Stream<OutputEvent> get broadcastStream => _broadcast.stream;

  // 타이머 기반 방출 (생략)
}
```

---

## 3. WebSocket 경로 (프로세스 분리 시)

Engine Harness 가 별도 프로세스·서버로 동작하는 경우:

```
team3 Engine (Harness port 8080)
    │
    ▼ REST pull 또는 WebSocket push (API-05)
    │
    ▼ JSON envelope (API-04.1)
    │
team4 CC Flutter 앱
    │ WebSocket client 가 JSON → OutputEvent 역직렬화
    ▼
OutputEventBuffer (같은 Dart Stream 인터페이스)
    │
    ├─ backstageStream → 운영진 Overlay
    └─ broadcastStream → 방송 Overlay (Security Delay 후)
```

**WebSocket 프레임 규약**: `API-05 WebSocket_Events.md` 와 envelope 일치. OutputEvent 는 `payload.kind: "OutputEvent"` 서브타입으로 포함.

---

## 4. 계약적 보장

### team3 보장 사항
- OutputEvent 순서는 엔진 적용 순서와 동일 (FIFO)
- `sessionId + seqNo` 는 세션 전역 유일
- 동일 Event 입력 → 동일 OutputEvent 시퀀스 (결정론)
- 엔진·harness 는 **buffer 안 가짐**. 재시도·지연 책임 없음

### team4 보장 사항
- Backstage 스트림은 **즉시** 송출 (latency ≤ 16ms, 1 frame)
- Broadcast 스트림은 `delay_seconds` 만큼 정확히 지연 (±1 frame)
- delay_seconds 변경 시 현 큐의 타임스탬프는 **기존 값 유지**, 새 이벤트만 신규 delay 적용 (API-04 §3.2 참조)
- 앱 종료 시 broadcast queue flush 정책 명시 필수 (drop 또는 flush-all)

### 공통 금지 사항
- team3 harness 가 delay 로직 포함 금지 (경계 위반)
- team4 buffer 가 OutputEvent 내용을 수정 금지 (read-only 통과)

---

## 5. 성능 예산

| 구간 | SLA |
|------|:---:|
| Engine.applyFull() 실행 시간 | ≤ 5ms (결정론 계산) |
| Harness REST 응답 왕복 | ≤ 20ms (로컬) / ≤ 100ms (LAN) |
| OutputEvent → Backstage 송출 | ≤ 16ms (1 frame @ 60fps) |
| Broadcast delay 드리프트 | ≤ 16ms |
| A/V Sync 드리프트 (lip-sync) | ≤ 16ms (BS-07-05 §8.1 참조) |

위 값 초과 시 성능 버그로 간주, 관련 팀 Backlog 등재.

---

## 6. 미해결 항목

- [ ] **WebSocket 푸시 vs REST pull**: 현재 REST 전용. streaming 전환 시기 결정 필요 (API-05 로드맵 협의)
- [ ] **Back-pressure**: buffer 오버플로 (120초 × 60fps = 7,200 이벤트 상한) 시 정책. API-04 §3.6 에 "메모리 증가" 만 언급. **drop-oldest 권장**, team4 결정
- [ ] **Replay mode**: scenario 재생 시 실시간 지연 적용 여부. 테스트 시 즉시 송출이 편함

---

## 7. 연관 문서

- `Overlay_Output_Events.md §3` — Security Delay 개요
- `Overlay_Output_Events.md §3.6` — OutputEventBuffer 소유권 선언 (본 문서 상세화)
- `OutputEvent_Serialization.md` (API-04.1) — JSON 스키마
- `Harness_REST_API.md` (API-04.2) — REST endpoint
- `team4-cc/` `BS-07-05 Audio.md §8.1` — A/V Sync
- 정본 코드 (team3): `ebs_game_engine/lib/engine.dart`, `lib/harness/session.dart`
- 예상 코드 (team4): `team4-cc/lib/overlay/output_event_buffer.dart` (미구현)
