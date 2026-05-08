---
title: EBS Conductor
---

# CLAUDE.md

Root: `C:/claude/ebs` | GitHub: `garimto81/ebs` | v1.0.0

팀 5 (Conductor + team1~4) | 산출물 2 (기획 문서 + 프로토타입) | 단일 docs/

---

## Safety Rules (HARD BLOCK)

| Rule | Detail |
|------|--------|
| **자유 편집 + additive** | 기존 블록 보존, 새 하위 섹션만 추가 |
| **사용자 권역** | 인텐트 변경 / vendor 외부 메일 / 사후 메타 거부권 |
| **자율 금지** | DB drop, prod 배포, git config, 사용자 결정 memory 폐기 |
| **충돌 해결** | SSOT 우선 → 판정 불가 시 Spec_Gap 등재 |
| **외부 PRD** | `derivative-of: ../<정본>.md` (정본 변경 시 동시 갱신) |

## Language

한글 출력, 기술 용어 영어 유지. `한글(영문)` 형식 금지.

## Git

Conventional Commit. main 직접 수정 허용: `CLAUDE.md`, `docs/`, `.claude/`.
팀 코드 = sibling worktree (`C:/claude/ebs-{stream}`) + `python tools/orchestrator/team_session_start.py` (자동 Issue + Draft PR) → 작업 → `team_session_end.py` (auto-merge). 상세: `docs/4. Operations/team_assignment_v10_3.yaml`.

## Build & Run

- 통합 테스트: HTTP/WebSocket only. `integration-tests/` `.http` 시나리오
- Docker 운영: `docs/4. Operations/Docker_Runtime.md` 절차
- 인덱스 재생성: `python tools/doc_discovery.py`

## Context Loading

작업별로 아래 문서를 읽어라:

| 작업 | 읽어라 |
|------|--------|
| 신규 기획 작성 | `docs/1. Product/Foundation.md`, `docs/README.md` |
| 외부 인계 PRD | `docs/1. Product/<feature>_PRD.md` + 정본 (`docs/2. Development/2.{N}/.../Overview.md`) |
| 코드 구현 | `team{N}-*/CLAUDE.md` |
| 멀티 세션 진입 (Stream) | `docs/2. Development/2.5 Shared/Stream_Entry_Guide.md` |
| 멀티 세션 spec | `docs/4. Operations/Multi_Session_Design_v10.3.md`, `team_assignment_v10_3.yaml`, `team-policy.json` |
| Conductor 운영 SOP | `docs/4. Operations/Workflow_Conductor_Autonomous.md` |
| Docker 운영 | `docs/4. Operations/Docker_Runtime.md` |
| 백로그 | `docs/4. Operations/Conductor_Backlog.md` 또는 팀 `Backlog.md` |
| WSOP LIVE 정렬 | `C:/claude/wsoplive/docs/confluence-mirror/` |
| 프로토타입 실패 분류 | `docs/4. Operations/Spec_Gap_Triage.md` |
| Ownership / 권한 | `docs/2. Development/2.5 Shared/team-policy.json` |
| Archive 복원 | `docs/_archive/governance-2026-05/INDEX.md` |
| 전체 인덱스 | `docs/_generated/full-index.md` |
