# Phase 2: WSOPLIVE DB 연동

> **BRACELET STUDIO** | EBS Project

**완료 시점**: 2027년 Q4
**목표**: WSOPLIVE 데이터베이스와 완전 연동하여 수동 입력 30% 감소
**전제조건**: Phase 0 Gate 100% 통과

---

## 1. Phase 2 개요

### 1.1 목표

> **"WSOPLIVE 데이터베이스와 연동하여 중복 입력을 제거한다"**

Phase 2는 WSOPLIVE 시스템의 데이터를 EBS와 동기화하여
운영자의 수동 입력 부담을 30% 이상 줄이는 것이 목표입니다.

### 1.2 핵심 원칙

| 원칙 | 설명 | 실패 시 처리 |
|------|------|-------------|
| **듀얼 소스** | EBS + WSOPLIVE 두 소스 통합 | - |
| **양방향 동기화** | EBS ↔ WSOPLIVE 데이터 흐름 | - |
| **Graceful Degradation** | 연결 실패 시 Phase 0 모드 | 수동 입력 폴백 |

### 1.3 성공 기준

| 기준 | 목표 | 검증 방법 |
|------|------|----------|
| 수동 입력 감소 | 30% 이상 | 입력 횟수 비교 |
| 데이터 정합성 | 100% (칩 카운트) | WSOPLIVE vs EBS 비교 |
| 동기화 지연 | < 5초 (95th percentile) | 성능 테스트 |
| 연결 가동률 | 99%+ (24시간 기준) | 모니터링 로그 |

---

## 2. 연동 범위

### 2.1 동기화 대상 데이터

| 데이터 | 방향 | 마스터 | 동기화 타이밍 | 우선순위 |
|--------|------|--------|--------------|:--------:|
| **플레이어 정보** | WSOPLIVE → EBS | WSOPLIVE | 토너먼트 시작 시 | P0 |
| **칩 카운트** | 양방향 | WSOPLIVE (브레이크) | 브레이크/핸드 종료 | P0 |
| **핸드 히스토리** | EBS → WSOPLIVE | EBS | 핸드 종료 시 | P1 |
| **플레이어 통계** | WSOPLIVE → EBS | WSOPLIVE | 요청 시 | P1 |
| **블라인드 레벨** | WSOPLIVE → EBS | WSOPLIVE | 레벨 변경 시 | P0 |
| **테이블 배치** | WSOPLIVE → EBS | WSOPLIVE | 테이블 이동 시 | P0 |

### 2.2 동기화 제외 항목

| 항목 | 제외 이유 |
|------|----------|
| 카드 정보 (홀카드/보드) | 보안 - EBS 독점 관리 |
| 실시간 베팅 액션 | 지연 이슈 - 수동 입력 유지 |
| UI 스킨/설정 | EBS 로컬 관리 |

### 2.3 데이터 흐름 다이어그램

```
┌─────────────────────────────────────────────────────────────────────┐
│                         WSOPLIVE Database                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐            │
│  │ Players  │  │  Chips   │  │  Tables  │  │  Stats   │            │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘            │
└───────┼─────────────┼─────────────┼─────────────┼───────────────────┘
        │             │             │             │
        ▼             ▼             ▼             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         Sync Service                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │   Poller     │  │   Conflict   │  │    Queue     │              │
│  │  (5초 간격)  │  │   Resolver   │  │   Manager    │              │
│  └──────────────┘  └──────────────┘  └──────────────┘              │
└─────────────────────────────────────────────────────────────────────┘
        │             │             │             │
        ▼             ▼             ▼             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          EBS Database                                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐            │
│  │ Players  │  │  Chips   │  │  Hands   │  │  Cards   │            │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘            │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 3. 데이터 동기화 상세

### 3.1 플레이어 정보 동기화

#### 동기화 필드

| 필드 | 소스 | 초기화 시점 | 업데이트 시점 |
|------|------|------------|--------------|
| 이름 | WSOPLIVE | 토너먼트 시작 | 변경 없음 |
| 국적 | WSOPLIVE | 토너먼트 시작 | 변경 없음 |
| 시트 번호 | WSOPLIVE | 테이블 배정 | 테이블 이동 |
| WSOP ID | WSOPLIVE | 토너먼트 시작 | 변경 없음 |
| 프로필 이미지 URL | WSOPLIVE | 토너먼트 시작 | 변경 없음 |

#### 동기화 로직

```python
def sync_players(wsop_table_id: str) -> List[Player]:
    """토너먼트 시작 시 플레이어 정보 동기화"""

    # 1. WSOPLIVE API에서 플레이어 목록 조회
    wsop_players = wsop_api.get_table_players(wsop_table_id)

    # 2. EBS DB에 플레이어 정보 저장
    for wp in wsop_players:
        player = Player(
            name=wp.display_name,
            seat=wp.seat_number,
            stack=wp.chip_count,
            wsop_id=wp.player_id,
            nationality=wp.country_code
        )
        db.upsert(player)

    # 3. 동기화 상태 기록
    sync_log.record('players', 'pull', len(wsop_players))

    return db.get_all_players()
