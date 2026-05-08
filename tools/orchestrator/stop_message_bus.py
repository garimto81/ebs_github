#!/usr/bin/env python3
"""Graceful shutdown for EBS Message Bus broker.

Reads .claude/locks/broker.pid, sends SIGTERM (or terminate on Windows),
waits for clean exit (max 10s), force-kills if needed.

Usage:
  python tools/orchestrator/stop_message_bus.py
  python tools/orchestrator/stop_message_bus.py --force   # immediate kill
"""
from __future__ import annotations

import argparse
import os
import signal
import subprocess
import sys
import time
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
PID_FILE = PROJECT_ROOT / ".claude" / "locks" / "broker.pid"


def _read_pid() -> int | None:
    if not PID_FILE.exists():
        return None
    try:
        return int(PID_FILE.read_text().strip())
    except (ValueError, OSError):
        return None


def _terminate(pid: int) -> bool:
    try:
        if sys.platform == "win32":
            # taskkill /PID
            r = subprocess.run(
                ["taskkill", "/PID", str(pid), "/T"],
                capture_output=True, text=True, timeout=5,
            )
            return r.returncode == 0
        else:
            os.kill(pid, signal.SIGTERM)
            return True
    except Exception as e:
        print(f"[stop] terminate failed: {e}")
        return False


def _force_kill(pid: int) -> bool:
    try:
        if sys.platform == "win32":
            r = subprocess.run(
                ["taskkill", "/F", "/PID", str(pid), "/T"],
                capture_output=True, text=True, timeout=5,
            )
            return r.returncode == 0
        else:
            os.kill(pid, signal.SIGKILL)
            return True
    except Exception as e:
        print(f"[stop] force kill failed: {e}")
        return False


def _is_alive(pid: int) -> bool:
    try:
        if sys.platform == "win32":
            r = subprocess.run(
                ["tasklist", "/FI", f"PID eq {pid}", "/NH", "/FO", "CSV"],
                capture_output=True, text=True, timeout=5,
            )
            return str(pid) in r.stdout
        else:
            os.kill(pid, 0)
            return True
    except Exception:
        return False


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--force", action="store_true", help="immediate force kill")
    p.add_argument("--timeout", type=float, default=10.0, help="graceful wait sec")
    args = p.parse_args()

    pid = _read_pid()
    if not pid:
        print("[stop] no broker.pid found, nothing to stop")
        sys.exit(0)
    if not _is_alive(pid):
        print(f"[stop] PID {pid} not alive (stale .pid)")
        try:
            PID_FILE.unlink(missing_ok=True)
        except OSError:
            pass
        sys.exit(0)

    if args.force:
        if _force_kill(pid):
            print(f"[stop] force killed PID {pid}")
        sys.exit(0)

    print(f"[stop] sending terminate to PID {pid}")
    if not _terminate(pid):
        print("[stop] terminate failed, falling back to force kill")
        _force_kill(pid)
        sys.exit(0)

    # Wait for graceful exit
    deadline = time.time() + args.timeout
    while time.time() < deadline:
        if not _is_alive(pid):
            print(f"[stop] PID {pid} exited gracefully")
            sys.exit(0)
        time.sleep(0.5)

    print(f"[stop] timed out after {args.timeout}s, force killing")
    _force_kill(pid)


if __name__ == "__main__":
    main()
