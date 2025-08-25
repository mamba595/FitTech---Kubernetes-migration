from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional
from sqlalchemy import Boolean

class UserCreate(BaseModel):
    email: EmailStr
    password: str

class UserInDB(BaseModel):
    id: int
    email: EmailStr
    hashed_password: str

    class Config:
        from_attributes = True

class UserPublic(BaseModel):
    id: int
    email: str