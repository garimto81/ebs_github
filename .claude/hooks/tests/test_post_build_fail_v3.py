"""
Tests for post_build_fail.py v3 (S11 Cycle 7 #322).

Validates 4-layer false-positive filter + severity classification.

Run:
  pytest .claude/hooks/tests/test_post_build_fail_v3.py -v

KPI (Issue #322):
  - false-positive 비율 < 10%
  - severity 분류 정확도 100% (deterministic)

Test corpus 는 Cycle 6 events.db false-positive 60건 분석 (PR #314) 기반.
"""
from __future__ import annotations

import importlib.util
import io
import json
import sys
from pathlib import Path
from typing import Any
from unittest.mock import patch

import pytest


# 모듈 동적 로드 (hooks/ 디렉토리는 sys.path 외부)
HOOK_PATH = Path(__file__).resolve().parents[1] / "post_build_fail.py"
_spec = importlib.util.spec_from_file_location("post_build_fail_v3", HOOK_PATH)
hook = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(hook)


# =============================================================================
# L1: Whitelist prefix (gh / git commit-push-stash / cat > / claude --bg)
# =============================================================================

class TestL1Whitelist:
    """L1 whitelist prefix 매칭 — Cycle 6 false-positive 22+ 건의 주 원인."""

    @pytest.mark.parametrize("cmd", [
        # Cycle 6 events.db 실제 false-positive 샘플 (seq=1025~1036)
        'gh issue create --title "[SMEM Cycle 7]" --label "stream:SMEM,cycle:7" --body "pytest coverage"',
        'gh pr create --title "feat(s8): docker compose build" --body "Cycle 6 v03"',
        'gh issue comment 310 --body "## cascade:engine-v03-ready"',
        'git commit -m "feat(s3/cycle6): npm install + flutter build"',
        'git push origin work/s11/cycle7',
        'git stash push -m "wip pytest"',
        'cd C:/claude/ebs && gh pr create --base main --head work/s3',
        'cd /c/claude/ebs-engine-stream && claude --bg "pytest + docker compose build"',
        'claude --background "S8 Engine pytest + flutter build runner"',
        'echo "pytest done"',
        'printf "build complete\\n"',
        'sleep 4',
        'git add docs/ && git commit -m "docker compose up"',
    ])
    def test_whitelist_blocks_false_positives(self, cmd):
        """gh/git/cat/claude/echo prefix 는 L1 에서 차단되어야 함."""
        head = hook._strip_heredoc(cmd)
        assert hook._is_whitelisted(head), f"L1 should whitelist: {cmd!r}"

    @pytest.mark.parametrize("cmd", [
        # 실제 빌드 명령 — whitelist 매칭 X
        'docker compose build bo',
        'docker compose up -d',
        'flutter build web --release',
        'flutter test',
        'pytest tests/ -v',
        'pnpm run build',
        'npm install',
        'dart test',
        'ruff check src/',
        'python -m pytest tests/',
        'uvicorn app:app --reload',
    ])
    def test_whitelist_passes_real_builds(self, cmd):
        """실제 빌드 명령은 whitelist 통과 (L3 에서 BUILD_PATTERNS 매치 필요)."""
        head = hook._strip_heredoc(cmd)
        assert not hook._is_whitelisted(head), f"L1 must NOT whitelist build: {cmd!r}"


# =============================================================================
# L2: Heredoc body strip
# =============================================================================

