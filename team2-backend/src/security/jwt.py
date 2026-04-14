"""JWT token creation & decoding — python-jose."""
from datetime import datetime, timedelta, timezone

from jose import JWTError, jwt

from src.app.config import settings

# Environment-based Access TTL defaults (CCR-006)
_ACCESS_TTL_MAP: dict[str, int] = {
    "dev": 3600,       # 1h
    "staging": 7200,   # 2h
    "prod": 7200,      # 2h
    "live": 43200,     # 12h
}

# Refresh TTL defaults
_REFRESH_TTL_MAP: dict[str, int] = {
    "dev": 86400,      # 24h
    "staging": 604800,  # 7d
    "prod": 604800,
    "live": 604800,
}


def _get_access_ttl() -> int:
    """Return access token TTL in seconds.

    settings.jwt_access_ttl_s takes precedence if explicitly set to
    a non-default value; otherwise fall back to profile-based map.
    """
    profile = settings.auth_profile
    default_for_profile = _ACCESS_TTL_MAP.get(profile, 3600)
    # If settings value matches default dev (3600) AND profile is not dev,
    # use profile map. Otherwise respect explicit override.
    if settings.jwt_access_ttl_s != 3600 or profile == "dev":
        return settings.jwt_access_ttl_s
    return default_for_profile


def _get_refresh_ttl() -> int:
    profile = settings.auth_profile
    return _REFRESH_TTL_MAP.get(profile, 604800)


def get_access_ttl() -> int:
    """Public accessor for access TTL (used by service layer)."""
    return _get_access_ttl()


def get_refresh_ttl() -> int:
    """Public accessor for refresh TTL."""
    return _get_refresh_ttl()


def create_access_token(user_id: int, email: str, role: str) -> str:
    now = datetime.now(timezone.utc)
    expire = now + timedelta(seconds=_get_access_ttl())
    payload = {
        "sub": str(user_id),
        "email": email,
        "role": role,
        "type": "access",
        "iat": int(now.timestamp()),
        "exp": int(expire.timestamp()),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def create_refresh_token(user_id: int) -> str:
    now = datetime.now(timezone.utc)
    expire = now + timedelta(seconds=_get_refresh_ttl())
    payload = {
        "sub": str(user_id),
        "type": "refresh",
        "iat": int(now.timestamp()),
        "exp": int(expire.timestamp()),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def decode_token(token: str) -> dict:
    """Decode and validate JWT. Raises JWTError on failure."""
    return jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
