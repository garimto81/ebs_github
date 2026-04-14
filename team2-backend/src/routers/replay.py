"""Replay endpoint — GET /tables/:id/events (CCR-015)."""
import json

from fastapi import APIRouter, Depends, Query
from sqlmodel import Session

from src.app.database import get_db
from src.middleware.rbac import get_current_user
from src.models.user import User
from src.repositories.event_repository import event_repository

router = APIRouter(prefix="/api/v1", tags=["replay"])


@router.get("/tables/{table_id}/events")
def replay_events(
    table_id: str,
    since: int = Query(..., description="Last received seq"),
    limit: int = Query(500, ge=1, le=2000),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Replay audit events for WebSocket gap recovery."""
    result = event_repository.fetch_since(
        table_id=table_id,
        since_seq=since,
        limit=limit,
        db=db,
    )

    events_out = []
    for evt in result.events:
        payload = evt.payload
        if isinstance(payload, str):
            try:
                payload = json.loads(payload)
            except (json.JSONDecodeError, TypeError):
                pass

        events_out.append({
            "type": evt.event_type,
            "seq": evt.seq,
            "table_id": evt.table_id,
            "ts": evt.created_at,
            "server_time": evt.created_at,
            "payload": payload,
            "can_undo": event_repository.get_can_undo(evt),
        })

    return {
        "data": {
            "table_id": table_id,
            "events": events_out,
            "last_seq": result.last_seq,
            "has_more": result.has_more,
        },
        "error": None,
    }
