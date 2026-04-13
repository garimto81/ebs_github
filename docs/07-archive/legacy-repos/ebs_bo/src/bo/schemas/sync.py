from pydantic import BaseModel


class SyncTriggerResponse(BaseModel):
    status: str
    message: str


class SyncStatusResponse(BaseModel):
    status: str
    last_sync_at: str | None = None
    records_synced: int = 0
