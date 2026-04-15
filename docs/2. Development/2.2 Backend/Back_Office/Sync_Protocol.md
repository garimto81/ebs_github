---
title: Sync Protocol
owner: team2
tier: internal
legacy-id: BO-02
last-updated: 2026-04-15
---

# BO-02 Sync Protocol — 동기화 프로토콜

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | BO-09 + BO-10 병합. 동기화 정책, 오프라인 대응, 충돌 해결, WSOP LIVE 폴링/UPSERT/장애 대응, Mock 모드 |
| 2026-04-10 | 서킷브레이커/Fallback Queue | §7.1 WSOP LIVE 폴링 실패 시 Circuit Breaker + `sync:wsop:pending` Redis Stream fallback queue + cursor 기반 delta 재개 (IMPL-10 §3.3 / GAP-BO-009 정합) |
| 2026-04-14 | L0 중복 제거 | §5 폴링 주기·§5.2 config 키·§6 UPSERT 규칙을 `contracts/api/API-01` Part II 인용으로 축약. team2 구현 노트만 유지. drift 위험 제거 |

---

## 개요

Lobby↔BO↔CC 동기화 + WSOP LIVE 외부 데이터 수집의 **정책과 장애 대응**을 정의한다.

> WebSocket 이벤트 상세: API-05 WebSocket Events
> WSOP LIVE API 계약: API-01 Part II §7-15 (WSOP LIVE Integration)

---

## 1. 동기화 개요

| 채널 | 방향 | 역할 |
|------|------|------|
| **REST API** | Lobby → BO | CRUD 작업 (생성/수정/삭제) |
| **WebSocket** | CC ↔ BO ↔ Lobby | 실시간 이벤트 (핸드, 상태, 설정 변경) |
| **폴링** | BO → WSOP LIVE | 외부 데이터 주기적 수집 |

> 상세: API-05 §1 연결 아키텍처, API-01 REST 엔드포인트

---

## 2. 오프라인 대응

### 2.1 CC 로컬 버퍼

CC가 BO WebSocket 연결이 끊긴 상태에서도 **게임 진행을 중단하지 않는다**.

| 상태 | CC 동작 | 데이터 처리 |
|------|---------|------------|
| **정상** | WebSocket으로 즉시 전송 | BO DB에 실시간 기록 |
| **연결 끊김** | 로컬 SQLite 버퍼에 저장 | 핸드/액션 로컬 영구 저장 |
| **재연결** | 버퍼 데이터 일괄 전송 (FIFO) | BO DB에 순서대로 INSERT |
| **재연결 후** | 실시간 모드 복귀 | 버퍼 비움 확인 후 전환 |

**로컬 버퍼 규격:**

| 항목 | 값 | 설명 |
|------|:--:|------|
| 저장소 | CC 로컬 SQLite | 앱 내부 DB |
| 최대 크기 | 100MB | 약 10,000 핸드 분량 |
| 보존 기간 | 재연결 + 전송 완료까지 | 전송 확인 후 삭제 |
| 순서 보장 | seq 필드 기준 FIFO | 순서 역전 방지 |

### 2.2 Lobby 오프라인 동작

| 장애 유형 | Lobby 동작 | UI 표시 |
|----------|-----------|---------|
| BO 서버 다운 | 읽기 전용 캐시 표시, CRUD 비활성 | "서버 연결 끊김" 배너 |
| WebSocket 끊김 | REST 폴링 폴백 (5초 주기) | "실시간 업데이트 중단" 배너 |
| 네트워크 전체 단절 | 마지막 캐시 표시, 모든 기능 비활성 | "네트워크 끊김" 전체 오버레이 |

> 참조: BS-02-lobby.md §장애 시 기능 축소 매트릭스

---

## 3. 충돌 해결

### 3.1 동시 수정 규칙

| 시나리오 | 규칙 | 이유 |
|---------|------|------|
| Lobby 플레이어 수정 + CC 칩 변경 | **양쪽 모두 반영** — 필드가 다름 | 이름과 칩은 독립 필드 |
| Lobby 블라인드 변경 + CC 핸드 진행 중 | **CC 핸드 종료 후 적용** | 핸드 중간 블라인드 변경 금지 |
| 두 Admin이 동시에 같은 설정 변경 | **Last Write Wins** + 감사 로그 | 낙관적 동시성 |
| CC 로컬 버퍼 + BO에 이미 같은 핸드 존재 | **중복 무시** (hand_id 기준) | 멱등성 보장 |
| WSOP LIVE API 데이터 + 수동 입력 | **API 우선** (source = 'api') | 외부 데이터가 권위 소스 |

### 3.2 충돌 감지 메커니즘

| 메커니즘 | 적용 대상 | 동작 |
|---------|----------|------|
| `updated_at` 타임스탬프 비교 | 테이블/플레이어/설정 | 구버전 덮어쓰기 방지 |
| `seq` 시퀀스 번호 | WebSocket 메시지 | 순서 역전 감지 |
| `hand_id` 유니크 키 | 핸드 데이터 | 중복 INSERT 방지 |
| `source` 필드 | 대회/플레이어 | manual vs api 구분 |

