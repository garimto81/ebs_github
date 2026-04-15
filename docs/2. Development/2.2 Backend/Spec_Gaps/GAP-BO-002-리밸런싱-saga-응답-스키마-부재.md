---
id: GAP-BO-002
title: 리밸런싱 saga 응답 스키마 부재
status: RESOLVED
source: docs/2. Development/2.2 Backend/Spec_Gaps.md
---

# [GAP-BO-002] 리밸런싱 saga 응답 스키마 부재

- **관찰**: `contracts/api/API-01` `/tables/rebalance` 는 단순 200/400만 정의. 부분 실패 시 어떤 단계가 성공/롤백됐는지 운영자가 확인 불가.
- **참조**:
  - WSOP `Tables API.md` 리밸런싱 다단계 흐름
  - BO-03 §4 "부분 롤백" 복구 시나리오 (본 작업에서 신설)
- **구현 가능성**: ~~불가(CCR)~~ → **가능 (CCR-010 contracts 반영 완료)**
- **액션**: ~~CCR-DRAFT 제출~~ → **완료**. 승격본 `docs/05-plans/CCR-010-tablesrebalance-응답에-saga-구조-추가.md`. 정본은 `contracts/api/API-01 §POST /tables/rebalance` (saga_id/steps[]/200/207/500)
- **상태**: **RESOLVED (2026-04-10)** — IMPL-10 §3.4, BO-03 §4.4, IMPL-05 `get_saga_orchestrator` DI 에 구현 가이드 반영됨

---
