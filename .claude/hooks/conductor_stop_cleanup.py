#!/usr/bin/env python3
"""Stop hook: Conductor 세션 종료 시 main 복귀 + auto-stash.

설계 근거: 멀티 세션 워크플로우 MVI Phase 1.
- 선행 Conductor 세션이 team 브랜치에 고정된 채 종료되면 다음 세션이 오염된 상태로 시작.
- 시작-시 강제 교정은 dirty tree 유실 위험 → 종료-시 정리가 안전.
- Conductor 세션이 아니면 침묵 통과 (팀 세션은 자유).
"""
from __future__ import annotations

import datetime
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from _common import detect_team, read_payload, PROJECT  # noqa: E402


def _git(*args: str) -> tuple[int, str]:
    try:
        r = subprocess.run(["git", *args], cwd=PROJECT, capture_output=True,
                           text=True, timeout=10)
        return r.returncode, (r.stdout + r.stderr).strip()
    except Exception as e:
        return 1, str(e)


def _current_branch() -> str:
    code, out = _git("branch", "--show-current")
    return out if code == 0 else ""


def _has_uncommitted() -> bool:
    code, out = _git("status", "--porcelain")
    return bool(out.strip()) if code == 0 else False


def main() -> int:
    payload = read_payload()
    team = detect_team(payload.get("cwd"))
    if team != "conductor":
        return 0

    cur = _current_branch()
    if cur == "main" or cur == "":
        return 0

    sys.stderr.write(f"[conductor-cleanup] Conductor session ending on non-main branch: {cur}\n")

    stashed = False
    if _has_uncommitted():
        ts = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
        code, out = _git("stash", "push", "-u", "-m",
                         f"auto-conductor-stop-{ts} — main 복귀 전 WIP 보존")
        if code == 0:
            stashed = True
            sys.stderr.write(f"[conductor-cleanup] stashed uncommitted changes\n")
        else:
            sys.stderr.write(f"[conductor-cleanup] stash failed ({out}); staying on {cur}\n")
            return 0

    code, out = _git("checkout", "main")
    if code == 0:
        sys.stderr.write(f"[conductor-cleanup] restored to main (stashed={stashed})\n")
    else:
        sys.stderr.write(f"[conductor-cleanup] checkout main failed: {out}\n")

    # v4.0: stale session-manifest 정리
    _try_cleanup_manifests()

    return 0


def _try_cleanup_manifests() -> None:
    """세션 종료 시 stale manifest 정리 (v4.0). 실패 시 침묵."""
    try:
        skill_script = Path.home() / ".claude" / "skills" / "team" / "scripts" / "team_manifest.py"
        if skill_script.exists():
            subprocess.run(
                [sys.executable, str(skill_script), "cleanup-stale"],
                cwd=PROJECT, capture_output=True, timeout=5,
            )
    except Exception:
        pass


if __name__ == "__main__":
    sys.exit(main())
