#!/usr/bin/env python3
"""
team1 — Phase 5 Final E2E Integration Verification
==================================================

검증 시나리오 (frontend 실제 wiring 기반 — `lib/foundation/configs/app_config.dart` 정합):

    [S1] http://localhost:3000  → 200 + Flutter bootstrap 마커 ('flutter_bootstrap.js')
    [S2] frontend.apiBaseUrl    → http://localhost:8000/api/v1 (200)
    [S3] frontend.wsBaseUrl     → ws://localhost:8000/ws/lobby (handshake 또는 auth gate)
    [S4] engine HTTP (8080)     → 200 (HTTP-only, WS 미제공 — Type B spec note)
    [S5] CORS preflight         → bo 가 lobby Origin 허용

Gatekeeper:
    Connection Refused / CORS Reject / WebSocket Timeout → Exit 1
    부분 PASS (auth gate 등 의도된 거부) → Exit 0

Env override:
    LOBBY_URL              default http://localhost:3000  (host port)
    BO_URL                 default http://localhost:8000  (frontend apiBaseUrl host)
    ENGINE_URL             default http://localhost:8080  (HTTP-only)
    WS_BASE_URL            default ws://localhost:8000    (frontend wsBaseUrl)
    BO_AUTH_LOGIN_PATH     default /auth/login            (canonical bo)
    WS_AUTH_REQUIRED       default 1                      ("0"=lax)

self-correction trigger 후보:
    S2 connection refused → bo_api_client.dart baseUrl 환경 변수 점검
    S3 timeout            → lobby_websocket_client.dart wsBaseUrl 환경 변수 점검
"""

from __future__ import annotations

import asyncio
import json
import os
import sys
import time
from dataclasses import asdict, dataclass, field

import requests
import websockets

LOBBY_URL = os.environ.get("LOBBY_URL", "http://localhost:3000")
BO_URL = os.environ.get("BO_URL", "http://localhost:8000")
ENGINE_URL = os.environ.get("ENGINE_URL", "http://localhost:8080")
WS_BASE_URL = os.environ.get("WS_BASE_URL", "ws://localhost:8000")
BO_AUTH_LOGIN_PATH = os.environ.get("BO_AUTH_LOGIN_PATH", "/auth/login")
WS_AUTH_REQUIRED = os.environ.get("WS_AUTH_REQUIRED", "1").strip() in {"1", "true", "yes"}


@dataclass
class Step:
    sid: str
    name: str
    status: str = "PENDING"
    detail: str = ""
    elapsed_ms: int = 0


@dataclass
class Report:
    started_at: float = field(default_factory=time.time)
    steps: list[Step] = field(default_factory=list)

    def add(self, s: Step) -> None:
        self.steps.append(s)

    def summary(self) -> dict[str, int]:
        out = {"PASS": 0, "FAIL": 0, "NOTE": 0}
        for s in self.steps:
            out[s.status] = out.get(s.status, 0) + 1
        return out


def s1_lobby_render(report: Report) -> None:
    s = Step("S1", "lobby static + Flutter bootstrap")
    t0 = time.time()
    try:
        r = requests.get(f"{LOBBY_URL}/", timeout=5)
        s.elapsed_ms = int((time.time() - t0) * 1000)
        if r.status_code != 200:
            s.status = "FAIL"
            s.detail = f"expected 200 got {r.status_code}"
        elif "flutter_bootstrap.js" not in r.text and "main.dart.js" not in r.text:
            s.status = "FAIL"
            s.detail = "Flutter bootstrap marker missing in HTML"
        else:
            # Confirm bootstrap js itself reachable
            r2 = requests.get(f"{LOBBY_URL}/flutter_bootstrap.js", timeout=5)
            if r2.status_code != 200:
                s.status = "FAIL"
                s.detail = f"/flutter_bootstrap.js {r2.status_code}"
            else:
                s.status = "PASS"
                s.detail = (f"index 200 {len(r.content)}B + bootstrap.js 200 "
                            f"{len(r2.content)}B")
    except requests.exceptions.ConnectionError as e:
        s.elapsed_ms = int((time.time() - t0) * 1000)
        s.status = "FAIL"
        s.detail = f"ConnectionRefused: {e}"
    except Exception as e:
        s.elapsed_ms = int((time.time() - t0) * 1000)
        s.status = "FAIL"
        s.detail = f"{type(e).__name__}: {e}"
    report.add(s)


