---
title: Demo & Test Mode (DEPRECATED)
owner: team4
tier: feature
status: deprecated-2026-04-21
last-updated: 2026-04-21
---

> # ⚠️ DEPRECATED (2026-04-21)
>
> **Demo Scenario (사전 시나리오 자동 재생) 는 scope 제외** (사용자 결정 2026-04-21).
>
> Lobby 없이 CC 를 개발·QA 검증용으로 실행하는 경로는 기획 문서 없음 — 프로토타입 범위에서 `flutter run -d windows` 로 충분 (`Overview.md §2.0`). Engine 없이 실행은 `Overlay/Engine_Dependency_Contract.md §4 StubEngine Fallback` 참조.
>
> 본 문서는 **역사 참조용**. 아래 원문은 편집하지 않는다 (2026-04-16 ~ 2026-04-17 의사결정 흔적).

---

# [DEPRECATED] Command Center — Demo & Test Mode (RFID 비연결 게임 진행 검증)

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-16 | 신규 작성 | RFID 미연결 상태에서 게임 엔진·핸드 진행 검증 가능한 데모 모드 설계 |
| 2026-04-17 | Web 배포 추가 | Flutter Web 빌드로 LAN 내 브라우저 접속 지원. §1.4 신설 |
| 2026-04-21 | DEPRECATED | Demo Scenario scope 제외. Standalone 기획 과대로 철회 — 프로토타입은 `flutter run -d windows` 로 충분. |

---

## 개요

이 문서는 RFID 하드웨어가 연결되지 않은 환경에서도 **게임 엔진 연동, 핸드 진행, 액션 디스패치, 카드 입력**을 검증할 수 있는 Demo & Test Mode를 정의한다.

**목적**: Phase 1 (소프트웨어 전용) 상태에서 CC의 전체 게임 플로우를 시각적으로 확인.

**사용 대상**: 개발자, QA, 운영 교육.

**비목적**: 프로덕션 운영용이 아님. 실제 테이블에서는 사용하지 않는다.

**접속 방식**: 데스크톱 앱(로컬) 또는 **Flutter Web 빌드 → 브라우저 접속**(LAN 내 원격).

---

## §1. 진입 조건 및 활성화

### §1.1 Feature Flag

| 플래그 | 기본값 | 설명 |
|--------|:------:|------|
| `Features.enableDemoMode` | `false` | Demo Mode UI 표시 여부 |

### §1.2 진입 방법

| 방법 | 설명 |
|------|------|
| **커맨드라인 인자** | `--demo` 플래그 추가 시 자동 활성화 |
| **런타임 토글** | Toolbar 메뉴 → "Demo Mode" (Feature Flag on일 때만 노출) |

### §1.3 진입 시 자동 설정

Demo Mode 진입 시 아래 상태가 자동 초기화된다:

| 항목 | 값 | 근거 |
|------|-----|------|
| `Features.useMockRfid` | `true` | RFID 하드웨어 불필요 |
| WebSocket 연결 | 미연결 허용 (오프라인 모드) | 백엔드 미실행 환경 |
| Game Engine | 로컬 Dart 패키지 또는 HTTP 하니스 | Option A/B 선택 |
| 테이블 설정 | 기본 NL 홀덤 (SB 50 / BB 100) | 즉시 시작 가능 |
| 좌석 | 3명 자동 착석 (S1, S4, S7) | 최소 핸드 진행 조건 |
| 딜러 | S1 자동 할당 | 핸드 시작 전제조건 충족 |

### §1.4 Web 배포 (LAN 브라우저 접속)

CC는 Flutter 데스크톱 앱이지만, **Flutter Web 빌드**로 동일 네트워크의 다른 머신에서 브라우저 접속이 가능하다.

| 항목 | 값 |
|------|-----|
| 빌드 명령 | `flutter build web --release --dart-define=DEMO_MODE=true` |
| 서빙 | Docker Compose `cc-web` 서비스 (Nginx, 포트 3100) |
| 접속 URL | `http://<LAN_IP>:3100` |
| 지원 기능 | 게임 진행, Demo Mode, WebSocket, REST — **전부 동작** |
| 미지원 | RFID 하드웨어, NDI 출력, 로컬 파일 접근 (플랫폼 채널) |

> **Demo Mode에서는 Web 미지원 기능이 전부 불필요** (MockRfid, StubNdi 사용). 따라서 Web 빌드가 Demo Mode의 최적 배포 형태.

상세: `docs/4. Operations/Network_Deployment.md §CC 웹 배포`

---

## §2. Demo Mode 제어 패널

Toolbar 아래에 접이식 패널로 표시. 프로덕션 UI와 시각적으로 구분 (주황색 상단 바 + "DEMO" 라벨).

### §2.1 패널 레이아웃

