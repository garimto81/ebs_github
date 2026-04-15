---
id: GAP-BO-001
title: Idempotency-Key 헤더 표준 부재
status: RESOLVED
source: docs/2. Development/2.2 Backend/Spec_Gaps.md
---

# [GAP-BO-001] Idempotency-Key 헤더 표준 부재

- **관찰**: `contracts/api/API-01~06` 어디에도 멱등성 키 헤더 정의 없음. 방송 중 네트워크 재시도/운영자 더블클릭 시 seat draw/chip 출납 중복 적용 위험.
- **참조**:
  - WSOP `Chip Master.md` (2-phase confirmation: Requested→Approved/Rejected)
  - WSOP `Waiting API.md` (seat draw 재시도 케이스)
- **구현 가능성**: ~~불가(CCR)~~ → **가능 (CCR-003 contracts 반영 완료)**
- **액션**: ~~CCR-DRAFT 제출~~ → **완료**. 승격본 `docs/05-plans/CCR-003-모든-mutation-api에-idempotency-key-헤더-표준-도입.md`. 정본은 `contracts/api/API-01 §공통 요청 헤더 Idempotency-Key`, `contracts/data/DATA-04 §5.1`
- **상태**: **RESOLVED (2026-04-10)** — IMPL-10 §3.1, IMPL-06 §4.4, IMPL-05 DI 에 구현 가이드 반영됨

---
