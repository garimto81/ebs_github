"""Shared pytest fixtures for chat-server tests."""
from __future__ import annotations

import pytest
from fastapi.testclient import TestClient

from tools.chat_server.server import app


def pytest_configure(config):
    config.addinivalue_line(
        "markers", "integration: requires live broker"
    )


@pytest.fixture
def client():
    return TestClient(app)
