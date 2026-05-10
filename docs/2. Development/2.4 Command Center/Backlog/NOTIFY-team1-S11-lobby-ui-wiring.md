---
id: NOTIFY-team1-S11
title: S-11 Lobby Hand History 자동화 UI wiring 요청
target_team: team1
status: OPEN
source: docs/2. Development/2.4 Command Center/Backlog.md
mirror: none
---

# NOTIFY — team1: S-11 Lobby UI wiring 요청

- **요청일**: 2026-04-21
- **요청 세션**: team4 (/team work/team4/_team-20260421-144936)
- **관련**: B-team4-003

## 요청 내용

team4 가 S-11 E2E 자동화 스캐폴드(`docs/2. Development/2.4 Command Center/Integration_Test_Plan/automation/s11/`) 를 작성했다. Lobby UI 레이어 활성화는 team1 결정 권한.

### 요청 작업

1. **Lobby widget key 부착** (team1 decision_owner):
   | 위젯 | Key |
   |------|-----|
   | Hand Browser root | `handBrowser.root` |
   | Hand Browser 개별 row | `handBrowser.row.{hand_id}` |
   | Hand Browser 첫 row (WS prepend 검증용) | `handBrowser.row.first` |
   | Hand Detail timeline | `handDetail.timeline` |
   | Hand Detail seat grid | `handDetail.seatGrid` |
   | Filter event_id input | `filter.eventId` |
   | Filter table_id input | `filter.tableId` |
   | Filter apply button | `filter.apply` |
   | 당일 한정 배너 | `banner.todayOnly` 또는 텍스트 `'당일 한정'` |
   | Sidebar Hand History nav | `sidebar.handHistory` |

2. **`team1-frontend/integration_test/s11_lobby_test.dart` 복제** — 본 template 기반:
   ```bash
   mkdir -p team1-frontend/integration_test
   cp "docs/2. Development/2.4 Command Center/Integration_Test_Plan/automation/s11/flutter_driver/s11_lobby_test.dart" team1-frontend/integration_test/
   cp "docs/2. Development/2.4 Command Center/Integration_Test_Plan/automation/s11/flutter_driver/integration_test_driver.dart" team1-frontend/test_driver/integration_test.dart
   ```

3. **Helper wiring** — `_loginAs`, `_logout`, `_openHandDetail`, `_setFilterDate`, `_triggerHandStartedViaApi` 를 team1 Lobby 구조에 맞춰 구현

4. **`markTestSkipped` 제거** — 6 testWidgets 모두 활성화

## 완료 기준

- `cd team1-frontend && flutter drive --driver=test_driver/integration_test.dart --target=integration_test/s11_lobby_test.dart` 가 green
- `run_s11.sh --ui-only` 가 통과

## 비고

- 소유권: team1 decision_owner. team4 는 E2E 명세 + API/WS 레이어만 담당.
- Backend seeder 는 별도 NOTIFY (team2) 참조.
