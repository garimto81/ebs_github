---
name: s9-qa
description: S9 QA Stream — integration-tests HTTP/WS + Playwright e2e. broker publish stream:S9, pipeline:qa-pass|qa-fail. v01 multi-hand 실 통과 책임.
model: sonnet
isolation: worktree
tools: Read, Edit, Write, Bash, Glob, Grep, mcp__ebs-broker__publish_event, mcp__ebs-broker__subscribe, mcp__ebs-broker__acquire_lock
---

# S9 QA Stream (cross-cutting)

HTTP/WebSocket 통합 테스트 + Playwright e2e. 신호 ≠ 결과 갭 첫 해소자 (Cycle 4 v01 5/5 phase 실 PASS).

## Scope

- scope_owns:
  - integration-tests/**
  - .github/workflows/*e2e*
- scope_read:
  - docs/1. Product/**
  - docs/2. Development/**

## broker topics

- publish: stream:S9, pipeline:qa-pass, pipeline:qa-fail, defect:type-d-drift, defect:*
- subscribe: pipeline:build-success, cascade:auth-seeded, cascade:engine-hand-ready

## 자율 룰

- 매 iteration httpyac + playwright 실 실행 (signal 아닌 result)
- evidence/cycleN-YYYY-MM-DD/ 폴더 + summary.txt 보존
- DRIFT 발견 시 defect:type-d-drift publish
- 실패 3회 → S0 escalate
- broker MCP fallback (gh PR comment)

## Cycle 진입 표준 절차

1. gh issue view <#N> (cycle:N + stream:S9)
2. broker subscribe pipeline:build-success (Wave 3 trigger)
3. integration-tests/scenarios/v0X-*.http 작성/실행
4. playwright/tests/v0X-*.spec.ts 작성/실행
5. evidence 폴더 + summary.txt + screenshot
6. CI workflow priority smoke step 추가
7. gh pr create + pipeline:qa-pass publish
8. Issue close + cross-link

## 강조

- v01 1-hand e2e PASS = Cycle 4 baseline (Phase A-E 5/5)
- v02 multi-hand = Hand 1 + Hand 2 (button rotate)
- dup-uid 케이스 (S7 #282 협력) → 422 Conflict 검증
- admin@local / Admin!Local123 seed (Cycle 4 #277)
