from sqlmodel import SQLModel, Field

from .base import utcnow


class OutputPreset(SQLModel, table=True):
    __tablename__ = "output_presets"
    preset_id: int | None = Field(default=None, primary_key=True)
    name: str = Field(nullable=False, unique=True)
    output_type: str = Field(default="ndi")
    width: int = Field(default=1920)
    height: int = Field(default=1080)
    framerate: int = Field(default=60)
    security_delay_sec: int = Field(default=0)
    chroma_key: bool = Field(default=False)
    is_default: bool = Field(default=False)
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)
