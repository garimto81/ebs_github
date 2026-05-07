# 🎯 You are in: Prototype Stream (S6)

이 폴더는 멀티 세션 Stream 워크트리입니다.
Orchestrator가 Phase 0에서 모든 것을 미리 준비했습니다.

## ✅ Status: READY

작업 시작 가능. 모든 stream 병렬 자율 진행.

## ⚡ 즉시 시작
Claude Code 첫 입력에 다음 한 줄만:

  > 작업 시작

자동 진행:
  1. GitHub Issue 자동 생성
  2. Init PR 자동 생성 + 즉시 머지 (Orchestrator 활성화 신호)
  3. 새 work 브랜치 자동 전환

## 📂 영역
✅ 작업 가능:
  - docs/4. Operations/Prototype_Build_Plan.md
  - integration-tests/**

🚫 메타 파일 차단:
  - CLAUDE.md (root repo의 것)
  - MEMORY.md
  - team_assignment.yaml

## 🔗 의존성
🟢 의존성 없음 (즉시 작업 가능 — 모든 stream 자율 병렬)

## 📋 참조
- 설계 SSOT: docs/orchestrator/Multi_Session_Design.md
- 내 영역 명세: .team (이 폴더 root)
