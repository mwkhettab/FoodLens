from fastapi import FastAPI
from routes.health import router as health_router
from routes.food import router as food_router

app = FastAPI()

app.root_path = "/api/v1"
app.include_router(health_router)
app.include_router(food_router, prefix="/food")
