#!/usr/bin/env python3
"""
team1 E2E Harness Validation
=============================

Multi-Service Docker (SG-022 폐기) 환경 검증:
    Lobby Web (team1)  :: http://localhost:3001  (or 3000)
    Backend (team2)    :: http://localhost:8000
    Engine (team3)     :: http://localhost:8080
    WebSocket (team2)  :: ws://localhost:8000/ws/{lobby,cc}

3-tier validation:
    L1 — HTTP probes        (requests 동기)
    L2 — WebSocket handshake (asyncio + websockets)
    L3 — Headless DOM       (Playwright Chromium, optional)

Exit code:
    0  ALL PASS
    1  Critical FAIL  (lobby down 등)
    2  Partial PASS   (일부 PASS, 일부 FAIL)

Env override:
    LOBBY_URL                default http://localhost:3001
    BO_URL                   default http://localhost:8000
    BO_AUTH_LOGIN_PATH       default /api/v1/auth/login  (canonical bo: /auth/login)
    ENGINE_URL               default http://localhost:8080
    ENGINE_HEALTH_PATH       default /health  (canonical engine: /)
    WS_BASE_URL              default ws://localhost:8000
    WS_AUTH_REQUIRED         "1" → 403 handshake 도 PASS (auth gate present)
    SKIP_PLAYWRIGHT          "1" → L3 스킵
"""

from __future__ import annotations

import asyncio
import json
import os
import sys
import time
from dataclasses import asdict, dataclass, field
from typing import Any

import requests
import websockets

LOBBY_URL = os.environ.get("LOBBY_URL", "http://localhost:3001")
BO_URL = os.environ.get("BO_URL", "http://localhost:8000")
BO_AUTH_LOGIN_PATH = os.environ.get("BO_AUTH_LOGIN_PATH", "/api/v1/auth/login")
ENGINE_URL = os.environ.get("ENGINE_URL", "http://localhost:8080")
ENGINE_HEALTH_PATH = os.environ.get("ENGINE_HEALTH_PATH", "/health")
WS_BASE_URL = os.environ.get("WS_BASE_URL", "ws://localhost:8000")
WS_AUTH_REQUIRED = os.environ.get("WS_AUTH_REQUIRED", "").strip() in {"1", "true", "yes"}
SKIP_PLAYWRIGHT = os.environ.get("SKIP_PLAYWRIGHT", "").strip() in {"1", "true", "yes"}


@dataclass
class Check:
    name: str
    tier: str
    target: str
    status: str = "PENDING"
    detail: str = ""
    elapsed_ms: int = 0


@dataclass
class Report:
    started_at: float = field(default_factory=time.time)
    checks: list[Check] = field(default_factory=list)

    def add(self, c: Check) -> None:
        self.checks.append(c)

    def summary(self) -> dict[str, int]:
        out = {"PASS": 0, "FAIL": 0, "SKIP": 0}
        for c in self.checks:
            out[c.status] = out.get(c.status, 0) + 1
        return out


def _probe(name: str, tier: str, url: str, expect_status: int = 200,
           contains: str | None = None, json_path: list[str] | None = None) -> Check:
    c = Check(name=name, tier=tier, target=url)
    t0 = time.time()
    try:
        r = requests.get(url, timeout=5)
        c.elapsed_ms = int((time.time() - t0) * 1000)
        if r.status_code != expect_status:
            c.status = "FAIL"
            c.detail = f"expected {expect_status} got {r.status_code}"
            return c
        if contains and contains not in r.text:
            c.status = "FAIL"
            c.detail = f"body missing '{contains}' (first 200ch: {r.text[:200]!r})"
            return c
        if json_path:
            payload = r.json()
            cur: Any = payload
            for k in json_path:
                if isinstance(cur, dict) and k in cur:
                    cur = cur[k]
                else:
                    c.status = "FAIL"
                    c.detail = f"json path {json_path} missing at '{k}'"
                    return c
        c.status = "PASS"
        c.detail = f"{r.status_code} {len(r.content)}B"
        return c
    except Exception as e:
        c.elapsed_ms = int((time.time() - t0) * 1000)
        c.status = "FAIL"
        c.detail = f"{type(e).__name__}: {e}"
        return c


async def _ws_probe(name: str, url: str) -> Check:
    c = Check(name=name, tier="L2", target=url)
    t0 = time.time()
    try:
        async with websockets.connect(url, open_timeout=5, close_timeout=2) as ws:
            c.elapsed_ms = int((time.time() - t0) * 1000)
            try:
                msg = await asyncio.wait_for(ws.recv(), timeout=2)
                c.detail = f"handshake OK, first msg {len(msg)}B"
            except asyncio.TimeoutError:
                c.detail = "handshake OK, no initial frame in 2s"
            c.status = "PASS"
            return c
    except Exception as e:
        c.elapsed_ms = int((time.time() - t0) * 1000)
        # WS_AUTH_REQUIRED=1 환경: HTTP 401/403 = endpoint 존재 + auth gate 정상
        # → "auth gate detected" 로 PASS 처리 (canonical bo 의 보안 정책 반영)
        msg = str(e)
        if WS_AUTH_REQUIRED and ("HTTP 401" in msg or "HTTP 403" in msg):
            c.status = "PASS"
            c.detail = f"auth gate detected ({msg.split(':')[-1].strip()})"
            return c
        c.status = "FAIL"
        c.detail = f"{type(e).__name__}: {e}"
        return c


