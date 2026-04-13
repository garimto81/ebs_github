from datetime import datetime, timezone

from sqlmodel import Session, func, select

from bo.db.models import Hand, HandAction, HandPlayer, Table


def hands_summary(
    session: Session,
    table_id: int | None = None,
    event_id: int | None = None,
) -> dict:
    """Count hands, average pot, total actions."""
    stmt = select(Hand)
    if table_id:
        stmt = stmt.where(Hand.table_id == table_id)

    hands = session.exec(stmt).all()
    hand_ids = [h.hand_id for h in hands]

    total_hands = len(hands)
    avg_pot = 0.0
    total_actions = 0

    if total_hands > 0:
        avg_pot = sum(h.pot_total for h in hands) / total_hands

        if hand_ids:
            action_count = session.exec(
                select(func.count())
                .select_from(HandAction)
                .where(HandAction.hand_id.in_(hand_ids))
            ).one()
            total_actions = action_count

    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    return {
        "report_type": "hands-summary",
        "generated_at": now,
        "data": [
            {
                "total_hands": total_hands,
                "avg_pot": round(avg_pot, 2),
                "total_actions": total_actions,
            }
        ],
    }


def player_stats(
    session: Session,
    player_id: int | None = None,
    event_id: int | None = None,
) -> dict:
    """Count hands played, VPIP%, PFR%."""
    stmt = select(HandPlayer)
    if player_id:
        stmt = stmt.where(HandPlayer.player_id == player_id)

    records = session.exec(stmt).all()
    total = len(records)
    vpip_count = sum(1 for r in records if r.vpip)
    pfr_count = sum(1 for r in records if r.pfr)

    vpip_pct = round(vpip_count / total * 100, 1) if total > 0 else 0.0
    pfr_pct = round(pfr_count / total * 100, 1) if total > 0 else 0.0

    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    return {
        "report_type": "player-stats",
        "generated_at": now,
        "data": [
            {
                "total_hands": total,
                "vpip_pct": vpip_pct,
                "pfr_pct": pfr_pct,
            }
        ],
    }


def table_activity(
    session: Session,
    flight_id: int | None = None,
    from_dt: str | None = None,
    to_dt: str | None = None,
) -> dict:
    """Hands per table, duration."""
    stmt = select(Table)
    if flight_id:
        stmt = stmt.where(Table.event_flight_id == flight_id)
    tables = session.exec(stmt).all()

    table_data = []
    for t in tables:
        hand_stmt = select(func.count()).select_from(Hand).where(
            Hand.table_id == t.table_id
        )
        if from_dt:
            hand_stmt = hand_stmt.where(Hand.started_at >= from_dt)
        if to_dt:
            hand_stmt = hand_stmt.where(Hand.started_at <= to_dt)
        hand_count = session.exec(hand_stmt).one()

        dur_stmt = select(func.sum(Hand.duration_sec)).where(
            Hand.table_id == t.table_id
        )
        total_duration = session.exec(dur_stmt).one() or 0

        table_data.append({
            "table_id": t.table_id,
            "table_name": t.name,
            "hand_count": hand_count,
            "total_duration_sec": total_duration,
        })

    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    return {
        "report_type": "table-activity",
        "generated_at": now,
        "data": table_data,
    }


def session_log(
    session: Session,
    user_id: int | None = None,
    from_dt: str | None = None,
    to_dt: str | None = None,
) -> dict:
    """Login/logout audit entries."""
    from bo.db.models import AuditLog

    stmt = select(AuditLog).where(AuditLog.entity_type == "session")
    if user_id:
        stmt = stmt.where(AuditLog.user_id == user_id)
    if from_dt:
        stmt = stmt.where(AuditLog.created_at >= from_dt)
    if to_dt:
        stmt = stmt.where(AuditLog.created_at <= to_dt)

    logs = session.exec(stmt.order_by(AuditLog.created_at.desc())).all()

    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    return {
        "report_type": "session-log",
        "generated_at": now,
        "data": [
            {
                "id": log.id,
                "user_id": log.user_id,
                "action": log.action,
                "detail": log.detail,
                "created_at": log.created_at,
            }
            for log in logs
        ],
    }