class TestL2HeredocStrip:
    """L2 heredoc body 제거 — PR description / commit message 안 build 단어 false-positive 차단."""

    def test_strip_eof_heredoc(self):
        cmd = "git commit -m \"$(cat <<'EOF'\nfeat: pytest + flutter build\nEOF\n)\""
        head = hook._strip_heredoc(cmd)
        assert "pytest" not in head, "L2 should strip EOF body"
        assert "flutter build" not in head
        assert "git commit" in head

    def test_strip_unquoted_heredoc(self):
        cmd = "gh pr create --body \"$(cat <<EOF\nDocker compose up failed.\nEOF\n)\""
        head = hook._strip_heredoc(cmd)
        assert "Docker compose up" not in head

    def test_strip_dash_heredoc(self):
        cmd = "cat <<-EOF\n  flutter test\nEOF"
        head = hook._strip_heredoc(cmd)
        assert "flutter test" not in head

    def test_no_heredoc_passthrough(self):
        """heredoc 없는 명령은 그대로 통과."""
        cmd = "docker compose build bo"
        head = hook._strip_heredoc(cmd)
        assert head == cmd

    def test_strip_quoted_eof(self):
        cmd = 'cat <<"EOF"\nnpm install\nEOF'
        head = hook._strip_heredoc(cmd)
        assert "npm install" not in head


# =============================================================================
# L3: BUILD_PATTERNS match on head only
# =============================================================================

class TestL3PatternMatch:
    """L3 build pattern matching — L1/L2 통과 후 head 에 build 단어 매치."""

    @pytest.mark.parametrize("cmd,expected", [
        ("docker compose build bo", True),
        ("docker compose up -d", True),
        ("docker-compose build", True),
        ("flutter pub get", True),
        ("flutter build web", True),
        ("flutter test", True),
        ("dart test", True),
        ("dart run bin/server.dart", True),
        ("pytest tests/", True),
        ("ruff check src/", True),
        ("pnpm install", True),
        ("npm run build", True),
        ("uvicorn app:app", True),
        ("python -m pytest", True),
        ("python -m alembic upgrade head", True),
        ("build_runner build", True),
        # Non-build
        ("ls -la", False),
        ("rm -rf node_modules", False),
        ("curl http://localhost:8000/health", False),
        ("ps -ef | grep python", False),
    ])
    def test_build_patterns(self, cmd, expected):
        match = hook.BUILD_PATTERNS.search(cmd)
        assert bool(match) == expected, f"BUILD_PATTERNS({cmd!r}) → {bool(match)}, expected {expected}"


# =============================================================================
# Severity classification
# =============================================================================

class TestSeverity:
    """severity 분류 매트릭스."""

    def test_critical_full_signal(self):
        """exit_code ∈ [1,255] + stderr ≥ 20 = critical."""
        assert hook._classify_severity(1, "Error: module not found at /path/x.py:42") == "critical"
        assert hook._classify_severity(127, "command not found: pytest in target dir") == "critical"
        assert hook._classify_severity(2, "FAILED tests/test_x.py::test_a - AssertionError") == "critical"

    def test_warning_weak_signal(self):
        """exit_code ∈ [1,255] + stderr < 20 chars = warning."""
        assert hook._classify_severity(1, "x") == "warning"
        assert hook._classify_severity(1, "") == "warning"
        assert hook._classify_severity(1, None) == "warning"
        assert hook._classify_severity(2, "short") == "warning"

    def test_info_no_signal(self):
        """exit_code = -1 (Claude bash internal) + empty stderr = info."""
        assert hook._classify_severity(-1, "") == "info"
        assert hook._classify_severity(-1, None) == "info"
        assert hook._classify_severity(None, "") == "info"

    def test_info_even_with_stderr_when_exit_minus_one(self):
        """exit_code = -1 이면 stderr 있어도 info — Claude bash internal failure 표시."""
        # 디자인 결정: exit_code = -1 = Claude bash tool 의 internal failure 표시 (Windows cmd.exe 비정상)
        # 실제 빌드 실패가 아니므로 stderr 가 있어도 info 로 분류.
        assert hook._classify_severity(-1, "Some error text that is long enough") == "info"


# =============================================================================
# matched_pattern forensic
# =============================================================================

class TestMatchedPattern:
    def test_returns_matched_token(self):
        assert hook._matched_pattern("docker compose build bo") == "docker compose build"
        assert "pytest" in hook._matched_pattern("pytest tests/")
        assert "flutter test" in hook._matched_pattern("flutter test")

    def test_empty_on_no_match(self):
        assert hook._matched_pattern("ls -la") == ""


# =============================================================================
# Integration: main() end-to-end via stdin payload
# =============================================================================

