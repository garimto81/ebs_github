"""
capture_v4.py — v4 HTML mockup → PNG capture using Playwright.

Captures #q-app element from each HTML file.
Output: docs/mockups/v4/*.png (same directory as HTML files)
"""

import os
from pathlib import Path
from playwright.sync_api import sync_playwright

BASE_DIR = Path(__file__).resolve().parent

# (html_filename, viewport_width, viewport_height)
SCREENS = {
    "ebs-at-login":        ("ebs-at-login.html",        820, 600),
    "ebs-at-main-layout":  ("ebs-at-main-layout.html",  820, 900),
    "ebs-at-full-layout":  ("ebs-at-full-layout.html",  1060, 900),
    "ebs-at-card-selector": ("ebs-at-card-selector.html", 820, 700),
    "ebs-at-stats-panel":  ("ebs-at-stats-panel.html",  820, 800),
    "ebs-at-rfid-register": ("ebs-at-rfid-register.html", 820, 700),
    "ebs-at-settings-view": ("ebs-at-settings-view.html", 820, 900),
    "ebs-at-player-edit":  ("ebs-at-player-edit.html",  820, 600),
    "ebs-at-seat-cell":    ("ebs-at-seat-cell.html",    700, 600),
    "ebs-action-tracker":  ("ebs-action-tracker.html",  1060, 900),
}


def main():
    with sync_playwright() as p:
        browser = p.chromium.launch()

        for screen_id, (html_file, vw, vh) in SCREENS.items():
            html_path = BASE_DIR / html_file
            if not html_path.exists():
                print(f"[SKIP] {html_path} not found")
                continue

            page = browser.new_page(viewport={"width": vw, "height": vh})
            page.goto(html_path.as_uri())
            page.wait_for_timeout(1000)  # wait for Quasar CDN + fonts

            container = page.locator("#q-app").first
            out_path = BASE_DIR / f"{screen_id}.png"
            container.screenshot(path=str(out_path))

            print(f"[OK] {screen_id}.png")
            page.close()

        browser.close()

    png_count = len(list(BASE_DIR.glob("*.png")))
    print(f"\nDone. {png_count} PNG files in {BASE_DIR}")


if __name__ == "__main__":
    main()
