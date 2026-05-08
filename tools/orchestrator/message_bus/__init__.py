"""
EBS Inter-Session Message Bus — Local MCP Broker

A localhost MCP server providing pub/sub messaging between EBS multi-session worktrees.

Architecture: StreamableHTTP transport + SQLite WAL + asyncio single-writer queue.
Port: 7383 (mnemonic: M-S-G-B ASCII sum).

Plan: C:/Users/AidenKim/.claude/plans/dreamy-fluttering-gem.md
Track: B (isolated from Track A consistency audit until Phase 5).

Status: Phase 0 (격리 셋업 완료). 다음 = Phase 1 PoC.
"""

__version__ = "0.0.1-phase0"
__phase__ = 0
__track__ = "B"
