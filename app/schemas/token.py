from pydantic import BaseModel
from typing import Optional

class TokenPayload(BaseModel):
    sub: Optional[int] = None  
    exp: Optional[int] = None
