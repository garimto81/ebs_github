"""AT Annotated PNG Generator (Generic).

Reads elements JSON (from Playwright pipeline) + analysis JSON + original screenshot,
draws bbox overlays with numbered markers and badge labels,
outputs annotated PNG to annotated/ directory.

Usage:
    python annotate_at.py                # at-01 (backward compatible)
    python annotate_at.py --screen at-02 # specific screen
    python annotate_at.py --all          # all screens with elements JSON
"""
import argparse
import glob
import json
import re
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

SCRIPT_DIR = Path(__file__).resolve().parent
OUTPUT_DIR = SCRIPT_DIR / "annotated"


# Category -> color mapping
CATEGORY_COLORS = {
    "titlebar": "#3498DB",
    "hand_control": "#E67E22",
    "toolbar": "#9B59B6",
    "card_area": "#2ECC71",
    "seat": "#1ABC9C",
    "option": "#F39C12",
    "position": "#E74C3C",
    "blind": "#D35400",
    "game_settings": "#8E44AD",
    "navigation": "#C0392B",
    "chrome": "#3498DB",
    "table_header": "#E67E22",
    "data_column": "#2ECC71",
    "data_cell": "#1ABC9C",
    "action_panel": "#9B59B6",
    "card_grid": "#F39C12",
    "status_bar": "#C0392B",
    "dialog": "#8E44AD",
    "form": "#D35400",
    "button": "#E74C3C",
}

COMMON_COLOR = "#2563EB"
UNIQUE_COLOR = "#DC2626"


def get_font(size: int):
    for path in [
        r"C:\Windows\Fonts\malgun.ttf",
        r"C:\Windows\Fonts\segoeui.ttf",
        r"C:\Windows\Fonts\arial.ttf",
    ]:
        try:
            return ImageFont.truetype(path, size)
        except (OSError, IOError):
            continue
    return ImageFont.load_default()


def get_bold_font(size: int):
    for path in [
        r"C:\Windows\Fonts\malgunbd.ttf",
        r"C:\Windows\Fonts\segoeuib.ttf",
        r"C:\Windows\Fonts\arialbd.ttf",
    ]:
        try:
            return ImageFont.truetype(path, size)
        except (OSError, IOError):
            continue
    return get_font(size)


FONT_BADGE = get_bold_font(9)
FONT_NUM = get_bold_font(10)
FONT_LEGEND = get_font(11)
FONT_TITLE = get_bold_font(13)


def hex_to_rgba(hex_color: str, alpha: int = 35) -> tuple:
    h = hex_color.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), alpha)


def extract_badge(annotation_text: str):
    m = re.match(r"\[([^\]]+)\]", annotation_text)
    if not m:
        return None, None
    code = m.group(1)
    badge_type = "common" if code.startswith("COM-") else "unique"
    return code, badge_type


