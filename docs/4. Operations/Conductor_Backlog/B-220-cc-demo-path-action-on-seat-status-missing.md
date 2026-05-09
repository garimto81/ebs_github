---
id: B-220
title: "B-220 — CC dispatchLocalDemoEvent: actionOn + seat status sync 누락"
owner: team4 + team2
tier: internal
status: IMPLEMENTED
type: backlog
severity: HIGH
blocker: true
source: docs/4. Operations/Plans/E2E_Verification_Report_2026-05-10.md
last-updated: 2026-05-10
implemented-at: 2026-05-10
implemented-by: conductor (E2E v1.7)
---

## 개요

E2E v1.5 QA 자동화 검증 중 사용자 지적 발견:
> "cc 로직 설계도 불완전함 (empty 위치에 액션을 호출)"

코드 분석 결과 `team4-cc/src/lib/data/remote/ws_provider.dart`의 `dispatchLocalDemoEvent`에:
- **HandStarted** (line 200-208): pot/handNumber/boardCards 갱신만, `setActionOn` 호출 없음
- **ActionPerformed** (line 212-221): pot/hasBetToMatch 갱신만, **next actionOn + seat fold status sync 없음**

기획 §1.1.1 Action-to-Transport Matrix는 Engine response의 full state snapshot을 dispatcher가 받아 처리하라고 명시 (`engine_output_dispatcher.dart`). 그러나 demo path는 Engine 미사용이므로 자체 actionOn 결정 로직 필요.

## 영향

| 증상 | 화면 | 코드 |
|------|------|------|
| ACTING glow가 stale 또는 EMPTY 좌석에 잘못 표시 | screenshot 22 (S2 EMPTY yellow) | seat_provider.actionOn 미갱신 |
| Folded 좌석이 시각적으로 표시 안 됨 | quickHand 시나리오 후 S4 (Bob fold) 정상 표시 | seat status 갱신 누락 |
| 액션 dispatch 시 actionSeat = null → seatNo 0 | _dispatchAction line 247-248 | actionOn 무관계 dispatch |

## 작업 범위

### 1. ws_provider.dart `dispatchLocalDemoEvent` 보강

**HandStarted 처리** (line 200):
```dart
case 'HandStarted':
  // ... existing pot/handNumber/boardCards 갱신
  // 추가: dealer 다음 occupied 좌석 (BB+1)을 actionOn으로
  final dealerSeat = payload['dealer_seat'] as int? ?? 1;
  final seatNotifier = read(seatsProvider.notifier);
  final firstActionSeat = seatNotifier.nextOccupiedAfter(dealerSeat, offset: 3);
  // 3 = BB+1 (Dealer → SB → BB → UTG)
  seatNotifier.setActionOn(firstActionSeat);
```

**ActionPerformed 처리** (line 212):
```dart
case 'ActionPerformed':
  final seat = payload['seat'] as int? ?? 0;
  final actionType = payload['action_type'] as String? ?? '';
  // ... existing pot/hasBetToMatch 갱신
  // 추가: 좌석 status 갱신 (fold → folded)
  if (actionType == 'fold') {
    read(seatsProvider.notifier).setStatus(seat, SeatStatus.folded);
  }
  // 추가: next actionOn (occupied만 순환, folded skip)
  final next = read(seatsProvider.notifier).nextActiveAfter(seat);
  read(seatsProvider.notifier).setActionOn(next);
```

### 2. seat_provider에 helper 추가

```dart
// SeatNotifier에 추가
int? nextOccupiedAfter(int fromSeat, {int offset = 1}) { ... }
int? nextActiveAfter(int fromSeat) { ... }  // occupied + !folded
void setStatus(int seatNo, SeatStatus status) { ... }
```

### 3. quickHand 시나리오의 actionOn 명시

scenarios.dart에 ActionPerformed payload `next_action_seat` 추가 (선택):
```dart
DemoEvent(type: 'ActionPerformed', payload: {
  'seat': 4, 'action_type': 'fold', 'pot_after': 150,
  'next_action_seat': 7,  // ← 명시적 다음 액션 좌석
}),
```

### 4. 회귀 검증

- [ ] cc-web 재빌드 + Demo 자동 재생
- [ ] HandStarted → S? actionOn (occupied만)
- [ ] S4 fold → S4 folded visual + S7 actionOn
- [ ] S7 call → S1 actionOn  
- [ ] 어떤 시점에도 EMPTY 좌석이 actionOn 안 됨

## 완료 기준

- [ ] EMPTY 좌석에 ACTING glow 표시 0건
- [ ] folded 좌석 시각적 구분 (반투명 또는 dimmed)
- [ ] quickHand 시나리오에서 actionOn S1→S4→S7 순환 (Dealer S1 기준 PRE-FLOP)
- [ ] Engine path와 동일한 행동 (full state snapshot dispatch와 일관)

## 위험

- **광범위 영향**: ws_provider는 production WS path도 사용. 변경 시 prod 시나리오도 영향. team2 publisher와 정합 필요.
- 기획 §1.1.1: **Engine response의 full state snapshot이 SSOT**. demo path는 engine_output_dispatcher.dart 우회이므로 별도 sync 로직 추가 = duplicate logic. 권장 해결: demo도 stub_engine 사용해 동일 dispatcher 경로.

## 권장 path

**Option A** (빠름): ws_provider의 demo path에 actionOn/status 갱신 직접 추가
**Option B** (정석): demo가 stub_engine을 통해 EngineOutputDispatcher.dispatchState() 호출. dispatch 통일.

Option B가 §1.1.1 정합 + duplicate logic 방지. 단 stub_engine 시나리오 매핑 작업 필요.

## 참조

- E2E 보고서 v1.5 (iteration-5/22 캡처)
- §1.1.1 Action-to-Transport Matrix (`Command_Center_UI/Overview.md`)
- `engine_output_dispatcher.dart` (Engine path SSOT)
- `services/stub_engine.dart` (Demo Mode 후속 활용 후보)
