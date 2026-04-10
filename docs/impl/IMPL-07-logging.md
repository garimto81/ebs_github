# IMPL-07 Logging — 로그 레벨, 필드, 저장 전략

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 로그 레벨, 구조화 필드, 저장/전송, 보존 정책 |

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

### 2.4 로그 메시지 예시

```json
{
  "timestamp": "2026-04-08T14:30:00.123Z",
  "level": "INFO",
  "source": "engine",
  "message": "Hand started",
  "table_id": 5,
  "hand_number": 15,
  "hand_id": 42
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
  "error_code": "RFID_DUPLICATE_CARD"
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

## 4. 감사 로그 vs 운영 로그

### 4.1 구분

| 구분 | 감사 로그 (Audit Log) | 운영 로그 (Operational Log) |
|------|---------------------|--------------------------|
| 목적 | 누가 무엇을 언제 변경했는가 | 시스템이 어떻게 동작했는가 |
| 대상 | 사용자 액션, 데이터 변경 | 시스템 이벤트, 에러, 성능 |
| 저장 | BO DB `audit_logs` 테이블 | 로그 파일 + BO 집중 저장 |
| 보존 | 영구 (삭제 불가) | 90일 (자동 정리) |
| 필수 필드 | user_id, entity_type, action, detail | source, level, message |

> 참조: DATA-04 §4 audit_logs 테이블, BO-08

### 4.2 감사 대상 이벤트

| 이벤트 | entity_type | action |
|--------|-----------|--------|
| 로그인/로그아웃 | user | login / logout |
| 사용자 생성/수정/삭제 | user | create / update / delete |
| 테이블 설정 변경 | table | update |
| 블라인드 변경 | blind_structure | update |
| 플레이어 좌석 배치/이동 | seat | assign / move |
| 핸드 수동 종료 | hand | force_end |
| Config 변경 | config | update |

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
