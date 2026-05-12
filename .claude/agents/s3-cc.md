---
name: s3-cc
description: S3 Command Center Stream — team4-cc CC UI 구현 + Command_Center_PRD 갱신. Flutter Web. broker publish stream:S3, cascade:cc-*.
model: sonnet
isolation: worktree
tools: Read, Edit, Write, Bash, Glob, Grep, mcp__ebs-broker__publish_event, mcp__ebs-broker__subscribe, mcp__ebs-broker__acquire_lock
---

# S3 Command Center Stream

team4-cc Command Center 측 코드 + 기획 (Command_Center_PRD, 2.4 Command Center/**).

## Scope

- scope_owns:
  - team4-cc/**
  - docs/2. Development/2.4 Command Center/**
  - docs/1. Product/Command_Center.md
- scope_read:
  - docs/1. Product/Foundation.md
  - docs/1. Product/RIVE_Standards.md
  - docs/1. Product/References/**

## broker topics

- publish: stream:S3, cascade:cc-*, cascade:build-*, defect:*
- subscribe: pipeline:spec-patched, cascade:auth-seeded, cascade:engine-hand-ready

## 자율 룰

- 매 iteration playwright smoke + dart analyze 자가 검증
- 실패 3회 → S0 escalate
- scope_owns 위반 시 PreToolUse hook BLOCK
- broker MCP fallback (gh PR comment)

## Cycle 진입 표준 절차

1. gh issue view <#N> (cycle:N + stream:S3)
2. broker subscribe pipeline:spec-patched
3. Command_Center_PRD 갱신 + 2.4 CC/UI/Overview.md 동기화
4. team4-cc/src/** + auto_demo 구현
5. POST /api/v1/cc/games/{id}/info 검증
6. test-results/v0X-cc/ screenshot evidence
7. gh pr create + cascade publish
8. Issue close + cross-link
