"""
Tests for post_build_fail.py v4 (S11 Cycle 8 #340) — L5 cross-process debounce dedup.

Validates Cycle 8 추가:
  - L5: 동일 (matched_pattern + severity) 가 60s 내 재발 시 publish skip.
  - dedup state file 은 atomic rename 으로 race-free.
  - hash key 정규화 (case + whitespace insensitive).

Run:
  pytest .claude/hooks/tests/test_post_build_fail_v4.py -v

KPI (Issue #340):
  - cascade:build-fail < 1회/시간 (Cycle 7 4회/시간 대비 75%+ 감소).
  - dedup 통과율 >= 90% (동일 패턴 반복 발생 시).
"""
from __future__ import annotations

import importlib.util
import shutil
import time
from pathlib import Path
from unittest.mock import patch

import pytest


# 모듈 동적 로드
HOOK_PATH = Path(__file__).resolve().parents[1] / "post_build_fail.py"
_spec = importlib.util.spec_from_file_location("post_build_fail_v4", HOOK_PATH)
hook = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(hook)


@pytest.fixture
def isolated_dedup_dir(tmp_path, monkeypatch):
    """각 테스트마다 격리된 dedup state dir 사용."""
    test_dir = tmp_path / "post_build_fail_dedup"
    monkeypatch.setattr(hook, "DEDUP_STATE_DIR", test_dir)
    yield test_dir
    if test_dir.exists():
        shutil.rmtree(test_dir, ignore_errors=True)


# =============================================================================
# L5: dedup key normalization
# =============================================================================

class TestDedupKey:
    """matched_pattern + severity 정규화 검증."""

    def test_same_pattern_same_severity_same_key(self):
        k1 = hook._dedup_key("pytest", "critical")
        k2 = hook._dedup_key("pytest", "critical")
        assert k1 == k2

    def test_case_insensitive(self):
        k1 = hook._dedup_key("pytest", "critical")
        k2 = hook._dedup_key("PYTEST", "critical")
        k3 = hook._dedup_key("Pytest", "critical")
        assert k1 == k2 == k3

    def test_whitespace_normalized(self):
        k1 = hook._dedup_key("pytest", "critical")
        k2 = hook._dedup_key("  pytest  ", "critical")
        k3 = hook._dedup_key("pytest ", "critical")
        assert k1 == k2 == k3

    def test_severity_partitioned(self):
        """동일 pattern 이라도 severity 다르면 별도 key (warning != critical)."""
        k_crit = hook._dedup_key("pytest", "critical")
        k_warn = hook._dedup_key("pytest", "warning")
        assert k_crit != k_warn
        # severity prefix 가 key 에 포함되어 시각적 식별도 가능
        assert k_crit.startswith("critical_")
        assert k_warn.startswith("warning_")

    def test_different_patterns_different_keys(self):
        k1 = hook._dedup_key("pytest", "critical")
        k2 = hook._dedup_key("docker compose build", "critical")
        k3 = hook._dedup_key("flutter test", "critical")
        assert len({k1, k2, k3}) == 3

    def test_empty_pattern_safe(self):
        """matched_pattern 이 비어도 unknown 으로 falls back, 충돌 없음."""
        k = hook._dedup_key("", "critical")
        assert k.startswith("critical_")


# =============================================================================
# L5: should_dedup behavior (window 내 재발 시 True)
# =============================================================================

class TestShouldDedup:
    """L5 dedup window 60s 검증."""

    def test_first_call_returns_false(self, isolated_dedup_dir):
        """최초 호출 시 dedup miss (publish 허용)."""
        assert hook._should_dedup("pytest", "critical") is False

    def test_repeat_within_window_returns_true(self, isolated_dedup_dir):
        """첫 호출 직후 재호출 → dedup hit (publish skip)."""
        assert hook._should_dedup("pytest", "critical") is False
        assert hook._should_dedup("pytest", "critical") is True
        assert hook._should_dedup("pytest", "critical") is True

    def test_different_pattern_no_dedup(self, isolated_dedup_dir):
        """서로 다른 pattern 은 독립."""
        assert hook._should_dedup("pytest", "critical") is False
        assert hook._should_dedup("docker compose build", "critical") is False

    def test_different_severity_no_dedup(self, isolated_dedup_dir):
        """동일 pattern 이라도 severity 다르면 독립."""
        assert hook._should_dedup("pytest", "critical") is False
        assert hook._should_dedup("pytest", "warning") is False

    def test_expired_window_allows_publish(self, isolated_dedup_dir):
        """window_sec 초과 후 재호출 → dedup miss (publish 허용)."""
        # 1초 window 로 빠른 검증
        assert hook._should_dedup("pytest", "critical", window_sec=1) is False
        time.sleep(1.1)
        assert hook._should_dedup("pytest", "critical", window_sec=1) is False

    def test_window_extended_on_repeat(self, isolated_dedup_dir):
        """재발 시 timestamp 갱신 — slide window 동작."""
        # Each call writes fresh ts, so window slides.
        assert hook._should_dedup("pytest", "critical", window_sec=2) is False
        time.sleep(0.5)
        assert hook._should_dedup("pytest", "critical", window_sec=2) is True


# =============================================================================
# L5: state file atomic rename behavior
# =============================================================================

