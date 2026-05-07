#!/usr/bin/env python3
"""
Setup a Stream worktree with all pre-configured files.

Phase 0 Step 6 of orchestrator skill.
Creates: git worktree + .team + CLAUDE.md + START_HERE.md + hooks + .vscode/

Usage:
  python setup_stream_worktree.py --stream=S2 --config=path/to/team_assignment.yaml
  python setup_stream_worktree.py --all --config=path/to/team_assignment.yaml
"""
import argparse
import json
import os
import shutil
import subprocess
import sys
from datetime import date
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.stderr.write("PyYAML required. pip install pyyaml\n")
    sys.exit(1)


SCRIPT_DIR = Path(__file__).resolve().parent
SKILL_DIR = SCRIPT_DIR.parent
HOOK_TEMPLATES = SKILL_DIR / "hook_templates"


def render_team_file(stream_id: str, config: dict, project_root: Path):
    """`.team` yaml 파일 내용 생성"""
    return {
        'team_id': stream_id,
        'team_name': config.get('name', stream_id),
        'team_role': config.get('role', ''),
        'worktree_path': str(config['worktree']).replace('\\', '/'),
        'branch': config.get('_branch', f'work/{stream_id.lower()}/init'),
        'absorbs_existing': config.get('absorbs_existing', []),
        'scope_owns': _collect_phase_scope(config, 'scope_owns'),
        'scope_read': _collect_phase_scope(config, 'scope_read'),
        'meta_files_blocked': config.get(
            'meta_files_blocked',
            ['CLAUDE.md', 'MEMORY.md', 'docs/orchestrator/team_assignment.yaml']
        ),
        'blocked_by': config.get('blocked_by', []),
        'blocks': config.get('blocks', []),
        'design_version': '10.3.0',
        'project_root': str(project_root).replace('\\', '/'),
    }


def _collect_phase_scope(config: dict, key: str):
    """phases.*.{key} 들을 합쳐 단일 list로"""
    result = []
    for phase_data in (config.get('phases') or {}).values():
        result.extend(phase_data.get(key, []))
    return list(dict.fromkeys(result))  # dedupe preserving order


def render_stream_claude_md(stream_id: str, config: dict):
    name = config.get('name', stream_id)
    scope_lines = "\n".join(f"  - {p}" for p in _collect_phase_scope(config, 'scope_owns'))
    return f"""# {name} ({stream_id}) Worktree

## 🎯 Your Identity
You are working as **{name}** in the multi-session orchestration.
Source of Truth: `.team` file in this worktree root.

## 🚫 Hard Boundaries
You CANNOT edit:
- Other streams' SCOPE
- Meta files: CLAUDE.md (root repo), MEMORY.md, team_assignment.yaml
- Files outside scope_owns

You CAN edit (only):
{scope_lines or '  (defined in .team scope_owns)'}

## ✅ Workflow
1. Session start → SessionStart hook auto-injects identity
2. Hook checks dependencies (blocked_by) automatically
3. PreToolUse hook blocks scope violations

## 📋 Reference
- Design SSOT: docs/orchestrator/Multi_Session_Design.md
- This Stream's identity: .team
- First action: type "작업 시작" to auto-create issue + draft PR
"""


def render_start_here(stream_id: str, config: dict, status: str = "READY", blocker: str = None):
    name = config.get('name', stream_id)
    scope_lines = "\n".join(f"  - {p}" for p in _collect_phase_scope(config, 'scope_owns'))

    if status == "BLOCKED" and blocker:
        status_block = f"""
## 🚫 Status: BLOCKED by {blocker}

This Stream is waiting for {blocker} PR to merge.
- PreToolUse hook blocks all Edit/Write
- VSCode다시 열기 시 자동 unblock 검사

다음 가능 액션:
  1. {blocker} 워크트리 보기
  2. gh pr list로 진행 상황 확인
"""
    else:
        status_block = f"""
## ✅ Status: READY

작업 시작 가능합니다.
"""

    return f"""# 🎯 You are in: {name} ({stream_id})

이 폴더는 멀티 세션 Stream 워크트리입니다.
Orchestrator가 Phase 0에서 모든 것을 미리 준비했습니다.
{status_block}
## ⚡ 즉시 시작
Claude Code 첫 입력에 다음 한 줄만:

  > 작업 시작

자동 진행:
  1. GitHub Issue 자동 생성 + 'status:in-progress' label
  2. Draft PR 자동 생성 + Issue link
  3. 작업 진입

## 📂 영역
✅ 작업 가능:
{scope_lines}

🚫 메타 파일 차단:
  - CLAUDE.md (root repo의 것)
  - MEMORY.md
  - team_assignment.yaml

## 🔗 의존성
{'🟢 의존성 없음 (즉시 작업 가능)' if not config.get('blocked_by') else '⏳ 차단 중: ' + ', '.join(config['blocked_by'])}

## 📋 참조
- 설계 SSOT: docs/orchestrator/Multi_Session_Design.md
- 내 영역 명세: .team (이 폴더 root)
"""


