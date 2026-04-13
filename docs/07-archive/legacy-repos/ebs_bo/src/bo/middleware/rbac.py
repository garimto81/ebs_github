from typing import Callable

from fastapi import Depends, HTTPException, Request, status
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware

from bo.db.models import User
from bo.middleware.auth import get_current_user
from bo.services.auth_service import verify_token


def require_role(*allowed_roles: str) -> Callable:
    def role_checker(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Role '{current_user.role}' not allowed. Required: {', '.join(allowed_roles)}",
            )
        return current_user

    return role_checker


class ViewerReadOnlyMiddleware(BaseHTTPMiddleware):
    """API-06 §5.4: Viewer는 GET만 허용, 그 외 메서드 → 403"""

    EXEMPT_PATHS = {"/api/v1/auth/login", "/api/v1/auth/refresh", "/api/v1/auth/verify-2fa"}

    async def dispatch(self, request: Request, call_next):
        if request.method == "GET" or request.method == "OPTIONS":
            return await call_next(request)

        path = request.url.path
        if path in self.EXEMPT_PATHS or not path.startswith("/api/"):
            return await call_next(request)

        # DELETE /auth/session (logout) 은 모든 역할 허용
        if request.method == "DELETE" and path == "/api/v1/auth/session":
            return await call_next(request)

        auth_header = request.headers.get("authorization", "")
        if not auth_header.startswith("Bearer "):
            return await call_next(request)

        token = auth_header[7:]
        payload = verify_token(token)
        if payload and payload.get("role") == "viewer":
            return JSONResponse(
                status_code=403,
                content={"data": None, "error": {"code": "AUTH_FORBIDDEN", "message": "Viewer role is read-only"}},
            )

        return await call_next(request)
