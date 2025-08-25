from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class WorkoutLogCreate(BaseModel):
    date: Optional[datetime] = None
    workout_type: Optional[str] = None
    duration: Optional[int] = None # en minutos
    total_distance: Optional[float] = None # en kms
    avg_pace: Optional[float] = None
    avg_heart_rate: Optional[int] = None
    max_heart_rate: Optional[int] = None
    calories_burned: Optional[int] = None
    notes: Optional[str] = None

class WorkoutLogInDB(WorkoutLogCreate):
    id: int
    user_id: int

    class Config:
        from_attributes = True