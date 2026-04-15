---
title: Team Structure
owner: conductor
tier: internal
last-updated: 2026-04-15
---

# Team Structure — 5팀 구조

## 팀 레지스트리

| 팀 | 코드 폴더 | 문서 폴더 | 기술 | 소유 API |
|----|-----------|-----------|------|----------|
| **Team 0 — Conductor** | `tools/`, `integration-tests/` | `docs/1. Product/`, `docs/2. Development/2.5 Shared/`, `docs/3. Change Requests/`, `docs/4. Operations/` | — | — |
| **Team 1 — Frontend** | `team1-frontend/` | `docs/2. Development/2.1 Frontend/` | Quasar (Vue 3) + TypeScript | consumes API-01/05/06 |
| **Team 2 — Backend** | `team2-backend/` | `docs/2. Development/2.2 Backend/` | FastAPI + SQLite/PostgreSQL | publisher: API-01/05/06, DATA-*, BO |
| **Team 3 — Engine** | `team3-engine/` | `docs/2. Development/2.3 Game Engine/` | Pure Dart | publisher: API-04 OutputEvent |
| **Team 4 — CC** | `team4-cc/` | `docs/2. Development/2.4 Command Center/` | Flutter/Dart + Rive | publisher: RFID HAL; consumes API-04 |

## 팀 소유 경계

**코드**:
- 각 팀은 `team{N}-*/` 아래만 수정 가능
- 다른 팀 코드 폴더 접근 금지

**문서**:
- 각 팀은 `docs/2. Development/2.{1..4} {팀}/` 아래만 수정 가능
- Shared (`2.5`), Product (`1.`), Change Requests (승격 이후), Operations (`4.`) 는 Conductor 소유
- 팀 간 계약 변경은 `docs/3. Change Requests/pending/CR-teamN-*.md` 경유

## Publisher Fast-Track

publisher 팀은 자기 소유 계약 파일을 CR 없이 직접 수정 가능 (사후 `tools/ccr_validate_risk.py` 검증 필수):

| 팀 | 경로 |
|----|------|
| team2 | `docs/2. Development/2.2 Backend/{APIs,Database,Back_Office}/**` |
| team3 | `docs/2. Development/2.3 Game Engine/APIs/**` |
| team4 | `docs/2. Development/2.4 Command Center/APIs/**` |

## Claude Code 세션 분리

| 세션 | 루트 | CLAUDE.md |
|------|------|-----------|
| Conductor | `C:/claude/ebs/` | `CLAUDE.md` (레포 루트) |
| Team 1 | `C:/claude/ebs/team1-frontend/` | `team1-frontend/CLAUDE.md` |
| Team 2 | `C:/claude/ebs/team2-backend/` | `team2-backend/CLAUDE.md` |
| Team 3 | `C:/claude/ebs/team3-engine/` | `team3-engine/CLAUDE.md` |
| Team 4 | `C:/claude/ebs/team4-cc/` | `team4-cc/CLAUDE.md` |
