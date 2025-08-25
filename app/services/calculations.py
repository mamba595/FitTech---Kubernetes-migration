from datetime import date, datetime
from app.schemas.onboarding import OnboardingInDB

def calculate_age(birthdate: date) -> int:
    today = date.today()
    return today.year - birthdate.year - ((today.month, today.day) < (birthdate.month, birthdate.day))

def calculate_bmr(onboarding: OnboardingInDB) -> float:
    if onboarding.weight is None or onboarding.height is None or onboarding.birthdate is None or onboarding.sex is None:
        raise ValueError("Missing required biometric data")

    weight = onboarding.weight
    height = onboarding.height

    if isinstance(onboarding.birthdate, str):
        birthdate = datetime.strptime(onboarding.birthdate, '%Y-%m-%d').date()
    else:
        birthdate = onboarding.birthdate

    age = calculate_age(birthdate)
    sex = onboarding.sex.lower()

    if sex == "male":
        bmr = 10 * weight + 6.25 * height - 5 * age + 5
    elif sex == "female":
        bmr = 10 * weight + 6.25 * height - 5 * age - 161
    else:
        raise ValueError("Sex must be 'male' or 'female'")

    return round(bmr, 2)

def calculate_tdee(onboarding: OnboardingInDB) -> float:
    if onboarding.work_schedule is None:
        raise ValueError("Missing work_schedule (activity level)")

    activity_map = {
        "sedentary": 1.2,
        "light": 1.375,
        "moderate": 1.55,
        "active": 1.725,
        "very_active": 1.9
    }

    level = onboarding.work_schedule.lower()
    factor = activity_map.get(level)
    if not factor:
        raise ValueError(f"Invalid activity level: {level}")

    bmr = calculate_bmr(onboarding)
    return round(bmr * factor, 2)

def calculate_macros(onboarding: OnboardingInDB) -> dict:
    if onboarding.main_goal is None:
        raise ValueError("Missing main_goal")

    tdee = calculate_tdee(onboarding)
    goal = onboarding.main_goal.lower()

    ratio_map = {
        "maintain": {"protein": 0.3, "carbs": 0.4, "fats": 0.3},
        "lose": {"protein": 0.4, "carbs": 0.3, "fats": 0.3},
        "gain": {"protein": 0.3, "carbs": 0.5, "fats": 0.2},
    }

    ratios = ratio_map.get(goal)
    if not ratios:
        raise ValueError(f"Invalid goal: {goal}")

    return {
        "protein_g": round(tdee * ratios["protein"] / 4),
        "carbs_g": round(tdee * ratios["carbs"] / 4),
        "fats_g": round(tdee * ratios["fats"] / 9),
        "tdee": round(tdee),
        "goal": goal
    }
