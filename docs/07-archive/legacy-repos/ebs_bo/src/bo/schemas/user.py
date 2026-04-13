from pydantic import BaseModel


class UserCreate(BaseModel):
    email: str
    password: str
    display_name: str
    role: str = "viewer"


class UserUpdate(BaseModel):
    display_name: str | None = None
    role: str | None = None
    is_active: bool | None = None


class UserRead(BaseModel):
    user_id: int
    email: str
    display_name: str
    role: str
    is_active: bool
    created_at: str
