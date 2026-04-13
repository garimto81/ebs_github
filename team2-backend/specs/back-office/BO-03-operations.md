# BO-03 Operations — 감사 로그 & 리포팅

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | BO-08 + BO-11 병합. 운영 정책/카탈로그만 유지, API 엔드포인트는 API-01로 이관 |
| 2026-04-10 | 감사 및 복구 보강 | audit_events 이벤트 스토어 관점 추가, 감사 로그-핸드 리플레이 관계 명확화, §4 손실 데이터 복구 절차 신설 (WSOP LIVE Confluence 대조) |
| 2026-04-10 | CCR 의존 축소 | `audit_events`, `idempotency_keys`, saga 등 계약 변경 의존 항목을 CCR-001/003/010 참조로 축소. §4 복구 절차 중 독립 영역(Scenario B WSOP sync cursor, Scenario C Redis 손실)만 상세 유지 |
| 2026-04-10 | CCR 활성화 (반영 완료) | CCR-001/003/010 모두 contracts 반영 완료. §1.1 기록 대상 매트릭스, §1.2 3-way 관계, §2 details JSON 필드, §4.1/§4.4 시나리오, §4.5 책임 매트릭스, §5 유저스토리 전면 복원. 정본은 contracts/ 를 참조 |

---

## 개요

BO의 운영 관련 정책 — 감사 로그 기록 대상/보존 정책, 리포트 카탈로그, 내보내기 형식을 정의한다.

> API 엔드포인트: API-01 Backend Endpoints §감사 로그, §리포트
> 데이터 모델: DATA-02 Entities §audit_logs

---

## Part 1: 감사 로그

## 1. 기록 대상 매트릭스

### 1.1 기록 대상

| 분류 | 이벤트 | 기록 내용 |
|------|--------|----------|
| **인증** | 로그인/로그아웃 | 사용자, IP, 역할, 시각 |
| **인증** | 로그인 실패 | 이메일, IP, 실패 사유, 시각 |
| **인증** | 2FA 활성화/비활성화 | 사용자, 시각 |
| **사용자** | 사용자 생성/수정/비활성화 | 대상 사용자, 변경 내용, 실행 Admin |
| **사용자** | 역할 변경 | 이전/이후 역할, 실행 Admin |
| **대회** | Series/Event/Flight 생성/수정/삭제 | 대상 엔티티, 변경 내용, 실행 Admin |
| **테이블** | 테이블 CRUD | 대상 테이블, 변경 내용, 실행 Admin |
| **테이블** | 상태 전환 | 이전/이후 상태, 실행 사용자 |
| **플레이어** | 플레이어 등록/제거 | 대상 플레이어, 테이블, 실행 Admin |
| **좌석** | 좌석 배치/변경/비우기 | 이전/이후 좌석, 플레이어, 실행 Admin |
| **RFID** | 리더 할당/해제 | 리더 ID, 테이블, 실행 Admin |
| **설정** | Config 변경 | 키, 이전/이후 값, 실행 Admin |
| **장애** | 장애 발생/복구 | 장애 유형, 시각, 영향 범위 |
| **CC** | CC 연결/해제 | table_id, operator, 시각 |
| **WSOP LIVE 동기화** | 폴링 성공/실패/회복 | sync_cursor 이전/이후, 에러 유형 (BO-02 §7.1 Fallback Queue) |
| **좌석 이력** | 할당/해제/이동 | `audit_events` 에 `seat_assigned`/`seat_released`/`seat_moved` 이벤트 + `inverse_payload` (CCR-001 활성) |
| **리밸런싱** | Saga 단계별 진행/보상 | `audit_events` 에 `rebalance_step_started`/`rebalance_step_completed`/`rebalance_step_compensated` (CCR-010 활성) |
| **Undo/Revive** | 역방향 이벤트 | `audit_events` 에 inverse 이벤트 append + `causation_id` 로 원 이벤트 연결 (CCR-001 활성) |

