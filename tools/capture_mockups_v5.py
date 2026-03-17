"""v5 PNG 전체 신규 캡처 스크립트.

v3 HTML 26개 + v5 HTML 14개를 2048×540 viewport (deviceScaleFactor=2)로 캡처하여
docs/02-design/mockups/v5/에 PNG로 저장한다.

v5 HTML은 v3와 동명 파일을 덮어쓰며, clip 기반 캡처로 하단 공백을 제거한다.
"""

import sys
from pathlib import Path
from playwright.sync_api import sync_playwright

ROOT = Path("C:/claude/ebs")
V3_DIR = ROOT / "docs/02-design/mockups/v3"
V5_DIR = ROOT / "docs/02-design/mockups/v5"

# v3 소스 26개 HTML 파일 목록
V3_HTML_FILES = [
    "ebs-console-main-v4.html",
    "ebs-action-tracker.html",
    "ebs-at-card-selector.html",
    "ebs-at-full-layout.html",
    "ebs-at-main-layout.html",
    "ebs-at-rfid-register.html",
    "ebs-at-seat-cell.html",
    "ebs-at-settings-view.html",
    "ebs-at-stats-panel.html",
    "ebs-blinds-graphic.html",
    "ebs-board-graphic.html",
    "ebs-field-graphic.html",
    "ebs-grid-system.html",
    "ebs-leaderboard.html",
    "ebs-overlay-broadcast.html",
    "ebs-overlay-layout-b.html",
    "ebs-overlay-layout-c.html",
    "ebs-overlay-layout-d.html",
    "ebs-overlay-layout-grid.html",
    "ebs-player-graphic.html",
    "ebs-production-dashboard.html",
    "ebs-seat-template-a.html",
    "ebs-seat-template-b.html",
    "ebs-seat-template-c.html",
    "ebs-strip.html",
    "ebs-ticker.html",
]

# v5 소스 14개 HTML 파일 (Quasar White Minimal)
V5_HTML_FILES = [
    "ebs-console-display.html",
    "ebs-console-gfx.html",
    "ebs-console-main-v4.html",
    "ebs-console-outputs.html",
    "ebs-console-rules.html",
    "ebs-console-stats.html",
    "ebs-gfx-board-position.html",
    "ebs-gfx-indent-action.html",
    "ebs-gfx-leaderboard-position.html",
    "ebs-gfx-player-layout.html",
    "ebs-overlay-vertical-toggle.html",
    "ebs-stats-equity-outs.html",
    "ebs-stats-leaderboard-columns.html",
    "ebs-stats-score-strip.html",
]


def capture_html(page, src_dir: Path, html_file: str, output_png: str):
    """단일 HTML을 clip 기반으로 PNG 캡처 (공백 제거).

    측정 전략 (2단계):
      1. fit-content: html+body에 fit-content 강제 → 고정 폭/명시적 폭 레이아웃 정확 측정
      2. scrollWidth fallback: fit-content=0인 절대 배치 레이아웃 (overlay 등)

    HTML 요구사항: grid 1fr / flex:1 레이아웃은 반드시 컨테이너에 명시적 width를 지정해야
    fit-content가 정확한 값을 반환한다. (CSS spec: 1fr은 shrink-wrap 컨텍스트에서 붕괴)
    """
    html_path = src_dir / html_file
    if not html_path.exists():
        print(f"  SKIP (not found): {html_file}")
        return False

    url = html_path.as_uri()
    page.goto(url)
    page.wait_for_load_state("networkidle")

    content_box = page.evaluate("""() => {
        const html = document.documentElement;
        const body = document.body;
        const orig = {
            hw: html.style.width, hd: html.style.display,
            bw: body.style.width, bd: body.style.display
        };

        // Step 1: fit-content 강제 측정
        html.style.setProperty('width', 'fit-content', 'important');
        html.style.setProperty('display', 'block', 'important');
        body.style.setProperty('width', 'fit-content', 'important');
        body.style.setProperty('display', 'block', 'important');
        void body.offsetWidth;

        let w = body.getBoundingClientRect().width;
        let h = body.getBoundingClientRect().height;

        // 복원
        html.style.width = orig.hw; html.style.display = orig.hd;
        body.style.width = orig.bw; body.style.display = orig.bd;
        void body.offsetWidth;

        // Step 2: fit-content 실패 시 scrollWidth fallback (절대 배치 레이아웃)
        if (w < 1 || h < 1) {
            w = body.scrollWidth;
            h = body.scrollHeight;
        }
        return { x: 0, y: 0, width: Math.ceil(w), height: Math.ceil(h) };
    }""")

    out_path = V5_DIR / output_png
    page.screenshot(path=str(out_path), clip=content_box)
    size_kb = out_path.stat().st_size / 1024
    print(f"  OK: {output_png} ({size_kb:.0f} KB, {content_box['width']}x{content_box['height']})")
    return True


def main():
    V5_DIR.mkdir(parents=True, exist_ok=True)

    with sync_playwright() as p:
        browser = p.chromium.launch()
        context = browser.new_context(
            viewport={"width": 2048, "height": 540},
            device_scale_factor=2,
        )
        page = context.new_page()

        # Step 1: v3 HTML 26개 → PNG 캡처
        print("=== Step 1: v3 HTML → PNG 캡처 (26개) ===")
        ok_count = 0
        for html_file in V3_HTML_FILES:
            png_name = Path(html_file).stem + ".png"
            if capture_html(page, V3_DIR, html_file, png_name):
                ok_count += 1
        print(f"\nv3 캡처 완료: {ok_count}/{len(V3_HTML_FILES)}")

        # Step 2: v5 HTML 14개 → PNG 캡처 (동명 v3 PNG 덮어쓰기)
        print("\n=== Step 2: v5 HTML → PNG 캡처 (14개, 덮어쓰기) ===")
        v5_ok = 0
        for html_file in V5_HTML_FILES:
            png_name = Path(html_file).stem + ".png"
            if capture_html(page, V5_DIR, html_file, png_name):
                v5_ok += 1
        print(f"\nv5 캡처 완료: {v5_ok}/{len(V5_HTML_FILES)}")

        browser.close()

    # Step 3: 검증
    print("\n=== Step 3: 검증 ===")
    png_files = list(V5_DIR.glob("*.png"))
    print(f"총 PNG 파일: {len(png_files)}개")

    empty_files = [f for f in png_files if f.stat().st_size == 0]
    if empty_files:
        print(f"WARNING: 빈 파일 {len(empty_files)}개: {[f.name for f in empty_files]}")
        sys.exit(1)
    else:
        print("모든 파일 크기 정상 (> 0)")

    # 이미지 크기 heuristic 검증 (1KB 미만 = 실질적 빈 이미지)
    suspect_files = [f for f in png_files if f.stat().st_size < 1024]
    if suspect_files:
        print(f"WARNING: 의심스러운 파일 크기 {len(suspect_files)}개:")
        for f in suspect_files:
            print(f"  {f.name} ({f.stat().st_size / 1024:.1f} KB)")
    else:
        print("이미지 크기 검증 통과 (모두 >= 1 KB)")

    expected = len(V3_HTML_FILES) + len(V5_HTML_FILES)
    if len(png_files) >= len(V3_HTML_FILES):
        print(f"SUCCESS: {len(png_files)}개 PNG 생성 완료 (v3: {len(V3_HTML_FILES)}, v5 덮어쓰기: {v5_ok})")
    else:
        print(f"WARNING: {len(png_files)}개만 생성됨 (최소 {len(V3_HTML_FILES)}개 예상)")
        sys.exit(1)


if __name__ == "__main__":
    main()
