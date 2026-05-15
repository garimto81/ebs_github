---
title: Error Handling
owner: team2
tier: internal
legacy-id: IMPL-06
last-updated: 2026-04-15
confluence-page-id: 3818455658
confluence-parent-id: 3811770578
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818455658/EBS+Error+Handling+0578
mirror: none
---

# IMPL-06 Error Handling — 에러 분류 + 복구 전략

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 에러 레벨, 도메인별 에러, 복구 전략, 사용자 노출 |
| 2026-04-10 | CCR-001/003 반영 + 신뢰성 정합성 | IMPL-10 §3 연결: Retryable/NonRetryable 분류, 서킷브레이커 상태 노출. contracts 반영 완료 — §4.4 Idempotency-Key 인지 처리, audit_events 기록 확정 |

---

## 개요

이 문서는 EBS의 **에러 처리 전략**을 정의한다. RFID 에러, 네트워크 에러, 게임 엔진 에러를 분류하고 각각의 복구 전략과 사용자 노출 방식을 기술한다.

> 참조: API-03 §4 에러 코드 카탈로그, API-05 §7 에러/경고 이벤트 구분, BS-00 §9 Mock 모드

---

## 1. 에러 레벨 분류

### 1.1 4-Level 체계

| 레벨 | 심각도 | 의미 | 시스템 반응 | 사용자 노출 |
|------|:------:|------|-----------|-----------|
| **FATAL** | 최고 | 앱 정상 동작 불가 | 앱 재시작 필요 | 전체 화면 에러 + 재시작 안내 |
| **ERROR** | 높음 | 현재 작업 중단 필요 | 핸드 중단 또는 기능 비활성화 | 모달 다이얼로그 |
| **WARNING** | 중간 | 주의 필요하나 동작 계속 | 로그 기록 + 사용자 알림 | 토스트 또는 배너 |
| **INFO** | 낮음 | 정보 전달 | 로그 기록만 | 상태바 또는 미표시 |

### 1.2 레벨 판정 기준

| 기준 | FATAL | ERROR | WARNING | INFO |
|------|:-----:|:-----:|:-------:|:----:|
| 데이터 손실 가능성 | O | O | X | X |
| 핸드 무결성 영향 | O | O | X | X |
| 운영자 개입 필요 | O | O | 선택 | X |
| 자동 복구 가능 | X | △ | O | — |

---

## 2. 도메인별 에러 분류

### 2.1 RFID 에러

| 에러 코드 | 레벨 | 설명 | 복구 전략 |
|----------|:----:|------|----------|
| connectionLost (100) | ERROR | 리더 연결 끊김 | 자동 재연결 3회 시도 → 실패 시 수동 폴백 안내 |
| connectionTimeout (101) | ERROR | 리더 연결 타임아웃 | 자동 재시도 → 실패 시 Mock 모드 전환 제안 |
| serialPortError (102) | FATAL | Serial 포트 오류 | 앱 재시작 안내 + USB 연결 확인 |
| antennaDisconnected (200) | WARNING | 안테나 1개 해제 | 영향받는 좌석 표시 + 수동 카드 입력 안내 |
| antennaOverload (201) | WARNING | 다수 태그 동시 감지 | 카드 재배치 안내 |
| duplicateCard (300) | WARNING | 동일 카드 중복 | 중복 카드 하이라이트 + 운영자 확인 요청 |
| unknownCard (301) | WARNING | 미등록 카드 | 덱 재등록 또는 수동 입력 안내 |
| cardConflict (303) | WARNING | 수동 입력 vs RFID 불일치 | 운영자에게 선택 팝업 (RFID 우선 / 수동 우선) |
| deckRegistrationFailed (400) | ERROR | 덱 등록 실패 | 재등록 안내 |
| deckIncomplete (401) | ERROR | 52장 미만 | 누락 카드 표시 + 재스캔 또는 수동 등록 |

### 2.2 네트워크 에러

| 시나리오 | 레벨 | 영향 범위 | 복구 전략 |
|---------|:----:|---------|----------|
| BO WebSocket 끊김 | WARNING | CC→BO 데이터 전송 중단 | 지수 백오프 재연결 + 로컬 버퍼 |
| BO REST API 타임아웃 | WARNING | Lobby CRUD 실패 | 재시도 3회 → 에러 토스트 |
| BO 서버 다운 | ERROR | 전체 동기화 중단 | CC: 로컬 모드 전환, Lobby: 오프라인 알림 |
| JWT 인증 실패 | ERROR | API 접근 불가 | 토큰 갱신 시도 → 실패 시 재로그인 |
| WSOP LIVE API 실패 | WARNING | 외부 데이터 동기화 중단 | 캐시 데이터 사용 + 재시도 예약 |

### 2.3 Game Engine 에러

