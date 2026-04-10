# QA-LOBBY-00: 테스트 품질 감사 결과

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | Lobby 테스트 품질 감사 |

---

## 개요

Lobby 앱(`/ebs_lobby_web/`)의 기존 테스트를 감사한 결과. **품질 점수 2/10**.

> 레포: `/ebs_lobby_web/` | 프레임워크: Flutter Web | 상태관리: Riverpod + go_router

---

## 감사 요약

| 항목 | 상태 |
|------|------|
| 테스트 파일 | 7건 (widget 전부) |
| Unit 테스트 | **0건** |
| 비즈니스 로직 검증 | **없음** |
| 에러 경로 테스트 | **없음** |
| E2E | **없음** |
| CI/CD | **없음** |
| Mock 프레임워크 | **미설치** (mockito/mocktail 없음) |

---

## 테스트 파일 상세

| 파일 | 테스트 수 | 검증 내용 | 문제 |
|------|:--------:|----------|------|
| `breadcrumb_test.dart` | 2 | 텍스트 렌더링만 | 네비게이션 클릭 미테스트 |
| `cc_lock_test.dart` | 1 | 아이콘 존재만 (`findsWidgets`) | 상태별 분기 미테스트 |
| `event_list_test.dart` | 1 | 탭 이름 렌더링만 | 필터링 로직 미테스트 |
| `series_screen_test.dart` | 1 | 시리즈 카드 텍스트만 | 검색/월별 그룹핑 미테스트 |
| `session_restore_test.dart` | 2 | 다이얼로그 텍스트만 | 버튼 클릭 콜백 미테스트 |
| `table_management_test.dart` | 1 | 아이콘 1개 확인만 | 정렬/좌석/상태 전환 미테스트 |
| `widget_test.dart` | 1 | 로그인 폼 필드 존재만 | 로그인 플로우 미테스트 |

---

## CRITICAL 미테스트 영역

| 영역 | 소스 위치 | 위험도 |
|------|----------|:------:|
| **세션 계층 clearing** | `session_service.dart` `clearBelow()` | CRITICAL |
| **이벤트 상태 필터링** | `event_list_screen.dart` `_filtered()` | CRITICAL |
| **API 에러 핸들링** (409 TransitionBlocked) | `api_client.dart` | CRITICAL |
| **로그인 → 세션 복원 플로우** | `login_screen.dart` lines 44-76 | CRITICAL |
| **JSON 파서** (null 처리, 타입 변환) | `json_parsers.dart` | HIGH |
| **테이블 정렬** (Feature 우선) | `table_management_screen.dart` `_sortedTables` | HIGH |
| **좌석 렌더링** (색상 매핑) | `table_management_screen.dart` | MEDIUM |

---

## Mock 인프라 문제

- `mock_api_client.dart` — 에러 시뮬레이션 불가, `assignSeat()` 빈 구현
- mockito/mocktail 미설치 — 고급 mock 패턴 사용 불가
- 비동기 에러 테스트 불가능

---

## 참조

- 행동 명세: `docs/02-behavioral/BS-02-lobby/BS-02-lobby.md`
- QA 전략: `docs/qa/lobby/QA-LOBBY-01-strategy.md`