> **기록 분류**: 사람 관리 액션(로그인, 권한 변경 등)은 기존 `audit_logs`, 상태 변경 이벤트 소싱(좌석/리밸런싱/Undo)은 `audit_events`(DATA-04 §5.2). 두 테이블은 `correlation_id` 로 묶인다.

### 1.2 기록하지 않는 것 + 감사-리플레이 관계

| 제외 대상 | 이유 |
|----------|------|
| 핸드 개별 액션 (Fold, Bet 등) | `hand_actions` 테이블에 별도 저장 (이벤트 소싱) |
| API 읽기 요청 (GET) | 볼륨 과다, 보안 가치 낮음 |
| WebSocket 하트비트 | 시스템 레벨 로그에 별도 기록 |

**감사 로그 / 이벤트 스토어 / 게임 액션 3-way 구분** (2026-04-10 명확화, CCR-001 활성):

| 테이블 | 역할 | 기록 대상 | 정본 |
|--------|------|----------|------|
| `audit_logs` | 사람/시스템의 *관리 액션* 감사 | 로그인, 사용자 생성, 권한 변경, Config 변경 | DATA-04 §4 |
| `audit_events` | 모든 상태 변경의 append-only **이벤트 스토어** | 좌석/블라인드/토너먼트 상태 전이, 리밸런싱 saga, Undo/Revive, WSOP 동기화 복구 | DATA-04 §5.2 (CCR-001) |
| `hand_actions` | 핸드 진행 중 *게임 액션* | Fold, Call, Raise, Check, All-in | DATA-04 §3 |

**핸드 리플레이 복구 시나리오**:
1. `audit_events` 에서 해당 테이블의 `table_config_changed`/`blind_level_changed`/`seat_assigned` 이벤트를 `seq` 순으로 apply → 핸드 시작 당시 테이블 상태 재구성
2. `hand_actions` 에서 해당 `hand_id` 의 액션을 순차 apply → 카드/베팅 재생
3. 두 소스를 `correlation_id` 로 묶어 전체 핸드 문맥을 복원

→ `audit_events` 와 `hand_actions` 의 역할이 명확히 분리되어 이중 기록 없음.

---

## 2. details JSON 구조

모든 감사 로그의 `details` JSON은 **상관관계 필드**를 기본 포함한다. 분산 추적, 멱등성 검증, Undo 체인 재구성에 필수.

### 2.1 공통 필드 (2026-04-10 신규)

| 필드 | 타입 | 설명 | 근거 |
|------|------|------|------|
| `correlation_id` | string | 단일 사용자 작업 단위 식별자 (여러 이벤트 묶음). 요청 진입점에서 생성·전파 | 독립 |
| `causation_id` | string | 직전 원인 이벤트의 id (event sourcing 체인, Undo 추적) | CCR-001 활성 |
| `idempotency_key` | string | 요청이 `Idempotency-Key` 헤더를 동반했을 때 기록 | CCR-003 활성 |
| `actor_user_id` | string | 주체 사용자. 시스템 이벤트는 null | 독립 |
| `ip` | string | 주체 IP (인증 이벤트만) | 독립 |

### 2.2 예시

**테이블 상태 변경 (`audit_logs`):**
```json
{
  "field": "status",
  "old_value": "SETUP",
  "new_value": "LIVE",
  "table_name": "Table 1",
  "correlation_id": "corr-20260410-abc123",
  "causation_id": null,
  "idempotency_key": "a1b2c3d4-uuid",
  "actor_user_id": "u-admin-01"
}
```

**좌석 이동 (`audit_events`, Undo 가능):**
```json
{
  "table_id": "tbl-01",
  "seq": 15002,
  "event_type": "seat_moved",
  "actor_user_id": "u-admin-01",
  "correlation_id": "corr-rebalance-001",
  "causation_id": "evt-15001",
  "idempotency_key": "rebalance-sg-20260410-001",
  "payload": {
    "player_id": "p-123",
    "from_table": "tbl-01",
    "from_seat": 5,
    "to_table": "tbl-05",
    "to_seat": 3
  },
  "inverse_payload": {
    "player_id": "p-123",
    "from_table": "tbl-05",
    "from_seat": 3,
    "to_table": "tbl-01",
    "to_seat": 5
  }
}
```

