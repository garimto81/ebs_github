# EBS Contracts — 계약 관리

> Conductor(Team 0) 단독 소유. 팀 세션에서 직접 수정 금지 (hook 차단).

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-14 | README 통합 | api/, data/, specs/ 하위 README를 본 문서로 통합 |
| 2026-04-10 | 신규 작성 | 5팀 구조 재설계 — contracts/ 도입 |

## 소유권

- **Conductor만 수정 가능** — 모든 팀은 읽기 전용
- 변경 필요 시 CCR(Contract Change Request) 프로세스 따름. 상세: `docs/05-plans/ccr-inbox/README.md`
- Publisher 팀 직접 수정은 `team-policy.json` → `contract_ownership` + `ccr-risk-matrix.md` 판정 기준

---

## api/ — REST·WebSocket 계약

EBS 3-앱 아키텍처(Lobby ↔ BO ↔ CC)의 API 단일 출처.

| 문서 | 핵심 내용 |
|------|----------|
| `API-01-backend-api.md` | BO REST API 전체 카탈로그 + WSOP LIVE Integration (Part II §7-15) |
| `API-03-rfid-hal-interface.md` | IRfidReader 추상 인터페이스, Real/Mock HAL 교체 |
| `API-04-overlay-output.md` | CC→Overlay 데이터 흐름, OutputEventBuffer, Security Delay |
| `API-05-websocket-events.md` | CC ↔ BO ↔ Lobby WebSocket 프로토콜, 이벤트 카탈로그 |
| `API-06-auth-session.md` | JWT 인증, 토큰 관리, RBAC |
| `API-07-graphic-editor.md` | Graphic Editor 엔드포인트, Idempotency-Key, ETag |

## data/ — DB 스키마·엔티티

BO 영구 저장 계층. Phase 1=SQLite, Phase 3+=PostgreSQL.

| 문서 | 내용 |
|------|------|
| `DATA-01-er-diagram.md` | ER 다이어그램 |
| `DATA-03-state-machines.md` | FSM 상태 전이 |
| `DATA-04-db-schema.md` | SQLAlchemy/SQLModel 스키마 + 엔티티 필드 정의 (BO 데이터 SSOT) |
| `DATA-07-gfskin-schema.md` | .gfskin ZIP 포맷 + JSON Schema |

> Phase 1 마이그레이션 전략·시드 데이터는 `team2-backend/migrations/STRATEGY.md`, `team2-backend/seed/README.md` 참조 (Team 2 내부 관리).

> Game Engine 내부 데이터 모델은 `team3-engine/specs/engine-spec/` 에 별도.

## specs/ — 행동 명세 (팀 간 계약만)

팀 내부 명세는 `team*/specs/` 소유. 여기는 교차팀 계약 전용.

| 코드 | 문서 | 주요 참조 팀 |
|------|------|-------------|
| BS-00 | `BS-00-definitions.md` | 전체 — 용어/상태/트리거 SSOT |
| BS-01 | `BS-01-auth/BS-01-auth.md` | Team 1, Team 2 |
| BS-04 | `BS-04-rfid/BS-04-04-hal-contract.md` | Team 3, Team 4 |
| BS-06 | `BS-06-game-engine/BS-06-00-triggers.md` | Team 3 — CC/RFID/Engine/BO 4소스 트리거 경계 |

> BS-06 게임 규칙(핸드 라이프사이클·베팅·쇼다운 등)은 `team3-engine/specs/engine-spec/` 에 있다. 이 폴더는 "누가 발동하는가"(트리거)만 관리.

## 참조 관계

```
BS-00 (용어 SSOT)
  ├── API-01 ← team2-backend specs + BS-02 (Lobby WSOP 연동, Part II)
  ├── API-03 ← team4-cc BS-04 (RFID)
  ├── API-04 ← team4-cc BS-07 (Overlay)
  ├── API-05 ← BS-06-00-triggers (이벤트 카탈로그)
  └── API-06 ← BS-01-auth (인증 행동)
```

## 규약

- 모든 계약 문서는 WSOP LIVE Confluence 표준 준수 (Edit History + 개요 + 상세 + 검증/예외)
- 팀 CLAUDE.md에서는 1줄 포인터로 참조: `계약 참조: ../contracts/api/ (읽기 전용)`
- 별도 스텁 파일(api-refs 등) 생성 금지 — drift 방지
- Enum/상태/용어 정의는 BS-00 먼저, 개별 문서는 BS-00 재인용만

## 보조 파일

- `ccr-risk-matrix.md` — CCR LOW/MEDIUM/HIGH 판정 기준 (v4 Fast-Track)
- `team-policy.json` — 팀별 소유권·경로·의존성 SSOT (hook 입력)
- `_templates/SSOT-ALIGNED-SPEC-TEMPLATE.md` — `/ssot-align` 스킬 템플릿
