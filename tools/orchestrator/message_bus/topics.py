"""Topic ACL — who can publish to which topic.

Convention (mirrors GitHub label scheme):
  stream:S{N}    — only that Stream's identity can publish
  cascade:*      — any Stream can publish (cascade advisory)
  defect:*       — any Stream can publish
  bus:*          — broker-internal events (not user-publishable)
  *              — broadcast (any Stream can publish)
  bench-*, test-*, poc-* — test/dev topics, anyone can publish

Phase 2 PoC: ACL is advisory (warns but does not strictly enforce yet).
Phase 4 hardening: enforce strictly via PreToolUse-equivalent for tool calls.
"""
from __future__ import annotations

import re

# Topics that lock to a specific source identity
_STREAM_TOPIC_RE = re.compile(r"^stream:(S\d+)$")

# Topics any source may publish
_OPEN_TOPIC_PREFIXES = ("cascade:", "defect:", "bench-", "test-", "poc-")
_OPEN_TOPICS = {"*"}

# Reserved (broker only)
_RESERVED_PREFIXES = ("bus:",)


def check_publish_acl(topic: str, source: str) -> tuple[bool, str | None]:
    """Check if `source` can publish to `topic`.

    Returns:
        (allowed, reason) — reason is None if allowed.
    """
    if not topic:
        return False, "topic is empty"

    # Reserved (broker-internal)
    for pfx in _RESERVED_PREFIXES:
        if topic.startswith(pfx):
            return False, f"topic '{topic}' is reserved (prefix '{pfx}')"

    # Open topics
    if topic in _OPEN_TOPICS:
        return True, None
    for pfx in _OPEN_TOPIC_PREFIXES:
        if topic.startswith(pfx):
            return True, None

    # stream:S{N} — only matching source
    m = _STREAM_TOPIC_RE.match(topic)
    if m:
        expected = m.group(1)
        if source == expected:
            return True, None
        return False, (
            f"topic '{topic}' restricted to source='{expected}', "
            f"got source='{source}'"
        )

    # Default-allow for other custom topics (PoC permissive)
    return True, None


def parse_stream_id(source: str) -> str | None:
    """Extract S1~S99 stream id from source string. None if not a stream."""
    m = re.match(r"^(S\d+)", source)
    return m.group(1) if m else None
