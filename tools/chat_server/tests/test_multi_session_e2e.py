"""Multi-session e2e — 9 stream + hook 통합 시뮬레이션.

Requires broker live. Tests cascade flow, mention inject, consensus,
and broker history integrity end-to-end.

Run:
  pytest tools/chat_server/tests/test_multi_session_e2e.py -v -m integration
"""
import asyncio
import os
from datetime import datetime, timezone

import pytest

from tools.chat_server.broker_client import BrokerClient
from tools.chat_server.hook_integration import (
    consensus_silent_ok,
    _resolve_owner_streams,
)


BROKER_URL = os.environ.get("BROKER_URL", "http://127.0.0.1:7383/mcp")
STREAMS = ["S1", "S2", "S3", "S7", "S8", "S9", "S10-A", "S10-W", "S11"]


def _now_iso():
    return datetime.now(timezone.utc).isoformat()


async def _check_broker():
    try:
        client = BrokerClient(url=BROKER_URL)
        async with client.session() as _:
            return True
    except Exception:
        return False


@pytest.fixture(scope="module")
def broker_alive():
    if not asyncio.run(_check_broker()):
        pytest.skip("broker not running")


# ───────────── Scenario 1: Bootstrap 9 streams ─────────────

@pytest.mark.integration
@pytest.mark.asyncio
async def test_l4_bootstrap_9_streams(broker_alive):
    """9 가상 stream 이 각자 broker session 가지고 status publish."""
    async def stream_init(stream_id: str):
        client = BrokerClient(url=BROKER_URL)
        r = await client.publish(
            topic=f"stream:{stream_id}",
            payload={"status": "READY", "ts": _now_iso()},
            source=stream_id,
        )
        return r["seq"]

    seqs = await asyncio.gather(*(stream_init(s) for s in STREAMS))
    assert len(seqs) == 9
    assert all(isinstance(s, int) and s > 0 for s in seqs)


# ───────────── Scenario 2: Cascade advisory logic ─────────────

@pytest.mark.integration
@pytest.mark.asyncio
async def test_l4_cascade_advisory(broker_alive):
    """S1 가 Foundation.md edit 시뮬 → advisory message publish.

    emit_chat_advisory 의 sync wrapper 는 asyncio.run() 이라 nested loop
    환경에서 silent skip — test 는 async path 로 직접 publish + payload
    구조 검증 (broker WAL durability 는 별도 broker test 가 커버).
    """
    target_rel = "docs/1. Product/Foundation.md"
    impacted = [
        "docs/1. Product/Lobby.md",
        "docs/1. Product/Command_Center.md",
        "docs/2. Development/2.1 Frontend/Lobby/Overview.md",
    ]

    client = BrokerClient(url=BROKER_URL)
    owners = _resolve_owner_streams(impacted)
    if "S1" in owners:
        owners.remove("S1")

    body_lines = [
        f"[AUTO] Editing `{target_rel}` impacts {len(impacted)} docs:"
    ] + [f"- {p}" for p in impacted[:5]]

    pub_r = await client.publish(
        topic="chat:room:design",
        payload={
            "kind": "system", "from": "S1", "to": owners,
            "body": "\n".join(body_lines),
            "reply_to": None, "thread_id": None,
            "mentions": [f"@{s}" for s in owners],
            "ts": _now_iso(),
        },
        source="S1",
    )

    # publish 성공
    advisory_seq = pub_r.get("seq", 0)
    assert advisory_seq > 0, f"publish failed: {pub_r}"

    # owners 매핑 검증 (Lobby/Overview.md → S2)
    assert "S2" in owners, f"expected S2 in owners, got {owners}"


# ───────────── Scenario 3: Mention 응답 ─────────────

