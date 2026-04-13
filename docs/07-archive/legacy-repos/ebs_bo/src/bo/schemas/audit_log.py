from pydantic import BaseModel


class AuditLogRead(BaseModel):
    id: int
    user_id: int
    entity_type: str
    entity_id: int | None
    action: str
    detail: str | None
    ip_address: str | None
    created_at: str
