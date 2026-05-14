---
title: PLAN-BO-Phase1
owner: conductor
tier: internal
last-updated: 2026-04-15
confluence-page-id: 3819209396
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819209396/EBS+PLAN-BO-Phase1
---

# PLAN-BO-Phase1 — Back Office Phase 1 실행 계획

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | Phase 1 (2026 상반기) 실행 계획 |

---

## 개요

**목표**: FastAPI + SQLite + JWT + WebSocket 기반 BO 서버 최초 구동  
**기간**: 2026 상반기 (6개월)  
**완료 기준**: Phase 1 체크리스트 100% 통과 (B-001~B-020)  
**기술 스택**: Python 3.11+ / FastAPI / SQLAlchemy / Alembic / SQLite / WebSocket

---

## 구현 순서 (의존성 그래프)

```
[B-001] FastAPI 초기화
   │
   ├─[B-002] DB 스키마 (13개 테이블)
   │    │
   │    ├─[B-003] JWT 인증
   │    │    └─[B-004] RBAC 미들웨어
   │    │         ├─[B-005] 사용자 관리 CRUD
   │    │         ├─[B-009] 감사 로그
   │    │         ├─[B-011] Series CRUD
   │    │         │    └─[B-012] Event CRUD + FSM
   │    │         │         └─[B-013] Flight CRUD
   │    │         │              └─[B-014] 테이블 CRUD
   │    │         │                   └─[B-015] TableFSM
   │    │         │                        └─[B-016] 좌석 관리
   │    │         └─[B-017] 플레이어 관리
   │    │
   │    ├─[B-006] 설정 API
   │    │    ├─[B-008] ConfigChanged 이벤트 (B-007 필요)
   │    │    └─[B-010] Mock RFID 모드
   │    │
   │    └─[B-018] Mock 시드 스크립트
   │
   ├─[B-007] WebSocket 허브 (B-001만 필요, 병렬 가능)
   │    └─[B-008] ConfigChanged 이벤트
   │
   └─[B-019] 에러 응답 + 헬스체크 (B-001만 필요, 병렬 가능)

[B-020] Phase 1 통합 테스트 (B-001~B-019 완료 후)
```

---

## 디렉토리 구조

```
backend/
├── main.py                  FastAPI 앱 진입점
├── config.py                환경변수 로드 (.env)
├── database.py              SQLAlchemy 세션 관리
├── pyproject.toml
├── requirements.txt
├── .env.example
│
├── models/                  SQLAlchemy ORM 모델
│   ├── user.py              users, user_sessions
│   ├── tournament.py        series, events, event_flights
│   ├── table.py             tables, table_seats
│   ├── player.py            players
│   ├── hand.py              hands, hand_players, hand_actions
│   ├── config.py            configs
│   └── audit.py             audit_logs
│
├── routers/                 FastAPI 라우터
│   ├── auth.py              /auth/*
│   ├── users.py             /users/*
│   ├── series.py            /series/*
│   ├── events.py            /events/*
│   ├── tables.py            /tables/*
│   ├── players.py           /players/*
│   ├── configs.py           /configs/*
│   ├── audit.py             /audit-logs/*
│   ├── health.py            /health/*
│   └── sync.py              /sync/*
│
├── services/                비즈니스 로직
│   ├── auth_service.py      JWT, TOTP, 세션
│   ├── table_fsm.py         TableFSM 상태 전이
│   ├── event_fsm.py         EventFSM 상태 전이
│   └── audit_service.py     감사 로그 자동 기록
│
├── websocket/               WebSocket 허브
│   ├── hub.py               채널 관리, 브로드캐스트
│   └── handlers.py          메시지 핸들러
│
├── schemas/                 Pydantic 스키마 (요청/응답)
│   ├── auth.py
│   ├── user.py
│   ├── tournament.py
│   ├── table.py
│   ├── player.py
│   └── config.py
│
├── dependencies/            FastAPI Dependency
│   ├── auth.py              현재 사용자, 역할 검증
│   └── db.py                DB 세션
│
├── middleware/              미들웨어
│   ├── audit_middleware.py  감사 로그 자동 기록
│   └── error_handler.py     표준 에러 응답
│
├── alembic/                 DB 마이그레이션
│   ├── env.py
│   └── versions/
│
├── seeds/                   초기 데이터
│   ├── config_defaults.py   설정 초기값
│   └── mock_data.py         Mock 시드 (B-018)
│
└── tests/                   테스트
    ├── test_auth.py
    ├── test_users.py
    ├── test_tables.py
    ├── test_configs.py
    ├── test_websocket.py
    └── conftest.py
```

---

## 핵심 구현 명세

### 1. DB 스키마 (B-002)

**13개 테이블 생성 순서** (FK 의존성 순):
1. `users`
2. `user_sessions` (FK: users)
3. `series`
4. `events` (FK: series)
5. `event_flights` (FK: events)
6. `tables` (FK: event_flights)
7. `table_seats` (FK: tables, players)
8. `players`
9. `hands` (FK: tables)
10. `hand_players` (FK: hands, players)
11. `hand_actions` (FK: hands)
12. `configs`
13. `audit_logs` (FK: users)

