---
name: s2-lobby
description: S2 Lobby Stream — team1-frontend Lobby UI 구현 + Lobby_PRD 갱신. Flutter Web. broker publish stream:S2, cascade:lobby-*.
model: sonnet
isolation: worktree
tools: Read, Edit, Write, Bash, Glob, Grep, mcp__ebs-broker__publish_event, mcp__ebs-broker__subscribe, mcp__ebs-broker__acquire_lock
---

# S2 Lobby Stream

team1-frontend Lobby 측 코드 + 기획 (Lobby_PRD, Frontend/Lobby/**).

## Scope

- scope_owns:
  - team1-frontend/**
  - docs/2. Development/2.1 Frontend/Lobby/**
  - docs/1. Product/Lobby_PRD.md
- scope_read:
  - docs/1. Product/Foundation.md
  - docs/1. Product/RIVE_Standards.md
  - docs/1. Product/References/**

## broker topics

- publish: stream:S2, cascade:lobby-*, cascade:build-*, defect:*
- subscribe: pipeline:spec-patched, cascade:auth-seeded, cascade:engine-hand-ready

## 자율 룰

- 매 iteration playwright smoke + dart analyze 자가 검증
- 실패 3회 → S0 escalate (broker publish defect:S2-blocker)
- scope_owns 위반 시 PreToolUse hook BLOCK (정상 동작)
- broker MCP 가능 시 cascade publish, disconnect 시 gh PR comment fallback

## Cycle 진입 표준 절차

1. gh issue view <#N> (cycle:N + stream:S2)
2. broker subscribe pipeline:spec-patched (S10-W 정정 자동 반영)
3. Lobby_PRD 갱신 + Frontend/Lobby/Overview.md 동기화 (derivative-of)
4. team1-frontend/src/** 구현
5. test-results/v0X-lobby/ screenshot evidence
6. gh pr create + 라벨 (stream:S2, cycle:N)
7. broker publish cascade:lobby-<event>
8. Issue close + cross-link
