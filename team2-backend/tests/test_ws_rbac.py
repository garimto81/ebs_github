"""WS Operator table guard — SSOT WebSocket_Events.md §4.3 L573.

Previously `manager.py` captured `role` but never enforced per-table
authorization, letting any Operator attach to any `/ws/cc?table_id=X`.
"""
import json

import pytest

from src.security.jwt import create_access_token


def test_operator_with_empty_assigned_tables_rejected(client, seed_users):
    """Operator token with assigned_tables=[] must be rejected on /ws/cc."""
    token = create_access_token(
        user_id=seed_users["operator"].user_id,
        email="operator@test.com",
        role="operator",
        assigned_tables=[],  # no assignment
    )
    with pytest.raises(Exception):
        with client.websocket_connect(f"/ws/cc?token={token}&table_id=tbl-1") as ws:
            ws.send_text("hello")


def test_operator_with_wrong_table_rejected(client, seed_users):
    """Operator with different assignment than requested table → reject."""
    token = create_access_token(
        user_id=seed_users["operator"].user_id,
        email="operator@test.com",
        role="operator",
        assigned_tables=["tbl-99"],
    )
    with pytest.raises(Exception):
        with client.websocket_connect(f"/ws/cc?token={token}&table_id=tbl-1") as ws:
            ws.send_text("hello")


def test_operator_with_matching_table_accepted(client, seed_users):
    """Operator with table_id in assigned_tables → accepted."""
    token = create_access_token(
        user_id=seed_users["operator"].user_id,
        email="operator@test.com",
        role="operator",
        assigned_tables=["tbl-1", "tbl-2"],
    )
    with client.websocket_connect(f"/ws/cc?token={token}&table_id=tbl-1") as ws:
        ws.send_text(json.dumps({
            "type": "HandStarted",
            "tableId": "tbl-1",
            "payload": {"handNumber": 1},
            "messageId": "m1",
        }))
        ack = json.loads(ws.receive_text())
        assert ack["type"] == "Ack"


def test_admin_bypasses_table_guard(client, seed_users):
    """Admin has no table restriction even if assigned_tables=[]."""
    token = create_access_token(
        user_id=seed_users["admin"].user_id,
        email="admin@test.com",
        role="admin",
        assigned_tables=[],
    )
    with client.websocket_connect(f"/ws/cc?token={token}&table_id=tbl-7") as ws:
        ws.send_text(json.dumps({
            "type": "HandStarted",
            "tableId": "tbl-7",
            "payload": {"handNumber": 1},
            "messageId": "m1",
        }))
        ack = json.loads(ws.receive_text())
        assert ack["type"] == "Ack"


def test_operator_without_claim_still_allowed_backcompat(client, seed_users):
    """Pre-CCR-006 tokens (no `assigned_tables` claim) remain unrestricted.

    This preserves backward compatibility with tokens minted before the
    guard landed. Production tokens should include the claim to trigger
    enforcement.
    """
    token = create_access_token(
        user_id=seed_users["operator"].user_id,
        email="operator@test.com",
        role="operator",
        # no assigned_tables → None → unrestricted
    )
    with client.websocket_connect(f"/ws/cc?token={token}&table_id=tbl-1") as ws:
        ws.send_text(json.dumps({
            "type": "HandStarted",
            "tableId": "tbl-1",
            "payload": {"handNumber": 1},
            "messageId": "m1",
        }))
        ack = json.loads(ws.receive_text())
        assert ack["type"] == "Ack"
