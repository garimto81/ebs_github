---
title: CR-team4-20260410-bs07-security-delay
owner: conductor
tier: internal
last-updated: 2026-04-15
legacy-id: CCR-DRAFT-team4-20260410-bs07-security-delay
---

# CCR-DRAFT: BS-07 Security Delay (홀카드 공개 지연) 명세

- **제안팀**: team4
- **제안일**: 2026-04-10
- **영향팀**: [team1, team2]
- **변경 대상 파일**: contracts/specs/BS-07-overlay/BS-07-07-security-delay.md, contracts/api/`Overlay_Output_Events.md` (legacy-id: API-04)
- **변경 유형**: add
- **변경 근거**: 라이브 포커 방송에서 **Security Delay**(방송 지연)는 치트 방지를 위한 필수 기능이다. 시청자(또는 공모자)가 실시간 방송을 보면서 플레이어와 통신하여 카드 정보를 전달할 수 없도록, 홀카드/액션을 **N초 지연 후** 방송에 표시한다. WSOP 원본(`EBS UI Design.md` §Delay)과 PokerGFX는 30~60초 지연을 기본으로 운영한다. 현재 API-04 Overlay Output에 출력 파이프라인이 정의되어 있지만 Security Delay 메커니즘이 없어 EBS가 프로덕션 방송에 사용될 수 없다. 본 CCR은 이 공백을 메운다.

## 변경 요약

1. `BS-07-07-security-delay.md` 신규: Security Delay 원리, 버퍼 아키텍처, 지연 설정, 예외 처리
2. `Overlay_Output_Events.md §Security Delay` (legacy-id: API-04) 섹션 추가: OutputEvent가 delay buffer를 거치는 흐름

## 변경 내용

### 1. BS-07-07-security-delay.md (신규 파일)

```markdown
# BS-07-07 Security Delay (홀카드 공개 지연)

> **참조**: `Overlay_Output_Events.md` (legacy-id: API-04), BS-07-06-layer-boundary §반자동 §Action Badge

## 배경

라이브 포커 방송에서 실시간으로 홀카드가 공개되면, 시청자나 공모자가 휴대폰/신호로
플레이어에게 카드 정보를 전달할 수 있다. 이를 방지하기 위해 방송은 **N초 지연**하여
송출되어야 한다.

이는 WSOP, EPT, WPT 등 메이저 대회의 필수 요구사항이며, PokerGFX도 동일 기능을 제공한다.

## 원리

```
게임 이벤트 발생 (t=0)
    │
    ├─ Overlay 내부 Buffer 저장 (delay_sec 동안 보관)
    │
    ├─ Backstage Output (즉시)
    │   └─ 운영진만 보는 화면 (CC, Director)
    │
    └─ Broadcast Output (t=delay_sec 후)
        └─ 시청자용 방송 화면
```

### 이중 출력 (Dual Output)

EBS Overlay는 **두 가지 출력 스트림**을 동시에 제공:

1. **Backstage Stream** (NDI 채널 1): 운영진/감독용. Security Delay 없음.
2. **Broadcast Stream** (NDI 채널 2): 시청자용. Security Delay 적용.

두 스트림은 동일 내용이지만 **시간 차이**로 분리된다.

## 지연 설정

| 파라미터 | 기본값 | 범위 | 설정 위치 |
|---------|:------:|:---:|---------|
| `delay_enabled` | false | true/false | BS-03 Settings §Output |
| `delay_seconds` | 30 | 0 ~ 600 (10분) | BS-03 Settings §Output |
| `delay_holecards_only` | false | true/false | BS-03 Settings §Output (true면 홀카드만 지연, 다른 요소는 즉시) |

**운영 기본**: 30초 (WSOP 대회 표준)

## 버퍼 아키텍처

### OutputEventBuffer

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
    // Timer가 releaseAt 시점에 broadcast stream으로 이벤트 전달
  }
}
```