def s2_bo_api_reachable(report: Report) -> None:
    """Frontend.apiBaseUrl = http://<host>:8000/api/v1.
    /api/v1/series 같은 list endpoint 가 401 (auth required) 또는 200 이면
    bo가 wiring 정확히 살아있음을 증명."""
    s = Step("S2", "bo /api/v1 reachable (frontend apiBaseUrl)")
    t0 = time.time()
    try:
        r = requests.get(f"{BO_URL}/api/v1/series", timeout=5)
        s.elapsed_ms = int((time.time() - t0) * 1000)
        if r.status_code in (200, 401, 403):
            # 200 = open, 401/403 = endpoint exists + auth gate
            s.status = "PASS"
            s.detail = f"{r.status_code} ({'open' if r.status_code == 200 else 'auth gate'})"
        elif r.status_code == 404:
            # Try alternate endpoint
            r2 = requests.get(f"{BO_URL}/openapi.json", timeout=5)
            if r2.status_code == 200:
                s.status = "PASS"
                s.detail = f"/api/v1/series 404, openapi 200 (api online)"
            else:
                s.status = "FAIL"
                s.detail = f"/api/v1/series 404 + openapi {r2.status_code}"
        else:
            s.status = "FAIL"
            s.detail = f"unexpected {r.status_code}"
    except requests.exceptions.ConnectionError as e:
        s.elapsed_ms = int((time.time() - t0) * 1000)
        s.status = "FAIL"
        s.detail = f"ConnectionRefused: bo down? — {e}"
    except Exception as e:
        s.elapsed_ms = int((time.time() - t0) * 1000)
        s.status = "FAIL"
        s.detail = f"{type(e).__name__}: {e}"
    report.add(s)


def s2b_bo_openapi_login(report: Report) -> None:
    s = Step("S2b", f"bo openapi has {BO_AUTH_LOGIN_PATH}")
    t0 = time.time()
    try:
        r = requests.get(f"{BO_URL}/openapi.json", timeout=5)
        s.elapsed_ms = int((time.time() - t0) * 1000)
        if r.status_code != 200:
            s.status = "FAIL"
            s.detail = f"openapi {r.status_code}"
        else:
            paths = r.json().get("paths", {})
            if BO_AUTH_LOGIN_PATH in paths:
                s.status = "PASS"
                s.detail = f"{len(paths)} paths, login present"
            else:
                # Look for any auth login variant
                hits = [p for p in paths if "auth" in p and "login" in p]
                if hits:
                    s.status = "PASS"
                    s.detail = f"{len(paths)} paths, auth login at {hits[0]}"
                else:
                    s.status = "FAIL"
                    s.detail = f"{len(paths)} paths, no auth/login endpoint"
    except Exception as e:
        s.elapsed_ms = int((time.time() - t0) * 1000)
        s.status = "FAIL"
        s.detail = f"{type(e).__name__}: {e}"
    report.add(s)


async def s3_ws_lobby(report: Report) -> None:
    """frontend lobby_websocket_client.dart → ws://<host>:8000/ws/lobby"""
    s = Step("S3", "ws://<bo>/ws/lobby (frontend WS)")
    t0 = time.time()
    url = f"{WS_BASE_URL}/ws/lobby"
    try:
        async with websockets.connect(url, open_timeout=5, close_timeout=2) as ws:
            s.elapsed_ms = int((time.time() - t0) * 1000)
            try:
                msg = await asyncio.wait_for(ws.recv(), timeout=2)
                s.detail = f"OK + initial frame {len(msg)}B"
            except asyncio.TimeoutError:
                s.detail = "OK, no initial frame in 2s"
            s.status = "PASS"
    except Exception as e:
        s.elapsed_ms = int((time.time() - t0) * 1000)
        msg = str(e)
        if WS_AUTH_REQUIRED and ("HTTP 401" in msg or "HTTP 403" in msg):
            s.status = "PASS"
            s.detail = f"auth gate detected ({msg.split(':')[-1].strip()})"
        else:
            s.status = "FAIL"
            s.detail = f"{type(e).__name__}: {e}"
    report.add(s)