```

### 3.2 칩 카운트 동기화

#### 동기화 타이밍

| 이벤트 | 방향 | 설명 |
|--------|------|------|
| **토너먼트 시작** | WSOPLIVE → EBS | 초기 스택 가져오기 |
| **핸드 종료** | EBS → WSOPLIVE | 칩 변동 전송 |
| **브레이크 시작** | WSOPLIVE → EBS | 공식 칩 카운트로 보정 |
| **리바이/애드온** | WSOPLIVE → EBS | 칩 추가 반영 |

#### 동기화 흐름

```
[WSOPLIVE] ─────────────────────────────────────────> [EBS]
          토너먼트 시작: 초기 스택 PULL
                    │
[WSOPLIVE] <────────── │ ────────────────────────────> [EBS]
                    │ 브레이크: 양방향 보정
                    │
[WSOPLIVE] <───────────┴───────────────────────────── [EBS]
          핸드 종료: 칩 변동 PUSH
```

#### 칩 보정 로직

```python
def reconcile_chips(ebs_chips: dict, wsop_chips: dict) -> dict:
    """브레이크 시 칩 카운트 보정"""

    reconciled = {}
    conflicts = []

    for seat, ebs_count in ebs_chips.items():
        wsop_count = wsop_chips.get(seat, 0)

        # 5% 이상 차이나면 충돌로 기록
        if abs(ebs_count - wsop_count) / max(ebs_count, wsop_count) > 0.05:
            conflicts.append({
                'seat': seat,
                'ebs': ebs_count,
                'wsop': wsop_count,
                'diff': ebs_count - wsop_count
            })

        # WSOPLIVE 값을 마스터로 사용
        reconciled[seat] = wsop_count

    if conflicts:
        notify_operator(conflicts)

    return reconciled
```

### 3.3 핸드 히스토리 동기화

#### 전송 데이터 형식

```json
{
  "hand_id": "EBS-2026012800001",
  "wsop_table_id": "TABLE-42",
  "timestamp": "2026-01-28T14:30:00Z",
  "blinds": {
    "sb": 100,
    "bb": 200,
    "ante": 25
  },
  "players": [
    {"seat": 1, "name": "John Doe", "stack_start": 50000, "stack_end": 52000}
  ],
  "actions": [
    {"seat": 1, "street": "preflop", "action": "raise", "amount": 500}
  ],
  "board": ["A♠", "K♥", "Q♦", "J♣", "10♠"],
  "pot": 15000,
  "winners": [
    {"seat": 3, "amount": 15000}
  ]
}
```

#### 전송 로직

```python
async def push_hand_history(hand_id: int):
    """핸드 종료 시 히스토리 전송"""

    hand = db.get_hand(hand_id)
    actions = db.get_actions(hand_id)
    players = db.get_hand_players(hand_id)

    payload = format_hand_history(hand, actions, players)

    try:
        response = await wsop_api.post_hand(payload)
        sync_log.record('hand', 'push', hand_id, 'success')
    except Exception as e:
        # 실패 시 큐에 저장, 나중에 재시도
        retry_queue.add(payload)
        sync_log.record('hand', 'push', hand_id, 'queued')
