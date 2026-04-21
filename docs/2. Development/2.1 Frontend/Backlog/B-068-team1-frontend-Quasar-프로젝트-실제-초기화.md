---
id: B-068
title: team1-frontend Quasar 프로젝트 실제 초기화
status: DONE
source: docs/2. Development/2.1 Frontend/Backlog.md
---

# [B-068] team1-frontend Quasar 프로젝트 실제 초기화
- **날짜**: 2026-04-10
- **teams**: [team1]
- **설명**: `team1-frontend/src/`가 `.gitkeep`만 포함하여 사실상 빈 상태. commit `9c45acf`가 "ebs_lobby 통합 완료"를 주장하지만 실제 소스 파일이 들어있지 않음. Quasar (Vue 3) + TypeScript 프로젝트를 실제로 초기화하고 기존 `C:/Claude/EbsArchiveBackup/07-archive/LegacyRepos/ebs_lobby-react/` 또는 통합 이전 `ebs_lobby_web` 내용을 Quasar로 이식/재작성.
- **수락 기준**: `team1-frontend/src/` 하위에 Quasar 프로젝트 구조(`src/`, `quasar.config.js` 등) 존재, `pnpm dev` 또는 `quasar dev` 명령으로 Lobby 기본 화면이 로컬에서 부팅.
- **관련 PRD**: CLAUDE.md §Team 1, contracts/specs/BS-02-lobby/, team1-frontend/CLAUDE.md, `UI-A1-architecture.md`, `UI-04-graphic-editor.md`, `QA-LOBBY-06-quasar-test-strategy.md`
- **진행 상황 (2026-04-10)**: Phase A 완료 (UI-A1 아키텍처 문서 작성, UI-00 §9-12 확장, CLAUDE.md 보강). Phase D 진행 예정.

- **완료 (2026-04-16)**: Quasar 초기화 후 Flutter Desktop으로 전면 전환 완료. lib/ 103 파일, 16,427 LOC. Riverpod + Freezed + go_router. 기존 Quasar 소스는 `_archive-quasar/` 보존.
