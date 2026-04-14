# Team 2: Backend (BO) — CLAUDE.md

세션 부트스트랩 + 문서 인덱스. 이 파일 하나만 읽으면 team2-backend 전체 구조를 찾을 수 있다.

## Role

FastAPI Back Office — REST API + WebSocket 서버 + DB 관리 + WSOP LIVE 동기화.

**기술 스택**: FastAPI (Python) + SQLite (dev) / PostgreSQL (prod)

## 소유 경로

| 경로 | 내용 |
|------|------|
| `specs/back-office/` | BO 개요, 동기화 프로토콜, 운영 가이드, PRD |
| `specs/impl/` | 기술 스택, 프로젝트 구조, 상태 관리, 라우팅, DI, 에러 처리, 로깅, 테스트 전략, 빌드/배포, NFR |
| `qa/spec-gap.md` | Spec Gap 기록 (GAP-BO-{NNN}) |
| `src/db/init.sql` | 권위 DDL — `../../contracts/data/DATA-04-db-schema.md`와 일치 필수 |
| `src/` | FastAPI 소스 코드 |
| `migrations/` | Alembic 마이그레이션 |

## 구현 대상 API

| API | 역할 |
|-----|------|
| API-01 | 66+ REST 엔드포인트 전체 구현 |
| API-01 Part II | WSOP LIVE 폴링 동기화 워커 (API-01 §7-15) |
| API-05 | WebSocket 3채널 (cc_command, cc_event, lobby_monitor) |
| API-06 | JWT 발행, RBAC, Google OAuth |

---

## 문서 인덱스

### 상황별 빠른 찾기

| 지금 하려는 것 | 먼저 읽어야 할 문서 |
|---------------|-------------------|
| **처음 레포 진입** | 이 파일 → `specs/impl/IMPL-00-dev-setup.md` |
| **BO 기능 범위 확인** | `specs/back-office/PRD-EBS_BackOffice.md` |
| **3-앱 아키텍처** | `specs/back-office/PRD-EBS_BackOffice.md` §2 |
| **REST 엔드포인트** | `../contracts/api/API-01` (정본) → `specs/back-office/BO-03-operations.md` |
| **WebSocket** | `../contracts/api/API-05` (정본) → `specs/back-office/BO-02-sync-protocol.md` |
| **WSOP LIVE 동기화** | `../contracts/api/API-01` Part II §7-15 (정본) → `BO-02-sync-protocol.md` §7 |
| **Auth/JWT** | `../contracts/api/API-06` (정본) → `../contracts/specs/BS-01-auth/` |
| **DB 스키마 변경** | `../contracts/data/DATA-04-db-schema.md` → CCR-DRAFT → `migrations/README.md` |
| **Alembic 실행** | `migrations/README.md` |
| **에러 처리/복구** | `specs/impl/IMPL-06-error-handling.md` + `IMPL-10-nfr.md` §3 |
| **로그/감사 기록** | `specs/impl/IMPL-07-logging.md` §4 (감사 매트릭스 SSOT) → `BO-03-operations.md` §1 보존 정책 |
| **DI/Mock 교체** | `specs/impl/IMPL-05-dependency-injection.md` |
| **테스트 작성** | `specs/impl/IMPL-08-testing-strategy.md` |
| **빌드/Docker** | `specs/impl/IMPL-09-build-deployment.md` |
| **NFR·신뢰성** | `specs/impl/IMPL-10-nfr.md` |
| **기획 공백 발견** | `qa/spec-gap.md` → 필요 시 CCR-DRAFT |

### 전체 문서 목록 (18개)

#### 운영 (2)
| 파일 | 줄 | 목적 |
|------|----|-----|
| `qa/spec-gap.md` | 209 | Spec Gap 로그 (GAP-BO-001~012, CCR pointer) |
| `migrations/README.md` | 81 | Alembic 운영 (baseline `0001_baseline`) |

#### Back Office 스펙 (3)
| 파일 | 줄 | 목적 | 선행 |
|------|----|-----|------|
| `specs/back-office/PRD-EBS_BackOffice.md` | ~325 | 기능 채택/제거/EBS 고유 추가 결정 + **§2 아키텍처/SLO SSOT** (구 BO-01 흡수) | `BS-00` |
| `specs/back-office/BO-02-sync-protocol.md` | 247 | Lobby↔BO↔CC 동기화·WSOP 폴링·Circuit Breaker | PRD §2 + API-01 Part II/API-05 |
| `specs/back-office/BO-03-operations.md` | ~125 | 감사 보존 정책·DR 책임 매트릭스·운영자 유저 스토리·리포팅 카탈로그 (감사 매트릭스/DR 절차/RBAC는 IMPL-07/IMPL-10/API-06으로 이관) | PRD §3 + IMPL-07/10 |

