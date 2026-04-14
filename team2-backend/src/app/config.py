"""Centralized settings — single source for all env vars."""
from pydantic import model_validator
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # ── DB ──
    database_url: str = "sqlite:///data/ebs.db"

    # ── Redis ──
    redis_url: str = "redis://localhost:6379/0"
    redis_timeout_ms: int = 500

    # ── JWT / Auth ──
    jwt_secret: str = "dev-secret-change-me-in-production"
    jwt_algorithm: str = "HS256"
    auth_profile: str = "dev"  # dev | staging | prod | live
    jwt_access_ttl_s: int = 3600
    jwt_refresh_ttl_s: int = 604800

    # ── Timeouts ──
    http_timeout_ms: int = 30000
    wsop_poll_timeout_ms: int = 10000
    db_query_timeout_ms: int = 5000
    ws_ping_interval_ms: int = 30000
    ws_pong_timeout_ms: int = 60000
    saga_timeout_ms: int = 60000

    # ── Circuit Breaker ──
    cb_failure_ratio: float = 0.5
    cb_window_size: int = 20
    cb_open_duration_s: int = 30

    # ── Distributed Lock ──
    lock_default_ttl_s: int = 10

    # ── Idempotency ──
    idempotency_ttl_s: int = 86400

    # ── WSOP LIVE ──
    wsop_live_base_url: str = ""
    wsop_poll_interval_s: int = 5

    # ── Misc ──
    rfid_mode: str = "mock"
    log_level: str = "DEBUG"
    cors_origins: list[str] = ["http://localhost:3000"]

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}

    @model_validator(mode="after")
    def validate_prod_secrets(self) -> "Settings":
        if self.auth_profile in ("prod", "live"):
            if self.jwt_secret == "dev-secret-change-me-in-production":
                raise ValueError("JWT_SECRET must be set explicitly in prod/live")
            if "*" in self.cors_origins:
                raise ValueError("Wildcard CORS not allowed in prod/live")
        return self


settings = Settings()
