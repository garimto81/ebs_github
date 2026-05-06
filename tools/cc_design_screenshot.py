"""
CC React Design Prototype Screenshot Capture (v2 — diagnostic + best-effort)
============================================================================
"""

from pathlib import Path
from playwright.sync_api import sync_playwright

REPO = Path("C:/claude/ebs")
HTML = REPO / "claude-design-archive" / "2026-05-06" / "cc-react-extracted" / "EBS Command Center.html"
OUT = REPO / "docs" / "images" / "cc-design-prototype"
OUT.mkdir(parents=True, exist_ok=True)

VIEWPORT = {"width": 1600, "height": 900}


def capture():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        ctx = browser.new_context(viewport=VIEWPORT, device_scale_factor=1.0)
        page = ctx.new_page()

        console_log = []
        request_failed = []
        page.on("console", lambda msg: console_log.append(f"[{msg.type}] {msg.text}"))
        page.on("requestfailed", lambda req: request_failed.append(
            f"{req.method} {req.url} -> {req.failure}"
        ))

        # HTTP server required (file:// blocks .jsx XHR fetches per CORS).
        url = "http://localhost:8765/EBS%20Command%20Center.html"
        print(f"Loading: {url}")
        page.goto(url, wait_until="domcontentloaded", timeout=20000)

        # Try to wait for #app, but tolerate failure.
        try:
            page.wait_for_selector("#app", timeout=15000)
            page.wait_for_timeout(2500)
            print("✅ #app rendered")
        except Exception as e:
            print(f"⚠️  #app not rendered within 15s — capturing anyway. {e}")
            page.wait_for_timeout(3000)

        # Always capture, even if React failed.
        out0 = OUT / "00-initial-load.png"
        page.screenshot(path=str(out0), full_page=False)
        print(f"[diag] initial -> {out0.name}")

        # DOM snapshot (helps diagnose CDN failure)
        body_html = page.evaluate("() => document.body.innerHTML.length")
        root_html = page.evaluate("() => (document.getElementById('root') || {}).innerHTML?.length || 0")
        print(f"body.innerHTML.length = {body_html}")
        print(f"#root.innerHTML.length = {root_html}")

        if root_html < 200:
            print("\n--- CONSOLE LOG ---")
            for line in console_log[:30]:
                print(line)
            print("\n--- REQUEST FAILED ---")
            for line in request_failed[:20]:
                print(line)
            print("\n→ React not initialized. Likely CDN blocked.")
            browser.close()
            return False

        # 1. IDLE
        out1 = OUT / "01-idle-full.png"
        page.screenshot(path=str(out1), full_page=False)
        print(f"[1/4] IDLE        -> {out1.name}")

        # Press N
        page.locator("body").click()
        page.keyboard.press("n")
        page.wait_for_timeout(1000)

        out2 = OUT / "02-pre-flop-face-down.png"
        page.screenshot(path=str(out2), full_page=False)
        print(f"[2/4] PRE_FLOP    -> {out2.name}")

        # 3. CardPicker
        try:
            first_hcard = page.locator(".pcol:not(.empty) .hcard").first
            first_hcard.click(timeout=3000)
            page.wait_for_timeout(700)
            out3 = OUT / "03-card-picker-D7-violation.png"
            page.screenshot(path=str(out3), full_page=False)
            print(f"[3/4] CardPicker  -> {out3.name}  (D7 위반 시각 증명)")
            page.keyboard.press("Escape")
            page.wait_for_timeout(400)
        except Exception as e:
            print(f"[3/4] CardPicker SKIP: {e}")

        # 4. FLOP board
        try:
            for i in range(3):
                slot = page.locator(".ts-slot").nth(i)
                slot.click(timeout=3000)
                page.wait_for_timeout(300)
                first_pick = page.locator(".cp-card").first
                first_pick.click(timeout=3000)
                page.wait_for_timeout(300)
            out4 = OUT / "04-flop-board.png"
            page.screenshot(path=str(out4), full_page=False)
            print(f"[4/4] FLOP board  -> {out4.name}")
        except Exception as e:
            print(f"[4/4] FLOP board SKIP: {e}")

        browser.close()
        return True


if __name__ == "__main__":
    ok = capture()
    print("\nDONE." if ok else "\nFAILED — see diagnostic above.")
    print("Files in:", OUT)