**설정 변경 (`audit_logs`):**
```json
{
  "field": "system.rfid_mode",
  "old_value": "mock",
  "new_value": "real",
  "correlation_id": "corr-20260410-cfg-001",
  "actor_user_id": "u-admin-01"
}
```

---

## 3. 보존 정책

| 항목 | 값 | 설명 |
|------|:--:|------|
| 보존 기간 | 시리즈 종료 후 1년 | 감사 요구사항 충족 |
| 아카이빙 | 1년 경과 → 압축 아카이브 | 조회 불가, 필요 시 복원 |
| 삭제 | 아카이브 후 2년 | 영구 삭제 |
| 수정 금지 | append-only | 기존 로그 수정/삭제 API 없음 |

---

## 4. 손실 데이터 복구 절차 (신규 2026-04-10, CCR 활성 후 전면 복원)

방송 환경은 완전 가용성을 보장할 수 없다. 부분 장애 발생 시 운영자가 실행할 수 있는 **표준 복구 시나리오**를 정의한다. 모든 시나리오는 `audit_events` 이벤트 스토어(DATA-04 §5.2, IMPL-10 §7)를 주 복구 소스로 사용한다.

### 4.1 Scenario A: CC 크래시 후 TableState 재구성

**트리거**: Command Center(CC) 프로세스 크래시 또는 네트워크 장기 단절.

**절차**:
1. CC 자동 재시작 (IMPL-06 §4.3 로컬 모드 유지)
2. CC 재기동 시 `GET /api/v1/tables/{id}/events?since=0&limit=500` 호출 — API-01 replay 엔드포인트 (CCR-015)
3. 응답의 `events[]` 를 `seq` 순서로 apply → Riverpod state 재구성
4. 응답의 `has_more=true` 이면 `since={last_seq}` 로 다음 페이지 호출, `has_more=false` 가 나올 때까지 반복
5. 최종 `seq` 를 메모리에 기록하고 WebSocket 재연결
6. 이후 실시간 이벤트는 `seq` 연속성 검증 (IMPL-10 §4.2)

**페이징 규칙** (IMPL-10 §4.2 및 API-01 replay 계약 준수):

| 항목 | 값 |
|------|----|
| `limit` 기본값 | 500 |
| `limit` 최대값 | 2000 (초과 시 400) |
| 응답 필드 | `events[]`, `last_seq`, `has_more` |
| 레이트 리미트 | 10 req/sec per `(table_id, client)` |
| OOM 방지 | CC 클라이언트는 받은 페이지를 **순차 apply 후 메모리에서 해제**, 전체 버퍼링 금지 |
| 대회 24h 상한 가정 | `audit_events` 최대 ~50만 rows/table → 약 1000 페이지. 클라는 페이지 당 apply 시 50ms 이내 처리 |

**수용 기준**: 10분 내 복구, GameState 일치율 100%, 페이징 중 OOM 0건.

**Edge case**: 복구 중 운영자가 액션 시도 시 IMPL-04 라우트 가드가 임시 잠금 → "복구 중" 모달 + 진행률(`처리 seq / last_seq`) 표시.

### 4.2 Scenario B: BO ↔ WSOP LIVE 동기화 분기

**트리거**: WSOP LIVE 폴링 장기 실패 후 재개. BO와 WSOP LIVE 간 토너먼트/플레이어 데이터 분기 발생.

**절차**:
1. BO-02 §7.1 서킷브레이커 HALF_OPEN 전환
2. `sync_cursor:{entity}` 마지막 성공 지점에서 delta 요청 재개
3. 변경분 merge — **BO 우선 규칙**: BO 측에서 수정된 필드는 WSOP LIVE 값보다 우선 (BO-02 §3 충돌 해결 LWW)
4. `audit_events` 에 `wsop_sync_resolved` 이벤트 append (`correlation_id` 로 장애 구간 그룹화)
5. 운영자에게 분기 요약 알림

