"""
annotate_v4.py — Generate annotated HTML + PNG from v4 clean mockups.

1. Reads each clean HTML
2. Injects annotation CSS + JS (badge overlays by CSS selector)
3. Saves *-annotated.html
4. Captures *-annotated.png via Playwright
"""

from pathlib import Path
from playwright.sync_api import sync_playwright

BASE_DIR = Path(__file__).resolve().parent

# Category colors (matching AT-Annotation-Reference.md palette)
CAT_COLORS = {
    "header":           "#3498db",
    "input":            "#e67e22",
    "action":           "#c0392b",
    "status":           "#27ae60",
    "feedback":         "#e74c3c",
    "toolbar":          "#27ae60",
    "card_area":        "#f39c12",
    "card_icon":        "#f39c12",
    "card_grid":        "#f39c12",
    "seat":             "#e67e22",
    "seat_tab":         "#e67e22",
    "hand_control":     "#00bcd4",
    "blind":            "#795548",
    "game_settings":    "#607d8b",
    "option":           "#9c27b0",
    "chip_input":       "#ff5722",
    "action_panel":     "#c0392b",
    "action_button":    "#8e44ad",
    "community_cards":  "#f39c12",
    "info_bar":         "#00bcd4",
    "broadcast_control":"#607d8b",
    "table_header":     "#3498db",
    "table_data":       "#607d8b",
    "rfid":             "#9c27b0",
    "navigation":       "#4caf50",
    "chrome":           "#607d8b",
    "display":          "#3498db",
    "settings":         "#607d8b",
    "state":            "#3498db",
    "component":        "#00bcd4",
}

# Badge definitions per screen: (badge_label, css_selector, category)
SCREEN_BADGES = {
    "ebs-at-login": [
        ("LG-01", ".app-title",              "header"),
        ("LG-02", ".input-group:first-of-type", "input"),
        ("LG-03", ".input-group:last-of-type",  "input"),
        ("LG-04", ".login-btn",              "action"),
        ("LG-05", ".status-row",             "status"),
        ("LG-06", ".error-msg",              "feedback"),
    ],
    "ebs-at-main-layout": [
        ("M-01",  ".toolbar",                "toolbar"),
        ("M-02",  ".card-icon-row",          "card_area"),
        ("M-03",  ".seat-tab-row",           "seat_tab"),
        ("M-04",  ".ma-left",               "blind"),
        ("M-05",  ".ma-center",             "chip_input"),
        ("M-06",  ".ma-right",              "game_settings"),
        ("M-07",  ".straddle-row",           "option"),
    ],
    "ebs-at-full-layout": [
        ("FL-01", ".status-bar",             "toolbar"),
        ("FL-02", ".game-bar",               "hand_control"),
        ("FL-03", ".table-felt",             "seat"),
        ("FL-04", ".board-cards",            "community_cards"),
        ("FL-05", ".pot-display",            "info_bar"),
        ("FL-06", ".action-row",             "action_button"),
        ("FL-07", ".bet-row",                "action_panel"),
        ("FL-08", ".special-row",            "action_panel"),
    ],
    "ebs-at-card-selector": [
        ("CS-01", ".cs-header",              "chrome"),
        ("CS-02", ".cs-selected-area",       "display"),
        ("CS-03", ".suit-row:nth-child(1)",  "card_grid"),
        ("CS-04", ".suit-row:nth-child(2)",  "card_grid"),
        ("CS-05", ".suit-row:nth-child(3)",  "card_grid"),
        ("CS-06", ".suit-row:nth-child(4)",  "card_grid"),
    ],
    "ebs-at-stats-panel": [
        ("SP-01", ".panel-header",           "header"),
        ("SP-02", ".stats-table",            "table_data"),
        ("SP-03", ".side-panel",             "broadcast_control"),
        ("SP-04", ".panel-footer",           "action"),
    ],
    "ebs-at-rfid-register": [
        ("RR-01", ".instr-box",              "rfid"),
        ("RR-02", ".big-card",               "rfid"),
        ("RR-03", ".progress-section",       "rfid"),
        ("RR-04", ".cancel-btn",             "action"),
    ],
    "ebs-at-settings-view": [
        ("SV-01", ".at-toolbar",             "toolbar"),
        ("SV-02", ".seat-straddle-block",    "seat"),
        ("SV-03", ".card-status-row",        "card_area"),
        ("SV-04", ".settings-scroll",        "settings"),
        ("SV-05", ".bottom-actions",         "action"),
    ],
    "ebs-at-player-edit": [
        ("PE-01", ".title-bar",              "header"),
        ("PE-02", ".field-section:nth-of-type(1)", "input"),
        ("PE-03", ".field-section:nth-of-type(2)", "input"),
        ("PE-05", ".photo-box",              "display"),
        ("PE-06", ".action-btn-row",         "action"),
        ("PE-08", ".sit-out-row",            "option"),
        ("PE-09", ".bottom-row",             "action"),
    ],
    "ebs-at-seat-cell": [
        ("SC-01", ".seats-row:nth-of-type(1) .seat-cell:nth-child(1)", "state"),
        ("SC-02", ".seats-row:nth-of-type(1) .seat-cell:nth-child(2)", "state"),
        ("SC-03", ".seats-row:nth-of-type(1) .seat-cell:nth-child(3)", "state"),
        ("SC-04", ".seats-row:nth-of-type(2) .seat-cell:nth-child(1)", "state"),
        ("SC-05", ".seats-row:nth-of-type(2) .seat-cell:nth-child(2)", "state"),
        ("SC-06", ".seats-row:nth-of-type(2) .seat-cell:nth-child(3)", "state"),
    ],
    "ebs-action-tracker": [
        ("AT-01", ".status-bar",             "toolbar"),
        ("AT-02", ".game-bar",               "hand_control"),
        ("AT-03", ".table-area",             "seat"),
        ("AT-04", ".action-row",             "action_button"),
        ("AT-05", ".bet-row",                "action_panel"),
        ("AT-06", ".special-row",            "action_panel"),
    ],
}

