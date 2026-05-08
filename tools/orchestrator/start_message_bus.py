#!/usr/bin/env python3
"""Entrypoint: start the EBS Message Bus broker (FastMCP + SQLite WAL).

Phase 1 PoC: simple foreground start. Phase 3 will add supervisor / detached spawn.

Usage:
  python tools/orchestrator/start_message_bus.py
  python tools/orchestrator/start_message_bus.py --port 7383
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--port", type=int, default=7383)
    p.add_argument("--host", default="127.0.0.1")
    args = p.parse_args()

    # Ensure project root on sys.path for module imports
    project_root = Path(__file__).resolve().parents[2]
    sys.path.insert(0, str(project_root))

    from tools.orchestrator.message_bus.server import mcp, run

    # Override host/port from CLI
    mcp.settings.host = args.host
    mcp.settings.port = args.port

    print(f"[broker] starting EBS Message Bus on http://{args.host}:{args.port}/mcp")
    print(f"[broker] SQLite WAL at {project_root / '.claude/message_bus/events.db'}")
    print("[broker] Phase 1 PoC — long-poll subscribe (true notifications/* in MVP Phase 2)")
    run()


if __name__ == "__main__":
    main()
