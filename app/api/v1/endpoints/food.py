from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime

from app.models.food import FoodLog
from app.schemas.food import FoodLogCreate, FoodLogInDB
from app.api.deps import get_db, get_current_user

router = APIRouter()


@router.post("/users/{user_id}/food-logs", response_model=FoodLogInDB, status_code=201)
def create_food_log(
    user_id: int,
    log: FoodLogCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    if user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")

    log_data = log.dict()
    if log_data.get("timestamp") is None:
        log_data["timestamp"] = datetime.utcnow()

    food_log = FoodLog(user_id=user_id, **log_data)
    db.add(food_log)
    db.commit()
    db.refresh(food_log)
    return food_log


@router.get("/users/{user_id}/food-logs", response_model=list[FoodLogInDB])
def get_food_logs(
    user_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    if user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")

    logs = db.query(FoodLog).filter(FoodLog.user_id == user_id).all()
    return logs