| 시나리오 | 레벨 | 설명 | 복구 전략 |
|---------|:----:|------|----------|
| 잘못된 이벤트 순서 | ERROR | FLOP 이전에 TURN 카드 감지 | 이벤트 거부 + 운영자 알림 |
| 불가능한 액션 | WARNING | 폴드한 플레이어가 베팅 시도 | 액션 거부 + UI에서 불가 표시 |
| 스택 음수 | ERROR | 베팅 금액 > 보유 스택 | 올인으로 자동 보정 또는 거부 |
| 핸드 상태 불일치 | FATAL | GameState 복원 실패 | 핸드 강제 종료 + 수동 재시작 |
| 팟 계산 오류 | ERROR | 메인+사이드 팟 합산 불일치 | 경고 로그 + 운영자 수동 검증 요청 |

### 2.4 Retryable vs NonRetryable 분류 (IMPL-10 §3 정합)

재시도 정책을 적용하기 전에 모든 예외는 두 유형 중 하나로 분류되어야 한다. Python 코드에서는 `RetryableError` / `NonRetryableError` 기반 클래스를 상속하여 구분.

| 유형 | 의미 | 대표 케이스 | 재시도 |
|------|------|-----------|:------:|
| `RetryableError` | 일시적 장애, 재시도 시 성공 가능 | Redis 타임아웃, DB deadlock, 5xx, 408 Request Timeout, 429 Too Many Requests | ✅ |
| `NonRetryableError` | 논리/검증 오류, 재시도해도 동일 | 4xx(401/403/404/409/422), 게임 룰 위반, 스키마 오류 | ❌ |
| `IdempotentOnlyRetryable` | Idempotency-Key 동반 시에만 재시도 가능 | 포스트 계열 network 에러 (커넥션 끊김) | 조건부 |

**재시도 회수/백오프**: IMPL-10 §3.2 표 준수 (client→BO 3회, BO→WSOP 5회 등).

**FastAPI exception handler 규칙**:
- `RetryableError` → 5xx 응답 + `Retry-After` 헤더
- `NonRetryableError` → 4xx 응답 (매핑 테이블)
- 양자 모두 `error_code`, `correlation_id`, `details` 포함

---

## 3. 사용자 노출 UI 패턴

### 3.1 CC 에러 표시

| 패턴 | 사용 조건 | 동작 |
|------|----------|------|
| **전체 화면 오버레이** | FATAL 에러 | 반투명 배경 + 에러 메시지 + 재시작 버튼 |
| **모달 다이얼로그** | ERROR 에러 | 제목 + 상세 + 확인/재시도 버튼 |
| **토스트** | WARNING 에러 | 3초 표시 → 자동 해제 |
| **상태바 아이콘** | INFO + 연결 상태 | 화면 하단 영구 표시 (녹/황/적) |

### 3.2 상태바 아이콘 체계

| 아이콘 색상 | 의미 | 세부 |
|:----------:|------|------|
| 녹색 | 정상 | BO 연결 + RFID 정상 |
| 황색 | 경고 | BO 연결 불안정 또는 RFID 경고 |
| 적색 | 에러 | BO 미연결 또는 RFID 에러 |

### 3.3 Lobby 에러 표시

| 패턴 | 사용 조건 | 동작 |
|------|----------|------|
| **토스트** | REST API 에러 | 우상단 5초 표시 |
| **인라인 에러** | 폼 유효성 검사 실패 | 필드 하단 빨간 텍스트 |
| **페이지 에러** | 데이터 로드 실패 | 빈 상태 + 재시도 버튼 |
| **배너** | WebSocket 연결 끊김 | 상단 고정 배너 (재연결 중...) |

---

## 4. 에러 복구 패턴

### 4.1 자동 재시도

| 대상 | 재시도 정책 | 최대 횟수 | 간격 |
|------|-----------|:--------:|------|
| BO WebSocket 재연결 | 지수 백오프 | 무한 (5분까지) | 1s → 2s → 4s → ... → 30s |
| REST API 요청 | 고정 간격 | 3회 | 1초 |
| RFID 리더 재연결 | 지수 백오프 | 5회 | 2s → 4s → 8s |
| 토큰 갱신 | 즉시 1회 | 1회 | — |

### 4.2 폴백 전략

| 시나리오 | 폴백 동작 |
|---------|----------|
| RFID 연결 실패 | Mock 모드 전환 → 수동 카드 입력 |
| BO 연결 실패 | CC 로컬 모드 (핸드 진행 가능, 데이터 로컬 버퍼) |
| 덱 등록 실패 | 수동 카드 입력 모드 (덱 미등록 상태로 게임 진행) |
| Lobby WebSocket 실패 | REST 폴링 (30초 간격) |
| WSOP LIVE API 실패 | 로컬 캐시 데이터 사용 |

### 4.3 CC 로컬 모드

BO 연결 실패 시 CC는 **로컬 모드**로 전환한다.