```

---

## 4. API 설계

### 4.1 WSOPLIVE API 엔드포인트 (예상)

| Endpoint | Method | 용도 | 응답 |
|----------|--------|------|------|
| `/api/tournaments/{id}/players` | GET | 플레이어 목록 | Player[] |
| `/api/tournaments/{id}/tables/{table_id}` | GET | 테이블 정보 | Table |
| `/api/tournaments/{id}/tables/{table_id}/chips` | GET/PUT | 칩 카운트 | ChipCount[] |
| `/api/players/{id}/stats` | GET | 플레이어 통계 | Stats |
| `/api/hands` | POST | 핸드 히스토리 전송 | HandId |
| `/api/blinds/current` | GET | 현재 블라인드 레벨 | BlindLevel |

### 4.2 EBS 신규 API 엔드포인트

| Endpoint | Method | 용도 | 설명 |
|----------|--------|------|------|
| `/api/sync/init` | POST | 동기화 초기화 | WSOPLIVE 연결 시작 |
| `/api/sync/status` | GET | 동기화 상태 | 연결 상태, 마지막 동기화 |
| `/api/sync/chips` | POST | 칩 동기화 트리거 | 수동 동기화 |
| `/api/sync/players` | POST | 플레이어 동기화 | 수동 동기화 |
| `/api/sync/conflicts` | GET | 충돌 목록 | 미해결 충돌 조회 |
| `/api/sync/conflicts/{id}/resolve` | POST | 충돌 해결 | 수동 해결 |

### 4.3 인증/권한

| 항목 | 방식 | 비고 |
|------|------|------|
| 인증 방식 | OAuth 2.0 (예상) | WSOPLIVE 측 확인 필요 |
| 권한 범위 | 테이블별 scope | tournament:{id}:table:{id} |
| 토큰 갱신 | Refresh Token | 만료 5분 전 갱신 |
| 통신 암호화 | TLS 1.3 | 필수 |

---

## 5. 데이터베이스 확장

### 5.1 동기화 상태 테이블

```sql
CREATE TABLE sync_status (
    id INTEGER PRIMARY KEY,
    entity_type TEXT NOT NULL,      -- 'player', 'chips', 'hand'
    entity_id TEXT NOT NULL,
    wsop_id TEXT,                   -- WSOPLIVE 측 ID
    last_sync_at TIMESTAMP,
    sync_direction TEXT,            -- 'pull', 'push', 'bidirectional'
    status TEXT DEFAULT 'pending',  -- 'pending', 'synced', 'conflict', 'error'
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(entity_type, entity_id)
);

