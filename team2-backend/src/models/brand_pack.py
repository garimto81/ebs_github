"""BrandPack model — event branding data (Cycle 17, 사용자 표 #6).

SSOT: docs/1. Product/RIVE_Standards.md Ch.7 — Brand Pack
  "컬러 팔레트, 폰트, 로고 (3 종), 그래픽 모티프"

Brand Pack 은 한 대회가 시작될 때 모든 `.riv` 파일에 동시 주입되어
overlay 의 시각적 정체성을 결정한다. 예: `wsop_2026`, `ept_2026`, `gg_master`.
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Optional

from sqlmodel import Field, SQLModel


def utcnow() -> str:
    return datetime.now(timezone.utc).isoformat()


class BrandPack(SQLModel, table=True):
    __tablename__ = "brand_packs"

    brand_pack_id: Optional[int] = Field(default=None, primary_key=True)
    # 식별자 (slug 형식, 유일). 예: "wsop_2026", "ept_2026".
    name: str = Field(nullable=False, unique=True, index=True)
    # 사람이 읽는 이름. 예: "WSOP 2026 Main Event".
    display_name: str = Field(nullable=False)

    # 컬러 팔레트 (RIVE_Standards Ch.7 — "컬러 팔레트")
    primary_color: str = Field(nullable=False, max_length=16)
    secondary_color: str = Field(nullable=False, max_length=16)
    accent_color: str = Field(nullable=False, max_length=16)

    # 폰트 (RIVE_Standards Ch.7 — "폰트")
    font_family: Optional[str] = Field(default=None, max_length=128)

    # 로고 3 종 (RIVE_Standards Ch.7 — "로고 (3 종)")
    logo_primary_url: Optional[str] = Field(default=None)
    logo_secondary_url: Optional[str] = Field(default=None)
    logo_tertiary_url: Optional[str] = Field(default=None)

    # 그래픽 모티프 (RIVE_Standards Ch.7 — "그래픽 모티프"). JSON blob.
    motif_data: str = Field(default="{}")

    # 한 시점에 하나의 default 만 유효 (Skin 패턴 동일).
    is_default: bool = Field(default=False)

    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)
