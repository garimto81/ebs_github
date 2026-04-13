class SyncStatus:
    def __init__(self):
        self.status = "idle"
        self.last_sync_at: str | None = None
        self.last_error: str | None = None
        self.records_synced: int = 0


sync_status = SyncStatus()


def trigger_sync() -> dict:
    sync_status.status = "running"
    # Stub: In production, this would poll WSOP LIVE API
    sync_status.status = "idle"
    return {"status": "accepted", "message": "Sync job has been queued"}


def get_sync_status() -> dict:
    return {
        "status": sync_status.status,
        "last_sync_at": sync_status.last_sync_at,
        "last_error": sync_status.last_error,
        "records_synced": sync_status.records_synced,
    }
