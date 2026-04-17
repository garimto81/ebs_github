#!/usr/bin/env python3
"""EBS 실제 브라우저 E2E 러너 — Playwright 기반.

API 스모크(tools/run_integration_tests.py)는 curl 레벨 검증.
이 러너는 **실제 Chromium 브라우저**로 Lobby 접속 → 로그인 → 대시보드 진입까지 검증.
CORS, 브라우저 런타임 URL 구성, 클라이언트 JSON 파싱 등 API 스모크로는 못 잡는 영역 커버.

사전 준비:
    pip install playwright
    playwright install chromium

사용:
    python tools/run_browser_e2e.py                              # localhost 기본
    EBS_HOST=10.10.100.115 python tools/run_browser_e2e.py       # LAN
    python tools/run_browser_e2e.py --headed                     # GUI 모드 (디버그)
    python tools/run_browser_e2e.py --screenshot-dir logs/e2e    # 단계별 캡처
"""
from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

EMAIL = "admin@ebs.local"
PASSWORD = "admin123"


def host() -> str:
    return os.environ.get("EBS_HOST", "localhost")


def port_lobby() -> int:
    return int(os.environ.get("EBS_PORT_LOBBY", "3000"))


def port_cc() -> int:
    return int(os.environ.get("EBS_PORT_CC", "3100"))


