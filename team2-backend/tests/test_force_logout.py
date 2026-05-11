"""IMPL-009 / Cycle 3 — force_logout service unit tests.

직접 service 호출 + ConnectionManager mock 으로 검증. FastAPI app fixture
(decks.py 204 baseline 이슈 회피용 — 본 모듈은 router 가 아닌 service 만 부하).

검증 항목:
  - access / refresh jti blacklist 등록
  - user_sessions 행 전체 삭제 (단일 + 다중 device)
  - audit_events row 삽입 (table_id="_global", event_type="force_logout")
  - 만료된 token 의 jti 는 blacklist skip
  - ConnectionManager.disconnect_user 가 대상 user 의 cc + lobby ws 만 끊고
    cc_session_count broadcast 트리거
"""
from __future__ import annotations

import json
from datetime import datetime, timedelta, timezone

import pytest
from sqlmodel import Session, SQLModel, create_engine, select

from src.models.audit_event import AuditEvent
from src.models.user import User, UserSession
from src.security import blacklist
from src.security.jwt import create_access_token, create_refresh_token
from src.services.auth_service import (
    _decode_jti_and_remaining_ttl,
    force_logout_user,
)


# ── Fixtures ─────────────────────────────────────────────────────────


@pytest.fixture()
def db_session():
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
    )
    SQLModel.metadata.create_all(engine)
    with Session(engine) as session:
        yield session
    engine.dispose()


@pytest.fixture(autouse=True)
def _reset_blacklist():
    blacklist.reset_for_test()
    yield
    blacklist.reset_for_test()


@pytest.fixture()
def target_user(db_session: Session) -> User:
    u = User(
        email="target@ebs.test",
        password_hash="$2b$12$placeholder",
        display_name="Target",
        role="operator",
        is_active=True,
    )
    db_session.add(u)
    db_session.commit()
    db_session.refresh(u)
    return u


# ── _decode_jti_and_remaining_ttl ─────────────────────────────────


def test_decode_jti_returns_remaining_ttl():
    token = create_access_token(user_id=42, email="x@y", role="admin")
    jti, ttl = _decode_jti_and_remaining_ttl(token)
    assert jti is not None
    assert ttl > 0


def test_decode_jti_returns_none_for_invalid():
    jti, ttl = _decode_jti_and_remaining_ttl("not-a-jwt")
    assert jti is None and ttl == 0


def test_decode_jti_zero_ttl_for_expired_token():
    jti, ttl = _decode_jti_and_remaining_ttl(None)
    assert jti is None and ttl == 0


# ── force_logout_user — DB-side behavior ──────────────────────────


def test_force_logout_blacklists_jti_and_deletes_sessions(
    db_session: Session, target_user: User
):
    access = create_access_token(target_user.user_id, target_user.email, target_user.role)
    refresh = create_refresh_token(target_user.user_id)
    sess = UserSession(
        user_id=target_user.user_id,
        device_id="default",
        access_token=access,
        refresh_token=refresh,
    )
    db_session.add(sess)
    db_session.commit()

    result = force_logout_user(
        target_user_id=target_user.user_id,
        actor_user_id=1,
        db=db_session,
        reason="security incident",
    )

    assert result["deleted_sessions"] == 1
    assert result["blacklisted_jtis"] == 2  # access + refresh
    assert result["audit_event_id"] is not None

    # user_sessions 행 모두 삭제
    remaining = db_session.exec(
        select(UserSession).where(UserSession.user_id == target_user.user_id)
    ).all()
    assert remaining == []

    # jti 가 blacklist 에 등록되었는지 확인 — payload decode 후 jti 확인
    from src.security.jwt import decode_token
    access_jti = decode_token(access)["jti"]
    refresh_jti = decode_token(refresh)["jti"]
    assert blacklist.is_revoked(access_jti) is True
    assert blacklist.is_revoked(refresh_jti) is True


def test_force_logout_multiple_devices(db_session: Session, target_user: User):
    """다중 device session 모두 한 번에 종료."""
    for device in ("lobby", "cc"):
        access = create_access_token(
            target_user.user_id, target_user.email, target_user.role
        )
        refresh = create_refresh_token(target_user.user_id)
        db_session.add(UserSession(
            user_id=target_user.user_id,
            device_id=device,
            access_token=access,
            refresh_token=refresh,
        ))
    db_session.commit()

    result = force_logout_user(
        target_user_id=target_user.user_id,
        actor_user_id=99,
        db=db_session,
    )

    assert result["deleted_sessions"] == 2
    assert result["blacklisted_jtis"] == 4  # 2 device × (access + refresh)


