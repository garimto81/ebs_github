"""Tests for observer_loop dispatch dedup + severity filter (S11 Cycle 8 #340).

Run:
  pytest tools/orchestrator/message_bus/tests/test_observer_dispatch_dedup.py -v
"""
from __future__ import annotations

import time

import pytest

from tools.orchestrator.message_bus import observer_loop as ol


class _FakePath:
    """relative_to() 가 ValueError 던지면 그대로 fallback 됨."""

    def __init__(self, p):
        self._p = p

    def relative_to(self, root):
        raise ValueError("test stub")

    def __str__(self):
        return self._p


@pytest.fixture(autouse=True)
def reset_dispatch_state():
    """각 테스트 전 dispatch cache + stats 초기화."""
    ol._DISPATCH_DEDUP_CACHE.clear()
    for k in ol._DISPATCH_STATS:
        ol._DISPATCH_STATS[k] = 0
    yield


def _build_event(topic="cascade:build-fail", severity="critical", matched="pytest", action_type="inbox-drop"):
    return {
        "seq": 1,
        "topic": topic,
        "source": "S11",
        "ts": "2026-05-12T00:00:00Z",
        "payload": {
            "severity": severity,
            "matched_pattern": matched,
            "filter_version": "v4",
            "next_action": {"type": action_type, "target": "S10-A"},
        },
    }


class TestSeverityFilter:
    """min_severity 미만의 severity 는 dispatch skip."""

    def test_critical_passes_min_warning(self, monkeypatch):
        called = []
        monkeypatch.setattr(ol, "_dispatch_inbox_drop", lambda e, a: called.append(1) or _FakePath("/tmp/x"))
        evt = _build_event(severity="critical")
        ol._dispatch_action(evt, min_severity_level=1)  # min=warning
        assert called

    def test_warning_skipped_when_min_critical(self, monkeypatch):
        called = []
        monkeypatch.setattr(ol, "_dispatch_inbox_drop", lambda e, a: called.append(1) or _FakePath("/tmp/x"))
        evt = _build_event(severity="warning")
        ol._dispatch_action(evt, min_severity_level=2)  # min=critical
        assert not called
        assert ol._DISPATCH_STATS["skipped_severity"] == 1

    def test_info_skipped_when_min_warning(self, monkeypatch):
        called = []
        monkeypatch.setattr(ol, "_dispatch_inbox_drop", lambda e, a: called.append(1) or _FakePath("/tmp/x"))
        evt = _build_event(severity="info")
        ol._dispatch_action(evt, min_severity_level=1)
        assert not called
        assert ol._DISPATCH_STATS["skipped_severity"] == 1

    def test_default_min_zero_allows_all(self, monkeypatch):
        called = []
        monkeypatch.setattr(ol, "_dispatch_inbox_drop", lambda e, a: called.append(1) or _FakePath("/tmp/x"))
        # min_severity_level=0 (info) → 모두 통과
        for sev in ["info", "warning", "critical"]:
            ol._DISPATCH_DEDUP_CACHE.clear()  # reset dedup between calls
            ol._dispatch_action(_build_event(severity=sev, matched=f"p_{sev}"), min_severity_level=0)
        assert len(called) == 3

    def test_no_severity_payload_treated_as_critical(self, monkeypatch):
        """legacy payload (severity 없음) 는 critical 로 간주 — 보수적."""
        called = []
        monkeypatch.setattr(ol, "_dispatch_inbox_drop", lambda e, a: called.append(1) or _FakePath("/tmp/x"))
        # cascade:build-fail 토픽 이지만 severity 미정 — legacy 호환
        evt = {
            "seq": 1, "topic": "cascade:build-fail", "source": "S11",
            "ts": "...", "payload": {"next_action": {"type": "inbox-drop"}},
        }
        ol._dispatch_action(evt, min_severity_level=2)  # min=critical
        assert called  # legacy = critical → 통과