```
┌─────────────────────────────────────────────────────┐
│ 🟠 DEMO MODE                          [Collapse ▲] │
├─────────────────────────────────────────────────────┤
│                                                     │
│  [시나리오]  ▼ Quick Hand    [▶ 실행]  [⏭ 스텝]    │
│                                                     │
│  [플레이어]  [+추가] [−제거] [스택 리셋]            │
│                                                     │
│  [카드 주입] S1: [__][__]  S4: [__][__]  S7: [__][__]│
│             보드: [__][__][__][__][__]               │
│                                                     │
│  [이벤트 로그]  HandStarted → ActionPerformed(fold)  │
│                → CardDetected(Ah) → ...             │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### §2.2 제어 버튼

| 버튼 | 동작 | 설명 |
|------|------|------|
| **▶ 실행** | 선택된 시나리오 전체 자동 실행 | 각 이벤트 500ms 간격 |
| **⏭ 스텝** | 시나리오의 다음 이벤트 1개만 실행 | 디버깅용 단계별 진행 |
| **⏹ 정지** | 자동 실행 중지 | 현재 상태에서 멈춤 |
| **↺ 리셋** | 핸드 초기화 → IDLE 상태 | 좌석·팟·보드 모두 초기화 |

---

## §3. 시나리오 시스템

### §3.1 내장 시나리오

| 시나리오 | 설명 | 이벤트 수 |
|---------|------|:---------:|
| **Quick Hand** | 3인 NL 홀덤 기본. fold→call→check→check→showdown | 12 |
| **All-in Preflop** | 프리플랍 올인 콜. 런아웃 5장. | 8 |
| **Full Street** | 모든 스트리트 진행 (플랍→턴→리버→쇼다운) | 25 |
| **Miss Deal** | 핸드 시작 후 Miss Deal 선언 → 핸드 무효화 | 4 |
| **RFID Fallback** | RFID 감지 실패 → 수동 카드 입력 → 계속 진행 | 15 |
| **Multi-action** | 다양한 액션 조합 (raise→re-raise→call→fold) | 20 |

### §3.2 시나리오 데이터 포맷

```dart
class DemoScenario {
  final String name;
  final String description;
  final List<DemoEvent> events;
}

class DemoEvent {
  final String type;           // "HandStarted", "ActionPerformed", etc.
  final Map<String, dynamic> payload;
  final Duration delay;        // 이전 이벤트로부터의 지연
  final String? uiHint;        // 제어 패널 로그에 표시할 설명
}
```

### §3.3 시나리오 실행 흐름

```
시나리오 선택
  │
  ├─ [▶ 실행] ──→ 자동 이벤트 주입 (500ms 간격)
  │                각 이벤트 → dispatchIncomingEvent() 호출
  │                CC UI 실시간 반영
  │                마지막 이벤트 → "시나리오 완료" 표시
  │
  └─ [⏭ 스텝] ──→ 다음 이벤트 1개만 주입
                   제어 패널에 "Step 3/12" 진행률 표시
                   운영자가 UI 상태를 확인한 후 다음 스텝
