#!/usr/bin/env python3
"""
PreToolUse hook (Layer 5 of 6-layer defense).

Blocks Edit/Write/MultiEdit tools when:
1. Target file is in meta_files_blocked
2. Target file is outside scope_owns
3. Stream is BLOCKED by dependency (no edits allowed)

Placement: <worktree>/.claude/hooks/PreToolUse.py
Trigger: Before every Edit/Write/MultiEdit tool call.

Exit codes:
  0 = allow (default)
  2 = block + show stderr to LLM
"""
import os
import sys
import json
import subprocess
from pathlib import Path
from fnmatch import fnmatch

try:
    import yaml
except ImportError:
    sys.exit(0)  # 없으면 차단 안 함 (graceful degrade)


WRITE_TOOLS = {'Edit', 'Write', 'MultiEdit', 'NotebookEdit'}


def get_repo_root():
    """git worktree base 찾기 (못 찾으면 cwd)"""
    try:
        result = subprocess.run(
            ['git', 'rev-parse', '--show-toplevel'],
            capture_output=True, text=True, timeout=5
        )
        if result.returncode == 0:
            return Path(result.stdout.strip())
    except Exception:
        pass
    return Path.cwd()


def relative_to_root(target_path):
    """절대 경로 → repo root 기준 상대 경로"""
    try:
        target = Path(target_path).resolve()
        root = get_repo_root().resolve()
        return str(target.relative_to(root)).replace('\\', '/')
    except (ValueError, OSError):
        return None


def check_meta_file(target_rel, team_data):
    blocked = team_data.get('meta_files_blocked', [])
    for pattern in blocked:
        if fnmatch(target_rel, pattern):
            sys.stderr.write(
                f"⛔ BLOCK: '{target_rel}' is META file (orchestrator only).\n"
                f"   To request change, add '## Meta Changes Requested' to PR body.\n"
            )
            return True
    return False


def check_scope(target_rel, team_data):
    scope_owns = team_data.get('scope_owns', [])
    if not scope_owns:
        return False  # SCOPE 정의 없음 = 차단 안 함 (관대)

    for pattern in scope_owns:
        # fnmatch는 ** 미지원 → 변환
        if '**' in pattern:
            # docs/lobby/** → docs/lobby/* (재귀 매칭)
            base = pattern.rsplit('/**', 1)[0]
            if target_rel == base or target_rel.startswith(base + '/'):
                return False  # OK
        else:
            if fnmatch(target_rel, pattern):
                return False  # OK

    sys.stderr.write(
        f"⛔ BLOCK: '{target_rel}' is OUTSIDE {team_data['team_id']} scope.\n"
        f"   Allowed:\n"
    )
    for s in scope_owns[:5]:
        sys.stderr.write(f"     - {s}\n")
    return True


def check_dependency_status(team_data):
    """SessionStart hook과 동일 로직 (간소화)"""
    blocked_by = team_data.get('blocked_by', [])
    if not blocked_by:
        return False

    for upstream in blocked_by:
        try:
            result = subprocess.run([
                'gh', 'pr', 'list',
                '--label', f'stream:{upstream}',
                '--state', 'all',
                '--limit', '1',
                '--json', 'state'
            ], capture_output=True, text=True, timeout=10)

            if result.returncode != 0:
                continue  # gh 미사용 시 차단 안 함

            prs = json.loads(result.stdout)
            if not prs or prs[0].get('state') != 'MERGED':
                sys.stderr.write(
                    f"⛔ BLOCK: {team_data['team_id']} is BLOCKED by {upstream}.\n"
                    f"   Wait for {upstream} PR to merge.\n"
                )
                return True
        except Exception:
            continue
    return False


def cascade_advisory(target_rel, repo_root):
    """docs edit 시 영향 문서 list 를 stderr 에 advisory 로 출력 (non-blocking)."""
    if not target_rel.startswith("docs/") or not target_rel.endswith(".md"):
        return
    discovery = repo_root / "tools" / "doc_discovery.py"
    if not discovery.exists():
        return
    try:
        result = subprocess.run(
            [sys.executable, str(discovery), "--impact-of", target_rel],
            capture_output=True, text=True, timeout=15,
            encoding="utf-8", errors="ignore",
            env={**os.environ, "PYTHONIOENCODING": "utf-8", "PYTHONUTF8": "1"},
        )
        out = (result.stdout or "").strip()
        if not out:
            return
        import re as _re
        pat = "docs/[^" + chr(10) + chr(13) + chr(9) + r"<>|*?]+?\.md"
        paths = []
        seen = set()
        for line in out.splitlines():
            m = _re.search(pat, line)
            if m:
                p2 = m.group(0)
                if p2 != target_rel and p2 not in seen:
                    seen.add(p2)
                    paths.append(p2)
        if paths:
            sys.stderr.write(chr(10) + "[doc-cascade] Editing '" + target_rel + "' may affect " + str(len(paths)) + " docs:" + chr(10))
            for q in paths[:8]:
                sys.stderr.write("     - " + q + chr(10))
            if len(paths) > 8:
                sys.stderr.write("     ... +" + str(len(paths) - 8) + " more" + chr(10))
            sys.stderr.write("   (advisory only -- not blocked)" + chr(10) + chr(10))
    except (subprocess.TimeoutExpired, OSError):
        pass


def main():
    # stdin에서 tool input 읽기
    try:
        tool_input = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)  # malformed input — 차단 안 함

    tool_name = tool_input.get('tool_name', '')
    if tool_name not in WRITE_TOOLS:
        sys.exit(0)

    # .team 파일 찾기 (worktree root)
    cwd = Path.cwd()
    team_file = cwd / '.team'
    if not team_file.exists():
        sys.exit(0)  # main session

    try:
        team_data = yaml.safe_load(team_file.read_text(encoding='utf-8'))
    except Exception:
        sys.exit(0)

    # 대상 파일 추출
    inputs = tool_input.get('tool_input', {})
    target = inputs.get('file_path') or inputs.get('path')
    if not target:
        sys.exit(0)

    target_rel = relative_to_root(target)
    if not target_rel:
        sys.exit(0)

    # Cascade advisory (non-blocking, before any block check)
    cascade_advisory(target_rel, get_repo_root())

    # 의존성 차단 검사 (가장 우선)
    if check_dependency_status(team_data):
        sys.exit(2)

    # 메타 파일 차단
    if check_meta_file(target_rel, team_data):
        sys.exit(2)

    # SCOPE 차단
    if check_scope(target_rel, team_data):
        sys.exit(2)

    sys.exit(0)


if __name__ == "__main__":
    main()
