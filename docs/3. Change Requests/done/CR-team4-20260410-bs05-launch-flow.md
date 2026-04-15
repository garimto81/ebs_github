---
title: CR-team4-20260410-bs05-launch-flow
owner: conductor
tier: internal
last-updated: 2026-04-15
legacy-id: CCR-DRAFT-team4-20260410-bs05-launch-flow
---

# CCR-DRAFT: BS-05 Lobby → BO → CC Launch 플로우 상세 명세

- **제안팀**: team4
- **제안일**: 2026-04-10
- **영향팀**: [team1, team2]
- **변경 대상 파일**: contracts/specs/BS-05-command-center/BS-05-00-overview.md, contracts/api/API-01-backend-api.md
- **변경 유형**: modify
- **변경 근거**: 현재 BS-05-00-overview에 "Launch 플로우: Lobby에서 [Launch] 클릭 → BO 인스턴스 생성 → WebSocket 연결 → IDLE 상태 수신"이라는 한 줄만 있다. 실제 구현 시 필요한 세부(운영자 인증 전파, 초기 상태 수신, Launch 실패 복구, CC 프로세스 실행 방식, BO와의 Handshake)가 모두 누락되어 Team 1/2/4 각자 임의 구현 위험이 있다. WSOP 원본(`EBS UI Design Action Tracker.md` §로그인)과 일치시키며, team1의 BS-02-lobby §Launch 섹션과 양방향 참조가 필요하다.

## 변경 요약

1. BS-05-00-overview.md §Launch 플로우를 대폭 확장
2. API-01에 `POST /tables/{id}/launch` 엔드포인트 명시 (없으면 추가)

## 변경 내용

### 1. BS-05-00-overview.md §Launch 플로우 (확장)

```markdown
## Launch 플로우 (상세)

### 시퀀스 다이어그램

```
[Operator]      [Lobby Web]       [BO]         [DB]         [CC (신규 프로세스)]
    │               │              │            │                  │
    │ click Launch  │              │            │                  │
    │──────────────▶│              │            │                  │
    │               │              │            │                  │
    │               │ POST /tables/{id}/launch  │                  │
    │               │─────────────▶│            │                  │
    │               │              │            │                  │
    │               │              │ check auth │                  │
    │               │              │ check RBAC │                  │
    │               │              │ check table status            │
    │               │              │───────────▶│                  │
    │               │              │ ◀──────────│                  │
    │               │              │                               │
    │               │              │ generate cc_instance_id       │
    │               │              │ create cc_session record      │
    │               │              │───────────▶│                  │
    │               │              │                               │
    │               │              │ generate launch_token (JWT 5분)│
    │               │              │                               │
    │               │ 200 OK       │                               │
    │               │ { cc_instance_id, launch_token, ws_url }     │
    │               │ ◀────────────│                               │
    │               │              │                               │
    │               │ Flutter CC 앱 실행                             │
    │               │ (OS별 shell command 또는 deep link)           │
    │               │─────────────────────────────────────────────▶│
    │               │              │                               │
    │               │              │                               │ CC 앱 시작
    │               │              │                               │ args: --table_id={id}
    │               │              │                               │       --token={launch_token}
    │               │              │                               │       --cc_instance_id={uuid}
    │               │              │                               │
    │               │              │ WebSocket 연결                 │
    │               │              │ ws://host/ws/cc?table_id=...   │
    │               │              │ ◀─────────────────────────────│
    │               │              │                               │
    │               │              │ JWT 검증                       │
    │               │              │ cc_instance_id 검증             │
    │               │              │ (cc_session 레코드 매칭)        │
    │               │              │                               │
    │               │              │ 연결 수락                       │
    │               │              │──────────────────────────────▶│
    │               │              │                               │
    │               │              │ 초기 상태 push                  │
    │               │              │ { table_state, hand_state, ...} │
    │               │              │──────────────────────────────▶│
    │               │              │                               │
    │               │              │                               │ IDLE 화면 렌더링
    │               │              │                               │
    │               │              │ CCRegistered 이벤트 → Lobby    │
    │               │              │──────────▶│                   │
    │               │ UI 갱신       │                               │
    │               │ "CC Table 5  │                               │
    │               │  Active" 표시 │                               │
    │               │ ◀────────────│                               │
