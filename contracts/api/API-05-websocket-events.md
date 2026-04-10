# API-05 WebSocket Events — CC ↔ BO ↔ Lobby 실시간 이벤트 프로토콜

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 연결 아키텍처, 메시지 포맷, 이벤트 분류, 생명주기 |
| 2026-04-09 | GAP-L-002 보강 | §1.3 WebSocket JWT 인증 방식 추가 |

---

## 개요

이 문서는 EBS 3-앱 아키텍처(CC ↔ BO ↔ Lobby)의 **WebSocket 실시간 이벤트 프로토콜**을 정의한다. CC와 Lobby는 각각 독립된 WebSocket 연결로 BO에 접속하며, BO가 이벤트를 라우팅한다.

> **참조**: 이벤트 소스 분류는 `BS-06-00-triggers.md`, 모니터링 항목은 `BS-02-lobby.md §활성 CC 모니터링`, 용어 정의는 `BS-00-definitions.md`

---

## 1. 연결 아키텍처

### 1.1 연결 토폴로지

```
CC (Flutter)  ───WebSocket───  BO (FastAPI)  ───WebSocket───  Lobby (웹)
   발행자                        라우터/저장소                    구독자
```

| 연결 | 프로토콜 | 엔드포인트 | 방향 | 용도 |
|------|---------|----------|------|------|
| CC → BO | WebSocket | `ws://{host}/ws/cc?table_id={id}` | 양방향 | 게임 데이터 발행 + 설정 수신 |
| Lobby → BO | WebSocket | `ws://{host}/ws/lobby` | 양방향 | 모니터링 구독 + 설정 발행 |

### 1.2 핵심 원칙

- CC와 Lobby는 **직접 연결하지 않는다** — BO를 경유한 간접 통신만 허용
- CC는 테이블당 1개 WebSocket 연결 (table_id로 식별)
- Lobby는 1개 WebSocket 연결로 모든 테이블 이벤트를 구독
- BO는 수신한 이벤트를 DB에 저장하고 구독자에게 포워딩

### 1.3 WebSocket JWT 인증 방식

> **GAP-L-002 보강**: WebSocket 연결 시 JWT 토큰 전달 방식 명시.

WebSocket 프로토콜은 HTTP `Authorization` 헤더를 직접 지원하지 않는다. EBS는 **연결 URL query parameter** 방식을 사용한다.

| 연결 | 인증 방식 | 예시 |
|------|----------|------|
| CC → BO | `token` query param | `ws://{host}/ws/cc?table_id={id}&token={access_token}` |
| Lobby → BO | `token` query param | `ws://{host}/ws/lobby?token={access_token}` |

**인증 처리 흐름:**

```
클라이언트 WebSocket 연결 요청 (URL에 token 포함)
  │
  ├─ BO: token 검증 (JWT 서명, 만료 확인)
  │    │
  │    ├─ 유효 → 연결 수락, role 및 table_id 권한 확인
  │    │
  │    └─ 무효/만료 → 연결 거부 (HTTP 401 Upgrade 실패)
  │
  └─ 토큰 만료 중 재연결 시
       └─ 클라이언트가 먼저 POST /auth/refresh → 새 Access Token 취득
            └─ 새 token으로 WebSocket 재연결
```

**보안 주의사항:**

| 항목 | 내용 |
|------|------|
| token 노출 | URL에 포함되어 서버 로그에 남을 수 있음. HTTPS/WSS 필수 (운영 환경) |
| 개발 환경 | `ws://` 허용. 운영 환경은 `wss://` 강제 |
| 토큰 만료 | 연결 수립 후 15분 경과 시 BO가 연결을 강제 종료하지 않음. 단, 핸드 저장 등 API 호출이 필요한 시점에 Refresh 흐름 적용 |

---

## 2. 메시지 포맷

### 2.1 JSON Envelope

모든 WebSocket 메시지는 동일한 envelope 구조를 따른다.

