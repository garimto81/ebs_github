#!/usr/bin/env python3
"""WSOP LIVE Mock Webhook 도구 — SG-042 PR-A Area 1.

로컬 개발자가 WSOP LIVE 없이 chip count snapshot 시뮬레이션할 수 있는 CLI 도구.
HMAC-SHA256 서명 + Idempotency-Key 를 자동 생성하여 BO 엔드포인트에 POST 한다.

SSOT: docs/2. Development/2.2 Backend/APIs/WSOP_LIVE_Chip_Count_Sync.md §3

사용법:
    python tools/wsop_live_mock_webhook.py \\
        --table-id 1 \\
        --break-id 1001 \\
        --seat 1:50000 --seat 2:45000 --seat 3:60000 \\
        --recorded-at 2026-05-14T10:00:00Z \\
        --secret dev-secret-change-me \\
        --url http://localhost:8000

    # 단일 좌석 빠른 테스트:
    python tools/wsop_live_mock_webhook.py --seat 1:100000

    # 전체 테이블 시뮬레이션 (기본 9좌석, 칩 균등 분배):
    python tools/wsop_live_mock_webhook.py --table-id 2 --auto-fill --total-chips 900000

환경 변수:
    WSOP_LIVE_WEBHOOK_SECRET — --secret 기본값
    BO_URL                  — --url 기본값 (기본: http://localhost:8000)
"""
from __future__ import annotations

import argparse
import hashlib
import hmac
import json
import os
import sys
import uuid
from datetime import datetime, timezone


# ── HMAC 서명 헬퍼 ────────────────────────────────────────────────────────────

PATH = "/api/wsop-live/chip-count-snapshot"


def _canonical(method: str, path: str, timestamp: str, body_bytes: bytes) -> str:
    body_hash = hashlib.sha256(body_bytes).hexdigest()
    return f"{method}\n{path}\n{timestamp}\n{body_hash}"


def _sign(secret: str, method: str, path: str, timestamp: str, body_bytes: bytes) -> str:
    msg = _canonical(method, path, timestamp, body_bytes).encode("utf-8")
    return hmac.new(secret.encode("utf-8"), msg, hashlib.sha256).hexdigest()


# ── 페이로드 빌더 ────────────────────────────────────────────────────────────


def _build_payload(
    table_id: int,
    break_id: int,
    snapshot_id: str,
    recorded_at: str,
    seats: list[dict],
) -> dict:
    return {
        "snapshot_id": snapshot_id,
        "break_id": break_id,
        "table_id": table_id,
        "recorded_at": recorded_at,
        "seats": seats,
    }


def _auto_fill_seats(total_chips: int, seat_count: int) -> list[dict]:
    """total_chips 를 seat_count 개 좌석에 균등 분배."""
    per_seat = total_chips // seat_count
    remainder = total_chips % seat_count
    return [
        {
            "seat_number": i + 1,
            "player_id": None,
            "chip_count": per_seat + (1 if i < remainder else 0),
        }
        for i in range(seat_count)
    ]


# ── CLI 파싱 ─────────────────────────────────────────────────────────────────


def _parse_seat(token: str) -> dict:
    """'SEAT_NO:CHIPS' 또는 'SEAT_NO:CHIPS:PLAYER_ID' 파싱."""
    parts = token.split(":")
    if len(parts) < 2:  # noqa: PLR2004
        raise argparse.ArgumentTypeError(
            f"seat 형식 오류: '{token}' — 'seat_number:chip_count[:player_id]' 필요"
        )
    seat_no = int(parts[0])
    chips = int(parts[1])
    player_id = int(parts[2]) if len(parts) >= 3 else None  # noqa: PLR2004
    return {"seat_number": seat_no, "player_id": player_id, "chip_count": chips}


