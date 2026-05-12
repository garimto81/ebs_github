"""Test suite for confluence_pagename_audit._normalize().

S11 Cycle 18 — regression guard for the rename-aware audit. Without
normalization, the audit reports MISMATCH forever after the rename even
when the page title is the legitimate natural-language form of the file
stem. These tests pin the contract so future refactors do not silently
revert the behavior.
"""
from __future__ import annotations

import sys
from pathlib import Path

# Make tools/ importable
REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT / "tools"))

from confluence_pagename_audit import _normalize  # noqa: E402


class TestUnderscoreSpaceEquivalence:
    """Cycle 18 rename use cases — underscored stem == spaced title."""

    def test_back_office_match(self):
        assert _normalize("Back_Office") == _normalize("Back Office")

    def test_command_center_match(self):
        assert _normalize("Command_Center") == _normalize("Command Center")

    def test_rive_standards_match_after_cleanup(self):
        # Future rename target — keep test ready for when RIVE_Standards is
        # renamed to plain "RIVE Standards".
        assert _normalize("RIVE_Standards") == _normalize("RIVE Standards")

    def test_product_ssot_policy_match(self):
        assert _normalize("Product_SSOT_Policy") == _normalize("Product SSOT Policy")


class TestCaseInsensitive:
    """Title casing differs from stem — audit should still match."""

    def test_lowercase_match(self):
        assert _normalize("Lobby") == _normalize("lobby")

    def test_uppercase_match(self):
        assert _normalize("Lobby") == _normalize("LOBBY")


class TestMismatchPreserved:
    """When the title genuinely differs, audit must still flag MISMATCH."""

    def test_descriptive_title_still_mismatch(self):
        # Foundation.md vs "EBS 기초 기획서" — must NOT match.
        assert _normalize("Foundation") != _normalize("EBS 기초 기획서")

    def test_ebs_prefix_still_mismatch(self):
        assert _normalize("1. Product") != _normalize("EBS · 1. Product")

    def test_subtitle_still_mismatch(self):
        # The pre-Cycle-18 titles must register as MISMATCH so audits
        # would correctly flag a regression that re-introduces them.
        old_title = "EBS · Back Office PRD — 보이지 않는 뼈대"
        assert _normalize("Back_Office") != _normalize(old_title)


class TestWhitespaceCollapse:
    """Multiple internal spaces collapse to one."""

    def test_double_space_collapses(self):
        assert _normalize("Back  Office") == _normalize("Back_Office")

    def test_tabs_normalize(self):
        assert _normalize("Back\tOffice") == _normalize("Back Office")

    def test_leading_trailing_strip(self):
        assert _normalize("  Lobby  ") == _normalize("Lobby")
