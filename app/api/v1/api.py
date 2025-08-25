from fastapi import APIRouter

from app.api.v1.endpoints import users, food, workouts, dashboard, auth, health

api_router = APIRouter()

api_router.include_router(auth.router)
api_router.include_router(users.router)
api_router.include_router(food.router)  
api_router.include_router(workouts.router)
api_router.include_router(dashboard.router)
api_router.include_router(health.router)