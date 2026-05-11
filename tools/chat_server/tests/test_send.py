"""Tests for POST /chat/send."""
import re
import pytest
from unittest.mock import AsyncMock


@pytest.fixture
def mock_broker(monkeypatch):
    mock = AsyncMock()
    mock.publish.return_value = {
        "seq": 99,
        "ts": "2026-05-11T15:35:00Z",
        "topic": "chat:room:design",
        "recipients": 3,
    }
    monkeypatch.setattr("tools.chat_server.server.broker", mock)
    return mock


def test_send_basic(client, mock_broker):
    r = client.post("/chat/send", json={
        "channel": "room:design",
        "body": "hello",
    })
    assert r.status_code == 200
    body = r.json()
    assert body["seq"] == 99
    mock_broker.publish.assert_called_once()
    kwargs = mock_broker.publish.call_args.kwargs
    assert kwargs["topic"] == "chat:room:design"
    assert kwargs["source"] == "user"
    assert kwargs["payload"]["from"] == "user"
    assert kwargs["payload"]["body"] == "hello"


def test_send_with_mentions(client, mock_broker):
    r = client.post("/chat/send", json={
        "channel": "room:design",
        "body": "@S3 quick question",
    })
    assert r.status_code == 200
    kwargs = mock_broker.publish.call_args.kwargs
    assert "@S3" in kwargs["payload"]["mentions"]


def test_send_with_reply_to(client, mock_broker):
    r = client.post("/chat/send", json={
        "channel": "room:design",
        "body": "agreed",
        "reply_to": 42,
    })
    assert r.status_code == 200
    kwargs = mock_broker.publish.call_args.kwargs
    assert kwargs["payload"]["reply_to"] == 42
    assert kwargs["payload"]["kind"] == "reply"


def test_send_body_too_long(client, mock_broker):
    r = client.post("/chat/send", json={
        "channel": "room:design",
        "body": "x" * 5000,
    })
    assert r.status_code == 422


def test_send_kind_msg_when_no_reply_to(client, mock_broker):
    r = client.post("/chat/send", json={
        "channel": "room:design",
        "body": "hi",
    })
    assert r.status_code == 200
    kwargs = mock_broker.publish.call_args.kwargs
    assert kwargs["payload"]["kind"] == "msg"
