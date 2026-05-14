---
title: B-Q19 — list_hands SQLAlchemy 2.x Row int() TypeError (Type A)
owner: team2 (or conductor Mode A)
tier: internal
status: DONE
resolved: 2026-05-03
type: backlog
linked-decision: Session 2.4b 발견 (2026-04-27), Conductor Mode A 자율 수정 (2026-05-03)
last-updated: 2026-05-03
confluence-page-id: 3819766424
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819766424/EBS+B-Q19+list_hands+SQLAlchemy+2.x+Row+int+TypeError+Type+A
---

## 발견

Session 2.4b (B-Q10 cascade) 에서 `tests/test_services_2_4b_extended.py` 작성 중 발견:

**증상**: `list_hands(db=db_session)` 또는 모든 filter 호출 시:
```
TypeError: int() argument must be a string, a bytes-like object or a real number, not 'Row'
```

**Type 분류**: **Type A (구현 실수)** — SQLAlchemy 2.x compatibility.

## 근본 원인

`hand_service.list_hands` line 97-101:

```python
count_stmt = sa_select(func.count()).select_from(stmt.subquery())
total = db.exec(count_stmt).one()
if isinstance(total, tuple):  # SQLAlchemy 1.x 호환
    total = total[0]

# paginated items
stmt = stmt.order_by(...).offset(skip).limit(limit)
items = db.exec(stmt).all()
return list(items), int(total)  # ← TypeError here
```

**문제**: SQLAlchemy 2.x 에서 `.one()` 은 **Row 객체** (tuple 아님) 반환. `isinstance(total, tuple)` 분기 false → Row 객체 그대로 → `int(Row)` 실패.

## 처리 옵션

### Option 1 (권장) — Row indexed access

```python
total = db.exec(count_stmt).one()
if isinstance(total, tuple):
    total = total[0]
elif hasattr(total, '_data'):  # SQLAlchemy 2.x Row
    total = total[0]
return list(items), int(total)
```

### Option 2 — scalar() 사용

```python
count_stmt = sa_select(func.count()).select_from(stmt.subquery())
total = db.exec(count_stmt).scalar() or 0
return list(items), int(total)
```

### Option 3 — len() 사용 (router pattern)

```python
total = len(db.exec(stmt).all())  # 다른 services 와 일관
```

권장: **Option 2 (scalar())** — 가장 깔끔, 명시적 int 반환.

## 우선순위

**P1** — Production blocker. `list_hands` 가 router `GET /hands` 에서 호출 시 500 에러. 단 기존 router 테스트 (test_hands.py 등) 가 본 path 를 통과한다면 router 가 다른 경로 사용 가능 — 검증 필요.

## 처리 작업

1. `hand_service.list_hands` line 99-106 수정 (Option 2 권장, 4 lines change)
2. router test 영향 검토 (test_hands.py 의 GET /hands 시나리오)
3. tests/test_services_2_4b_extended.py 에 list_hands 7 tests 재추가 (현재 보류)
4. pytest regression PASS 검증

## Strict 룰 영향

본 turn (Session 2.4b) 에서는 Strict 룰 (production code 0 수정) 준수. 따라서 **본 bug 수정은 별도 turn 에서 진행**.

테스트는 list_hands 영역 7 tests 보류 → coverage 부분 도달 (hand_service 의 list_hands path 미커버).

## 참조

- `team2-backend/src/services/hand_service.py` line 97-106
- `team2-backend/tests/test_services_2_4b_extended.py` (Session 2.4b 신규)
- `docs/4. Operations/Conductor_Backlog/B-Q18-structure-update-same-tx-flush-bug.md` (유사 production bug)
- `docs/4. Operations/Conductor_Backlog/B-Q10-95-coverage-roadmap.md`
