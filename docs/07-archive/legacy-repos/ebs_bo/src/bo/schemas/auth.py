from pydantic import BaseModel


class SessionUser(BaseModel):
    user_id: int
    email: str
    display_name: str
    role: str
    table_ids: list[int] = []


class SessionNavigation(BaseModel):
    last_series_id: int | None = None
    last_event_id: int | None = None
    last_flight_id: int | None = None
    last_table_id: int | None = None
    last_screen: str | None = None


class TokenUser(BaseModel):
    user_id: int
    email: str
    role: str
    table_ids: list[int] = []


class LoginRequest(BaseModel):
    email: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "Bearer"
    requires_2fa: bool = False
    expires_in: int
    user: TokenUser


class TwoFaSetupResponse(BaseModel):
    secret: str
    qr_uri: str
    backup_codes: list[str] = []


class TwoFaVerifyRequest(BaseModel):
    temp_token: str  # temporary token from login when 2fa required
    totp_code: str  # 6-digit TOTP code


class TwoFaDisableRequest(BaseModel):
    totp_code: str  # current TOTP code to confirm


class RefreshRequest(BaseModel):
    refresh_token: str


class SessionResponse(BaseModel):
    user: SessionUser
    session: SessionNavigation
