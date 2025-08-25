from sqlalchemy import String, Integer, ForeignKey, DateTime
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base

class FoodLog(Base):
    __tablename__ = 'food_logs'  # Use underscores instead of dashes

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey('users.id'), index=True)
    food_name: Mapped[str] = mapped_column(String)
    serving_size: Mapped[int] = mapped_column(Integer)
    serving_unit: Mapped[str] = mapped_column(String)
    calories: Mapped[int] = mapped_column(Integer)
    protein: Mapped[int] = mapped_column(Integer)
    carbs: Mapped[int] = mapped_column(Integer)
    fats: Mapped[int] = mapped_column(Integer)
    timestamp: Mapped[DateTime] = mapped_column(DateTime)
