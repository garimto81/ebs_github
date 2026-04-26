"""test_publishers — J2 (2026-04-21) publisher 20건 smoke test.

각 publisher 가 import 가능 + ConnectionManager.broadcast 호출 + payload shape 검증.
seq 자동 주입·send_personal 전환 등 TODO 는 후속 세션에서 검증.
"""
from __future__ import annotations

import pytest

from src.websocket import publishers
from src.websocket.publishers import __all__ as PUBLISHER_NAMES


class FakeManager:
    """ConnectionManager mock — broadcast 호출을 캡처."""

    def __init__(self):
        self.calls: list[tuple[str, str, dict]] = []

    async def broadcast(self, channel: str, table_id: str, event_data: dict) -> int:
        self.calls.append((channel, table_id, event_data))
        return 1


@pytest.mark.asyncio
async def test_all_publishers_exported():
    """publishers.__all__ 에 26건 모두 등록 (J2 20 + SG-020 6)."""
    assert len(PUBLISHER_NAMES) == 26
    for name in PUBLISHER_NAMES:
        assert hasattr(publishers, name), f"missing: {name}"
        assert callable(getattr(publishers, name))


@pytest.mark.asyncio
async def test_snake_case_publishers_payload():
    m = FakeManager()
    await publishers.publish_clock_detail_changed(m, "t1", {"phase": "running"}, seq=10)
    await publishers.publish_clock_reload_requested(m, "t1", "level_up", seq=11)
    await publishers.publish_tournament_status_changed(m, "e1", "running", seq=12)
    await publishers.publish_blind_structure_changed(m, "t1", "bs1", seq=13)
    await publishers.publish_prize_pool_changed(m, "e1", 1_000_000, seq=14)
    await publishers.publish_stack_adjusted(m, "t1", seat=3, delta=500, reason="color-up", seq=15)
    await publishers.publish_skin_updated(m, "t1", "skin-uuid", "1.2.3", seq=16)

    assert len(m.calls) == 7
    types = [call[2]["type"] for call in m.calls]
    assert types == [
        "clock_detail_changed", "clock_reload_requested", "tournament_status_changed",
        "blind_structure_changed", "prize_pool_changed", "stack_adjusted", "skin_updated",
    ]
    # seq 전달 확인
    assert [c[2]["seq"] for c in m.calls] == list(range(10, 17))


@pytest.mark.asyncio
async def test_error_publishers_payload():
    m = FakeManager()
    await publishers.publish_auth_failed(m, "t1", "u1", "invalid_token")
    await publishers.publish_table_not_found(m, "t1", "missing")
    await publishers.publish_permission_denied(m, "t1", "u1", "reveal_holecards")
    await publishers.publish_invalid_message(m, "t1", "unknown event type")
    await publishers.publish_rfid_hardware_error(m, "t1", "reader-1", "ANTENNA_TIMEOUT")
    await publishers.publish_duplicate_card(m, "t1", "AS", [2, 5])
    await publishers.publish_card_conflict(m, "t1", "AS", expected=2, seen=5)
    await publishers.publish_slow_connection(m, "t1", "u1", latency_ms=750)
    await publishers.publish_token_expiring_soon(m, "t1", "u1", expires_in_sec=60)

    assert len(m.calls) == 9
    types = [call[2]["type"] for call in m.calls]
    assert types == [
        "AuthFailed", "TableNotFound", "PermissionDenied", "InvalidMessage",
        "RfidHardwareError", "DuplicateCard", "CardConflict",
        "SlowConnection", "TokenExpiringSoon",
    ]
    # error event 는 seq 없음 (skeleton 은 전부 cc 채널)
    for c in m.calls:
        assert c[0] == "cc"


@pytest.mark.asyncio
async def test_command_state_publishers_payload():
    m = FakeManager()
    await publishers.publish_assign_seat_command(m, "t1", seat=3, player_id="p1", seq=20)
    await publishers.publish_blind_structure_changed_cc(m, "t1", "bs1", seq=21)
    await publishers.publish_player_updated(m, "t1", "p1", {"photo": "new.jpg"}, seq=22)
    await publishers.publish_table_assigned(m, "t1", "op1", "operator", seq=23)

    assert len(m.calls) == 4
    types = [call[2]["type"] for call in m.calls]
    assert types == [
        "AssignSeatCommand", "BlindStructureChanged", "PlayerUpdated", "TableAssigned",
    ]


@pytest.mark.asyncio
async def test_broadcast_channel_selection():
    """채널 선택 규칙: snake_case/command → lobby/cc 구분, error → cc."""
    m = FakeManager()
    await publishers.publish_clock_detail_changed(m, "t1", {}, seq=1)  # lobby
    await publishers.publish_auth_failed(m, "t1", "u1", "x")  # cc (error)
    await publishers.publish_assign_seat_command(m, "t1", seat=1, player_id="p1")  # cc (command)
    await publishers.publish_player_updated(m, "t1", "p1", {}, seq=2)  # lobby (monitoring)

    channels = [c[0] for c in m.calls]
    assert channels == ["lobby", "cc", "cc", "lobby"]


@pytest.mark.asyncio
async def test_ack_reject_publishers_payload():
    """SG-020 Ack/Reject 6 publisher (WebSocket_Events §9-11) — 모두 cc 채널."""
    m = FakeManager()
    await publishers.publish_game_info_ack(m, "t1", hand_id=248, ready_for_deal=True, seq=30)
    await publishers.publish_game_info_rejected(m, "t1", hand_id=248, reason="invalid_seat", seq=31)
    await publishers.publish_action_ack(m, "t1", hand_id=248, action_index=5, seq=32)
    await publishers.publish_action_rejected(m, "t1", hand_id=248, reason="audit_failed", seq=33)
    await publishers.publish_deal_ack(m, "t1", hand_id=248, phase="PRE_FLOP", seq=34)
    await publishers.publish_deal_rejected(m, "t1", hand_id=248, reason="duplicate_hand_id", seq=35)

    assert len(m.calls) == 6
    types = [call[2]["type"] for call in m.calls]
    assert types == [
        "GameInfoAck", "GameInfoRejected",
        "ActionAck", "ActionRejected",
        "DealAck", "DealRejected",
    ]
    # SG-020 모든 ack/reject 은 cc 채널 (CC sender 가 응답 수신)
    for c in m.calls:
        assert c[0] == "cc", f"ack/reject must use cc channel, got {c[0]}"
    # payload schema 검증
    assert m.calls[0][2]["payload"] == {"hand_id": 248, "ready_for_deal": True}
    assert m.calls[1][2]["payload"] == {"hand_id": 248, "reason": "invalid_seat"}
    assert m.calls[2][2]["payload"] == {"hand_id": 248, "action_index": 5}
    assert m.calls[3][2]["payload"] == {"hand_id": 248, "reason": "audit_failed"}
    assert m.calls[4][2]["payload"] == {"hand_id": 248, "phase": "PRE_FLOP"}
    assert m.calls[5][2]["payload"] == {"hand_id": 248, "reason": "duplicate_hand_id"}
    # seq 전달 확인
    assert [c[2]["seq"] for c in m.calls] == list(range(30, 36))
