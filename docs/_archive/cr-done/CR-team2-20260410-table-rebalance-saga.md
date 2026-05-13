---
title: CR-team2-20260410-table-rebalance-saga
owner: conductor
tier: internal
last-updated: 2026-04-15
legacy-id: CCR-DRAFT-team2-20260410-table-rebalance-saga
confluence-page-id: 3818816663
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818816663/EBS+CR-team2-20260410-table-rebalance-saga
---

# CCR-DRAFT: /tables/rebalance 응답에 saga 구조 추가

- **제안팀**: team2
- **제안일**: 2026-04-10
- **영향팀**: [team1]
- **변경 대상 파일**: contracts/api/`Backend_HTTP.md` (legacy-id: API-01)
- **변경 유형**: modify
- **변경 근거**: WSOP `Tables API.md` 의 리밸런싱은 여러 테이블에 걸친 **다단계 연산**(seat release → seat assign → chip move → WSOP LIVE notify)이며, 중간에 부분 실패 시 일부 플레이어만 이동 완료되는 고장 모드가 실제로 발생한다. 현재 API-01의 `/tables/rebalance` 계약은 단순 200/400 응답만 정의되어 있어, 부분 실패 시 운영자가 어떤 단계가 성공했고 어떤 단계가 롤백됐는지 확인할 방법이 없다. saga 패턴 응답으로 가시화한다.

## 변경 요약

`POST /api/v1/tables/rebalance` 응답 바디를 saga 형태로 확장. 각 단계의 성공/실패/보상 결과를 명시.

## Diff 초안

```diff
### POST /api/v1/tables/rebalance

**용도**: 여러 테이블 간 플레이어 재배치.

+**멱등성**: `Idempotency-Key` 헤더 필수. saga 전체에 1개 키 부여.

**Request**:
```json
{
  "event_flight_id": "ef-001",
  "strategy": "balanced",
  "target_players_per_table": 9,
  "dry_run": false
}
```

-**Response 200**:
+**Response 200 (전체 성공)**:
```json
{
+  "saga_id": "sg-20260410-001",
+  "status": "completed",
  "moved": [
    { "player_id": "p-123", "from_table": "tbl-01", "to_table": "tbl-05", "to_seat": 3 },
    ...
  ],
-  "tables_closed": ["tbl-07"]
+  "tables_closed": ["tbl-07"],
+  "steps": [
+    { "step_no": 1, "name": "acquire_locks", "status": "ok", "duration_ms": 42 },
+    { "step_no": 2, "name": "compute_plan", "status": "ok", "duration_ms": 18 },
+    { "step_no": 3, "name": "release_seats", "status": "ok", "duration_ms": 120 },
+    { "step_no": 4, "name": "assign_seats", "status": "ok", "duration_ms": 180 },
+    { "step_no": 5, "name": "notify_wsop_live", "status": "ok", "duration_ms": 310 },
+    { "step_no": 6, "name": "broadcast_ws", "status": "ok", "duration_ms": 25 }
+  ],
+  "completed_at": "2026-04-10T12:34:57.234Z"
}
```

+**Response 207 Multi-Status (부분 성공 후 보상)**:
+
+saga 중간 실패 후 compensating action이 실행되어 **일관된 상태로 복원됐을 때**.
+
+```json
+{
+  "saga_id": "sg-20260410-002",
+  "status": "compensated",
+  "steps": [
+    { "step_no": 1, "name": "acquire_locks", "status": "ok" },
+    { "step_no": 2, "name": "compute_plan", "status": "ok" },
+    { "step_no": 3, "name": "release_seats", "status": "ok" },
+    { "step_no": 4, "name": "assign_seats", "status": "failed",
+      "error": "seat_conflict",
+      "message": "Seat tbl-05/3 already taken by concurrent operation"
+    },
+    { "step_no": 3, "name": "release_seats", "status": "compensated",
+      "compensation": "reverted_releases", "affected_players": ["p-123", "p-456"]
+    }
+  ],
+  "moved": [],
+  "tables_closed": [],
+  "error": {
+    "code": "partial_failure_compensated",
+    "message": "Rebalancing rolled back to original state. Retry safe."
+  }
+}
+```
+
+**Response 500 (보상 실패 — 수동 개입 필요)**:
+```json
+{
+  "saga_id": "sg-20260410-003",
+  "status": "compensation_failed",
+  "steps": [ ... ],
+  "error": {
+    "code": "manual_intervention_required",
+    "message": "Partial state detected. See audit_events for recovery.",
+    "audit_cursor": { "from_seq": 15001, "to_seq": 15024 }
+  }
+}
+```
+Operator 경고 + `BO-03 §4 Scenario D` 복구 절차 트리거.

+**단계 설명**:
+1. `acquire_locks` — 영향 테이블 전체에 distributed lock (`lock:table:{id}` Redis SET NX EX 30s) + fencing token
+2. `compute_plan` — 대상 플레이어/좌석 배치 계산
+3. `release_seats` — 원 좌석 비움 (audit_events 기록)
+4. `assign_seats` — 신규 좌석 배정 (audit_events 기록)
+5. `notify_wsop_live` — WSOP LIVE 동기화 (실패 시 fallback queue로 보내고 단계 성공 처리)
+6. `broadcast_ws` — WebSocket 이벤트 발행
+
+실패 시 역순으로 compensating action 실행. 각 step 별 idempotent 보장.
```

## 영향 분석

- **Team 2 (자기)**: `RebalanceSagaOrchestrator` 클래스 신설, 단계별 compensator, `audit_events` 기록. 약 16시간.
- **Team 1 (Lobby)**: 응답 status 3종 분기 처리 (`completed`/`compensated`/`compensation_failed`), saga 단계별 toast UI, `compensation_failed` 시 경고 모달. 약 6시간.
- **Team 4 (CC)**: WebSocket에서 `rebalance_completed`/`rebalance_compensated` 이벤트 수신 시 테이블 상태 재로드. 약 2시간.
- **마이그레이션**: 기존 클라(있다면)는 `moved`/`tables_closed`만 읽으므로 `status`/`steps` 필드 추가는 하위 호환.

## 대안 검토

1. **단순 transaction (전체 rollback)** — 단일 DB transaction으로 처리. 하지만 `notify_wsop_live` 는 외부 API 호출이라 DB transaction에 포함 불가. 탈락.
2. **Eventual consistency + 재시도** — 부분 상태 장기 지속 허용. 방송 맥락에서 허용 불가. 탈락.
3. **Saga 패턴 (채택)** — compensating action으로 일관성 복원, 각 단계 가시화.
4. **외부 saga framework (temporal.io 등)** — Phase 3+ 고려.

## 검증 방법

- **단위**: 각 단계별 compensator 호출 테스트
- **통합**: `assign_seats` 단계에 강제 에러 주입 → 207 응답 + audit_events에 compensation 기록
- **혼돈 테스트**: compensation 중 다시 에러 → 500 + `manual_intervention_required`, 상태 조회 가능
- **멱등성**: 동일 Idempotency-Key로 재요청 시 saga 중복 실행 안 됨

## 승인 요청

- [ ] Conductor 승인
- [ ] Team 1 기술 검토 (Lobby 응답 분기)
- [ ] 종속 CCR (`idempotency-key`, `data-idempotency-audit`) 선행