### 3.3 충돌 해결 경우의 수

| CC 상태 | BO 상태 | 충돌 유형 | 해결 |
|:-------:|:-------:|----------|------|
| 온라인 | 정상 | 없음 | 실시간 동기화 |
| 오프라인 → 재연결 | 정상 | 시간 갭 | 버퍼 순차 전송, 중복 무시 |
| 온라인 | DB 복원됨 | 데이터 유실 | CC 로컬 캐시에서 재전송 |
| 오프라인 | 오프라인 | 양쪽 유실 | 수동 복구 (최악 시나리오) |

---

## 4. 데이터 정합성 검증

### 4.1 자동 검증

| 검증 | 주기 | 대상 | 동작 |
|------|------|------|------|
| 핸드 카운트 일치 | 핸드 종료 시 | CC 로컬 vs BO DB | 불일치 시 경고 로그 |
| 칩 합계 검증 | 핸드 종료 시 | 전체 칩 합 = 시작 칩 합 | 불일치 시 `CHIP_MISMATCH` 경고 |
| 시퀀스 연속성 | 메시지 수신 시 | seq 번호 갭 검사 | 갭 발견 시 누락 메시지 재요청 |

### 4.2 수동 검증 도구

| 도구 | 트리거 | 용도 |
|------|--------|------|
| `/sync/verify` API | Admin 수동 호출 | CC↔BO 데이터 정합성 리포트 |
| `/sync/force` API | Admin 수동 호출 | CC 로컬 데이터를 BO에 강제 동기화 |
| `/sync/status` API | Lobby Dashboard | 각 CC의 동기화 상태 (지연, 버퍼 크기) |

---

## 5. WSOP LIVE 폴링 전략

폴링 주기·설정 키·`source` 필드 의미·UPSERT 규칙·수동→API 전환 매칭 규칙은 모두 **`contracts/api/API-01` Part II §7-8, §13**을 정본으로 한다. 이 문서는 정본을 재서술하지 않는다.

**team2 구현 노트** (정본에 없는 운영 결정만):

| 항목 | 결정 |
|------|------|
| 폴링 워커 | APScheduler `BackgroundScheduler` (IMPL-05 DI로 주입, IMPL-08 §Mock 교체 가능) |
| 주기 런타임 조정 | `system.wsop_api_poll_sec.*` config (API-01 §13) 변경 시 다음 tick부터 반영. 진행 중 작업은 완료 후 재스케줄 |
| 폴링 disable 처리 | `system.wsop_api_enabled=false` → scheduler `pause()`, 큐는 비우지 않음 (재활성 시 재개) |
| Manual ↔ API 매칭 UI | Admin 확인 단계는 Lobby Settings → "WSOP Sync" 탭 (BS-03 §매칭) — 자동 머지 금지 |

> **변경 영향 시**: `contracts/api/API-01` Part II §7-8, §13의 폴링 주기·config 키·UPSERT 규칙 변경은 CCR 절차로만 가능. 본 문서 §5 단독 변경 금지.

---

## 6. (Reserved)

> 구 §6 "WSOP LIVE UPSERT 규칙"은 §5에 통합되었다. 외부 참조 안정성을 위해 §7 이후 번호는 유지한다.

---

## 7. 장애 대응

### 7.1 API 연결 끊김 (Circuit Breaker + Fallback Queue)

WSOP LIVE 폴링은 **Circuit Breaker**(IMPL-10 §3.3)로 감싸져 있으며, 실패 시 `sync:wsop:pending` **Redis Stream**으로 요청이 이동한다.

| 상황 | BO 동작 | Lobby 영향 |
|------|---------|-----------|
| API 호출 실패 1회 | 재시도 (exponential: 200ms/1s/3s/10s/30s, IMPL-10 §3.2) | 영향 없음 |
| 실패율 ≥ 50% (20 req window) | Circuit Breaker **OPEN**, 이후 요청은 Fallback Queue에 적재 | 노랑 배너 "WSOP LIVE 일시 장애" |
| OPEN 30s 경과 | HALF_OPEN, 1 req 시범 | — |
| HALF_OPEN 성공 | CLOSED 복귀, Fallback Queue 드레인 시작 | 배너 제거 |
| HALF_OPEN 실패 | OPEN 재진입 | 배너 유지 |
| 장기 끊김 (>10min) | 캐시 데이터로 정상 운영 + Admin 경보 | 신규 데이터만 미반영 |

**Fallback Queue 동작**:

- **큐 형태**: Redis Stream `sync:wsop:pending` — ordering + consumer group 지원. 구현 백엔드(Redis Stream vs. SQLite journal table 등)는 team2 아키텍처 결정(옵션 1/2) 확정 이후 최종화. 현 단계에서는 **논리적 스펙**만 유지.