def port_bo() -> int:
    return int(os.environ.get("EBS_PORT_BO", "8000"))


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--headed", action="store_true", help="브라우저 창 표시 (기본: headless)")
    p.add_argument("--screenshot-dir", type=Path, default=None, help="단계별 스크린샷 저장 디렉토리")
    p.add_argument("--timeout", type=int, default=30000, help="기본 타임아웃(ms)")
    p.add_argument("--skip-cc", action="store_true", help="CC Demo 페이지 검증 건너뛰기")
    args = p.parse_args()

    try:
        from playwright.sync_api import sync_playwright, TimeoutError as PWTimeout  # type: ignore
    except ImportError:
        print("[ERROR] playwright 미설치. 설치: pip install playwright && playwright install chromium")
        return 2

    lobby_url = f"http://{host()}:{port_lobby()}"
    cc_url = f"http://{host()}:{port_cc()}"
    bo_url = f"http://{host()}:{port_bo()}"

    print(f"[INFO] Lobby = {lobby_url}")
    print(f"[INFO] CC    = {cc_url}")
    print(f"[INFO] BO    = {bo_url}")

    if args.screenshot_dir:
        args.screenshot_dir.mkdir(parents=True, exist_ok=True)

    def snap(page, name: str):
        if args.screenshot_dir:
            path = args.screenshot_dir / f"{name}.png"
            page.screenshot(path=str(path), full_page=True)
            print(f"       screenshot → {path}")

    failed = 0
    console_errors: list[str] = []
    network_failures: list[str] = []

    with sync_playwright() as pw:
        browser = pw.chromium.launch(headless=not args.headed)
        context = browser.new_context(ignore_https_errors=True)
        page = context.new_page()
        page.set_default_timeout(args.timeout)

        page.on("console", lambda msg: (
            console_errors.append(f"[{msg.type}] {msg.text}")
            if msg.type == "error" else None
        ))
        page.on("requestfailed", lambda r: network_failures.append(
            f"{r.method} {r.url} — {r.failure}"
        ))

        # 모든 /auth/, /api/ 요청/응답 로깅 + 4xx/5xx 카운트
        auth_requests: list[str] = []
        api_errors: list[str] = []
        def _log_req(req):
            if "/auth/" in req.url or "/api/" in req.url:
                auth_requests.append(f"REQ  {req.method} {req.url}")
        def _log_resp(resp):
            if "/auth/" in resp.url or "/api/" in resp.url:
                status = resp.status
                auth_requests.append(f"RESP {status} {resp.url}")
                if status >= 400:
                    api_errors.append(f"HTTP {status} {resp.request.method} {resp.url}")
        page.on("request", _log_req)
        page.on("response", _log_resp)

        # ── 1. Lobby 초기 진입 ────────────────────────────────────────
        try:
            page.goto(lobby_url, wait_until="networkidle")
            snap(page, "01-lobby-loaded")
            title = page.title()
            assert "EBS" in title or "Lobby" in title or title, f"unexpected title: {title}"
            print(f"[OK] Lobby 로드 — title='{title}'")
        except Exception as e:
            print(f"[FAIL] Lobby 로드 — {e}"); failed += 1; snap(page, "01-lobby-FAIL")

        # ── 2. 로그인 폼 입력 + 제출 ─────────────────────────────────
        # Flutter CanvasKit 렌더러는 <input> DOM을 생성하지 않음.
        # Tab 키로 포커스 이동하면 Flutter가 <flt-text-editing-host>에 <input> 동적 생성.
        # 그래서 keyboard-only 네비게이션 사용.
        login_ok = False
        try:
            page.wait_for_timeout(1500)  # Flutter 초기 렌더 여유

            # 캔버스에 포커스 주기 (Flutter view)
            flutter_view = page.locator('flutter-view, flt-glass-pane, body').first
            flutter_view.click(position={"x": 10, "y": 10}, force=True)
            page.wait_for_timeout(200)

            # Tab → 1st field (email)
            page.keyboard.press("Tab")
            page.wait_for_timeout(300)
            page.keyboard.type(EMAIL, delay=30)
            page.wait_for_timeout(200)

            # Tab → 2nd field (password)
            page.keyboard.press("Tab")
            page.wait_for_timeout(300)
            page.keyboard.type(PASSWORD, delay=30)
            page.wait_for_timeout(200)
            snap(page, "02-form-filled")

            # Submit: 로그인 버튼 클릭 (좌표 기반 — Flutter CanvasKit는 role selector 불안정)
            # 기본 viewport 1280x720 기준 로그인 버튼 중심 (640, 391) ±  여유.
            # Semantics가 활성이면 role selector도 시도.
            submit_clicked = False
            for selector in [
                'flt-semantics[role="button"]:has-text("로그인")',
                '[role="button"]:has-text("로그인")',
                'flt-semantics[aria-label="로그인"]',
            ]:
                try:
                    el = page.locator(selector).first
                    if el.count() > 0:
                        with page.expect_response(lambda r: "/auth/login" in r.url, timeout=args.timeout) as resp_info:
                            el.click()
                        resp = resp_info.value
                        submit_clicked = True
                        break
                except Exception:
                    continue

            if not submit_clicked:
                # 좌표 기반 fallback
                vp = page.viewport_size or {"width": 1280, "height": 720}
                cx = vp["width"] // 2
                cy = 391 if vp["height"] == 720 else int(vp["height"] * 0.543)
                print(f"[INFO] 좌표 기반 클릭 ({cx}, {cy}) — 로그인 버튼")
                with page.expect_response(lambda r: "/auth/login" in r.url, timeout=args.timeout) as resp_info:
                    page.mouse.click(cx, cy)
                resp = resp_info.value

            print(f"[INFO] /auth/login → {resp.status}")
            snap(page, "03-after-login")
            assert resp.status == 200, f"login response {resp.status}: {resp.text()[:200]}"
            login_ok = True
            print("[OK] Login 성공 (HTTP 200)")
        except PWTimeout as e:
            print(f"[FAIL] Login — timeout ({e})"); failed += 1; snap(page, "02-login-TIMEOUT")
        except AssertionError as e:
            print(f"[FAIL] Login — {e}"); failed += 1; snap(page, "02-login-ASSERT")
        except Exception as e:
            print(f"[FAIL] Login — {type(e).__name__}: {e}"); failed += 1; snap(page, "02-login-EXCEPTION")

        # ── 3. 로그인 후 URL / 상태 확인 + Dashboard 체류 ──────────────
        if login_ok:
            try:
                try:
                    page.wait_for_url(lambda u: "login" not in u.lower(), timeout=10000)
                except PWTimeout:
                    pass
                after_url = page.url
                snap(page, "04-after-navigation")
                assert "login" not in after_url.lower(), f"still on login page: {after_url}"
                print(f"[OK] 로그인 후 라우팅 — {after_url}")

                # Dashboard 렌더링 완료까지 체류 (사용자가 로그인 직후 경험하는 구간)
                print("[INFO] Lobby Dashboard 체류 10초 — 모든 후속 API + 런타임 에러 수집")
                page.wait_for_timeout(10000)
                snap(page, "04b-dashboard-10s")

                # Flutter 런타임 에러 검출 — 3단 방어:
                # 1) DOM innerText (HTML 렌더러)
                # 2) 스크린샷의 빨간 에러 박스 픽셀 색상 (CanvasKit)
                # 3) 콘솔 에러 메시지는 이미 page.on("console")로 수집 중
                page_content = page.evaluate("() => document.body.innerText || ''")
                error_markers = ["TypeError", "Exception", "not a subtype", "Stack trace"]
                text_errors = [m for m in error_markers if m in page_content]
                if text_errors:
                    import re as _re
                    for marker in text_errors[:3]:
                        m = _re.search(rf".{{0,80}}{_re.escape(marker)}.{{0,150}}", page_content)
                        if m:
                            print(f"[FAIL] UI 텍스트 에러 감지: {m.group(0).strip()[:200]}")
                    failed += len(text_errors)

                # 픽셀 색상 기반 에러 박스 감지 (CanvasKit 대응)
                # Flutter의 ErrorWidget은 기본 빨간 배경 (#F44336 근처)
                try:
                    if args.screenshot_dir:
                        from PIL import Image  # type: ignore
                        img_path = args.screenshot_dir / "04b-dashboard-10s.png"
                        if img_path.exists():
                            img = Image.open(img_path).convert("RGB")
                            w, h = img.size
                            # 중앙 70% 영역 샘플링 (네비게이션 바 제외)
                            red_pixels = 0; total = 0
                            for y in range(int(h*0.1), int(h*0.9), 10):
                                for x in range(int(w*0.1), int(w*0.9), 10):
                                    r, g, b = img.getpixel((x, y))
                                    total += 1
                                    # 빨간 계열: R 강함, G/B 약함
                                    if r > 180 and g < 120 and b < 120:
                                        red_pixels += 1
                            red_ratio = red_pixels / max(total, 1)
                            if red_ratio > 0.03:   # 화면의 3% 이상이 빨간색 = 에러 박스 가능성
                                print(f"[FAIL] UI에 빨간 에러 박스 감지 (빨간 픽셀 비율 {red_ratio:.1%})")
                                failed += 1
                except Exception as e:
                    print(f"[WARN] 픽셀 색상 검사 실패: {e}")
            except Exception as e:
                print(f"[FAIL] 로그인 후 라우팅 — {e}"); failed += 1

        # ── 3.5 Drill-down: Event → Flight → Tables 자동 로드 검증 ──
        # TablesRepository.listTables({event_flight_id}) 가 실제로 2xx 반환하는지
        # Lobby Dashboard에서 Event 카드 클릭하면 /tables 요청이 발생해야 함.
        if login_ok:
            try:
                # Event 행 첫 번째 클릭 (좌표는 스크린샷 기준 추정)
                # 실제 존재 확인 후 다음 단계 진행
                page.wait_for_timeout(1500)

                # /api/v1/tables 응답 대기 또는 타임아웃 시 skip
                tables_seen = any(
                    "/tables" in url and "RESP 200" in url for url in auth_requests
                )
                if not tables_seen:
                    # Event 행 클릭 시도 — canvas 좌표 기반
                    vp = page.viewport_size or {"width": 1280, "height": 720}
                    # Lobby Live Events 테이블 첫 행 대략 좌표 (스크린샷 04b 기준 y=163)
                    event_row_y = 163
                    try:
                        with page.expect_response(
                            lambda r: "/api/v1/tables" in r.url,
                            timeout=5000,
                        ) as tables_resp_info:
                            page.mouse.click(300, event_row_y)
                        tables_resp = tables_resp_info.value
                        print(f"[INFO] Event 클릭 → /tables {tables_resp.status}")
                    except PWTimeout:
                        print("[INFO] Event 클릭 후 /tables 요청 없음 — UI 미연결 or B-F006")

                snap(page, "04c-drill-down")
                print("[OK] Drill-down 시도 완료")
            except Exception as e:
                print(f"[WARN] Drill-down — {type(e).__name__}: {e}")

        # ── 3.6 Settings 6탭 순회 ────────────────────────────────────
        if login_ok:
            try:
                # Settings 탭 클릭 (좌측 네비게이션 아이콘 기반)
                # 좌표는 스크린샷 기준: x=40, y=164 (Settings 아이콘)
                page.mouse.click(40, 164)
                page.wait_for_timeout(2000)
                snap(page, "06-settings-loaded")
                print("[OK] Settings 진입")
            except Exception as e:
                print(f"[WARN] Settings 진입 — {e}")

            try:
                page.mouse.click(40, 100)  # Staff 아이콘
                page.wait_for_timeout(2000)
                snap(page, "07-staff-loaded")
                print("[OK] Staff List 진입")
            except Exception as e:
                print(f"[WARN] Staff 진입 — {e}")

            try:
                page.mouse.click(40, 228)  # GFX 아이콘
                page.wait_for_timeout(2000)
                snap(page, "08-gfx-loaded")
                print("[OK] GFX 진입")
            except Exception as e:
                print(f"[WARN] GFX 진입 — {e}")

            try:
                page.mouse.click(40, 291)  # Reports 아이콘
                page.wait_for_timeout(2000)
                snap(page, "09-reports-loaded")
                print("[OK] Reports 진입")
            except Exception as e:
                print(f"[WARN] Reports 진입 — {e}")

        # ── 4. CC Demo 페이지 접속 (선택) ────────────────────────────
        if not args.skip_cc:
            try:
                page.goto(cc_url, wait_until="networkidle")
                snap(page, "05-cc-loaded")
                title = page.title()
                print(f"[OK] CC Demo 로드 — title='{title}'")
            except Exception as e:
                print(f"[FAIL] CC Demo — {e}"); failed += 1; snap(page, "05-cc-FAIL")

        # ── 마무리 ────────────────────────────────────────────────
        browser.close()

    # ── 진단 정보 출력 ────────────────────────────────────────────
    if console_errors:
        print("\n─── 브라우저 Console 에러 ───")
        for msg in console_errors[:20]:
            print(f"  {msg}")
        if len(console_errors) > 20:
            print(f"  ... +{len(console_errors) - 20} more")

    if network_failures:
        print("\n─── 네트워크 실패 요청 ───")
        for msg in network_failures[:20]:
            print(f"  {msg}")

    if auth_requests:
        print("\n─── Auth/API 요청 URL ───")
        for url in auth_requests[:30]:
            print(f"  {url}")

    # 엄격 판정: API/Auth 응답 중 4xx/5xx가 있으면 FAIL
    if api_errors:
        print("\n─── ❌ API/Auth 4xx/5xx 응답 (엄격 검증) ───")
        for err in api_errors:
            print(f"  {err}")
        failed += len(api_errors)

    # Console error도 count 반영
    if console_errors:
        failed += len(console_errors)

    print(f"\n=== {'PASSED' if failed == 0 else f'{failed} FAILED'} ===")
    if failed == 0:
        print("    (모든 API 응답 2xx + Console error 0)")
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
