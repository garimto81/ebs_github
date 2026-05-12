"""S11 Cycle 11 — Confluence linkify regression tests (URL-first).

Background:
    Cycle 10 emitted <ac:link><ri:page ri:content-title="{stem}"/></ac:link>
    assuming "Confluence page name = file stem". Live audit
    (tools/confluence_pagename_audit.py) proved the invariant fails for 7/7
    Product PRDs (e.g., Foundation.md vs page "EBS 기초 기획서").

    Cycle 11 switches to URL-first anchors when `confluence-url` is present.
    URLs embed the page-id, which is stable across title renames — so links
    work even when titles diverge from stems. ac:link with content-title
    remains as a fallback only when no URL is provided.

These tests pin the new resolution order:
    1. confluence-url present                  → <a href="{url}">
    2. confluence-page-id only (no URL)        → <ac:link><ri:page content-title=stem/>
    3. neither                                  → <code>path</code>
"""
from __future__ import annotations

import sys
from pathlib import Path

import pytest

_CLAUDE_ROOT = Path("C:/claude")
if str(_CLAUDE_ROOT) not in sys.path:
    sys.path.insert(0, str(_CLAUDE_ROOT))

from lib.confluence import md2confluence as m  # noqa: E402


# ---------------------------------------------------------------------------
# Fixtures: docs tree exercising every resolution branch.
# ---------------------------------------------------------------------------


@pytest.fixture()
def fake_repo(tmp_path: Path) -> Path:
    """Build a docs/ tree with three pages:

    1. Foundation.md       — has page_id AND url (Cycle 11 URL-first path)
    2. Legacy_Reference.md — has url only (no page_id)
    3. Id_Only_Page.md     — has page_id only (no url) — ri:content-title fallback
    """
    docs = tmp_path / "docs" / "1. Product"
    docs.mkdir(parents=True)

    (docs / "Foundation.md").write_text(
        "---\n"
        "title: EBS 기초 기획서\n"
        "confluence-page-id: 3625189547\n"
        "confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/X/pages/3625189547\n"
        "---\n\n# Foundation\n",
        encoding="utf-8",
    )

    (docs / "Legacy_Reference.md").write_text(
        "---\n"
        "title: Some Legacy Title\n"
        "confluence-url: https://ggnetwork.atlassian.net/wiki/x/abcDEF\n"
        "---\n\n# Legacy\n",
        encoding="utf-8",
    )

    (docs / "Id_Only_Page.md").write_text(
        "---\n"
        "title: Internal Only\n"
        "confluence-page-id: 9999999999\n"
        "---\n\n# Id Only\n",
        encoding="utf-8",
    )

    return tmp_path


# ---------------------------------------------------------------------------
# 1) repo_map title is always file stem (regardless of frontmatter title:)
# ---------------------------------------------------------------------------


def test_repo_map_title_is_filename_stem(fake_repo: Path) -> None:
    repo_map = m.build_repo_path_to_pageid_map(fake_repo)
    entry = repo_map.get("docs/1. Product/Foundation.md")
    assert entry is not None
    _page_id, title, _url = entry
    assert title == "Foundation", (
        f"title must be file stem (page-name invariant); got {title!r}"
    )
    assert "EBS 기초" not in title, "frontmatter title leaked into repo_map"


# ---------------------------------------------------------------------------
# 2) URL-first: when both page_id AND url exist, anchor uses the URL
# ---------------------------------------------------------------------------


def test_linkify_url_first_when_both_id_and_url(fake_repo: Path) -> None:
    """Cycle 11 invariant: confluence-url anchor beats ri:content-title.

    Page-id URLs are stable across Confluence title renames. ri:content-title
    requires exact title match — which we proved is false in production for
    all 7 Product PRDs (see docs/_generated/confluence-pagename-audit.md).
    """
    repo_map = m.build_repo_path_to_pageid_map(fake_repo)
    current_dir = fake_repo / "docs" / "1. Product"

    out = m._linkify_path(
        "Foundation.md (§Ch.5.4 — Command Center 위치)",
        repo_map=repo_map, current_dir=current_dir, repo_root=fake_repo,
    )

    assert "<a href=" in out, f"expected URL anchor, got: {out}"
    assert "/pages/3625189547" in out, f"page-id URL not surfaced: {out}"
    assert "<ac:link>" not in out, (
        "URL-first must skip ac:link when url is present (Cycle 11). "
        f"Got: {out}"
    )


# ---------------------------------------------------------------------------
# 3) URL fallback: page has url only (no page_id) — still uses URL anchor
# ---------------------------------------------------------------------------


