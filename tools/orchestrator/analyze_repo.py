#!/usr/bin/env python3
"""
Phase -1: 프로젝트 자동 분석 (Stream 매트릭스 추론용).

자동 감지:
- git 레포 root
- 기술 스택 (package.json, pyproject.toml, pubspec.yaml, etc.)
- 기존 폴더 (frontend/, backend/, team*-*/, apps/*, packages/*)
- docs/, tests/, integration-tests/
- 기존 team_assignment.yaml (있으면 추론 스킵)

Usage:
  python analyze_repo.py --root=<project-root>
  python analyze_repo.py  # cwd 사용
"""
import argparse
import json
import os
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    yaml = None


TECH_MARKERS = {
    'package.json':      'node',
    'pyproject.toml':    'python',
    'requirements.txt':  'python',
    'pubspec.yaml':      'flutter',
    'Cargo.toml':        'rust',
    'go.mod':            'go',
    'pom.xml':           'java',
    'build.gradle':      'java',
    'Gemfile':           'ruby',
    'composer.json':     'php',
}

FOLDER_TO_STREAM = {
    'frontend':         'Frontend Stream',
    'backend':          'Backend Stream',
    'mobile':           'Mobile Stream',
    'web':              'Web Stream',
    'api':              'API Stream',
    'shared':           'Shared Stream',
    'common':           'Common Stream',
    'core':             'Core Stream',
    # EBS
    'team1-frontend':   'Frontend Stream',
    'team2-backend':    'Backend Stream',
    'team3-engine':     'Engine Stream',
    'team4-cc':         'Command Center Stream',
}

DOC_FOLDERS = ['docs', 'documentation', 'doc']
TEST_FOLDERS = ['integration-tests', 'e2e', 'tests', 'test', '__tests__']


def detect_tech_stack(root: Path):
    found = []
    for marker, tech in TECH_MARKERS.items():
        if (root / marker).exists():
            found.append(tech)
    return found or ['unknown']


def detect_folders(root: Path):
    folders = {}
    for entry in root.iterdir():
        if entry.is_dir() and not entry.name.startswith('.'):
            folders[entry.name] = entry
    return folders


def detect_monorepo(root: Path):
    """apps/* + packages/* 패턴"""
    apps = root / 'apps'
    packages = root / 'packages'
    if apps.is_dir() or packages.is_dir():
        return {
            'apps': [p.name for p in apps.iterdir() if p.is_dir()] if apps.exists() else [],
            'packages': [p.name for p in packages.iterdir() if p.is_dir()] if packages.exists() else [],
        }
    return None


def check_existing_orchestrator(root: Path):
    """기존 team_assignment.yaml 있는지"""
    for path in [
        root / 'docs' / 'orchestrator' / 'team_assignment.yaml',
        root / 'docs' / '4. Operations' / 'team_assignment.yaml',
        root / 'docs' / '4. Operations' / 'team_assignment_v10_3.yaml',
    ]:
        if path.exists():
            return str(path)
    return None


def infer_streams(folders, docs_present, tests_present, monorepo):
    streams = {}
    sid = 1

    # S1 Foundation (PRD 폴더 없거나 분산 시)
    if not docs_present:
        streams[f'S{sid}'] = {
            'name': 'Foundation',
            'role': 'PRD + Architecture docs',
            'absorbs_existing': [],
            'inferred_phase': 'P1',
            'blocked_by': [],
        }
        sid += 1

    if monorepo:
        for app in monorepo['apps']:
            streams[f'S{sid}'] = {
                'name': f'{app.title()} App',
                'absorbs_existing': [f'apps/{app}'],
                'inferred_phase': 'P2',
                'blocked_by': ['S1'] if 'S1' in streams else [],
            }
            sid += 1
        for pkg in monorepo['packages']:
            streams[f'S{sid}'] = {
                'name': f'{pkg.title()} Package',
                'absorbs_existing': [f'packages/{pkg}'],
                'inferred_phase': 'P2',
                'blocked_by': ['S1'] if 'S1' in streams else [],
            }
            sid += 1
    else:
        for fname, fpath in folders.items():
            if fname in FOLDER_TO_STREAM:
                streams[f'S{sid}'] = {
                    'name': FOLDER_TO_STREAM[fname],
                    'absorbs_existing': [fname],
                    'inferred_phase': 'P2',
                    'blocked_by': ['S1'] if 'S1' in streams else [],
                }
                sid += 1

    if tests_present:
        all_existing = list(streams.keys())
        streams[f'S{sid}'] = {
            'name': 'Integration Test Stream',
            'absorbs_existing': [tests_present],
            'inferred_phase': 'P4',
            'blocked_by': all_existing,
        }

    return streams


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--root', default='.')
    parser.add_argument('--output', choices=['json', 'yaml', 'human'], default='human')
    args = parser.parse_args()

    root = Path(args.root).resolve()

    existing = check_existing_orchestrator(root)
    if existing:
        result = {
            'status': 'existing_orchestrator_found',
            'path': existing,
            'recommendation': 'Use existing matrix, skip auto-inference'
        }
    else:
        tech = detect_tech_stack(root)
        folders = detect_folders(root)
        docs = next((d for d in DOC_FOLDERS if (root / d).is_dir()), None)
        tests = next((t for t in TEST_FOLDERS if (root / t).is_dir()), None)
        monorepo = detect_monorepo(root)
        streams = infer_streams(folders, docs, tests, monorepo)
        result = {
            'status': 'inferred',
            'project_root': str(root),
            'project_name': root.name,
            'tech_stack': tech,
            'top_folders': list(folders.keys()),
            'docs_folder': docs,
            'tests_folder': tests,
            'monorepo': monorepo,
            'inferred_streams': streams,
        }

    if args.output == 'json':
        print(json.dumps(result, indent=2, ensure_ascii=False))
    elif args.output == 'yaml' and yaml:
        print(yaml.safe_dump(result, allow_unicode=True, sort_keys=False))
    else:
        print(f"📂 Project: {result.get('project_name', 'unknown')}")
        print(f"   Tech: {', '.join(result.get('tech_stack', []))}")
        if result['status'] == 'existing_orchestrator_found':
            print(f"   ✓ Existing orchestrator: {result['path']}")
        else:
            print(f"   Folders: {', '.join(result.get('top_folders', []))}")
            print(f"\n💡 Inferred Streams:")
            for sid, s in result['inferred_streams'].items():
                absorbs = ', '.join(s.get('absorbs_existing', [])) or '(new)'
                print(f"   {sid:<4} {s['name']:<30} ← {absorbs}")


if __name__ == "__main__":
    main()
