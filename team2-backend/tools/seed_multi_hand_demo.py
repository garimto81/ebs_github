#!/usr/bin/env python3
"""Seed multi-hand demo data — S7 Cycle 8 #341 신규.

v02 multi-hand e2e (S9 Cycle 6 PR #320) 의 admin@local + multi-hand state 를
BO DB 에 reflective seed. /next-hand 회귀 시나리오의 BO 측 read-only fixture.

특징:
  1) admin@local seed 보장 (seed_admin.py 위임 — idempotent)
  2) demo Table 1개 + 누적 Hand 3개 (handNumber 1/2/3, dealer 0/1/2 rotate)
  3) Hand 마다 6 seats + dealer 위치별 isDealer 패턴

기획서 정렬:
  - docs/2. Development/2.3 Game Engine/Rules/Multi_Hand_State.md
  - docs/2. Development/2.2 Backend/Database/Schema.md (hands, hand_players)
  - integration-tests/scenarios/v02-2-hand-flow.http (회전 의미론 SSOT)

사용:
  python tools/seed_multi_hand_demo.py
  python tools/seed_multi_hand_demo.py --reset      # 기존 demo 삭제 후 재시드
  docker exec ebs-bo python tools/seed_multi_hand_demo.py

idempotent: Table.name='S7_C8_MultiHand_Demo' 키로 검증, 중복 생성 차단.

관련:
  - Issue #341 (S7 Cycle 8 /next-hand 회귀 강화)
  - Cycle 6 PR #320 v02 baseline
"""
from __future__ import annotations

import argparse
import sys
from datetime import datetime, timezone
from pathlib import Path

TEAM2_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TEAM2_ROOT))

from sqlmodel import Session, create_engine, delete, select  # noqa: E402

from src.app.config import settings  # noqa: E402
from src.models.hand import Hand, HandPlayer  # noqa: E402
from src.models.table import Table  # noqa: E402

# ── Demo data SSOT ────────────────────────────────────────────────────────

DEMO_TABLE_NAME = "S7_C8_MultiHand_Demo"
DEMO_HAND_COUNT = 3
DEMO_SEAT_COUNT = 6


def _utcnow_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _ensure_demo_table(db: Session) -> Table:
    """Find or create the demo table. Independent of competition tree —
    multi-hand demo는 standalone fixture (Hand-only 검증 목적).
    """
    existing = db.exec(
        select(Table).where(Table.name == DEMO_TABLE_NAME)
    ).first()
    if existing:
        return existing

    # event_flight_id = 1 을 기본값으로 가정. seed_demo_data.py 가 먼저 실행되어
    # flight 가 존재한다는 전제 (없으면 1번 flight 가 자동 매핑).
    # 본 fixture 는 Hand 회귀 검증 목적이므로 flight 의 실제성은 무관.
    flight_id = 1
    table = Table(
        event_flight_id=flight_id,
        table_no=999,                  # demo 전용 high number (충돌 회피)
        name=DEMO_TABLE_NAME,
        type="demo",
        status="setup",
        max_players=DEMO_SEAT_COUNT,
    )
    db.add(table)
    db.commit()
    db.refresh(table)
    return table


def _seed_multi_hand(db: Session, table: Table) -> list[Hand]:
    """Create 3 sequential hands rotating dealer 0→1→2.

    v02-2-hand-flow.http SSOT 의미론:
      - hand_number 단조 증가 (1, 2, 3)
      - dealer_seat round-robin +1 (0, 1, 2)
      - 각 hand 종료 (ended_at != None)
    """
    out: list[Hand] = []
    now = _utcnow_iso()

    for hn in range(1, DEMO_HAND_COUNT + 1):
        existing = db.exec(
            select(Hand).where(
                Hand.table_id == table.table_id,
                Hand.hand_number == hn,
            )
        ).first()
        if existing:
            out.append(existing)
            continue

        dealer = (hn - 1) % DEMO_SEAT_COUNT  # hand 1 → dealer 0, hand 2 → 1, ...
        hand = Hand(
            table_id=table.table_id,
            hand_number=hn,
            game_type=0,                # NL Holdem (0 in DATA-04 §3 enum)
            bet_structure=0,            # NL
            dealer_seat=dealer,
            board_cards="[]",
            pot_total=15,               # SB 5 + BB 10 (v02 baseline)
            side_pots="[]",
            current_street=None,
            started_at=now,
            ended_at=now,
            duration_sec=30,
        )
        db.add(hand)
        db.commit()
        db.refresh(hand)
        out.append(hand)

        # Hand 마다 6 seats (winner=BB=seat 2 in hand 1, shift +1 with dealer)
        winner_seat = (dealer + 2) % DEMO_SEAT_COUNT  # BB position = dealer+2
        for seat_no in range(DEMO_SEAT_COUNT):
            is_winner = 1 if seat_no == winner_seat else 0
            pnl = 15 if is_winner else (-10 if seat_no == (dealer + 1) % DEMO_SEAT_COUNT else 0)
            start_stack = 1000
            end_stack = 1005 if is_winner else (995 if pnl == -10 else 1000)
            hp = HandPlayer(
                hand_id=hand.hand_id,
                seat_no=seat_no,
                player_id=None,
                player_name=f"Demo Seat {seat_no + 1}",
                hole_cards="[]",
                start_stack=start_stack,
                end_stack=end_stack,
                final_action="walk" if is_winner else "fold",
                is_winner=is_winner,
                pnl=pnl,
            )
            db.add(hp)
        db.commit()

    return out


