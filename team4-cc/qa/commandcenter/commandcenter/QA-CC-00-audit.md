# QA-CC-00: 테스트 품질 감사 결과

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | Command Center 테스트 품질 감사 |

---

## 개요

Command Center 앱(`/ebs_app/`)의 기존 테스트를 감사한 결과. **품질 점수 3/10**.

> 레포: `/ebs_app/` | 프레임워크: Flutter Desktop | 상태관리: Riverpod

---

## 감사 요약

| 항목 | 상태 |
|------|------|
| 테스트 파일 | 3건 |
| 테스트 함수 | 10건 (unit 3 + integration 5 + widget 2) |
| API 계층 테스트 | **0건** (CcApiClient 전체 미테스트) |
| 에러 경로 테스트 | **없음** |
| E2E | **없음** |
| CI/CD | **없음** |
| Mock 프레임워크 | **미설치** |

---

## 테스트 파일 상세

| 파일 | 테스트 수 | 검증 내용 | 문제 |
|------|:--------:|----------|------|
| `fake_rfid_reader_test.dart` | 3 | stream inject, deck 52장, playScenario | **품질 양호** (타이밍 flakiness 주의) |
| `game_session_test.dart` | 5 | 초기 상태, copyWith, RFID 중복제거, enterLive, advanceStreet | **debugSetState로 실제 경로 우회** |
| `widget_test.dart` | 2 | 로딩 텍스트, 서버 미연결 에러 | **실제 서버 상태에 의존** |

---

## 안티패턴 상세

### debugSetState 남용

```dart
// game_session_test.dart — loadTable() API 경로를 완전히 우회
ctrl.debugSetState(const GameSession(
  phase: SessionPhase.deckRegistration,
  tableId: 'table-001',
));
```

API가 깨져도 테스트 PASS. loadTable() → 상태 전환 경로가 **미검증**.

### 실제 네트워크 의존

```dart
// widget_test.dart — localhost:8080이 꺼져있어야 PASS
expect(find.textContaining('서버 연결 실패'), findsOneWidget);
```

서버가 실행 중이면 테스트 FAIL.

### Tautological 테스트

```dart
// GameSession 기본 생성자 기본값을 확인 — 언어를 테스트하는 것
expect(session.phase, SessionPhase.loading);
```

---

## CRITICAL 미테스트 영역

| 영역 | 소스 위치 | 위험도 |
|------|----------|:------:|
| **CcApiClient 전체** | `services/api_client.dart` (7개 메서드) | CRITICAL |
| **loadTable() 상태 전환** | `game_session_provider.dart` lines 40-71 | CRITICAL |
| **enterLive() API 호출** | `game_session_provider.dart` lines 85-105 | HIGH |
| **DeckRegistrationScreen** | `screens/deck_registration_screen.dart` | HIGH |
| **CommandCenterScreen** | `screens/command_center_screen.dart` | HIGH |
| **OverlayScreen** | `screens/overlay_screen.dart` | MEDIUM |
| **PlayingCard.shortLabel** | `models/card.dart` 52종 매핑 | MEDIUM |
| **RFID 스캔 (loading phase)** | `game_session_provider.dart` line 154 | P1 |
| **커뮤니티 카드 5장 초과** | `game_session_provider.dart` line 148 | P1 |

---

## 의존성 문제

`pubspec.yaml`에 **mockito/mocktail 없음** — CcApiClient mock 불가. 테스트 인프라 추가 필수.

---

## 참조

- 행동 명세: `contracts/specs/BS-05-command-center/` (7파일)
- QA 전략: `docs/qa/commandcenter/QA-CC-01-strategy.md`
