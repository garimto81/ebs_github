# EBS — 5팀 통합 모노레포

> Live Poker Broadcasting System. Conductor + 4 development teams in a single repository.

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-15 | v5.0.0 (docs v10) | 단일 `docs/` 원칙 — 4 홈 폴더 (Product / Development / Change Requests / Operations). 팀 폴더는 코드 전용 |
| 2026-04-10 | v4.0.0 | 5팀 구조 재편, Quasar 전환 반영 |

---

## 개요

EBS(WSOP LIVE 연계 라이브 포커 방송 시스템)의 기획·계약·구현 문서가 단일 레포에 통합되어 있다. 최상위는 **Conductor**(Team 0)가 관리하는 문서·통합 테스트·도구, 그 아래 **4개 팀 폴더**(`team1~4`)가 각자의 구현(코드만)을 소유한다.

핵심 규칙은 모두 `CLAUDE.md`(Conductor 세션용)에서 선언한다.

---

## 검수 진입점

| 용도 | 경로 |
|------|------|
| **전체 문서 인덱스** | `docs/_generated/full-index.md` |
| **API 전체 보기** | `docs/_generated/by-topic/APIs.md` |
| 팀별 인덱스 | `docs/_generated/by-team/` |
| feature별 인덱스 | `docs/_generated/by-feature/` |
| 문서 표준 / 규칙 | `docs/README.md` |

---

## 문서 홈 4개

| 폴더 | 답하는 질문 |
|------|-------------|
| [`docs/1. Product/`](docs/1.%20Product/) | 이 제품이 무엇인가? (Foundation, Architecture, Game Rules, PokerGFX Reference) |
| [`docs/2. Development/`](docs/2.%20Development/) | 어떻게 만드나? (2.1 Frontend / 2.2 Backend / 2.3 Game Engine / 2.4 Command Center / 2.5 Shared) |
| [`docs/3. Change Requests/`](docs/3.%20Change%20Requests/) | 무엇을 바꾸나? (CR pending → in-progress → done) |
| [`docs/4. Operations/`](docs/4.%20Operations/) | 어떻게 운영하나? (Roadmap, Conductor Backlog, Plans, Reports) |

---

## 팀 구조

| 팀 | 코드 폴더 | 문서 폴더 | 기술 스택 |
|----|-----------|-----------|-----------|
| Team 0 — Conductor | `tools/`, `integration-tests/`, `docs/1.`, `docs/2.5`, `docs/3.`, `docs/4.` | — | — |
| Team 1 — Frontend | `team1-frontend/` | `docs/2. Development/2.1 Frontend/` | Quasar (Vue 3) + TypeScript |
| Team 2 — Backend | `team2-backend/` | `docs/2. Development/2.2 Backend/` | FastAPI + SQLite/PostgreSQL |
| Team 3 — Engine | `team3-engine/` | `docs/2. Development/2.3 Game Engine/` | Pure Dart |
| Team 4 — CC | `team4-cc/` | `docs/2. Development/2.4 Command Center/` | Flutter/Dart + Rive |

**팀 폴더에는 `docs/` 가 없다.** 모든 문서는 `docs/` 단일 경로에 있다.

---

## 레포 구조

```
ebs/
├── CLAUDE.md                   Conductor 세션 규칙 (v5.0.0)
├── README.md                   이 파일
│
├── docs/                       ★ 모든 문서
│   ├── 1. Product/             제품 정의
│   ├── 2. Development/         개발 상세 (2.1~2.5)
│   ├── 3. Change Requests/     CR lifecycle
│   ├── 4. Operations/          운영 (Roadmap, Backlog, Reports)
│   ├── mockups/                공유 HTML 목업
│   ├── images/                 공유 그래픽 자산
│   └── _generated/             CI auto-commit (수작업 편집 금지)
│
├── integration-tests/          HTTP/WebSocket 기반 통합 테스트
│
├── team1-frontend/             Quasar (Vue 3) — 코드 전용
├── team2-backend/              FastAPI — 코드 전용
├── team3-engine/               Pure Dart Game Engine — 코드 전용
├── team4-cc/                   Flutter + Rive — 코드 전용
│
└── tools/                      Python 유틸 (ccr_promote, validate_links, spec_aggregate 등)
```

---

## 팀 세션 진입

각 팀 세션은 해당 팀 폴더 루트에서 시작한다.

| 세션 | 루트 | CLAUDE.md |
|------|------|-----------|
| Conductor | `C:/claude/ebs/` | `CLAUDE.md` (이 레포 루트) |
| Team 1 | `C:/claude/ebs/team1-frontend/` | `team1-frontend/CLAUDE.md` |
| Team 2 | `C:/claude/ebs/team2-backend/` | `team2-backend/CLAUDE.md` |
| Team 3 | `C:/claude/ebs/team3-engine/` | `team3-engine/CLAUDE.md` |
| Team 4 | `C:/claude/ebs/team4-cc/` | `team4-cc/CLAUDE.md` |

---

## 개발 서비스 엔드포인트 (로컬)

| 서비스 | 포트 | 소유 팀 |
|--------|------|---------|
| Backend (BO) REST | `http://localhost:8000` | team2 |
| Engine Harness | `http://localhost:8080` | team3 |
| Lobby WebSocket | `ws://localhost:8000/ws/lobby` | team2 |
| CC WebSocket | `ws://localhost:8000/ws/cc` | team2 |

---

## 변경 이력 요약

- `refactor/docs-v10` — Phase 0~6 문서 재설계. 단일 `docs/` 경로, 4 홈 폴더, 팀 폴더는 코드 전용. `contracts/`, `docs/05-plans/`, `team*/specs|ui-design|qa/` 폐지.
- v4.0.0 (2026-04-10) — 5팀 구조 확정, `contracts/` 분리 (이후 v10 에서 `docs/2. Development/` 로 흡수)
- v3 (2026-04-02) — 페르소나 순서, Confluence 매핑
