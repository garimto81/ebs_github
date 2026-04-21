"""EBS Pydantic base model — WSOP LIVE 규약 100% 정렬.

외부 JSON 표면은 camelCase, 내부 Python 은 snake_case 양립.
원칙 1 (WSOP LIVE 정렬) 준수 — `docs/2. Development/2.5 Shared/Naming_Conventions.md` v2.
B-088 PR 2 — 모든 Pydantic 요청/응답 모델의 base class.

사용법:
    from src.models.base import EbsBaseModel

    class EventResponse(EbsBaseModel):
        event_id: int       # 외부 JSON: eventId
        event_name: str     # 외부 JSON: eventName
        buy_in: int | None  # 외부 JSON: buyIn

주의:
- SQLModel `table=True` 모델은 이 class 를 상속하지 않는다 (DB column mapping 보존).
- FastAPI `response_model` 에 지정된 class 는 자동으로 `by_alias=True` 로 직렬화.
- Request body 는 `populate_by_name=True` 로 camelCase/snake_case 양립.
"""
from __future__ import annotations

from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel


class EbsBaseModel(BaseModel):
    """EBS 전역 Pydantic base — 외부 camelCase / 내부 snake_case 양립."""

    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
        from_attributes=True,
    )
