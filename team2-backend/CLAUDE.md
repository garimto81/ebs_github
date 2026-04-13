# Team 2: Backend (BO) — CLAUDE.md

## Role

FastAPI Back Office — REST API + WebSocket 서버 + DB 관리 + WSOP LIVE 동기화

**기술 스택**: FastAPI (Python) + SQLite (dev) / PostgreSQL (prod)

## 소유 경로

| 경로 | 내용 |
|------|------|
| `specs/back-office/` | BO 개요, 동기화 프로토콜, 운영 가이드, PRD |
| `specs/impl/` | 기술 스택, 프로젝트 구조, 상태 관리, 라우팅, DI, 에러 처리, 로깅, 테스트 전략, 빌드/배포, NFR |
| `qa/spec-gap.md` | Spec Gap 기록 (GAP-BO-{NNN}) |
| `src/db/init.sql` | 권위 DDL — `../../contracts/data/DATA-04-db-schema.md`와 일치 필수 |
| `src/` | FastAPI 소스 코드 |

## 구현 대상 API

| API | 역할 | 이 팀의 책임 |
|-----|------|-------------|
| API-01 | Backend Endpoints | 66+ REST 엔드포인트 전체 구현 |
| API-02 | WSOP LIVE Integration | 폴링 동기화 워커 구현 |
| API-05 | WebSocket Events | 3개 채널 (cc_command, cc_event, lobby_monitor) 서버 구현 |
| API-06 | Auth & Session | JWT 발행, RBAC 적용, Google OAuth |

## 계약 참조 (읽기 전용 — 수정 금지)

- API 계약: `../../contracts/api/` (API-01~06 — 이 팀이 구현하지만 계약 자체는 Conductor 소유)
- 행동 명세: `../../contracts/specs/BS-01-auth/` (서버 측 auth 로직)
- 데이터 스키마: `../../contracts/data/` (DATA-01~06)

## 계약 경계

- `contracts/api/`는 읽기 전용 — Backend가 구현하지만 스펙 자체의 변경은 Conductor CCR 프로세스 경유
- `src/db/init.sql`은 `contracts/data/DATA-04-db-schema.md`와 항상 일치해야 함
- 스키마 변경 시 DATA-04 CCR 먼저 제출

## Spec Gap

`qa/spec-gap.md` — 형식: `GAP-BO-{NNN}`

## 금지

- `../../contracts/` 파일 수정 금지
- `../team1-frontend/`, `../team3-engine/`, `../team4-cc/` 접근 금지
- Game Engine 코드 직접 참조 금지

## Build

- 린트: `ruff check src/ --fix`
- 테스트: `pytest tests/test_specific.py -v` (개별 파일 권장)

> 전체 테스트는 120초 초과 시 크래시. 개별 파일 실행 권장.

---

## 문서 동기화 규칙

### 문서 계층
- **L0 계약** (contracts/): 읽기 전용, Conductor 소유. 이 팀은 수정 불가.
- **L1 파생** (이 팀의 ui-design/, qa/, 구현 가이드): 이 팀 소유. contracts/ 기준 일관성은 AI 책임.

### 사용자의 동기화 지시 시
1. 지정된 contracts/ 파일 Read
2. 자기 파생 문서와 비교 → 불일치 수정 (contracts/가 맞음)
3. 변경 사항 보고

### 파생 문서 생성/수정 시
- 반드시 contracts/ 참조하여 일관성 확인
- contracts/와 다르면 → CCR draft 제출 (contracts/ 직접 수정 금지)
- 파생 문서 = 인간이 읽지 않는 AI 산출물 (일관성은 AI 책임)

### 금지
- contracts/와 불일치하는 파생 문서 생성 금지
- 불일치 발견 시 "어느 쪽이 맞나요?" 질문 금지 (contracts/가 맞음, 파생 문서 수정)
- 파생 문서(ui-design/, qa/, LLD)를 인간에게 읽으라고 제시 금지