def _build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        description="WSOP LIVE Mock Webhook — chip count snapshot 시뮬레이터",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    p.add_argument(
        "--table-id", type=int, default=1,
        help="대상 Table ID (기본: 1)",
    )
    p.add_argument(
        "--break-id", type=int, default=1001,
        help="Break ID (기본: 1001)",
    )
    p.add_argument(
        "--seat", metavar="SEAT_NO:CHIPS[:PLAYER_ID]", action="append",
        type=_parse_seat, dest="seats",
        help="좌석:칩카운트[:플레이어ID]. 반복 가능. 예: --seat 1:50000 --seat 2:45000",
    )
    p.add_argument(
        "--auto-fill", action="store_true",
        help="--seat 없이 균등 분배로 자동 생성 (--seat-count + --total-chips 사용)",
    )
    p.add_argument(
        "--seat-count", type=int, default=9,
        help="auto-fill 시 좌석 수 (기본: 9)",
    )
    p.add_argument(
        "--total-chips", type=int, default=900000,
        help="auto-fill 시 총 칩 수 (기본: 900000)",
    )
    p.add_argument(
        "--snapshot-id", type=str, default=None,
        help="Snapshot UUID (기본: 자동 생성)",
    )
    p.add_argument(
        "--recorded-at", type=str, default=None,
        help="ISO-8601 UTC 기록 시각 (기본: 현재 시각). 예: 2026-05-14T10:00:00Z",
    )
    p.add_argument(
        "--secret",
        default=os.environ.get("WSOP_LIVE_WEBHOOK_SECRET", "dev-secret-32-bytes-aaaaaaaaaaaaaaa"),
        help="HMAC-SHA256 공유 비밀키 (기본: 환경변수 WSOP_LIVE_WEBHOOK_SECRET)",
    )
    p.add_argument(
        "--url",
        default=os.environ.get("BO_URL", "http://localhost:8000"),
        help="BO 서버 URL (기본: http://localhost:8000)",
    )
    p.add_argument(
        "--dry-run", action="store_true",
        help="실제 HTTP 요청 없이 페이로드만 출력",
    )
    p.add_argument(
        "--verbose", "-v", action="store_true",
        help="상세 출력 (헤더 포함)",
    )
    return p


# ── 메인 ─────────────────────────────────────────────────────────────────────


def main(argv: list[str] | None = None) -> int:
    args = _build_parser().parse_args(argv)

    # 좌석 결정
    if args.seats:
        seats = args.seats
    elif args.auto_fill:
        seats = _auto_fill_seats(args.total_chips, args.seat_count)
    else:
        # 기본: 단일 좌석 예시
        seats = [{"seat_number": 1, "player_id": None, "chip_count": 100000}]
        print("[INFO] --seat 미지정 → 기본 예시 좌석 1개 사용", file=sys.stderr)

    # 스냅샷 ID
    snapshot_id = args.snapshot_id or str(uuid.uuid4())

    # 기록 시각
    recorded_at = args.recorded_at or (
        datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    )

    payload = _build_payload(args.table_id, args.break_id, snapshot_id, recorded_at, seats)
    body_bytes = json.dumps(payload, separators=(",", ":")).encode("utf-8")

    timestamp = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    signature = _sign(args.secret, "POST", PATH, timestamp, body_bytes)

    headers = {
        "Content-Type": "application/json",
        "X-WSOP-Timestamp": timestamp,
        "X-WSOP-Signature": signature,
        "Idempotency-Key": snapshot_id,
    }

    if args.verbose or args.dry_run:
        print("=== Mock Webhook Payload ===")
        print(json.dumps(payload, indent=2, ensure_ascii=False))
        print("\n=== Headers ===")
        for k, v in headers.items():
            print(f"  {k}: {v}")

    if args.dry_run:
        print("\n[DRY-RUN] HTTP 요청 생략")
        return 0

    # HTTP 요청
    try:
        import urllib.request

        url = args.url.rstrip("/") + PATH
        req = urllib.request.Request(
            url,
            data=body_bytes,
            headers=headers,
            method="POST",
        )

        if args.verbose:
            print(f"\n→ POST {url}")

        try:
            with urllib.request.urlopen(req) as resp:
                status = resp.getcode()
                body = resp.read().decode("utf-8", errors="replace")
        except urllib.error.HTTPError as e:
            status = e.code
            body = e.read().decode("utf-8", errors="replace")

        print(f"\n=== Response: HTTP {status} ===")
        try:
            parsed = json.loads(body)
            print(json.dumps(parsed, indent=2, ensure_ascii=False))
        except json.JSONDecodeError:
            print(body)

        if status in (200, 202):
            print("\n✅ 성공")
            return 0
        else:
            print(f"\n❌ 실패 (HTTP {status})")
            return 1

    except OSError as exc:
        print(f"\n❌ 연결 오류: {exc}", file=sys.stderr)
        print("  --url 과 BO 서버 상태를 확인하세요.", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