- 버퍼 크기: 이론상 무제한 (메모리 허용 범위)
- 실제 운영: 최대 1000 이벤트 (30초 × 33 이벤트/초 여유)
- 초과 시: 가장 오래된 이벤트를 drop + 경고 로그

### 이벤트 순서 보장

버퍼는 FIFO. 이벤트가 buffer에 들어간 순서대로 release됨.

### 시계 동기화

`releaseAt`는 로컬 시스템 시간 기준. NTP 동기화 가정.
방송 장비와 EBS가 같은 네트워크 NTP 사용 권장.

## 지연 대상 이벤트

| 이벤트 | 지연 적용 | 근거 |
|--------|:-------:|------|
| HoleCardRevealed | ✅ | 치트 방지 핵심 |
| BoardCardDealt | ✅ | 카드 정보 누설 방지 |
| ActionPerformed (FOLD/CHECK/CALL/RAISE/BET/ALL-IN) | ✅ | 베팅 패턴 누설 방지 |
| PotUpdated | ✅ | 액션 결과 노출 방지 |
| EquityUpdated | ✅ | 실시간 승률 누설 방지 |
| WinnerRevealed | ✅ | 결과 누설 방지 |
| PlayerStacksUpdated | ✅ | 결과 추론 방지 |
| PlayerInfoUpdated (이름/국가) | ❌ | 정적 정보, 지연 불필요 |
| SkinChanged | ❌ | 방송 시스템 변경, 즉시 적용 |
| TableNameChanged | ❌ | 방송 라벨, 즉시 적용 |
| ConnectionStatus | ❌ | 내부 상태, Broadcast에 노출 안 함 |

`delay_holecards_only=true` 옵션 시 HoleCardRevealed만 지연, 나머지는 즉시.

## 예외 처리

### 1. 지연 중 Skin 변경

Backstage에 즉시 반영되지만, Broadcast는 `delay_seconds` 후 반영.
이는 의도된 동작 (Backstage와 Broadcast의 시각 연속성 유지).

### 2. 지연 중 연결 끊김

- Backstage Output 중단 → 재연결 시 이어서
- Broadcast Output은 이미 버퍼된 이벤트를 계속 release (연결만 재수립)
- 장시간 끊김 시: 버퍼 overflow 위험 → 오래된 이벤트 drop + 경고

### 3. 버퍼 overflow

- 1000 이벤트 초과 시: 가장 오래된 이벤트 drop
- 로그: "OutputBuffer overflow: dropped N events"
- 알림: CC AT-01에 경고 배너 (운영자 인지 필요)

### 4. 지연 시간 변경 (운영 중)

- `delay_seconds`를 30 → 45로 변경 시:
  - 기존 버퍼 내 이벤트는 원래 scheduled time 유지
  - 새로 들어오는 이벤트만 45초 지연
- 30 → 0으로 변경 시: 모든 기존 버퍼 이벤트 즉시 release (운영자 확인 다이얼로그 필수)

## 구현 위치

- `team4-cc/src/lib/features/overlay/services/output_event_buffer.dart`
- `team4-cc/src/lib/features/overlay/services/dual_output_manager.dart`
- `team4-cc/src/lib/foundation/configs/security_delay_config.dart`

## 테스트

### Unit 테스트
- 버퍼 enqueue → delay 경과 → release 순서 검증
- 1000 이벤트 overflow 시 drop 정책
- `delay_holecards_only` 모드에서 지연/즉시 분기

### Integration 테스트
- Mock OutputEvent 100개를 5초 간격으로 enqueue → Backstage 즉시 / Broadcast 30초 후 확인
- 지연 중 연결 끊김 → 재연결 → 이벤트 이어서 release

## 참조