def render_vscode_settings():
    return {
        "files.exclude": {
            "**/.git": True,
            "**/__pycache__": True,
            "**/.pytest_cache": True
        },
        "files.watcherExclude": {
            "**/node_modules/**": True
        },
        "claude.contextFiles": [
            ".team",
            "START_HERE.md",
            "CLAUDE.md"
        ]
    }


def setup_stream(stream_id: str, config: dict, project_root: Path,
                 dry_run: bool = False):
    worktree_path = Path(config['worktree'])
    branch = f"work/{stream_id.lower()}/{date.today().isoformat()}-init"
    config['_branch'] = branch

    print(f"\n[{stream_id}] {config.get('name', '')}")
    print(f"  worktree: {worktree_path}")
    print(f"  branch:   {branch}")

    # Step 1. git worktree add
    if not dry_run:
        if worktree_path.exists():
            print(f"  ⚠ worktree already exists, skipping git worktree add")
        else:
            try:
                subprocess.run([
                    'git', '-C', str(project_root),
                    'worktree', 'add', str(worktree_path),
                    '-b', branch, 'main'
                ], check=True, capture_output=True, text=True)
                print(f"  ✓ git worktree created")
            except subprocess.CalledProcessError as e:
                print(f"  ✗ git worktree failed: {e.stderr}")
                return False

    # Step 2. .team 파일
    team_data = render_team_file(stream_id, config, project_root)
    if not dry_run:
        (worktree_path / '.team').write_text(
            yaml.safe_dump(team_data, allow_unicode=True, sort_keys=False),
            encoding='utf-8'
        )
    print(f"  ✓ .team")

    # Step 3. CLAUDE.md (override)
    if not dry_run:
        (worktree_path / 'CLAUDE.md').write_text(
            render_stream_claude_md(stream_id, config),
            encoding='utf-8'
        )
    print(f"  ✓ CLAUDE.md")

    # Step 4. START_HERE.md
    blocker = config['blocked_by'][0] if config.get('blocked_by') else None
    status = "BLOCKED" if blocker else "READY"
    if not dry_run:
        (worktree_path / 'START_HERE.md').write_text(
            render_start_here(stream_id, config, status, blocker),
            encoding='utf-8'
        )
    print(f"  ✓ START_HERE.md ({status})")

    # Step 5. .claude/hooks/
    if not dry_run:
        hooks_dir = worktree_path / '.claude' / 'hooks'
        hooks_dir.mkdir(parents=True, exist_ok=True)
        for hook_name in ['SessionStart.py', 'PreToolUse.py']:
            src = HOOK_TEMPLATES / hook_name
            dst = hooks_dir / hook_name
            if src.exists():
                shutil.copy2(src, dst)
        # settings.local.json: hooks 활성화
        settings = {
            "hooks": {
                "SessionStart": [{"command": f"python .claude/hooks/SessionStart.py"}],
                "PreToolUse": [{"command": f"python .claude/hooks/PreToolUse.py"}]
            }
        }
        (worktree_path / '.claude' / 'settings.local.json').write_text(
            json.dumps(settings, indent=2), encoding='utf-8'
        )
    print(f"  ✓ .claude/hooks + settings.local.json")

    # Step 6. .vscode/settings.json
    if not dry_run:
        vscode_dir = worktree_path / '.vscode'
        vscode_dir.mkdir(exist_ok=True)
        (vscode_dir / 'settings.json').write_text(
            json.dumps(render_vscode_settings(), indent=2), encoding='utf-8'
        )
    print(f"  ✓ .vscode/settings.json")

    return True


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--stream', help='Single stream ID (e.g., S2)')
    parser.add_argument('--all', action='store_true', help='Setup all streams')
    parser.add_argument('--config', required=True, help='team_assignment.yaml path')
    parser.add_argument('--project-root', help='project root (default: cwd)')
    parser.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()

    config_path = Path(args.config).resolve()
    if not config_path.exists():
        sys.stderr.write(f"Config not found: {config_path}\n")
        sys.exit(1)

    config = yaml.safe_load(config_path.read_text(encoding='utf-8'))
    project_root = Path(args.project_root or os.getcwd()).resolve()

    streams = config.get('streams', {})
    if args.stream:
        targets = {args.stream: streams[args.stream]}
    else:
        targets = streams

    success = 0
    failed = []
    for sid, sconfig in targets.items():
        if setup_stream(sid, sconfig, project_root, args.dry_run):
            success += 1
        else:
            failed.append(sid)

    print(f"\n{'='*60}")
    print(f"Setup complete: {success}/{len(targets)} streams")
    if failed:
        print(f"Failed: {', '.join(failed)}")
        sys.exit(1)


if __name__ == "__main__":
    main()
