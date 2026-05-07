"""Capture screenshots of the React prototype for CC redesign PRD."""
from playwright.sync_api import sync_playwright
from pathlib import Path
import threading, http.server, socketserver, os

PROTOTYPE_DIR = Path(r"C:/Users/AidenKim/Downloads/EBS Command Center (1)")
OUT_DIR = Path(r"C:/claude/ebs-cc-stream/docs/images/cc/2026-05-07-redesign")
OUT_DIR.mkdir(parents=True, exist_ok=True)


def start_http_server():
    os.chdir(str(PROTOTYPE_DIR))

    class Quiet(http.server.SimpleHTTPRequestHandler):
        def log_message(self, *a, **k): pass

    socketserver.TCPServer.allow_reuse_address = True
    for port in (18765, 18888, 19000, 21345, 23456):
        try:
            httpd = socketserver.TCPServer(("127.0.0.1", port), Quiet)
            threading.Thread(target=httpd.serve_forever, daemon=True).start()
            return httpd, port
        except OSError:
            continue
    raise RuntimeError("no port")


def safe_clip(page, sel, name, pad=4):
    el = page.locator(sel)
    if el.count() == 0:
        return False
    try:
        box = el.first.bounding_box()
        if not box:
            return False
        page.screenshot(path=str(OUT_DIR / name),
            clip={"x": max(0, box["x"]-pad), "y": max(0, box["y"]-pad),
                  "width": box["width"]+pad*2, "height": box["height"]+pad*2})
        return True
    except Exception:
        return False


def main():
    httpd, port = start_http_server()
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            ctx = browser.new_context(viewport={"width":1600,"height":900}, device_scale_factor=2)
            page = ctx.new_page()
            page.goto(f"http://127.0.0.1:{port}/EBS%20Command%20Center.html",
                      wait_until="networkidle", timeout=60000)
            page.wait_for_selector("#app[data-screen-label]", timeout=60000)
            page.wait_for_timeout(3000)

            page.screenshot(path=str(OUT_DIR / "01-idle-full.png"))
            safe_clip(page, ".statusbar", "09-statusbar-detail.png", 2)

            page.keyboard.press("n"); page.wait_for_timeout(800)
            page.screenshot(path=str(OUT_DIR / "02-preflop-full.png"))
            safe_clip(page, ".topstrip", "07-topstrip-detail.png", 2)

            cols = page.locator(".pcol").all()
            if len(cols) >= 4:
                b1, b4 = cols[0].bounding_box(), cols[3].bounding_box()
                if b1 and b4:
                    page.screenshot(path=str(OUT_DIR / "06-playercolumn-detail.png"),
                        clip={"x":max(0,b1["x"]-4),"y":max(0,b1["y"]-4),
                              "width":(b4["x"]+b4["width"])-b1["x"]+8,"height":b1["height"]+8})

            page.keyboard.press("f"); page.wait_for_timeout(300)
            page.keyboard.press("c"); page.wait_for_timeout(300)
            page.screenshot(path=str(OUT_DIR / "03-preflop-midaction.png"))

            page.keyboard.press("b"); page.wait_for_timeout(500)
            if page.locator(".numpad-overlay").count() > 0:
                page.screenshot(path=str(OUT_DIR / "04-numpad-bet.png"))
                page.keyboard.press("Escape"); page.wait_for_timeout(300)

            safe_clip(page, ".actionpanel", "08-actionpanel-detail.png", 2)

            slots = page.locator(".ts-slot").all()
            if slots:
                slots[0].click(); page.wait_for_timeout(500)
                if page.locator(".cp-modal").count() > 0:
                    page.screenshot(path=str(OUT_DIR / "05-cardpicker-board.png"))
                    page.keyboard.press("Escape"); page.wait_for_timeout(300)

            safe_clip(page, ".mini-diagram", "10-minidiagram-detail.png", 4)
            safe_clip(page, ".ts-acting", "11-acting-box.png", 6)
            safe_clip(page, ".ts-board", "12-community-board.png", 4)

            holes = page.locator(".pcol .hcard").all()
            if holes:
                holes[0].click(); page.wait_for_timeout(500)
                if page.locator(".cp-modal").count() > 0:
                    page.screenshot(path=str(OUT_DIR / "13-cardpicker-hole-option-on.png"))
                    page.keyboard.press("Escape"); page.wait_for_timeout(300)

            cols = page.locator(".pcol.action-on").all()
            if cols:
                try:
                    box = cols[0].bounding_box()
                    if box:
                        page.screenshot(path=str(OUT_DIR / "14-acting-glow.png"),
                            clip={"x":max(0,box["x"]-10),"y":max(0,box["y"]-10),
                                  "width":box["width"]+20,"height":box["height"]+20})
                except Exception:
                    pass

            safe_clip(page, ".kbd-hint", "15-keyboard-hints.png", 4)

            browser.close()
    finally:
        httpd.shutdown()

    files = sorted(OUT_DIR.glob("*.png"))
    print(f"=== {len(files)} screenshots ===")


if __name__ == "__main__":
    main()
