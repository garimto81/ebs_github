#!/usr/bin/env python3
"""verify_ecosystem.py — EBS Multi-Service Docker E2E smoke validation.

Run #3 refactor (2026-04-27):
  • Gap 4 (port collision): find_free_port(preferred) 자동 할당 + .env.runtime 작성
  • Gap 3 (WS auth 403):     /health/ws 엔드포인트 사용 (BO 미인증 health probe)
  • 환경 변수 동적 매핑:       EBS_{BO,ENGINE,LOBBY,CC}_HOST_PORT 읽어 probe URL 구성

작업 단위:
  1) (선택) `python verify_ecosystem.py --allocate-ports` 로 .env.runtime 생성
  2) `docker compose --env-file .env.runtime --profile web up -d`
  3) `python verify_ecosystem.py --env-file .env.runtime` 로 검증
  4) `docker compose --env-file .env.runtime --profile web down -v`

검증 대상:
  • bo         (team2)   :{EBS_BO_HOST_PORT}/health           — FastAPI Backend
  • engine     (team3)   :{EBS_ENGINE_HOST_PORT}/engine/health — Dart Harness (B-331)
  • lobby-web  (team1)   :{EBS_LOBBY_HOST_PORT}/healthz        — Flutter Web
  • cc-web     (team4)   :{EBS_CC_HOST_PORT}/healthz           — Flutter Web
  • bo (WS)    :{EBS_BO_HOST_PORT}/health/ws                   — auth-free WS upgrade

Exit codes:
  0  — 모든 서비스 정상 (Gatekeeper PASS)
  1  — 하나 이상 실패 (Gatekeeper FAIL)
  2  — 사용자 입력 오류

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
from pathlib import Path
from typing import Optional


# --- Port allocation -------------------------------------------------------

DEFAULT_PORTS = {
    "EBS_BO_HOST_PORT": 8000,
    "EBS_ENGINE_HOST_PORT": 8080,
    "EBS_LOBBY_HOST_PORT": 3000,
    "EBS_CC_HOST_PORT": 3001,
}


def find_free_port(preferred_port: int) -> int:
    """Return preferred_port if free, else find any free ephemeral port.

    Gap 4 fix — 호스트의 외부 프로세스 (e.g. node.exe :3000) 점유 충돌 회피.
    검사: 0.0.0.0 으로 bind 가능해야 docker compose 도 publish 가능.
    """
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            s.bind(("0.0.0.0", preferred_port))
            return preferred_port
    except OSError:
        pass

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(("0.0.0.0", 0))
        return s.getsockname()[1]


def allocate_ports() -> dict[str, int]:
    """Allocate free ports for all 4 host-published services."""
    return {var: find_free_port(default) for var, default in DEFAULT_PORTS.items()}


def write_env_file(path: Path, ports: dict[str, int]) -> None:
    """Write a docker compose --env-file compatible KEY=VALUE file."""
    lines = [f"{k}={v}" for k, v in ports.items()]
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def load_env_file(path: Path) -> dict[str, str]:
    out: dict[str, str] = {}
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        out[k.strip()] = v.strip()
    return out


def resolve_ports(env_file: Optional[Path]) -> dict[str, int]:
    """Determine effective host ports.

    Precedence (highest first):
      1. --env-file (if provided and exists)
      2. process env vars
      3. DEFAULT_PORTS
    """
    resolved = dict(DEFAULT_PORTS)
    for var in DEFAULT_PORTS:
        v = os.environ.get(var)
        if v is not None and v.strip():
            try:
                resolved[var] = int(v)
            except ValueError:
                pass
    if env_file and env_file.exists():
        for k, v in load_env_file(env_file).items():
            if k in DEFAULT_PORTS:
                try:
                    resolved[k] = int(v)
                except ValueError:
                    pass
    return resolved


# --- Check definitions -----------------------------------------------------

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


def build_checks(ports: dict[str, int]) -> tuple[list[HttpCheck], list[WsCheck]]:
    bo = ports["EBS_BO_HOST_PORT"]
    eng = ports["EBS_ENGINE_HOST_PORT"]
    lob = ports["EBS_LOBBY_HOST_PORT"]
    cc = ports["EBS_CC_HOST_PORT"]
    https = [
        HttpCheck("bo",        f"http://localhost:{bo}/health"),
        HttpCheck("engine",    f"http://localhost:{eng}/engine/health"),
        HttpCheck("lobby-web", f"http://localhost:{lob}/healthz"),
        HttpCheck("cc-web",    f"http://localhost:{cc}/healthz"),
    ]
    wss = [
        # Gap 3: 미인증 health probe — /ws/lobby (인증 필수, 403) 가 아닌 /health/ws 사용
        WsCheck("bo-ws-health", "localhost", bo, "/health/ws"),
    ]
    return https, wss


# --- Probes ----------------------------------------------------------------

def http_check(check: HttpCheck) -> CheckResult:
    started = time.monotonic()
    req = urllib.request.Request(check.url, method="GET",
                                 headers={"User-Agent": "ebs-verify-ecosystem/2.0"})
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

    101 Switching Protocols 응답을 받으면 OK.
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
            f"User-Agent: ebs-verify-ecosystem/2.0\r\n"
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
        status = None
        if first_line:
            parts = first_line.split()
            if len(parts) >= 2 and parts[1].isdigit():
                status = int(parts[1])
        return CheckResult(
            name=check.name, kind="ws", target=target, ok=ok,
            status=status,
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


def run_all(checks_http: list[HttpCheck], checks_ws: list[WsCheck],
            retries: int, retry_delay_s: float) -> tuple[list[CheckResult], int]:
    results: list[CheckResult] = []
    failed_count = 0

    for chk in checks_http:
        last: CheckResult = http_check(chk)
        for _ in range(retries):
            if last.ok:
                break
            time.sleep(retry_delay_s)
            last = http_check(chk)
        results.append(last)
        if not last.ok:
            failed_count += 1

    for wschk in checks_ws:
        last2: CheckResult = ws_handshake(wschk)
        for _ in range(retries):
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


# --- Entry -----------------------------------------------------------------

def main(argv: Optional[list[str]] = None) -> int:
    ap = argparse.ArgumentParser(
        prog="verify_ecosystem.py",
        description="EBS Multi-Service Docker E2E smoke validation",
    )
    ap.add_argument("--retries", type=int, default=3,
                    help="failed check 재시도 횟수 (default: 3)")
    ap.add_argument("--retry-delay", type=float, default=2.0,
                    help="재시도 간 대기 (s, default: 2.0)")
    ap.add_argument("--json", dest="as_json", action="store_true",
                    help="JSON 출력 (CI/agent 소비)")
    ap.add_argument("--allocate-ports", action="store_true",
                    help="free port 자동 할당 + --env-file 경로에 작성하고 종료")
    ap.add_argument("--env-file", type=Path, default=Path(".env.runtime"),
                    help="docker compose --env-file 호환 KEY=VALUE 파일 (default: .env.runtime)")
    args = ap.parse_args(argv)

    if args.allocate_ports:
        ports = allocate_ports()
        write_env_file(args.env_file, ports)
        print(f"# free ports allocated -> {args.env_file}")
        for k, v in ports.items():
            default = DEFAULT_PORTS[k]
            note = "" if v == default else f"  (preferred {default} occupied)"
            print(f"{k}={v}{note}")
        print()
        print("# next steps:")
        print(f"#   docker compose --env-file {args.env_file} --profile web up -d")
        print(f"#   python tools/verify_ecosystem.py --env-file {args.env_file}")
        print(f"#   docker compose --env-file {args.env_file} --profile web down -v")
        return 0

    ports = resolve_ports(args.env_file)
    https, wss = build_checks(ports)

    print("=" * 78)
    print("EBS Multi-Service Docker E2E Smoke Validation (v2.0)")
    print(f"  HTTP checks: {len(https)}  |  WS checks: {len(wss)}  |  retries: {args.retries}")
    print(f"  ports: {ports}")
    if args.env_file.exists():
        print(f"  env-file: {args.env_file} (loaded)")
    print("=" * 78)

    results, failed = run_all(https, wss, args.retries, args.retry_delay)

    if args.as_json:
        payload = {
            "ok": failed == 0,
            "failed_count": failed,
            "total": len(results),
            "ports": ports,
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
        print(f"GATEKEEPER PASS - {len(results)}/{len(results)} services healthy.")
        return 0
    else:
        print(f"GATEKEEPER FAIL - {failed}/{len(results)} services unhealthy.")
        print("Self-correction trigger: run `docker compose logs <service>` for failing services.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
