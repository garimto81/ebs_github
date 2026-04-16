"""Configs router — API-01 §5.12."""
from fastapi import APIRouter, Depends
from sqlmodel import Session, select

from src.app.database import get_db
from src.middleware.rbac import require_role
from src.models.config import Config
from src.models.schemas import (
    ApiResponse,
    ConfigBulkItem,
    ConfigResponse,
)
from src.models.user import User
from src.services.config_service import upsert_config

router = APIRouter(prefix="/api/v1", tags=["configs"])


@router.get("/configs/{section}")
def api_list_configs_by_section(
    section: str,
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    items = db.exec(select(Config).where(Config.category == section)).all()
    return ApiResponse(
        data=[ConfigResponse.model_validate(c, from_attributes=True) for c in items],
        meta={"total": len(items)},
    )


@router.put("/configs/{section}")
async def api_bulk_update_configs(
    section: str,
    body: list[ConfigBulkItem],
    _user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    results = []
    for item in body:
        cfg, _old = await upsert_config(
            db,
            key=item.key,
            value=item.value,
            scope=item.scope or "global",
            scope_id=item.scope_id,
            category=section,
            description=item.description,
        )
        results.append(ConfigResponse.model_validate(cfg, from_attributes=True))
    return ApiResponse(data=results, meta={"updated": len(results)})
