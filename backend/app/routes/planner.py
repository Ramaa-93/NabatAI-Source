from fastapi import APIRouter
from pydantic import BaseModel
import json
from pathlib import Path
from app.services.gemini_service import generate_ai_itinerary

router = APIRouter(prefix="/planner", tags=["Trip Planner"])

DATA_FILE = Path("app/database/places.json")


class PlannerRequest(BaseModel):
    days: int
    budget: str
    interests: list[str]


def load_places():
    with open(DATA_FILE, "r", encoding="utf-8") as file:
        data = json.load(file)

    if isinstance(data, list):
        return data

    if isinstance(data, dict):
        all_places = []
        for value in data.values():
            if isinstance(value, list):
                all_places.extend(value)
        return all_places

    return []


@router.post("/")
def generate_plan(request: PlannerRequest):
    places = load_places()

    user_request = {
        "days": request.days,
        "budget": request.budget,
        "interests": request.interests
    }

    ai_plan = generate_ai_itinerary(user_request, places)

    return {
        "type": "AI Generated Itinerary",
        "request": user_request,
        "plan": ai_plan
    }