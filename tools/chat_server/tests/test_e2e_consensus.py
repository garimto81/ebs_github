"""E2E — 2 세션 합의 시나리오 (spec §12 시연).

Prereq:
  - broker 실행 중 (python tools/orchestrator/start_message_bus.py --detach)

Run:
  pytest tools/chat_server/tests/test_e2e_consensus.py -v -m integration
"""
import asyncio
import os
from datetime import datetime, timezone

import pytest

from tools.chat_server.broker_client import BrokerClient
from tools.chat_server.hook_integration import consensus_silent_ok


BROKER_URL = os.environ.get("BROKER_URL", "http://127.0.0.1:7383/mcp")


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
        pytest.skip("broker not running — start with start_message_bus.py --detach")


@pytest.mark.integration
@pytest.mark.asyncio
async def test_e2e_consensus_answered(broker_alive):
    """S2 질문 → S3 1초 후 reply → consensus returns 'answered'."""
    client = BrokerClient(url=BROKER_URL)
    topic = "chat:room:design"

    r = await client.publish(
        topic=topic,
        payload={
            "kind": "msg", "from": "S2", "to": ["S3"],
            "body": "@S3 rake 누적 OK?",
            "mentions": ["@S3"], "reply_to": None,
            "thread_id": None, "ts": _now_iso(),
        },
        source="S2",
    )
    question_seq = r["seq"]

    async def s3_reply():
        await asyncio.sleep(1)
        await client.publish(
            topic=topic,
            payload={
                "kind": "reply", "from": "S3", "to": ["S2"],
                "body": "CC는 flat. Lobby 누적 OK.",
                "mentions": ["@S2"], "reply_to": question_seq,
                "thread_id": None, "ts": _now_iso(),
            },
            source="S3",
        )

    reply_task = asyncio.create_task(s3_reply())

    outcome, replies = await consensus_silent_ok(
        question_seq=question_seq, topic=topic,
        from_team="S2", ttl_sec=5,
    )
    await reply_task

    assert outcome == "answered"
    assert len(replies) >= 1
    assert any(e["payload"]["reply_to"] == question_seq for e in replies)


@pytest.mark.integration
@pytest.mark.asyncio
async def test_e2e_consensus_silent_ok(broker_alive):
    """S2 질문 → 아무도 reply 안 함 (TTL 2s) → silent_ok + decision publish."""
    client = BrokerClient(url=BROKER_URL)
    topic = "chat:room:design"

    r = await client.publish(
        topic=topic,
        payload={
            "kind": "msg", "from": "S2", "to": [],
            "body": "(silent test) proceeding with default",
            "mentions": [], "reply_to": None,
            "thread_id": None, "ts": _now_iso(),
        },
        source="S2",
    )
    question_seq = r["seq"]

    outcome, replies = await consensus_silent_ok(
        question_seq=question_seq, topic=topic,
        from_team="S2", ttl_sec=2,
    )

    assert outcome == "silent_ok"
    assert replies == []

    h = await client.get_history(topic=topic, since_seq=question_seq, limit=20)
    decisions = [
        e for e in h["events"]
        if e["payload"].get("kind") == "decision"
        and e["payload"].get("reply_to") == question_seq
    ]
    assert len(decisions) == 1


@pytest.mark.integration
@pytest.mark.asyncio
async def test_e2e_user_mention_blocks_silent_ok(broker_alive):
    """@user 멘션 포함 → silent_ok 비활성. 사용자 응답 대기."""
    client = BrokerClient(url=BROKER_URL)
    topic = "chat:room:design"

    r = await client.publish(
        topic=topic,
        payload={
            "kind": "msg", "from": "S2", "to": ["user"],
            "body": "@user 결정 필요",
            "mentions": ["@user"], "reply_to": None,
            "thread_id": None, "ts": _now_iso(),
        },
        source="S2",
    )
    question_seq = r["seq"]

    outcome, replies = await consensus_silent_ok(
        question_seq=question_seq, topic=topic,
        from_team="S2", ttl_sec=2,
        question_mentions=["@user"],
    )

    assert outcome == "user_mention_pending"
    assert replies == []
