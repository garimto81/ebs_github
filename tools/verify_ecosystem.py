#!/usr/bin/env python3
"""verify_ecosystem.py — EBS Multi-Service Docker E2E smoke validation.

작업 단위: docker compose --profile web up -d 로 기동된 5개 서비스에 대해
host 측에서 실제 endpoint 를 호출하여 healthy 상태를 검증한다.

검증 대상 (SG-022 폐기 cascade 후 SSOT):
  • bo         (team2)   :8000 /health           — FastAPI Backend
  • engine     (team3)   :8080 /engine/health    — Dart Harness (B-331)
  • lobby-web  (team1)   :3000 /healthz          — Flutter Web (profile web)
  • cc-web     (team4)   :3001 /healthz          — Flutter Web (profile web)
  • bo (WS)    :8000 /ws/lobby                   — WebSocket upgrade handshake

Exit codes:
  0  — 모든 서비스 정상 (Gatekeeper PASS)
  1  — 하나 이상 실패 (Gatekeeper FAIL → docker compose logs 분석 + 자가 치유 트리거)
  2  — 사용자 입력 오류 (--help 등)

Stdlib only — pip install 불필요.
"""
from __future__ import annotations

import argparse
import base64
import json
import os
import socket
import sys
import time
import urllib.error
import urllib.request
from dataclasses import dataclass
from typing import Optional


@dataclass(frozen=True)
class HttpCheck:
    name: str
    url: str
    expect_status: int = 200
    timeout_s: float = 5.0


@dataclass(frozen=True)
class WsCheck:
    name: str
    host: str
    port: int
    path: str
    timeout_s: float = 5.0


@dataclass
class CheckResult:
    name: str
    kind: str  # "http" | "ws"
    target: str
    ok: bool
    status: Optional[int] = None
    detail: str = ""
    elapsed_ms: float = 0.0
    body_excerpt: str = ""


CHECKS_HTTP: list[HttpCheck] = [
    HttpCheck("bo",        "http://localhost:8000/health"),
    HttpCheck("engine",    "http://localhost:8080/engine/health"),
    HttpCheck("lobby-web", "http://localhost:3000/healthz"),
    HttpCheck("cc-web",    "http://localhost:3001/healthz"),
]

CHECKS_WS: list[WsCheck] = [
    WsCheck("bo-ws-lobby", "localhost", 8000, "/ws/lobby"),
]


