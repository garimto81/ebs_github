---
id: B-074
title: IMPL-01 Lobby 섹션 stale 수정 (Team 2 인계)
status: PENDING
source: docs/4. Operations/Conductor_Backlog.md
---

# [B-074] IMPL-01 Lobby 섹션 stale 수정 (Team 2 인계)
- **날짜**: 2026-04-10
- **teams**: [team2]
- **설명**: `team2-backend/specs/impl/IMPL-01-tech-stack.md` §2 Lobby 섹션이 "Next.js 15 + Zustand + shadcn/ui"로 기재되어 있으나, 커밋 `347be60`(2026-04-10)에서 Lobby 스택이 Quasar (Vue 3) + TypeScript + Pinia로 전환됨. 루트 `CLAUDE.md` 팀 레지스트리 및 `PRD-EBS_Foundation.md` §소프트웨어 앱 구조(2026-04-10 신설)와 IMPL-01 불일치.
- **수락 기준**:
  1. IMPL-01 §2 Lobby가 Quasar 스택으로 재작성되고, 대안 기각 사유 섹션(Next.js → Quasar 전환 근거)도 갱신됨.
  2. `grep "Next.js" team2-backend/specs/impl/IMPL-01*.md` 결과 0건.
  3. IMPL-01 §1 아키텍처 요약 ASCII 다이어그램의 Lobby 블록도 Quasar로 갱신.
- **인계 메모**: 다음 Team 2 세션 시작 시 사용자가 본 항목을 Team 2로 전달. Conductor 세션은 `team2-backend/` 수정 권한 없음 (Layered Scope Guard).
- **관련 메모 (Conductor 자체 후속 작업)**: `docs/01-strategy/PRD-EBS_Foundation.md` Ch.10 기술 스택 표 L1031-1032도 stale(서버=게임 엔진 잘못 표기, 프론트엔드 Flutter 단일 표기)이지만, 2026-04-10 SW/HW 아키텍처 이미지 작업 범위를 벗어나 보류. 별도 CCR 없이 Conductor가 후속 정리 가능.
- **관련 파일**: `team2-backend/specs/impl/IMPL-01-tech-stack.md`, 루트 `CLAUDE.md`, `docs/01-strategy/PRD-EBS_Foundation.md` §기술 스택
