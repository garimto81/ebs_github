# QA-CC-01: QA 전략 및 구현 가이드

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | Command Center QA 전략, 테스트 항목, 구현 순서 |

---

## 개요

QA-CC-00 감사 결과를 기반으로 Command Center 앱의 테스트 전략을 정의한다.

> 레포: `/ebs_app/` | 프레임워크: Flutter Desktop | 행동 명세: BS-05

---

## Invariant

| Invariant | 검증 방법 |
|----------|----------|
| 등록 카드 ≤ 52장 | registeredCards.length 항상 0~52 |
| 커뮤니티 카드 ≤ 5장 | communityCards.length 항상 0~5 |

---

## 사전 작업

```bash
cd /c/claude/ebs_app
flutter pub add --dev mocktail
```

---

## Unit 테스트 (P0)

| # | 대상 | 파일 | 테스트 항목 | 우선순위 |
|---|------|------|-----------|:-------:|
| C-U01 | CcApiClient | `test/services/api_client_test.dart` | `getTable()` 성공/404/5xx | P0 |
| C-U02 | CcApiClient | 상동 | `getSeats()` JSON 파싱 | P0 |
| C-U03 | CcApiClient | 상동 | `transitionTable()` 성공/409 conflict | P0 |
| C-U04 | CcApiClient | 상동 | `markDeckRegistered()` 성공/실패 | P0 |
| C-U05 | GameSession model | `test/models/game_session_test.dart` | `deckComplete` (51장=false, 52장=true) | P1 |
| C-U06 | PlayingCard | `test/models/card_test.dart` | `shortLabel` 52종 전부 검증 | P2 |

---

## Integration 테스트 — loadTable 경로 (P0)

`debugSetState`를 제거하고 **mock API를 통한 실제 경로** 테스트:

| # | 대상 | 테스트 항목 | 우선순위 |
|---|------|-----------|:-------:|
| C-I01 | loadTable 성공 (미등록) | API 성공 → phase=deckRegistration | P0 |
| C-I02 | loadTable 성공 (등록완료) | API 성공 + deckRegistered=true → phase=live | P0 |
| C-I03 | loadTable 실패 (404) | API 404 → errorMessage 설정 | P0 |
| C-I04 | loadTable 실패 (네트워크) | 네트워크 오류 → '서버 연결 실패' | P0 |
| C-I05 | enterLive API 호출 | markDeckRegistered + transitionTable 호출 검증 | P1 |
| C-I06 | enterLive API 실패 | API 예외 → 에러 처리 | P1 |
| C-I07 | RFID 스캔 (loading phase) | loading 상태에서 카드 무시 | P1 |
| C-I08 | RFID 스캔 (커뮤니티 5장 초과) | 6번째 카드 무시 | P1 |

---

## Widget 테스트 (P1)

| # | 대상 | 테스트 항목 | 우선순위 |
|---|------|-----------|:-------:|
| C-W01 | DeckRegistrationScreen | 진행바 값 = registeredCards.length/52 | P1 |
| C-W02 | DeckRegistrationScreen | 52장 완료 시 "Enter Live" 버튼 활성화 | P1 |
| C-W03 | CommandCenterScreen | street 라벨 변경 (preflop→flop→...) | P1 |
| C-W04 | CommandCenterScreen | 커뮤니티 카드 표시 (0~5장) | P2 |
| C-W05 | DeckGrid | 등록된 카드 = 녹색, 미등록 = 회색 | P2 |

---

## E2E 테스트 (P2)

| # | 시나리오 | 검증 |
|---|---------|------|
| C-E01 | 앱 시작 → 테이블 로딩 → 덱 등록 | phase 전환, 진행바 |
| C-E02 | 52장 등록 → Enter Live → 핸드 진행 | street 전환, 커뮤니티 카드 |
| C-E03 | 서버 미연결 → 에러 표시 → 재시도 | 에러 복구 |

---

## 커버리지 목표

| 계층 | Phase 1 | 최종 |
|------|:-------:|:----:|
| Unit | ≥60% | ≥80% |
| Integration | loadTable 4경로 | 전체 상태 전환 |
| E2E | 3 시나리오 | TEST-02 전체 |

---

## 구현 순서

| Phase | 항목 | 범위 |
|:-----:|------|------|
| 1 | mocktail 설치 + C-U01~C-U04 + C-I01~C-I04 | 인프라 + P0 |
| 2 | C-U05~C-U06 + C-I05~C-I08 + C-W01~C-W05 | P1 unit + widget |
| 3 | C-E01~C-E03 + CI/CD | E2E + 자동화 |

---

## 참조

- 감사 결과: `docs/qa/commandcenter/QA-CC-00-audit.md`
- 행동 명세: `docs/02-behavioral/BS-05-command-center/` (7파일)
  - `BS-05-00-overview.md`
  - `BS-05-01-hand-lifecycle.md`
  - `BS-05-02-action-buttons.md`
  - `BS-05-03-seat-management.md`
  - `BS-05-04-manual-card-input.md`
  - `BS-05-05-undo-recovery.md`
  - `BS-05-06-keyboard-shortcuts.md`
- 상위 전략: `docs/testing/TEST-01-test-plan.md`
