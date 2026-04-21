# Team 2: Backend (BO) — CLAUDE.md (코드 전용)

## 🎯 2026-04-21 이관 시 우선 작업 (MUST READ)

**전체 이관 가이드**: `docs/4. Operations/Multi_Session_Handoff.md` — 세션 시작 시 필독.

### team2 우선 작업 (기준 커밋 `7543452`)

1. **Fresh DB workflow 확립** — `python team2-backend/tools/init_db.py --force` (init.sql + alembic stamp head 자동, 25 tables). 이 한 명령으로 DB 재빌드.
2. **IMPL-003 decks.py DB session 교체** — `docs/4. Operations/Conductor_Backlog/IMPL-003-team2-decks-db-session.md`. 현재 in-memory (13 test PASS). `TODO-T2-004` 마커 해소
3. **settings_kv.py DB session 교체** — `src/routers/settings_kv.py` 현재 in-memory 4-level resolver 실동작 (11 test PASS). `TODO-T2-011` 마커 해소
4. **reports.py MV 실DB 쿼리** — `src/routers/reports.py` 6 endpoint 현재 mock data 실동작 (13 test PASS). `TODO-T2-009` MV 설계 + aggregation 실구현
5. **publishers.py trigger 연결** — `src/websocket/publishers.py` 20 event publisher skeleton 완료 (5 test PASS, drift D2 20→0). `TODO-T2-014` 실제 trigger (router/service) 에서 호출 wiring
6. **SG-008 (a) 77 endpoint 실구현** — `Backend_HTTP.md §5.17` 편입 완료. 코드는 대부분 skeleton/존재. 실제 response schema + DB 연결 + RBAC 가드 완결
7. **SG-008 (b1~b9) 9 endpoint 실구현** — audit-events/logs-read/download, auth-me/logout, sync-status/trigger, sync-mock-seed/reset
8. **SG-008-b14 2FA migration 0006** — users 테이블 twofa_enabled/secret/backup_codes 컬럼 + 6 endpoint 구현
9. **Users Suspend/Lock/Delete 3상태** (NOTIFY-CCR-053) + **audit_events event_type 카탈로그** (NOTIFY-CCR-039)
10. **SG-004 .gfskin 업로드 검증 endpoint** — `tools/validate_gfskin.py` 재사용하여 POST /api/v1/skins 에 8 단계 검증

### 주요 도구

- `python team2-backend/tools/init_db.py --force` — fresh DB
- `python -m pytest team2-backend/tests/` — 247 tests baseline
- `python tools/spec_drift_check.py --api --websocket --schema --fsm --settings`

### 현 baseline
- pytest 247 tests 0 errors
- drift: events/fsm/websocket **완전 PASS**, api D3=0, schema D4=23
- FSM enums: `src/db/enums.py` 7종 canonical (TableFSM/HandFSM/SeatFSM/PlayerStatus/DeckFSM/EventFSM/ClockFSM)

---

## 브랜치 규칙

- **작업 브랜치**: `work/team2/{YYYYMMDD}-session` (SessionStart hook 자동 생성)
- **main 직접 작업 금지** — commit/push 차단됨
- **병합**: `/team-merge` 커맨드로만 main 병합 (Conductor 세션 권장)

## Role

FastAPI Back Office — REST API + WebSocket 서버 + DB 관리 + WSOP LIVE 동기화.

**기술 스택**: FastAPI (Python) + SQLite (dev) / PostgreSQL (prod)

**Publisher**: API-01, API-05, API-06, DATA-* 스키마, Back Office 전반.

---

## 문서 위치 (docs v10)

**팀 문서는 모두 `docs/2. Development/2.2 Backend/` 에 있다. 이 폴더는 코드 전용.**

| 문서 카테고리 | 경로 |
|--------------|------|
| 섹션 landing | `../docs/2. Development/2.2 Backend/2.2 Backend.md` |
| APIs (publisher) | `../docs/2. Development/2.2 Backend/APIs/` |
| Database (publisher) | `../docs/2. Development/2.2 Backend/Database/` |
| Back Office (publisher) | `../docs/2. Development/2.2 Backend/Back_Office/` |
| Engineering (IMPL-*) | `../docs/2. Development/2.2 Backend/Engineering/` |
| Backlog | `../docs/2. Development/2.2 Backend/Backlog.md` |

### Publisher 직접 편집 권한

team2는 자기 소유 계약 파일을 직접 수정 가능:

| 파일 | 직접 수정 허용 |
|------|---------------|
| `../docs/2. Development/2.2 Backend/APIs/**` | ✓ |
| `../docs/2. Development/2.2 Backend/Database/**` | ✓ |
| `../docs/2. Development/2.2 Backend/Back_Office/**` | ✓ |

파괴적 변경(remove/rename/breaking) 시 subscriber 팀 전원 사전 합의 필수.

## 소유 경로 (코드)

| 경로 | 내용 |
|------|------|
| `src/` | FastAPI 소스 코드 |
| `src/db/init.sql` | 권위 DDL — `../docs/2. Development/2.2 Backend/Database/Schema.md` 와 일치 필수 |
| `migrations/` | Alembic 마이그레이션 (baseline `0001_baseline`) |
| `tests/` | pytest |
| `seed/` | 시드 데이터 |
| `pyproject.toml`, `alembic.ini`, `docker-compose.yml`, `Dockerfile` | 설정 |

## 구현 대상 API

| API | 역할 |
|-----|------|
| API-01 | 66+ REST 엔드포인트 전체 구현 |
| API-01 Part II | WSOP LIVE 폴링 동기화 워커 |
| API-05 | WebSocket 3채널 (cc_command, cc_event, lobby_monitor) |
| API-06 | JWT 발행, RBAC, Google OAuth |

## 다른 팀이 소유하는 공통 계약 (읽기 전용)

| 계약 | 경로 | 소유 |
|------|------|------|
| BS-00 공통 정의 | `../docs/2. Development/2.5 Shared/BS_Overview.md` | conductor |
| BS-01 Authentication | `../docs/2. Development/2.5 Shared/Authentication.md` | conductor |
| API-03 RFID HAL | `../docs/2. Development/2.4 Command Center/APIs/RFID_HAL.md` | team4 |
| API-04 Overlay Output | `../docs/2. Development/2.3 Game Engine/APIs/Overlay_Output_Events.md` | team3 |

수정 필요 시 해당 문서를 직접 보강 (additive). decision_owner 는 publisher 팀.

## 기획 공백 발견 시

개발 중 기획 문서에 없는 판단이 필요하면 해당 기획 문서를 **즉시 보강**한다 (additive). decision_owner 는 `team-policy.json` 참조. 상세: `../CLAUDE.md` §"문서 변경 거버넌스".

## 금지

- `../docs/1. Product/`, `../docs/2. Development/2.{1,3,4,5}*/`, `../docs/4. Operations/` 수정 금지 (다른 팀 소유)
- 다른 팀 코드 폴더(`../team1-frontend/`, `../team3-engine/`, `../team4-cc/`) 접근 금지
- Game Engine 코드 직접 참조 금지

## Build

- 린트: `ruff check src/ --fix`
- 테스트 (개별): `pytest tests/test_specific.py -v`
- 테스트 (전체): `pytest tests/ -v` (~50s, 95/95 pass, 90% 커버리지)
- 마이그레이션: `python -m alembic upgrade head`

> 2026-04-14 기준: 95/95 pass in 49s. Alembic baseline `0001_baseline`. SQLModel 12 테이블 커버, 나머지 12 테이블은 `init.sql` 권위.
