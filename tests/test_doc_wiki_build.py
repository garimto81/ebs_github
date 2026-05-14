"""
test_doc_wiki_build.py — TDD: doc_wiki_build 도구 검증 (Red Phase)

Red->Green: 구현 전 실패 테스트 먼저 작성.
검증:
 - source_files -> wiki body ~300 tokens 압축
 - output: frontmatter + body 구조
 - token_estimate < 400 (압축 효과)
 - 빈 source_files -> graceful 처리
"""

from __future__ import annotations

import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))

import pytest


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

SAMPLE_SOURCE = """---
title: "Lobby Overview"
tier: internal
---

# Lobby Overview

Lobby 는 딜러가 테이블을 생성하고 관리하는 핵심 화면입니다.
주요 기능:
- 테이블 생성 / 삭제
- 플레이어 좌석 배정
- 블라인드 레벨 설정
- 실시간 테이블 상태 조회

## RBAC
- Admin: 전체 테이블 접근
- Operator: 할당된 테이블만 접근
- Viewer: 읽기 전용

## 기술 스택
Flutter + WebSocket + FastAPI
"""


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture
def tmp_source_dir(tmp_path):
    src_dir = tmp_path / "source"
    src_dir.mkdir()
    return src_dir


@pytest.fixture
def sample_source_file(tmp_source_dir):
    f = tmp_source_dir / "Overview.md"
    f.write_text(SAMPLE_SOURCE, encoding="utf-8")
    return f


# ---------------------------------------------------------------------------
# Tests - build_wiki_page
# ---------------------------------------------------------------------------

class TestBuildWikiPage:
    """build_wiki_page 함수 — wiki 페이지 생성 검증."""

    def test_returns_string_output(self, sample_source_file):
        """source_files -> 문자열 반환."""
        from doc_wiki_build import build_wiki_page

        result = build_wiki_page(
            topic="lobby",
            owner_stream="S2",
            source_files=[str(sample_source_file)],
        )
        assert isinstance(result, str), "build_wiki_page 는 str 반환"
        assert len(result) > 0, "결과가 비어있지 않아야 함"

    def test_output_has_frontmatter(self, sample_source_file):
        """결과에 YAML frontmatter 포함 (--- 로 시작)."""
        from doc_wiki_build import build_wiki_page

        result = build_wiki_page(
            topic="lobby",
            owner_stream="S2",
            source_files=[str(sample_source_file)],
        )
        assert result.startswith("---"), "frontmatter 로 시작해야 함"
        assert "type: topic_wiki" in result, "type: topic_wiki 포함 필요"
        assert "topic: lobby" in result, "topic 필드 포함 필요"
        assert "owner_stream: S2" in result, "owner_stream 필드 포함 필요"
        assert "last_ingest_at:" in result, "last_ingest_at 필드 포함 필요"

    def test_token_estimate_under_400(self, sample_source_file):
        """token_estimate < 400 (압축 효과 검증)."""
        from doc_wiki_build import build_wiki_page, estimate_tokens

        result = build_wiki_page(
            topic="lobby",
            owner_stream="S2",
            source_files=[str(sample_source_file)],
        )
        tokens = estimate_tokens(result)
        assert tokens < 400, f"압축 결과 400 토큰 미만 필요. got: {tokens}"

    def test_empty_source_files_returns_skeleton(self):
        """source_files=[] -> skeleton 반환 (에러 안 남)."""
        from doc_wiki_build import build_wiki_page

        result = build_wiki_page(
            topic="lobby",
            owner_stream="S2",
            source_files=[],
        )
        assert isinstance(result, str), "빈 source_files -> str 반환"
        assert "lobby" in result.lower(), "topic 이름 포함"

    def test_multiple_source_files(self, tmp_source_dir):
        """source_files 여러 개 -> 하나의 wiki 페이지로 합성."""
        from doc_wiki_build import build_wiki_page

        for i, name in enumerate(["Overview.md", "RBAC.md", "API.md"]):
            f = tmp_source_dir / name
            f.write_text(f"# {name}\n\n내용 {i}.", encoding="utf-8")

        result = build_wiki_page(
            topic="lobby",
            owner_stream="S2",
            source_files=[str(tmp_source_dir / n) for n in ["Overview.md", "RBAC.md", "API.md"]],
        )
        assert isinstance(result, str)
        assert len(result) > 50, "여러 파일 합성 결과가 충분히 길어야 함"


# ---------------------------------------------------------------------------
# Tests - estimate_tokens
# ---------------------------------------------------------------------------

class TestEstimateTokens:
    """estimate_tokens 함수 — 토큰 수 추정."""

    def test_empty_string_returns_zero(self):
        """빈 문자열 -> 0."""
        from doc_wiki_build import estimate_tokens
        assert estimate_tokens("") == 0

    def test_short_text_reasonable_count(self):
        """짧은 텍스트 -> 합리적 토큰 수."""
        from doc_wiki_build import estimate_tokens
        # 영어 약 4글자 = 1 토큰 기준
        text = "Hello world this is a test"  # 6 단어 -> ~6-7 토큰
        tokens = estimate_tokens(text)
        assert 4 <= tokens <= 15, f"짧은 텍스트 토큰 범위 오류. got: {tokens}"

    def test_long_text_proportional(self):
        """긴 텍스트는 짧은 텍스트보다 토큰 수 많음."""
        from doc_wiki_build import estimate_tokens
        short = "Hello world"
        long = short * 100
        assert estimate_tokens(long) > estimate_tokens(short)


# ---------------------------------------------------------------------------
# Tests - WikiBuildResult
# ---------------------------------------------------------------------------

class TestWikiBuildResult:
    """WikiBuildResult 데이터 구조."""

    def test_build_wiki_result_fields(self, sample_source_file):
        """WikiBuildResult: body / token_estimate / source_count."""
        from doc_wiki_build import build_wiki_result, WikiBuildResult

        result = build_wiki_result(
            topic="lobby",
            owner_stream="S2",
            source_files=[str(sample_source_file)],
        )
        assert isinstance(result, WikiBuildResult)
        assert hasattr(result, "body")
        assert hasattr(result, "token_estimate")
        assert hasattr(result, "source_count")
        assert result.source_count == 1
        assert result.token_estimate >= 0
