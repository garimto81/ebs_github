---
title: Multi-Session Workflow — v4.0/v4.1 → v5.0 전환 이유 (Archived 2026-04-28)
owner: conductor
status: archived
archived_date: 2026-04-28
archived_phase: v8.0 Phase 8a
parent: docs/4. Operations/Multi_Session_Workflow.md (v5.1+L4)
purpose: main doc 압축 (395 → 380), 역사 섹션 보존
---

# Multi-Session Workflow — v4.0/v4.1 → v5.0 전환 이유 (Archived)

> 본 섹션은 2026-04-28 v8.0 Phase 8a 마이그레이션으로 main doc 에서 archive 이동되었다.
> v5.0/v5.1 전환의 역사적 맥락 보존 목적이며, 운영 정책으로는 더 이상 참조되지 않는다.

## 발견된 문제 (2026-04-21 critic review)

| v4.0 약속 | 실제 | 원인 |
|-----------|------|------|
| "매 호출 완결 트랜잭션" | 4 단계 수동 조치 필요 | 플랫폼이 main push 차단 |
| "자동 commit + merge + push" | Push 실패 → 사용자 수동 수습 | PR review bypass 정책 |
| "세션 시작·종료 개념 없음" | 팀 세션 재시작 필수 | subdir 모드 shared HEAD 오염 |
| "Pre-Declaration 충돌 방지" | team1 등 manifest 미등록 | enforcement 경로 없음 |

## 2026 업계 표준 조사 결과

- **The Agentic Blog (2026-03)**: "one task → one branch → one worktree → one agent" canonical pattern
- **GitHub Merge Queue (2025 GA)**: 복잡 monorepo 표준. 24% PR cycle reduction
- **Claude Code v2.1.50**: `claude -w` 네이티브 worktree 지원
- **AddyOsmani (2026)**: 3-5 agent sweet spot. 같은 파일 2 agent 편집 금지

→ **EBS v4.0 = 업계가 이미 Git/GitHub/Claude Code 네이티브로 해결한 문제의 재발명**

## 관련 마이그레이션

- v4.0 → v5.0: `Multi_Session_Workflow.md` v5.0 (sibling worktree + PR + auto-merge)
- v5.0 → v5.1: L0 Pre-Work Contract 추가 (proactive coordination)
- v5.1 → v8.0 Phase 8a: 본 섹션 archive 이동 (main doc 압축, 역사 보존)
