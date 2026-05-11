"""Tests for hook_integration helpers (used by .claude/hooks/)."""
import json
from unittest.mock import patch, MagicMock

from tools.chat_server import hook_integration as hi  # noqa: F401 (json used by appended tests)


def test_emit_chat_advisory_skips_when_no_impact():
    with patch("tools.chat_server.hook_integration._publish_sync") as pub:
        hi.emit_chat_advisory("docs/X.md", impacted=[], editor_team="S2")
        pub.assert_not_called()


def test_emit_chat_advisory_publishes_with_mentions():
    with patch("tools.chat_server.hook_integration._publish_sync") as pub, \
         patch("tools.chat_server.hook_integration._resolve_owner_streams") as resolve:
        resolve.return_value = ["S3", "S7"]
        hi.emit_chat_advisory(
            "docs/Foundation.md",
            impacted=["docs/Lobby_PRD.md", "docs/CC_PRD.md"],
            editor_team="S1",
        )
        pub.assert_called_once()
        kwargs = pub.call_args.kwargs
        assert kwargs["topic"] == "chat:room:design"
        assert kwargs["source"] == "S1"
        payload = kwargs["payload"]
        assert payload["kind"] == "system"
        assert payload["from"] == "S1"
        assert "@S3" in payload["mentions"]
        assert "@S7" in payload["mentions"]
        assert "Foundation.md" in payload["body"]


def test_emit_chat_advisory_silent_when_broker_down():
    with patch("tools.chat_server.hook_integration._publish_sync",
               side_effect=Exception("broker dead")):
        # 예외 발생해도 hook 진행 막지 않음 (silent skip)
        hi.emit_chat_advisory("docs/X.md", impacted=["docs/Y.md"], editor_team="S2")


def test_inject_chat_mentions_returns_empty_when_no_mentions(tmp_path):
    state_file = tmp_path / "chat_last_seen_S2.json"
    with patch("tools.chat_server.hook_integration._subscribe_sync") as sub:
        sub.return_value = {"events": [], "next_seq": 0}
        result = hi.inject_chat_mentions(team_id="S2", state_file=state_file)
    assert result == []


def test_inject_chat_mentions_filters_by_team(tmp_path):
    state_file = tmp_path / "chat_last_seen_S2.json"
    with patch("tools.chat_server.hook_integration._subscribe_sync") as sub:
        sub.return_value = {
            "events": [
                {
                    "seq": 10, "topic": "chat:room:design",
                    "source": "user", "ts": "2026-05-11T16:00:00Z",
                    "payload": {"mentions": ["@S2"], "body": "ping", "from": "user"},
                },
                {
                    "seq": 11, "topic": "chat:room:design",
                    "source": "user", "ts": "2026-05-11T16:01:00Z",
                    "payload": {"mentions": ["@S3"], "body": "ping3", "from": "user"},
                },
            ],
            "next_seq": 12,
        }
        result = hi.inject_chat_mentions(team_id="S2", state_file=state_file)
    assert len(result) == 1
    assert result[0]["seq"] == 10
    import json as J
    assert J.loads(state_file.read_text())["last_seq"] == 12


def test_inject_chat_mentions_silent_when_broker_down(tmp_path):
    state_file = tmp_path / "chat_last_seen_S2.json"
    with patch("tools.chat_server.hook_integration._subscribe_sync",
               side_effect=Exception("broker dead")):
        result = hi.inject_chat_mentions(team_id="S2", state_file=state_file)
    assert result == []


import asyncio


def _async_run(coro):
    return asyncio.run(coro)


def test_consensus_returns_replies_when_answered():
    """When a reply arrives before TTL, return ('answered', replies)."""
    with patch("tools.chat_server.hook_integration._subscribe_async") as sub:
        sub.return_value = {
            "events": [
                {
                    "seq": 43, "topic": "chat:room:design",
                    "source": "S3", "ts": "2026-05-11T16:01:00Z",
                    "payload": {"reply_to": 42, "body": "ok"},
                }
            ],
            "next_seq": 44,
        }
        outcome, replies = _async_run(
            hi.consensus_silent_ok(
                question_seq=42, topic="chat:room:design",
                from_team="S2", ttl_sec=2,
            )
        )
    assert outcome == "answered"
    assert len(replies) == 1


def test_consensus_silent_ok_after_ttl():
    """When no reply within TTL, return ('silent_ok', [])."""
    with patch("tools.chat_server.hook_integration._subscribe_async") as sub, \
         patch("tools.chat_server.hook_integration._publish_async") as pub:
        sub.return_value = {"events": [], "next_seq": 43}
        outcome, replies = _async_run(
            hi.consensus_silent_ok(
                question_seq=42, topic="chat:room:design",
                from_team="S2", ttl_sec=1,
            )
        )
    assert outcome == "silent_ok"
    assert replies == []
    pub.assert_called_once()
    payload = pub.call_args.kwargs["payload"]
    assert payload["kind"] == "decision"
    assert payload["reply_to"] == 42


def test_consensus_user_mention_disables_silent_ok():
    """@user 멘션이 question 메시지에 있으면 silent_ok 비활성, 사용자 응답 대기."""
    with patch("tools.chat_server.hook_integration._subscribe_async") as sub, \
         patch("tools.chat_server.hook_integration._publish_async") as pub:
        sub.return_value = {"events": [], "next_seq": 43}
        outcome, replies = _async_run(
            hi.consensus_silent_ok(
                question_seq=42, topic="chat:room:design",
                from_team="S2", ttl_sec=1,
                question_mentions=["@user", "@S3"],
            )
        )
    assert outcome == "user_mention_pending"
    assert replies == []
    pub.assert_not_called()
