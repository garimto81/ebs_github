"""Tests for broker rate_limit (S11 Cycle 8 #340).

Sliding-window per (topic, source) rate limit 검증.

Run:
  pytest tools/orchestrator/message_bus/tests/test_rate_limit.py -v
"""
from __future__ import annotations

import time

import pytest

from tools.orchestrator.message_bus.rate_limit import (
    DEFAULT_TOPIC_LIMITS,
    RateLimiter,
    get_limiter,
)


@pytest.fixture
def limiter():
    """각 테스트마다 격리된 limiter 사용."""
    return RateLimiter(topic_limits={"cascade:build-fail": (3, 60)})


class TestRateLimit:
    def test_under_limit_allowed(self, limiter):
        """한계 이하면 모두 allow."""
        for _ in range(3):
            allowed, reason = limiter.check("cascade:build-fail", "S11")
            assert allowed, reason

    def test_over_limit_throttled(self, limiter):
        """한계 초과 시 throttle."""
        for _ in range(3):
            limiter.check("cascade:build-fail", "S11")
        allowed, reason = limiter.check("cascade:build-fail", "S11")
        assert allowed is False
        assert "rate_limit" in reason
        assert "3/3" in reason

    def test_per_source_independent(self, limiter):
        """source 가 다르면 독립 counting."""
        for _ in range(3):
            limiter.check("cascade:build-fail", "S11")
        # S11 이미 한계 도달했지만 S9 는 처음
        allowed, _ = limiter.check("cascade:build-fail", "S9")
        assert allowed

    def test_per_topic_independent(self, limiter):
        """topic 이 다르면 독립."""
        for _ in range(3):
            limiter.check("cascade:build-fail", "S11")
        # cascade:build-fail 한계 도달 but other topic 무제한 (no_limit)
        allowed, reason = limiter.check("stream:S2", "S11")
        assert allowed
        assert reason == "no_limit"

    def test_undefined_topic_unlimited(self, limiter):
        """미정의 토픽은 무제한."""
        for _ in range(1000):
            allowed, reason = limiter.check("stream:S2", "S11")
            assert allowed
            assert reason == "no_limit"

    def test_window_expiry_releases(self, limiter):
        """window 만료 후 다시 publish 허용."""
        small_limiter = RateLimiter(topic_limits={"cascade:test": (2, 1)})  # 1초 window
        for _ in range(2):
            small_limiter.check("cascade:test", "S11")
        # 한계 도달
        allowed, _ = small_limiter.check("cascade:test", "S11")
        assert allowed is False
        time.sleep(1.2)
        # window 만료 후 다시 허용
        allowed, _ = small_limiter.check("cascade:test", "S11")
        assert allowed

    def test_stats_tracking(self, limiter):
        for _ in range(3):
            limiter.check("cascade:build-fail", "S11")
        limiter.check("cascade:build-fail", "S11")  # throttled
        stats = limiter.stats()
        assert stats["allowed"] == 3
        assert stats["throttled"] == 1
        assert stats["checked"] == 4

    def test_set_limit_runtime_override(self, limiter):
        limiter.set_limit("cascade:build-fail", 10, 60)
        for _ in range(10):
            allowed, _ = limiter.check("cascade:build-fail", "S11")
            assert allowed
        allowed, _ = limiter.check("cascade:build-fail", "S11")
        assert allowed is False

    def test_clear_resets_state(self, limiter):
        for _ in range(3):
            limiter.check("cascade:build-fail", "S11")
        limiter.check("cascade:build-fail", "S11")  # throttled
        limiter.clear()
        # clear 후 다시 가능
        for _ in range(3):
            allowed, _ = limiter.check("cascade:build-fail", "S11")
            assert allowed

    def test_default_topic_limits_includes_build_fail(self):
        """기본 config 에 cascade:build-fail 포함."""
        assert "cascade:build-fail" in DEFAULT_TOPIC_LIMITS
        max_events, window = DEFAULT_TOPIC_LIMITS["cascade:build-fail"]
        assert max_events == 30
        assert window == 60

    def test_singleton_get_limiter(self):
        """get_limiter() 는 singleton."""
        l1 = get_limiter()
        l2 = get_limiter()
        assert l1 is l2
