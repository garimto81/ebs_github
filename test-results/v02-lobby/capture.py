"""Cycle 6 evidence capture — S2 Lobby multi-hand auto_demo (Issue #312).

Captures 6 screenshots aligned with the multi-hand HandAutoSetupStep machine:

  01-idle          → pending             (demo overlay rendered, before run() kicks off)
  02-hand1-dealt   → cascadeReady        (Hand 1 dealt, dealer=seat 1, pot=0)
  03-hand1-complete → hand1Complete       (Hand 1 done, pot=240, winner seat 1)
  04-next-hand-pressed → nextHandRotating (ManualNextHand dispatched)
  05-hand2-dealt   → hand2Dealt          (Hand 2, dealer rotated to seat 2)
  06-history-visible → hand2Dealt (sustained, handHistory panel visible)

Runs against the HAND_AUTO_SETUP=true build served at $LOBBY_URL.
Default: http://localhost:3000 (assumes a build with HAND_AUTO_SETUP=true is
served there — see test-results/v02-lobby/README.md for build commands).

Usage:
    python test-results/v02-lobby/capture.py
"""

from __future__ import annotations

import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

try:
    from playwright.sync_api import sync_playwright
except ImportError:
    sys.stderr.write(
        "playwright not installed. Run: "
        "pip install playwright && playwright install chromium\n"
    )
    sys.exit(1)

OUT_DIR = Path(__file__).resolve().parent
LOBBY_URL = os.environ.get("LOBBY_URL", "http://localhost:3000")

# Timing aligned to HandAutoSetupNotifier.run() in
# team1-frontend/lib/features/lobby/providers/hand_auto_setup_provider.dart.
# Each Future.delayed = 100-200 ms; we wait generously to cross boundaries.
STAGE_PLAN = [
    ("01-idle", 50, "pending — overlay rendered, run() not yet kicked"),
    ("02-hand1-dealt", 800, "cascadeReady — Hand 1 dealt, dealer=seat 1"),
    ("03-hand1-complete", 1200, "hand1Complete — pot=240, winner seat 1"),
    ("04-next-hand-pressed", 1450, "nextHandRotating — POST /next-hand"),
    ("05-hand2-dealt", 1750, "hand2Dealt — dealer rotated 1->2, pot reset"),
    ("06-history-visible", 2500, "hand2Dealt sustained — history panel visible"),
]


def shot(page, label: str, description: str) -> tuple[str, int]:
    file = OUT_DIR / f"{label}.png"
    page.screenshot(path=str(file), full_page=False)
    size = file.stat().st_size
    print(f"[shot] {label} ({size} bytes) - {description}")
    return str(file), size


def main() -> int:
    evidence = {
        "stream": "S2",
        "cycle": 6,
        "issue": 312,
        "build": "v02-lobby",
        "captured_at": datetime.now(timezone.utc).isoformat(),
        "lobby_url": LOBBY_URL,
        "stages": [],
        "console_log": [],
        "network_log": [],
        "result": "UNKNOWN",
    }

    with sync_playwright() as p:
        browser = p.chromium.launch(
            headless=True, args=["--disable-web-security"]
        )
        ctx = browser.new_context(
            viewport={"width": 1440, "height": 900},
            user_agent="Mozilla/5.0 EBS-S2-Cycle6-Capture",
        )
        page = ctx.new_page()

        def on_console(msg):
            evidence["console_log"].append(
                {
                    "ts": datetime.now(timezone.utc).isoformat(),
                    "type": msg.type,
                    "text": (msg.text or "")[:300],
                }
            )

        def on_response(resp):
            url = resp.url
            if "/api/" in url or "/ws" in url:
                evidence["network_log"].append(
                    {
                        "ts": datetime.now(timezone.utc).isoformat(),
                        "status": resp.status,
                        "url": url[:200],
                    }
                )

        page.on("console", on_console)
        page.on("response", on_response)

        try:
            page.goto(LOBBY_URL, wait_until="domcontentloaded", timeout=30000)
            # Give Flutter Web canvas a moment to render initial frame.
            page.wait_for_timeout(700)

            start_ms = 0
            for label, target_ms, description in STAGE_PLAN:
                delta = target_ms - start_ms
                if delta > 0:
                    page.wait_for_timeout(delta)
                    start_ms = target_ms
                file_path, size = shot(page, label, description)
                evidence["stages"].append(
                    {
                        "step": label,
                        "target_ms": target_ms,
                        "description": description,
                        "ts": datetime.now(timezone.utc).isoformat(),
                        "file": Path(file_path).name,
                        "bytes": size,
                    }
                )

            evidence["result"] = "SUCCESS"
        except Exception as e:
            evidence["result"] = "PARTIAL"
            evidence["error"] = f"{type(e).__name__}: {e}"
            print(f"[capture] error: {e}")
        finally:
            (OUT_DIR / "evidence.json").write_text(
                json.dumps(evidence, indent=2, ensure_ascii=False),
                encoding="utf-8",
            )
            print(
                f"[capture] evidence.json saved "
                f"({len(evidence['stages'])} stages, "
                f"{len(evidence['console_log'])} console events, "
                f"{len(evidence['network_log'])} API calls, "
                f"result={evidence['result']})"
            )
            browser.close()

    return 0 if evidence["result"] == "SUCCESS" else 1


if __name__ == "__main__":
    sys.exit(main())
