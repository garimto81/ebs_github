#!/usr/bin/env python3
"""
Stream session 시작 시 호출 (워크트리 안에서).

자동 수행:
1. git fetch + 의존성 확인
2. GitHub Issue 생성 (status:in-progress 라벨)
3. Draft PR 생성 (Issue link)

Usage:
  python team_session_start.py [--title "작업 제목"]
"""
import argparse
import json
import subprocess
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.stderr.write("PyYAML required\n")
    sys.exit(1)


def load_team():
    team_file = Path.cwd() / '.team'
    if not team_file.exists():
        sys.stderr.write("⛔ .team not found. Are you in a Stream worktree?\n")
        sys.exit(1)
    return yaml.safe_load(team_file.read_text(encoding='utf-8'))


def check_dependency(team):
    """blocked_by 모두 merged 인지 확인"""
    for upstream in team.get('blocked_by', []):
        result = subprocess.run([
            'gh', 'pr', 'list',
            '--label', f'stream:{upstream}',
            '--state', 'all',
            '--limit', '1',
            '--json', 'state'
        ], capture_output=True, text=True)
        if result.returncode != 0:
            return True  # gh 미사용 시 통과
        prs = json.loads(result.stdout)
        if not prs or prs[0].get('state') != 'MERGED':
            sys.stderr.write(
                f"⛔ BLOCKED by {upstream}. Cannot start session.\n"
            )
            return False
    return True


def create_issue(team, title):
    body = f"""## Stream Work Declaration

Stream: **{team['team_id']} ({team['team_name']})**
Phase: (auto-detected)

### Scope
{chr(10).join(f'- {p}' for p in team.get('scope_owns', []))}

### Dependencies
Blocked by: {team.get('blocked_by', []) or 'none'}

### Worktree
`{team.get('worktree_path', 'unknown')}`

---
Auto-created by orchestrator skill.
"""
    result = subprocess.run([
        'gh', 'issue', 'create',
        '--title', f"[{team['team_id']}] {title}",
        '--label', f"stream:{team['team_id']},status:in-progress",
        '--body', body
    ], capture_output=True, text=True)
    if result.returncode != 0:
        sys.stderr.write(f"Issue create failed: {result.stderr}\n")
        return None
    # URL parse → number
    url = result.stdout.strip()
    issue_num = int(url.rsplit('/', 1)[-1])
    print(f"✓ Issue #{issue_num} created: {url}")
    return issue_num


def create_draft_pr(team, issue_num, title):
    """현재 브랜치에서 빈 commit 후 draft PR"""
    branch = team.get('branch', '')
    # 빈 커밋 (placeholder)
    subprocess.run(['git', 'commit', '--allow-empty', '-m', f'chore: start {team["team_id"]}'])
    subprocess.run(['git', 'push', '-u', 'origin', branch])

    body = f"""## Stream
Stream: {team['team_id']}
Phase: P{team.get('current_phase', '?')}

Closes #{issue_num}

## Changes
(work in progress)

## Scope Verification
- [ ] Changed files within `scope_owns`
- [ ] Meta files unchanged

## Dependencies
{', '.join(f'#{d}' for d in team.get('blocked_by', [])) or 'none'}
"""
    result = subprocess.run([
        'gh', 'pr', 'create',
        '--draft',
        '--base', 'main',
        '--head', branch,
        '--title', f"[{team['team_id']}] {title}",
        '--label', f"stream:{team['team_id']},draft",
        '--body', body
    ], capture_output=True, text=True)
    if result.returncode != 0:
        sys.stderr.write(f"PR create failed: {result.stderr}\n")
        return None
    print(f"✓ Draft PR created: {result.stdout.strip()}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--title', default='in progress', help='Work title')
    args = parser.parse_args()

    team = load_team()
    if not check_dependency(team):
        sys.exit(1)

    issue_num = create_issue(team, args.title)
    if issue_num:
        create_draft_pr(team, issue_num, args.title)
    print(f"\n✅ Session ready. Start working in: {team.get('worktree_path')}")


if __name__ == "__main__":
    main()