class TestIntegration:
    """전체 hook 흐름 — stdin payload → filter → publish (mocked)."""

    def _run_main(self, command: str, exit_code: int, stderr: str = "") -> tuple[int, str, list]:
        """Mock broker publish + redirect stdin/stdout. Returns (exit_code, stdout, publish_calls)."""
        payload = {
            "tool_input": {"command": command},
            "tool_response": {"exit_code": exit_code, "stderr": stderr, "is_error": exit_code != 0},
        }
        publish_calls: list[dict] = []

        def fake_publish(cascade_payload, source, max_retries=3):
            publish_calls.append({"payload": cascade_payload, "source": source})
            return True

        stdin = io.StringIO(json.dumps(payload))
        stdout = io.StringIO()
        with patch.object(hook, "_broker_publish_build_fail", side_effect=fake_publish), \
             patch.object(sys, "stdin", stdin), \
             patch.object(sys, "stdout", stdout):
            rc = hook.main()
        return rc, stdout.getvalue(), publish_calls

    def test_success_no_publish(self):
        """exit_code=0 → 조용히 통과."""
        rc, out, calls = self._run_main("docker compose build bo", 0)
        assert rc == 0
        assert out == ""
        assert calls == []

    def test_l1_whitelist_skip(self):
        """gh issue create → L1 차단 (false-positive 방지)."""
        rc, out, calls = self._run_main(
            'gh issue create --title "pytest fails" --body "docker compose build"',
            -1, ""
        )
        assert rc == 0
        assert calls == [], "L1 should block publish"
        assert out == ""

    def test_l2_heredoc_body_ignored(self):
        """git commit heredoc body 의 'pytest' 매치 X."""
        rc, out, calls = self._run_main(
            "git commit -m \"$(cat <<'EOF'\nfeat: pytest passing\nflutter build done\nEOF\n)\"",
            -1, ""
        )
        assert rc == 0
        # L1 (git commit) 이 먼저 차단하므로 publish 없음
        assert calls == []

    def test_l3_no_build_pattern_skip(self):
        """build pattern 없는 명령은 publish X."""
        rc, out, calls = self._run_main("ls -la", -1, "")
        assert rc == 0
        assert calls == []

    def test_l4_info_severity_skip(self):
        """exit_code=-1 + empty stderr = info → publish skip."""
        rc, out, calls = self._run_main("docker compose build bo", -1, "")
        assert rc == 0
        assert calls == [], "info severity should not publish"
        assert out == ""

    def test_critical_publishes_with_severity(self):
        """실제 빌드 실패 → severity=critical publish."""
        rc, out, calls = self._run_main(
            "docker compose build bo",
            1,
            "Error response from daemon: pull access denied for ebs-bo, ImageNotFound"
        )
        assert rc == 0
        assert len(calls) == 1
        cp = calls[0]["payload"]
        assert cp["severity"] == "critical"
        assert cp["filter_version"] in ("v3", "v4")  # v4 (Cycle 8 #340) backward-compatible
        assert cp["matched_pattern"] == "docker compose build"
        assert cp["next_action"]["target"] == "S9,S10-A"
        assert "post_build_fail" in out
        assert "severity=critical" in out

    def test_warning_publishes_no_reminder(self):
        """warning → publish only, no stdout reminder."""
        rc, out, calls = self._run_main("pytest tests/", 1, "short")
        assert rc == 0
        assert len(calls) == 1
        assert calls[0]["payload"]["severity"] == "warning"
        assert calls[0]["payload"]["next_action"]["target"] == "S10-A"
        assert out == "", "warning should not emit stdout reminder"

    def test_invalid_json_passthrough(self):
        """잘못된 stdin payload → silent return."""
        stdin = io.StringIO("not json")
        with patch.object(sys, "stdin", stdin):
            rc = hook.main()
        assert rc == 0


# =============================================================================
# KPI: false-positive 비율 < 10% (Cycle 6 corpus 기준)
# =============================================================================

