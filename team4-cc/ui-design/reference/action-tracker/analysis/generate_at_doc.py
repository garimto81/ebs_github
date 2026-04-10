"""
generate_at_doc.py — 3-Layer AT Annotation Reference Document Generator.

Reads analysis JSON files and produces AT-Annotation-Reference.md with:
  Layer 1: Original screenshot PNG
  Layer 2: Clean annotated capture (boxes only, no badges)
  Layer 3: Markdown table of UI elements

Special handling:
  - at-02/at-04 merged: at-04 diff shown as sub-section within at-02
  - at-04 has no separate section
"""

import json
import re
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
ANALYSIS_DIR = BASE_DIR / "analysis"
OUT_FILE = BASE_DIR / "AT-Annotation-Reference.md"

# Screen definitions: (json_file, original_png, clean_png, display_name)
SCREENS = [
    ("at-01-setup-mode.json",        "at-01-setup-mode.png",        "captures/at-01-clean-annotated.png", "AT-01: Setup Mode"),
    ("at-02-action-preflop.json",     "at-02-action-preflop.png",    "captures/at-02-clean-annotated.png", "AT-02: Pre-Flop Action"),
    ("at-03-card-selector.json",      "at-03-card-selector.png",     "captures/at-03-clean-annotated.png", "AT-03: Card Selector"),
    ("at-05-statistics-register.json","at-05-statistics-register.png","captures/at-05-clean-annotated.png", "AT-05: Statistics / Register Panel"),
    ("at-06-rfid-registration.json",  "at-06-rfid-registration.png", "captures/at-06-clean-annotated.png", "AT-06: RFID Registration"),
]

# at-04 diff data (loaded separately)
AT04_JSON = "at-04-action-postflop.json"

# Diff element mapping (from task spec)
DIFF_MAP = {
    11: ("카드 아이콘 노란 배경 (카드 입력됨)", "카드 아이콘 어두운 회색 배경 (비활성/폴드)"),
    21: ("SEAT 1 빨간 배경 (현재턴)", "SEAT 1 회색 배경 (비활성)"),
    22: ("SEAT 2 흰 배경 (활성)", "SEAT 2 빨간 배경 (현재턴)"),
    33: ("커뮤니티 카드 비어있음", "커뮤니티 카드 7♥ 6♠ 4♥ (Flop)"),
    34: ("(1) SEAT 1 - STACK 1,000,000", "(2) SEAT 2 - STACK 995,000"),
    39: ("CALL 액션 전송", "CHECK 액션 전송"),
    40: ("RAISE-TO 액션 전송", "BET 액션 전송"),
}


def parse_badge(annotation_text: str) -> tuple[str, str]:
    """Extract badge code and description from annotation_text.

    '[COM-TB-01] 앱 아이콘' -> ('COM-TB-01', '앱 아이콘')
    '[COM-TB] 윈도우 타이틀바 (5개 요소 그룹)' -> ('COM-TB', '윈도우 타이틀바 (5개 요소 그룹)')
    """
    m = re.match(r'\[([^\]]+)\]\s*(.*)', annotation_text)
    if m:
        return m.group(1), m.group(2)
    return "", annotation_text


def load_json(filename: str) -> dict:
    path = ANALYSIS_DIR / filename
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def render_elements_table(elements: list[dict]) -> str:
    """Render markdown table for a list of elements."""
    lines = [
        "| ID | Badge | Name | Category | Description |",
        "|----|-------|------|----------|-------------|",
    ]
    for el in elements:
        badge, desc = parse_badge(el.get("annotation_text", ""))
        name = el.get("name", "")
        cat = el.get("category", "")
        eid = el.get("id", "")
        # Escape pipes in content
        name = name.replace("|", "\\|")
        desc = desc.replace("|", "\\|")
        lines.append(f"| {eid} | {badge} | {name} | {cat} | {desc} |")
    return "\n".join(lines)


