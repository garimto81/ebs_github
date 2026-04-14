# EBS — 5팀 통합 모노레포

> Live Poker Broadcasting System. Conductor + 4 development teams in a single repository.

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | v4.0.0 | 5팀 구조 재편, `contracts/` 분리, Quasar 전환 반영. 구 README 대체 |
| 2026-04-02 | v3 | 페르소나 순서, Confluence 매핑 (구버전) |

---

## 개요

EBS(WSOP LIVE 연계 라이브 포커 방송 시스템)의 기획·계약·구현 문서가 단일 레포에 통합되어 있다. 최상위는 **Conductor**(Team 0)가 관리하는 계약·문서·통합 테스트, 그 아래 **4개 팀 폴더**(`team1~4`)가 각자의 구현을 소유한다.

핵심 규칙은 모두 `CLAUDE.md`(Conductor 세션용)에서 선언한다. 각 팀 세션은 자기 팀 폴더의 `team*/CLAUDE.md`를 따른다.

---

## 팀 구조

| 팀 | 폴더 | 기술 스택 | 역할 |
|----|------|----------|------|
| **Team 0 — Conductor** | `contracts/`, `docs/`, `integration-tests/`, `tools/` | — | 계약 관리, 통합 테스트, 문서 표준 |
| **Team 1 — Frontend** | `team1-frontend/` | Quasar (Vue 3) + TypeScript | Lobby / Settings / Graphic Editor UI |
| **Team 2 — Backend** | `team2-backend/` | FastAPI + SQLite/PostgreSQL | API/WS/DB, Back-Office |
| **Team 3 — Engine** | `team3-engine/` | Pure Dart | Game Engine (Pure Dart package) |
| **Team 4 — CC** | `team4-cc/` | Flutter/Dart + Rive | Command Center + Overlay |

---

## 레포 구조

```
ebs/
├── CLAUDE.md                   Conductor 세션 규칙 (v4.0.0)
├── README.md                   이 파일
├── .gitignore
│
├── contracts/                  ★ Conductor 단독 소유 (팀 수정 금지)
│   ├── api/                    API-01~06 명세
│   ├── data/                   DATA-01~06 + PRD
│   └── specs/                  BS-00~07 행동 명세
│
├── integration-tests/          HTTP/WebSocket 기반 통합 테스트 (팀 간 계약 검증)
│   └── scenarios/
│
├── docs/
│   ├── backlog.md              글로벌 백로그 (teams: 필드로 팀별 필터)
│   ├── README.md
│   ├── mockups/                공유 HTML 목업 (flows, lobby)
│   ├── images/                 공유 그래픽 자산
│   ├── 00-reference/           WSOP 프로덕션 분석, PokerGFX 매뉴얼, 이미지 라이브러리
│   ├── 01-strategy/            Foundation PRD (SSOT, v41.0.0)
│   ├── 05-plans/               실행 계획서
│   ├── 06-reports/             완료 보고서
│   └── 07-archive/             PokerGFX 역설계, 레거시 레포, 구식 plan
│       ├── 01-pokergfx-analysis/   PokerGFX 역설계 (참고)
│       ├── 05-plans-legacy/        구식 plan (5팀 구조 전환 이전)
│       ├── 07-legacy/              구버전 문서 아카이브
│       └── legacy-repos/           통합 이전 개별 레포 8종
│
├── team1-frontend/             Quasar (Vue 3) + TypeScript
│   ├── CLAUDE.md
│   ├── src/
│   ├── qa/
│   └── ui-design/              Console/Action Tracker 통합 디자인 참조
│
├── team2-backend/              FastAPI
│   ├── CLAUDE.md
│   ├── src/
│   ├── specs/                  back-office/, impl/
│   └── qa/
│
├── team3-engine/               Pure Dart Game Engine
│   ├── CLAUDE.md
│   ├── ebs_game_engine/        Dart 패키지 (bin/, lib/, test/)
│   ├── specs/
│   │   ├── engine-spec/        BS-06 엔진 하위 명세
│   │   ├── games/              PRD-GAME-01~04 (Confluence 발행 대상)
│   │   └── plans/              게임 엔진 구현 플랜
│   └── qa/
│
├── team4-cc/                   Flutter + Rive
│   ├── CLAUDE.md
│   ├── src/
│   ├── specs/                  testing/ 등
│   ├── qa/                     commandcenter/, graphic-editor/
│   └── ui-design/              Action Tracker, Skin Editor 참조
│
└── tools/                      Python 유틸 (Conductor 소유)
```

> `logs/`, `node_modules/`, `Media/`, `archive/`, `docs/.pdca-snapshots/`, `.worktrees/`는 `.gitignore` 대상.

---

## 주요 문서

| 목적 | 경로 |
|------|------|
| Conductor 규칙 | `CLAUDE.md` |
| Foundation PRD (SSOT) | `docs/01-strategy/PRD-EBS_Foundation.md` (v41.0.0) |
| 행동 명세 (BS-00~07) | `contracts/specs/` |
| API 계약 (API-01~06) | `contracts/api/` |
| Data 모델 (DATA-01~06) | `contracts/data/` |
| 게임 PRD (Confluence) | `team3-engine/specs/games/PRD-GAME-*.md` |
| 글로벌 백로그 | `docs/backlog.md` |
| 통합 테스트 시나리오 | `integration-tests/scenarios/` |
| 레거시 레포 아카이브 | `C:/claude/ebs-archive-backup/07-archive/legacy-repos/` |

---

## 팀 세션 진입

각 팀 세션은 해당 팀 폴더 루트에서 시작한다. 팀 세션은 `contracts/`와 다른 팀 폴더를 **읽기만** 가능하며, 수정하려면 Conductor에 **CCR(Contract Change Request)** 을 제출해야 한다.

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
| Backend (BO) REST | `http://localhost:8000` | Team 2 |
| Engine Harness | `http://localhost:8080` | Team 3 |
| Lobby WebSocket | `ws://localhost:8000/ws/lobby` | Team 2 |
| CC WebSocket | `ws://localhost:8000/ws/cc` | Team 2 |

---

## 변경 이력 요약

통합 경위:
- `b0e57c8` — Phase 9 ecosystem consolidation (기존 ebs_*, ecosystem, lobby, table 등 8+ 레포를 단일 레포로 통합)
- `347be60` — Team 1 tech stack React → Quasar 전환, Rive overlay 명확화
- `9c45acf` — ebs_lobby 소스 team1-frontend 통합
- `5fe3830` — 5팀 재편 후 legacy 정리
- CLAUDE.md v4.0.0 (2026-04-10) — 5팀 구조 및 CCR 프로세스 확정