def test_force_logout_inserts_audit_event(db_session: Session, target_user: User):
    access = create_access_token(target_user.user_id, target_user.email, target_user.role)
    db_session.add(UserSession(
        user_id=target_user.user_id,
        device_id="default",
        access_token=access,
        refresh_token=None,
    ))
    db_session.commit()

    force_logout_user(
        target_user_id=target_user.user_id,
        actor_user_id=7,
        db=db_session,
        reason="kicked",
    )

    audit = db_session.exec(
        select(AuditEvent).where(AuditEvent.event_type == "force_logout")
    ).first()
    assert audit is not None
    assert audit.table_id == "_global"
    assert audit.seq == 1
    assert audit.actor_user_id == "7"
    body = json.loads(audit.payload)
    assert body["target_user_id"] == target_user.user_id
    assert body["reason"] == "kicked"
    assert body["deleted_sessions"] == 1


def test_force_logout_with_no_sessions_is_noop(
    db_session: Session, target_user: User
):
    """user_sessions 행이 없어도 audit_events 만 기록되고 성공."""
    result = force_logout_user(
        target_user_id=target_user.user_id,
        actor_user_id=1,
        db=db_session,
    )
    assert result["deleted_sessions"] == 0
    assert result["blacklisted_jtis"] == 0
    assert result["audit_event_id"] is not None


def test_force_logout_audit_seq_monotonic(db_session: Session, target_user: User):
    """audit_events.seq 가 _global 범위 안에서 단조증가."""
    force_logout_user(target_user_id=target_user.user_id, actor_user_id=1, db=db_session)
    force_logout_user(target_user_id=target_user.user_id, actor_user_id=2, db=db_session)
    seqs = [
        row.seq for row in db_session.exec(
            select(AuditEvent)
            .where(AuditEvent.event_type == "force_logout")
            .order_by(AuditEvent.seq)
        ).all()
    ]
    assert seqs == [1, 2]


# ── ConnectionManager.disconnect_user — WS-side behavior ──────────


class _FakeWebSocket:
    """ConnectionManager 가 WebSocket 인터페이스에서 호출하는 메서드만 stub."""

    def __init__(self):
        self.sent_messages: list[str] = []
        self.close_calls: list[int] = []
        self.closed = False

    async def send_text(self, message: str) -> None:
        if self.closed:
            raise RuntimeError("send after close")
        self.sent_messages.append(message)

    async def close(self, code: int = 1000) -> None:
        self.close_calls.append(code)
        self.closed = True


@pytest.mark.asyncio
async def test_disconnect_user_closes_only_target_connections():
    from src.websocket.manager import ConnectionManager
    mgr = ConnectionManager()

    target_ws_cc = _FakeWebSocket()
    target_ws_lobby = _FakeWebSocket()
    other_ws_cc = _FakeWebSocket()
    mgr._connections["cc"].append((target_ws_cc, {"user_id": "42", "role": "operator"}))
    mgr._connections["cc"].append((other_ws_cc, {"user_id": "7", "role": "admin"}))
    mgr._connections["lobby"].append((target_ws_lobby, {"user_id": "42", "role": "operator"}))

    payload = {"type": "force_logout", "payload": {"target_user_id": "42"}}
    closed = await mgr.disconnect_user(user_id="42", payload=payload, close_code=4003)

    assert closed == 2
    assert target_ws_cc.closed is True
    assert target_ws_cc.close_calls == [4003]
    assert target_ws_lobby.closed is True
    assert target_ws_lobby.close_calls == [4003]
    assert other_ws_cc.closed is False  # 다른 user 영향 없음

    # target connection 들이 registry 에서 제거되었는지
    assert len(mgr._connections["cc"]) == 1
    assert mgr._connections["cc"][0][1]["user_id"] == "7"
    assert mgr._connections["lobby"] == []


@pytest.mark.asyncio
async def test_disconnect_user_broadcasts_cc_session_count_when_cc_affected():
    """cc 채널 연결이 끊긴 경우 cc_session_count 가 lobby 로 broadcast 되어야 함."""
    from src.websocket.manager import ConnectionManager
    mgr = ConnectionManager()

    target_ws_cc = _FakeWebSocket()
    lobby_subscriber = _FakeWebSocket()
    mgr._connections["cc"].append((target_ws_cc, {"user_id": "42"}))
    mgr._connections["lobby"].append((lobby_subscriber, {"user_id": "99"}))

    await mgr.disconnect_user(
        user_id="42",
        payload={"type": "force_logout", "payload": {}},
        close_code=4003,
    )

    # lobby subscriber 가 cc_session_count 메시지를 받았는지 확인
    cc_count_msgs = [
        json.loads(m) for m in lobby_subscriber.sent_messages
        if json.loads(m).get("type") == "cc_session_count"
    ]
    assert len(cc_count_msgs) == 1
    assert cc_count_msgs[0]["data"]["count"] == 0


@pytest.mark.asyncio
async def test_disconnect_user_no_match_noop():
    from src.websocket.manager import ConnectionManager
    mgr = ConnectionManager()
    other = _FakeWebSocket()
    mgr._connections["cc"].append((other, {"user_id": "99"}))

    closed = await mgr.disconnect_user(
        user_id="42",
        payload={"type": "force_logout"},
    )
    assert closed == 0
    assert other.closed is False