```json
{
  "type": "HandStarted",
  "payload": {
    "hand_id": 42,
    "table_id": 5,
    "hand_number": 15,
    "dealer_seat": 3,
    "player_count": 6
  },
  "timestamp": "2026-04-08T14:30:00.123Z",
  "source_id": "cc-table-5",
  "message_id": "msg-uuid-1234"
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `type` | string | O | 이벤트 타입 (PascalCase) |
| `payload` | object | O | 이벤트별 데이터 |
| `timestamp` | string (ISO 8601) | O | 이벤트 발생 시각 (ms 정밀도) |
| `source_id` | string | O | 발신자 식별 (`cc-table-{id}` / `lobby` / `bo`) |
| `message_id` | string (UUID) | O | 메시지 고유 ID (중복 방지) |

### 2.2 응답/확인 메시지

서버가 클라이언트 메시지에 대해 확인을 보내는 경우:

```json
{
  "type": "Ack",
  "payload": {
    "original_message_id": "msg-uuid-1234",
    "status": "ok"
  },
  "timestamp": "2026-04-08T14:30:00.150Z",
  "source_id": "bo",
  "message_id": "msg-uuid-5678"
}
```

---

## 3. CC → BO 이벤트 (게임 데이터 발행)

CC가 게임 진행 중 BO에 발행하는 이벤트. BO는 DB에 저장 후 Lobby에 포워딩한다.

| 이벤트 | payload 주요 필드 | 발동 조건 | 설명 |
|--------|------------------|----------|------|
| `HandStarted` | hand_id, hand_number, dealer_seat, player_count, blind_level | 핸드 시작 | 새 핸드 개시 |
| `HandEnded` | hand_id, winner_seats, pot_total, duration_ms | 핸드 종료 | 팟 분배 완료 |
| `ActionPerformed` | hand_id, seat, action_type, amount, pot_after | 플레이어 액션 | Fold/Check/Bet/Call/Raise/AllIn |
| `CardDetected` | hand_id, seat, suit, rank, is_board, position | 카드 인식 | RFID 또는 수동 입력 |
| `GameChanged` | table_id, previous_game, new_game | 종목 변경 | Mix 게임 모드에서 게임 전환 |
| `RfidStatusChanged` | table_id, status, antenna_count, error_code | RFID 상태 변경 | 연결/해제/에러 |
| `OutputStatusChanged` | table_id, output_type, status, resolution | 출력 상태 변경 | NDI/SDI 연결/해제 |

### 3.1 HandStarted payload 상세

```json
{
  "hand_id": 42,
  "table_id": 5,
  "hand_number": 15,
  "dealer_seat": 3,
  "player_count": 6,
  "blind_level": {
    "level": 5,
    "sb": 200,
    "bb": 400,
    "ante": 50
  },
  "game": "holdem",
  "bet_structure": "no_limit"
}
```

### 3.2 ActionPerformed payload 상세

```json
{
  "hand_id": 42,
  "seat": 5,
  "action_type": "raise",
  "amount": 1200,
  "pot_after": 3400,
  "stack_after": 8800,
  "game_phase": 2,
  "action_index": 3
}
```

> `action_type` 값: `fold`, `check`, `bet`, `call`, `raise`, `allin`
> `game_phase` 값: BS-00 §3.2 참조 (0=IDLE ~ 7=HAND_COMPLETE)

---

## 4. BO → Lobby 이벤트 (모니터링 포워딩)

BO가 CC 이벤트를 가공하여 Lobby에 포워딩하는 이벤트. CC → BO 이벤트를 그대로 전달하되, Lobby 전용 이벤트가 추가된다.

### 4.1 CC 이벤트 포워딩

§3의 모든 CC → BO 이벤트는 BO가 수신 후 Lobby에 동일 포맷으로 포워딩한다. `source_id`는 원본 CC의 값을 유지한다.

### 4.2 Lobby 전용 이벤트

| 이벤트 | payload 주요 필드 | 발동 조건 | 설명 |
|--------|------------------|----------|------|
| `OperatorConnected` | table_id, operator_id, username | CC WebSocket 연결 | Operator가 CC를 실행 |
| `OperatorDisconnected` | table_id, operator_id, reason | CC WebSocket 끊김 | CC 종료 또는 네트워크 단절 |

### 4.3 구독 필터링

Lobby는 연결 시 구독할 테이블 범위를 지정할 수 있다.

```json
{
  "type": "Subscribe",
  "payload": {
    "table_ids": [1, 5, 12],
    "event_types": ["HandStarted", "HandEnded", "OperatorConnected"]
  },
  "timestamp": "2026-04-08T09:00:00Z",
  "source_id": "lobby",
  "message_id": "msg-uuid-sub-1"
}
```

| 필드 | 설명 |
|------|------|
| `table_ids` | 빈 배열 = 모든 테이블 구독 (Admin/Viewer). Operator는 할당 테이블만 |
| `event_types` | 빈 배열 = 모든 이벤트 구독. 특정 타입만 필터링 가능 |

---

## 5. Lobby → BO → CC 이벤트 (설정 변경)

Lobby(또는 Settings)에서 설정을 변경하면 BO를 경유하여 CC에 실시간 반영한다.

| 이벤트 | payload 주요 필드 | 발동 조건 | 수신자 | 설명 |
|--------|------------------|----------|--------|------|
| `ConfigChanged` | table_id, config_key, old_value, new_value | Admin Settings 변경 | CC | 출력/오버레이/게임 설정 |
| `PlayerUpdated` | table_id, seat, player_id, fields_changed | Lobby 플레이어 수정 | CC | 이름/프로필 변경 |
| `TableAssigned` | table_id, rfid_reader_id, deck_status, output_preset | Lobby 테이블 설정 | CC | RFID/덱/출력 설정 |
| `BlindStructureChanged` | table_id, new_level, sb, bb, ante | Lobby 블라인드 변경 | CC | 새 블라인드 레벨 적용 |

### 5.1 ConfigChanged payload 상세

```json
{
  "table_id": 5,
  "config_key": "overlay.security_delay_ms",
  "old_value": 30000,
  "new_value": 60000,
  "changed_by": "admin-user-1"
}
```

### 5.2 핸드 중간 설정 변경 지연

> **참조**: `BS-06-00-triggers.md §5.2` — CC 액션과 BO ConfigChanged 동시 발생 시 CC 우선

| 설정 유형 | 적용 시점 | 이유 |
|----------|----------|------|
| 블라인드 레벨 | 다음 핸드 시작 시 | 현재 핸드의 블라인드 일관성 유지 |
| 오버레이 스킨 | 즉시 | 시각적 변경만, 게임 로직 무관 |
| Security Delay | 즉시 | 보안 설정은 지연 없이 즉시 |
| RFID 모드 변경 | 현재 핸드 종료 후 | 카드 인식 방식 변경은 핸드 무결성 보호 |

---

## 6. 연결 생명주기

### 6.1 연결 흐름

```
클라이언트                    BO 서버
    │                           │
    │── WebSocket CONNECT ──→   │
    │                           │── JWT 검증
    │← 101 Switching ──────     │
    │                           │
    │── Auth { token } ────→    │
    │← AuthResult { ok } ──    │
    │                           │
    │── Subscribe {...} ───→    │  (Lobby만)
    │← Ack ─────────────────   │
    │                           │
    │←→ 이벤트 송수신 ←→        │
    │                           │
    │── Ping ──────────────→    │  (30초 간격)
    │← Pong ───────────────    │
    │                           │
