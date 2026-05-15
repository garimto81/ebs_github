---
title: Logging
owner: team2
tier: internal
legacy-id: IMPL-07
last-updated: 2026-04-15
confluence-page-id: 3832971440
confluence-parent-id: 3811770578
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3832971440/Logging
---

# IMPL-07 Logging — 로그 레벨, 필드, 저장 전략

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 로그 레벨, 구조화 필드, 저장/전송, 보존 정책 |
| 2026-04-10 | 상관관계 필드 추가 | correlation_id, causation_id, idempotency_key, seq 표준화 (IMPL-10 §7 / BO-03 §2 정합) |
| 2026-04-10 | CCR-001/003/015 반영 | contracts 반영 완료 — `correlation_id`/`causation_id`/`idempotency_key`/`seq` 필드 확정, §4.1 audit_events 3-way 구분 확정 (중간 "의존 축소" 단계는 git log 참조) |

---

## 개요

이 문서는 EBS의 **로깅 전략**을 정의한다. CC, BO, Game Engine, RFID HAL의 로그를 구조화하여 BO에 집중 저장하고, 운영 중 문제 진단과 핸드 리플레이에 활용한다.

> 참조: IMPL-06 §5 에러 보고 체계, BO-08 감사 로그, API-05 WebSocket 프로토콜

---

## 1. 로그 레벨

### 1.1 5-Level 체계

| 레벨 | 코드 | 용도 | 예시 |
|------|:----:|------|------|
| **DEBUG** | 10 | 개발/디버깅 전용. 상세 내부 동작 | Provider 갱신 상세, 이벤트 페이로드 전체 |
| **INFO** | 20 | 정상 동작 기록. 주요 이벤트 | 핸드 시작/종료, 카드 감지, 사용자 로그인 |
| **WARNING** | 30 | 주의 필요. 정상 동작 유지 | 네트워크 재연결, 중복 카드 감지, 느린 응답 |
| **ERROR** | 40 | 기능 실패. 운영자 개입 필요 | RFID 연결 실패, API 에러, 핸드 상태 불일치 |
| **CRITICAL** | 50 | 시스템 장애. 즉시 대응 | 앱 크래시, DB 손상, 인증 시스템 실패 |

### 1.2 환경별 기본 로그 레벨

| 환경 | CC | BO | Engine |
|------|:--:|:--:|:------:|
| 개발 (dev) | DEBUG | DEBUG | DEBUG |
| 스테이징 (staging) | INFO | INFO | INFO |
| 프로덕션 (prod) | WARNING | INFO | INFO |
| 방송 중 (live) | WARNING | WARNING | INFO |

> 런타임 변경: BO Config `log_level` 키로 CC/BO 로그 레벨을 실시간 변경 가능.

---

## 2. 구조화 로그 필드

### 2.1 공통 필드 (모든 로그)

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `timestamp` | string (ISO 8601, ms) | O | 로그 발생 시각 |
| `level` | string | O | DEBUG / INFO / WARNING / ERROR / CRITICAL |
| `source` | string | O | 로그 발생 컴포넌트 |
| `message` | string | O | 사람이 읽을 수 있는 로그 메시지 |

### 2.2 source 값

| source | 컴포넌트 | 설명 |
|--------|---------|------|
| `cc` | Command Center | CC 앱 로그 |
| `bo` | Back Office | BO 서버 로그 |
| `engine` | Game Engine | 게임 규칙 처리 로그 |
| `rfid` | RFID HAL | 카드 인식, 덱 등록, 하드웨어 로그 |
| `overlay` | Overlay | 그래픽 렌더링, 출력 로그 |
| `lobby` | Lobby | 웹 클라이언트 로그 (BO로 전송) |

### 2.3 컨텍스트 필드 (선택)

| 필드 | 타입 | 설명 | 해당 source |
|------|------|------|-----------|
| `table_id` | int | 테이블 ID | cc, engine, rfid, overlay |
| `hand_number` | int | 핸드 번호 | cc, engine |
| `hand_id` | int | 핸드 DB ID | cc, engine, bo |
| `seat_no` | int | 좌석 번호 | cc, engine, rfid |
| `user_id` | string | 사용자 ID | bo, lobby |
| `event_type` | string | 이벤트 타입 | cc, bo (WebSocket) |
| `error_code` | string | 에러 코드 | 모두 |
| `duration_ms` | int | 처리 시간 | bo (API 응답) |
| `rfid_uid` | string | RFID UID | rfid |
| `correlation_id` | string | 분산 추적용 단일 작업 단위 ID. 모든 하위 이벤트에 전파 | 모두 |
| `causation_id` | string | 직전 원인 이벤트 id — `audit_events.causation_id` (DATA-04 §5.2). Undo 체인 추적 | bo, cc, engine |
| `idempotency_key` | string | mutation 요청이 동반한 `Idempotency-Key` 헤더 (API-01, CCR-003) | bo |
| `seq` | int | 테이블별 단조증가 이벤트 순번 — `audit_events.seq` 와 WebSocket envelope `seq` 에 1:1 매핑 (CCR-015) | bo, cc |