```

### 단계별 상세

#### 1. Launch 요청 (Lobby)

Lobby의 Table Row에서 Admin/Operator가 "Launch CC" 버튼 클릭.

**검증 (Lobby 측)**:
- 현재 사용자가 해당 테이블에 할당되어 있는지 확인 (RBAC)
- 해당 테이블에 이미 내 CC 인스턴스가 있는지 확인 (중복 Launch 방지, BS-05-10 참조)
- 이미 있으면: "Focus existing CC" 버튼으로 변경

**요청**:
```http
POST /tables/{id}/launch
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "operator_id": 42,
  "force_takeover": false
}
```

#### 2. BO 처리

**검증**:
- JWT 유효성 (Authorization header)
- RBAC: `operator_id`가 Admin 또는 테이블에 할당된 Operator
- Table FSM 상태가 `SETUP` 또는 `LIVE` (EMPTY/CLOSED/PAUSED는 거부)
- 동일 `operator_id × table_id` 조합의 기존 cc_session 확인:
  - 없음: 정상 진행
  - 있음 + `force_takeover: false`: HTTP 409 Conflict
  - 있음 + `force_takeover: true`: 기존 세션 `CLOSED`로 전환 + 신규 생성

**생성**:
```sql
INSERT INTO cc_sessions (
  id, cc_instance_id, table_id, operator_id, 
  launch_token, launch_token_expires_at, 
  status, created_at
) VALUES (
  default, 'uuid-1234', 5, 42,
  '{jwt}', NOW() + INTERVAL '5 minutes',
  'LAUNCHING', NOW()
);
```

**응답**:
```json
{
  "cc_instance_id": "uuid-1234",
  "launch_token": "eyJhbGc...",
  "ws_url": "ws://ebs-bo.local/ws/cc",
  "expires_at": "2026-04-10T14:35:00Z"
}
```

#### 3. CC 프로세스 실행

Lobby가 OS별 방법으로 Flutter CC 앱 실행:

**Windows**:
```
ebs-cc.exe --table_id=5 --token={token} --cc_instance_id={uuid} --ws_url={url}
```

**macOS/Linux**:
```bash
/Applications/EBS-CC.app/Contents/MacOS/ebs-cc --table_id=5 --token=...
```

**Web 기반 대안 (Phase 2)**:
- Lobby가 브라우저 URL scheme `ebs-cc://launch?table_id=5&token=...` 호출
- OS가 등록된 CC 앱을 실행

**실패 시**:
- CC 앱 실행 파일 부재: Lobby에 "CC 앱을 찾을 수 없습니다" 경고 + Download 링크
- 권한 거부: OS 레벨 오류 전달

#### 4. CC 앱 초기화

CC 앱이 command-line args를 파싱:
- `--table_id`: 담당 테이블
- `--token`: launch_token (5분 내 사용 필수)
- `--cc_instance_id`: 고유 식별자
- `--ws_url`: WebSocket 엔드포인트

**초기 화면**: 연결 중 스플래시 (Connecting to Table 5...)

#### 5. WebSocket 연결

CC가 `--ws_url`에 연결:
```
ws://ebs-bo.local/ws/cc?table_id=5&token={launch_token}&format=json
```

(format 협상은 CCR-021 참조)

**BO 측 검증**:
- `launch_token`의 JWT 유효성 + 만료 확인
- `table_id`가 cc_sessions 레코드와 일치
- `cc_instance_id`를 토큰 claim에서 추출하여 검증

**연결 성공 시**:
- `cc_sessions.status` → `ACTIVE`
- Heartbeat 타이머 시작 (API-05 §하트비트 참조)

**연결 실패 시**:
- HTTP 401 또는 1008 close code
- CC 앱이 "Authentication failed. Please re-launch from Lobby." 에러 화면

#### 6. 초기 상태 수신

BO가 연결 성공 후 즉시 초기 상태를 push:

```json
{
  "type": "InitialState",
  "payload": {
    "table": { /* DATA-02 Table 엔티티 */ },
    "hand": { /* 진행 중 HAND 또는 null */ },
    "seats": [ /* 10 seats */ ],
    "blind_structure": { /* ... */ },
    "active_skin_id": "skin-uuid",
    "security_delay_seconds": 30
  }
}
```

CC는 이 payload로 IDLE 또는 진행 중 HandFSM 상태로 렌더링.

#### 7. 등록 완료 알림

BO가 다음 이벤트를 발행:
- Lobby로: `CCRegistered { cc_instance_id, table_id, operator_id, pid? }`
- Lobby UI: Table Row의 "Launch CC" 버튼이 "Focus CC" + 녹색 인디케이터로 변경

### 실패 복구

#### Launch Token 만료 (5분 초과)

사용자가 Launch 버튼 누르고 CC 앱 실행까지 5분 초과 (예: 수동 다운로드 중):
- BO가 WebSocket 연결 시 JWT 만료 감지 → 401
- CC 앱이 "Launch token expired. Re-launch from Lobby." 화면
- Lobby에서 재Launch 필요 (새 token 발급)

#### 중복 Launch (동일 operator × table)

- 첫 번째 CC 인스턴스가 이미 ACTIVE
- 운영자가 Lobby에서 다시 Launch 클릭
- BO 응답: HTTP 409 Conflict
- Lobby가 선택 다이얼로그:
  - "Focus existing CC" (기존 창으로 포커스)
  - "Force Takeover" (기존 종료 + 신규)
  - "Cancel"

#### Force Takeover

