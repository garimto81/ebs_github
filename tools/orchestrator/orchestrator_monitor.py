#!/usr/bin/env python3
"""
Orchestrator monitoring loop (Observer Mode).

30초 간격 GitHub 폴링 + 상황판 출력 + 의존성 위반 감지.

Usage:
  python orchestrator_monitor.py --config=docs/orchestrator/team_assignment.yaml
  python orchestrator_monitor.py --once   # 단발 실행
"""
import argparse
import json
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.stderr.write("PyYAML required\n")
    sys.exit(1)


def fetch_state():
    issues_result = subprocess.run([
        'gh', 'issue', 'list', '--state', 'all', '--limit', '50',
        '--json', 'number,title,state,labels,createdAt,updatedAt'
    ], capture_output=True, text=True)
    prs_result = subprocess.run([
        'gh', 'pr', 'list', '--state', 'all', '--limit', '50',
        '--json', 'number,title,state,isDraft,labels,headRefName,createdAt,mergedAt'
    ], capture_output=True, text=True)

    issues = json.loads(issues_result.stdout) if issues_result.returncode == 0 else []
    prs = json.loads(prs_result.stdout) if prs_result.returncode == 0 else []
    return issues, prs


def label_names(item):
    return [l['name'] for l in item.get('labels', [])]


def stream_state(stream_id, issues, prs):
    label = f"stream:{stream_id}"
    s_issues = [i for i in issues if label in label_names(i)]
    s_prs = [p for p in prs if label in label_names(p)]

    has_merged = any(p['state'] == 'MERGED' for p in s_prs)
    has_open_draft = any(p['state'] == 'OPEN' and p.get('isDraft') for p in s_prs)
    has_open_ready = any(p['state'] == 'OPEN' and not p.get('isDraft') for p in s_prs)

    if has_merged and not has_open_draft and not has_open_ready:
        return ('DONE', s_issues, s_prs)
    if has_open_ready:
        return ('REVIEW', s_issues, s_prs)
    if has_open_draft:
        return ('IN_PROGRESS', s_issues, s_prs)
    if s_issues:
        return ('STARTED', s_issues, s_prs)
    return ('IDLE', s_issues, s_prs)


def render_dashboard(config, issues, prs):
    lines = []
    lines.append("=" * 70)
    lines.append(f"Orchestrator Dashboard — {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    lines.append("=" * 70)
    lines.append(f"{'Stream':<6} {'State':<12} {'Issue':<8} {'PR':<10} {'Last':<10}")
    lines.append("-" * 70)

    streams = config.get('streams', {})
    violations = []

    for sid, sconfig in streams.items():
        state, s_issues, s_prs = stream_state(sid, issues, prs)
        issue_str = f"#{s_issues[0]['number']}" if s_issues else "-"
        pr_str = f"#{s_prs[0]['number']}" if s_prs else "-"
        last = "now" if s_prs else "-"
        lines.append(f"{sid:<6} {state:<12} {issue_str:<8} {pr_str:<10} {last:<10}")

        # 의존성 위반 검사
        if state in ['IN_PROGRESS', 'REVIEW']:
            for upstream in sconfig.get('blocked_by', []):
                up_state, _, _ = stream_state(upstream, issues, prs)
                if up_state != 'DONE':
                    violations.append((sid, upstream, up_state))

    lines.append("=" * 70)

    if violations:
        lines.append("\n⚠️ Dependency Violations:")
        for sid, up, up_state in violations:
            lines.append(f"   {sid} active but {up} is {up_state}")

    return "\n".join(lines)


def loop(config_path, interval=30, once=False):
    config = yaml.safe_load(Path(config_path).read_text(encoding='utf-8'))

    while True:
        try:
            issues, prs = fetch_state()
            print(render_dashboard(config, issues, prs))
            if once:
                break
            time.sleep(interval)
        except KeyboardInterrupt:
            print("\nMonitor stopped.")
            break
        except Exception as e:
            sys.stderr.write(f"Monitor error: {e}\n")
            if once:
                break
            time.sleep(interval)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--config', required=True)
    parser.add_argument('--interval', type=int, default=30)
    parser.add_argument('--once', action='store_true')
    args = parser.parse_args()
    loop(args.config, args.interval, args.once)


if __name__ == "__main__":
    main()
