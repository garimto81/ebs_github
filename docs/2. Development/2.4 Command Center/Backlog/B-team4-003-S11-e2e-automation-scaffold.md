---
id: B-team4-003
title: S-11 E2E 자동화 스캐폴드 — Playwright + flutter_driver
status: DONE
source: docs/2. Development/2.4 Command Center/Backlog.md
mirror: none
---

# [B-team4-003] S-11 E2E 자동화 스캐폴드

- **등록일**: 2026-04-21
- **완료일**: 2026-04-21
- **관련 기획**: `docs/2. Development/2.4 Command Center/Integration_Test_Plan.md §S-11`
- **산출물**: `docs/2. Development/2.4 Command Center/Integration_Test_Plan/automation/s11/`

## 배경

2026-04-21 Migration Plan Phase 4 에서 S-11 (Lobby Hand History 조회 + 필터 + RBAC) 시나리오가 Integration_Test_Plan 에 추가되었다 (commit `8e2d670`). 명세만으로는 "외부 개발팀이 재구현 가능" 기준을 충족하지 못하므로 실행 가능한 자동화 스캐폴드를 추가했다.

## 결과물

| 자산 | 용도 |
|------|------|
| `fixtures/fixtures.json` | 3 계정 (Admin/Operator/Viewer) + Event/Flight/Table/Hand seed + expected API/WS 응답 |
| `playwright/tests/s11.api.spec.ts` | §5.10.1 필터 정합 · RBAC · hole_card 마스킹 · 페이지네이션 · 당일 한정 정책 (7 testcases) |
| `playwright/tests/s11.ws.spec.ts` | `HandStarted` prepend · `ActionPerformed` contract · seq 단조증가 (3 testcases) |
| `flutter_driver/s11_lobby_test.dart` | Lobby UI skeleton (6 testWidgets, `markTestSkipped` + TODO) |
| `run_s11.sh` / `run_s11.ps1` | seed + api + ui 3-stage orchestrator |
| `scripts/seed_s11.py` | BO seeder stub (team2 가 INSERT 로직 구현 예정) |
| `README.md` | 실행 계약 + 소유권 경계 + 알려진 한계 |

## 소유권 (v7 free_write + decision_owner)

- `Integration_Test_Plan/automation/s11/` 자체 — **team4**
- `flutter_driver/s11_lobby_test.dart` 는 team4 디렉토리 내 **template**. team1 이 `team1-frontend/integration_test/` 로 복제 + widget key 부착
- `seed_s11.py` stub 대체 — **team2** 가 BO seeder 로 구현

## Follow-up (Backlog 연계)

| 항목 | 팀 | 내용 |
|------|:---:|------|
| Lobby widget key 부착 | team1 | `handBrowser.root`, `handBrowser.row.{hand_id}`, `handDetail.timeline`, `filter.{eventId,tableId,apply}`, `banner.todayOnly` |
| s11_lobby_test.dart 활성화 | team1 | `markTestSkipped` 제거 + login/logout helper wiring |
| seed_s11 INSERT 구현 | team2 | fixtures 3 계정 + Event/Table/Hands INSERT |
| CC HandStarted 트리거 자동화 | team2/team4 | Playwright 가 수동 대기 없이 실행 가능하도록 mock publisher endpoint 또는 admin API |

## 검증

- `dart analyze team4-cc/src` — 본 PR 은 team4-cc/src 를 수정하지 않음 (docs 추가만). 영향 없음 확인.
- Playwright 자체 실행은 team2 BO + seeder 가 있어야 green. 본 PR 에서는 스캐폴드 제공까지.

## 참조

- Integration_Test_Plan §S-11 (10 단계)
- Backend_HTTP.md §5.10.1 (필터 RBAC 매트릭스)
- WebSocket_Events.md §3.3.3 (Lobby Hand History consumer)