**수용 기준**: 동기화 cursor 에 기록된 진행 지점만큼 재처리, 중복 0, 누락 0.

**Edge case**: 동일 레코드를 양쪽에서 동시 수정한 경우 → `conflict_detected` 이벤트 + Admin 확인 대기.

### 4.3 Scenario C: Redis 캐시 손실

**트리거**: Redis 장애, 재시작, flush. 캐시 계층 전체 소실.

**절차**:
1. Circuit Breaker OPEN → 모든 요청을 DB 직접 조회로 우회
2. p95 응답시간 degrade 허용 (방송 중에도 중단 없이 진행)
3. Redis 복구 후 캐시는 lazy 로딩 (Write-Through 재작동)
4. 일시 중복 응답/stale 가능성을 감수 (TTL 안전망)

**수용 기준**: Redis 전면 장애 중에도 BO API 연속 응답, p95 < 1.5×평상시.

**Edge case**: 분산락(`lock:*`) 소실되지만 fencing token으로 stale 요청 차단. `idempotency_keys` 는 DB 백업(DATA-04 §5.1)에서 재생성. Phase 1 SQLite 환경에서 Redis 미사용 시 본 시나리오 비대상.

### 4.4 Scenario D: 부분 롤백 (Saga Compensation Failure)

**트리거**: `POST /tables/rebalance` (API-01, CCR-010) saga 중간 실패 → compensating action 실행 중 또 실패 → 부분 상태 지속.

**절차**:
1. API 응답 `500 Manual intervention required` (`status: "compensation_failed"`) + `audit_cursor: {from_seq, to_seq}` 반환 — 계약 정본 참조
2. 운영자 대시보드에 경고 모달 + `saga_id` 표시
3. Admin이 `audit_events` 조회: `SELECT * FROM audit_events WHERE table_id=? AND seq BETWEEN :from AND :to ORDER BY seq`
4. saga 단계별 `status` 를 확인하여 수동 복구 경로 선택:
   - **재시도 안전**: 동일 `saga_id` + Idempotency-Key 로 재실행 (saga 재개)
   - **수동 정정**: Admin이 구체적 좌석/상태를 수동 수정 → 해당 변경은 `manual_intervention` 이벤트로 `audit_events` 에 기록
5. 복구 완료 후 `manual_intervention_resolved` 이벤트 append

**수용 기준**: 10분 내 Admin 수동 개입으로 일관성 복원. 잔여 부분 상태 0.

**Edge case**: saga 로그 자체가 손상된 경우 → DB 백업에서 해당 테이블만 point-in-time 복원.

### 4.5 복구 책임 매트릭스

| 시나리오 | 자동 복구 | 운영자 개입 | 개발팀 개입 |
|----------|:--------:|:----------:|:----------:|
| A: CC 크래시 | O (자동 replay) | — | — |
| B: WSOP 동기화 분기 | O (부분) | 확인 필요 | 분기 대량 시 |
| C: Redis 손실 | O (degraded) | 모니터 | — |
| D: Saga 보상 실패 | X | **필수** | 로그 분석 |

### 4.6 DR 훈련