def http_check(check: HttpCheck) -> CheckResult:
    started = time.monotonic()
    req = urllib.request.Request(check.url, method="GET",
                                 headers={"User-Agent": "ebs-verify-ecosystem/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=check.timeout_s) as resp:
            elapsed_ms = (time.monotonic() - started) * 1000
            body = resp.read(2048)
            body_text = body.decode("utf-8", errors="replace")
            ok = resp.status == check.expect_status
            return CheckResult(
                name=check.name, kind="http", target=check.url, ok=ok,
                status=resp.status,
                detail=("OK" if ok else f"unexpected status {resp.status}"),
                elapsed_ms=elapsed_ms,
                body_excerpt=body_text[:200].replace("\n", " "),
            )
    except urllib.error.HTTPError as e:
        elapsed_ms = (time.monotonic() - started) * 1000
        body_text = ""
        try:
            body_text = e.read(512).decode("utf-8", errors="replace")
        except Exception:
            pass
        ok = e.code == check.expect_status
        return CheckResult(
            name=check.name, kind="http", target=check.url, ok=ok,
            status=e.code,
            detail=("OK" if ok else f"HTTP {e.code}: {e.reason}"),
            elapsed_ms=elapsed_ms,
            body_excerpt=body_text[:200].replace("\n", " "),
        )
    except urllib.error.URLError as e:
        elapsed_ms = (time.monotonic() - started) * 1000
        return CheckResult(
            name=check.name, kind="http", target=check.url, ok=False,
            detail=f"URLError: {e.reason}",
            elapsed_ms=elapsed_ms,
        )
    except (TimeoutError, socket.timeout):
        elapsed_ms = (time.monotonic() - started) * 1000
        return CheckResult(
            name=check.name, kind="http", target=check.url, ok=False,
            detail=f"timeout after {check.timeout_s}s",
            elapsed_ms=elapsed_ms,
        )
    except Exception as e:
        elapsed_ms = (time.monotonic() - started) * 1000
        return CheckResult(
            name=check.name, kind="http", target=check.url, ok=False,
            detail=f"{type(e).__name__}: {e}",
            elapsed_ms=elapsed_ms,
        )


def ws_handshake(check: WsCheck) -> CheckResult:
    """Raw WebSocket upgrade handshake — RFC 6455 §4.1.

    101 Switching Protocols 응답을 받으면 OK. 그 외 (404, 403, connection refused) FAIL.
    """
    target = f"ws://{check.host}:{check.port}{check.path}"
    started = time.monotonic()
    sock: Optional[socket.socket] = None
    try:
        sock = socket.create_connection((check.host, check.port), timeout=check.timeout_s)
        sock.settimeout(check.timeout_s)
        key = base64.b64encode(os.urandom(16)).decode("ascii")
        request = (
            f"GET {check.path} HTTP/1.1\r\n"
            f"Host: {check.host}:{check.port}\r\n"
            f"Upgrade: websocket\r\n"
            f"Connection: Upgrade\r\n"
            f"Sec-WebSocket-Key: {key}\r\n"
            f"Sec-WebSocket-Version: 13\r\n"
            f"User-Agent: ebs-verify-ecosystem/1.0\r\n"
            f"\r\n"
        )
        sock.sendall(request.encode("ascii"))
        raw = b""
        while b"\r\n\r\n" not in raw and len(raw) < 4096:
            chunk = sock.recv(1024)
            if not chunk:
                break
            raw += chunk
        elapsed_ms = (time.monotonic() - started) * 1000
        head = raw.split(b"\r\n\r\n", 1)[0].decode("latin1", errors="replace")
        first_line = head.split("\r\n", 1)[0] if head else ""
        ok = first_line.startswith("HTTP/1.1 101")
        return CheckResult(
            name=check.name, kind="ws", target=target, ok=ok,
            status=int(first_line.split()[1]) if first_line and first_line.split()[1:2] and first_line.split()[1].isdigit() else None,
            detail=("OK (101 Switching Protocols)" if ok else f"unexpected: {first_line[:120]}"),
            elapsed_ms=elapsed_ms,
            body_excerpt=first_line[:200],
        )
    except (ConnectionRefusedError, OSError) as e:
        elapsed_ms = (time.monotonic() - started) * 1000
        return CheckResult(
            name=check.name, kind="ws", target=target, ok=False,
            detail=f"{type(e).__name__}: {e}",
            elapsed_ms=elapsed_ms,
        )
    except Exception as e:
        elapsed_ms = (time.monotonic() - started) * 1000
        return CheckResult(
            name=check.name, kind="ws", target=target, ok=False,
            detail=f"{type(e).__name__}: {e}",
            elapsed_ms=elapsed_ms,
        )
    finally:
        if sock is not None:
            try:
                sock.close()
            except Exception:
                pass


def run_all(retries: int, retry_delay_s: float) -> tuple[list[CheckResult], int]:
    results: list[CheckResult] = []
    failed_count = 0

    for chk in CHECKS_HTTP:
        last: CheckResult = http_check(chk)
        for attempt in range(retries):
            if last.ok:
                break
            time.sleep(retry_delay_s)
            last = http_check(chk)
        results.append(last)
        if not last.ok:
            failed_count += 1

    for wschk in CHECKS_WS:
        last2: CheckResult = ws_handshake(wschk)
        for attempt in range(retries):
            if last2.ok:
                break
            time.sleep(retry_delay_s)
            last2 = ws_handshake(wschk)
        results.append(last2)
        if not last2.ok:
            failed_count += 1

    return results, failed_count


def render_table(results: list[CheckResult]) -> str:
    headers = ["service", "kind", "status", "elapsed_ms", "result", "detail"]
    rows = [headers]
    for r in results:
        rows.append([
            r.name,
            r.kind,
            str(r.status) if r.status is not None else "-",
            f"{r.elapsed_ms:.1f}",
            "PASS" if r.ok else "FAIL",
            r.detail[:60],
        ])
    widths = [max(len(row[i]) for row in rows) for i in range(len(headers))]
    out_lines = []
    for idx, row in enumerate(rows):
        line = "  ".join(cell.ljust(widths[i]) for i, cell in enumerate(row))
        out_lines.append(line)
        if idx == 0:
            out_lines.append("  ".join("-" * w for w in widths))
    return "\n".join(out_lines)


def main(argv: Optional[list[str]] = None) -> int:
    ap = argparse.ArgumentParser(
        prog="verify_ecosystem.py",
        description="EBS Multi-Service Docker E2E smoke validation",
    )
    ap.add_argument("--retries", type=int, default=3,
                    help="실패한 check 재시도 횟수 (default: 3)")
    ap.add_argument("--retry-delay", type=float, default=2.0,
                    help="재시도 간 대기 (s, default: 2.0)")
    ap.add_argument("--json", dest="as_json", action="store_true",
                    help="JSON 출력 (CI/agent 소비)")
    args = ap.parse_args(argv)

    print("=" * 78)
    print("EBS Multi-Service Docker E2E Smoke Validation")
    print(f"  HTTP checks: {len(CHECKS_HTTP)}  |  WS checks: {len(CHECKS_WS)}  |  retries: {args.retries}")
    print("=" * 78)

    results, failed = run_all(args.retries, args.retry_delay)

    if args.as_json:
        payload = {
            "ok": failed == 0,
            "failed_count": failed,
            "total": len(results),
            "results": [
                {
                    "name": r.name, "kind": r.kind, "target": r.target,
                    "ok": r.ok, "status": r.status, "detail": r.detail,
                    "elapsed_ms": r.elapsed_ms, "body_excerpt": r.body_excerpt,
                }
                for r in results
            ],
        }
        print(json.dumps(payload, indent=2, ensure_ascii=False))
    else:
        print(render_table(results))
        print()
        for r in results:
            if r.body_excerpt:
                print(f"  [{r.name}] body: {r.body_excerpt}")

    print()
    if failed == 0:
        print(f"GATEKEEPER PASS — {len(results)}/{len(results)} services healthy.")
        return 0
    else:
        print(f"GATEKEEPER FAIL — {failed}/{len(results)} services unhealthy.")
        print("Self-correction trigger: run `docker compose logs <service>` for failing services.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