```

### 6.2 인증

WebSocket 연결 후 첫 메시지로 인증 토큰을 전송해야 한다. 5초 이내 인증하지 않으면 서버가 연결을 종료한다.

```json
{
  "type": "Auth",
  "payload": {
    "access_token": "eyJhbGciOi..."
  },
  "timestamp": "2026-04-08T09:00:00Z",
  "source_id": "cc-table-5",
  "message_id": "msg-uuid-auth-1"
}
```

### 6.3 하트비트

| 항목 | 값 | 설명 |
|------|:--:|------|
| Ping 간격 | 30초 | 클라이언트 → 서버 |
| Pong 타임아웃 | 10초 | 서버 미응답 시 재연결 시도 |
| 최대 미응답 | 3회 | 3회 연속 미응답 시 연결 끊김 판정 |

### 6.4 재연결

| 시나리오 | 클라이언트 동작 |
|---------|---------------|
| 네트워크 일시 단절 | 지수 백오프 재연결 (1초 → 2초 → 4초 → 최대 30초) |
| 서버 재시작 | 동일 지수 백오프 + 이전 구독 재등록 |
| 토큰 만료 중 재연결 | Refresh Token으로 갱신 후 재연결 |
| 5분 이상 연결 실패 | 사용자에게 연결 실패 알림 + 수동 재연결 버튼 |

### 6.5 연결 끊김 처리

| 끊김 주체 | BO 서버 동작 | 상대방 알림 |
|----------|------------|-----------|
| CC 연결 끊김 | `operator_disconnected` 이벤트 저장 | Lobby에 `OperatorDisconnected` 발행 |
| Lobby 연결 끊김 | 구독 해제 | CC에 영향 없음 (독립 동작) |
| BO 서버 다운 | — | CC: 로컬 캐시로 게임 진행, Lobby: 재연결 대기 |

---

## 7. 에러 이벤트와 경고 이벤트 구분

### 7.1 에러 이벤트 (Error)

시스템 동작에 영향을 주는 이벤트. 즉시 처리가 필요하다.

| 이벤트 | 심각도 | 설명 | 후속 조치 |
|--------|:------:|------|----------|
| `AuthFailed` | CRITICAL | 인증 실패 | 연결 종료 |
| `TableNotFound` | ERROR | 존재하지 않는 table_id | 연결 종료 |
| `PermissionDenied` | ERROR | RBAC 권한 부족 | 해당 메시지 거부 |
| `InvalidMessage` | ERROR | 메시지 포맷 오류 | 해당 메시지 거부 + 에러 응답 |
| `RfidHardwareError` | ERROR | RFID 하드웨어 장애 | Lobby에 알림, 운영자 개입 필요 |

### 7.2 경고 이벤트 (Warning)

정보성 이벤트. 시스템은 정상 동작하지만 주의가 필요하다.

| 이벤트 | 설명 | 표시 위치 |
|--------|------|----------|
| `DuplicateCard` | 동일 카드 중복 감지 | CC 경고 배너 + Lobby 로그 |
| `CardConflict` | CC 수동 입력과 RFID 감지 불일치 | CC 경고 팝업 |
| `SlowConnection` | 하트비트 응답 지연 (>5초) | Lobby 연결 상태 표시 |
| `TokenExpiringSoon` | Access Token 만료 2분 전 | 내부 (자동 갱신 트리거) |

### 7.3 에러 응답 포맷

```json
{
  "type": "Error",
  "payload": {
    "code": "PERMISSION_DENIED",
    "message": "Operator not assigned to table 5",
    "original_message_id": "msg-uuid-1234"
  },
  "timestamp": "2026-04-08T14:30:01Z",
  "source_id": "bo",
  "message_id": "msg-uuid-err-1"
}
```
