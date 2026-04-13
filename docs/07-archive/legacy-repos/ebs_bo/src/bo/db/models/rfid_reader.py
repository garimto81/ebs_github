from sqlmodel import SQLModel, Field

from .base import utcnow


class RfidReader(SQLModel, table=True):
    __tablename__ = "rfid_readers"
    reader_id: int | None = Field(default=None, primary_key=True)
    serial_number: str = Field(nullable=False, unique=True, index=True)
    alias: str | None = None
    table_id: int | None = Field(default=None, foreign_key="tables.table_id")
    status: str = Field(default="offline")  # online / offline / error
    mode: str = Field(default="mock")  # real / mock
    firmware_version: str | None = None
    last_seen_at: str | None = None
    registered_at: str = Field(default_factory=utcnow)