> **원칙**: `correlation_id` 는 요청 진입점(REST/WS)에서 생성·전파. 없으면 자동 생성(UUIDv4). 모든 로그 + `audit_events` + 응답 헤더 `X-Request-ID` 에 echo.

### 2.4 로그 메시지 예시

```json
{
  "timestamp": "2026-04-08T14:30:00.123Z",
  "level": "INFO",
  "source": "engine",
  "message": "Hand started",
  "table_id": 5,
  "hand_number": 15,
  "hand_id": 42,
  "correlation_id": "corr-20260408-abc123",
  "seq": 15001
}
```

```json
{
  "timestamp": "2026-04-08T14:30:05.456Z",
  "level": "WARNING",
  "source": "rfid",
  "message": "Duplicate card detected",
  "table_id": 5,
  "hand_number": 15,
  "rfid_uid": "04A3B2C1D5E6F7A8",
  "error_code": "RFID_DUPLICATE_CARD",
  "correlation_id": "corr-20260408-abc123",
  "causation_id": "evt-15001"
}
```

---

## 3. 로그 저장 전략

### 3.1 2-Tier 저장

| Tier | 위치 | 용도 | 보존 기간 |
|------|------|------|----------|
| **Tier 1 — 로컬** | CC/BO 로컬 파일 | 즉시 접근, 오프라인 대응 | 7일 (자동 로테이션) |
| **Tier 2 — BO 집중** | BO DB (audit_logs) 또는 로그 파일 | 중앙 검색, 핸드 리플레이 | 90일 (Phase 1) |

### 3.2 로컬 파일 저장

| 앱 | 파일 경로 | 포맷 | 로테이션 |
|----|---------|------|---------|
| CC | `{app_dir}/logs/cc-{date}.log` | JSON Lines (JSONL) | 일별, 7일 보존 |
| BO | `{app_dir}/logs/bo-{date}.log` | JSON Lines (JSONL) | 일별, 30일 보존 |
| Overlay | `{app_dir}/logs/overlay-{date}.log` | JSON Lines (JSONL) | 일별, 7일 보존 |

### 3.3 BO 집중 전송

| 소스 | 전송 방식 | 전송 조건 |
|------|----------|----------|
| CC | WebSocket 이벤트 (batch) | WARNING 이상 즉시 전송. INFO는 10초 버퍼 |
| BO | 직접 DB 쓰기 | 로컬 파일과 동시 기록 |
| Overlay | WebSocket 이벤트 (batch) | WARNING 이상만 전송 |
| Lobby | REST API POST | ERROR 이상만 전송 |

### 3.4 오프라인 로그

| 시나리오 | 동작 |
|---------|------|
| BO 연결 끊김 | 로컬 파일에만 저장. 재연결 시 미전송 WARNING+ 로그 일괄 전송 |
| 로컬 디스크 부족 | 가장 오래된 로그 파일 삭제 (FIFO) |
| CC 크래시 | 크래시 직전 로그는 로컬 파일에 이미 기록됨 (버퍼 플러시) |

---

## 4. 감사 로그 / 이벤트 스토어 / 운영 로그

### 4.1 3-way 구분 (2026-04-10 재정의, CCR-001 활성)

| 구분 | 감사 로그 (`audit_logs`) | 이벤트 스토어 (`audit_events`) | 운영 로그 (파일/stream) |
|------|-----------------------|----------------------------|----------------------|
| 목적 | 사용자·관리 액션 감사 | 모든 상태 변경의 append-only 이벤트 소싱 | 시스템 진단/성능 |
| 대상 | 로그인, 설정 변경, 권한 변경 등 | 좌석/블라인드/토너먼트 상태 전이, Undo/Revive, saga 단계 | 에러, 성능, 디버그 |
| 저장 | BO DB `audit_logs` | BO DB `audit_events` | 파일 JSONL + BO 집중 |
| 보존 | 1년 (아카이브 후 2년) | 1년 (append-only) | 90일 자동 정리 |
| 필수 필드 | user_id, entity_type, action, detail, correlation_id | table_id, seq, event_type, payload, correlation_id, causation_id, idempotency_key, inverse_payload | source, level, message, correlation_id |
| Undo 지원 | 불필요 | ✅ (inverse_payload) | 불필요 |
| WebSocket 발행 | 선택 | ✅ (seq와 1:1 매핑, CCR-015) | WARNING+ 만 |
| 정본 | DATA-04 §4 | DATA-04 §5.2 (CCR-001) | 본 문서 §3 |

> 참조: DATA-04 §4 audit_logs, DATA-04 §5.2 audit_events, BO-03 §1.2, IMPL-10 §7.

### 4.2 감사 대상 이벤트 (14-카테고리 매트릭스)

> 2026-04-14: BO-03 §1 흡수. 감사 기록 정책 SSOT.

