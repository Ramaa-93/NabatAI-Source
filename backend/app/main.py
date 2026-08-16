from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routes.places import router as places_router
from app.routes.planner import router as planner_router
from app.routes.guide import router as guide_router
from app.routes.crowd import router as crowd_router
from app.routes.reconstruction import router as reconstruction_router

app = FastAPI(
    title="NabatAI API",
    description="AI Tourism Platform for Jordan",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(places_router)
app.include_router(planner_router)
app.include_router(guide_router)
app.include_router(crowd_router)
app.include_router(reconstruction_router)

@app.get("/")
def root():
    return {
        "message": "Welcome to NabatAI API 🚀"
    }