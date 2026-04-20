#!/usr/bin/env python3
"""
post_build_fail.py — PostToolUse hook (EBS Conductor, 2026-04-20)

프로토타입 빌드/테스트 실패 감지 시 Type A/B/C 분류 프로토콜을 세션에 주입.

Trigger: PostToolUse(Bash)
Mechanism:
  stdin 으로 Claude Code 가 전달하는 JSON 에서 tool_response.exit_code 확인.
  command 가 build/test/run 패턴 + exit_code != 0 이면 프로토콜 reminder 출력.

출력: stdout 으로 session reminder 텍스트 (exit code 0 유지 — 차단 아님).

관련 문서:
  - docs/4. Operations/Spec_Gap_Triage.md (프로토콜 전체)
  - CLAUDE.md §"프로토타입 실패 대응 프로토콜"
  - memory: feedback_prototype_failure_as_spec_signal.md
"""
from __future__ import annotations

import json
import re
import sys


BUILD_PATTERNS = re.compile(
    r"\b("
    r"flutter\s+(pub|run|test|build|analyze)"
    r"|dart\s+(run|test|pub)"
    r"|pytest"
    r"|ruff\s+check"
    r"|pnpm\s+(install|run|test|build|dev)"
    r"|npm\s+(install|run|test|build)"
    r"|quasar\s+(dev|build)"
    r"|python\s+-m\s+(alembic|pytest|uvicorn)"
    r"|uvicorn"
    r"|docker(-compose)?\s+(up|build)"
    r"|build_runner"
    r")\b",
    re.I,
)


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except json.JSONDecodeError:
        return 0  # no payload, pass silently

    tool_input = payload.get("tool_input") or {}
    tool_response = payload.get("tool_response") or {}

    command = tool_input.get("command", "") if isinstance(tool_input, dict) else ""
    exit_code = tool_response.get("exit_code") if isinstance(tool_response, dict) else None
    is_error = tool_response.get("is_error") if isinstance(tool_response, dict) else False

    # 성공 또는 build 아님 → 조용히 통과
    if not BUILD_PATTERNS.search(command):
        return 0
    if exit_code == 0 and not is_error:
        return 0

    # 프로토콜 reminder (stdout) — 사용자/어시스턴트 모두에게 노출
    print(
        "\n[post_build_fail] 프로토타입 빌드/테스트 실패 감지.\n"
        "프로젝트 의도 (2026-04-20): 이 프로젝트는 개발팀 인계용 기획서 완결이 목적.\n"
        "앱 실행 실패는 기획 공백/모순의 신호일 수 있음.\n\n"
        "다음 3-Type 분류를 먼저 수행한 후 대응 순서를 결정하십시오:\n"
        "  Type A (빌드 실수)   → 기획엔 답 있음. 구현 PR.\n"
        "  Type B (기획 공백)   → 팀마다 다른 가정. 기획 보강 PR 먼저.\n"
        "  Type C (기획 모순)   → 기획서 간 충돌. 기획 정렬 PR 먼저.\n\n"
        "상세 프로토콜: docs/4. Operations/Spec_Gap_Triage.md\n"
        "실패를 Type B/C 로 판정하면 `docs/4. Operations/Conductor_Backlog/SG-*.md` 생성으로 추적.\n",
        flush=True,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
