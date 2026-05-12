"""Chat payload Pydantic schemas.

본 schema 는 docs/4. Operations/Chat_Protocol.md §1 의 직접 반영.
"""
from __future__ import annotations

from typing import Literal
from pydantic import BaseModel, Field


ChatKind = Literal["msg", "reply", "system", "decision"]


class ChatMessage(BaseModel):
    """Single chat message payload (broker payload 본문)."""

    kind: ChatKind
    from_: str = Field(alias="from")
    to: list[str] = Field(default_factory=list)
    body: str = Field(max_length=4000)
    reply_to: int | None = None
    thread_id: str | None = None
    mentions: list[str] = Field(default_factory=list)
    ts: str  # ISO8601, client-supplied

    model_config = {"populate_by_name": True}


class SendRequest(BaseModel):
    """POST /chat/send body."""

    channel: str  # e.g., "room:design"
    body: str = Field(max_length=4000)
    reply_to: int | None = None
    thread_id: str | None = None
    mentions: list[str] = Field(default_factory=list)
