#!/usr/bin/env python3
"""
Orchestrator monitoring loop (Observer Mode).

v11 (default): subscribe-based push (broker, ~50ms latency).
v10.3 (--legacy): 30초 GitHub 폴링.

Usage:
  python orchestrator_monitor.py --config=...                  # v11 push (default)
  python orchestrator_monitor.py --config=... --legacy         # v10.3 polling
  python orchestrator_monitor.py --config=... --once           # 단발
"""
import argparse
import json
import socket
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


def _broker_alive():
    """Quick TCP probe — broker on 127.0.0.1:7383 (v11)."""
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(1.0)
    try:
        s.connect(("127.0.0.1", 7383))
        return True
    except OSError:
        return False
    finally:
        s.close()


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


def loop_polling(config_path, interval=30, once=False):
    """v10.3 polling loop — --legacy flag 활성 시 사용."""
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


# Backward-compat alias
loop = loop_polling


def loop_subscribe(config_path, once=False):
    """v11 subscribe-based loop. broker push 즉시 wake.

    fallback: broker dead 시 polling 으로 자동 전환 (graceful degradation).
    """
    if not _broker_alive():
        sys.stderr.write("⚠ broker dead — falling back to v10.3 polling\n")
        loop_polling(config_path, interval=30, once=once)
        return

    # observer_loop.py 의 subscribe loop 재사용
    # 2026-05-11 (S11 Cycle 2, Issue #240) — parent.parent 는 tools/ 에서 멈춰서
    # `from tools.orchestrator...` 절대 import 실패. project root 까지 3 hops 필요.
    sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))
    try:
        from tools.orchestrator.message_bus.observer_loop import observer_loop
    except ImportError as e:
        sys.stderr.write(f"⚠ observer_loop import failed: {e} — fallback polling\n")
        loop_polling(config_path, interval=30, once=once)
        return

    import asyncio
    if sys.platform == "win32":
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

    config = yaml.safe_load(Path(config_path).read_text(encoding='utf-8'))
    print(f"v11 Observer (subscribe-based) — config={config_path}")
    print(f"  streams: {list(config.get('streams', {}).keys())}")
    print(f"  fallback: --legacy → v10.3 polling")

    try:
        max_iter = 1 if once else None
        asyncio.run(observer_loop(topic="*", print_only=False, max_iter=max_iter))
    except KeyboardInterrupt:
        print("\nMonitor stopped.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--config', required=True)
    parser.add_argument('--interval', type=int, default=30, help='polling interval (legacy mode)')
    parser.add_argument('--once', action='store_true')
    parser.add_argument('--legacy', action='store_true',
                        help='v10.3 polling mode (default: v11 subscribe push)')
    args = parser.parse_args()

    if args.legacy:
        loop_polling(args.config, args.interval, args.once)
    else:
        loop_subscribe(args.config, args.once)


if __name__ == "__main__":
    main()
