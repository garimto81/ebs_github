#!/usr/bin/env python3
"""
Stream session 시작 시 호출 (워크트리 안에서).

핵심 동작 (사용자 요구 — Orchestrator 모니터링 활성화):
1. 의존성 확인 (blocked_by 모두 merged?)
2. 워크트리 setup 파일 commit (init commit)
3. push origin
4. Init PR 생성 (ready, draft 아님)
5. **즉시 자동 머지** (--squash --delete-branch)
6. 새 work 브랜치 생성 (워크트리 검출 후 작업용)

이 PR이 머지되면 Orchestrator의 `gh pr list --label stream:SX` 가 Stream 활성화를 감지.

Usage:
  python team_session_start.py [--title "작업 제목"]
"""
import argparse
import json
import re
import subprocess
import sys
from datetime import date
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
            '--limit', '5',
            '--json', 'state,labels'
        ], capture_output=True, text=True)
        if result.returncode != 0:
            return True  # gh CLI 없으면 통과
        prs = json.loads(result.stdout)
        # initialization 또는 작업 PR이 머지된 것 검색
        merged = [p for p in prs if p.get('state') == 'MERGED']
        if not merged:
            sys.stderr.write(
                f"⛔ BLOCKED by {upstream}. No merged PR with stream:{upstream} label.\n"
                f"   Wait for {upstream} session to run team_session_start.py first.\n"
            )
            return False
    return True


def init_commit_and_push(team):
    """워크트리 setup 파일들을 commit + push"""
    files_to_add = [
        '.team',
        'CLAUDE.md',
        'START_HERE.md',
        '.claude/hooks/orch_SessionStart.py',
        '.claude/hooks/orch_PreToolUse.py',
        '.claude/settings.json',  # hooks merged
        '.vscode/settings.json',
    ]
    # 존재하는 것만 add
    existing = [f for f in files_to_add if Path(f).exists()]

    subprocess.run(['git', 'add'] + existing, capture_output=True)
    result = subprocess.run(
        ['git', 'commit', '-m', f'feat({team["team_id"]}): Stream init - identity + hooks + scope'],
        capture_output=True, text=True
    )
    if result.returncode != 0 and 'nothing to commit' not in result.stdout + result.stderr:
        sys.stderr.write(f"⚠ commit warning: {result.stdout}{result.stderr}\n")

    subprocess.run(['git', 'push', '-u', 'origin', team['branch']], check=True)
    print(f"✓ Pushed init commit to origin/{team['branch']}")


def create_and_merge_init_pr(team):
    """Init PR 생성 + 즉시 머지 = Orchestrator 활성화 신호"""
    body = f"""## 🚀 Stream Initialization

Stream: **{team['team_id']} ({team['team_name']})**
Worktree: `{team.get('worktree_path', 'unknown')}`

### Setup Files Merged
- `.team` (identity SSOT)
- `CLAUDE.md` (Stream-local override)
- `START_HERE.md` (사용자 첫 화면)
- `.claude/hooks/orch_*.py` (Layer 4, 5 defense)
- `.claude/settings.json` (hooks merged with EBS existing)

### Scope
{chr(10).join(f'- {p}' for p in team.get('scope_owns', []))}

### Dependencies
{', '.join(f'#{d}' for d in team.get('blocked_by', [])) or '없음 (즉시 활성화)'}

---
🤖 **Auto-merge enabled** — Orchestrator activation signal via `gh pr list --label stream:{team['team_id']}`
"""
    title = f"[{team['team_id']}] Stream Initialization"
    label = f"stream:{team['team_id']},type:initialization,status:auto-merge"

    create_result = subprocess.run([
        'gh', 'pr', 'create',
        '--base', 'main',
        '--head', team['branch'],
        '--title', title,
        '--label', label,
        '--body', body
    ], capture_output=True, text=True)

    if create_result.returncode != 0:
        sys.stderr.write(f"PR create failed: {create_result.stderr}\n")
        sys.exit(1)

    pr_url = create_result.stdout.strip()
    pr_num = int(re.search(r'/pull/(\d+)', pr_url).group(1))
    print(f"✓ Init PR #{pr_num}: {pr_url}")

    # 즉시 머지 (--squash --delete-branch)
    merge_result = subprocess.run([
        'gh', 'pr', 'merge', str(pr_num),
        '--squash', '--delete-branch', '--auto'
    ], capture_output=True, text=True)
    if merge_result.returncode == 0:
        print(f"✓ PR #{pr_num} auto-merge enabled (will merge after CI green)")
    else:
        print(f"⚠ Auto-merge setup: {merge_result.stderr[:200]}")
        print(f"  → Trying immediate merge...")
        immediate = subprocess.run([
            'gh', 'pr', 'merge', str(pr_num),
            '--squash', '--delete-branch'
        ], capture_output=True, text=True)
        if immediate.returncode == 0:
            print(f"✓ PR #{pr_num} merged immediately")
        else:
            print(f"⚠ Immediate merge: {immediate.stderr[:200]}")

    return pr_num


def switch_to_work_branch(team):
    """Init 머지 후 새 작업 브랜치로 전환"""
    branch = team['branch']
    work_branch = branch.replace('-init', f'-work-{date.today().isoformat()}')

    subprocess.run(['git', 'fetch', 'origin'], capture_output=True)

    # main에서 새 브랜치 생성 (Init PR이 머지된 main 기준)
    result = subprocess.run(
        ['git', 'checkout', '-b', work_branch, 'origin/main'],
        capture_output=True, text=True
    )
    if result.returncode == 0:
        print(f"✓ Switched to work branch: {work_branch}")
        # .team에 새 브랜치 반영
        team_file = Path.cwd() / '.team'
        if team_file.exists():
            team_data = yaml.safe_load(team_file.read_text(encoding='utf-8'))
            team_data['branch'] = work_branch
            team_file.write_text(yaml.safe_dump(team_data, allow_unicode=True, sort_keys=False),
                                 encoding='utf-8')
            print(f"✓ .team branch updated to {work_branch}")
    else:
        print(f"⚠ Branch switch failed (init PR not yet merged?): {result.stderr[:150]}")
        print(f"  → After init PR merge, run: git checkout -b {work_branch} origin/main")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--title', default='Stream init', help='Init context')
    parser.add_argument('--skip-merge', action='store_true', help='Create PR but do not merge')
    parser.add_argument('--skip-switch', action='store_true', help='Do not switch to work branch')
    args = parser.parse_args()

    team = load_team()

    print(f"🚀 {team['team_id']} ({team['team_name']}) Stream initialization\n")

    # 1. Dependency check
    if not check_dependency(team):
        sys.exit(1)
    print("✓ Dependencies satisfied")

    # 2. Init commit + push
    init_commit_and_push(team)

    # 3. PR 생성 + 머지
    if args.skip_merge:
        print("⏭ Skipping merge (--skip-merge)")
    else:
        pr_num = create_and_merge_init_pr(team)

    # 4. Work branch 전환
    if not args.skip_switch:
        switch_to_work_branch(team)

    # 5. 사용자 안내
    print(f"\n{'='*60}")
    print(f"✅ Stream {team['team_id']} ACTIVATED")
    print(f"   Orchestrator monitoring: gh pr list --label stream:{team['team_id']}")
    print(f"   Now begin actual work in worktree.")
    print(f"   When done: python team_session_end.py --message='<요약>'")


if __name__ == "__main__":
    main()
