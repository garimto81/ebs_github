#!/usr/bin/env python3
"""
Stream session 종료 시 호출 (워크트리 안에서).

자동 수행:
1. 모든 변경 사항 commit
2. PR ready_for_review (Draft → Ready)
3. auto-merge 활성화
4. 머지 + 브랜치 삭제 → 워크트리 정리

Usage:
  python team_session_end.py [--message "completion summary"]
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
        sys.stderr.write("⛔ .team not found.\n")
        sys.exit(1)
    return yaml.safe_load(team_file.read_text(encoding='utf-8'))


def find_pr(team):
    branch = team.get('branch', '')
    result = subprocess.run([
        'gh', 'pr', 'list',
        '--head', branch,
        '--state', 'open',
        '--json', 'number,isDraft,state'
    ], capture_output=True, text=True)
    prs = json.loads(result.stdout)
    return prs[0] if prs else None


def _publish_done_signal(team, pr_num):
    """v11 Phase B: PR ready 후 broker 에 stream:S{N} DONE 신호 발행.

    의존하는 stream 의 subscribe(topic="stream:S{N}") 가 즉시 wake.
    broker dead → silent skip (v10.3 호환).
    """
    import socket as _socket
    s = _socket.socket(_socket.AF_INET, _socket.SOCK_STREAM)
    s.settimeout(1.0)
    try:
        s.connect(("127.0.0.1", 7383))
    except OSError:
        return  # broker dead, silent skip
    finally:
        s.close()

    try:
        import asyncio as _asyncio
        from mcp import ClientSession  # type: ignore
        from mcp.client.streamable_http import streamablehttp_client  # type: ignore

        async def _run():
            async with streamablehttp_client("http://127.0.0.1:7383/mcp") as (r, w, _gs):
                async with ClientSession(r, w) as sess:
                    await sess.initialize()
                    await sess.call_tool("publish_event", {
                        "topic": f"stream:{team['team_id']}",
                        "payload": {
                            "status": "DONE",
                            "pr": pr_num,
                            "branch": team.get("branch", ""),
                        },
                        "source": team["team_id"],
                    })

        try:
            _asyncio.run(_asyncio.wait_for(_run(), timeout=3.0))
            print(f"✓ broker: published stream:{team['team_id']} DONE (PR #{pr_num})")
        except Exception as e:
            print(f"⚠ broker publish failed: {e} (non-fatal)")
    except Exception as e:
        print(f"⚠ broker import failed: {e} (non-fatal)")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--message', default='Stream work complete')
    parser.add_argument('--no-cleanup', action='store_true', help='Keep worktree')
    args = parser.parse_args()

    team = load_team()
    branch = team.get('branch', '')

    # 1. commit + push
    subprocess.run(['git', 'add', '-A'])
    result = subprocess.run(
        ['git', 'commit', '-m', f"feat({team['team_id']}): {args.message}"],
        capture_output=True
    )
    if result.returncode == 0:
        print("✓ Changes committed")
    subprocess.run(['git', 'push', 'origin', branch])

    # 2. Find PR
    pr = find_pr(team)
    if not pr:
        sys.stderr.write("⛔ PR not found. Did you run team_session_start.py?\n")
        sys.exit(1)
    pr_num = pr['number']

    # 3. Mark as ready
    if pr.get('isDraft'):
        subprocess.run(['gh', 'pr', 'ready', str(pr_num)])
        print(f"✓ PR #{pr_num} marked ready")

    # 4. Auto-merge
    subprocess.run([
        'gh', 'pr', 'merge', str(pr_num),
        '--auto', '--squash', '--delete-branch'
    ])
    print(f"✓ Auto-merge enabled for PR #{pr_num}")

    # 4.5 v11: publish_event(stream:S{N}, status=DONE) — broker 가 살아있을 때만
    _publish_done_signal(team, pr_num)

    # 5. Worktree cleanup (optional)
    if not args.no_cleanup:
        print(f"\n💡 Worktree cleanup:")
        print(f"   PR will auto-merge when CI passes.")
        print(f"   After merge, exit Claude Code and run from main repo:")
        print(f"     git worktree remove {team.get('worktree_path')}")
    print(f"\n✅ Session ended. Monitoring: gh pr view {pr_num}")


if __name__ == "__main__":
    main()
