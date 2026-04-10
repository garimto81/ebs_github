"""AT JSON -> HTML Annotation Generator (Generic).

Reads analysis/{screen_id}-*.json and produces an HTML file with transparent
div overlays positioned over the original screenshot.

Usage:
    python generate_at_html.py                # at-01 (backward compatible)
    python generate_at_html.py --screen at-02 # specific screen
    python generate_at_html.py --all          # all screens (at-04 excluded, merged into at-02)
"""

import argparse
import glob
import json
import os
import re
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ANALYSIS_DIR = os.path.join(SCRIPT_DIR, "analysis")
OUTPUT_DIR = os.path.join(SCRIPT_DIR, "html_reproductions")

# at-04 is merged into at-02 as a diff tab; skip standalone generation
SKIP_SCREENS = {"at-04"}

# Diff mapping: at-04 element id -> (preflop_title, postflop_title)
DIFF_TITLES = {
    11: ("카드 아이콘 '노란 배경'", "카드 아이콘 '어두운 회색 배경'"),
    21: ("SEAT 1 '빨간 배경 (현재턴)'", "SEAT 1 '회색 배경 (비활성)'"),
    22: ("SEAT 2 '흰 배경'", "SEAT 2 '빨간 배경 (현재턴)'"),
    33: ("커뮤니티 카드 '비어있음'", "커뮤니티 카드 '7\u2665 6\u2660 4\u2665'"),
    34: ("(1) SEAT 1 - 1,000,000", "(2) SEAT 2 - 995,000"),
    39: ("CALL 액션 전송", "CHECK 액션 전송"),
    40: ("RAISE-TO 액션 전송", "BET 액션 전송"),
}


def to_kebab(name: str) -> str:
    """Convert 'Seat 1 Card Slot' -> 'seat-1-card-slot'."""
    s = name.strip().lower()
    s = re.sub(r"[^a-z0-9]+", "-", s)
    return s.strip("-")


def extract_badge(annotation_text: str):
    """Extract badge code and type from annotation_text.

    '[COM-TB-01] ...' -> ('COM-TB-01', 'common')
    '[S01-001] ...'   -> ('S01-001', 'unique')
    """
    m = re.match(r"\[([^\]]+)\]", annotation_text)
    if not m:
        return None, None
    code = m.group(1)
    if code.startswith("COM-"):
        badge_class = "common"
    elif re.match(r"S\d{2}-", code):
        badge_class = "unique"
    else:
        badge_class = "unique"
    return code, badge_class


def build_element_div(el: dict, is_diff: bool = False) -> str:
    bbox = el["bbox_pct"]
    annotation = el.get("annotation_text", "")
    badge_code, badge_class = extract_badge(annotation)
    kebab_name = to_kebab(el["name"])

    extra_style = ""
    extra_attrs = ""
    if is_diff:
        badge_class = "diff"
        extra_style = " border-style: dashed;"
        extra_attrs = ' data-diff="true"'

    style = (
        f"left:{bbox['x']}%; top:{bbox['y']}%; "
        f"width:{bbox['w']}%; height:{bbox['h']}%;{extra_style}"
    )

    badge_html = ""
    if badge_code:
        badge_html = (
            f'\n      <span class="badge {badge_class}">{badge_code}</span>'
        )

    return (
        f'    <div data-element-id="{el["id"]}" '
        f'data-element-name="{kebab_name}" '
        f'data-element-group="{el["category"]}"\n'
        f'         class="element-overlay"\n'
        f'         style="{style}"\n'
        f'         title="{annotation}"{extra_attrs}>'
        f"{badge_html}\n"
        f"    </div>"
    )


def find_json_for_screen(screen_id: str) -> str:
    """Find analysis JSON for a given screen_id via glob."""
    pattern = os.path.join(ANALYSIS_DIR, f"{screen_id}-*.json")
    matches = glob.glob(pattern)
    if not matches:
        raise FileNotFoundError(f"No analysis JSON found for {screen_id} in {ANALYSIS_DIR}")
    return matches[0]


def find_png_for_screen(screen_id: str) -> str:
    """Find the screenshot PNG for a given screen_id."""
    pattern = os.path.join(SCRIPT_DIR, f"{screen_id}-*.png")
    matches = [m for m in glob.glob(pattern) if "playwright" not in os.path.basename(m).lower()]
    if not matches:
        raise FileNotFoundError(f"No screenshot PNG found for {screen_id}")
    return matches[0]


def get_all_screen_ids() -> list:
    """Discover all screen IDs from analysis/ directory."""
    pattern = os.path.join(ANALYSIS_DIR, "at-*.json")
    ids = set()
    for path in glob.glob(pattern):
        basename = os.path.basename(path)
        # Extract at-NN from at-NN-something.json
        m = re.match(r"(at-\d+)", basename)
        if m:
            sid = m.group(1)
            if sid not in SKIP_SCREENS:
                ids.add(sid)
    return sorted(ids)


