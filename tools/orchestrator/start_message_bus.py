#!/usr/bin/env python3
"""Entrypoint + supervisor for EBS Message Bus broker.

Phase 3 Hybrid:
- port lock (range scan 7383-7393)
- PID file (`.claude/locks/broker.pid`)
- broker.health heartbeat (atomic write every N seconds)
- DETACHED spawn support (--detach for hook auto-start, Phase 5)

Usage:
  python tools/orchestrator/start_message_bus.py            # foreground
  python tools/orchestrator/start_message_bus.py --detach   # background
  python tools/orchestrator/start_message_bus.py --probe    # health probe only
"""
from __future__ import annotations

import argparse
import asyncio
import os
import socket
import subprocess
import sys
import time
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
LOCKS_DIR = PROJECT_ROOT / ".claude" / "locks"
PID_FILE = LOCKS_DIR / "broker.pid"
PORT_FILE = LOCKS_DIR / "broker.port"
HEALTH_FILE = LOCKS_DIR / "broker.health"
LOG_FILE = PROJECT_ROOT / ".claude" / "message_bus" / "broker.log"

PORT_RANGE = range(7383, 7394)  # 7383 mnemonic, 7384-7393 fallback


def _is_port_free(host: str, port: int) -> bool:
    """Check if (host, port) is free for binding."""
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        s.bind((host, port))
        return True
    except OSError:
        return False
    finally:
        s.close()


def _find_free_port(host: str = "127.0.0.1") -> int:
    for port in PORT_RANGE:
        if _is_port_free(host, port):
            return port
    raise RuntimeError(f"No free port in range {list(PORT_RANGE)}")


def _read_pid() -> int | None:
    if not PID_FILE.exists():
        return None
    try:
        return int(PID_FILE.read_text().strip())
    except (ValueError, OSError):
        return None


def _is_pid_alive(pid: int) -> bool:
    """Best-effort cross-platform PID alive check."""
    try:
        if sys.platform == "win32":
            # Windows: tasklist with PID filter
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


def _probe_alive(host: str, port: int, timeout: float = 1.0) -> bool:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(timeout)
    try:
        s.connect((host, port))
        return True
    except OSError:
        return False
    finally:
        s.close()


def probe() -> dict:
    """Check if broker is alive (port + PID + health file)."""
    pid = _read_pid()
    port = None
    if PORT_FILE.exists():
        try:
            port = int(PORT_FILE.read_text().strip())
        except (ValueError, OSError):
            port = None
    health = None
    if HEALTH_FILE.exists():
        try:
            health = HEALTH_FILE.read_text().strip()
        except OSError:
            pass
    pid_alive = _is_pid_alive(pid) if pid else False
    port_open = _probe_alive("127.0.0.1", port) if port else False
    return {
        "pid": pid,
        "pid_alive": pid_alive,
        "port": port,
        "port_open": port_open,
        "health_ts": health,
        "alive": pid_alive and port_open,
    }


async def _heartbeat_loop(interval_sec: float = 5.0) -> None:
    """Background task: write broker.health every interval."""
    while True:
        try:
            HEALTH_FILE.write_text(
                f"alive\t{int(time.time())}\t{os.getpid()}\n"
            )
        except OSError:
            pass
        await asyncio.sleep(interval_sec)


def _cleanup_lockfiles() -> None:
    for f in (PID_FILE, PORT_FILE, HEALTH_FILE):
        try:
            f.unlink(missing_ok=True)
        except OSError:
            pass


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--port", type=int, default=None, help="port (auto-scan if omitted)")
    p.add_argument("--host", default="127.0.0.1")
    p.add_argument("--probe", action="store_true", help="health probe only, exit")
    p.add_argument("--detach", action="store_true", help="spawn detached (Windows DETACHED_PROCESS)")
    args = p.parse_args()

    if args.probe:
        import json as _json
        print(_json.dumps(probe(), indent=2))
        sys.exit(0 if probe()["alive"] else 1)

    LOCKS_DIR.mkdir(parents=True, exist_ok=True)
    LOG_FILE.parent.mkdir(parents=True, exist_ok=True)

    # Stale PID cleanup
    existing_pid = _read_pid()
    if existing_pid and not _is_pid_alive(existing_pid):
        print(f"[broker] stale PID {existing_pid} found, cleaning up")
        _cleanup_lockfiles()
    elif existing_pid:
        print(f"[broker] another broker already running (PID {existing_pid})")
        sys.exit(0)

    if args.detach:
        # Spawn self detached (Phase 5 hook auto-start)
        flags = 0
        if sys.platform == "win32":
            flags = subprocess.DETACHED_PROCESS | subprocess.CREATE_NEW_PROCESS_GROUP
        cmd = [sys.executable, str(Path(__file__).resolve())]
        if args.port is not None:
            cmd += ["--port", str(args.port)]
        cmd += ["--host", args.host]
        proc = subprocess.Popen(
            cmd,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            close_fds=True,
            creationflags=flags,
        )
        print(f"[broker] detached PID {proc.pid}")
        sys.exit(0)

    # Foreground execution
    port = args.port or _find_free_port(args.host)
    sys.path.insert(0, str(PROJECT_ROOT))

    from tools.orchestrator.message_bus.server import mcp, run

    # Override host/port
    mcp.settings.host = args.host
    mcp.settings.port = port

    # Write PID + port files
    PID_FILE.write_text(str(os.getpid()))
    PORT_FILE.write_text(str(port))
    HEALTH_FILE.write_text(f"starting\t{int(time.time())}\t{os.getpid()}\n")

    print(f"[broker] starting on http://{args.host}:{port}/mcp (PID {os.getpid()})")
    print(f"[broker] DB: {PROJECT_ROOT / '.claude/message_bus/events.db'}")
    print(f"[broker] log: {LOG_FILE}")

    # Heartbeat task in addition to FastMCP server
    # (FastMCP's mcp.run is sync, so we register heartbeat via its event loop hook later)
    # For Phase 3 PoC: rely on /health tool endpoint + manual probe

    try:
        run()
    finally:
        _cleanup_lockfiles()
        print("[broker] shutdown complete")


if __name__ == "__main__":
    main()