class TestDispatchDedup:
    """Cycle 8: in-process dispatch dedup (60s window)."""

    def test_first_dispatch_executes(self, monkeypatch):
        called = []
        monkeypatch.setattr(ol, "_dispatch_inbox_drop", lambda e, a: called.append(1) or _FakePath("/tmp/x"))
        evt = _build_event()
        ol._dispatch_action(evt, min_severity_level=0)
        assert called
        assert ol._DISPATCH_STATS["executed"] == 1

    def test_repeat_dedup_skips(self, monkeypatch):
        called = []
        monkeypatch.setattr(ol, "_dispatch_inbox_drop", lambda e, a: called.append(1) or _FakePath("/tmp/x"))
        evt = _build_event()
        for _ in range(5):
            ol._dispatch_action(evt, min_severity_level=0)
        assert len(called) == 1
        assert ol._DISPATCH_STATS["skipped_dedup"] == 4

    def test_different_pattern_not_deduped(self, monkeypatch):
        called = []
        monkeypatch.setattr(ol, "_dispatch_inbox_drop", lambda e, a: called.append(1) or _FakePath("/tmp/x"))
        ol._dispatch_action(_build_event(matched="pytest"), min_severity_level=0)
        ol._dispatch_action(_build_event(matched="docker compose build"), min_severity_level=0)
        ol._dispatch_action(_build_event(matched="flutter test"), min_severity_level=0)
        assert len(called) == 3
        assert ol._DISPATCH_STATS["skipped_dedup"] == 0

    def test_different_severity_not_deduped(self, monkeypatch):
        called = []
        monkeypatch.setattr(ol, "_dispatch_inbox_drop", lambda e, a: called.append(1) or _FakePath("/tmp/x"))
        ol._dispatch_action(_build_event(severity="critical"), min_severity_level=0)
        ol._dispatch_action(_build_event(severity="warning"), min_severity_level=0)
        assert len(called) == 2

    def test_dedup_only_for_cascade_build_fail(self, monkeypatch):
        """다른 토픽은 dedup 적용 안 됨."""
        called = []
        monkeypatch.setattr(ol, "_dispatch_inbox_drop", lambda e, a: called.append(1) or _FakePath("/tmp/x"))
        # stream:S2 토픽은 dedup 무관
        evt = _build_event(topic="stream:S2")
        # Note: stream:S2 는 severity payload 가 없으면 severity filter 도 우회
        # 여기선 severity 명시했으므로 filter 만 통과
        for _ in range(3):
            evt2 = dict(evt)
            evt2["payload"] = dict(evt["payload"])
            ol._dispatch_action(evt2, min_severity_level=0)
        assert len(called) == 3  # dedup 없음

    def test_window_expiry_allows_redispatch(self, monkeypatch):
        called = []
        monkeypatch.setattr(ol, "_dispatch_inbox_drop", lambda e, a: called.append(1) or _FakePath("/tmp/x"))
        evt = _build_event()
        ol._dispatch_action(evt, min_severity_level=0)
        # 1초 window 로 빠르게 검증
        result = ol._dispatch_is_duplicate(ol._dispatch_dedup_key(evt), window_sec=1)
        assert result is True
        time.sleep(1.2)
        result = ol._dispatch_is_duplicate(ol._dispatch_dedup_key(evt), window_sec=1)
        assert result is False


class TestDedupKey:
    """dispatch dedup key 정규화."""

    def test_same_event_same_key(self):
        e1 = _build_event(matched="pytest", severity="critical")
        e2 = _build_event(matched="pytest", severity="critical")
        assert ol._dispatch_dedup_key(e1) == ol._dispatch_dedup_key(e2)

    def test_case_insensitive(self):
        e1 = _build_event(matched="PYTEST")
        e2 = _build_event(matched="pytest")
        assert ol._dispatch_dedup_key(e1) == ol._dispatch_dedup_key(e2)

    def test_topic_partitions(self):
        e1 = _build_event(topic="cascade:build-fail")
        e2 = _build_event(topic="cascade:test")
        assert ol._dispatch_dedup_key(e1) != ol._dispatch_dedup_key(e2)


class TestKPICycle8:
    """KPI: dispatch 단에서 추가 noise reduction."""

    def test_10_repeat_events_1_dispatch(self, monkeypatch):
        """10 동일 critical 신호 → 1 dispatch (90% throttle)."""
        called = []
        monkeypatch.setattr(ol, "_dispatch_inbox_drop", lambda e, a: called.append(1) or _FakePath("/tmp/x"))
        evt = _build_event()
        for _ in range(10):
            ol._dispatch_action(evt, min_severity_level=0)
        throttle_rate = (10 - len(called)) / 10
        assert throttle_rate >= 0.9, f"KPI fail: dispatch throttle {throttle_rate:.0%} < 90%"

    def test_severity_filter_kpi(self, monkeypatch):
        """warning + critical 혼합 50건 중 min=critical 시 critical 만 dispatch."""
        called = []
        monkeypatch.setattr(ol, "_dispatch_inbox_drop", lambda e, a: called.append(1) or _FakePath("/tmp/x"))
        for i in range(50):
            sev = "critical" if i % 5 == 0 else "warning"
            pattern = f"pattern_{i}"  # 모두 다른 pattern (dedup 회피)
            ol._dispatch_action(_build_event(severity=sev, matched=pattern), min_severity_level=2)
        # 50건 중 critical 10건만 dispatch
        assert len(called) == 10
        assert ol._DISPATCH_STATS["skipped_severity"] == 40
