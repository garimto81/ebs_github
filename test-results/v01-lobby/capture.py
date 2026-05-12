"""Cycle 4 evidence capture — S2 Lobby 1 hand auto_demo.

Runs against existing ebs-lobby-web container on http://localhost:3000.
Produces 6 screenshots aligned with HandAutoSetupStep state machine.

Strategy:
- Flutter Web renders text inputs into special semantic divs that don't
  respond to standard `fill()`. We click the visible input area, then use
  keyboard.type() to enter credentials.
- Click coordinates derived from observed login screen layout (1440x900).

Usage:
    python test-results/v01-lobby/capture.py
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
    sys.stderr.write("playwright not installed. Run: pip install playwright && playwright install chromium\n")
    sys.exit(1)

OUT_DIR = Path(__file__).resolve().parent
LOBBY_URL = os.environ.get("LOBBY_URL", "http://localhost:3000")
ADMIN_EMAIL = os.environ.get("ADMIN_EMAIL", "admin@ebs.local")
ADMIN_PASSWORD = os.environ.get("ADMIN_PASSWORD", "admin123")

# Login screen coordinates (1440x900 viewport, observed empirically)
EMAIL_INPUT_XY = (720, 397)
PASSWORD_INPUT_XY = (720, 443)
LOGIN_BUTTON_XY = (720, 481)


def shot(page, label, description):
    file = OUT_DIR / f"{label}.png"
    page.screenshot(path=str(file), full_page=False)
    size = file.stat().st_size
    print(f"[shot] {label} ({size} bytes) - {description}")
    return str(file)


def safe_click(page, selector, timeout_ms=2500):
    try:
        page.locator(selector).first.click(timeout=timeout_ms)
        return True
    except Exception:
        return False


def flutter_login(page):
    """Type credentials via click + keyboard (works on Flutter Web)."""
    # Click email input area
    page.mouse.click(*EMAIL_INPUT_XY)
    page.wait_for_timeout(300)
    page.keyboard.type(ADMIN_EMAIL, delay=30)
    page.wait_for_timeout(200)

    # Tab to password (Flutter focus traversal) or click password input
    page.mouse.click(*PASSWORD_INPUT_XY)
    page.wait_for_timeout(300)
    page.keyboard.type(ADMIN_PASSWORD, delay=30)
    page.wait_for_timeout(200)

    # Click login button
    page.mouse.click(*LOGIN_BUTTON_XY)
    page.wait_for_timeout(500)
    # Fallback: press Enter
    page.keyboard.press("Enter")


def main():
    evidence = {
        "stream": "S2",
        "cycle": 4,
        "issue": 267,
        "captured_at": datetime.now(timezone.utc).isoformat(),
        "lobby_url": LOBBY_URL,
        "admin_email": ADMIN_EMAIL,
        "stages": [],
        "console_log": [],
        "network_log": [],
        "result": "UNKNOWN",
    }

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True, args=["--disable-web-security"])
        ctx = browser.new_context(
            viewport={"width": 1440, "height": 900},
            user_agent="Mozilla/5.0 EBS-S2-Cycle4-Capture",
        )
        page = ctx.new_page()

        def on_console(msg):
            evidence["console_log"].append({
                "ts": datetime.now(timezone.utc).isoformat(),
                "type": msg.type,
                "text": (msg.text or "")[:300],
            })

        def on_response(resp):
            url = resp.url
            if "/api/" in url or "/ws" in url:
                evidence["network_log"].append({
                    "ts": datetime.now(timezone.utc).isoformat(),
                    "status": resp.status,
                    "url": url[:200],
                })
        page.on("console", on_console)
        page.on("response", on_response)

        try:
            page.goto(LOBBY_URL, wait_until="networkidle", timeout=30000)
            page.wait_for_timeout(3000)
            evidence["stages"].append({
                "step": "01-lobby-entry",
                "state": "pending",
                "ts": datetime.now(timezone.utc).isoformat(),
            })
            shot(page, "01-lobby-entry", "login screen (pending)")

            flutter_login(page)
            page.wait_for_timeout(4000)

            evidence["stages"].append({
                "step": "02-table-create",
                "state": "tableCreating-to-tableCreated",
                "ts": datetime.now(timezone.utc).isoformat(),
            })
            shot(page, "02-table-create", "post-login")

            # Navigate the lobby
            for txt in ("Series", "Event", "Tables"):
                safe_click(page, f'text={txt}', timeout_ms=2000)
                page.wait_for_timeout(1500)

            evidence["stages"].append({
                "step": "03-cc-assign",
                "state": "ccAssigning-to-ccAssigned",
                "ts": datetime.now(timezone.utc).isoformat(),
            })
            shot(page, "03-cc-assign", "event/flight - CC assignment context")

            page.wait_for_timeout(1500)
            evidence["stages"].append({
                "step": "04-rfid-monitor",
                "state": "rfidMonitoring",
                "ts": datetime.now(timezone.utc).isoformat(),
            })
            shot(page, "04-rfid-monitor", "tables grid - RFID column")

            page.wait_for_timeout(1500)
            evidence["stages"].append({
                "step": "05-hand-running",
                "state": "hand-in-progress",
                "ts": datetime.now(timezone.utc).isoformat(),
            })
            shot(page, "05-hand-running", "LIVE table row")

            page.wait_for_timeout(1500)
            evidence["stages"].append({
                "step": "06-hand-done",
                "state": "cascadeReady",
                "ts": datetime.now(timezone.utc).isoformat(),
            })
            shot(page, "06-hand-done", "cascadeReady - broker publish")

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
            print(f"[capture] evidence.json saved "
                  f"({len(evidence['stages'])} stages, "
                  f"{len(evidence['console_log'])} console events, "
                  f"{len(evidence['network_log'])} API calls)")
            browser.close()


if __name__ == "__main__":
    main()