- `Overlay_Output_Events.md` (legacy-id: API-04) §Security Delay (이하 §2 추가)
- `Settings/Outputs.md` (legacy-id: BS-03-01) §Output 설정 (delay_seconds 필드)
- BS-07-06-layer-boundary §Action Badge 반자동 (Security Delay의 운영 개입점)
```

### 2. API-04 §Security Delay 섹션 추가

```markdown
## Security Delay

> **상세 명세**: BS-07-07-security-delay.md 참조

Overlay는 두 출력 스트림을 제공한다:

| Stream | 용도 | 지연 |
|--------|------|:---:|
| Backstage | 운영진(CC/Director) | 없음 |
| Broadcast | 시청자 송출 | `delay_seconds` (기본 30s) |

OutputEvent는 Backstage로 즉시 전달되고, 동시에 `OutputEventBuffer`에 저장되어
`delay_seconds` 후 Broadcast로 release된다.

지연 대상 이벤트 및 설정은 BS-07-07 참조.
```

## 영향 분석

### Team 1 (Lobby/Frontend)
- **영향**:
  - BS-03 Settings §Output 탭에 `delay_enabled`, `delay_seconds`, `delay_holecards_only` 3개 필드 추가
  - Admin이 Lobby에서 delay 설정 변경 가능
- **예상 작업 시간**: 4시간

### Team 2 (Backend)
- **영향**:
  - `delay_seconds` 설정을 `ConfigChanged` WebSocket 이벤트로 Overlay에 전파
  - Output 설정 DB 저장 (`configs` 테이블)
- **예상 작업 시간**: 3시간

### Team 4 (self)
- **영향**:
  - `OutputEventBuffer` 구현 (FIFO 큐 + Timer)
  - `DualOutputManager` 구현 (Backstage + Broadcast 2 stream)
  - 설정 변경 시 buffer 재조정 로직
  - 연결 끊김/overflow 예외 처리
- **예상 작업 시간**:
  - 버퍼/Timer: 10시간
  - Dual Output: 8시간
  - 예외 처리: 6시간
  - 통합 테스트: 6시간
  - 총 30시간

### 마이그레이션
- 없음 (신규 기능)

## 대안 검토

### Option 1: Security Delay 생략
- **단점**: 
  - WSOP/EPT/WPT 대회 사용 불가 (라이선스 요건)
  - 치트 방지 불능 → 공정성 훼손
- **채택**: ❌

### Option 2: Backstage/Broadcast 분리 + 버퍼 (본 제안)
- **장점**: 
  - 운영진 즉시 + 시청자 지연 동시 충족
  - WSOP 대회 표준 충족
- **단점**: Dual output 복잡도, 대역폭 2배
- **채택**: ✅

### Option 3: Broadcast 전용, Backstage 없음
- **단점**: 운영진도 30초 지연 → CC/Director가 현재 상황을 실시간 파악 불가
- **채택**: ❌

## 검증 방법

### 1. 지연 정확성
- [ ] OutputEvent 발행 시각 t0 + delay_seconds(30s) = Broadcast release 시각 t1
- [ ] t1 - t0 오차 < 100ms

### 2. 순서 보장
- [ ] 100개 이벤트 순차 enqueue → Broadcast에서 동일 순서로 release
- [ ] FIFO 위반 없음

### 3. Overflow 정책
- [ ] 1001번째 이벤트 enqueue → 0번 drop + 로그 발생

### 4. 설정 변경
- [ ] 운영 중 30 → 45로 변경 → 기존 이벤트는 30s 지연 유지, 신규는 45s
- [ ] 30 → 0으로 변경 → 확인 다이얼로그 + 버퍼 즉시 flush

### 5. 시각 모니터링
- [ ] Backstage와 Broadcast를 나란히 모니터에 띄워 30초 지연 시각 확인

## 승인 요청

- [ ] Conductor 승인
- [ ] Team 1 기술 검토 (BS-03 Settings UI)
- [ ] Team 2 기술 검토 (ConfigChanged 전파)
- [ ] Team 4 기술 검토 (Buffer 구현, Dual Output)
