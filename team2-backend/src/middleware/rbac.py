"""RBAC middleware — JWT extraction + role-based access control."""
from typing import Callable

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError
from sqlmodel import Session, select

from src.app.database import get_db
from src.models.user import User
from src.security.blacklist import is_revoked
from src.security.jwt import decode_token

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> User:
    """Decode Bearer token → load User from DB. Raises 401 on failure.

    BS-01 §강제 무효화: jti blacklist 검증 (M1 Item 2). jti 누락 토큰은 legacy 로
    간주하고 blacklist 검사 skip (rolling deploy 호환).
    """
    try:
        payload = decode_token(token)
        if payload.get("type") != "access":
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="AUTH_UNAUTHORIZED")
        user_id = int(payload["sub"])
    except (JWTError, KeyError, ValueError):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="AUTH_UNAUTHORIZED")

    # blacklist:jti:{jti} 검증 — BS-01 §강제 무효화 SSOT
    jti = payload.get("jti")
    if jti and is_revoked(jti):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="AUTH_TOKEN_REVOKED")

    user = db.exec(select(User).where(User.user_id == user_id)).first()
    if user is None or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="AUTH_UNAUTHORIZED")
    return user


def get_current_token_payload(token: str = Depends(oauth2_scheme)) -> dict:
    """Bearer access token 의 raw payload 를 반환. logout 등에서 jti 추출용."""
    try:
        payload = decode_token(token)
        if payload.get("type") != "access":
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="AUTH_UNAUTHORIZED")
        return payload
    except (JWTError, KeyError, ValueError):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="AUTH_UNAUTHORIZED")


def require_role(*roles: str) -> Callable:
    """Dependency factory — checks that current user has one of the given roles."""

    def _checker(user: User = Depends(get_current_user)) -> User:
        if user.role not in roles:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="PERMISSION_DENIED")
        return user

    return _checker
