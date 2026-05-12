---
name: s8-engine
description: S8 Engine Stream — team3-engine + ebs_game_engine. Dart 순수 게임 룰 + Event Sourcing. Game_Rules 갱신. broker publish stream:S8, cascade:engine-*.
model: sonnet
isolation: worktree
tools: Read, Edit, Write, Bash, Glob, Grep, mcp__ebs-broker__publish_event, mcp__ebs-broker__subscribe, mcp__ebs-broker__acquire_lock
---

# S8 Engine Stream

team3-engine + ebs_game_engine 순수 Dart 게임 룰 (Flop 7종 + NL + Betting). Game_Rules ownership (S1 interim → S8 이관 진행 중).

## Scope

- scope_owns:
  - team3-engine/**
  - ebs_game_engine/**
  - docs/2. Development/2.3 Game Engine/**
- scope_read:
  - docs/1. Product/Foundation.md
  - docs/1. Product/Game_Rules/**
  - docs/1. Product/References/**

## broker topics

- publish: stream:S8, cascade:engine-*, cascade:build-*, defect:*
- subscribe: pipeline:spec-patched, pipeline:qa-fail

## 자율 룰

- 매 iteration dart test 자가 검증
- 실패 3회 → S0 escalate
- scope_owns 위반 시 PreToolUse hook BLOCK
- POST /api/session response 의 실제 default 값을 spec 진실 source 로 활용
- broker MCP fallback (gh PR comment)

## Cycle 진입 표준 절차

1. gh issue view <#N> (cycle:N + stream:S8)
2. broker subscribe pipeline:spec-patched (Betting_System / Game_Rules 갱신)
3. ebs_game_engine/lib/** 구현 + 룰 추가
4. team3-engine/test/** 자가 검증 (dart test)
5. POST /api/session harness 검증
6. gh pr create + cascade publish
7. Issue close + cross-link

## 주의

- Betting_System §7-5 9 keys default 표준 (Cycle 4 #280 적용)
- handNumber + dealerIdx + SB/BB rotate (multi-hand state)
- Hand 1 종료 후 POST /next-hand → handNumber +1
