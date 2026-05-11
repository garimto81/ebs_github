"""Tests for tools/chat_server/cli.py."""
import json
from unittest.mock import patch, AsyncMock

from tools.chat_server import cli


def test_cli_send_invokes_broker_publish(monkeypatch, capsys):
    mock_pub = AsyncMock(return_value={"seq": 99, "ts": "t"})
    monkeypatch.setattr("tools.chat_server.cli._broker_publish", mock_pub)
    rc = cli.main(["send", "--channel", "room:design", "@S3 hi"])
    assert rc == 0
    mock_pub.assert_called_once()
    args = mock_pub.call_args.kwargs
    assert args["topic"] == "chat:room:design"
    assert args["payload"]["body"] == "@S3 hi"
    assert "@S3" in args["payload"]["mentions"]


def test_cli_history_prints_messages(monkeypatch, capsys):
    mock_h = AsyncMock(return_value={
        "events": [
            {
                "seq": 1, "topic": "chat:room:design", "source": "S2",
                "ts": "2026-05-11T15:30:00Z",
                "payload": {"from": "S2", "body": "hello", "kind": "msg"},
            }
        ],
        "count": 1,
    })
    monkeypatch.setattr("tools.chat_server.cli._broker_history", mock_h)
    rc = cli.main(["history", "room:design", "--last", "10"])
    assert rc == 0
    out = capsys.readouterr().out
    assert "S2" in out
    assert "hello" in out