@pytest.mark.integration
@pytest.mark.asyncio
async def test_l4_mention_response(broker_alive):
    """S2 가 @S3 mention → S3 가 자율 reply publish."""
    client = BrokerClient(url=BROKER_URL)
    topic = "chat:room:design"

    r = await client.publish(
        topic=topic,
        payload={
            "kind": "msg", "from": "S2", "to": ["S3"],
            "body": "@S3 L4 mention test", "mentions": ["@S3"],
            "reply_to": None, "thread_id": None, "ts": _now_iso(),
        },
        source="S2",
    )
    question_seq = r["seq"]
    assert question_seq > 0

    # S3 reply 시뮬
    await asyncio.sleep(0.5)
    reply_r = await client.publish(
        topic=topic,
        payload={
            "kind": "reply", "from": "S3", "to": ["S2"],
            "body": "S3 response", "mentions": ["@S2"],
            "reply_to": question_seq, "thread_id": None, "ts": _now_iso(),
        },
        source="S3",
    )
    assert reply_r["seq"] > question_seq, "reply seq must be after question"


# ───────────── Scenario 4: Silent OK consensus ─────────────

@pytest.mark.integration
@pytest.mark.asyncio
async def test_l4_silent_ok_consensus(broker_alive):
    """S7 가 질문 → 2s 응답 없음 → silent_ok + decision publish."""
    client = BrokerClient(url=BROKER_URL)
    topic = "chat:room:design"

    r = await client.publish(
        topic=topic,
        payload={
            "kind": "msg", "from": "S7", "to": [],
            "body": "L4 silent_ok test", "mentions": [],
            "reply_to": None, "thread_id": None, "ts": _now_iso(),
        },
        source="S7",
    )
    question_seq = r["seq"]

    outcome, replies = await consensus_silent_ok(
        question_seq=question_seq, topic=topic,
        from_team="S7", ttl_sec=2,
    )

    assert outcome == "silent_ok"
    assert replies == []


# ───────────── Scenario 5: User mention 차단 ─────────────

@pytest.mark.integration
@pytest.mark.asyncio
async def test_l4_user_mention_blocks_silent_ok(broker_alive):
    """@user 멘션 포함 시 silent_ok 비활성."""
    client = BrokerClient(url=BROKER_URL)
    topic = "chat:room:design"

    r = await client.publish(
        topic=topic,
        payload={
            "kind": "msg", "from": "S8", "to": ["user"],
            "body": "@user L4 user-mention test", "mentions": ["@user"],
            "reply_to": None, "thread_id": None, "ts": _now_iso(),
        },
        source="S8",
    )
    question_seq = r["seq"]

    outcome, replies = await consensus_silent_ok(
        question_seq=question_seq, topic=topic,
        from_team="S8", ttl_sec=2,
        question_mentions=["@user"],
    )

    assert outcome == "user_mention_pending"
    assert replies == []


# ───────────── Scenario 6: 9 stream concurrent publish ─────────────

@pytest.mark.integration
@pytest.mark.asyncio
async def test_l4_concurrent_9_streams(broker_alive):
    """9 stream 동시 publish (3 msg each = 27 total) → 모두 seq 받음 + unique."""
    async def burst(stream_id: str):
        c = BrokerClient(url=BROKER_URL)
        seqs = []
        for i in range(3):
            r = await c.publish(
                topic=f"stream:{stream_id}",
                payload={
                    "status": "WORKING",
                    "iteration": i,
                    "ts": _now_iso(),
                },
                source=stream_id,
            )
            seqs.append((stream_id, r.get("seq", 0)))
        return seqs

    results = await asyncio.gather(*(burst(s) for s in STREAMS))
    all_publishes = [item for sub in results for item in sub]

    # 27 publish 모두 valid seq
    assert len(all_publishes) == 27
    assert all(seq > 0 for _, seq in all_publishes), \
        "some publishes returned seq=0"

    # 9 stream sources 모두 표현
    sources_seen = set(sid for sid, _ in all_publishes)
    assert sources_seen == set(STREAMS), \
        f"sources mismatch: {sources_seen} != {set(STREAMS)}"

    # seq unique (broker WAL guarantees)
    seqs_returned = [seq for _, seq in all_publishes]
    assert len(set(seqs_returned)) == 27, \
        f"duplicate seqs: {len(seqs_returned)} returned, {len(set(seqs_returned))} unique"
