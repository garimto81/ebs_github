"""
capture_clean.py — Badge-free annotation capture using Playwright.

Opens existing annotated HTML files, hides badge text via CSS injection,
and captures the screenshot-container element only.

Output: captures/at-{XX}-clean-annotated.png
"""

import os
from pathlib import Path
from playwright.sync_api import sync_playwright

BASE_DIR = Path(__file__).resolve().parent
HTML_DIR = BASE_DIR / "html_reproductions"
OUT_DIR = BASE_DIR / "captures"

# screen_id -> (html_filename, width, height, extra_css)
SCREENS = {
    "at-01": (
        "at-01-setup-mode-annotated.html",
        786, 553,
        ".badge { display: none !important; }"
    ),
    "at-02": (
        "at-02-action-annotated.html",
        786, 553,
        ".badge { display: none !important; } "
        ".tab-bar { display: none !important; } "
        "body { padding-top: 0 !important; }"
    ),
    "at-03": (
        "at-03-card-selector-annotated.html",
        786, 460,
        ".badge { display: none !important; }"
    ),
    "at-05": (
        "at-05-statistics-register-annotated.html",
        786, 553,
        ".badge { display: none !important; }"
    ),
    "at-06": (
        "at-06-rfid-registration-annotated.html",
        786, 553,
        ".badge { display: none !important; }"
    ),
}


def main():
    OUT_DIR.mkdir(exist_ok=True)

    with sync_playwright() as p:
        browser = p.chromium.launch()

        for screen_id, (html_file, width, height, css) in SCREENS.items():
            html_path = HTML_DIR / html_file
            if not html_path.exists():
                print(f"[SKIP] {html_path} not found")
                continue

            # Use viewport slightly larger to avoid scroll bars
            page = browser.new_page(viewport={"width": width + 100, "height": height + 200})
            page.goto(html_path.as_uri())
            page.add_style_tag(content=css)
            page.wait_for_timeout(500)

            container = page.locator(".screenshot-container").first
            out_path = OUT_DIR / f"{screen_id}-clean-annotated.png"
            container.screenshot(path=str(out_path))

            print(f"[OK] {screen_id} -> {out_path.name} ({width}x{height})")
            page.close()

        browser.close()

    print(f"\nDone. {len(list(OUT_DIR.glob('*.png')))} files in {OUT_DIR}")


if __name__ == "__main__":
    main()
