"""E2E happy path verifier — Lobby login → launch-cc → WS /ws/cc connect → engine probe.

Phase 1 deliverable evidence (per Workflow_Conductor_Autonomous SOP).

Usage:
  python tools/e2e_lobby_to_cc_ws.py
"""
from __future__ import annotations

import asyncio
import json
import os
import sys
import urllib.parse
import uuid

import httpx
import websockets


BO = os.environ.get("BO_URL", "http://localhost:8000")
ENGINE = os.environ.get("ENGINE_URL", "http://localhost:8080")
ADMIN_EMAIL = os.environ.get("EBS_ADMIN_EMAIL", "admin@ebs.local")
ADMIN_PWD = os.environ.get("EBS_ADMIN_PWD", "admin123")


def step(label: str, ok: bool, detail: str = "") -> None:
    icon = "PASS" if ok else "FAIL"
    print(f"[{icon}] {label}" + (f"  — {detail}" if detail else ""))


async def main() -> int:
    failures = 0

    async with httpx.AsyncClient(timeout=10.0) as c:
        # ── 1. Login
        r = await c.post(
            f"{BO}/auth/login",
            json={"email": ADMIN_EMAIL, "password": ADMIN_PWD},
        )
        ok = r.status_code == 200 and "accessToken" in r.json().get("data", {})
        step("1. POST /auth/login", ok, f"http={r.status_code}")
        if not ok:
            return 1
        token = r.json()["data"]["accessToken"]
        H = {"Authorization": f"Bearer {token}"}

        # ── 2. Series drill-down
        r = await c.get(f"{BO}/api/v1/series", headers=H)
        ok = r.status_code == 200 and len(r.json().get("data", [])) > 0
        step("2. GET /api/v1/series", ok, f"count={len(r.json().get('data', []))}")
        failures += 0 if ok else 1
        series_id = r.json()["data"][0]["seriesId"] if ok else None

        # ── 3. Events
        r = await c.get(f"{BO}/api/v1/events", headers=H)
        ok = r.status_code == 200 and len(r.json().get("data", [])) > 0
        step("3. GET /api/v1/events", ok, f"count={len(r.json().get('data', []))}")
        failures += 0 if ok else 1

        # ── 4. Flights
        r = await c.get(f"{BO}/api/v1/flights", headers=H)
        ok = r.status_code == 200 and len(r.json().get("data", [])) > 0
        step("4. GET /api/v1/flights", ok, f"count={len(r.json().get('data', []))}")
        failures += 0 if ok else 1

        # ── 5. Tables
        r = await c.get(f"{BO}/api/v1/tables", headers=H)
        ok = r.status_code == 200 and len(r.json().get("data", [])) > 0
        step("5. GET /api/v1/tables", ok, f"count={len(r.json().get('data', []))}")
        failures += 0 if ok else 1
        table_id = r.json()["data"][0]["tableId"] if ok else 1

        # ── 6. POST /tables/{id}/launch-cc
        r = await c.post(
            f"{BO}/api/v1/tables/{table_id}/launch-cc",
            headers={**H, "Idempotency-Key": str(uuid.uuid4())},
            json={},
        )
        ok = r.status_code == 200 and "launch_token" in r.json().get("data", {})
        step(f"6. POST /tables/{table_id}/launch-cc", ok, f"http={r.status_code}")
        failures += 0 if ok else 1
        if not ok:
            return failures
        launch = r.json()["data"]
        # Verify response shape
        required_keys = {"table_id", "launch_token", "ws_url", "cc_instance_id",
                         "cc_url", "deep_link"}
        ok = required_keys.issubset(launch.keys())
        step("7. launch-cc response shape", ok,
             f"missing={required_keys - launch.keys() if not ok else 'none'}")
        failures += 0 if ok else 1

        # ── 8. WS /ws/cc connect
        # ws_url 이 "ws://localhost:8000/ws/cc?table_id=X" — token은 아직 미부여
        # 실제 인증된 연결을 위해 token + cc_instance_id 추가
        ws_url = (
            f"ws://localhost:8000/ws/cc"
            f"?table_id={table_id}"
            f"&token={urllib.parse.quote(launch['launch_token'])}"
            f"&cc_instance_id={launch['cc_instance_id']}"
        )
        try:
            async with websockets.connect(ws_url, open_timeout=5.0) as ws:
                # 첫 메시지 수신 시도 (3초 timeout)
                try:
                    msg = await asyncio.wait_for(ws.recv(), timeout=3.0)
                    parsed = json.loads(msg) if isinstance(msg, str) else msg
                    msg_type = parsed.get("type", "?") if isinstance(parsed, dict) else "?"
                    step("8. WS /ws/cc connect + initial msg", True,
                         f"type={msg_type}")
                except asyncio.TimeoutError:
                    # 연결은 되었으나 초기 메시지 없음 (CC가 send 시작점일 수 있음)
                    step("8. WS /ws/cc connect (no auto-msg)", True,
                         "connection accepted, no auto-push (acceptable)")
        except Exception as e:
            step("8. WS /ws/cc connect", False, f"err={type(e).__name__}: {e}")
            failures += 1

        # ── 9. Engine probe
        r = await c.get(f"{ENGINE}/health")
        ok = r.status_code == 200 and r.json().get("status") == "ok"
        step("9. GET engine /health", ok, f"http={r.status_code}")
        failures += 0 if ok else 1

    print()
    print(f"Total: {failures} failure(s)")
    return failures


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