```

---

## §4. 수동 이벤트 주입

시나리오 없이 운영자가 직접 이벤트를 주입할 수 있다.

### §4.1 플레이어 관리

| 동작 | 입력 | 결과 |
|------|------|------|
| 추가 | 좌석 번호 선택 + 이름(옵션) | `SeatNotifier.seatPlayer()` 호출 |
| 제거 | 좌석 번호 선택 | `SeatNotifier.vacateSeat()` 호출 |
| 스택 리셋 | 전원 | 모든 착석 플레이어 스택 → 10,000 |

### §4.2 카드 주입 (RFID 바이패스)

보드 카드와 홀카드를 수동으로 주입한다. RFID 없이 카드 상태를 직접 설정.

| 대상 | 입력 | 결과 |
|------|------|------|
| 홀카드 | 좌석 번호 + Suit + Rank × 2장 | `cardInputProvider.manualSelect()` |
| 보드 카드 | Suit + Rank (1장씩) | `dispatchIncomingEvent(CardDetected, is_board: true)` |

카드 선택 UI는 기존 AT-03 Card Selector 모달을 재사용한다.

### §4.3 액션 주입

일반 CC 액션 버튼을 그대로 사용한다 (Demo Mode에서도 ActionPanel은 동일). 단, WebSocket 없이 **로컬 디스패치**로 처리:

| 액션 | 로컬 처리 |
|------|----------|
| NEW HAND | `HandFsmNotifier.startHand()` + 팟/보드 초기화 |
| FOLD | `HandFsmNotifier` 에 fold 반영 + 다음 좌석 actionOn |
| CHECK/CALL | 팟 업데이트 + 다음 좌석 |
| BET/RAISE | 금액 반영 + `hasBetToMatch = true` |
| ALL-IN | 스택 전액 → 팟 |
| DEAL | 카드 입력 모드 진입 (수동 입력) |

---

## §5. 이벤트 로그

Demo 제어 패널 하단에 실시간 이벤트 로그를 표시한다.

### §5.1 로그 항목

```
[14:23:01] HandStarted — hand #1, dealer S1
[14:23:02] ActionPerformed — S4 fold
[14:23:03] ActionPerformed — S7 call 100
[14:23:04] CardDetected — board Ah (flop 1/3)
[14:23:05] CardDetected — board Ks (flop 2/3)
[14:23:06] CardDetected — board 7d (flop 3/3)
[14:23:06] StreetAdvanced — FLOP
```

### §5.2 로그 사양

| 속성 | 값 |
|------|-----|
| 최대 표시 | 최근 50건 (스크롤 가능) |
| 폰트 | `EbsTypography.mono`, 12px |
| 타임스탬프 | `HH:mm:ss` |
| 색상 | 이벤트 타입별: HandStarted=초록, Action=흰색, Card=노랑, Error=빨강 |

---

## §6. 오프라인 모드 (WebSocket 미연결)

### §6.1 WebSocket 미연결 시 동작

Demo Mode에서 WebSocket이 연결되지 않아도 게임이 진행된다:

| 구성요소 | 오프라인 동작 |
|---------|-------------|
| **Hand FSM** | 로컬 `HandFsmNotifier` 직접 전이 |
| **Pot/Board** | 로컬 `StateProvider` 직접 업데이트 |
| **Card Input** | `MockRfidReader.injectCard()` 또는 수동 AT-03 |
| **Action Buttons** | 로컬 `ActionButtonProvider` 상태 업데이트 |
| **Seat Management** | 로컬 `SeatNotifier` 직접 조작 |
| **Game Engine** | 선택적 — HTTP 하니스 연결 시 실제 엔진 사용, 미연결 시 로컬 FSM만 |

### §6.2 오프라인 vs 온라인 차이

| 항목 | 오프라인 (Demo) | 온라인 (프로덕션) |
|------|:-:|:-:|
| 핸드 번호 | 로컬 자동증가 | 서버 할당 |
| 액션 검증 | FSM 가드만 | 엔진 + 서버 검증 |
| 팟 계산 | 단순 합산 | 엔진 정밀 계산 (사이드팟 포함) |
| Undo | 로컬 스택 | 서버 동기화 |
| 통계 | 미수집 | 서버 집계 |

---

## §7. 시각적 구분

Demo Mode가 활성화되면 프로덕션 화면과 혼동을 방지하기 위해:

| 요소 | 사양 |
|------|------|
| **Toolbar 배경** | `#E65100` (주황) → 프로덕션 `surfaceContainerHigh`와 명확 구분 |
| **"DEMO" 배지** | Toolbar 좌측에 고정 표시, `FontWeight.w900`, 흰색 |
| **보더** | 전체 화면 2px 주황색 보더 |
| **비콘** | 제어 패널 접힌 상태에서도 "DEMO" 배지 유지 |

---

## §8. 런타임 토글 규칙

| 전환 | 허용 | 조건 |
|------|:----:|------|
| 프로덕션 → Demo | O | 핸드 미진행 (IDLE/HAND_COMPLETE) |
| Demo → 프로덕션 | O | 핸드 미진행 + Demo 상태 리셋 |
| 핸드 진행 중 전환 | X | 핸드 완료 후에만 가능 |

---

## §9. 구현 파일 매핑

| 기능 | 파일 | 비고 |
|------|------|------|
| Feature Flag | `lib/foundation/configs/features.dart` | `enableDemoMode` 추가 |
| Demo 제어 패널 | `lib/features/command_center/widgets/demo_control_panel.dart` | 신규 |
| 시나리오 데이터 | `lib/features/command_center/demo/scenarios.dart` | 신규 |
| 시나리오 실행기 | `lib/features/command_center/demo/scenario_runner.dart` | 신규 |
| 로컬 디스패치 | `lib/features/command_center/demo/local_dispatcher.dart` | 신규 — WS 없이 이벤트 주입 |
| Demo Provider | `lib/features/command_center/providers/demo_provider.dart` | 신규 |
| AT-01 통합 | `lib/features/command_center/screens/at_01_main_screen.dart` | 수정 — 제어 패널 삽입 |
| LaunchConfig | `lib/models/launch_config.dart` | 수정 — `--demo` 인자 파싱 |

---

## §10. 테스트 계획

| 테스트 | 검증 내용 |
|--------|----------|
| `test/demo/scenario_runner_test.dart` | Quick Hand 시나리오 전체 실행 → 최종 상태 검증 |
| `test/demo/local_dispatcher_test.dart` | WS 없이 이벤트 주입 → provider 상태 변경 |
| `test/demo/demo_provider_test.dart` | Demo 진입/탈출 + 자동 초기화 |
| 기존 테스트 | Demo Mode 비활성 시 기존 207개 테스트 영향 없음 |

---

## §11. 제외 범위

| 항목 | 사유 |
|------|------|
| 커스텀 시나리오 편집 UI | Phase 2 — 내장 시나리오로 충분 |
| 시나리오 파일 import/export | Phase 2 — JSON 포맷 확정 후 |
| 멀티테이블 Demo | Phase 2 — 단일 테이블만 지원 |
| Overlay Demo | 별도 문서 (Overlay 자체 데모 경로) |
| 네트워크 장애 시뮬레이션 | RFID fallback 문서에서 이미 커버 |
