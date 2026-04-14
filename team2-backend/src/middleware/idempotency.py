"""Idempotency middleware — replay cached responses for duplicate mutation requests."""
import hashlib

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.responses import JSONResponse
from sqlmodel import Session

from src.app.database import get_engine
from src.repositories.idempotency_store import IdempotencyStore

_MUTATION_METHODS = {"POST", "PUT", "PATCH", "DELETE"}


class IdempotencyMiddleware(BaseHTTPMiddleware):
    """Intercept mutation requests with Idempotency-Key header.

    - Same key + same request_hash → replay cached response.
    - Same key + different request_hash → 409 IDEMPOTENCY_KEY_REUSED.
    - No header → passthrough (no guarantee).
    """

    async def dispatch(
        self, request: Request, call_next: RequestResponseEndpoint,
    ) -> Response:
        # Only intercept mutation methods
        if request.method not in _MUTATION_METHODS:
            return await call_next(request)

        idem_key = request.headers.get("Idempotency-Key")
        if not idem_key:
            return await call_next(request)

        # Read body once and cache for downstream
        body_bytes = await request.body()

        # Build request hash: method + path + body
        hash_input = f"{request.method}\n{request.url.path}\n".encode() + body_bytes
        request_hash = hashlib.sha256(hash_input).hexdigest()

        # Extract user_id from request state or auth header (best-effort)
        user_id = self._extract_user_id(request)

        with Session(get_engine()) as db:
            existing = IdempotencyStore.get_or_none(user_id, idem_key, db)

            if existing is not None:
                # Check if expired
                from datetime import datetime, timezone

                def _is_expired(expires_at_str: str) -> bool:
                    expires = datetime.fromisoformat(expires_at_str.replace("Z", "+00:00"))
                    return expires < datetime.now(timezone.utc)

                if _is_expired(existing.expires_at):
                    # Expired — delete and treat as miss
                    db.delete(existing)
                    db.commit()
                else:
                    if existing.request_hash == request_hash:
                        # Replay cached response
                        return Response(
                            content=existing.response_body or "",
                            status_code=existing.status_code,
                            media_type="application/json",
                            headers={"Idempotent-Replayed": "true"},
                        )
                    else:
                        # Same key, different payload
                        return JSONResponse(
                            status_code=409,
                            content={
                                "data": None,
                                "error": {
                                    "code": "IDEMPOTENCY_KEY_REUSED",
                                    "message": "Idempotency key already used with different request body",
                                },
                                "meta": None,
                            },
                        )

        # Miss — process downstream
        response = await call_next(request)

        # Cache successful responses (2xx)
        if 200 <= response.status_code < 300:
            # Read the response body
            resp_body = b""
            async for chunk in response.body_iterator:
                if isinstance(chunk, str):
                    resp_body += chunk.encode()
                else:
                    resp_body += chunk

            with Session(get_engine()) as db:
                IdempotencyStore.save(
                    user_id=user_id,
                    key=idem_key,
                    method=request.method,
                    path=request.url.path,
                    request_hash=request_hash,
                    status_code=response.status_code,
                    response_body=resp_body.decode("utf-8", errors="replace"),
                    db=db,
                )

            # Return a new response since we consumed the body_iterator
            return Response(
                content=resp_body,
                status_code=response.status_code,
                media_type=response.media_type,
                headers=dict(response.headers),
            )

        return response

    @staticmethod
    def _extract_user_id(request: Request) -> str:
        """Best-effort user_id extraction from Authorization header."""
        auth = request.headers.get("Authorization", "")
        if auth.startswith("Bearer "):
            token = auth[7:]
            try:
                from src.security.jwt import decode_token
                payload = decode_token(token)
                return str(payload.get("sub", "anonymous"))
            except Exception:
                pass
        return "anonymous"
