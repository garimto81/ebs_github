# QA-LOBBY-01: QA 전략 및 구현 가이드

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | Lobby QA 전략, 테스트 항목, 구현 순서 |

---

## 개요

QA-LOBBY-00 감사 결과를 기반으로 Lobby 앱의 테스트 전략을 정의한다.

> 레포: `/ebs_lobby_web/` | 프레임워크: Flutter Web | 행동 명세: BS-02

---

## Invariant

| Invariant | 검증 방법 |
|----------|----------|
| 세션 계층 일관성 | series 선택 시 event/flight/table 반드시 null |

---

## 사전 작업

```bash
cd /c/claude/ebs_lobby_web
flutter pub add --dev mocktail
```

---

## Unit 테스트 (P0 — 최우선)

| # | 대상 | 파일 | 테스트 항목 | 우선순위 |
|---|------|------|-----------|:-------:|
| L-U01 | SessionService | `test/services/session_service_test.dart` | `clearBelow('series')` → event/flight/table null | P0 |
| L-U02 | SessionService | 상동 | `clearBelow('event')` → flight/table null, series 유지 | P0 |
| L-U03 | SessionService | 상동 | `saveContext()` → `restore()` 왕복 검증 | P0 |
| L-U04 | JSON Parsers | `test/services/json_parsers_test.dart` | null 필드 처리, 타입 변환, DateTime 파싱 | P1 |
| L-U05 | API Client | `test/services/api_client_test.dart` | 200 성공, 404 미발견, 409 TransitionBlocked, 5xx 에러 | P0 |
| L-U06 | Event Filtering | `test/logic/event_filter_test.dart` | 탭별 필터(All, Created, Running, Completed 등) | P1 |
| L-U07 | Table Sorting | `test/logic/table_sort_test.dart` | Feature 우선, 번호 순 정렬 | P2 |

---

## Widget 테스트 (P1)

| # | 대상 | 테스트 항목 | 우선순위 |
|---|------|-----------|:-------:|
| L-W01 | LoginScreen | 이메일/비밀번호 입력 → 로그인 버튼 클릭 → provider 호출 | P1 |
| L-W02 | LoginScreen | 로그인 실패 → 에러 메시지 표시 | P1 |
| L-W03 | SessionRestoreDialog | "Continue" 클릭 → 콜백 호출 | P1 |
| L-W04 | EventListScreen | 탭 클릭 → 필터링된 목록 렌더링 | P1 |
| L-W05 | TableManagementScreen | Feature 테이블 상단, 좌석 색상 매핑 | P2 |
| L-W06 | Breadcrumb | 칩 클릭 → 해당 레벨로 네비게이션 | P2 |

---

## E2E 테스트 (P2)

| # | 시나리오 | 검증 |
|---|---------|------|
| L-E01 | 로그인 → 시리즈 선택 → 이벤트 목록 | 화면 전환, 데이터 로딩 |
| L-E02 | 이벤트 선택 → 테이블 관리 → CC 잠금 상태 | 좌석 렌더링, 상태 표시 |
| L-E03 | 세션 복원 플로우 | 기존 세션 감지 → 복원 다이얼로그 → 이전 위치 복원 |

---

## 커버리지 목표

| 계층 | Phase 1 | 최종 |
|------|:-------:|:----:|
| Unit | ≥60% | ≥80% |
| Widget | 핵심 5개 화면 | 전체 화면 |
| E2E | 3 시나리오 | TEST-02 전체 |

---

## 구현 순서

| Phase | 항목 | 범위 |
|:-----:|------|------|
| 1 | mocktail 설치 + L-U01~L-U05 | 인프라 + P0 unit |
| 2 | L-U06~L-U07 + L-W01~L-W06 | P1 unit + widget |
| 3 | L-E01~L-E03 + CI/CD | E2E + 자동화 |

---

## 참조

- 감사 결과: `docs/qa/lobby/QA-LOBBY-00-audit.md`
- 행동 명세: `docs/02-behavioral/BS-02-lobby/BS-02-lobby.md`
- 상위 전략: `docs/testing/TEST-01-test-plan.md`
