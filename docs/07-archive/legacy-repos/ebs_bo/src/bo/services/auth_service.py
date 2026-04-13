from datetime import datetime, timedelta, timezone

import pyotp
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlmodel import Session, select

from bo.config import settings
from bo.db.models import User

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(plain: str) -> str:
    return pwd_context.hash(plain)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


def create_access_token(user: User) -> str:
    now = datetime.now(timezone.utc)
    expire = now + timedelta(minutes=settings.access_token_expire_minutes)
    payload = {
        "sub": str(user.user_id),
        "email": user.email,
        "role": user.role,
        "iat": now,
        "exp": expire,
        "type": "access",
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm="HS256")


def create_refresh_token(user: User) -> str:
    now = datetime.now(timezone.utc)
    expire = now + timedelta(days=settings.refresh_token_expire_days)
    payload = {
        "sub": str(user.user_id),
        "iat": now,
        "exp": expire,
        "type": "refresh",
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm="HS256")


def create_session(db: Session, user_id: int, ip_address: str | None = None) -> "UserSession":
    """Create session with 2-session limit enforcement."""
    from bo.db.models.user_session import UserSession

    # Count active sessions
    active = db.exec(
        select(UserSession).where(
            UserSession.user_id == user_id,
            UserSession.is_active == True,  # noqa: E712
        ).order_by(UserSession.created_at)
    ).all()
    # If 2+ sessions, invalidate oldest
    while len(active) >= 2:
        oldest = active.pop(0)
        oldest.is_active = False
        db.add(oldest)
    # Create new session
    session = UserSession(user_id=user_id, ip_address=ip_address, is_active=True)
    db.add(session)
    db.commit()
    db.refresh(session)
    return session


def invalidate_user_sessions(db: Session, user_id: int) -> None:
    """Invalidate all sessions for a user (used on deactivation/deletion)."""
    from bo.db.models.user_session import UserSession

    sessions = db.exec(
        select(UserSession).where(
            UserSession.user_id == user_id,
            UserSession.is_active == True,  # noqa: E712
        )
    ).all()
    for s in sessions:
        s.is_active = False
        db.add(s)
    db.commit()


def verify_token(token: str) -> dict | None:
    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=["HS256"])
        return payload
    except JWTError:
        return None


def authenticate_user(session: Session, email: str, password: str) -> User | None:
    stmt = select(User).where(User.email == email, User.is_active == True)  # noqa: E712
    user = session.exec(stmt).first()
    if user and verify_password(password, user.password_hash):
        return user
    return None


def generate_totp_secret() -> str:
    return pyotp.random_base32()


def get_totp_uri(secret: str, email: str) -> str:
    return pyotp.totp.TOTP(secret).provisioning_uri(name=email, issuer_name="EBS")


def verify_totp(secret: str, code: str) -> bool:
    totp = pyotp.TOTP(secret)
    return totp.verify(code, valid_window=1)  # ±30sec tolerance


def create_temp_token(user: User) -> str:
    """Short-lived token for 2FA verification step."""
    expire = datetime.now(timezone.utc) + timedelta(minutes=5)
    payload = {
        "sub": str(user.user_id),
        "exp": expire,
        "type": "2fa_temp",
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm="HS256")