- **메시지 envelope 스키마**:
  ```json
  {
    "msg_id": "1713000000-0",                  // Redis Stream entry ID 또는 UUID
    "entity": "series | event | flight | player | seat",
    "cursor": "2026-04-10T12:34:56.789Z",      // 마지막 성공 동기화 시점 (ISO 8601)
    "requested_at": "2026-04-10T12:34:57.123Z",
    "retry_count": 0,                          // 0부터 시작, 성공 시 소거
    "last_error": null,                        // 직전 시도 실패 이유 (nullable)
    "correlation_id": "corr-cb-20260410-ab1",  // 장애 구간 묶음 ID
    "causation_msg_id": null                   // 이전 재시도 메시지 ID (체이닝)
  }
  ```

- **재개 cursor 규칙**:
  - SSOT: Redis `sync_cursor:{entity}` 또는 DB `sync_cursors(entity PK, cursor, updated_at)` 테이블
  - 복구 시 해당 cursor 를 기준으로 `since=cursor` 파라미터로 WSOP LIVE delta 요청
  - 성공 수신 후 `sync_cursor:{entity}` 를 새 cursor 로 업데이트 (commit 후)
  - **cursor 롤백 금지**: 항상 단조증가. 만약 WSOP 응답이 더 오래된 cursor 를 반환하면 drift 경고 로그

- **재처리 흐름**:
  1. Circuit Breaker HALF_OPEN → 1 req 성공 → CLOSED
  2. Drainer worker 가 `sync:wsop:pending` 에서 `entity` 별 가장 오래된 메시지부터 순차 pop
  3. 각 메시지의 `cursor` 기준 delta 재요청 → 성공 시 ACK, 실패 시 `retry_count++` 후 재적재 (최대 5회)
  4. 5회 초과 메시지는 `sync:wsop:deadletter` 로 이동, Admin 경보
  5. 재처리 중 중복 레코드 발생 시 UPSERT 규칙(§6)으로 흡수

- **큐 관리 임계값**:
  | 지표 | 임계 | 조치 |
  |------|------|------|
  | 큐 길이 | > 10,000 | Admin 경보 + 폴링 속도 자동 감속 |
  | 가장 오래된 메시지 age | > 10분 | 경보 + drainer 병렬 스케일 아웃 요청 |
  | `sync_cursor_lag_seconds` | > 5분 | `wsop_sync_lag` 대시보드 경고 |
  | deadletter 큐 | ≥ 1건 | Admin 수동 개입 알림 |

- **복구 완료 기록**: drainer 가 `entity` 별 모든 메시지를 소거하고 `sync_cursor` 가 "현재 시각 - 30s" 이내로 따라잡으면 `audit_events` 에 `wsop_sync_resumed` 이벤트 append. `correlation_id` 로 장애 구간 전체 묶음 (CB OPEN 시점 ~ 재개 시점).

**메트릭**:
- `wsop_live_cb_state{state=closed|half_open|open}` — Prometheus gauge
- `wsop_live_fallback_queue_length` — Prometheus gauge
- `wsop_live_sync_cursor_lag_seconds` — Prometheus gauge

> 세부 복구 시나리오: BO-03 §4.2 Scenario B "BO ↔ WSOP LIVE 동기화 분기" 참조.

### 7.2 데이터 불일치

| 시나리오 | 해결 |
|---------|------|
| API 플레이어 이름 변경 | API 값으로 자동 업데이트 |
| API Event 삭제 | BO에서 삭제하지 않음 (soft delete + 경고) |
| API 데이터가 BO 수동 수정과 충돌 | 수동 수정 필드 보호, API 필드만 업데이트 |

---

## 8. Mock 데이터 모드

WSOP LIVE API 연동 전 또는 테스트/데모 환경에서 가상 데이터로 운영.

| 데이터 | 생성 방식 | 수량 |
|--------|----------|:----:|
| Series | Seed 스크립트 | 3개 |
| Event | Seed 스크립트 | 시리즈당 10개 |
| Flight | Seed 스크립트 | 이벤트당 2~4개 |
| Player | Seed 스크립트 | 100명 |

| 메서드 | 경로 | 권한 | 설명 |
|:------:|------|:----:|------|
| POST | `/sync/mock/seed` | Admin | Mock 데이터 시드 생성 |
| DELETE | `/sync/mock/reset` | Admin | Mock 데이터 초기화 |

---

## 비활성 조건

- BO 서버 미실행: 모든 동기화 중단, CC는 로컬 모드
- `wsop_api_enabled=false`: WSOP LIVE 자동 폴링 비활성 (수동 CRUD만)
- API URL 미설정: WSOP LIVE 동기화 기능 전체 비활성
- 네트워크 전체 단절: WSOP LIVE 폴링 중단, Lobby↔BO 통신 불가

## 영향 받는 요소

| 영향 대상 | 관계 |
|----------|------|
| PRD-EBS_BackOffice §2 | 데이터 흐름의 상세 프로토콜 (3-앱 관계 SSOT) |
| BS-02-lobby.md | Lobby 장애 시 기능 축소 매트릭스 |
| BS-06-00-triggers.md | BO 소스 이벤트 정의 |
| API-05 WebSocket Events | WebSocket 메시지 포맷/생명주기 SSOT |
| API-01 Part II §7-15 (WSOP LIVE Integration) | WSOP LIVE API 계약 SSOT |
