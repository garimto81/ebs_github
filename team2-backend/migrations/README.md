# Alembic Migrations

## 개요

Team 2 Backend의 DB 스키마 진화를 Alembic revision 체인으로 관리한다.
- **권위 SSOT**: `contracts/data/DATA-04-db-schema.md` (Conductor 소유)
- **Alembic baseline**: SQLModel 모델 메타데이터 기반 자동 생성

## 현재 상태 (2026-04-14 — S1-05)

| 항목 | 값 |
|---|---|
| Baseline revision | `0001_baseline.py` (revision ID `437c961ee28c`) |
| Alembic 관리 테이블 | 12개 (SQLModel 모델 존재하는 것) |
| init.sql 테이블 | 24개 |
| 미커버 테이블 | 12개 (blind_structures, blind_structure_levels, hands, hand_players, hand_actions, decks, deck_cards, configs, skins, output_presets, waiting_list, cards) |

**미커버 사유**: 해당 테이블용 SQLModel 모델이 `src/models/` 에 아직 없음. Sprint 1 S1-03(Competition 계층), S1-06(WebSocket 이벤트), Sprint 2 S2-01(BlindStructure) 등 구현 시점에 모델 + migration revision 추가 예정.

**현행 운영**: 개발 환경은 `init.sql` + SQLModel `create_all` 병행. Alembic은 새 스키마 변경용.

## 워크플로우

### 개발 환경 초기화 (fresh DB)

```bash
DATABASE_URL="sqlite:///./ebs.db" python -m alembic upgrade head
```

### 스키마 변경 시

1. `src/models/*.py` SQLModel 클래스 수정 또는 추가
2. autogenerate revision 생성:
   ```bash
   python -m alembic revision --autogenerate -m "add_blind_structures_table"
   ```
3. 생성된 `migrations/versions/<hash>_<msg>.py` 리뷰 + 필요 시 수동 편집
4. 테스트 DB에 적용:
   ```bash
   rm -f /tmp/test.db
   DATABASE_URL="sqlite:////tmp/test.db" python -m alembic upgrade head
   ```
5. 커밋 (revision 파일 + 모델 변경 함께)

### 롤백

```bash
python -m alembic downgrade -1      # 직전 revision으로
python -m alembic downgrade base    # 처음 상태로
```

### 현재 상태 확인

```bash
python -m alembic current
python -m alembic history
```

## 환경변수

| 변수 | 기본값 | 용도 |
|---|---|---|
| `DATABASE_URL` | `alembic.ini` sqlalchemy.url (`sqlite:///./ebs.db`) | 대상 DB. env 제공 시 ini 값 덮어씀 |

## CI 통합 권고

```yaml
- name: Apply migrations
  run: python -m alembic upgrade head
  env:
    DATABASE_URL: ${{ matrix.database_url }}

- name: Run tests
  run: pytest tests/
```

## init.sql ↔ Alembic 관계 (GAP-BO-011 연계)

- **현재 (Phase 1)**: init.sql이 권위 DDL. Alembic은 SQLModel 모델 커버 범위만 관리.
- **목표 (Sprint 2~3)**: 모든 테이블에 SQLModel 모델 작성 → Alembic 단독 관리.
- **전환 시점**: GAP-BO-011 완전 해소 (init.sql 전체가 모델로 표현 가능한 시점).
