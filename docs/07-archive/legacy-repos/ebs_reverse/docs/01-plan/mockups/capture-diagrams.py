"""Playwright script to capture individual diagram sections as PNG."""
import sys
from pathlib import Path
from playwright.sync_api import sync_playwright

DIAGRAM_NAMES = [
    "diagram-01-phase-roadmap",
    "diagram-02-system-concept",
    "diagram-03-app-ecosystem",
    "diagram-04-broadcast-prep",
    "diagram-05-hand-sequence",
    "diagram-06-broadcast-end",
    "diagram-07-error-recovery",
    "diagram-08-screen-map",
    "diagram-09-game-distribution",
    "diagram-10-antenna-layout",
    "diagram-11-card-registration",
    "diagram-12-security-mode",
    "diagram-13-priority-grid",
    "diagram-14-roadmap-dependency",
    "diagram-15-viewer-journey",
]

def main():
    script_dir = Path(__file__).parent
    html_path = script_dir / "clone-prd-diagrams.html"
    output_dir = script_dir.parent / "images"
    output_dir.mkdir(exist_ok=True)

    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page(viewport={"width": 1000, "height": 800})
        page.goto(f"file:///{html_path.as_posix()}")
        page.wait_for_load_state("networkidle")

        sections = page.locator(".diagram-section").all()
        print(f"Found {len(sections)} diagram sections")

        for i, section in enumerate(sections):
            name = DIAGRAM_NAMES[i] if i < len(DIAGRAM_NAMES) else f"diagram-{i+1:02d}"
            out_path = output_dir / f"{name}.png"
            section.screenshot(path=str(out_path), scale="device")
            print(f"  Captured: {name}.png")

        browser.close()
        print(f"\nDone! {len(sections)} diagrams -> {output_dir}")

if __name__ == "__main__":
    main()