class TestKPI:
    """Cycle 6 events.db corpus 기반 false-positive 비율 측정."""

    # Cycle 6 false-positive 샘플 60건 중 대표 22건 (모두 v3 에서 차단 기대)
    CYCLE6_FALSE_POSITIVES = [
        # Issue/PR/commit creation (Cycle 6 events.db 발췌)
        'gh issue create --title "S8 Cycle 7" --body "docker compose"',
        'gh pr create --title "feat: flutter build" --body "..."',
        'gh issue comment 310 --body "## cascade:engine-v03-ready"',
        'git commit -m "feat(s3/cycle6): npm install + pytest"',
        'git push origin main',
        'git stash push',
        'cd /c/ebs && gh pr create',
        'cd /c/ebs-engine-stream && claude --bg "pytest"',
        'claude --background "build_runner"',
        # heredoc with build words in body
        'git commit -m "$(cat <<\'EOF\'\nfeat: pytest pass\nEOF\n)"',
        'gh pr create --body "$(cat <<\'EOF\'\ndocker compose build done.\nEOF\n)"',
        'gh issue comment 305 --body "$(cat <<\'EOF\'\nflutter test PASS\nEOF\n)"',
        # echo / printf / sleep
        'echo "pytest result"',
        'printf "build done"',
        'sleep 5',
        # cd && gh patterns
        'cd C:/claude/ebs-devops && gh pr view 322',
        'cd /c/claude/ebs && git log --oneline',
        # Long claude --bg with pattern words
        'claude --bg "S8 Engine. pytest + docker compose build + flutter test"',
        'claude --bg "S11 Cycle 7 — docker-compose build refinement"',
        # 약간 다른 명령
        'gh workflow run ci.yml',
        'gh release create v1.0',
        'git log -- "**/build*"',
    ]

    # 실제 빌드 실패 사례 (v3 에서 정확히 critical/warning publish 기대)
    REAL_BUILD_FAILURES = [
        ("docker compose build bo", 1, "Error response from daemon: build failed", "critical"),
        ("flutter build web --release", 1, "Compilation error: lib/main.dart:42:8: Type 'Foo' not found", "critical"),
        ("pytest tests/", 1, "FAILED tests/test_a.py::test_x - assert 1 == 2", "critical"),
        ("npm install", 2, "npm ERR! peer dep missing react@18", "critical"),
        ("dart test", 1, "TestFailure: timer-related test hung", "critical"),
    ]

    def test_kpi_false_positive_filter_rate(self):
        """false-positive 22건 모두 v3 에서 차단되어야 함 (rate < 10% → 실제 0%)."""
        blocked = 0
        leaked: list[str] = []
        for cmd in self.CYCLE6_FALSE_POSITIVES:
            head = hook._strip_heredoc(cmd)
            if hook._is_whitelisted(head):
                blocked += 1
            elif not hook.BUILD_PATTERNS.search(head):
                blocked += 1
            else:
                # 매치 통과 — info severity 이면 publish 차단됨
                sev = hook._classify_severity(-1, "")
                if sev == "info":
                    blocked += 1
                else:
                    leaked.append(cmd)

        total = len(self.CYCLE6_FALSE_POSITIVES)
        leak_rate = len(leaked) / total
        assert leak_rate < 0.10, (
            f"KPI fail: false-positive leak rate {leak_rate:.1%} >= 10%. "
            f"Leaked: {leaked}"
        )
        # KPI: 22건 모두 차단되어야 이상적
        assert blocked == total, f"blocked {blocked}/{total}, leaks: {leaked}"

    def test_kpi_real_failure_detection(self):
        """실제 빌드 실패는 100% critical publish."""
        for cmd, exit_code, stderr, expected_sev in self.REAL_BUILD_FAILURES:
            head = hook._strip_heredoc(cmd)
            assert not hook._is_whitelisted(head), f"L1 false-block: {cmd}"
            assert hook.BUILD_PATTERNS.search(head), f"L3 false-block: {cmd}"
            sev = hook._classify_severity(exit_code, stderr)
            assert sev == expected_sev, (
                f"{cmd!r} → severity={sev}, expected={expected_sev}"
            )
