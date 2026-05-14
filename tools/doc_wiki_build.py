"""
doc_wiki_build.py -- source_files 변경 감지 시 wiki 페이지 재생성

사용법:
    python tools/doc_wiki_build.py --topic lobby --owner-stream S2         --source-files "docs/.../Lobby/Overview.md"         --out docs/_meta/doc-wiki/lobby.md

LLM 압축:
    ANTHROPIC_API_KEY 존재 시 Haiku 호출로 ~300 토큰 압축.
    API 키 없으면 fallback: 원문 합성 후 선두 300 토큰 truncate.

wiki = compression artifact. raw docs 가 항상 진실.
"""

from __future__ import annotations

import argparse
import os
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional


REPO = Path(__file__).resolve().parent.parent
DEFAULT_WIKI_DIR = REPO / "docs" / "_meta" / "doc-wiki"
TARGET_TOKENS = 300
CHARS_PER_TOKEN = 3.5


@dataclass
class WikiBuildResult:
    """wiki 페이지 생성 결과."""

    body: str
    token_estimate: int
    source_count: int


def estimate_tokens(text: str) -> int:
    """텍스트 토큰 수 간이 추정 (tiktoken 불필요).

    영문 4자 = 1 토큰, 한글 2자 = 1 토큰 기준 간이 계산.
    빈 문자열 -> 0.
    """
    if not text:
        return 0
    return max(0, int(len(text) / CHARS_PER_TOKEN))


def _read_source_files(source_files: list) -> str:
    """source_files 목록을 읽어 연결."""
    NL2 = chr(10) + chr(10)
    SEP = NL2 + "---" + NL2
    parts = []
    for fpath in source_files:
        p = Path(fpath)
        if not p.exists():
            parts.append("[소스 없음: " + str(fpath) + "]")
            continue
        try:
            text = p.read_text(encoding="utf-8", errors="ignore")
            parts.append("## Source: " + p.name + NL2 + text.strip())
        except OSError:
            parts.append("[읽기실패: " + str(fpath) + "]")
    return SEP.join(parts)


def _compress_with_llm(raw_text: str, topic: str) -> Optional[str]:
    """Anthropic Haiku API 로 raw_text 를 ~300 토큰으로 압축.

    ANTHROPIC_API_KEY 없으면 None 반환 (fallback 처리).
    """
    api_key = os.environ.get("ANTHROPIC_API_KEY", "")
    if not api_key:
        return None
    try:
        import anthropic  # type: ignore

        client = anthropic.Anthropic(api_key=api_key)
        NL = chr(10)
        prompt = (
            "아래 문서를 " + topic + " wiki 용으로 " + str(TARGET_TOKENS) + " 토큰 이내로 압축." + NL
            + "핵심 기능/RBAC/기술 스택만 보존. Markdown 유지." + NL + NL
            + "---" + NL + raw_text[:8000] + NL + "---"
        )
        msg = client.messages.create(
            model="claude-haiku-4-5",
            max_tokens=TARGET_TOKENS + 50,
            messages=[{"role": "user", "content": prompt}],
        )
        return msg.content[0].text.strip() if msg.content else None
    except Exception:
        return None


def _compress_fallback(raw_text: str) -> str:
    """LLM 없이 간단 요약: 첫 N 토큰만 보존."""
    max_chars = int(TARGET_TOKENS * CHARS_PER_TOKEN)
    if len(raw_text) <= max_chars:
        return raw_text
    truncated = raw_text[:max_chars]
    last_nl = truncated.rfind(chr(10))
    if last_nl > max_chars // 2:
        truncated = truncated[:last_nl]
    NL2 = chr(10) + chr(10)
    return truncated + NL2 + "> *(자동 truncate -- 원문은 source_files 참조)*"


def _build_frontmatter(
    topic: str,
    owner_stream: str,
    source_files: list,
    token_estimate: int,
    now_iso: str,
) -> str:
    """YAML frontmatter 생성."""
    NL = chr(10)
    src_block = NL.join("  - " + f for f in source_files) if source_files else "  []"
    title = topic.replace("-", " ").title()
    rows = [
        "---",
        "id: topic-" + topic,
        'title: "' + title + ' -- Wiki SSOT"',
        "type: topic_wiki",
        "topic: " + topic,
        "owner_stream: " + owner_stream,
        "status: ACTIVE",
        "tier: meta",
        "confluence-sync: false",
        "last_ingest_at: " + now_iso,
        "token_estimate: " + str(token_estimate),
        "source_files:",
        src_block,
        "---",
        "",
        "",
    ]
    return NL.join(rows)


def build_wiki_page(topic: str, owner_stream: str, source_files: list) -> str:
    """source_files -> topic wiki 페이지 (frontmatter + body) 생성.

    Args:
        topic: wiki slug (예: lobby, back-office)
        owner_stream: 소유 스트림 (예: S2, S3)
        source_files: raw docs 경로 목록

    Returns:
        완성된 wiki 페이지 문자열 (frontmatter 포함).
    """
    now_iso = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    NL = chr(10)
    if not source_files:
        fm = _build_frontmatter(topic, owner_stream, [], 0, now_iso)
        title = topic.replace("-", " ").title()
        return fm + "# " + title + " Topic Wiki" + NL + NL + "*(source_files 미지정 -- 빈 skeleton)*" + NL

    raw_text = _read_source_files(source_files)
    compressed = _compress_with_llm(raw_text, topic)
    if compressed is None:
        compressed = _compress_fallback(raw_text)

    token_est = estimate_tokens(compressed)
    title = topic.replace("-", " ").title()
    body = "# " + title + " Topic Wiki" + NL + NL + compressed.strip() + NL
    fm = _build_frontmatter(topic, owner_stream, source_files, token_est, now_iso)
    return fm + body


def build_wiki_result(
    topic: str,
    owner_stream: str,
    source_files: list,
) -> WikiBuildResult:
    """build_wiki_page 를 WikiBuildResult 로 래핑."""
    body = build_wiki_page(topic, owner_stream, source_files)
    return WikiBuildResult(
        body=body,
        token_estimate=estimate_tokens(body),
        source_count=len(source_files),
    )


def main(argv: list) -> int:
    p = argparse.ArgumentParser(description="doc_wiki_build -- wiki 페이지 재생성")
    p.add_argument("--topic", required=True, help="wiki slug")
    p.add_argument("--owner-stream", required=True, help="소유 스트림")
    p.add_argument("--source-files", nargs="+", default=[], help="raw docs 경로")
    p.add_argument("--out", help="출력 파일 경로 (미지정 시 stdout)")
    args = p.parse_args(argv)

    result = build_wiki_result(
        topic=args.topic,
        owner_stream=args.owner_stream,
        source_files=args.source_files,
    )

    if args.out:
        out_path = Path(args.out)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(result.body, encoding="utf-8")
        print("wiki 생성 완료: " + args.out + "  (~" + str(result.token_estimate) + " tokens, " + str(result.source_count) + " files)")
    else:
        print(result.body)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
