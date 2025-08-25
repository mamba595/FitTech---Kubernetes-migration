from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.models.users import User
from app.models.onboarding import Onboarding
from app.schemas.onboarding import OnboardingCreate, OnboardingInDB
from app.api.deps import get_db, get_current_user

router = APIRouter()


@router.post("/users/{user_id}/onboarding", response_model=OnboardingInDB, status_code=201)
def create_onboarding(
    user_id: int,
    data: OnboardingCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")

    existing = db.query(Onboarding).filter_by(user_id=user_id).first()
    if existing:
        raise HTTPException(status_code=400, detail="Onboarding already exists")

    data_dict = data.dict()
    data_dict.pop('user_id', None)
    onboarding = Onboarding(user_id=user_id, **data_dict)
    db.add(onboarding)
    db.commit()
    db.refresh(onboarding)

    return onboarding


@router.get("/users/{user_id}/onboarding", response_model=OnboardingInDB)
def get_onboarding(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")

    onboarding = db.query(Onboarding).filter_by(user_id=user_id).first()
    if not onboarding:
        raise HTTPException(status_code=404, detail="Onboarding not found")

    return onboarding


@router.put("/users/{user_id}/onboarding", response_model=OnboardingInDB)
def update_onboarding(
    user_id: int,
    data: OnboardingCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")

    onboarding = db.query(Onboarding).filter_by(user_id=user_id).first()
    if not onboarding:
        raise HTTPException(status_code=404, detail="Onboarding not found")

    for key, value in data.dict().items():
        setattr(onboarding, key, value)

    db.commit()
    db.refresh(onboarding)

    return onboarding