| 분류 | 이벤트 | 기록 내용 | 저장 |
|------|--------|----------|:----:|
| **인증** | 로그인/로그아웃 | 사용자, IP, 역할, 시각 | `audit_logs` |
| **인증** | 로그인 실패 | 이메일, IP, 실패 사유, 시각 | `audit_logs` |
| **인증** | 2FA 활성화/비활성화 | 사용자, 시각 | `audit_logs` |
| **사용자** | 생성/수정/비활성화 | 대상 사용자, 변경 내용, 실행 Admin | `audit_logs` |
| **사용자** | 역할 변경 | 이전/이후 역할, 실행 Admin | `audit_logs` |
| **대회** | Series/Event/Flight CRUD | 대상 엔티티, 변경 내용, 실행 Admin | `audit_logs` |
| **테이블** | 테이블 CRUD | 대상 테이블, 변경 내용, 실행 Admin | `audit_logs` |
| **테이블** | 상태 전환 | 이전/이후 상태, 실행 사용자 | `audit_logs` |
| **플레이어** | 등록/제거 | 대상 플레이어, 테이블, 실행 Admin | `audit_logs` |
| **좌석** | 배치/변경/비우기 (관리 액션) | 이전/이후 좌석, 플레이어, 실행 Admin | `audit_logs` |
| **RFID** | 리더 할당/해제 | 리더 ID, 테이블, 실행 Admin | `audit_logs` |
| **설정** | Config 변경 | 키, 이전/이후 값, 실행 Admin | `audit_logs` |
| **장애** | 발생/복구 | 장애 유형, 시각, 영향 범위 | `audit_logs` |
| **CC** | 연결/해제 | table_id, operator, 시각 | `audit_logs` |
| **WSOP LIVE 동기화** | 폴링 성공/실패/회복 | sync_cursor 이전/이후, 에러 유형 | `audit_logs` (BO-02 §7.1 Fallback Queue) |
| **좌석 이력** (이벤트 소싱) | seat_assigned/released/moved | inverse_payload 포함 | `audit_events` (CCR-001) |
| **리밸런싱** | rebalance_step_started/completed/compensated | saga 단계별 진행/보상 | `audit_events` (CCR-010) |
| **Undo/Revive** | 역방향 이벤트 | causation_id로 원 이벤트 연결 | `audit_events` (CCR-001) |
| **핸드 게임 액션** | Fold/Call/Raise/Check/All-in | 카드, 베팅 | `hand_actions` |

**제외 대상** (감사 비기록):
| 제외 대상 | 이유 |
|----------|------|
| 핸드 개별 액션 (Fold, Bet 등) | `hand_actions` 테이블에 별도 저장 (이벤트 소싱) |
| API 읽기 요청 (GET) | 볼륨 과다, 보안 가치 낮음 |
| WebSocket 하트비트 | 시스템 레벨 로그에 별도 기록 |

> **3-way 분리 원칙** (§4.1과 일치): 사람 관리 액션 → `audit_logs`, 상태 변경 이벤트 소싱 → `audit_events`, 핸드 게임 액션 → `hand_actions`. 두 감사 테이블은 `correlation_id` 로 묶인다.

---

## 5. 핸드 리플레이 로그

### 5.1 목적

핸드 리플레이 로그는 특정 핸드의 모든 이벤트를 시간순으로 재구성하기 위한 전용 로그다.

### 5.2 리플레이 로그 필드

| 필드 | 설명 |
|------|------|
| `hand_id` | 핸드 DB ID |
| `sequence` | 이벤트 순번 (0부터) |
| `event_type` | GameEvent 타입 |
| `payload` | 이벤트 데이터 (JSON) |
| `timestamp` | 이벤트 발생 시각 |

### 5.3 저장

- CC에서 핸드 종료 시 이벤트 시퀀스 전체를 BO에 전송
- BO는 `hand_actions` 테이블 + 별도 리플레이 JSON 파일로 저장
- 리플레이 JSON 경로: `{data_dir}/replays/{table_id}/{hand_id}.json`

---

## 6. 로그 검색과 필터링

### 6.1 BO 로그 검색 API

| 엔드포인트 | 설명 |
|-----------|------|
| `GET /logs?level=ERROR&source=rfid&table_id=5` | 필터 조건으로 로그 검색 |
| `GET /logs/hand/{hand_id}` | 특정 핸드의 리플레이 로그 |

### 6.2 필터 파라미터

| 파라미터 | 설명 | 예시 |
|---------|------|------|
| `level` | 최소 로그 레벨 | `WARNING` |
| `source` | 소스 필터 | `rfid`, `engine` |
| `table_id` | 테이블 필터 | `5` |
| `from` / `to` | 시간 범위 | ISO 8601 |
| `error_code` | 에러 코드 필터 | `RFID_CONNECTION_LOST` |

---

## 7. 성능 고려사항

| 항목 | 정책 |
|------|------|
| 로그 I/O 비동기 | 로그 쓰기는 비동기. 게임 루프 블로킹 금지 |
| DEBUG 로그 프로덕션 비활성 | `log_level >= WARNING`이면 DEBUG/INFO 메시지 생성 자체 스킵 |
| 버퍼링 | 로컬 파일 쓰기는 버퍼링 (1KB 또는 1초) |
| 로그 크기 제한 | 단일 메시지 최대 4KB. payload가 크면 요약 + 참조 ID |
| 핸드 액션 로그 | 핸드 중 액션은 메모리에 누적, 핸드 종료 시 일괄 저장 |
