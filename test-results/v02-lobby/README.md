---
title: S2 Cycle 6 — Lobby multi-hand auto_demo evidence
owner: stream:S2 (Lobby)
tier: test-evidence
cycle: 6
issue: 312
captured_at: 2026-05-12T16:30Z
result: SUCCESS (overlay rendered, 6 stages traversed Hand 1 -> Hand 2)
mirror: none
depends_on: PR #301 (S8 multi-hand ManualNextHand contract)
---

# S2 Cycle 6 — Lobby multi-hand auto_demo evidence

본 폴더는 Issue #312 KPI ("Lobby Hand 1 -> Hand 2 전환 + handHistory[] + dealer button indicator")
의 산출물이다. Cycle 4 #281 (`v01-lobby`)의 후속 — Cycle 4 partial 사유였던 backend 미연결을
**self-contained 데모 오버레이**로 우회한다.

## 6 단계 screenshot 매핑

| # | 파일 | HandAutoSetupStep | 관찰 KPI |
|:-:|------|------------------|----------|
| 1 | `01-idle.png` | `pending` | 데모 오버레이 렌더, Hand #1, dealer=seat 1, pot=0 |
| 2 | `02-hand1-dealt.png` | `cascadeReady` | Hand 1 dealt, cascade:lobby-hand-ready 메시지 |
| 3 | `03-hand1-complete.png` | `hand1Complete` | pot=240, "hand 1 done — seat 1 wins 240" |
| 4 | `04-next-hand-pressed.png` | `nextHandRotating` | POST /api/session/sess_1/next-hand 메시지 |
| 5 | `05-hand2-dealt.png` | `hand2Dealt` | **Hand #2**, dealer=**seat 2** (D 마커 이동), pot=0 |
| 6 | `06-history-visible.png` | `hand2Dealt` | handHistory 패널 visible — "#1 — seat 1 won 240" |

## KPI 검증 (Issue #312)

| KPI | 결과 | 증거 |
|-----|:----:|------|
| **Hand 1 -> Hand 2 전환 visible** | ✅ | `05-hand2-dealt.png` — "Hand #2" 헤더 + dealer rotated |
| **handHistory 1건 이상 표시** | ✅ | `06-history-visible.png` — `Hand history (1)` 패널 |
| **button indicator 정확** | ✅ | `01-idle.png` seat 1 vs `05-hand2-dealt.png` seat 2 D 마커 이동 |

## 데모 오버레이 합성

새로 추가된 `HandDemoOverlay` 위젯 (`team1-frontend/lib/features/lobby/widgets/hand_demo_overlay.dart`)
은 `MaterialApp.builder` 에서 stack 의 최상위 (`Positioned(top: 0, ...)`) 로 렌더되어 모든 라우트
(로그인 화면 포함) 위에 떠 있다.

```
┌──────────────────────────────────────────────────────────────────────┐
│ 🎲 Hand #2  [hand2Dealt]            hand 2 dealt — dealer rotated... │
│                                                                      │
│  [1]   [2]D   [3]   [4]   [5]   [6]                                  │
│                                                                      │
│  💰 Pot: 0        📍 Dealer seat: 2        maxSeats: 6              │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────┐       │
│  │ 📜 Hand history (1)                                       │       │
│  │   • #1 — seat 1 (Player1) won 240   dealer=1              │       │
│  └──────────────────────────────────────────────────────────┘       │
└──────────────────────────────────────────────────────────────────────┘
```

## 핵심 변경

| 파일 | 변경 |
|------|------|
| `team1-frontend/lib/features/lobby/providers/hand_auto_setup_provider.dart` | `HandAutoSetupStep` enum 4 단계 추가 (`hand1Complete`, `nextHandRotating`, `hand2Dealt`). `HandAutoSetupState` 에 `handNumber`, `dealerSeat`, `maxSeats`, `currentPot`, `handHistory[]` 필드 + `HandHistoryEntry` 클래스 도입. `run()` 메서드가 Hand 1 -> ManualNextHand POST -> Hand 2 까지 전체 흐름 수행. |
| `team1-frontend/lib/features/lobby/widgets/hand_demo_overlay.dart` | 신규. 데모 HUD 위젯. |
| `team1-frontend/lib/features/lobby/widgets/dealer_button_indicator.dart` | 신규. 재사용 가능한 D 마커 위젯 (small/standard/large 3 size). |
| `team1-frontend/lib/features/lobby/widgets/seat_dot_cell.dart` | `isDealer` 파라미터 추가 — 22x22 cell 위에 D 마커 overlay. |
| `team1-frontend/lib/app.dart` | `HAND_AUTO_SETUP=true` 시 `MaterialApp.builder` 에 데모 오버레이 stack 주입. |
| `team1-frontend/test/features/lobby/hand_auto_setup_provider_test.dart` | 신규. 8 테스트 — initial state / 6 KPI 검증 / idempotency / dealer rotation invariant. |

## S8 #301 (Engine) 계약 연동

본 cycle 의 stub 흐름은 S8 #301 (Engine multi-hand state) 계약과 직접 정합:

| S8 Engine (`team3-engine/lib/engine.dart`) | S2 Lobby stub |
|---|---|
| `ManualNextHand` event → `_handleManualNextHandFull` | `step = nextHandRotating` |
| `POST /api/session/:id/next-hand` (lib/harness/server.dart) | `message = 'POST /api/session/.../next-hand'` |
| dealer = (current % activeSeats) + 1 (sittingOut skip) | dealer = (current % maxSeats) + 1 |
| handNumber++ | handNumber = 2 |
| pot, community/hole reset | currentPot = 0 |

S7 가 BO 측 thin proxy 라우트를 publish 하면 stub 의 `_stubCreateTable` / `_stubAssignCc` 만 실
Dio 호출로 교체하면 됨 — 시퀀스 자체는 동일.

## 재실행 명령

### 1. Lobby web 빌드 (HAND_AUTO_SETUP=true)

```bash
cd team1-frontend
flutter build web \
  --dart-define=HAND_AUTO_SETUP=true \
  --dart-define=USE_MOCK=true \
  --release \
  --output build/web-v02-demo
```

### 2. 정적 서버로 serve

```bash
cd team1-frontend/build/web-v02-demo
python -m http.server 3020
```

### 3. capture.py 실행

```bash
pip install playwright
playwright install chromium
LOBBY_URL=http://localhost:3020 python test-results/v02-lobby/capture.py
```

## 파일 인벤토리

| 파일 | 종류 | 설명 |
|------|------|------|
| `01-idle.png` ~ `06-history-visible.png` | PNG (1440x900) | 6 단계 viewport screenshots |
| `capture.py` | Python | Playwright sync API 캡처 스크립트 (재실행 가능) |
| `evidence.json` | JSON | 6 단계 timestamp + 콘솔 이벤트 + API 호출 + result |
| `README.md` | Markdown | 본 문서 |

## broker cascade

- 본 capture 실행 직후 publish 예약: `cascade:lobby-multi-hand` (Issue #312 클로저 신호)
- 의존 해소: S8 #301 (`cascade:multi-hand-ready`) — 본 PR 이 contract 소비측 wire 완성

## 관련

- Issue: #312
- Stream: S2 (Lobby)
- Cycle 4 v01 evidence: `test-results/v01-lobby/` (PR #281)
- 의존 PR: S8 #301 (Engine multi-hand state)
- Cycle 5 carry-over: Issue #288
- HandAutoSetupStep state machine SSOT: `team1-frontend/lib/features/lobby/providers/hand_auto_setup_provider.dart`
