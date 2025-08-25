from sqlalchemy import String, Integer, ForeignKey, Date, Float
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base

class Onboarding(Base):
    __tablename__ = 'onboarding'

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey('users.id'), index=True)
    name: Mapped[str] = mapped_column(String, nullable=True)
    birthdate: Mapped[Date] = mapped_column(Date, nullable=True)
    sex: Mapped[str] = mapped_column(String, nullable=True)
    height: Mapped[int] = mapped_column(Integer, nullable=True)
    weight: Mapped[int] = mapped_column(Integer, nullable=True)
    main_goal: Mapped[str] = mapped_column(String, nullable=True)
    weight_target: Mapped[int] = mapped_column(Integer, nullable=True)
    deadline: Mapped[Date] = mapped_column(Date, nullable=True)
    medical_conditions: Mapped[str] = mapped_column(String, nullable=True)
    sleep_hours: Mapped[float] = mapped_column(Float, nullable=True)
    work_schedule: Mapped[str] = mapped_column(String, nullable=True)
    percFat: Mapped[float] = mapped_column(Float, nullable=True)
    percMuscle: Mapped[float] = mapped_column(Float, nullable=True)
    injuryHist: Mapped[str] = mapped_column(String, nullable=True)
    expLevel: Mapped[str] = mapped_column(String, nullable=True)
    restrictedFoods: Mapped[str] = mapped_column(String, nullable=True)
    timeAvailability: Mapped[str] = mapped_column(String, nullable=True)
    materialAccess: Mapped[str] = mapped_column(String, nullable=True)
