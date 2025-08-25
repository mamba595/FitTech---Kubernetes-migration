from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class FoodLogCreate(BaseModel):
    food_name: str
    serving_size: Optional[int] = None
    serving_unit: Optional[str] = None
    calories: Optional[int] = None 
    protein: Optional[int] = None
    carbs: Optional[int] = None
    fats: Optional[int] = None
    timestamp: Optional[datetime] = None

class FoodLogInDB(FoodLogCreate):
    id: int
    user_id: int

    class Config:
        from_attributes = True