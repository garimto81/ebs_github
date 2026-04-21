---
id: NOTIFY-team2-S11
title: S-11 자동화 실행을 위한 BO seeder + endpoint 준비 요청
target_team: team2
status: OPEN
source: docs/2. Development/2.4 Command Center/Backlog.md
---

# NOTIFY — team2: S-11 BO seeder + endpoint 준비

- **요청일**: 2026-04-21
- **요청 세션**: team4 (/team work/team4/_team-20260421-144936)
- **관련**: B-team4-003

## 요청 내용

team4 가 작성한 S-11 자동화(`Integration_Test_Plan/automation/s11/`) 가 실제 통과하려면 team2 가 다음을 완료해야 한다.

### 1. Seeder 구현

`scripts/seed_s11.py` 가 현재 stub. `fixtures/fixtures.json` 의 다음 데이터를 DB 에 INSERT:

| 항목 | 수량 |
|------|:---:|
| Users | 3 (admin_s11, operator_t1, viewer_s11) |
| User-Table 할당 | operator_t1 ↔ table_id=1 |
| Events | 1 (event_id=1) |
| Flights | 1 (flight_id=1, day_1a) |
| Tables | 2 (table_id=1, 2) |
| Hands (table 1) | 3 (hand_id=101, 102, 103, 당일) |
| Hands (table 2) | 1 (hand_id=201, 당일) |

### 2. API 계약 준수 (`Backend_HTTP.md §5.10.1`)

자동화 검증 포인트:

- `GET /api/v1/hands` 필터: `event_id`, `table_id`, `date_from`, `date_to`, `page`, `page_size`
- Operator 미할당 테이블 요청 시 **빈 배열 + 200** (403 아님 — 정보 노출 회피)
- Viewer `/hands/:id/players` 응답에서 `hole_card_1`, `hole_card_2` = `"★"` 마스킹
- Admin/Operator `/hands/:id/players` 에서는 실제 카드 값 (마스킹 해제)
- 당일 한정 정책: `date_from` 이 오늘 이전이면 빈 결과 + (UI 측 배너)

### 3. WebSocket 계약 준수 (`WebSocket_Events.md §3.3.3`)

- `ws://localhost:8000/ws/lobby?token={JWT}` JWT 인증
- `{"type":"Subscribe","event_types":["HandStarted","ActionPerformed","HandEnded"]}` payload 처리
- `HandStarted` / `ActionPerformed` 이벤트에 `seq` 단조증가 필드
- CC (테스트 조건) 이 새 hand 를 시작하면 WS 로 `HandStarted` 브로드캐스트

### 4. (선택) CC 트리거 mock endpoint

Playwright 가 수동 대기 없이 실행하려면:

- `POST /api/v1/_test/cc/hand-started` 같은 테스트 전용 endpoint (비프로덕션, `ENV=test` 에서만 활성) 또는
- Playwright 내부에서 CC WS 로 직접 publish

## 완료 기준

- `run_s11.sh --api-only` 가 BO 가동 상태에서 green
- 10 testcases (API 7 + WS 3) 전부 통과

## 비고

- 스키마 인덱스(idx_hands_event_table_started 등)는 §5.10.1 에 이미 명시. 구현 확인 필요.
- 현재 커밋 `fca4fd8` 에서 필터 파라미터가 확장됐지만 실제 Viewer 마스킹 / Operator scope / 당일 한정 로직은 검증 필요.
