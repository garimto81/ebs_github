# DATA 문서 네비게이션

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 데이터 모델 문서 7종 초판 |

---

## 개요

EBS Back Office DB의 데이터 모델을 정의하는 문서 모음이다. 3-앱 아키텍처(Lobby + CC + BO)에서 BO가 중앙 DB를 관리한다.

> 참조: Game Engine 내부 데이터 모델은 `team3-engine/specs/engine-spec/BS-06-00-REF-game-engine-spec.md` Ch.2에 정의되어 있다. 이 문서는 BO 영구 저장 계층을 다룬다.

## 문서 목록

| 문서 | 파일 | 내용 |
|------|------|------|
| **DATA-01** | `DATA-01-er-diagram.md` | ER 다이어그램 (엔티티 관계) |
| **DATA-02** | `DATA-02-entities.md` | 엔티티 필드 정의 테이블 |
| **DATA-03** | `DATA-03-state-machines.md` | FSM 상태 전이 다이어그램 |
| **DATA-04** | `DATA-04-db-schema.md` | SQLAlchemy/SQLModel DB 스키마 |
| **DATA-05** | `DATA-05-migrations.md` | Alembic 마이그레이션 전략 |
| **DATA-06** | `DATA-06-seed-data.md` | 개발/테스트용 시드 데이터 |

## DB 기술 스택

| Phase | DB | 이유 |
|-------|-----|------|
| Phase 1 (POC) | SQLite | 설치 불필요, 단일 파일, 빠른 프로토타이핑 |
| Phase 3+ | PostgreSQL | 동시 접속, JSON 네이티브, 확장성 |

## 관련 문서

| 참조 | 경로 |
|------|------|
| 엔티티 용어/FSM 정의 | `contracts/specs/BS-00-definitions.md` |
| Game Engine 데이터 모델 | `team3-engine/specs/engine-spec/BS-06-00-REF-game-engine-spec.md` |
| Lobby 엔티티/필드 정의 | `contracts/specs/BS-02-lobby/BS-02-lobby.md` |
| 기존 DB 스키마 초안 | `contracts/data/PRD-EBS_DB_Schema.md` |
