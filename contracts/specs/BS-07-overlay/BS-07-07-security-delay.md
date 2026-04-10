# BS-07-07 Security Delay (홀카드 공개 지연)

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 신규 작성 | 이중 출력(Backstage/Broadcast) + Delay Buffer + 설정/예외 (CCR-036) |

---

## 개요

라이브 포커 방송에서 실시간으로 홀카드가 공개되면 시청자 또는 공모자가 휴대폰/신호로 플레이어에게 카드 정보를 전달할 수 있다. 이를 방지하기 위해 방송은 **N초 지연**하여 송출되어야 한다. 이는 WSOP, EPT, WPT 등 메이저 대회의 필수 요구사항이다.

> **참조**: `API-04-overlay-output`, `BS-07-06-layer-boundary §1.1 Action Badge`.

---

## 1. 원리

```
게임 이벤트 발생 (t=0)
    │
    ├─ Overlay 내부 Buffer 저장 (delay_sec 동안 보관)
    │
    ├─ Backstage Output (즉시)
    │   └─ 운영진만 보는 화면 (CC, Director)
    │
    └─ Broadcast Output (t = delay_sec 후)
        └─ 시청자용 방송 화면
```

---

## 2. 이중 출력 (Dual Output)

EBS Overlay는 **두 가지 출력 스트림**을 동시에 제공한다:

| Stream | 용도 | NDI 채널 | Delay |
|--------|------|:--------:|:-----:|
| **Backstage** | 운영진 / 감독용 | 1 | **없음** (즉시) |
| **Broadcast** | 시청자용 방송 | 2 | `delay_seconds` 만큼 지연 |

두 스트림은 **동일 내용**이지만 시간차로 분리된다. HDMI/NDI 출력 설정은 `BS-03-01-outputs` 참조.

---

## 3. 지연 설정

| 파라미터 | 기본값 | 범위 | 설정 위치 |
|---------|:------:|:----:|-----------|
| `delay_enabled` | `false` | `true/false` | `BS-03-01-outputs §Security Delay` |
| `delay_seconds` | `30` | 0 ~ 600 (10분) | `BS-03-01-outputs §Security Delay` |
| `delay_holecards_only` | `false` | `true/false` | `BS-03-01-outputs §Security Delay` |

- **운영 기본**: 30초 (WSOP 대회 표준)
- `delay_holecards_only == true`: 홀카드만 지연, 다른 요소(액션 배지, Pot 등)는 즉시 송출

---

## 4. Buffer 아키텍처

### 4.1 OutputEventBuffer

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

  void _scheduleRelease() {
    // 가장 가까운 releaseAt 시점에 타이머 설정
    // 타이머 만료 시 Broadcast Output으로 이벤트 발행
  }
}
```

### 4.2 이벤트 타입별 처리

| OutputEvent | Backstage | Broadcast |
|-------------|:---------:|:---------:|
| `CardDealt` (hole) | 즉시 | delay 후 |
| `CardDealt` (board) | 즉시 | delay 후 (`delay_holecards_only == false` 시) |
| `ActionPerformed` | 즉시 | delay 후 (`delay_holecards_only == false` 시) |
| `EquityUpdated` | 즉시 | delay 후 |
| `WinnerRevealed` | 즉시 | delay 후 |
| `ConfigChanged` | 즉시 | **즉시** (설정 변경은 양쪽 동일) |
| `OverlayControl` (운영자 UI 명령) | 즉시 | 즉시 |

---

## 5. 예외 처리

### 5.1 `delay_enabled == false`

Buffer를 우회하고 Broadcast Output이 Backstage와 동일하게 즉시 송출. 테스트·리허설용.

### 5.2 Delay 변경 (중간 조정)

방송 중 `delay_seconds`를 변경하면:

- **증가** (예: 30→60s): 이미 buffer에 있는 이벤트는 **원래 releaseAt** 유지. 새 이벤트부터 60s 적용.
- **감소** (예: 60→30s): buffer 이벤트들의 `releaseAt`을 즉시 재계산. 이미 30s 이상 지난 이벤트는 즉시 release.

### 5.3 에러 / 크래시

Buffer가 실행 중 크래시하면:
- 모든 pending 이벤트는 손실됨
- Backstage Stream은 영향 없음 (별도 경로)
- Broadcast Stream은 복구 후 buffer 재시작 — 과거 이벤트 복원 안 함

### 5.4 방송 종료 / 핸드 Reset

`delay_seconds` 경과 전에 방송 종료하면:
- 옵션 A (기본): Buffer flush — 모든 pending 이벤트 즉시 release
- 옵션 B: Buffer discard — pending 이벤트 폐기
- `BS-03-01-outputs §Security Delay` 에서 선택

---

## 6. 운영 경고

운영자가 Backstage에서 본 것과 시청자가 본 것 사이에 **delay_seconds 간격**이 있으므로:

- 운영자가 "카드가 공개됐다"고 판단한 시점부터 시청자는 `delay_seconds` 후에 동일 화면을 본다
- 운영자는 **시청자 관점 타임라인**을 별도 모니터링해야 한다
- CC UI에 "Broadcast lag: 30s" 표시 (`M-01 Toolbar` 우측)

---

## 7. 연관 문서

- `API-04-overlay-output` — OutputEvent buffer 흐름 (§Security Delay 참조)
- `BS-03-01-outputs §Security Delay` — 설정 UI
- `BS-07-06-layer-boundary` — Layer 1 OutputEvent 종류
- `BS-07-00-overview §5` — 출력 채널 개요