def _reset_demo(db: Session) -> None:
    """Hard delete S7_C8_MultiHand_Demo table + cascading hands."""
    table = db.exec(
        select(Table).where(Table.name == DEMO_TABLE_NAME)
    ).first()
    if not table:
        return
    hand_ids = [
        h.hand_id for h in db.exec(
            select(Hand).where(Hand.table_id == table.table_id)
        ).all()
    ]
    if hand_ids:
        db.exec(delete(HandPlayer).where(HandPlayer.hand_id.in_(hand_ids)))
        db.exec(delete(Hand).where(Hand.hand_id.in_(hand_ids)))
    db.exec(delete(Table).where(Table.table_id == table.table_id))
    db.commit()


def _ensure_admin(db_url: str) -> int:
    """Delegate admin@local seed to seed_admin.py — idempotent.
    Returns 0 on success, non-zero on failure.
    """
    import subprocess

    seed_admin = TEAM2_ROOT / "tools" / "seed_admin.py"
    if not seed_admin.exists():
        print(f"WARNING: {seed_admin} not found — skipping admin seed")
        return 0
    result = subprocess.run(
        [
            sys.executable,
            str(seed_admin),
            "--email", "admin@local",
            "--password", "Admin!Local123",
            "--display-name", "Local Admin",
            "--role", "admin",
            "--database-url", db_url,
        ],
        capture_output=True,
        text=True,
    )
    print(result.stdout, end="")
    if result.returncode != 0:
        print(result.stderr, file=sys.stderr, end="")
    return result.returncode


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--reset", action="store_true",
                    help="기존 multi-hand demo 삭제 후 재시드")
    ap.add_argument("--database-url", default=None,
                    help="settings.database_url 기본")
    ap.add_argument("--skip-admin", action="store_true",
                    help="seed_admin.py 호출 생략 (admin 이미 존재 시)")
    args = ap.parse_args(argv)

    db_url = args.database_url or settings.database_url
    if not db_url:
        print("ERROR: DATABASE_URL not set. Run init_db.py first or set env var.")
        return 1

    print(f"DB: {db_url.split('@')[-1] if '@' in db_url else db_url}")

    # 1) admin@local seed (위임)
    if not args.skip_admin:
        print("→ Step 1: seed admin@local")
        rc = _ensure_admin(db_url)
        if rc != 0:
            print(f"ERROR: admin seed failed (rc={rc})")
            return rc

    # 2) multi-hand demo data
    print("→ Step 2: seed multi-hand demo data")
    engine = create_engine(db_url)
    with Session(engine) as db:
        if args.reset:
            print("  Resetting existing multi-hand demo...")
            _reset_demo(db)
            print("  OK reset")

        table = _ensure_demo_table(db)
        print(f"  Table: {table.name} (id={table.table_id}, table_no={table.table_no})")

        hands = _seed_multi_hand(db, table)
        print(f"  Hands: {len(hands)} created")
        for h in hands:
            print(
                f"    hand_number={h.hand_number} dealer_seat={h.dealer_seat} "
                f"pot_total={h.pot_total}"
            )

    print()
    print("✓ Multi-hand demo seed complete.")
    print("  Verify: GET /api/v1/hands?table_id={table.table_id}")
    print("  Verify: SELECT * FROM hands WHERE table_id = {table.table_id}")
    print(f"  Expect: 3 hands, hand_number=1/2/3, dealer_seat=0/1/2 rotate")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
