---
id: GAP-BO-011
title: `src/db/init.sql` ↔ `contracts/data/DATA-04-db-schema.md` 큰 격차
status: OPEN
source: docs/2. Development/2.2 Backend/Spec_Gaps.md
---

# [GAP-BO-011] `src/db/init.sql` ↔ `contracts/data/DATA-04-db-schema.md` 큰 격차

- **관찰**: **[CRITICAL]** `src/db/init.sql` 현재 상태는 Stage 0 RFID 카드 매핑용 `cards` 테이블 **1개**만 포함(54장 덱 seed data). DATA-04는 competitions/series/events/users/user_sessions/audit_logs/decks/hands/table_seats 등 12개+ 엔티티를 정의. CLAUDE.md L16 "권위 DDL — DATA-04와 일치 필수" 규칙 위반 상태.
- **참조**:
  - `C:\claude\ebs\contracts\data\DATA-04-db-schema.md`
  - `C:\claude\ebs\team2-backend\src\db\init.sql`
  - `C:\claude\ebs\team2-backend\CLAUDE.md:16`
- **구현 가능성**: 미결 (감사) — 격차 해소 방식 결정 필요
- **액션**:
  1. Phase 1 Stage 1 진입 전까지 `src/db/init.sql`을 DATA-04와 완전 동기화 (team2 내부 작업)
  2. 동기화 작업 자체는 CCR 불필요 (init.sql은 구현체)
  3. DATA-04의 최신 엔티티를 기반으로 CREATE TABLE 문 재작성
  4. 추가로 GAP-BO-001(idempotency_keys), GAP-BO-008(audit_events) CCR 승인 후 즉시 반영
  5. 향후 drift 방지를 위해 CI에 `tools/check_schema_drift.py` 추가 제안 (backlog 등록)
- **임시 구현**: 없음 — Stage 0만 동작 중이라 실질 영향은 Stage 1 진입 시점부터
- **상태**: OPEN — Stage 1 진입 전 동기화 필수

---