def draw_numbered_marker(draw, x, y, number, color):
    r = 8
    draw.ellipse([x - r - 1, y - r - 1, x + r + 1, y + r + 1], fill="white")
    draw.ellipse([x - r, y - r, x + r, y + r], fill=color)
    text = str(number)
    bbox = FONT_NUM.getbbox(text)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    draw.text((x - tw // 2, y - th // 2 - 1), text, fill="white", font=FONT_NUM)


def find_elements_json(screen_id: str) -> Path:
    """Find elements JSON for a given screen_id."""
    pattern = str(SCRIPT_DIR / "elements" / f"{screen_id}-*-elements.json")
    matches = glob.glob(pattern)
    if not matches:
        raise FileNotFoundError(f"No elements JSON for {screen_id}")
    return Path(matches[0])


def find_analysis_json(screen_id: str) -> Path:
    """Find analysis JSON for a given screen_id."""
    pattern = str(SCRIPT_DIR / "analysis" / f"{screen_id}-*.json")
    matches = glob.glob(pattern)
    if not matches:
        raise FileNotFoundError(f"No analysis JSON for {screen_id}")
    return Path(matches[0])


def find_screenshot(screen_id: str) -> Path:
    """Find screenshot PNG for a given screen_id (exclude _playwright)."""
    pattern = str(SCRIPT_DIR / f"{screen_id}-*.png")
    matches = [
        Path(m) for m in glob.glob(pattern)
        if "playwright" not in Path(m).name.lower()
    ]
    if not matches:
        raise FileNotFoundError(f"No screenshot PNG for {screen_id}")
    return matches[0]


def get_all_screen_ids_from_elements() -> list:
    """Discover screen IDs from elements/ directory."""
    pattern = str(SCRIPT_DIR / "elements" / "at-*-elements.json")
    ids = set()
    for path in glob.glob(pattern):
        basename = Path(path).name
        m = re.match(r"(at-\d+)", basename)
        if m:
            ids.add(m.group(1))
    return sorted(ids)


def annotate_screen(screen_id: str):
    """Generate annotated PNG for a single screen."""
    print(f"\n--- Annotating {screen_id} ---")

    elements_path = find_elements_json(screen_id)
    analysis_path = find_analysis_json(screen_id)
    screenshot_path = find_screenshot(screen_id)

    # Load elements (bbox from Playwright)
    with open(elements_path, encoding="utf-8") as f:
        elements_data = json.load(f)
    elements = elements_data["elements"]

    # Load analysis (annotation_text, category)
    with open(analysis_path, encoding="utf-8") as f:
        analysis_data = json.load(f)
    analysis_map = {el["id"]: el for el in analysis_data["elements"]}

    screen_name = analysis_data.get("screen_name", screen_id)

    img = Image.open(screenshot_path).convert("RGBA")
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    overlay_draw = ImageDraw.Draw(overlay)

    # Draw semi-transparent fills
    for elem in elements:
        eid = elem["id"]
        info = analysis_map.get(eid, {})
        category = info.get("category", elem.get("group", ""))
        color = CATEGORY_COLORS.get(category, "#FF0000")
        x1, y1, x2, y2 = elem["bbox"]
        fill = hex_to_rgba(color, alpha=30)
        overlay_draw.rectangle([x1, y1, x2, y2], fill=fill)

    img = Image.alpha_composite(img, overlay)
    draw = ImageDraw.Draw(img)

    # Draw outlines + badge labels
    groups_seen = {}
    for elem in elements:
        eid = elem["id"]
        info = analysis_map.get(eid, {})
        category = info.get("category", elem.get("group", ""))
        annotation = info.get("annotation_text", "")
        color = CATEGORY_COLORS.get(category, "#FF0000")
        x1, y1, x2, y2 = elem["bbox"]

        # Outline
        draw.rectangle([x1, y1, x2, y2], outline=color, width=1)

        # Badge label (top-left corner)
        badge_code, badge_type = extract_badge(annotation)
        if badge_code:
            badge_color = COMMON_COLOR if badge_type == "common" else UNIQUE_COLOR
            tb = FONT_BADGE.getbbox(badge_code)
            tw = tb[2] - tb[0]
            th = tb[3] - tb[1]
            bx = max(0, x1 - 2)
            by = max(0, y1 - th - 4)
            draw.rectangle([bx, by, bx + tw + 4, by + th + 3],
                           fill=badge_color)
            draw.text((bx + 2, by + 1), badge_code, fill="white", font=FONT_BADGE)

        # Track groups for legend
        display_name = info.get("name", elem.get("name", ""))
        if category not in groups_seen:
            groups_seen[category] = (color, [])
        groups_seen[category][1].append((eid, display_name))

    # Add legend at bottom
    legend_lines = 2  # title + blank
    for group, (_, items) in groups_seen.items():
        legend_lines += 1 + len(items)

    line_h = 15
    legend_h = legend_lines * line_h + 20
    canvas = Image.new("RGBA",
                        (img.width, img.height + legend_h),
                        (30, 30, 30, 255))
    canvas.paste(img, (0, 0))
    ld = ImageDraw.Draw(canvas)

    ly = img.height + 8
    com_count = sum(1 for el in analysis_data["elements"]
                    if el.get("annotation_text", "").startswith("[COM-"))
    # Count S\d{2}- pattern badges
    unique_pattern = re.compile(r"^\[S\d{2}-")
    sxx_count = sum(1 for el in analysis_data["elements"]
                    if unique_pattern.match(el.get("annotation_text", "")))
    ld.text((10, ly),
            f"{screen_id.upper()} {screen_name} — {len(elements)} elements (COM:{com_count} / Unique:{sxx_count})",
            fill="white", font=FONT_TITLE)
    ly += 20

    # Two-column legend
    col_w = img.width // 2
    col_x = [10, col_w + 10]
    col_y = [ly, ly]
    col_idx = 0

    for group, (color, items) in groups_seen.items():
        ld.rectangle([col_x[col_idx], col_y[col_idx],
                      col_x[col_idx] + 10, col_y[col_idx] + 10],
                     fill=color, outline="white")
        ld.text((col_x[col_idx] + 14, col_y[col_idx] - 2),
                f"{group.upper()} ({len(items)})", fill="white", font=FONT_TITLE)
        col_y[col_idx] += line_h
        for eid, ename in items:
            ld.text((col_x[col_idx] + 14, col_y[col_idx] - 2),
                    f"  {eid}: {ename}", fill="#BBBBBB", font=FONT_LEGEND)
            col_y[col_idx] += line_h
        col_y[col_idx] += 4
        # Switch columns to balance
        if col_y[col_idx] > col_y[1 - col_idx] + 30:
            col_idx = 1 - col_idx

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    # Derive output name from analysis JSON
    analysis_basename = analysis_path.stem  # e.g. at-01-setup-mode
    out_path = OUTPUT_DIR / f"{analysis_basename}-annotated.png"
    canvas.convert("RGB").save(str(out_path), "PNG")
    print(f"[OK] Annotated: {out_path} ({canvas.width}x{canvas.height})")
    print(f"     Elements: {len(elements)}, Categories: {len(groups_seen)}")

    return out_path


def main():
    parser = argparse.ArgumentParser(
        description="Generate annotated PNG overlays from AT elements + analysis JSONs."
    )
    parser.add_argument(
        "--screen", type=str, default=None,
        help="Screen ID to annotate (e.g., at-02). Default: at-01."
    )
    parser.add_argument(
        "--all", action="store_true",
        help="Annotate all screens that have elements JSON."
    )
    args = parser.parse_args()

    if args.all:
        screen_ids = get_all_screen_ids_from_elements()
        print(f"Annotating all screens with elements: {screen_ids}")
        results = []
        for sid in screen_ids:
            try:
                path = annotate_screen(sid)
                results.append((sid, path))
            except FileNotFoundError as e:
                print(f"[SKIP] {sid}: {e}")
        print(f"\n=== Summary: {len(results)} PNGs generated ===")
        for sid, path in results:
            print(f"  {sid}: {path.name}")
    elif args.screen:
        annotate_screen(args.screen)
    else:
        # Backward compatible: default to at-01
        annotate_screen("at-01")


if __name__ == "__main__":
    main()
