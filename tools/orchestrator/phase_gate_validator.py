#!/usr/bin/env python3
"""
Phase gate validator — verifies changed files comply with active Phase's SCOPE.

Used by:
- CI workflow .github/workflows/phase_gate_check.yml
- Local audit before PR

Usage:
  python phase_gate_validator.py --stream=S2 --phase=P2 --files="a.md b.md" --config=...
  python phase_gate_validator.py --stream=S2 --phase=AUTO --files="..." --config=...
"""
import argparse
import sys
from fnmatch import fnmatch
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.stderr.write("PyYAML required\n")
    sys.exit(1)


def matches_glob(file_path, pattern):
    """fnmatch with ** support"""
    if '**' in pattern:
        base = pattern.rsplit('/**', 1)[0]
        return file_path == base or file_path.startswith(base + '/')
    return fnmatch(file_path, pattern)


def validate(config, stream, phase, files):
    streams = config.get('streams', {})
    if stream not in streams:
        return False, [f"Unknown stream: {stream}"]

    stream_cfg = streams[stream]
    phases = stream_cfg.get('phases', {})

    if phase == 'AUTO':
        # union of all phases' scope_owns
        allowed = []
        for p in phases.values():
            allowed.extend(p.get('scope_owns', []))
        blocked = []
        phase_label = ', '.join(phases.keys())
    else:
        if phase not in phases:
            return False, [f"Unknown phase {phase} in stream {stream}"]
        phase_cfg = phases[phase]
        allowed = phase_cfg.get('scope_owns', [])
        blocked = phase_cfg.get('blocked', [])
        phase_label = phase

    violations = []
    for f in files:
        # blocked check
        if any(matches_glob(f, pat) for pat in blocked):
            violations.append(f"{f}: BLOCKED in phase {phase}")
            continue
        # must match allowed
        if not any(matches_glob(f, pat) for pat in allowed):
            violations.append(f"{f}: outside scope (phase={phase_label})")

    return (len(violations) == 0), violations


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--stream', required=True)
    parser.add_argument('--phase', default='AUTO')
    parser.add_argument('--files', required=True, help='Space- or comma-separated')
    parser.add_argument('--config', required=True)
    args = parser.parse_args()

    config = yaml.safe_load(Path(args.config).read_text(encoding='utf-8'))
    files = [f.strip() for f in args.files.replace(',', ' ').split() if f.strip()]

    if not files:
        print("✓ No files to check")
        return

    ok, violations = validate(config, args.stream, args.phase, files)

    if ok:
        print(f"✓ {args.stream}/{args.phase} scope OK ({len(files)} files)")
    else:
        print(f"✗ {args.stream}/{args.phase} violations:")
        for v in violations:
            print(f"  - {v}")
        sys.exit(1)


if __name__ == "__main__":
    main()