| 항목 | 로컬 모드 동작 |
|------|-------------|
| 게임 진행 | 정상 — Game Engine은 로컬 실행 |
| 핸드 데이터 | 로컬 파일/메모리에 버퍼링 |
| 설정 변경 | 불가 — 마지막 수신 설정 유지 |
| BO 재연결 시 | 버퍼의 미전송 이벤트를 순서대로 전송 |
| 재연결 실패 지속 | 로컬 모드 유지 + 운영자에게 알림 |

### 4.4 Idempotency-Key 인지 처리 — [CCR-003 활성]

**정본**: `contracts/api/API-01 §공통 요청 헤더` (`Idempotency-Key`), `contracts/data/DATA-04 §5.1 idempotency_keys`. 헤더 동작과 저장소 스키마는 계약에 정의됨.

**team2 구현 가이드 — FastAPI 미들웨어 처리 흐름**:

1. `IdempotencyMiddleware` (`src/middleware/idempotency.py`) 가 mutation 요청 수신
2. 헤더 없음 → 정상 진행, 재시도 안전성 미보장 (응답 헤더 `Retry-Allowed: false`)
3. 헤더 있음 → Redis `idem:{user_id}:{key}` 조회
   - Hit + 동일 `request_hash` → 캐시된 응답 재생 (`Idempotent-Replayed: true` 헤더 추가)
   - Hit + 상이 `request_hash` → `409 Conflict` + `IDEMPOTENCY_KEY_REUSED` 에러 코드 (API-01 정본)
   - Miss → 다운스트림 처리, 성공 응답을 Redis + DB 백업 (DATA-04 §5.1)
4. `RetryableError` 발생 시 미들웨어가 Idempotency-Key 유무 확인
   - 있음 → 501/503 응답 + 클라 재시도 안전
   - 없음 → 500 응답 + 클라 재시도 금지 권고

**IMPL-10 §3.1 과의 통합**: 본 미들웨어는 IMPL-10 §3.1 에 정의된 구현 가이드(저장소 순위, request_hash 알고리즘, 오버헤드 목표)를 따른다. 미들웨어는 `app.state.idempotency_store` 를 사용하고, IMPL-05 의 `get_idempotency_store()` DI 는 동일 싱글턴을 라우트 핸들러 레벨에서 선택적으로 주입받는 용도다 (두 경로 병존, 경계는 IMPL-10 §3.1 표 참조).

### 4.5 서킷브레이커 상태 노출 (IMPL-10 §3.3 정합)

외부 API(WSOP LIVE, OAuth) 호출부의 Circuit Breaker 상태는 에러 레벨에 영향:

| CB 상태 | 에러 레벨 | 사용자 노출 |
|---------|:--------:|-----------|
| CLOSED | — | 정상 |
| HALF_OPEN | WARNING | 배너 "외부 API 복구 시도 중" |
| OPEN | ERROR | 모달 또는 기능 비활성화 "WSOP LIVE 일시 장애, 캐시 사용 중" |

상태 변경은 `audit_events` (DATA-04 §5.2) + Prometheus counter 기록. OPEN 지속 5분 이상 시 Sentry 경보.

---

## 5. 에러 보고 체계

### 5.1 에러 로그 구조

| 필드 | 타입 | 설명 |
|------|------|------|
| `level` | string | FATAL / ERROR / WARNING / INFO |
| `domain` | string | rfid / network / engine / auth / system |
| `code` | string | 에러 코드 (예: `RFID_CONNECTION_LOST`) |
| `message` | string | 사람이 읽을 수 있는 에러 설명 |
| `table_id` | int | 에러 발생 테이블 |
| `hand_number` | int / null | 에러 발생 핸드 번호 (해당 시) |
| `timestamp` | string | ISO 8601 |
| `stack_trace` | string / null | 스택 트레이스 (개발 모드에서만) |

### 5.2 에러 전파 경로

```
에러 발생 (CC/BO)
    │
    ├── 로컬 로그 파일 기록
    │
    ├── BO에 전송 (audit_logs 저장)
    │
    └── ERROR/FATAL → Lobby에 WebSocket 이벤트로 전파
                        │
                        └── Lobby 대시보드에 경고 표시
```

---

## 6. 에러 처리 금지 사항

| 금지 | 이유 | 올바른 방식 |
|------|------|-----------|
| 에러 무시 (empty catch) | 디버깅 불가, 무한 상태 오류 | 최소 WARNING 로그 기록 |
| 사용자에게 스택 트레이스 노출 | 보안 위험 + UX 저하 | 사람이 읽을 수 있는 메시지만 |
| FATAL 에러 후 계속 진행 | 데이터 무결성 손상 | 앱 재시작 강제 |
| 핸드 중간 자동 복구 | 게임 무결성 훼손 가능 | 운영자 확인 후 복구 |
| 에러 메시지 하드코딩 | 다국어/변경 어려움 | 에러 코드 → 메시지 매핑 테이블 |
