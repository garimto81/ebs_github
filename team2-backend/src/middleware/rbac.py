"""RBAC middleware — JWT extraction + role-based access control."""
from typing import Callable

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError
from sqlmodel import Session, select

from src.app.database import get_db
from src.models.user import User
from src.security.jwt import decode_token

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> User:
    """Decode Bearer token → load User from DB. Raises 401 on failure."""
    try:
        payload = decode_token(token)
        if payload.get("type") != "access":
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="AUTH_UNAUTHORIZED")
        user_id = int(payload["sub"])
    except (JWTError, KeyError, ValueError):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="AUTH_UNAUTHORIZED")

    user = db.exec(select(User).where(User.user_id == user_id)).first()
    if user is None or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="AUTH_UNAUTHORIZED")
    return user


def require_role(*roles: str) -> Callable:
    """Dependency factory — checks that current user has one of the given roles."""

    def _checker(user: User = Depends(get_current_user)) -> User:
        if user.role not in roles:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="PERMISSION_DENIED")
        return user

    return _checker
