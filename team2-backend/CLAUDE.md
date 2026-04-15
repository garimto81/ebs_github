# Team 2: Backend (BO) — CLAUDE.md (코드 전용)

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

### Publisher Fast-Track

team2는 자기 소유 계약 파일을 직접 수정 가능:

| 파일 | 직접 수정 허용 |
|------|---------------|
| `../docs/2. Development/2.2 Backend/APIs/**` | ✓ |
| `../docs/2. Development/2.2 Backend/Database/**` | ✓ |
| `../docs/2. Development/2.2 Backend/Back_Office/**` | ✓ |

**단**, 수정 후 `python ../tools/ccr_validate_risk.py --draft <파일명>` 실행 필수. 리스크 등급이 허용 범위를 초과하면 풀 CR 절차로 전환.

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

수정 필요 시 CR 프로세스 경유 (`../docs/3. Change Requests/pending/CR-team2-*.md`).

## 기획 공백 발견 시

개발 중 기획 문서에 없는 판단이 필요하면 해당 기획 문서를 **즉시 보강**한다. Spec_Gaps.md · CR draft · CCR-first 프로세스는 폐지되었다. 상세: `../CLAUDE.md` §"기획 공백 발견 시 프로세스".

## 금지

- `../docs/1. Product/`, `../docs/2. Development/2.{1,3,4,5}*/`, `../docs/3. Change Requests/{in-progress,done}/`, `../docs/4. Operations/` 수정 금지 (CR 프로세스)
- 다른 팀 코드 폴더(`../team1-frontend/`, `../team3-engine/`, `../team4-cc/`) 접근 금지
- Game Engine 코드 직접 참조 금지

## Build

- 린트: `ruff check src/ --fix`
- 테스트 (개별): `pytest tests/test_specific.py -v`
- 테스트 (전체): `pytest tests/ -v` (~50s, 95/95 pass, 90% 커버리지)
- 마이그레이션: `python -m alembic upgrade head`

> 2026-04-14 기준: 95/95 pass in 49s. Alembic baseline `0001_baseline`. SQLModel 12 테이블 커버, 나머지 12 테이블은 `init.sql` 권위.