def render_diff_table(at02_data: dict, at04_data: dict) -> str:
    """Render Pre-Flop / Post-Flop diff table."""
    # Build lookup for badge codes from at-02
    at02_map = {el["id"]: el for el in at02_data["elements"]}

    lines = [
        "| ID | Badge | Pre-Flop | Post-Flop |",
        "|----|-------|----------|-----------|",
    ]
    for eid, (pre, post) in sorted(DIFF_MAP.items()):
        el = at02_map.get(eid, {})
        badge, _ = parse_badge(el.get("annotation_text", ""))
        lines.append(f"| {eid} | {badge} | {pre} | {post} |")
    return "\n".join(lines)


def main():
    # Load at-04 for diff
    at04_data = load_json(AT04_JSON)

    parts = []
    parts.append("# AT Annotation Reference")
    parts.append("")
    parts.append("PokerGFX Action Tracker UI 요소 3-Layer 참조 문서.")
    parts.append("")
    parts.append("각 화면별 구조: 원본 스크린샷 / Annotation Overlay (배지 제거) / UI 요소 테이블.")
    parts.append("")

    # Table of contents
    parts.append("## 목차")
    parts.append("")
    for _, _, _, title in SCREENS:
        anchor = title.lower().replace(" ", "-").replace(":", "").replace("/", "").replace("(", "").replace(")", "")
        # Simplify: use screen id
        sid = title.split(":")[0].strip().lower()
        parts.append(f"- [{title}](#{sid}-{title.split(': ')[1].lower().replace(' ', '-').replace('/', '-')})")
    parts.append("")
    parts.append("---")
    parts.append("")

    for json_file, orig_png, clean_png, title in SCREENS:
        data = load_json(json_file)
        elements = data["elements"]
        dims = data["dimensions"]
        screen_id = data["screen_id"]

        parts.append(f"## {title}")
        parts.append("")
        parts.append(f"**{dims['width']}x{dims['height']}** | **{len(elements)}개 요소**")
        parts.append("")

        # Layer 1: Original screenshot
        parts.append("### 원본 스크린샷")
        parts.append("")
        parts.append(f"![{screen_id} Original]({orig_png})")
        parts.append("")

        # Layer 2: Clean annotation overlay
        parts.append("### Annotation Overlay")
        parts.append("")
        parts.append(f"![{screen_id} Annotated]({clean_png})")
        parts.append("")

        # Layer 3: Elements table
        parts.append(f"### UI Elements ({len(elements)}개)")
        parts.append("")
        parts.append(render_elements_table(elements))
        parts.append("")

        # Special: at-02 gets diff sub-section
        if screen_id == "at-02":
            changed_ids = at04_data.get("diff_from_preflop", {}).get("changed_element_ids", [])
            parts.append(f"#### Pre-Flop / Post-Flop Diff ({len(changed_ids)}개 요소)")
            parts.append("")
            parts.append("at-04 (Post-Flop)에서 변경되는 요소. at-04는 별도 섹션 없이 여기에 통합.")
            parts.append("")
            parts.append(render_diff_table(data, at04_data))
            parts.append("")

        parts.append("---")
        parts.append("")

    # Write output
    content = "\n".join(parts)
    with open(OUT_FILE, "w", encoding="utf-8") as f:
        f.write(content)

    print(f"[OK] {OUT_FILE.name} generated ({len(content)} chars)")

    # Verify element counts
    expected = {"at-01": 83, "at-02": 41, "at-03": 8, "at-05": 22, "at-06": 9}
    for json_file, _, _, title in SCREENS:
        data = load_json(json_file)
        sid = data["screen_id"]
        actual = len(data["elements"])
        exp = expected.get(sid, "?")
        status = "OK" if actual == exp else "MISMATCH"
        print(f"  {sid}: {actual} elements [{status}]")


if __name__ == "__main__":
    main()
