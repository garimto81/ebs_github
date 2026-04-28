"""M1 Item 3 — 다중 세션 (Lobby + CC) 회귀 가드.

BS-01 §A-25 SSOT: 최대 동시 세션 2개 (1 Lobby + 1 CC). device_id 별 분리.

본 테스트는 service layer (create_session) 에서 device_id 별 row 분리를 검증.
HTTP route layer 의 X-Device-Id 헤더 파싱은 PR 4 (D+1 후속) 에서 추가.
"""
import pytest
from sqlmodel import select

from src.models.user import UserSession
from src.services.auth_service import create_session


def test_two_devices_create_separate_rows(db_session, seed_users):
    """동일 user 가 device_id="lobby" + "cc" 로 호출 → 2 row 분리 + 양 토큰 valid."""
    user = seed_users["operator"]

    a_access, _, _, _ = create_session(user, db_session, device_id="lobby")
    b_access, _, _, _ = create_session(user, db_session, device_id="cc")

    rows = db_session.exec(
        select(UserSession).where(UserSession.user_id == user.user_id)
    ).all()
    assert len(rows) == 2, (
        "device_id 별 row 분리되어야 함 — UNIQUE(user_id, device_id) 복합 키 동작 확인"
    )

    devices = sorted(r.device_id for r in rows)
    assert devices == ["cc", "lobby"]

    # 각 row 가 자기 토큰 보유
    tokens = {r.device_id: r.access_token for r in rows}
    assert tokens["lobby"] == a_access
    assert tokens["cc"] == b_access
    assert a_access != b_access


def test_same_device_id_upserts_existing_row(db_session, seed_users):
    """동일 user + 동일 device_id 로 재로그인 → row 1개 유지 + 토큰 갱신 (UNIQUE 충돌 회피)."""
    user = seed_users["operator"]

    first_access, _, _, _ = create_session(user, db_session, device_id="lobby")
    second_access, _, _, _ = create_session(user, db_session, device_id="lobby")

    rows = db_session.exec(
        select(UserSession).where(UserSession.user_id == user.user_id)
    ).all()
    assert len(rows) == 1, "동일 (user_id, device_id) 는 UPSERT 되어야 함 (UNIQUE 충돌 X)"
    assert rows[0].access_token == second_access
    assert rows[0].access_token != first_access  # 토큰은 새로 발급


def test_default_device_id_backward_compat(db_session, seed_users):
    """device_id 미명시 호출 (기존 코드 경로) → device_id="default" 단일 row."""
    user = seed_users["viewer"]

    create_session(user, db_session)  # device_id 미명시

    rows = db_session.exec(
        select(UserSession).where(UserSession.user_id == user.user_id)
    ).all()
    assert len(rows) == 1
    assert rows[0].device_id == "default"
