from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime

from app.models.workout import WorkoutLog
from app.schemas.workout import WorkoutLogCreate, WorkoutLogInDB
from app.api.deps import get_db, get_current_user

router = APIRouter()

@router.post("/users/{user_id}/workout-logs", response_model=WorkoutLogInDB, status_code=201)
def create_workout_log(
    user_id: int,
    log: WorkoutLogCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    if user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")

    log_data = log.dict()

    workout_log = WorkoutLog(user_id=user_id, **log_data)
    db.add(workout_log)
    db.commit()
    db.refresh(workout_log)
    return workout_log


@router.get("/users/{user_id}/workout-logs", response_model=list[WorkoutLogInDB])
def get_workout_logs(
    user_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    if user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")

    logs = db.query(WorkoutLog).filter(WorkoutLog.user_id == user_id).all()
    return logs