- Lobby가 `POST /tables/{id}/launch { force_takeover: true }` 재전송
- BO: 기존 cc_session을 `CLOSED`로 marking + 기존 CC에 `ForceClose` WebSocket 메시지 발송
- 기존 CC: 5초 카운트다운 후 앱 종료
- 신규 CC: 정상 Launch 플로우 진행

## Launch 상태 FSM

```
LAUNCHING ──WS 연결 성공──▶ ACTIVE ──runtime──▶ CLOSED
    │                         │
    │ token 만료                │ operator close / force takeover
    │ 또는 WS 실패               │
    ▼                         ▼
  FAILED                    CLOSED
```
```

### 2. API-01 §POST /tables/{id}/launch (확인 또는 신규)

API-01에 해당 엔드포인트가 없으면 다음 섹션 추가:

```markdown
### POST /tables/{id}/launch

CC 인스턴스 Launch를 위한 세션 생성 및 launch_token 발급.

**Request**:
```json
{
  "operator_id": 42,
  "force_takeover": false
}
```

**Response (200)**:
```json
{
  "cc_instance_id": "uuid-1234",
  "launch_token": "eyJhbGc...",
  "ws_url": "ws://ebs-bo.local/ws/cc",
  "expires_at": "2026-04-10T14:35:00Z"
}
```

**Errors**:
- 401: Unauthenticated
- 403: RBAC 거부 (operator가 해당 테이블 미할당)
- 404: Table not found
- 409: 이미 이 operator가 해당 테이블에 연결됨 (`force_takeover: false`)
- 422: Table FSM이 `EMPTY` / `CLOSED` (Launch 불가)
```

## 영향 분석

### Team 1 (Lobby/Frontend)
- **영향**:
  - Lobby의 Table Row "Launch CC" 버튼 구현
  - OS별 CC 앱 실행 로직 (또는 deep link)
  - 409 Conflict 시 선택 다이얼로그
  - CC 앱 부재 시 Download 링크
- **예상 작업 시간**: 12시간

### Team 2 (Backend)
- **영향**:
  - `POST /tables/{id}/launch` 엔드포인트 구현 (또는 기존 확인)
  - `cc_sessions` DB 테이블 스키마 확인 (DATA-02)
  - `launch_token` JWT 발급 + 5분 만료
  - `ForceClose` WebSocket 메시지 구현
  - `CCRegistered` 이벤트 발행
- **예상 작업 시간**: 12시간

### Team 4 (self)
- **영향**:
  - CC 앱이 command-line args 파싱 (`--table_id`, `--token` 등)
  - 연결 중 스플래시 화면
  - 인증 실패 에러 화면
  - `ForceClose` 수신 시 5초 카운트다운 + 종료
- **예상 작업 시간**: 8시간

### 마이그레이션
- 기존 CC 앱은 명시적 Launch 플로우 없이 동작 가능 → 본 CCR 승인 후 모든 CC 인스턴스는 Launch 플로우 필수

## 대안 검토

### Option 1: 현재 한 줄 설명 유지
- **단점**: 
  - Team 1/2/4가 임의 구현
  - Launch 실패 시나리오 처리 불일치
- **채택**: ❌

### Option 2: 7단계 플로우 + 실패 복구 명세 (본 제안)
- **장점**:
  - Launch 전 과정 결정론적 정의
  - 실패/중복/takeover 시나리오 명확
- **채택**: ✅

### Option 3: Deep link만 사용 (OS 앱 실행 생략)
- **단점**: 
  - CC 앱이 OS에 등록되지 않으면 작동 불가
  - 첫 설치 시 문제
- **채택**: ❌

## 검증 방법

### 1. 정상 플로우
- [ ] Lobby에서 Launch 클릭 → 5초 이내 CC 앱 실행 + ACTIVE 상태
- [ ] 초기 상태 수신 후 IDLE 화면 렌더링
- [ ] Lobby에 CCRegistered 이벤트 도착 확인

### 2. Token 만료
- [ ] Launch 후 6분 대기 → CC 앱 WebSocket 연결 → 401 + 에러 화면

### 3. 중복 Launch
- [ ] 첫 Launch 성공 → 두 번째 Launch 시도 → 409 + 선택 다이얼로그
- [ ] "Focus existing CC" 선택 → 기존 CC 창 전면으로

### 4. Force Takeover
- [ ] 두 번째 Launch에서 "Force Takeover" 선택
- [ ] 기존 CC에 ForceClose 메시지 도달 → 5초 카운트다운 → 종료
- [ ] 신규 CC 정상 실행

### 5. RBAC
- [ ] Viewer 권한 사용자가 Launch 시도 → 403
- [ ] 해당 테이블 미할당 Operator → 403
- [ ] Admin은 모든 테이블 Launch 가능

## 승인 요청

- [ ] Conductor 승인
- [ ] Team 1 기술 검토 (OS 앱 실행, 409 다이얼로그)
- [ ] Team 2 기술 검토 (Launch API, ForceClose 이벤트)
- [ ] Team 4 기술 검토 (CLI args, 연결 실패 복구)
