#!/usr/bin/env python3
"""
Dynamic Stream activation — for user requests like "QA 추가" / "Backend 코드 시작".

Reads team_assignment.yaml `future_streams`, moves selected stream to `streams`,
runs setup_stream_worktree.py, then sync_design_to_github.py.

Usage:
  python dynamic_stream_activation.py --activate=S7 --config=...
  python dynamic_stream_activation.py --list --config=...
"""
import argparse
import subprocess
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.stderr.write("PyYAML required\n")
    sys.exit(1)


SCRIPT_DIR = Path(__file__).resolve().parent


def list_future(config_path):
    config = yaml.safe_load(Path(config_path).read_text(encoding='utf-8'))
    futures = config.get('future_streams', {})
    if not futures:
        print("(no future streams defined)")
        return
    print("📋 Future streams:")
    for sid, s in futures.items():
        print(f"  {sid:<6} {s.get('name', '?'):<30}")
        print(f"         absorbs: {s.get('absorbs_existing', [])}")
        print(f"         trigger: {s.get('activation_trigger', '-')}")


def activate(config_path, stream_id, project_root, dry_run):
    config_path = Path(config_path).resolve()
    config = yaml.safe_load(config_path.read_text(encoding='utf-8'))

    futures = config.get('future_streams', {})
    if stream_id not in futures:
        sys.stderr.write(f"⛔ {stream_id} not in future_streams\n")
        sys.exit(1)

    fut = futures.pop(stream_id)
    print(f"🔄 Activating {stream_id} ({fut.get('name', '')})")

    # Convert future → active schema
    absorbs = fut.get('absorbs_existing', [])
    active = {
        'name': fut['name'],
        'role': fut.get('role', fut['name']),
        'worktree': fut['worktree'],
        'absorbs_existing': absorbs,
        'phases': fut.get('phases') or {
            'P5': {'scope_owns': [f"{a}/**" for a in absorbs]} if absorbs
                  else {'P_DYNAMIC': {'scope_owns': []}}
        },
        'blocked_by': fut.get('inferred_blocked_by', []),
        'blocks': [],
        'meta_files_blocked': [
            'CLAUDE.md', 'MEMORY.md',
            'docs/orchestrator/team_assignment.yaml',
            'docs/4. Operations/team_assignment_v10_3.yaml',
        ],
    }
    config.setdefault('streams', {})[stream_id] = active

    # Bump version
    parts = config.get('version', '10.3.0').split('.')
    parts[-1] = str(int(parts[-1]) + 1)
    config['version'] = '.'.join(parts)

    if not dry_run:
        config_path.write_text(
            yaml.safe_dump(config, allow_unicode=True, sort_keys=False),
            encoding='utf-8'
        )
    print(f"  ✓ {config_path.name} → v{config['version']}")

    # Run setup_stream_worktree.py
    setup = _find_script('setup_stream_worktree.py', project_root)
    if dry_run:
        print(f"  [DRY] Would run: {setup}")
    else:
        r = subprocess.run([
            sys.executable, str(setup),
            '--stream', stream_id,
            '--config', str(config_path),
            '--project-root', str(project_root),
        ])
        if r.returncode != 0:
            sys.exit(1)

    # Run sync_design_to_github.py
    sync = _find_script('sync_design_to_github.py', project_root)
    if sync and not dry_run:
        subprocess.run([
            sys.executable, str(sync),
            '--config', str(config_path),
            '--project-root', str(project_root),
        ])

    print(f"\n✅ {stream_id} activated.")
    print(f"   Worktree: {active['worktree']}")
    print(f"   Open in VSCode: code \"{active['worktree']}\"")


def _find_script(name, project_root):
    """Look in: skill scripts/ → project tools/orchestrator/"""
    candidates = [
        SCRIPT_DIR / name,
        Path(project_root) / 'tools' / 'orchestrator' / name,
    ]
    for c in candidates:
        if c.exists():
            return c
    return None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--activate', help='Stream ID (e.g., S7)')
    parser.add_argument('--list', action='store_true')
    parser.add_argument('--config', required=True)
    parser.add_argument('--project-root', default='.')
    parser.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()

    if args.list:
        list_future(args.config)
    elif args.activate:
        activate(args.config, args.activate, args.project_root, args.dry_run)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
