# 🔧 ebs-message-bus-dev — 격리 개발 worktree

**Branch**: `feat/message-bus`
**Created**: 2026-05-08
**Track**: Track B (Inter-Session Message Bus)
**Plan**: `C:\Users\AidenKim\.claude\plans\dreamy-fluttering-gem.md`

## 격리 보증

이 worktree 의 변경사항은 **Track A (8 정합성 감사)** 와 완전히 분리됩니다.

| 변경 가능 | 변경 금지 (감사 진행 중) |
|----------|-----------------------|
| `tools/orchestrator/message_bus/**` (신규) | `.claude/hooks/orch_*.py` (감사 hook) |
| `tools/orchestrator/start_message_bus.py` (신규) | `tools/orchestrator/setup_stream_worktree.py` |
| `tools/orchestrator/stop_message_bus.py` (신규) | `tools/orchestrator/orchestrator_monitor.py` |
| `.gitignore` (broker artifacts 만 추가) | `docs/4. Operations/orchestration/2026-05-08-consistency-audit/**` |
| `docs/4. Operations/Message_Bus_Runbook.md` (Phase 5) | 8 audit worktree 의 어떤 파일이든 |

## 5 Phase 진행

| Phase | 기간 | 상태 |
|-------|-----|------|
| 0. 격리 셋업 | Day 0 | ✅ 완료 (2026-05-08) |
| 1. PoC | Day 1 | 🔄 다음 |
| 2. MVP | Week 1 | ⏳ |
| 3. Hybrid | Week 2 | ⏳ |
| 4. Hardening | Week 3 | ⏳ |
| 5. ★통합★ | Week 4 (Track A 완료 후) | ⏳ |

## 작업 시작 명령

```
작업 시작
```

자동 진행 (Phase 1 PoC):
1. tools/orchestrator/message_bus/ 디렉토리 생성
2. server.py + store.py + 2 tools (publish_event, subscribe) 작성
3. tests/sub_demo.py + pub_demo.py 작성
4. latency 측정 (<200ms 검증)
5. PoC commit on feat/message-bus

## 통합 차단 검증 (자동)

Phase 4 까지 다음 모두 강제:
- main 으로 직접 머지 금지
- 8 audit worktree 의 어떤 파일도 수정 금지
- broker auto-start hook 비활성 (수동 시작만)
- `.mcp.json` 8 audit worktree 미배포

## 통합 시점 (Phase 5)

Trigger 동시 만족:
- ✅ Track A 8 audit PR 모두 머지
- ✅ Phase 4 hardening 완료

이때 `feat/message-bus` → main PR 1건으로 전체 활성화.
