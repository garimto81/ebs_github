"""Shared pytest fixtures for chat-server tests."""
from __future__ import annotations

import pytest
from fastapi.testclient import TestClient

from tools.chat_server.server import app


def pytest_configure(config):
    config.addinivalue_line(
        "markers", "integration: requires live broker"
    )
    config.addinivalue_line(
        "markers", "load: chat-server load + perf benchmarks (requires broker live)"
    )
    config.addinivalue_line(
        "markers", "resilience: SPOF recovery scenarios (broker kill/restart)"
    )


@pytest.fixture
def client():
    return TestClient(app)
