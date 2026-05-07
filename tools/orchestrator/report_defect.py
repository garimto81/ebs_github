#!/usr/bin/env python3
"""
Orchestrator defect reporting channel (메타 결함 보고 체계).

Stream 세션이 orchestrator 자체 결함 발견 시 호출.

자동 수행:
1. GitHub Issue 생성 (label: orchestrator-defect, severity:{level})
2. .orchestrator/HALT signal main에 commit (다른 stream 차단)
3. 사용자 escalate 출력

Usage:
  python report_defect.py --severity high --title "..." [--description "..."]
  python report_defect.py --resolve  # HALT 신호 해제 (defect fix 후)
"""
import argparse
import subprocess
import sys
from datetime import datetime
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.stderr.write("PyYAML required\n")
    sys.exit(1)


def find_repo_root():
    result = subprocess.run(['git', 'rev-parse', '--show-toplevel'],
                            capture_output=True, text=True)
    return Path(result.stdout.strip()) if result.returncode == 0 else None


def report(severity, title, description, reporter):
    """결함 보고 = GitHub Issue + main HALT commit"""
    repo_root = find_repo_root()
    if not repo_root:
        sys.stderr.write("⛔ Not in a git repo\n")
        sys.exit(1)

    # 1. GitHub Issue 생성
    body = f"""## Orchestrator Defect Report

**Reporter**: {reporter or 'unknown stream'}
**Severity**: {severity}
**Discovered**: {datetime.now().isoformat()}

### Description
{description or '(none)'}

### Effect
Other streams BLOCKED via `.orchestrator/HALT` signal.

### Resolution Status
🔴 Pending — main에 HALT signal 활성. fix 후 `report_defect.py --resolve` 호출.

---
Auto-created by orchestrator/report_defect.py
"""
    issue_url = subprocess.run([
        'gh', 'issue', 'create',
        '--title', f'[ORCHESTRATOR-DEFECT] {title}',
        '--label', f'orchestrator-defect,severity:{severity}',
        '--body', body
    ], capture_output=True, text=True).stdout.strip()
    print(f"✓ Issue: {issue_url}")

    # 2. .orchestrator/HALT signal commit
    halt_dir = repo_root / '.orchestrator'
    halt_dir.mkdir(exist_ok=True)
    halt_file = halt_dir / 'HALT'

    halt_content = yaml.safe_dump({
        'defect_id': f"ORCH-{datetime.now().strftime('%Y%m%d-%H%M')}",
        'reporter': reporter or 'unknown',
        'severity': severity,
        'title': title,
        'description': description or '',
        'discovered_at': datetime.now().isoformat(),
        'github_issue': issue_url,
        'resolution_status': 'pending',
    }, allow_unicode=True, sort_keys=False)
    halt_file.write_text(halt_content, encoding='utf-8')

    # commit + push (main 직접 또는 별도 브랜치 — 여기선 직접)
    subprocess.run(['git', '-C', str(repo_root), 'add', str(halt_file.relative_to(repo_root))])
    subprocess.run(['git', '-C', str(repo_root), 'commit', '-m',
                   f'chore(orchestrator): HALT signal — {title}'])
    print("✓ HALT signal committed (push 필요 시 별도)")

    print(f"\n⛔ All streams will halt on next SessionStart hook.")
    print(f"   Resolve defect, then run: report_defect.py --resolve")


def resolve():
    """defect resolved → HALT signal 제거 + Issue close"""
    repo_root = find_repo_root()
    halt_file = repo_root / '.orchestrator' / 'HALT'

    if not halt_file.exists():
        print("✓ No active HALT signal")
        return

    # HALT 내용 읽어서 issue URL 추출
    halt_data = yaml.safe_load(halt_file.read_text(encoding='utf-8'))
    issue_url = halt_data.get('github_issue', '')

    # HALT 파일 제거
    halt_file.unlink()
    subprocess.run(['git', '-C', str(repo_root), 'add', '-A',
                   str(halt_file.parent.relative_to(repo_root))])
    subprocess.run(['git', '-C', str(repo_root), 'commit', '-m',
                   'chore(orchestrator): HALT resolved — streams unblocked'])
    print(f"✓ HALT signal removed")

    # GitHub Issue close (있으면)
    if issue_url:
        issue_num = issue_url.rsplit('/', 1)[-1]
        subprocess.run(['gh', 'issue', 'close', issue_num,
                       '--comment', 'Resolved. HALT signal removed.'])
        print(f"✓ Issue #{issue_num} closed")

    print("\n✅ All streams can resume.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--severity', choices=['low', 'medium', 'high', 'critical'],
                        default='medium')
    parser.add_argument('--title', help='Defect title')
    parser.add_argument('--description', help='Detailed description')
    parser.add_argument('--reporter', help='Reporting stream (e.g., S1)')
    parser.add_argument('--resolve', action='store_true', help='Mark resolved + remove HALT')
    args = parser.parse_args()

    if args.resolve:
        resolve()
    elif args.title:
        report(args.severity, args.title, args.description, args.reporter)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
