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
    # Cycle 20 Wave 2 — webhook receiver (chip count sync, issue #435).
    # Shared HMAC-SHA256 secret with WSOP LIVE. Out-of-band rotation; _prev
    # holds the previous secret during grace period (spec §6.3).
    wsop_live_webhook_secret: str = ""
    wsop_live_webhook_secret_prev: str = ""
    # Replay-protection window (seconds). Spec §6.2 = 300s.
    wsop_live_webhook_timestamp_skew_s: int = 300

    # ── Misc ──
    rfid_mode: str = "mock"
    log_level: str = "DEBUG"
    cors_origins: list[str] = ["http://localhost:3000"]

    # ── Export folders / defaults (Cycle 4 #264, docs/2.2 Backend/Settings.md) ──
    # 컨테이너 내부 절대 경로. host 매핑은 docker-compose volumes 책임.
    api_db_export_folder: str = "/app/data/exports/db"
    export_logs_folder: str = "/app/data/exports/logs"
    # JSON 문자열 로 보관 (pydantic-settings 가 dict 자동 파싱 시도 회피).
    # 사용 시 `json.loads(settings.export_defaults)` — Settings.md §3.3 schema.
    export_defaults: str = (
        '{"format":"csv","includeHeaders":true,"maxRows":100000,'
        '"timezone":"UTC","compression":"none"}'
    )

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
