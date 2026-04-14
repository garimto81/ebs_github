# Migration Strategy (formerly contracts/data/DATA-05)

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | Alembic 마이그레이션 전략 + Phase 전환 계획 초판 |

---

## 개요

EBS Back Office DB의 스키마 마이그레이션 전략을 정의한다. Alembic(SQLAlchemy 마이그레이션 도구)을 사용하여 스키마 버전을 관리한다.

---

## 1. Alembic 설정

### 디렉토리 구조

```
src/
  bo/
    db/
      alembic/
        env.py
        versions/
          001_initial_schema.py
          002_xxx.py
        alembic.ini
      models.py          # SQLModel 정의 (DATA-04)
      session.py         # DB 세션 관리
```

### alembic.ini 핵심 설정

```ini
[alembic]
script_location = src/bo/db/alembic
sqlalchemy.url = sqlite:///data/ebs.db    # Phase 1

[alembic:production]
sqlalchemy.url = postgresql://...          # Phase 3+
```

### env.py 핵심

```python
from bo.db.models import SQLModel
target_metadata = SQLModel.metadata
```

---

## 2. 초기 스키마 마이그레이션

### 001_initial_schema.py

Phase 1 초기 스키마. DATA-04의 모든 테이블을 생성한다.

**생성 순서** (FK 의존성):

| 순서 | 테이블 | 의존 |
|:----:|--------|------|
| 1 | competitions | 없음 |
| 2 | users | 없음 |
| 3 | configs | 없음 |
| 4 | blind_structures | 없음 |
| 5 | skins | 없음 |
| 6 | output_presets | 없음 |
| 7 | series | competitions |
| 8 | events | series, blind_structures |
| 9 | event_flights | events |
| 10 | players | 없음 |
| 11 | tables | event_flights |
| 12 | table_seats | tables, players |
| 13 | hands | tables |
| 14 | hand_players | hands, players |
| 15 | hand_actions | hands |
| 16 | decks | tables |
| 17 | deck_cards | decks |
| 18 | user_sessions | users |
| 19 | audit_logs | users |
| 20 | blind_structure_levels | blind_structures |

**실행 명령:**

```bash
# 마이그레이션 생성
alembic revision --autogenerate -m "001_initial_schema"

# 적용
alembic upgrade head

# 현재 버전 확인
alembic current
```

---

## 3. 버전 관리 규칙

### 명명 규칙

```
{NNN}_{설명}.py
```

| 예시 | 설명 |
|------|------|
| `001_initial_schema.py` | 초기 스키마 |
| `002_add_table_lock_fields.py` | 테이블 잠금 필드 추가 |
| `003_add_hand_history_indexes.py` | Hand History 인덱스 추가 |

### 마이그레이션 작성 원칙

| 원칙 | 설명 |
|------|------|
| **단일 책임** | 마이그레이션 1개 = 변경 사항 1개 |
| **양방향** | 반드시 `upgrade()`와 `downgrade()` 모두 구현 |
| **데이터 보존** | 컬럼 삭제/변경 시 기존 데이터 마이그레이션 포함 |
| **테스트 필수** | 마이그레이션 적용/롤백 양방향 테스트 |
| **자동 생성 검증** | `--autogenerate` 후 반드시 수동 리뷰 |

### 롤백 규칙

| 상황 | 처리 |
|------|------|
| 최근 1개 롤백 | `alembic downgrade -1` |
| 특정 버전으로 | `alembic downgrade {revision}` |
| 전체 롤백 | `alembic downgrade base` (주의: 데이터 손실) |
| 프로덕션 롤백 | DB 백업 → 롤백 → 데이터 확인 → 서비스 재개 |

---

## 4. Phase 전환 마이그레이션

### Phase 1 → Phase 2: SQLite 유지, 스키마 확장

