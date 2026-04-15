---
id: GAP-BO-008
title: audit_events 스키마 및 Undo/Revive inverse 이벤트 부재
status: RESOLVED
source: docs/2. Development/2.2 Backend/Spec_Gaps.md
---

# [GAP-BO-008] audit_events 스키마 및 Undo/Revive inverse 이벤트 부재

- **관찰**: `contracts/data/DATA-04`에 이벤트 스토어 테이블 없음. Undo/Revive 시 2-way consistency 보장 불가, 핸드 리플레이/좌석 이력 복구 불가.
- **참조**:
  - WSOP DB `EventFlightSeatHistory` (모든 좌석 변경 이력)
  - WSOP `Action History.md` Undo/Revive 기능
- **구현 가능성**: ~~불가(CCR)~~ → **가능 (CCR-001 contracts 반영 완료)**
- **액션**: ~~CCR-DRAFT 제출~~ → **완료**. 승격본 `docs/05-plans/CCR-001-data-04에-idempotencykeys-auditevents-테이블-신설.md`. 정본은 `contracts/data/DATA-04 §5.2 audit_events` (스키마, 제약, 인덱스, SQLAlchemy 모델, append-only 강제 방법 포함)
- **상태**: **RESOLVED (2026-04-10)** — IMPL-10 §7.1/§7.2, BO-03 §1.2/§4, IMPL-05 `get_audit_repo` DI, IMPL-07 §4.1 3-way 구분에 반영됨

---
