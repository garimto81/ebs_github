---
id: IMPL-003
title: "구현: team2 decks.py in-memory → DB session 전환"
type: implementation
status: PENDING
owner: team2
created: 2026-04-20
spec_ready: true
blocking_spec_gaps: []
implements_chapters:
  - docs/4. Operations/Conductor_Backlog/SG-006-rfid-52-card-codemap.md
related_code:
  - team2-backend/src/routers/decks.py
  - team2-backend/migrations/versions/0005_decks_and_settings_kv.py
---

# IMPL-003 — team2 decks.py DB session 전환

## 배경

SG-006 에서 RFID deck 개념 + 52 카드 codemap + 등록 3모드 + 상태 머신이 확정되었다. Conductor 세션이:
- Alembic migration `0005_decks_and_settings_kv.py` (`decks` + `deck_cards` 테이블) 작성
- `src/routers/decks.py` 7 endpoint 를 **in-memory dict store** 로 실동작 구현 (Demo deck auto-seed 포함)
- `test_decks_inmemory.py` 13 tests (13/13 PASS)

남은 작업은 **DB session 연결 + migration 실행 + 기존 테스트를 DB 버전으로 확장**.

## 구현 대상 (TODO-T2-004)

### 1. `_decks_store` → SQLModel / sqlalchemy session

`decks.py` 상단의 in-memory dict:
```python
_decks_store: dict[str, dict] = {}
_deck_cards_store: dict[tuple[str, str], dict] = {}
_rfid_uid_index: set[str] = set()
```

이를 DB session 기반으로 교체:
- 각 handler 에 `session: Session = Depends(get_db)` 주입
- CRUD 를 SQL 로 수행
- cross-deck UID 유일성은 `uq_deck_cards_rfid_uid` 제약에서 자동 (IntegrityError → 409)

### 2. Alembic migration 적용

```bash
cd team2-backend
python -m alembic upgrade head
```

`0005_decks_and_settings_kv.py` 적용 + `settings_kv` 도 함께 (SG-003 API).

### 3. Demo deck seed

현재 in-memory `_seed_demo_deck()` 가 import 시 실행. DB 전환 후:
- 앱 startup event 에서 "demo deck 미존재 시 생성" 로직
- 또는 seed 스크립트 `seed/demo_deck.py`

### 4. 테스트 확장

`test_decks_inmemory.py` → `test_decks_db.py` (추가, in-memory 버전도 유지):
- fixture 로 testdb (SQLite in-memory)
- 13 기존 시나리오 + DB-specific (IntegrityError 처리, transaction rollback 등)

## 수락 기준

- [ ] `decks.py` 의 모든 handler 가 `session: Session = Depends(...)` 사용
- [ ] in-memory dict 제거 (또는 test fixture 로 격리)
- [ ] `alembic upgrade head` 성공
- [ ] Demo deck 이 DB 에 자동 seed 됨 (중복 실행 안전)
- [ ] `test_decks_db.py` 13+ tests PASS
- [ ] RBAC 가드 (TODO-T2-005): Admin/Operator 구분
- [ ] audit_events 연동 (TODO-T2-007): deck_created / card_registered / card_replaced / deck_retired

## 관련 (연쇄 구현)

- SG-003 `settings_kv.py` 도 동일 패턴 (in-memory → DB). 같은 migration `0005` 에 포함되어 있으므로 병행 작업 권장.
- SG-007 `reports.py` 6 endpoint 은 aggregation layer + MV 구현이 별도 필요. IMPL-004 승격 후보.

## 구현 메모

- Alembic baseline 이 `0001_baseline` 이고 `0005_decks_and_settings_kv` 가 최신. `0002~0004` 는 기존 제약 관련. `upgrade head` 로 전부 적용.
- `fakeredis` dev dep 는 이미 pyproject.toml 에 포함 — Redis mock 필요 시 사용 가능.
- pytest CI 기록: 95/95 (2026-04-14) + 본 IMPL 후 13+ 추가 예정.