| 변경 | 내용 |
|------|------|
| 멀티테이블 Dashboard | tables에 모니터링 필드 추가 |
| Skin Editor | skins 테이블 확장 (레이어, 애니메이션) |
| 출력 확장 | output_presets에 SDI, Cross-GPU 필드 |
| 게임 확장 (9종) | game_type enum 범위 확인 (이미 0-21 대응) |

### Phase 2 → Phase 3: SQLite → PostgreSQL 전환

**전환 전략: Export-Import**

```
Phase 2 SQLite
    |
    ├─ 1. SQLite DB 전체 백업
    |
    ├─ 2. 데이터 Export (JSON/CSV)
    |      sqlite3 ebs.db ".mode json" ".output data.json" "SELECT * FROM ..."
    |
    ├─ 3. PostgreSQL 스키마 생성
    |      alembic -c alembic_pg.ini upgrade head
    |
    ├─ 4. 데이터 Import
    |      pgloader 또는 커스텀 스크립트
    |
    ├─ 5. 타입 변환 적용
    |      TEXT(ISO) → TIMESTAMPTZ
    |      TEXT(JSON) → JSONB
    |      TEXT(array) → ARRAY
    |
    └─ 6. 검증 후 전환
```

**타입 변환 매핑:**

| SQLite (Phase 1) | PostgreSQL (Phase 3+) | 변환 |
|------------------|----------------------|------|
| TEXT (ISO 8601) | TIMESTAMPTZ | 파싱 후 저장 |
| TEXT (JSON) | JSONB | 파싱 후 저장 |
| TEXT (comma-sep) | TEXT[] | 분할 후 ARRAY 저장 |
| INTEGER (boolean) | BOOLEAN | 자동 |
| REAL | NUMERIC / DOUBLE PRECISION | 자동 |

**PostgreSQL 전용 기능 활성화:**

| 기능 | 용도 |
|------|------|
| JSONB 인덱스 | board_cards, side_pots, allowed_games 쿼리 최적화 |
| ARRAY 연산 | hole_cards 검색, game enum 필터 |
| Partial Index | `WHERE status = 'live'` 활성 테이블 빠른 조회 |
| LISTEN/NOTIFY | WebSocket 이벤트 DB 트리거 (CC 실시간 동기화 대체) |
| Row-Level Security | RBAC 기반 데이터 접근 제어 |

---

## 5. 백업 전략

### Phase 1 (SQLite)

| 항목 | 값 |
|------|---|
| 백업 주기 | 이벤트 시작 전 + 매 4시간 |
| 백업 방식 | 파일 복사 (`ebs.db` → `ebs_{timestamp}.db`) |
| 보존 기간 | 시리즈 종료 후 1년 |
| 복원 방식 | 파일 교체 |

### Phase 3+ (PostgreSQL)

| 항목 | 값 |
|------|---|
| 백업 주기 | 매일 자동 (pg_dump) + 이벤트 전후 수동 |
| 백업 방식 | `pg_dump --format=custom` |
| WAL 아카이브 | PITR (Point-in-Time Recovery) 지원 |
| 보존 기간 | 시리즈 종료 후 1년 |
| 복원 방식 | `pg_restore` 또는 PITR |

---

## 6. 마이그레이션 체크리스트

마이그레이션 작성/적용 시 아래 체크리스트를 확인한다.

| # | 항목 | 확인 |
|:-:|------|------|
| 1 | `upgrade()` + `downgrade()` 모두 구현 | |
| 2 | 새 테이블 생성 순서가 FK 의존성을 따름 | |
| 3 | 기존 데이터 마이그레이션 로직 포함 | |
| 4 | 인덱스 생성/삭제 포함 | |
| 5 | SQLite 호환성 확인 (Phase 1) | |
| 6 | 빈 DB에서 `upgrade head` 성공 | |
| 7 | `downgrade -1` 후 `upgrade head` 재성공 | |
| 8 | 시드 데이터 투입 후 정상 동작 | |