### 2. WebSocket 메시지 포맷 (B-007)

```json
{
  "type": "ConfigChanged | TableStatusChanged | OperatorConnected | Heartbeat",
  "table_id": "uuid | null",
  "payload": {},
  "timestamp": "2026-04-09T12:00:00Z",
  "seq": 1001
}
```

### 3. 설정 초기값 (B-006)

| 카테고리 | 키 | 기본값 |
|---------|-----|--------|
| Output | output.type | `none` |
| Output | resolution | `1920x1080` |
| Output | framerate | `60` |
| Overlay | skin_id | `default` |
| Overlay | show_equity | `false` |
| Game | auto_advance | `true` |
| Game | undo_limit | `3` |
| Statistics | show_vpip | `false` |
| System | rfid_mode | `mock` |
| System | log_level | `info` |
| System | auto_backup | `true` |
| System | backup_interval_min | `30` |
| System | wsop_api_poll_sec | `30` |

### 4. LOCK/CONFIRM/FREE 분류 (B-008)

| 분류 | 필드 | 적용 시점 |
|------|------|----------|
| LOCK | game_type, max_players, rfid_reader_id | CC 활성 중 변경 불가 |
| CONFIRM | small_blind, big_blind, ante_type, output_type | 다음 핸드부터 |
| FREE | show_equity, show_cards, animation_speed 등 오버레이 | 즉시 적용 |

### 5. TableFSM 전이 조건 (B-015)

| 현재 상태 | 다음 상태 | 전제조건 |
|----------|---------|---------|
| EMPTY | SETUP | — |
| SETUP | LIVE | CC 연결 1개 이상 |
| LIVE | PAUSED | — |
| PAUSED | LIVE | — |
| LIVE | CLOSED | CC 연결 없음 |
| PAUSED | CLOSED | — |
| CLOSED | EMPTY | — |

### 6. EventFSM 전이 조건 (B-012)

| 현재 상태 | 다음 상태 | 전제조건 |
|----------|---------|---------|
| Created | Announced | — |
| Announced | Registering | — |
| Registering | Running | Flight 1개 이상 Running |
| Running | Completed | 모든 Flight Completed |

---

## Phase 1 완료 체크리스트

- [ ] B-001: `uvicorn backend.main:app` 기동 성공
- [ ] B-002: `alembic upgrade head` — 13개 테이블 생성
- [ ] B-003: `POST /auth/login` JWT 토큰 발급
- [ ] B-003: TOTP 코드 검증 성공
- [ ] B-004: Viewer → POST 요청 403 응답
- [ ] B-005: 마지막 Admin 비활성화 → 400 응답
- [ ] B-006: `GET /configs/system` 초기값 조회
- [ ] B-007: WebSocket 연결 → 10초 하트비트 수신
- [ ] B-007: 30초 무응답 → 자동 연결 해제
- [ ] B-008: 설정 변경 → CC에 ConfigChanged 이벤트 수신
- [ ] B-009: 사용자 생성 → audit_logs에 user.created 기록
- [ ] B-010: Live 테이블 있을 때 rfid_mode→mock → 409 응답
- [ ] B-011: Series CRUD + 목록 페이지네이션
- [ ] B-012: Event 역방향 상태 전이 → 422 응답
- [ ] B-013: Flight 생성 → Event에 연결 확인
- [ ] B-014: Feature Table vs General Table 구분 생성
- [ ] B-015: EMPTY→LIVE 직접 전이 → 422 응답
- [ ] B-016: 무작위 좌석 배치 성공
- [ ] B-017: 플레이어 자동완성 검색 동작
- [ ] B-018: seed 실행 → Series 3건, Player 100명 조회
- [ ] B-019: `/health/db` → DB 연결 상태 반환
- [ ] B-020: `pytest backend/tests/ -v` 전체 통과

---

## 참조 문서

| 문서 | 경로 |
|------|------|
| BO Overview | `team2-backend/specs/back-office/BO-01-overview.md` |
| 사용자 관리 | `team2-backend/specs/back-office/BO-02-user-management.md` |
| 대회 관리 | `team2-backend/specs/back-office/BO-03-tournament-management.md` |
| 테이블 관리 | `team2-backend/specs/back-office/BO-04-table-management.md` |
| 플레이어 DB | `team2-backend/specs/back-office/BO-05-player-database.md` |
| 시스템 설정 | `team2-backend/specs/back-office/BO-07-system-config.md` |
| 감사 로그 | `team2-backend/specs/back-office/BO-08-audit-log.md` |
| 데이터 동기화 | `team2-backend/specs/back-office/BO-09-data-sync.md` |
| Settings 행동 명세 | `Settings/Overview.md` (legacy-id: BS-03-00) |
| 백로그 | `docs/backlog.md` |
