"""WebSocket event publishers — J2 (2026-04-21).

SG-008 scanner D2 drift 해소 대상 20 event 의 publisher skeleton.

**설계 원칙**:
- 각 publisher 는 payload dict 구성 + `ConnectionManager.broadcast()` 호출
- `seq` 는 caller 가 전달 (DB `audit_event.seq` 와 연계 권장)
- 오류/알림 event 는 broadcast 대신 `manager.send_personal` 고려 가능 (skeleton 은 broadcast 통일)

**TODO 마커**:
- `[TODO-T2-012]` seq 자동 주입 (audit_event 통합 트리거)
- `[TODO-T2-013]` 일부 error event 의 send_personal 전환 (AuthFailed/PermissionDenied/InvalidMessage)
- `[TODO-T2-014]` 실제 trigger 연결 (router/service 에서 호출)

**연동**:
- CCR-050 Clock FSM → clock_detail_changed, clock_reload_requested, tournament_status_changed
- CCR-054 WebSocket 카탈로그 → blind_structure_changed, prize_pool_changed, stack_adjusted, skin_updated
- 오류 계열 → AuthFailed, TableNotFound, PermissionDenied, InvalidMessage, RfidHardwareError, DuplicateCard, CardConflict, SlowConnection, TokenExpiringSoon
- 명령/상태 계열 → AssignSeatCommand, BlindStructureChanged, PlayerUpdated, TableAssigned
"""
from __future__ import annotations

from typing import Any

from .manager import ConnectionManager


# ---------------------------------------------------------------------------
# snake_case state-change events (CCR-050/054)
# ---------------------------------------------------------------------------


async def publish_clock_detail_changed(
    manager: ConnectionManager,
    table_id: str,
    detail: dict,
    *,
    seq: int | None = None,
) -> int:
    """CCR-050: clock 상태 (running/paused/break/endOfDay) 변경 시 발행."""
    return await manager.broadcast("lobby", table_id, {
        "type": "clock_detail_changed",
        "table_id": table_id,
        "detail": detail,
        "seq": seq,  # [TODO-T2-012] seq auto
    })


async def publish_clock_reload_requested(
    manager: ConnectionManager,
    table_id: str,
    reason: str,
    *,
    seq: int | None = None,
) -> int:
    """CCR-050: clock 설정 변경 후 클라이언트에게 재로드 요청."""
    return await manager.broadcast("lobby", table_id, {
        "type": "clock_reload_requested",
        "table_id": table_id,
        "reason": reason,
        "seq": seq,
    })


async def publish_tournament_status_changed(
    manager: ConnectionManager,
    event_id: str,
    status: str,
    *,
    seq: int | None = None,
) -> int:
    """토너먼트 상태 (announced/registering/running/completed) 전환."""
    return await manager.broadcast("lobby", event_id, {
        "type": "tournament_status_changed",
        "event_id": event_id,
        "status": status,
        "seq": seq,
    })


async def publish_blind_structure_changed(
    manager: ConnectionManager,
    table_id: str,
    blind_structure_id: str,
    *,
    seq: int | None = None,
) -> int:
    """블라인드 구조 교체 알림."""
    return await manager.broadcast("lobby", table_id, {
        "type": "blind_structure_changed",
        "table_id": table_id,
        "blind_structure_id": blind_structure_id,
        "seq": seq,
    })


async def publish_prize_pool_changed(
    manager: ConnectionManager,
    event_id: str,
    total: int,
    *,
    seq: int | None = None,
) -> int:
    """프라이즈 풀 갱신 (등록·리엔트리 반영)."""
    return await manager.broadcast("lobby", event_id, {
        "type": "prize_pool_changed",
        "event_id": event_id,
        "total": total,
        "seq": seq,
    })


async def publish_stack_adjusted(
    manager: ConnectionManager,
    table_id: str,
    seat: int,
    delta: int,
    reason: str,
    *,
    seq: int | None = None,
) -> int:
    """운영자 수동 스택 조정."""
    return await manager.broadcast("lobby", table_id, {
        "type": "stack_adjusted",
        "table_id": table_id,
        "seat": seat,
        "delta": delta,
        "reason": reason,
        "seq": seq,
    })


async def publish_skin_updated(
    manager: ConnectionManager,
    table_id: str,
    skin_id: str,
    version: str,
    *,
    seq: int | None = None,
) -> int:
    """스킨 활성화/업데이트 (CCR-015 + SG-004 .gfskin)."""
    return await manager.broadcast("lobby", table_id, {
        "type": "skin_updated",
        "table_id": table_id,
        "skin_id": skin_id,
        "version": version,
        "seq": seq,
    })


# ---------------------------------------------------------------------------
# PascalCase error/notification events
# ---------------------------------------------------------------------------


async def publish_auth_failed(
    manager: ConnectionManager,
    table_id: str,
    user_id: str,
    reason: str,
) -> int:
    """인증 실패 알림. [TODO-T2-013] send_personal 전환."""
    return await manager.broadcast("cc", table_id, {
        "type": "AuthFailed",
        "user_id": user_id,
        "reason": reason,
    })


async def publish_table_not_found(
    manager: ConnectionManager,
    table_id: str,
    requested_id: str,
) -> int:
    """존재하지 않는 테이블 조회 오류."""
    return await manager.broadcast("cc", table_id, {
        "type": "TableNotFound",
        "requested_id": requested_id,
    })


