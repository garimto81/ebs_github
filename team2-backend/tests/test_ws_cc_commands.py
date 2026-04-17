"""WS CC commands — WriteGameInfo/WriteDeal/WriteAction (SSOT §9-11).

Previously `cc_handler.py` had no branch for these explicit command types;
CC's NEW HAND / DEAL / action buttons had no server-side contract. This
test suite pins the new command → typed-ack envelope shape.
"""
import json

import pytest

from src.security.jwt import create_access_token


def _token(user):
    return create_access_token(
        user_id=user.user_id,
        email=user.email,
        role="admin",  # admin bypass for table guard
    )


# ── WriteGameInfo ──────────────────────────────────


def test_write_game_info_valid_returns_game_info_ack(client, seed_users):
    token = _token(seed_users["admin"])
    with client.websocket_connect(f"/ws/cc?token={token}&table_id=tbl-1") as ws:
        ws.send_text(json.dumps({
            "type": "WriteGameInfo",
            "table_id": "tbl-1",
            "payload": {
                "game_type": 0,
                "bet_structure": 0,
                "small_blind": 100,
                "big_blind": 200,
            },
            "message_id": "m1",
        }))
        ack = json.loads(ws.receive_text())
        assert ack["type"] == "GameInfoAck"
        assert ack["payload"]["status"] == "ok"
        assert "seq" in ack["payload"]


def test_write_game_info_missing_fields_returns_rejected(client, seed_users):
    token = _token(seed_users["admin"])
    with client.websocket_connect(f"/ws/cc?token={token}&table_id=tbl-1") as ws:
        ws.send_text(json.dumps({
            "type": "WriteGameInfo",
            "table_id": "tbl-1",
            "payload": {},  # missing required fields
            "message_id": "m2",
        }))
        ack = json.loads(ws.receive_text())
        assert ack["type"] == "GameInfoRejected"
        assert "reason" in ack["payload"]


# ── WriteDeal ──────────────────────────────────────


def test_write_deal_valid_returns_deal_ack(client, seed_users):
    token = _token(seed_users["admin"])
    with client.websocket_connect(f"/ws/cc?token={token}&table_id=tbl-1") as ws:
        ws.send_text(json.dumps({
            "type": "WriteDeal",
            "table_id": "tbl-1",
            "payload": {
                "hand_number": 101,
                "dealer_seat": 3,
                "deck_id": 1,
            },
            "message_id": "m3",
        }))
        ack = json.loads(ws.receive_text())
        assert ack["type"] == "DealAck"
        assert ack["payload"]["status"] == "ok"


def test_write_deal_missing_hand_number_rejected(client, seed_users):
    token = _token(seed_users["admin"])
    with client.websocket_connect(f"/ws/cc?token={token}&table_id=tbl-1") as ws:
        ws.send_text(json.dumps({
            "type": "WriteDeal",
            "table_id": "tbl-1",
            "payload": {"dealer_seat": 3},
            "message_id": "m4",
        }))
        ack = json.loads(ws.receive_text())
        assert ack["type"] == "DealRejected"


# ── WriteAction ────────────────────────────────────


def test_write_action_valid_returns_action_ack(client, seed_users):
    token = _token(seed_users["admin"])
    with client.websocket_connect(f"/ws/cc?token={token}&table_id=tbl-1") as ws:
        ws.send_text(json.dumps({
            "type": "WriteAction",
            "table_id": "tbl-1",
            "payload": {
                "hand_number": 101,
                "seat_no": 3,
                "action": "bet",
                "amount": 400,
            },
            "message_id": "m5",
        }))
        ack = json.loads(ws.receive_text())
        assert ack["type"] == "ActionAck"


def test_write_action_unknown_action_rejected(client, seed_users):
    token = _token(seed_users["admin"])
    with client.websocket_connect(f"/ws/cc?token={token}&table_id=tbl-1") as ws:
        ws.send_text(json.dumps({
            "type": "WriteAction",
            "table_id": "tbl-1",
            "payload": {
                "hand_number": 101,
                "seat_no": 3,
                "action": "wiggle",  # not in valid set
            },
            "message_id": "m6",
        }))
        ack = json.loads(ws.receive_text())
        assert ack["type"] == "ActionRejected"
        assert "wiggle" in str(ack["payload"]).lower()


# ── Envelope completeness (server_time present) ────


def test_game_info_ack_envelope_includes_server_time(client, seed_users):
    token = _token(seed_users["admin"])
    with client.websocket_connect(f"/ws/cc?token={token}&table_id=tbl-1") as ws:
        ws.send_text(json.dumps({
            "type": "WriteGameInfo",
            "table_id": "tbl-1",
            "payload": {
                "game_type": 0, "bet_structure": 0,
                "small_blind": 100, "big_blind": 200,
            },
            "message_id": "m7",
        }))
        ack = json.loads(ws.receive_text())
        assert "server_time" in ack
        assert "source_id" in ack
        assert ack["source_id"] == "bo"