def build_standard_html(data: dict, screen_id: str, png_basename: str) -> str:
    """Build standard HTML (non-at-02) from analysis data."""
    screen_name = data.get("screen_name", screen_id)
    dims = data["dimensions"]
    elements = data["elements"]

    divs = [build_element_div(el) for el in elements]

    html = STANDARD_TEMPLATE.format(
        title=f"{screen_id.upper()} {screen_name}",
        width=dims["width"],
        height=dims["height"],
        img_src=f"../{png_basename}",
        img_alt=f"{screen_id.upper()} {screen_name}",
        elements="\n".join(divs),
    )
    return html, elements


def build_at02_html(preflop_data: dict, postflop_data: dict,
                    png_basename_pre: str, png_basename_post: str) -> str:
    """Build at-02 HTML with Pre-Flop/Post-Flop tab switch."""
    dims = preflop_data["dimensions"]
    elements = preflop_data["elements"]

    # Get diff element IDs from at-04
    diff_ids = set()
    diff_info = postflop_data.get("diff_from_preflop", {})
    if diff_info:
        diff_ids = set(diff_info.get("changed_element_ids", []))

    # Build postflop element map for title toggling
    postflop_map = {el["id"]: el for el in postflop_data["elements"]}

    divs = []
    diff_title_map = {}  # id -> (preflop_title, postflop_title)
    for el in elements:
        is_diff = el["id"] in diff_ids
        divs.append(build_element_div(el, is_diff=is_diff))
        if is_diff:
            pre_ann = el.get("annotation_text", "")
            post_el = postflop_map.get(el["id"], {})
            post_ann = post_el.get("annotation_text", pre_ann)
            diff_title_map[el["id"]] = (pre_ann, post_ann)

    # Build JS diff map
    js_diff_entries = []
    for eid, (pre_title, post_title) in sorted(diff_title_map.items()):
        # Escape quotes for JS
        pre_esc = pre_title.replace("\\", "\\\\").replace('"', '\\"')
        post_esc = post_title.replace("\\", "\\\\").replace('"', '\\"')
        js_diff_entries.append(
            f'        {eid}: {{pre: "{pre_esc}", post: "{post_esc}"}}'
        )
    js_diff_map = "{\n" + ",\n".join(js_diff_entries) + "\n      }"

    html = AT02_TEMPLATE.format(
        width=dims["width"],
        height=dims["height"],
        img_src_pre=f"../{png_basename_pre}",
        img_src_post=f"../{png_basename_post}",
        elements="\n".join(divs),
        diff_map_js=js_diff_map,
    )
    return html, elements


STANDARD_TEMPLATE = """\
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>{title} — Annotated</title>
  <style>
    * {{ margin: 0; padding: 0; box-sizing: border-box; }}
    body {{ background: #1a1a1a; display: flex; justify-content: center; align-items: center; min-height: 100vh; }}
    .screenshot-container {{
      width: {width}px; height: {height}px; position: relative; overflow: hidden;
    }}
    .screenshot-container img {{
      width: 100%; height: 100%; display: block;
    }}
    .element-overlay {{
      position: absolute; border: 1px solid rgba(0,100,255,0.5);
      cursor: pointer; transition: background 0.2s;
    }}
    .element-overlay:hover {{
      background: rgba(0,100,255,0.15);
    }}
    .badge {{
      position: absolute; top: -8px; left: -4px;
      font-size: 8px; font-weight: bold; color: white;
      padding: 1px 3px; border-radius: 6px;
      white-space: nowrap; pointer-events: none;
      line-height: 1.2;
    }}
    .badge.common {{ background: #2563EB; }}
    .badge.unique {{ background: #DC2626; }}
  </style>
</head>
<body>
  <div class="screenshot-container">
    <img src="{img_src}" alt="{img_alt}">
{elements}
  </div>
</body>
</html>
"""


