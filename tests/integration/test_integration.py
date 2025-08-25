import pytest
import requests
import os
import uuid

BASE_URL = os.getenv("API_BASE_URL", "http://localhost:8000")

@pytest.fixture
def test_user():
    email = f"user_{uuid.uuid4()}@test.com"
    payload = {"email": email, "password": "password"}
    resp = requests.post(f"{BASE_URL}/auth/register", json=payload)
    resp_data = resp.json()
    user_id = resp_data.get("id")
    return {"username": email, "password": "password", "id": user_id}

@pytest.fixture
def auth_headers(test_user):
    resp = requests.post(f"{BASE_URL}/auth/token", data={"username": test_user["username"], "password": test_user["password"]})
    token = resp.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}

def test_health():
    resp = requests.get(f"{BASE_URL}/health")
    assert resp.status_code == 200

def test_onboarding_post_and_get(test_user, auth_headers):
    user_id = test_user["id"]
    url = f"{BASE_URL}/users/{user_id}/onboarding"
    data = {
        "user_id": user_id,
        "name": "string",
        "birthdate": "2025-08-21",
        "sex": "string",
        "height": 0,
        "weight": 0,
        "main_goal": "string",
        "weight_target": 0,
        "deadline": "2025-08-21",
        "medical_conditions": "string",
        "sleep_hours": 0,
        "work_schedule": "string",
        "percFat": 0,
        "percMuscle": 0,
        "injuryHist": "string",
        "expLevel": "string",
        "restrictedFoods": "string",
        "timeAvailability": "string",
        "materialAccess": "string"
        }
    resp = requests.post(url, json=data, headers=auth_headers)
    assert resp.status_code == 201

    resp = requests.get(url, headers=auth_headers)
    assert resp.status_code == 200  

def test_foodlogs_post(test_user, auth_headers):
    user_id = test_user["id"]
    url = f"{BASE_URL}/users/{user_id}/food-logs"
    data = {
        "food_name": "string",
        "serving_size": 0,
        "serving_unit": "string",
        "calories": 0,
        "protein": 0,
        "carbs": 0,
        "fats": 0,
        "timestamp": "2025-08-21T13:33:10.012Z"
    }
    resp = requests.post(url, json=data, headers=auth_headers)
    assert resp.status_code == 201

def test_foodlogs_get(test_user, auth_headers):
    user_id = test_user["id"]
    url = f"{BASE_URL}/users/{user_id}/food-logs"
    resp = requests.get(url, headers=auth_headers)
    assert resp.status_code == 200

def test_workoutlogs_post(test_user, auth_headers):
    user_id = test_user["id"]
    url = f"{BASE_URL}/users/{user_id}/workout-logs"
    data = {
        "date": "2025-08-21T13:34:43.735Z",
        "workout_type": "string",
        "duration": 0,
        "total_distance": 0,
        "avg_pace": 0,
        "avg_heart_rate": 0,
        "max_heart_rate": 0,
        "calories_burned": 0,
        "notes": "string"
    }
    resp = requests.post(url, json=data, headers=auth_headers)
    assert resp.status_code == 201

def test_workoutlogs_get(test_user, auth_headers):
    user_id = test_user["id"]
    url = f"{BASE_URL}/users/{user_id}/workout-logs"
    resp = requests.get(url, headers=auth_headers)
    assert resp.status_code == 200