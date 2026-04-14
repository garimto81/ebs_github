# CCR-DRAFT: DATA-04에 idempotency_keys, audit_events 테이블 신설

- **제안팀**: team2
- **제안일**: 2026-04-10
- **영향팀**: [team1, team4]
- **변경 대상 파일**: contracts/data/DATA-04-db-schema.md
- **변경 유형**: add
- **변경 근거**: WSOP+ Database 문서의 `EventFlightSeatHistory`, Audit 테이블 설계를 참고하면, 좌석/칩/블라인드 등 모든 상태 변경은 append-only 이벤트 스토어로 기록되어야 복구·감사·핸드 리플레이·Undo/Revive가 가능하다. 또한 `Idempotency-Key` CCR(동일 일자)과 WebSocket seq CCR(동일 일자)은 모두 전용 스토리지가 필요하므로 DATA-04 확장 필수.

## 변경 요약

`idempotency_keys` 와 `audit_events` 두 테이블 신설. 후자는 WebSocket `seq` 필드와 BO-03 복구 절차의 SSOT.

## Diff 초안

```diff
+### idempotency_keys
+
+재시도 안전성 보장용 요청/응답 캐시. 24h TTL 후 정리.
+
+| 컬럼 | 타입 | 제약 | 설명 |
+|------|------|------|------|
+| `key` | VARCHAR(128) | PK | 클라이언트가 생성한 UUIDv4/ULID |
+| `user_id` | VARCHAR(64) | NOT NULL | 멱등성 범위를 사용자당으로 좁혀 키 충돌 방지 |
+| `method` | VARCHAR(16) | NOT NULL | POST/PUT/PATCH/DELETE |
+| `path` | VARCHAR(255) | NOT NULL | 요청 경로 (query string 제외) |
+| `request_hash` | CHAR(64) | NOT NULL | 바디 SHA-256 |
+| `status_code` | SMALLINT | NOT NULL | 최초 응답 상태 |
+| `response_body` | TEXT | NULL | 최초 응답 바디 (JSON) |
+| `created_at` | TIMESTAMP | NOT NULL DEFAULT now() | 인입 시각 |
+| `expires_at` | TIMESTAMP | NOT NULL | created_at + 24h |
+
+**인덱스**: `(user_id, key)` unique, `expires_at` B-tree (청소용)
+**정리**: cron job `DELETE FROM idempotency_keys WHERE expires_at < now()`, 5분 간격
+**Phase 1 SQLite**: 동일 구조, TEXT for VARCHAR/TIMESTAMP
+
+### audit_events
+
+모든 상태 변경을 append-only로 기록하는 이벤트 스토어. `seq`는 테이블별 단조증가이며 WebSocket envelope의 `seq`와 1:1 매핑. 복구·리플레이·Undo의 SSOT.
+
+| 컬럼 | 타입 | 제약 | 설명 |
+|------|------|------|------|
+| `id` | BIGSERIAL | PK | 전역 순번 (audit용) |
+| `table_id` | VARCHAR(64) | NOT NULL | 테이블 식별자. 테이블 없는 이벤트(global)는 `'*'` |
+| `seq` | BIGINT | NOT NULL | 테이블별 단조증가. `(table_id, seq)` unique |
+| `event_type` | VARCHAR(64) | NOT NULL | `seat_assigned`, `hand_started`, `rebalance_step` 등 |
+| `actor_user_id` | VARCHAR(64) | NULL | 주체 (system 이벤트는 NULL) |
+| `correlation_id` | VARCHAR(64) | NULL | 분산 트레이싱 ID (same across service hops) |
+| `causation_id` | VARCHAR(64) | NULL | 직전 원인 이벤트의 id (event sourcing 체인) |
+| `idempotency_key` | VARCHAR(128) | NULL | 요청이 `Idempotency-Key` 동반 시 기록 |
+| `payload` | JSONB | NOT NULL | 이벤트 본문 (스키마는 event_type별) |
+| `inverse_payload` | JSONB | NULL | Undo/Revive용 역방향 이벤트 본문 |
+| `created_at` | TIMESTAMP | NOT NULL DEFAULT now() | append 시각 |
+
+**제약**:
+- `UNIQUE (table_id, seq)` — seq 중복 방지
+- `UNIQUE (idempotency_key) WHERE idempotency_key IS NOT NULL` — 방어적 중복 차단
+- **append-only**: UPDATE/DELETE는 DB 레벨에서 차단 (trigger 또는 역할 권한). Undo는 새 inverse 이벤트를 append.
+
+**인덱스**:
+- `(table_id, seq DESC)` — replay 쿼리 최적화
+- `(correlation_id)` — 분산 트레이싱
+- `(event_type, created_at)` — 이벤트 종류별 조회
+
+**보존**: 1년 (감사 규정). 이후 cold storage로 아카이브.
+
+**Phase 1 SQLite**: JSONB → TEXT(JSON), BIGSERIAL → INTEGER PRIMARY KEY AUTOINCREMENT.
```

## 영향 분석

- **Team 2 (자기)**: `src/db/init.sql` 두 테이블 추가. EventRepository, IdempotencyStore 클래스 구현. 마이그레이션(Alembic Phase 3부터). 약 10시간.
- **Team 1 (Lobby)**: 영향 없음 (DB 직접 접근 없음, REST API 경유). 단 replay 엔드포인트 소비.
- **Team 4 (CC)**: 영향 없음 (동일 이유).
- **`src/db/init.sql` 동기화 의무**: CLAUDE.md L16 "권위 DDL — DATA-04와 일치 필수" — 본 CCR 승격 후 즉시 동기화.
- **마이그레이션**: 신규 테이블이므로 기존 데이터 영향 0.

## 대안 검토

1. **Outbox 패턴 (별도 outbox 테이블)** — 이벤트 발행 보장에는 좋으나, audit 기능과 이벤트 소싱을 분리하면 중복 스토리지. `audit_events` 를 outbox 로 겸용하기로 채택.
2. **이벤트 스토어 전용 DB (EventStoreDB 등)** — Phase 1 scope 초과. 탈락.
3. **기존 감사 로그 테이블 확장** — BO-03의 감사 로그와 세부가 다름 (감사=사람 액션 기록, audit_events=상태 변경 전체). 혼용하면 오남용. 분리 유지.

## 검증 방법

- **스키마**: Alembic upgrade/downgrade 테스트
- **단위**: EventRepository append → 동일 (table_id, seq) 중복 시 DB 레벨 차단
- **통합**: 좌석 할당 수행 → audit_events 레코드 1건 생성 → WebSocket 브로드캐스트의 seq와 일치
- **멱등성**: 동일 Idempotency-Key 중복 요청 → `idempotency_keys` 조회 후 캐시된 응답 재생, audit_events 추가 레코드 0

## 승인 요청

- [ ] Conductor 승인
- [ ] Team 1 기술 검토 (replay 엔드포인트 소비 영향 확인)
- [ ] Team 4 기술 검토
- [ ] 종속 CCR (`idempotency-key`, `ws-event-seq`) 선행 또는 동시 승인
