from pydantic import BaseModel
from typing import Optional, Union
from datetime import date


class OnboardingCreate(BaseModel):
    user_id: int
    name: Optional[str] = None
    birthdate: Optional[date] = None
    sex: Optional[str] = None
    height: Optional[int] = None
    weight: Optional[int] = None
    main_goal: Optional[str] = None
    weight_target: Optional[int] = None
    deadline: Optional[date] = None
    medical_conditions: Optional[str] = None
    sleep_hours: Optional[float] = None
    work_schedule: Optional[str] = None
    percFat: Optional[float] = None
    percMuscle: Optional[float] = None
    injuryHist: Optional[str] = None
    expLevel: Optional[str] = None
    restrictedFoods: Optional[str] = None
    timeAvailability: Optional[str] = None
    materialAccess: Optional[str] = None


class OnboardingInDB(OnboardingCreate):
    id: int
    user_id: int

    class Config:
        from_attributes = True