#### 구현 설계 (11)
| 파일 | 줄 | 목적 | 선행 |
|------|----|-----|------|
| `specs/impl/IMPL-00-dev-setup.md` | 111 | 3-앱 개발 환경 셋업 (10분 빌드) | - |
| `specs/impl/IMPL-01-tech-stack.md` | 286 | 기술 선정 근거·대안 기각 | BS-00 |
| `specs/impl/IMPL-02-project-structure.md` | 376 | 5 레포 분리·패키지 레이아웃 | IMPL-01 |
| `specs/impl/IMPL-03-state-management.md` ⚠️ | 281 | CC Riverpod·Lobby Zustand | IMPL-01 |
| `specs/impl/IMPL-04-routing.md` ⚠️ | 262 | CC go_router·Lobby Next.js 라우팅 | IMPL-03 + API-06 |
| `specs/impl/IMPL-05-dependency-injection.md` | 304 | Riverpod DI + BO Depends·Mock 교체 | API-03 + IMPL-03 |
| `specs/impl/IMPL-06-error-handling.md` | 230 | 에러 레벨·분류·복구 | API-03 + IMPL-10 |
| `specs/impl/IMPL-07-logging.md` | 239 | 구조화 로그(correlation/causation/idempotency/seq) | IMPL-06 + BO-03 |
| `specs/impl/IMPL-08-testing-strategy.md` ⚠️ | 425 | 테스트 피라미드·Mock RFID·커버리지 | IMPL-05 |
| `specs/impl/IMPL-09-build-deployment.md` ⚠️ | 432 | 빌드·Docker(BO+Lobby)·환경변수 | IMPL-01/02 |
| `specs/impl/IMPL-10-nfr.md` | 418 | NFR: 신뢰성/동시성/캐시/타임아웃/감사/확장성/보안 **필독** | PRD §2 + contracts/ |

⚠️ = cross-team scope(Lobby/CC/Engine 주제 포함). 2026-04-14 critic 결과 향후 재분배 후보. 상세: `~/.claude/plans/atomic-rolling-spindle.md` §C2.

### 계약(contracts/) 정본 매핑

team2 문서는 **구현 가이드**. 헤더·필드·테이블 정의의 정본은 `../contracts/`.

| 찾는 값 | 정본 | team2 참조 |
|--------|------|-----------|
| REST 엔드포인트 | `../contracts/api/API-01` | BO-03 |
| WSOP LIVE API | `../contracts/api/API-01` Part II §7-15 | BO-02 §7 |
| RFID HAL | `../contracts/api/API-03` | IMPL-05 |
| WebSocket 이벤트 | `../contracts/api/API-05` | BO-02, IMPL-07 |
| Auth/JWT | `../contracts/api/API-06` | IMPL-04, IMPL-05 |
| Entity 스키마 | `../contracts/data/DATA-04` | BO-03 |
| DB DDL | `../contracts/data/DATA-04` | `src/db/init.sql` (일치 필수) |
| Auth 행동 명세 | `../contracts/specs/BS-01-auth/` | IMPL-04, IMPL-05 |
| 앱 아키텍처 용어 | `../contracts/specs/BS-00-definitions.md` | PRD §2, IMPL-01~05 |

**드리프트 방지**: 헤더명·필드명·테이블 정의는 contracts/ 값을 그대로 인용. 파생 재서술 금지.

### CCR 반영 이력 (2026-04-10)

| CCR | 주제 | team2 영향 |
|-----|------|-----------|
| CCR-001 | audit_events 이벤트 스토어 | BO-03, IMPL-05/06/07 |
| CCR-003 | Idempotency-Key 헤더 | IMPL-05/06/07, IMPL-10 §3 |
| CCR-006 | AUTH_PROFILE/JWT TTL | IMPL-05, IMPL-10 §9 |
| CCR-010 | Saga orchestrator | IMPL-05, BO-03 §4 |
| CCR-015 | WebSocket seq 순서 | IMPL-07, BO-02 §3 |

승격 로그: `../docs/05-plans/ccr-inbox/promoting/CCR-NNN-*.md`

### 외부 링크

| 레벨 | 경로 |
|------|------|
| EBS Conductor | `../CLAUDE.md` — 5팀 구조, Layered Scope Guard, CCR |
| L0 계약 | `../contracts/` |
| 백로그 | `../docs/backlog/team2.md` |

---

## 계약 경계

- `../../contracts/api/`는 읽기 전용. 변경은 CCR 프로세스.
- `src/db/init.sql`은 `contracts/data/DATA-04-db-schema.md`와 항상 일치.
- 스키마 변경 시 DATA-04 CCR 먼저 제출.

## Spec Gap (CCR-first)

- **contracts/ 변경 필요 시**: 먼저 `../docs/05-plans/ccr-inbox/CCR-DRAFT-team2-YYYYMMDD-slug.md` 작성 (**필수**). `qa/spec-gap.md`에는 CCR pointer + 임시 구현 1줄만.
- **팀 내부 판단만 필요 시**: `qa/spec-gap.md`에 직접 기록.
- 형식: `GAP-BO-{NNN}`
- 상세: `../CLAUDE.md` §"Spec Gap 프로세스"

## 금지

- `../../contracts/` 파일 수정
- `../team1-frontend/`, `../team3-engine/`, `../team4-cc/` 접근
- Game Engine 코드 직접 참조
- contracts/와 불일치하는 파생 문서 생성
- 파생 문서(qa/, LLD 등)를 인간에게 읽으라고 제시

## Build

- 린트: `ruff check src/ --fix`
- 테스트 (개별): `pytest tests/test_specific.py -v`
- 테스트 (전체): `pytest tests/ -v` (~50s, 95/95 pass, 90% 커버리지)
- 마이그레이션: `python -m alembic upgrade head` (상세 `migrations/README.md`)

> 2026-04-14: 95/95 pass in 49s. Alembic baseline `0001_baseline`. SQLModel 12 테이블 커버, 나머지 12 테이블은 init.sql 권위.

## 문서 동기화 규칙

- **L0 계약** (`../contracts/`): 읽기 전용. Conductor 소유.
- **L1 파생** (이 팀 문서): 일관성은 AI 책임. contracts/와 다르면 CCR 제출.
- 사용자가 "동기화"를 지시하면: contracts/ Read → 파생 문서 비교 → 불일치 수정(contracts/가 정답).
- 파생 문서가 contracts/와 다를 때 "어느 쪽이 맞나요?" 질문 금지. contracts/가 맞음.
