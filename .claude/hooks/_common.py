"""Hook 공통 유틸: 팀 식별, bypass 모드 감지, 정책 로드."""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent.parent
POLICY_PATH = PROJECT / "docs" / "2. Development" / "2.5 Shared" / "team-policy.json"


def load_policy() -> dict:
    if not POLICY_PATH.exists():
        return {}
    try:
        return json.loads(POLICY_PATH.read_text(encoding="utf-8"))
    except Exception:
        return {}


def detect_team(cwd: str | None = None) -> str:
    """CWD 또는 env로 현재 팀 식별. fallback 'conductor'."""
    env = os.environ.get("EBS_TEAM", "").strip().lower()
    if env in ("conductor", "team1", "team2", "team3", "team4"):
        return env
    cwd = (cwd or os.getcwd()).replace("\\", "/").lower()
    for n in (1, 2, 3, 4):
        if f"/team{n}-" in cwd or cwd.endswith(f"/team{n}-frontend") \
                or cwd.endswith(f"/team{n}-backend") or cwd.endswith(f"/team{n}-engine") \
                or cwd.endswith(f"/team{n}-cc"):
            return f"team{n}"
        # CWD 가 team{N}-* 폴더 내부 어디든
        if f"/team{n}-frontend/" in cwd or f"/team{n}-backend/" in cwd \
                or f"/team{n}-engine/" in cwd or f"/team{n}-cc/" in cwd:
            return f"team{n}"
    return "conductor"


def is_bypass_mode(payload: dict | None = None) -> bool:
    """bypass permissions 감지: stdin payload 또는 env."""
    if payload and payload.get("permission_mode") == "bypassPermissions":
        return True
    env = os.environ.get("CLAUDE_BYPASS_HOOKS", "").lower()
    if "all" in env.split(","):
        return True
    return False


def read_payload() -> dict:
    """stdin JSON payload 읽기. 없으면 빈 dict."""
    if sys.stdin.isatty():
        return {}
    try:
        data = sys.stdin.read()
        return json.loads(data) if data else {}
    except Exception:
        return {}


def emit(decision: str | None = None, reason: str = "", warning: bool = False) -> None:
    """hook 응답 출력. decision=None이면 침묵 통과."""
    if decision is None and not warning:
        sys.exit(0)
    out = {}
    if decision:
        out["decision"] = decision
        out["reason"] = reason
    elif warning:
        # 경고는 stderr로 표시 + 통과
        sys.stderr.write(f"[hook warning] {reason}\n")
        sys.exit(0)
    sys.stdout.write(json.dumps(out))
    sys.exit(0)
