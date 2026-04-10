# Plan: B-020 Phase 1 통합 테스트

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | B-020 Phase 1 통합 테스트 계획 |

---

## 배경

B-001~B-019 구현 완료. `backend/tests/` 디렉토리가 존재하나 테스트 파일이 없음.
pytest-asyncio(asyncio_mode=auto), httpx(ASGITransport) 의존성은 이미 requirements에 포함.

## 구현 범위

| 파일 | 커버 항목 |
|------|----------|
| `tests/conftest.py` | in-memory SQLite DB fixture, async client fixture, Admin 사용자 fixture, JWT 토큰 fixture |
| `tests/test_health.py` | GET /health, GET /health/db |
| `tests/test_auth.py` | 로그인 성공/실패, TOTP 플로우, refresh, logout |
| `tests/test_users.py` | CRUD, 마지막 Admin 보호, RBAC(Viewer 403) |
| `tests/test_series.py` | Series CRUD, 페이지네이션, q 검색 |
| `tests/test_events.py` | Event CRUD, FSM 정방향/역방향, Flight CRUD |
| `tests/test_tables.py` | Table CRUD, TableFSM, 좌석 관리, duplicate |
| `tests/test_players.py` | Player CRUD, search 자동완성 |
| `tests/test_configs.py` | GET/PUT configs, presets, reset |
| `tests/test_audit.py` | 감사 로그 조회, 필터, DELETE 405 |

## 영향 파일

- `backend/tests/conftest.py` (신규)
- `backend/tests/test_health.py` (신규)
- `backend/tests/test_auth.py` (신규)
- `backend/tests/test_users.py` (신규)
- `backend/tests/test_series.py` (신규)
- `backend/tests/test_events.py` (신규)
- `backend/tests/test_tables.py` (신규)
- `backend/tests/test_players.py` (신규)
- `backend/tests/test_configs.py` (신규)
- `backend/tests/test_audit.py` (신규)

## 핵심 설계 결정

### conftest.py fixture 구조
```python
@pytest.fixture
async def db_session():
    # in-memory SQLite, create_all, yield, drop_all

@pytest.fixture
async def client(db_session):
    # ASGITransport(app), lifespan 우회, DB override

@pytest.fixture
async def admin_token(client):
    # POST /users (직접 DB insert) → POST /auth/login → access_token
```

### DB 격리 전략
- 각 테스트 함수마다 fresh DB (`function` scope fixture)
- `app.dependency_overrides[get_db]` 로 테스트 DB 주입
- in-memory SQLite: `sqlite+aiosqlite:///:memory:`

## 위험 요소

| 위험 | 완화 |
|------|------|
| lifespan seed가 테스트 DB에 적용 안 됨 | conftest에서 직접 seed_configs() 호출 |
| Admin 사용자 없어 401/403 발생 | conftest fixture에서 Admin 직접 INSERT |
| WebSocket 테스트 비동기 복잡성 | B-020 범위에서 WS는 연결/heartbeat 기본만 |
| TableFSM LIVE 전이 시 CC 연결 요구 | ws_hub mock 또는 SETUP→LIVE 우회 fixture |

## 관련 PRD

- team2-backend/specs/back-office/BO-01-overview.md