CREATE INDEX idx_sync_status ON sync_status(entity_type, status);
```

### 5.2 충돌 로그 테이블

```sql
CREATE TABLE sync_conflicts (
    id INTEGER PRIMARY KEY,
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    ebs_value TEXT,                 -- JSON 형식
    wsop_value TEXT,                -- JSON 형식
    resolution TEXT,                -- 'ebs_wins', 'wsop_wins', 'manual'
    resolved_by TEXT,               -- 운영자 ID
    resolved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 5.3 재시도 큐 테이블

```sql
CREATE TABLE sync_retry_queue (
    id INTEGER PRIMARY KEY,
    payload TEXT NOT NULL,          -- JSON
    endpoint TEXT NOT NULL,
    method TEXT NOT NULL,
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    next_retry_at TIMESTAMP,
    status TEXT DEFAULT 'pending',  -- 'pending', 'processing', 'completed', 'failed'
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_retry_queue ON sync_retry_queue(status, next_retry_at);
```

---

## 6. 에러 핸들링

### 6.1 연결 실패 시 폴백

```
연결 상태 감지 (5초 간격)
        │
        ├── Connected: 정상 동기화
        │
        └── Disconnected (3회 연속 실패):
            ├── 경고 UI 표시 ("WSOPLIVE 연결 끊김")
            ├── Phase 0 모드 전환 (수동 입력)
            ├── 로컬 큐에 변경사항 저장
            └── 재연결 시 큐 자동 동기화
```

### 6.2 데이터 불일치 처리

| 불일치 유형 | 감지 방법 | 알림 | 자동 해결 |
|------------|----------|------|----------|
| 칩 카운트 차이 > 5% | 브레이크 비교 | 운영자 경고 | WSOPLIVE 값 사용 |
| 플레이어 누락 | 목록 비교 | 운영자 경고 | WSOPLIVE 추가 |
| 핸드 전송 실패 | ACK 타임아웃 | 시스템 로그 | 재전송 (3회) |
| 스택 마이너스 | 계산 검증 | 즉시 알림 | 수동 개입 |

### 6.3 롤백 절차

```python
def rollback_sync(sync_id: str):
    """동기화 실패 시 롤백"""

    # 1. 동기화 실패 감지
    sync = db.get_sync(sync_id)

    # 2. 로컬 트랜잭션 롤백
    db.rollback_to_checkpoint(sync.checkpoint_id)

    # 3. 이전 상태 복원
    restore_previous_state(sync.entity_type, sync.entity_id)

    # 4. 운영자 알림
    notify_operator({
        'type': 'sync_rollback',
        'entity': sync.entity_type,
        'reason': sync.error_message
    })

    # 5. 수동 재동기화 옵션 제공
    return {'status': 'rolled_back', 'manual_sync_available': True}
```

---

## 7. UI 변경사항

### 7.1 연결 상태 표시

연결 상태 패널은 WSOPLIVE 연결 여부(Connected/Disconnected), 마지막 동기화 시각, 데이터 유형별(Players/Chips/Blinds) 동기화 상태를 표시한다. 연결 끊김 시 Manual mode 전환 안내와 [Retry Connection] / [Continue Offline] 버튼을 노출한다.

### 7.2 충돌 해결 UI

충돌 해결 패널은 충돌 발생 시트 번호, EBS/WSOPLIVE 각각의 칩 카운트, 차이(절대값 및 %)를 표시한다. [Use EBS] / [Use WSOPLIVE (Recommended)] / [Enter Manually] 3개 액션 버튼을 제공한다.

### 7.3 동기화 로그 패널

| 시간 | 유형 | 방향 | 상태 | 상세 |
|------|------|------|------|------|
| 14:30:05 | Chips | Pull | ✅ Success | 10 players synced |
| 14:29:58 | Hand | Push | ✅ Success | Hand #127 |
| 14:25:00 | Players | Pull | ⚠️ Conflict | Seat 5 name mismatch |

---

## 8. 개발 일정

### 8.1 분기별 마일스톤

| 분기 | 마일스톤 | 주요 기능 | 완료 기준 |
|------|----------|----------|----------|
| **Q1** (1-3월) | Alpha | API 연동 기초 | 연결 상태 모니터링 UI |
| **Q2** (4-6월) | Beta | 칩 동기화 | 브레이크 시 자동 보정 |
| **Q3** (7-9월) | RC | 플레이어 동기화 | 자동 시트 배정, 통계 |
| **Q4** (10-12월) | Release | 전체 통합 | 24시간 안정성 테스트 |

### 8.2 Q1 상세 (Alpha)

- [ ] WSOPLIVE API 문서 확보 및 분석
- [ ] OAuth 2.0 인증 구현
- [ ] 기본 연결 테스트 (ping/pong)
- [ ] 연결 상태 모니터링 UI
- [ ] 자동 재연결 로직
- [ ] 연결 로그 저장

### 8.3 Q2 상세 (Beta)

- [ ] 칩 카운트 Pull 구현
- [ ] 칩 변동 Push 구현
- [ ] 브레이크 시 양방향 보정
- [ ] 충돌 감지 및 알림
- [ ] 수동 충돌 해결 UI

### 8.4 Q3 상세 (RC)

- [ ] 플레이어 정보 자동 로드
- [ ] 테이블 이동 감지 및 반영
- [ ] 플레이어 통계 연동
- [ ] 블라인드 레벨 자동 업데이트
- [ ] 핸드 히스토리 전송

### 8.5 Q4 상세 (Release)

- [ ] 폴백 모드 완전 구현
- [ ] 재시도 큐 자동 처리
- [ ] 24시간 연속 안정성 테스트
- [ ] 성능 최적화 (캐싱)
- [ ] 운영자 교육 및 문서화

---

## 9. 테스트 계획

### 9.1 단위 테스트

| 컴포넌트 | 테스트 항목 | 기대 결과 |
|----------|------------|----------|
| Sync Service | 연결/끊김 감지 | 3초 이내 감지 |
| Conflict Resolver | 충돌 감지 | 5% 이상 차이 감지 |
| Retry Queue | 재시도 로직 | 3회 후 실패 처리 |
| Rollback | 상태 복원 | 이전 상태 정확히 복원 |

### 9.2 통합 테스트

| 시나리오 | 단계 | 검증 |
|----------|------|------|
| **정상 동기화** | 토너먼트 시작 → 동기화 | 플레이어 10명 로드 |
| **연결 끊김** | 3회 실패 → 폴백 | 수동 모드 전환 |
| **재연결** | 연결 복구 → 큐 처리 | 미전송 데이터 동기화 |
| **충돌 해결** | 칩 차이 감지 → 해결 | WSOPLIVE 값 적용 |

### 9.3 안정성 테스트

| 테스트 | 조건 | 통과 기준 |
|--------|------|----------|
| **24시간 연속** | 실제 환경 시뮬레이션 | 99%+ 가동률 |
| **네트워크 불안정** | 50% 패킷 손실 | 데이터 손실 0 |
| **동시 동기화** | 10 테이블 동시 | 지연 < 5초 |

---

## 10. 위험 관리

| 위험 | 영향도 | 발생 확률 | 대응 방안 |
|------|:------:|:--------:|----------|
| WSOPLIVE API 미확정 | 높음 | 중간 | Phase 0 기간 내 확보 필수 |
| API 변경 | 중간 | 중간 | 버전 관리 + 어댑터 패턴 |
| 네트워크 불안정 | 중간 | 높음 | 로컬 큐 + 자동 재연결 |
| 데이터 불일치 | 높음 | 낮음 | 충돌 해결 UI + 알림 |
| 성능 저하 | 중간 | 낮음 | 캐싱 + 배치 처리 |

---

## 11. Phase 2 완료 조건 (Gate)

Phase 2 진입을 위해 다음 조건을 **모두** 충족해야 합니다:

| 조건 | 기준 | 검증 방법 | 담당 |
|------|------|----------|------|
| **연결 안정성** | 24시간 99%+ 가동률 | 모니터링 로그 | 개발팀 |
| **데이터 정합성** | 칩 카운트 100% 일치 | WSOPLIVE vs EBS 비교 | QA |
| **동기화 성능** | 지연 < 5초 (95th) | 성능 테스트 | QA |
| **수동 입력 감소** | 30% 이상 | 입력 횟수 비교 | 운영팀 |
| **폴백 동작** | 정상 작동 | 연결 끊김 테스트 | QA |

---

## 12. 부록

### 12.1 관련 문서

- [Phase 1 PRD](../02_Phase01/PRD-0003-Phase1-PokerGFX-Clone.md)
- [Phase 3 PRD](../04_Phase03_ngd/PRD-0003-Phase3-EBS-Automation.md)
- [Phase Progression Guide](../05_Operations_ngd/PHASE-PROGRESSION.md)

### 12.2 용어 정의

| 용어 | 정의 |
|------|------|
| WSOPLIVE | World Series of Poker 공식 토너먼트 관리 시스템 |
| Pull | WSOPLIVE → EBS 방향 데이터 동기화 |
| Push | EBS → WSOPLIVE 방향 데이터 동기화 |
| Conflict | EBS와 WSOPLIVE 데이터 불일치 상황 |
| Fallback | 연결 실패 시 Phase 0 수동 모드 전환 |

---

**Version**: 3.0.0 | **Updated**: 2026-02-03
