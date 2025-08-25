from fastapi import APIRouter, Depends, HTTPException, status, Form
from sqlalchemy.orm import Session

from app.models.users import User  
from app.schemas.user import UserCreate, UserInDB, UserPublic
from app.api.deps import get_db, hash_password, verify_password, create_access_token

router = APIRouter()

@router.post("/auth/register", response_model=UserPublic, status_code=status.HTTP_201_CREATED)
def register_user(user: UserCreate, db: Session = Depends(get_db)):
    existing = db.query(User).filter(User.email == user.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    hashed = hash_password(user.password)
    user_in_db = User(email=user.email, hashed_password=hashed)

    db.add(user_in_db)
    db.commit()
    db.refresh(user_in_db)

    return UserPublic(id=user_in_db.id, email=user_in_db.email)

@router.post("/auth/token")
def login(username: str = Form(...), password: str = Form(...), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == username).first()
    if not user or not verify_password(password, user.hashed_password):
        raise HTTPException(status_code=400, detail="Incorrect email or password")

    access_token = create_access_token(data={"sub": user.email})
    return {"access_token": access_token, "token_type": "bearer"}
