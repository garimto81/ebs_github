"""Tests for hook_integration helpers (used by .claude/hooks/)."""
import json
from unittest.mock import patch, MagicMock

from tools.chat_server import hook_integration as hi


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
