#!/usr/bin/env python3
"""SessionStart hook — v5.1 Pre-Work Contract visibility reminder.

⚠️ 등록 필수: 이 훅은 `.claude/settings.json` 에 등록해야 활성화됩니다.
   rule 17 (Circuit Breaker Deny-list) 에 따라 settings.json hook 정의
   자동 수정이 금지되어 있어, 사용자가 수동 등록 필요:

```json
"SessionStart": [
  {
    "hooks": [
      {"type": "command", "command": "python ${CLAUDE_PROJECT_DIR}/.claude/hooks/session_branch_init.py"},
      {"type": "command", "command": "python ${CLAUDE_PROJECT_DIR}/.claude/hooks/active_work_reminder.py"}
    ]
  }
]
```

목적:
  v5.1 Pre-Work Contract (proactive coordination) 의 L0 layer.
  세션 시작 시 현재 active claims 을 stderr 로 전시 + 팀 claim 가이드 출력.
  **block 하지 않음** — visibility 만. 사용자가 의도적으로 skip 가능.

동작:
  1. docs/4. Operations/Active_Work.md 읽기 (없거나 파싱 실패 시 침묵 통과)
  2. 활성 claim 요약 출력 (최대 10 개)
  3. cwd 로 팀 추론 → 해당 팀의 기존 claim 있으면 reminder
  4. cwd 가 sibling worktree 이면 scope 힌트 제공
  5. 실패 시 침묵 (hook 은 사용자를 방해하지 않음)

Exit:
  0 — 항상 (실패 침묵)
"""
from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    yaml = None  # type: ignore

# 현재 cwd 가 repo root 또는 sibling worktree 일 수 있으므로 여러 후보 탐색
CANDIDATE_REPOS = [
    Path.cwd(),
    Path("C:/claude/ebs"),
]


def _find_ssot() -> Path | None:
    for base in CANDIDATE_REPOS:
        p = base / "docs" / "4. Operations" / "Active_Work.md"
        if p.exists():
            return p
    # sibling worktree (ebs-teamN-*) → 상위가 C:/claude
    c = Path.cwd()
    for parent in [c, *c.parents]:
        name = parent.name.lower()
        if name == "ebs" or re.match(r"^ebs-team[1-4]-", name):
            p = parent / "docs" / "4. Operations" / "Active_Work.md"
            if p.exists():
                return p
    return None


def _detect_team(cwd: str | None) -> str:
    c = (cwd or os.getcwd()).replace("\\", "/").lower()
    m = re.search(r"/ebs-(team[1-4])-", c + "/")
    if m:
        return m.group(1)
    m2 = re.search(r"/ebs/team([1-4])-", c + "/")
    if m2:
        return f"team{m2.group(1)}"
    return "conductor"


def _parse_claims(md_text: str) -> list[dict]:
    if yaml is None:
        return []
    b = md_text.find("<!-- CLAIMS_BEGIN -->")
    e = md_text.find("<!-- CLAIMS_END -->")
    if b == -1 or e == -1 or e < b:
        return []
    inner = md_text[b:e]
    claims: list[dict] = []
    for m in re.finditer(r"```yaml\n(.*?)\n```", inner, re.DOTALL):
        try:
            d = yaml.safe_load(m.group(1))
            if isinstance(d, dict):
                claims.append(d)
        except yaml.YAMLError:
            pass
    return claims


def _read_payload() -> dict:
    try:
        data = sys.stdin.read()
        if data.strip():
            return json.loads(data)
    except Exception:
        pass
    return {}


def main() -> int:
    try:
        ssot = _find_ssot()
        if not ssot:
            return 0  # 침묵 통과

        payload = _read_payload()
        cwd = payload.get("cwd") or os.getcwd()
        team = _detect_team(cwd)

        md = ssot.read_text(encoding="utf-8")
        claims = _parse_claims(md)

        sys.stderr.write("\n")
        sys.stderr.write("━" * 68 + "\n")
        sys.stderr.write(f" 🗂️  EBS Active Work (v5.1 Pre-Work Contract)\n")
        sys.stderr.write("━" * 68 + "\n")
        sys.stderr.write(f"  Session team (cwd 기반 추론): {team}\n")

        if not claims:
            sys.stderr.write("  (현재 active claim 없음 — 깨끗한 상태)\n")
        else:
            sys.stderr.write(f"  현재 active claims: {len(claims)} 건\n\n")
            my_claims = [c for c in claims if c.get("team") == team]
            other_claims = [c for c in claims if c.get("team") != team]

            if my_claims:
                sys.stderr.write(f"  📌 당신 ({team}) 의 기존 claim:\n")
                for c in my_claims[:5]:
                    sys.stderr.write(f"    #{c.get('id','?')}: {c.get('task','?')}\n")
                    scope = c.get("scope", [])
                    if scope:
                        scope_str = ", ".join(scope[:2])
                        if len(scope) > 2:
                            scope_str += f" (+{len(scope)-2})"
                        sys.stderr.write(f"      scope: {scope_str}\n")

            if other_claims:
                sys.stderr.write(f"  ⚠️  다른 팀의 active claim (scope 겹침 주의):\n")
                for c in other_claims[:5]:
                    scope = c.get("scope", [])
                    scope_str = ", ".join(scope[:2])
                    if len(scope) > 2:
                        scope_str += f" (+{len(scope)-2})"
                    sys.stderr.write(f"    #{c.get('id','?')} [{c.get('team','?')}]: {c.get('task','?')}\n")
                    sys.stderr.write(f"      scope: {scope_str}\n")

        sys.stderr.write("\n")
        sys.stderr.write("  작업 시작 전:\n")
        sys.stderr.write("    1. scope 확인: python tools/active_work_claim.py check --scope \"path/glob,...\"\n")
        sys.stderr.write("    2. claim 추가: python tools/active_work_claim.py add --team <team> --task \"...\" --scope \"...\"\n")
        sys.stderr.write("  상세: docs/4. Operations/Active_Work.md\n")
        sys.stderr.write("━" * 68 + "\n\n")
        return 0
    except Exception as e:
        # 침묵 통과 — hook 이 세션을 방해하면 안 됨
        try:
            sys.stderr.write(f"[active-work-reminder] warn: {e}\n")
        except Exception:
            pass
        return 0


if __name__ == "__main__":
    sys.exit(main())
