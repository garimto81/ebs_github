"""Topic ACL — who can publish to which topic.

Convention (mirrors GitHub label scheme):
  stream:S{N}    — only that Stream's identity can publish
                   (Stream id may contain letters/digits/dashes: e.g. S10-A, S10-W)
  cascade:*      — any Stream can publish (cascade advisory)
  defect:*       — any Stream can publish (defect/bug report)
  audit:*        — any Stream can publish (audit signals)
  pipeline:*     — any Stream can publish (9-session pipeline: gap→write→dev→qa, v10.4)
  bus:*          — broker-internal events (not user-publishable)
  *              — broadcast (any Stream can publish)
  bench-*, test-*, poc-* — test/dev topics, anyone can publish (deny in prod mode)

v11 Phase A — strict mode by default:
  - Default-allow REMOVED. Custom topics must match a whitelist or explicit prefix.
  - test/bench/poc prefixes only allowed when EBS_BUS_DEV_MODE=1 environment.
  - Strict enforcement at publish_event tool entry (server.py).
"""
from __future__ import annotations

import os
import re

# Topics that lock to a specific source identity
# v10.4: allow dashes in stream id (e.g. S10-A, S10-W) for 9-session matrix
_STREAM_TOPIC_RE = re.compile(r"^stream:(S[\w-]+)$")

# Topics any source may publish
# v10.4: added "pipeline:" for cross-cutting gap→write→dev→qa flow
# v11.1 (B-222): added "chat:" for inter-session chat layer
_OPEN_TOPIC_PREFIXES = ("cascade:", "defect:", "audit:", "pipeline:", "chat:")
_OPEN_TOPICS = {"*"}

# Reserved (broker only)
_RESERVED_PREFIXES = ("bus:",)

# Dev/test topics (allowed only when EBS_BUS_DEV_MODE=1)
_DEV_TOPIC_PREFIXES = ("bench-", "test-", "poc-")

# v11.1 (B-222) — source="user" anti-spoofing.
# Only the chat-server (Web UI proxy) may publish as the human user.
_USER_SOURCE = "user"
_USER_AUTHORIZED_PUBLISHERS = {"chat-server"}


def _dev_mode_enabled() -> bool:
    return os.environ.get("EBS_BUS_DEV_MODE", "1") == "1"  # default ON for now (v11 Phase A)


def check_publish_acl(
    topic: str, source: str, publisher_id: str = ""
) -> tuple[bool, str | None]:
    """Check if `source` can publish to `topic`.

    v11 Phase A — strict mode:
        Custom topics not matching any whitelist prefix are DENIED
        (was: default-allow in PoC).
    v11.1 (B-222) — source='user' protected by publisher_id whitelist.

    Args:
        topic: Topic string (e.g., "stream:S2", "chat:room:design").
        source: Sender identity (e.g., "S2", "user").
        publisher_id: Caller process identifier (e.g., "chat-server").
            Used to gate source='user' anti-spoofing.

    Returns:
        (allowed, reason) — reason is None if allowed.
    """
    if not topic:
        return False, "topic is empty"

    # v11.1: source='user' may only be published by chat-server.
    if source == _USER_SOURCE and publisher_id not in _USER_AUTHORIZED_PUBLISHERS:
        return False, (
            f"source='{_USER_SOURCE}' reserved for Web UI; "
            f"publisher_id='{publisher_id}' not authorized "
            f"(allowed: {sorted(_USER_AUTHORIZED_PUBLISHERS)})"
        )

    # Reserved (broker-internal) — always deny external publishers
    for pfx in _RESERVED_PREFIXES:
        if topic.startswith(pfx):
            return False, f"topic '{topic}' is reserved (prefix '{pfx}')"

    # Broadcast topic
    if topic in _OPEN_TOPICS:
        return True, None

    # Open prefixes (cascade/defect/audit) — any source allowed
    for pfx in _OPEN_TOPIC_PREFIXES:
        if topic.startswith(pfx):
            return True, None

    # Dev/test topics — gated on EBS_BUS_DEV_MODE
    for pfx in _DEV_TOPIC_PREFIXES:
        if topic.startswith(pfx):
            if _dev_mode_enabled():
                return True, None
            return False, (
                f"topic '{topic}' is dev/test only "
                f"(set EBS_BUS_DEV_MODE=1 to enable)"
            )

    # stream:S{N} — only matching source identity
    m = _STREAM_TOPIC_RE.match(topic)
    if m:
        expected = m.group(1)
        if source == expected:
            return True, None
        return False, (
            f"topic '{topic}' restricted to source='{expected}', "
            f"got source='{source}'"
        )

    # v11 strict: unknown topic prefixes are DENIED (was default-allow in PoC)
    return False, (
        f"topic '{topic}' does not match any whitelist prefix. "
        f"Allowed prefixes: stream:S<N>, cascade:, defect:, audit:, pipeline:, '*'. "
        f"Dev: bench-/test-/poc- (if EBS_BUS_DEV_MODE=1)."
    )


def parse_stream_id(source: str) -> str | None:
    """Extract S1~S99 (incl. S10-A/S10-W variants) stream id from source string. None if not a stream."""
    m = re.match(r"^(S[\w-]+)", source)
    return m.group(1) if m else None
