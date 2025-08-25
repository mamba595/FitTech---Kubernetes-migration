from fastapi import APIRouter, Depends, HTTPException
from datetime import datetime, timedelta
from sqlalchemy.orm import Session

from app.models.onboarding import Onboarding
from app.models.food import FoodLog
from app.models.workout import WorkoutLog

from app.schemas.onboarding import OnboardingInDB
from app.schemas.food import FoodLogInDB
from app.schemas.workout import WorkoutLogInDB

from app.api.deps import get_db, get_current_user
from app.services.calculations import calculate_bmr, calculate_tdee, calculate_macros

router = APIRouter()

@router.get("/dashboard")
def get_dashboard(db: Session = Depends(get_db), current_user = Depends(get_current_user)):
    user_id = current_user.id

    onboarding_db = db.query(Onboarding).filter(Onboarding.user_id == user_id).first()
    if not onboarding_db:
        raise HTTPException(status_code=404, detail="Onboarding data not found")

    try:
        onboarding = OnboardingInDB.from_orm(onboarding_db)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid onboarding format: {e}")

    try:
        bmr = calculate_bmr(onboarding)
        tdee = calculate_tdee(onboarding)
        macros = calculate_macros(onboarding)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

    now = datetime.utcnow()
    start_of_day = datetime(now.year, now.month, now.day)
    end_of_day = start_of_day + timedelta(days=1)

    food_logs_db = (
        db.query(FoodLog)
        .filter(
            FoodLog.user_id == user_id,
            FoodLog.timestamp >= start_of_day,
            FoodLog.timestamp < end_of_day
        )
        .all()
    )

    total_calories = sum(log.calories or 0 for log in food_logs_db)
    total_protein = sum(log.protein or 0 for log in food_logs_db)
    total_carbs = sum(log.carbs or 0 for log in food_logs_db)
    total_fat = sum(log.fats or 0 for log in food_logs_db)

    food_logs = [FoodLogInDB.from_orm(log) for log in food_logs_db]

    workouts_db = (
        db.query(WorkoutLog)
        .filter(
            WorkoutLog.user_id == user_id,
            WorkoutLog.timestamp >= start_of_day,
            WorkoutLog.timestamp < end_of_day
        )
        .all()
    )

    workouts = [WorkoutLogInDB.from_orm(log) for log in workouts_db]

    return {
        "goals": {
            "bmr": bmr,
            "tdee": tdee,
            "macros": macros,
        },
        "intake_today": {
            "calories": total_calories,
            "protein": total_protein,
            "carbs": total_carbs,
            "fat": total_fat,
        },
        "food_logs": [log.model_dump() for log in food_logs],
        "workouts_today": [log.model_dump() for log in workouts],
    }