---
title: B-Q18 — Structure update same-transaction delete+insert IntegrityError (Type A)
owner: team2 (or conductor Mode A)
tier: internal
status: DONE
resolved: 2026-05-03
type: backlog
linked-decision: Session 2.2 발견 (2026-04-27), Conductor Mode A 자율 수정 (2026-05-03)
last-updated: 2026-05-03
---

## 발견

Session 2.2 (B-Q10 cascade) 에서 `tests/test_structure_services_extended.py` 작성 중 발견:

**증상**: 기존 levels 가 있는 BlindStructure / PayoutStructure 에 `update_*_structure(levels=[새 levels])` 호출 시:
```
sqlalchemy.exc.IntegrityError: UNIQUE constraint failed:
  payout_structure_levels.payout_structure_id, payout_structure_levels.position_from
  (or blind_structure_levels.blind_structure_id, level_no)
```

**Type 분류**: **Type A (구현 실수)** — 기획 spec 은 "delete existing → insert new" 인데 코드의 SQLAlchemy flush 타이밍이 잘못.

## 근본 원인

`blind_structure_service.update_blind_structure` (line 78-94) + `payout_structure_service.update_payout_structure` (line 77-92):

```python
if data.levels is not None:
    # Delete existing levels
    old_levels = db.exec(select(...).where(...)).all()
    for old in old_levels:
        db.delete(old)

    # Insert new levels
    for lv in data.levels:
        level = X(...)
        db.add(level)

db.commit()  # ← 단일 commit
```

**문제**: SQLAlchemy 의 unit-of-work 가 INSERT 를 DELETE 보다 먼저 flush 시도. 같은 unique key (level_no, position_from) 로 INSERT → IntegrityError.

## 처리 옵션

### Option 1 (권장) — explicit flush after delete

```python
for old in old_levels:
    db.delete(old)
db.flush()  # ← 추가: delete 를 먼저 commit-pending state 로

for lv in data.levels:
    db.add(X(...))

db.commit()
```

### Option 2 — separate transactions

```python
# Phase 1: delete + commit
for old in old_levels:
    db.delete(old)
db.commit()

# Phase 2: insert + commit
for lv in data.levels:
    db.add(X(...))
db.commit()
```

단점: rollback 불가 시 partial state.

### Option 3 — SQLAlchemy passive_deletes / cascade

모델에 `cascade="all, delete-orphan"` 설정 + parent 관계로 명시. 큰 변경.

## 우선순위

**P1** — Production blocker. update_*_structure 가 실제 사용 시 실패. 단 현재 기존 router test (test_blind_structures.py 등) 가 이 path 를 테스트 안 함 → drift 미발견.

## 처리 작업

1. Option 1 (explicit flush) 적용 — 가장 작은 변경
2. blind_structure_service.update_blind_structure 의 `db.delete(old)` 다음에 `db.flush()` 추가
3. payout_structure_service.update_payout_structure 동일 처리
4. 기존 tests/test_structure_services_extended.py 의 빈 리스트 테스트는 유지
5. **추가 테스트**: levels=[다른 level_no] 로 update → 정상 동작 확인 (현재 IntegrityError → 수정 후 PASS)

## Strict 룰 영향

본 turn (Session 2.2) 에서는 Strict 룰 (production code 0 수정) 준수. 따라서 **본 bug 수정은 별도 turn 에서 진행** (Session 2.2.1 또는 Session 4 통합 시).

테스트는 빈 리스트 path 만 커버 → coverage 부분 도달 (replace branch full coverage 는 bug 수정 후).

## 참조

- `team2-backend/src/services/blind_structure_service.py` line 78-94
- `team2-backend/src/services/payout_structure_service.py` line 77-92
- `team2-backend/tests/test_structure_services_extended.py` (Session 2.2 신규)
- `docs/4. Operations/Conductor_Backlog/B-Q10-95-coverage-roadmap.md`
- Session 2.2 SESSION_2_2_HANDOFF.md
