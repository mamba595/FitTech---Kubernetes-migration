from fastapi import FastAPI
from app.api import api_router
from app.core.database import Base, engine

app = FastAPI()

app.include_router(api_router)

Base.metadata.create_all(engine)