async def _l3_playwright(report: Report) -> None:
    """Headless Chromium으로 lobby-web 마운트 + console error 검사."""
    if SKIP_PLAYWRIGHT:
        report.add(Check(name="l3.playwright_skip", tier="L3",
                         target=LOBBY_URL, status="SKIP",
                         detail="SKIP_PLAYWRIGHT=1"))
        return
    try:
        from playwright.async_api import async_playwright
    except ImportError:
        report.add(Check(name="l3.playwright_import", tier="L3",
                         target=LOBBY_URL, status="SKIP",
                         detail="playwright not installed"))
        return

    c = Check(name="l3.lobby_dom_render", tier="L3", target=LOBBY_URL)
    t0 = time.time()
    console_errors: list[str] = []
    network_failures: list[str] = []
    try:
        async with async_playwright() as p:
            browser = await p.chromium.launch(headless=True)
            ctx = await browser.new_context()
            page = await ctx.new_page()

            page.on("console", lambda m: console_errors.append(m.text)
                    if m.type == "error" else None)
            page.on("requestfailed",
                    lambda req: network_failures.append(
                        f"{req.method} {req.url} :: {req.failure}"))

            resp = await page.goto(LOBBY_URL, wait_until="domcontentloaded",
                                   timeout=15000)
            await page.wait_for_timeout(2500)  # Flutter bootstrap settle
            title = await page.title()
            html_head = (await page.content())[:500]
            await browser.close()

        c.elapsed_ms = int((time.time() - t0) * 1000)
        if resp is None or resp.status != 200:
            c.status = "FAIL"
            c.detail = f"navigation status={resp.status if resp else 'none'}"
        elif console_errors:
            c.status = "FAIL"
            c.detail = (f"console errors ({len(console_errors)}): "
                        f"{console_errors[:3]}")
        else:
            c.status = "PASS"
            c.detail = (f"title={title!r}, "
                        f"net_failures={len(network_failures)}, "
                        f"head_len={len(html_head)}")
    except Exception as e:
        c.elapsed_ms = int((time.time() - t0) * 1000)
        c.status = "FAIL"
        c.detail = f"{type(e).__name__}: {e}"

    report.add(c)


async def main() -> int:
    report = Report()

    # ─── L1 HTTP probes ────────────────────────────────────────────────
    report.add(_probe("l1.lobby_root", "L1", f"{LOBBY_URL}/"))
    report.add(_probe("l1.lobby_healthz", "L1", f"{LOBBY_URL}/healthz",
                      contains="ok"))
    report.add(_probe("l1.bo_health", "L1", f"{BO_URL}/health"))
    report.add(_probe("l1.bo_openapi", "L1", f"{BO_URL}/openapi.json",
                      json_path=["paths", BO_AUTH_LOGIN_PATH]))
    report.add(_probe("l1.engine_health", "L1", f"{ENGINE_URL}{ENGINE_HEALTH_PATH}"))

    # ─── L2 WebSocket handshakes ───────────────────────────────────────
    report.add(await _ws_probe("l2.ws_lobby", f"{WS_BASE_URL}/ws/lobby"))
    report.add(await _ws_probe("l2.ws_cc", f"{WS_BASE_URL}/ws/cc"))

    # ─── L3 Headless DOM ───────────────────────────────────────────────
    await _l3_playwright(report)

    # ─── Render output ─────────────────────────────────────────────────
    print()
    print("=" * 70)
    print(" team1 E2E Harness Validation")
    print(f" started_at: {time.ctime(report.started_at)}")
    print(f" targets: lobby={LOBBY_URL} bo={BO_URL} engine={ENGINE_URL}")
    print(f"          ws_base={WS_BASE_URL}")
    print("=" * 70)
    for c in report.checks:
        sym = {"PASS": "✓", "FAIL": "✗", "SKIP": "─"}.get(c.status, "?")
        print(f" [{sym}] {c.tier} {c.name:30s} "
              f"({c.elapsed_ms:4d}ms) {c.detail}")
    s = report.summary()
    print("-" * 70)
    print(f" PASS={s['PASS']}  FAIL={s['FAIL']}  SKIP={s['SKIP']}")
    print("=" * 70)

    # JSON sidecar
    out_path = os.environ.get(
        "HARNESS_REPORT_PATH",
        os.path.join(os.path.dirname(__file__), "..", "harness_report.json"))
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump({
            "started_at": report.started_at,
            "summary": s,
            "checks": [asdict(c) for c in report.checks],
        }, f, indent=2)
    print(f" report → {os.path.abspath(out_path)}")

    # ─── Exit code ─────────────────────────────────────────────────────
    if s["FAIL"] == 0:
        return 0
    # Critical = lobby down
    critical = any(c.status == "FAIL" and c.name.startswith("l1.lobby")
                   for c in report.checks)
    return 1 if critical else 2


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