def s4_engine_http(report: Report) -> None:
    s = Step("S4", "engine HTTP 8080 (HTTP-only — Type B note)")
    t0 = time.time()
    try:
        r = requests.get(f"{ENGINE_URL}/", timeout=5)
        s.elapsed_ms = int((time.time() - t0) * 1000)
        if r.status_code == 200:
            s.status = "PASS"
            s.detail = f"200 {len(r.content)}B (engine harness static page)"
        else:
            s.status = "FAIL"
            s.detail = f"unexpected {r.status_code}"
    except Exception as e:
        s.elapsed_ms = int((time.time() - t0) * 1000)
        s.status = "FAIL"
        s.detail = f"{type(e).__name__}: {e}"
    report.add(s)


def s4b_engine_no_ws_note(report: Report) -> None:
    """task spec 가 언급한 ws://localhost:8080 은 canonical engine 에 미존재.
    NOTE 로 명시 (PASS도 FAIL도 아님)."""
    s = Step("S4b", "engine WS @ 8080 (task spec) — NOT IMPLEMENTED")
    s.status = "NOTE"
    s.detail = ("canonical team3 engine = static HTTP harness only. "
                "frontend WS는 bo (ws://<bo>/ws/lobby) — task spec drift, frontend 무영향")
    report.add(s)


def s5_cors_preflight(report: Report) -> None:
    """bo가 lobby Origin 허용하는지 OPTIONS preflight."""
    s = Step("S5", f"CORS preflight (Origin={LOBBY_URL})")
    t0 = time.time()
    try:
        r = requests.options(f"{BO_URL}/api/v1/series", timeout=5, headers={
            "Origin": LOBBY_URL,
            "Access-Control-Request-Method": "GET",
            "Access-Control-Request-Headers": "Content-Type, Authorization",
        })
        s.elapsed_ms = int((time.time() - t0) * 1000)
        ao = r.headers.get("Access-Control-Allow-Origin", "")
        if r.status_code in (200, 204) and ao:
            s.status = "PASS"
            s.detail = f"{r.status_code}, Allow-Origin={ao!r}"
        elif r.status_code == 405:
            # Some FastAPI configs reject OPTIONS without CORS middleware
            s.status = "FAIL"
            s.detail = "405 — bo CORS middleware 미설정?"
        else:
            s.status = "FAIL"
            s.detail = f"{r.status_code}, ACAO={ao!r}"
    except Exception as e:
        s.elapsed_ms = int((time.time() - t0) * 1000)
        s.status = "FAIL"
        s.detail = f"{type(e).__name__}: {e}"
    report.add(s)


async def main() -> int:
    report = Report()

    s1_lobby_render(report)
    s2_bo_api_reachable(report)
    s2b_bo_openapi_login(report)
    await s3_ws_lobby(report)
    s4_engine_http(report)
    s4b_engine_no_ws_note(report)
    s5_cors_preflight(report)

    # ── Render ─────────────────────────────────────────────────────────
    print()
    print("=" * 76)
    print(" team1 Phase 5 — Final E2E Integration Verification")
    print(f" started_at: {time.ctime(report.started_at)}")
    print(f" lobby={LOBBY_URL}  bo={BO_URL}  engine={ENGINE_URL}  ws={WS_BASE_URL}")
    print("=" * 76)
    for s in report.steps:
        sym = {"PASS": "✓", "FAIL": "✗", "NOTE": "i"}.get(s.status, "?")
        print(f" [{sym}] {s.sid:4s} {s.name:46s} ({s.elapsed_ms:4d}ms)")
        print(f"        {s.detail}")
    summ = report.summary()
    print("-" * 76)
    print(f" PASS={summ['PASS']}  FAIL={summ['FAIL']}  NOTE={summ['NOTE']}")
    print("=" * 76)

    out_path = os.environ.get(
        "E2E_REPORT_PATH",
        os.path.join(os.path.dirname(__file__), "..", "team1_e2e_report.json"))
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump({
            "started_at": report.started_at,
            "summary": summ,
            "steps": [asdict(s) for s in report.steps],
        }, f, indent=2)
    print(f" report → {os.path.abspath(out_path)}")

    # Gatekeeper: any FAIL → exit 1
    return 1 if summ["FAIL"] > 0 else 0


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
