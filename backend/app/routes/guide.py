from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import json
from pathlib import Path
from app.services.gemini_service import answer_tourist_question

router = APIRouter(
    prefix="/guide",
    tags=["Voice Guide"]
)

DATA_FILE = Path("app/database/places.json")


class GuideRequest(BaseModel):
    question: str
    language: str = "English"
    place_id: int | None = None

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
def ask_guide(request: GuideRequest):

    try:

        selected_place = None

        if request.place_id is not None:

            places = load_places()

            for place in places:
                if int(place.get("id", -1)) == request.place_id:
                    selected_place = place
                    break


        answer = answer_tourist_question(
            question=request.question,
            language=request.language,
            place=selected_place,
        )


        return {
            "success": True,
            "question": request.question,
            "answer": answer
        }


    except Exception as e:

        return {
            "success": False,
            "error": str(e)
        }