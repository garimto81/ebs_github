"""Alembic migration environment for EBS Backend.

Uses SQLModel metadata as target. Supports online (with DB connection) and
offline (SQL script generation) modes. Reads DATABASE_URL from env or falls
back to alembic.ini sqlalchemy.url.
"""
from __future__ import annotations

import os
from logging.config import fileConfig

from sqlalchemy import engine_from_config, pool
from sqlmodel import SQLModel

from alembic import context

# Register models so their tables exist in SQLModel.metadata
from src.models.audit_event import AuditEvent, IdempotencyKey  # noqa: F401
from src.models.audit_log import AuditLog  # noqa: F401
from src.models.competition import Competition, Event, EventFlight, Series  # noqa: F401
from src.models.table import Player, Table, TableSeat  # noqa: F401
from src.models.user import User, UserSession  # noqa: F401

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Override sqlalchemy.url with env var if provided
database_url = os.environ.get("DATABASE_URL")
if database_url:
    config.set_main_option("sqlalchemy.url", database_url)

target_metadata = SQLModel.metadata


def run_migrations_offline() -> None:
    """Emit SQL to stdout without a live DB connection."""
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        render_as_batch=True,
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Apply migrations against a live DB connection."""
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            render_as_batch=True,  # SQLite ALTER TABLE support
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
