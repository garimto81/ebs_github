"""Shared pytest fixtures for chat-server tests."""
from __future__ import annotations

import pytest
from fastapi.testclient import TestClient

from tools.chat_server.server import app


@pytest.fixture
def client():
    return TestClient(app)
