"""
test_doc_wiki_lint.py — TDD: doc_wiki_lint 검증 (Red Phase)

Red→Green: 구현 전 실패 테스트 먼저 작성.
검증: drift>24h WARN / drift<=24h OK / last_ingest_at 누락 WARN /
      scan_wiki_dir / build_summary / LintResult 인터페이스
"""

from __future__ import annotations

import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))

import pytest
from datetime import datetime, timezone, timedelta


def make_wiki_content(last_ingest_at):
    ingest_line = f"last_ingest_at: {last_ingest_at}" if last_ingest_at else ""
    return f"""---
id: topic-lobby
title: "Lobby — Wiki SSOT"
type: topic_wiki
topic: lobby
owner_stream: S2
status: ACTIVE
tier: meta
{ingest_line}
source_files:
  - docs/2. Development/2.1 Frontend/Lobby/Overview.md
token_estimate: 310
---

# Lobby Topic Wiki

Lobby 는 딜러가 테이블을 생성 관리하는 화면.
"""


@pytest.fixture
def tmp_wiki_dir(tmp_path):
    wiki_dir = tmp_path / "doc-wiki"
    wiki_dir.mkdir(parents=True)
    (wiki_dir / "candidates").mkdir()
    return wiki_dir


class TestDriftDetection:

    def test_drift_over_24h_returns_warn(self, tmp_wiki_dir):
        """25시간 경과 -> WARN."""
        from doc_wiki_lint import check_wiki_file, LintResult

        old_time = datetime.now(timezone.utc) - timedelta(hours=25)
        ingest_str = old_time.strftime("%Y-%m-%dT%H:%M:%SZ")
        wiki_file = tmp_wiki_dir / "lobby.md"
        wiki_file.write_text(make_wiki_content(ingest_str), encoding="utf-8")

        result = check_wiki_file(wiki_file)
        assert result.status == "WARN", f"25h drift -> WARN. got: {result.status}"
        assert "drift" in result.reason.lower(), f"reason 에 drift 필요. got: {result.reason}"

    def test_drift_under_24h_returns_ok(self, tmp_wiki_dir):
        """10시간 경과 -> OK."""
        from doc_wiki_lint import check_wiki_file

        recent = datetime.now(timezone.utc) - timedelta(hours=10)
        wiki_file = tmp_wiki_dir / "lobby.md"
        wiki_file.write_text(
            make_wiki_content(recent.strftime("%Y-%m-%dT%H:%M:%SZ")), encoding="utf-8"
        )
        result = check_wiki_file(wiki_file)
        assert result.status == "OK", f"10h drift -> OK. got: {result.status}"

    def test_drift_exactly_24h_returns_ok(self, tmp_wiki_dir):
        """정확히 24h -> OK (drift > 24h 만 WARN)."""
        from doc_wiki_lint import check_wiki_file

        exactly_24h = datetime.now(timezone.utc) - timedelta(hours=23, minutes=59)
        wiki_file = tmp_wiki_dir / "lobby.md"
        wiki_file.write_text(
            make_wiki_content(exactly_24h.strftime("%Y-%m-%dT%H:%M:%SZ")), encoding="utf-8"
        )
        result = check_wiki_file(wiki_file)
        assert result.status == "OK", "정확히 24h -> OK (> 24h 만 WARN)"

    def test_missing_last_ingest_at_returns_warn(self, tmp_wiki_dir):
        """last_ingest_at 누락 -> WARN."""
        from doc_wiki_lint import check_wiki_file

        wiki_file = tmp_wiki_dir / "lobby.md"
        wiki_file.write_text(make_wiki_content(None), encoding="utf-8")
        result = check_wiki_file(wiki_file)
        assert result.status == "WARN", "last_ingest_at 누락 -> WARN"
        assert "missing" in result.reason.lower() or "누락" in result.reason, (
            f"reason 에 missing/누락 필요. got: {result.reason}"
        )


class TestScanWikiDir:

    def test_returns_list_of_results(self, tmp_wiki_dir):
        """topic .md 2개 -> 결과 2개."""
        from doc_wiki_lint import scan_wiki_dir

        ts = (datetime.now(timezone.utc) - timedelta(hours=1)).strftime("%Y-%m-%dT%H:%M:%SZ")
        for slug in ["lobby", "back-office"]:
            (tmp_wiki_dir / f"{slug}.md").write_text(make_wiki_content(ts), encoding="utf-8")

        results = scan_wiki_dir(tmp_wiki_dir)
        assert len(results) == 2

    def test_skips_schema_and_log(self, tmp_wiki_dir):
        """_schema.md / Log.md / Index.md -> lint 제외."""
        from doc_wiki_lint import scan_wiki_dir

        ts = (datetime.now(timezone.utc) - timedelta(hours=1)).strftime("%Y-%m-%dT%H:%M:%SZ")
        (tmp_wiki_dir / "_schema.md").write_text("# schema", encoding="utf-8")
        (tmp_wiki_dir / "Log.md").write_text("# log", encoding="utf-8")
        (tmp_wiki_dir / "Index.md").write_text("# index", encoding="utf-8")
        (tmp_wiki_dir / "lobby.md").write_text(make_wiki_content(ts), encoding="utf-8")

        results = scan_wiki_dir(tmp_wiki_dir)
        slugs = [r.topic for r in results]
        assert "_schema" not in slugs
        assert "Log" not in slugs
        assert "Index" not in slugs
        assert "lobby" in slugs

    def test_warn_count_in_summary(self, tmp_wiki_dir):
        """WARN 2개 -> summary warn_count==2."""
        from doc_wiki_lint import scan_wiki_dir, build_summary

        old = (datetime.now(timezone.utc) - timedelta(hours=30)).strftime("%Y-%m-%dT%H:%M:%SZ")
        for slug in ["lobby", "back-office"]:
            (tmp_wiki_dir / f"{slug}.md").write_text(make_wiki_content(old), encoding="utf-8")

        results = scan_wiki_dir(tmp_wiki_dir)
        summary = build_summary(results)
        assert summary["warn_count"] == 2
        assert summary["ok_count"] == 0


class TestLintResult:

    def test_lint_result_has_required_fields(self, tmp_wiki_dir):
        """LintResult: status / topic / reason / drift_hours."""
        from doc_wiki_lint import check_wiki_file, LintResult

        recent = datetime.now(timezone.utc) - timedelta(hours=2)
        wiki_file = tmp_wiki_dir / "game-engine.md"
        wiki_file.write_text(
            make_wiki_content(recent.strftime("%Y-%m-%dT%H:%M:%SZ")), encoding="utf-8"
        )

        result = check_wiki_file(wiki_file)
        assert hasattr(result, "status")
        assert hasattr(result, "topic")
        assert hasattr(result, "reason")
        assert hasattr(result, "drift_hours")
        assert isinstance(result, LintResult)