Phase 1 출시 전 4개 시나리오(A~D) 전부 드라이런 훈련 완료를 **Phase 1 진입 게이트** 로 설정 (IMPL-10 §10 항목 #13).

---

## 5. 유저 스토리

| # | As a | When | Then | Edge Case |
|:-:|------|------|------|-----------|
| A-1 | Admin | 감사 로그 메뉴 진입 | 최근 로그 시간순 목록 표시 | 로그 0건: "기록된 감사 로그가 없습니다" |
| A-2 | Admin | 시간 범위 + 사용자 필터 | 필터 조건에 맞는 로그만 표시 | 결과 0건: "조건에 맞는 로그가 없습니다" |
| A-3 | Admin | 로그 항목 클릭 | 상세 (이전값/이후값, IP, 시각, correlation_id, causation_id) 표시 | — |
| A-4 | Admin | correlation_id 링크 클릭 | `audit_logs` + `audit_events` 전체 범위에서 동일 correlation 이벤트 조회 | 분산 트레이싱 연동 |
| A-5 | Admin | 복구 대시보드 진입 (Scenario D) | 미해결 saga 목록 + `audit_cursor` 기반 단계별 상태 | 없으면 "정상" |
| A-6 | Admin | `audit_events` 특정 `seq` 범위 조회 | 단계별 이벤트 + inverse_payload 표시 | replay 및 감사 용 |
| A-7 | Operator | 감사 로그 접근 시도 | 403 Forbidden | Admin 전용 |

---

## Part 2: 리포팅

## 6. 리포트 카탈로그

| 리포트 | 설명 | 데이터 소스 | 대상 |
|--------|------|-----------|:----:|
| **Event Summary** | 이벤트별 전체 요약 (핸드 수, 플레이어 수, 소요 시간) | `events`, `hands`, `hand_players` | Admin |
| **Table Activity** | 테이블별 활동 요약 (핸드 수, 평균 팟, 평균 소요 시간) | `tables`, `hands` | Admin |
| **Player Statistics** | 플레이어별 VPIP/PFR/AGR/P&L 종합 | `hand_players`, `hand_actions` | Admin |
| **Hand Distribution** | 핸드 유형별 분포 (게임 종류, 팟 크기, 승리 방식) | `hands`, `hand_players` | Admin |
| **RFID Health** | RFID 리더별 인식률, 에러 빈도, 가동 시간 | 실시간 로그 | Admin |
| **Operator Activity** | Operator별 핸드 처리 수, 평균 핸드 시간 | `hands`, `audit_logs` | Admin |

---

## 7. Dashboard 요약 데이터

| 지표 | 계산 | 갱신 주기 |
|------|------|----------|
| 오늘 총 핸드 수 | `hands` COUNT (today) | 실시간 |
| 활성 테이블 수 | `tables` COUNT (status=LIVE) | 실시간 |
| 활성 플레이어 수 | `table_seats` COUNT (status=OCCUPIED) | 실시간 |
| 평균 핸드 소요 시간 | `hands.duration_sec` AVG (today) | 5분 |
| 평균 팟 크기 | `hands.pot_total` AVG (today) | 5분 |
| RFID 에러 건수 | 에러 로그 COUNT (today) | 실시간 |

---

## 8. 내보내기

### 8.1 형식

| 형식 | 용도 | 최대 크기 |
|------|------|----------|
| **CSV** | 스프레드시트 분석 | 10MB (약 100,000행) |
| **JSON** | 프로그래밍 연동 | 10MB |

### 8.2 대상

| 데이터 | 포함 필드 |
|--------|----------|
| 핸드 목록 | hand_number, game_type, pot, winner, duration, timestamp |
| 플레이어 통계 | name, hands_played, vpip, pfr, agr, total_pnl |
| 테이블 활동 | table_name, hands_count, avg_pot, avg_duration, status |
| 감사 로그 | timestamp, user, action, entity, details |

---

## 9. 역할별 접근 매트릭스

| 역할 | Dashboard 조회 | 상세 리포트 | 내보내기 | 감사 로그 |
|:----:|:-------------:|:----------:|:--------:|:--------:|
| Admin | O | O | O | O |
| Operator | X | X | X | X |
| Viewer | O (읽기) | O (읽기) | X | X |

---

## 비활성 조건

- BO 서버 미실행: 감사 로그 기록/조회, 리포트 조회 불가
- 핸드 데이터 0건: 리포트 생성 불가 (빈 상태 안내)
- Operator: 감사 로그, 리포트 접근 불가
- DB 용량 부족: 경고 후 오래된 로그 강제 아카이빙

## 영향 받는 요소

| 영향 대상 | 관계 |
|----------|------|
| BO-01 Core | 인증/역할/대회/테이블 변경 기록 |
| BO-02 Game Engine | 핸드 데이터 = 리포트 주요 소스 |
| BS-02-lobby.md | Lobby 감사 로그 항목 정의 |
