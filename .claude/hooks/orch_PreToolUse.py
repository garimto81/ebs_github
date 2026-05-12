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


def _detect_cascade_impact(target_rel, repo_root):
    """B-222 L4 prereq — chat advisory feed.

    Run `tools.doc_discovery.impact_of` to find docs impacted by editing `target_rel`.
    Returns list of relative paths (max 20). Silent [] on any error.
    Used by emit_chat_advisory (chat:room:design system message).
    """
    try:
        sys.path.insert(0, str(repo_root))
        from tools import doc_discovery
        docs = doc_discovery.scan_docs()
        result = doc_discovery.impact_of(docs, target_rel)
        paths = []
        for _bucket, metas in result.items():
            for m in metas:
                p = getattr(m, "path", None)
                if p and str(p) != target_rel:
                    paths.append(str(p))
        # dedupe + cap
        seen = set()
        unique = []
        for p in paths:
            if p not in seen:
                seen.add(p)
                unique.append(p)
            if len(unique) >= 20:
                break
        return unique
    except Exception:
        return []


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

    # 결함 #138 fix: 런타임 worktree_path mismatch 감지 (mid-session contamination 차단)
    # SessionStart 시점엔 OK 였더라도, 세션 도중 다른 stream 의 .team 으로 덮어쓰여지면
    # 후속 Edit/Write 가 잘못된 scope_owns 로 평가되어 작업이 다른 stream 영역에 누출될 위험.
    expected_path = (team_data.get('worktree_path') or '').rstrip('/').replace('\\', '/')
    repo_root = get_repo_root()
    actual_path = str(repo_root.resolve()).rstrip('/').replace('\\', '/')
    if expected_path and actual_path.lower() != expected_path.lower():
        sys.stderr.write(
            f"⛔ BLOCK: .team contamination detected (mid-session race).\n"
            f"   .team team_id        = {team_data.get('team_id')}\n"
            f"   .team worktree_path  = {expected_path}\n"
            f"   actual worktree path = {actual_path}\n"
            f"   → 다른 stream 의 .team 이 이 워크트리를 덮어썼습니다.\n"
            f"   복구: 올바른 .team 재작성 (setup_stream_worktree.py 재실행) 후 재시도.\n"
        )
        sys.exit(2)

    # 대상 파일 추출
    inputs = tool_input.get('tool_input', {})
    target = inputs.get('file_path') or inputs.get('path')
    if not target:
        sys.exit(0)

    target_rel = relative_to_root(target)
    if not target_rel:
        sys.exit(0)

    # 의존성 차단 검사 (가장 우선)
    if check_dependency_status(team_data):
        sys.exit(2)

    # 메타 파일 차단
    if check_meta_file(target_rel, team_data):
        sys.exit(2)

    # SCOPE 차단
    if check_scope(target_rel, team_data):
        sys.exit(2)

    # B-222 L4 prereq — cascade chat advisory (non-blocking, fire-and-forget)
    # impacted docs 발견 시 chat:room:design 에 system message publish.
    # broker dead / doc_discovery 실패 모두 silent skip (hook 차단 X).
    if target_rel.endswith('.md'):
        try:
            impacted = _detect_cascade_impact(target_rel, repo_root)
            if impacted:
                from tools.chat_server.hook_integration import emit_chat_advisory
                emit_chat_advisory(
                    target_rel, impacted,
                    editor_team=team_data.get('team_id', 'unknown'),
                )
        except Exception as _e:
            sys.stderr.write(f"[chat-advisory] silent skip: {_e}\n")

    sys.exit(0)


if __name__ == "__main__":
    main()
