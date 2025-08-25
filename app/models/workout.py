from sqlalchemy import ForeignKey, String, Float, DateTime
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base
from datetime import datetime

class WorkoutLog(Base):
    __tablename__ = 'workout-logs'
    
    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey('users.id'), index=True)
    date: Mapped[datetime] = mapped_column(default=datetime.utcnow())
    workout_type: Mapped[str] = mapped_column(String)
    duration: Mapped[int] = mapped_column()  # seconds
    total_distance: Mapped[float] = mapped_column()
    avg_pace: Mapped[float] = mapped_column()
    avg_heart_rate: Mapped[float] = mapped_column()
    max_heart_rate: Mapped[float] = mapped_column()
    calories_burned: Mapped[int] = mapped_column()
    notes: Mapped[str] = mapped_column(String)