AT02_TEMPLATE = """\
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>AT-02 Pre-Flop / Post-Flop Action — Annotated</title>
  <style>
    * {{ margin: 0; padding: 0; box-sizing: border-box; }}
    body {{ background: #1a1a1a; display: flex; flex-direction: column; align-items: center; min-height: 100vh; padding-top: 20px; }}
    .tab-bar {{
      display: flex; gap: 4px; margin-bottom: 12px;
    }}
    .tab-btn {{
      padding: 8px 24px; border: 1px solid #555; border-radius: 6px 6px 0 0;
      background: #333; color: #aaa; cursor: pointer; font-size: 14px; font-weight: bold;
      transition: all 0.2s;
    }}
    .tab-btn.active {{
      background: #1a1a1a; color: #fff; border-bottom-color: #1a1a1a;
    }}
    .screenshot-container {{
      width: {width}px; height: {height}px; position: relative; overflow: hidden;
    }}
    .screenshot-container img {{
      width: 100%; height: 100%; display: block;
    }}
    .element-overlay {{
      position: absolute; border: 1px solid rgba(0,100,255,0.5);
      cursor: pointer; transition: background 0.2s;
    }}
    .element-overlay:hover {{
      background: rgba(0,100,255,0.15);
    }}
    .element-overlay[data-diff="true"] {{
      border-color: rgba(249,115,22,0.7);
      border-style: dashed;
    }}
    .element-overlay[data-diff="true"]:hover {{
      background: rgba(249,115,22,0.15);
    }}
    .badge {{
      position: absolute; top: -8px; left: -4px;
      font-size: 8px; font-weight: bold; color: white;
      padding: 1px 3px; border-radius: 6px;
      white-space: nowrap; pointer-events: none;
      line-height: 1.2;
    }}
    .badge.common {{ background: #2563EB; }}
    .badge.unique {{ background: #DC2626; }}
    .badge.diff {{ background: #F97316; }}
  </style>
</head>
<body>
  <div class="tab-bar">
    <button class="tab-btn active" id="tab-pre" onclick="switchTab('pre')">Pre-Flop</button>
    <button class="tab-btn" id="tab-post" onclick="switchTab('post')">Post-Flop</button>
  </div>
  <div class="screenshot-container">
    <img id="screenshot-img" src="{img_src_pre}" alt="AT-02 Pre-Flop Action">
{elements}
  </div>
  <script>
    (function() {{
      var diffMap = {diff_map_js};
      var currentTab = 'pre';
      var imgPre = "{img_src_pre}";
      var imgPost = "{img_src_post}";

      window.switchTab = function(tab) {{
        if (tab === currentTab) return;
        currentTab = tab;

        // Update tab buttons
        document.getElementById('tab-pre').classList.toggle('active', tab === 'pre');
        document.getElementById('tab-post').classList.toggle('active', tab === 'post');

        // Switch screenshot image
        document.getElementById('screenshot-img').src = (tab === 'pre') ? imgPre : imgPost;

        // Toggle diff element titles
        var diffEls = document.querySelectorAll('[data-diff="true"]');
        diffEls.forEach(function(el) {{
          var eid = parseInt(el.getAttribute('data-element-id'));
          var info = diffMap[eid];
          if (info) {{
            el.setAttribute('title', (tab === 'pre') ? info.pre : info.post);
          }}
        }});
      }};
    }})();
  </script>
</body>
</html>
"""


def generate_screen(screen_id: str):
    """Generate HTML for a single screen."""
    print(f"\n--- Generating {screen_id} ---")

    json_path = find_json_for_screen(screen_id)
    with open(json_path, encoding="utf-8") as f:
        data = json.load(f)

    png_path = find_png_for_screen(screen_id)
    png_basename = os.path.basename(png_path)
    screen_name = data.get("screen_name", screen_id)

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    if screen_id == "at-02":
        # Special: merge at-04 diff into at-02
        at04_json_path = find_json_for_screen("at-04")
        with open(at04_json_path, encoding="utf-8") as f:
            at04_data = json.load(f)
        at04_png_path = find_png_for_screen("at-04")
        at04_png_basename = os.path.basename(at04_png_path)

        html, elements = build_at02_html(data, at04_data, png_basename, at04_png_basename)
        out_name = f"{screen_id}-action-annotated.html"
    else:
        html, elements = build_standard_html(data, screen_id, png_basename)
        # Derive output name from JSON filename
        json_basename = os.path.basename(json_path)
        out_stem = json_basename.replace(".json", "")
        out_name = f"{out_stem}-annotated.html"

    out_path = os.path.join(OUTPUT_DIR, out_name)
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(html)

    print(f"Generated: {out_path}")
    print(f"Total elements: {len(elements)}")

    # Count badge types
    com_count = sum(
        1 for el in elements
        if el.get("annotation_text", "").startswith("[COM-")
    )
    unique_pattern = re.compile(r"^\[S\d{2}-")
    sxx_count = sum(
        1 for el in elements
        if unique_pattern.match(el.get("annotation_text", ""))
    )
    print(f"COM-* badges: {com_count}")
    print(f"S*-* badges: {sxx_count}")

    return out_path, len(elements)


def main():
    parser = argparse.ArgumentParser(
        description="Generate annotated HTML overlays from AT analysis JSONs."
    )
    parser.add_argument(
        "--screen", type=str, default=None,
        help="Screen ID to generate (e.g., at-02). Default: at-01."
    )
    parser.add_argument(
        "--all", action="store_true",
        help="Generate HTML for all screens (at-04 excluded, merged into at-02)."
    )
    args = parser.parse_args()

    if args.all:
        screen_ids = get_all_screen_ids()
        print(f"Generating all screens: {screen_ids}")
        results = []
        for sid in screen_ids:
            try:
                path, count = generate_screen(sid)
                results.append((sid, path, count))
            except FileNotFoundError as e:
                print(f"[SKIP] {sid}: {e}")
        print(f"\n=== Summary: {len(results)} HTMLs generated ===")
        for sid, path, count in results:
            print(f"  {sid}: {count} elements -> {os.path.basename(path)}")
    elif args.screen:
        if args.screen in SKIP_SCREENS:
            print(f"[SKIP] {args.screen} is merged into at-02. Use --screen at-02 instead.")
            sys.exit(1)
        generate_screen(args.screen)
    else:
        # Backward compatible: default to at-01
        generate_screen("at-01")


if __name__ == "__main__":
    main()