async def publish_permission_denied(
    manager: ConnectionManager,
    table_id: str,
    user_id: str,
    action: str,
) -> int:
    """권한 부족 오류. RBAC 가드 실패 시."""
    return await manager.broadcast("cc", table_id, {
        "type": "PermissionDenied",
        "user_id": user_id,
        "action": action,
    })


async def publish_invalid_message(
    manager: ConnectionManager,
    table_id: str,
    detail: str,
) -> int:
    """클라이언트 메시지 포맷 오류."""
    return await manager.broadcast("cc", table_id, {
        "type": "InvalidMessage",
        "detail": detail,
    })


async def publish_rfid_hardware_error(
    manager: ConnectionManager,
    table_id: str,
    reader_id: str,
    error_code: str,
) -> int:
    """RFID 하드웨어 오류 (SG-006 deck 운영 연동)."""
    return await manager.broadcast("cc", table_id, {
        "type": "RfidHardwareError",
        "reader_id": reader_id,
        "error_code": error_code,
    })


async def publish_duplicate_card(
    manager: ConnectionManager,
    table_id: str,
    card_code: str,
    seats: list[int],
) -> int:
    """동일 카드 UID 가 2 좌석에서 동시 감지 (엔진 오류)."""
    return await manager.broadcast("cc", table_id, {
        "type": "DuplicateCard",
        "card_code": card_code,
        "seats": seats,
    })


async def publish_card_conflict(
    manager: ConnectionManager,
    table_id: str,
    card_code: str,
    expected: int,
    seen: int,
) -> int:
    """카드 좌석 기대값과 실제 감지 불일치."""
    return await manager.broadcast("cc", table_id, {
        "type": "CardConflict",
        "card_code": card_code,
        "expected": expected,
        "seen": seen,
    })


async def publish_slow_connection(
    manager: ConnectionManager,
    table_id: str,
    user_id: str,
    latency_ms: int,
) -> int:
    """WebSocket 연결 지연 경고 (>500ms RTT)."""
    return await manager.broadcast("cc", table_id, {
        "type": "SlowConnection",
        "user_id": user_id,
        "latency_ms": latency_ms,
    })


async def publish_token_expiring_soon(
    manager: ConnectionManager,
    table_id: str,
    user_id: str,
    expires_in_sec: int,
) -> int:
    """JWT 만료 임박 (<5분) 알림. 클라가 refresh 요청."""
    return await manager.broadcast("cc", table_id, {
        "type": "TokenExpiringSoon",
        "user_id": user_id,
        "expires_in_sec": expires_in_sec,
    })


# ---------------------------------------------------------------------------
# Command / state events
# ---------------------------------------------------------------------------


async def publish_assign_seat_command(
    manager: ConnectionManager,
    table_id: str,
    seat: int,
    player_id: str,
    *,
    seq: int | None = None,
) -> int:
    """운영자 → CC 좌석 배정 명령 broadcast."""
    return await manager.broadcast("cc", table_id, {
        "type": "AssignSeatCommand",
        "table_id": table_id,
        "seat": seat,
        "player_id": player_id,
        "seq": seq,
    })


async def publish_blind_structure_changed_cc(
    manager: ConnectionManager,
    table_id: str,
    blind_structure_id: str,
    *,
    seq: int | None = None,
) -> int:
    """CC 채널에 블라인드 구조 변경 알림 (PascalCase 버전)."""
    return await manager.broadcast("cc", table_id, {
        "type": "BlindStructureChanged",
        "table_id": table_id,
        "blind_structure_id": blind_structure_id,
        "seq": seq,
    })


async def publish_player_updated(
    manager: ConnectionManager,
    table_id: str,
    player_id: str,
    changes: dict,
    *,
    seq: int | None = None,
) -> int:
    """플레이어 정보 (이름/사진/국적/stats) 변경 알림."""
    return await manager.broadcast("lobby", table_id, {
        "type": "PlayerUpdated",
        "player_id": player_id,
        "changes": changes,
        "seq": seq,
    })


async def publish_table_assigned(
    manager: ConnectionManager,
    table_id: str,
    operator_id: str,
    role: str,
    *,
    seq: int | None = None,
) -> int:
    """오퍼레이터가 테이블에 배정됨."""
    return await manager.broadcast("lobby", table_id, {
        "type": "TableAssigned",
        "table_id": table_id,
        "operator_id": operator_id,
        "role": role,
    })


__all__ = [
    # snake_case (7)
    "publish_clock_detail_changed",
    "publish_clock_reload_requested",
    "publish_tournament_status_changed",
    "publish_blind_structure_changed",
    "publish_prize_pool_changed",
    "publish_stack_adjusted",
    "publish_skin_updated",
    # PascalCase errors (9)
    "publish_auth_failed",
    "publish_table_not_found",
    "publish_permission_denied",
    "publish_invalid_message",
    "publish_rfid_hardware_error",
    "publish_duplicate_card",
    "publish_card_conflict",
    "publish_slow_connection",
    "publish_token_expiring_soon",
    # PascalCase command/state (4)
    "publish_assign_seat_command",
    "publish_blind_structure_changed_cc",
    "publish_player_updated",
    "publish_table_assigned",
]
