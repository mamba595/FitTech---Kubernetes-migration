from datetime import date
import pytest
from app.services.calculations import calculate_age, calculate_bmr, calculate_tdee, calculate_macros
from app.schemas.onboarding import OnboardingInDB

def test_calculate_age():
    birthdate = date(2000, 8, 21)
    age = calculate_age(birthdate)
    today = date.today()
    expected_age = today.year - 2000 - ((today.month, today.day) < (8, 21))
    assert age == expected_age

def test_calculate_bmr_male():
    user = OnboardingInDB(
        id=1,
        user_id=1,
        weight=70, 
        height=175, 
        birthdate=date(1990, 1, 1), 
        sex="male",
        work_schedule="moderate", 
        main_goal="maintain"
    )
    bmr = calculate_bmr(user)
    assert isinstance(bmr, float)

def test_calculate_bmr_female():
    user = OnboardingInDB(
        id=1,
        user_id=1,
        weight=60, 
        height=165, 
        birthdate=date(1990, 1, 1), 
        sex="female",
        work_schedule="moderate", 
        main_goal="maintain"
    )
    bmr = calculate_bmr(user)
    assert isinstance(bmr, float)

def test_calculate_tdee_normal():
    user = OnboardingInDB(
        id=1,
        user_id=1,
        weight=70, 
        height=175, 
        birthdate=date(1990,1,1),
        sex="male", 
        work_schedule="moderate", 
        main_goal="maintain"
    )
    tdee = calculate_tdee(user)
    assert tdee > 0

def test_calculate_macros_normal():
    user = OnboardingInDB(
        id=1,
        user_id=1,
        weight=70, 
        height=175, 
        birthdate=date(1990,1,1),
        sex="male", 
        work_schedule="moderate", 
        main_goal="gain")
    macros = calculate_macros(user)
    assert macros["goal"] == "gain"
    assert macros["protein_g"] > 0