class TestDedupStateFile:
    """state file 의 atomic write + 형식 검증."""

    def test_state_file_created(self, isolated_dedup_dir):
        hook._should_dedup("pytest", "critical")
        files = list(isolated_dedup_dir.glob("*.ts"))
        assert len(files) == 1
        # 형식: severity_hashhex.ts
        assert files[0].name.startswith("critical_")
        assert files[0].suffix == ".ts"

    def test_state_file_contains_float_timestamp(self, isolated_dedup_dir):
        hook._should_dedup("pytest", "critical")
        files = list(isolated_dedup_dir.glob("*.ts"))
        content = files[0].read_text(encoding="utf-8").strip()
        # 부동소수점 형식 검증
        ts = float(content)
        assert ts > 0

    def test_corrupt_state_file_treated_as_miss(self, isolated_dedup_dir):
        """state 파일 손상 시 fail-open (publish 허용)."""
        # 정상 호출로 파일 생성
        hook._should_dedup("pytest", "critical")
        files = list(isolated_dedup_dir.glob("*.ts"))
        # 손상시키기
        files[0].write_text("not_a_number", encoding="utf-8")
        # corrupt → miss 처리 + 새 ts 로 덮어쓰기
        result = hook._should_dedup("pytest", "critical")
        assert result is False

    def test_no_temp_file_left_behind(self, isolated_dedup_dir):
        """atomic rename 후 .tmp 파일 잔류 없음."""
        hook._should_dedup("pytest", "critical")
        tmps = list(isolated_dedup_dir.glob("*.tmp"))
        assert len(tmps) == 0


# =============================================================================
# main() integration — L5 통합 후 publish 흐름
# =============================================================================

class TestMainL5Integration:
    """stdin → main() → broker mock publish 통합 흐름에서 L5 dedup 검증."""

    @staticmethod
    def _build_stdin(command, exit_code, stderr):
        import io
        import json
        return io.StringIO(json.dumps({
            "tool_input": {"command": command},
            "tool_response": {"exit_code": exit_code, "stderr": stderr, "is_error": True},
        }))

    def test_first_critical_publishes(self, isolated_dedup_dir, monkeypatch):
        """첫 critical 신호는 broker publish."""
        publish_calls = []

        def mock_publish(payload, source, max_retries=3):
            publish_calls.append((payload, source))
            return True

        monkeypatch.setattr(hook, "_broker_publish_build_fail", mock_publish)
        monkeypatch.setattr("sys.stdin", self._build_stdin(
            "pytest tests/", 1, "FAILED test_a.py::test_x - AssertionError: 1 != 2"
        ))
        result = hook.main()
        assert result == 0
        assert len(publish_calls) == 1
        assert publish_calls[0][0]["severity"] == "critical"
        assert publish_calls[0][0]["filter_version"] == "v4"
        assert publish_calls[0][0]["dedup_window_sec"] == 60

    def test_dedup_blocks_repeat_critical(self, isolated_dedup_dir, monkeypatch):
        """동일 (pattern + severity) 재발은 publish skip."""
        publish_calls = []

        def mock_publish(payload, source, max_retries=3):
            publish_calls.append((payload, source))
            return True

        monkeypatch.setattr(hook, "_broker_publish_build_fail", mock_publish)
        for _ in range(5):
            monkeypatch.setattr("sys.stdin", self._build_stdin(
                "pytest tests/", 1, "FAILED test_a.py::test_x - AssertionError: 1 != 2"
            ))
            hook.main()
        # 5회 시도 중 1회만 publish (L5 dedup 차단 4회)
        assert len(publish_calls) == 1

    def test_different_pattern_each_publishes(self, isolated_dedup_dir, monkeypatch):
        """서로 다른 pattern 은 각각 publish."""
        publish_calls = []

        def mock_publish(payload, source, max_retries=3):
            publish_calls.append((payload, source))
            return True

        monkeypatch.setattr(hook, "_broker_publish_build_fail", mock_publish)
        commands = [
            ("pytest tests/", "FAILED test_a.py - AssertionError: 1 != 2"),
            ("docker compose build bo", "Error: build context failed to load"),
            ("flutter build web --release", "Compilation error: type mismatch found"),
        ]
        for cmd, err in commands:
            monkeypatch.setattr("sys.stdin", self._build_stdin(cmd, 1, err))
            hook.main()
        assert len(publish_calls) == 3
        patterns = {c[0]["matched_pattern"] for c in publish_calls}
        assert len(patterns) == 3


# =============================================================================
# KPI: Cycle 8 noise reduction simulation
# =============================================================================

class TestKPICycle8:
    """동일 critical 신호 N회 발생 시 publish 비율 측정."""

    def test_repeat_critical_throttled_90_percent(self, isolated_dedup_dir):
        """10회 동일 critical 신호 시 1회만 publish (90% throttle)."""
        publishes = 0
        for _ in range(10):
            if not hook._should_dedup("pytest", "critical"):
                publishes += 1
        # 첫 1회만 publish, 9회 dedup
        assert publishes == 1
        throttle_rate = (10 - publishes) / 10
        assert throttle_rate >= 0.9, f"KPI fail: throttle {throttle_rate:.0%} < 90%"

    def test_mixed_patterns_3_publishes(self, isolated_dedup_dir):
        """3 종 pattern 각 5회씩 발생 시 3회 publish (5x reduction per pattern)."""
        publishes = 0
        for _ in range(5):
            for pattern in ["pytest", "docker compose build", "flutter test"]:
                if not hook._should_dedup(pattern, "critical"):
                    publishes += 1
        # 첫 cycle 에서 3종 publish, 이후 4 cycle 모두 dedup
        assert publishes == 3