# Viewport sizes (match capture_v4.py)
VIEWPORTS = {
    "ebs-at-login":        (820, 600),
    "ebs-at-main-layout":  (820, 900),
    "ebs-at-full-layout":  (1060, 900),
    "ebs-at-card-selector": (820, 700),
    "ebs-at-stats-panel":  (820, 800),
    "ebs-at-rfid-register": (820, 700),
    "ebs-at-settings-view": (820, 900),
    "ebs-at-player-edit":  (820, 600),
    "ebs-at-seat-cell":    (700, 600),
    "ebs-action-tracker":  (1060, 900),
}


def build_annotation_snippet(badges: list) -> str:
    """Build CSS + JS annotation snippet to inject before </body>."""
    badge_data_js = ",\n      ".join(
        f'{{label:"{lbl}",sel:"{sel}",color:"{CAT_COLORS.get(cat, "#c0392b")}"}}'
        for lbl, sel, cat in badges
    )

    return f"""
<!-- ANNOTATION OVERLAY -->
<style>
  .anno-badge {{
    position: absolute;
    z-index: 9999;
    padding: 2px 6px;
    font-size: 10px;
    font-weight: 700;
    font-family: 'IBM Plex Mono', 'Consolas', monospace;
    color: #fff;
    border-radius: 3px;
    white-space: nowrap;
    line-height: 1.3;
    pointer-events: none;
    box-shadow: 0 1px 3px rgba(0,0,0,0.3);
  }}
  .anno-highlight {{
    position: absolute;
    z-index: 9998;
    border: 2px solid;
    border-radius: 3px;
    pointer-events: none;
  }}
</style>
<script>
  document.addEventListener('DOMContentLoaded', function() {{
    var badges = [
      {badge_data_js}
    ];
    badges.forEach(function(b) {{
      var el = document.querySelector(b.sel);
      if (!el) {{ console.warn('NOT FOUND:', b.sel); return; }}
      var rect = el.getBoundingClientRect();
      // Highlight border
      var hl = document.createElement('div');
      hl.className = 'anno-highlight';
      hl.style.left = (rect.left + window.scrollX - 2) + 'px';
      hl.style.top = (rect.top + window.scrollY - 2) + 'px';
      hl.style.width = (rect.width + 2) + 'px';
      hl.style.height = (rect.height + 2) + 'px';
      hl.style.borderColor = b.color + 'cc';
      hl.style.background = b.color + '15';
      document.body.appendChild(hl);
      // Badge label
      var badge = document.createElement('span');
      badge.className = 'anno-badge';
      badge.textContent = b.label;
      badge.style.background = b.color;
      badge.style.left = (rect.left + window.scrollX - 2) + 'px';
      badge.style.top = (rect.top + window.scrollY - 2) + 'px';
      document.body.appendChild(badge);
    }});
  }});
</script>
"""


def create_annotated_html(screen_id: str, badges: list):
    """Read clean HTML, inject annotation snippet, write annotated version."""
    src = BASE_DIR / f"{screen_id}.html"
    dst = BASE_DIR / f"{screen_id}-annotated.html"

    if not src.exists():
        print(f"[SKIP] {src.name} not found")
        return None

    html = src.read_text(encoding="utf-8")
    snippet = build_annotation_snippet(badges)

    # Insert before </body>
    if "</body>" in html:
        html = html.replace("</body>", snippet + "\n</body>")
    else:
        html += snippet

    dst.write_text(html, encoding="utf-8")
    print(f"[HTML] {dst.name}")
    return dst


def capture_annotated_pngs():
    """Capture all annotated HTMLs to PNG."""
    with sync_playwright() as p:
        browser = p.chromium.launch()

        for screen_id in SCREEN_BADGES:
            html_path = BASE_DIR / f"{screen_id}-annotated.html"
            if not html_path.exists():
                continue

            vw, vh = VIEWPORTS.get(screen_id, (820, 800))
            page = browser.new_page(viewport={"width": vw, "height": vh})
            page.goto(html_path.as_uri())
            page.wait_for_timeout(1500)  # wait for Quasar + annotations

            container = page.locator("#q-app").first
            out_path = BASE_DIR / f"{screen_id}-annotated.png"
            container.screenshot(path=str(out_path))

            print(f"[PNG] {out_path.name}")
            page.close()

        browser.close()


def main():
    print("=== Phase 1: Generate annotated HTML ===")
    for screen_id, badges in SCREEN_BADGES.items():
        create_annotated_html(screen_id, badges)

    print("\n=== Phase 2: Capture annotated PNG ===")
    capture_annotated_pngs()

    anno_html = len(list(BASE_DIR.glob("*-annotated.html")))
    anno_png = len(list(BASE_DIR.glob("*-annotated.png")))
    print(f"\nDone. {anno_html} annotated HTML, {anno_png} annotated PNG")


if __name__ == "__main__":
    main()
