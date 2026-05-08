"""GitHub Issue Comment mirror — Phase 3 Hybrid fallback channel.

Broker가 살아있을 때 = MCP push (50ms latency).
Broker가 죽었을 때 = GH Issue comment polling (30s latency, but durable).

Selective mirroring: only "important" events (configurable filter) get mirrored
to avoid GH API rate limits (5000 req/h authenticated user).
"""
from __future__ import annotations

import asyncio
import json
import logging
import os
import shutil
import subprocess
from collections.abc import Callable
from datetime import datetime, timezone
from pathlib import Path

logger = logging.getLogger(__name__)

# Default selective filter — topics worth mirroring
_DEFAULT_MIRROR_TOPICS = (
    "stream:",       # all stream:S{N} signals (DONE, BLOCKED, etc.)
    "cascade:",      # cascade advisories
    "defect:",       # defect reports
)

# Default GH issue number for fallback (the conductor epic)
DEFAULT_FALLBACK_ISSUE = int(os.environ.get("EBS_BUS_FALLBACK_ISSUE", "168"))


class GitHubMirror:
    """Mirror selected events to GH Issue comments. Async fire-and-forget."""

    def __init__(
        self,
        repo: str | None = None,
        fallback_issue: int = DEFAULT_FALLBACK_ISSUE,
        mirror_filter: Callable[[str], bool] | None = None,
        max_concurrent: int = 4,
    ):
        self.repo = repo  # None = use git remote default
        self.fallback_issue = fallback_issue
        self.mirror_filter = mirror_filter or self._default_filter
        self.semaphore = asyncio.Semaphore(max_concurrent)
        self._gh_path = shutil.which("gh")
        self._enabled = self._gh_path is not None
        if not self._enabled:
            logger.warning("gh CLI not found; GitHub mirror disabled")

    @staticmethod
    def _default_filter(topic: str) -> bool:
        return any(topic.startswith(p) for p in _DEFAULT_MIRROR_TOPICS)

    async def maybe_mirror(
        self,
        topic: str,
        seq: int,
        source: str,
        ts: str,
        payload: dict,
        issue: int | None = None,
    ) -> bool:
        """Enqueue mirror if filter passes. Returns True if mirrored."""
        if not self._enabled:
            return False
        if not self.mirror_filter(topic):
            return False
        target_issue = issue or self.fallback_issue
        body = self._format_comment(topic, seq, source, ts, payload)
        # Fire-and-forget — don't block publish path
        asyncio.create_task(self._post_comment(target_issue, body))
        return True

    @staticmethod
    def _format_comment(
        topic: str, seq: int, source: str, ts: str, payload: dict
    ) -> str:
        return (
            f"🤖 **bus mirror** seq=`{seq}` topic=`{topic}` source=`{source}`\n"
            f"\n"
            f"**ts**: {ts}\n"
            f"**payload**:\n"
            f"```json\n{json.dumps(payload, ensure_ascii=False, indent=2)}\n```\n"
        )

    async def _post_comment(self, issue: int, body: str) -> None:
        async with self.semaphore:
            try:
                cmd = [self._gh_path, "issue", "comment", str(issue), "--body", body]
                if self.repo:
                    cmd.extend(["--repo", self.repo])
                proc = await asyncio.create_subprocess_exec(
                    *cmd,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.PIPE,
                )
                _, stderr = await proc.communicate()
                if proc.returncode != 0:
                    logger.error(
                        f"gh issue comment failed (rc={proc.returncode}): "
                        f"{stderr.decode('utf-8', errors='replace')[:200]}"
                    )
            except Exception as e:
                logger.error(f"gh mirror exception: {e}")

    async def health_check(self) -> dict:
        """Verify gh CLI auth + reach repo."""
        if not self._enabled:
            return {"ok": False, "reason": "gh CLI not installed"}
        try:
            proc = await asyncio.create_subprocess_exec(
                self._gh_path, "auth", "status",
                stdout=subprocess.DEVNULL, stderr=subprocess.PIPE,
            )
            await proc.communicate()
            return {"ok": proc.returncode == 0}
        except Exception as e:
            return {"ok": False, "reason": str(e)}