def test_linkify_url_fallback_when_no_page_id(fake_repo: Path) -> None:
    repo_map = m.build_repo_path_to_pageid_map(fake_repo)
    current_dir = fake_repo / "docs" / "1. Product"

    out = m._linkify_path(
        "Legacy_Reference.md",
        repo_map=repo_map, current_dir=current_dir, repo_root=fake_repo,
    )

    assert "https://ggnetwork.atlassian.net/wiki/x/abcDEF" in out, out
    assert "<ac:link>" not in out, "no ac:link when url is the only signal"


# ---------------------------------------------------------------------------
# 4) ri:content-title fallback when only page_id (no URL)
# ---------------------------------------------------------------------------


def test_linkify_uses_ac_link_when_only_page_id(fake_repo: Path) -> None:
    """Pages without confluence-url fall back to ri:content-title=stem.

    Best-effort — works only when the live Confluence title equals the file
    stem. Spec recommends always populating confluence-url to avoid this path.
    """
    repo_map = m.build_repo_path_to_pageid_map(fake_repo)
    current_dir = fake_repo / "docs" / "1. Product"

    out = m._linkify_path(
        "Id_Only_Page.md",
        repo_map=repo_map, current_dir=current_dir, repo_root=fake_repo,
    )

    assert "<ac:link>" in out, f"expected ac:link fallback, got: {out}"
    assert 'ri:content-title="Id_Only_Page"' in out, (
        f"content-title must be stem; got: {out}"
    )


# ---------------------------------------------------------------------------
# 5) Display body preserves parenthetical context
# ---------------------------------------------------------------------------


def test_linkify_preserves_display_text(fake_repo: Path) -> None:
    repo_map = m.build_repo_path_to_pageid_map(fake_repo)
    current_dir = fake_repo / "docs" / "1. Product"

    out = m._linkify_path(
        "Foundation.md (§Ch.5.4 — Command Center 위치)",
        repo_map=repo_map, current_dir=current_dir, repo_root=fake_repo,
    )

    # User-visible body keeps the chapter cue regardless of anchor strategy.
    assert "Foundation.md (§Ch.5.4 — Command Center 위치)" in out, out


# ---------------------------------------------------------------------------
# 6) Truly unmapped path stays <code> (no phantom link)
# ---------------------------------------------------------------------------


def test_linkify_unmapped_path_stays_code(fake_repo: Path) -> None:
    repo_map = m.build_repo_path_to_pageid_map(fake_repo)
    current_dir = fake_repo / "docs" / "1. Product"

    out = m._linkify_path(
        "Nonexistent_Page.md",
        repo_map=repo_map, current_dir=current_dir, repo_root=fake_repo,
    )

    assert "<a href=" not in out, "phantom URL anchor for unmapped path"
    assert "<ac:link" not in out, "phantom ac:link for unmapped path"
    assert "<code>" in out


# ---------------------------------------------------------------------------
# 7) Paths with spaces ("2. Development/2.4 Command Center/...") resolve
# ---------------------------------------------------------------------------


def test_linkify_handles_path_with_spaces(fake_repo: Path) -> None:
    docs = fake_repo / "docs" / "2. Development" / "2.4 Command Center"
    docs.mkdir(parents=True)
    (docs / "Overview.md").write_text(
        "---\n"
        "title: Overview\n"
        "confluence-page-id: 3819602576\n"
        "confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/X/pages/3819602576\n"
        "---\n\n# Overview\n",
        encoding="utf-8",
    )

    repo_map = m.build_repo_path_to_pageid_map(fake_repo)
    current_dir = fake_repo / "docs" / "1. Product"

    out = m._linkify_path(
        "../2. Development/2.4 Command Center/Overview.md (정본 — D7 §5.1)",
        repo_map=repo_map, current_dir=current_dir, repo_root=fake_repo,
    )

    assert "<a href=" in out, f"path with spaces not resolved; got: {out}"
    assert "/pages/3819602576" in out, f"page-id URL missing; got: {out}"


# ---------------------------------------------------------------------------
# 8) Cross-link transform mirrors URL-first behavior
# ---------------------------------------------------------------------------


def test_cross_link_transform_uses_url_first(fake_repo: Path) -> None:
    repo_map = m.build_repo_path_to_pageid_map(fake_repo)
    current_dir = fake_repo / "docs" / "1. Product"

    html_in = '<p>See <a href="Foundation.md">the foundation</a> for details.</p>'
    html_out = m.transform_cross_links(html_in, repo_map, current_dir, fake_repo)

    assert "/pages/3625189547" in html_out, (
        f"body cross-link must use page-id URL (Cycle 11). Got: {html_out}"
    )
    assert "<ac:link>" not in html_out, (
        f"body must skip ac:link when url is present. Got: {html_out}"
    )
