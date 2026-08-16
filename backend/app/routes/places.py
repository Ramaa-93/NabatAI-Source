from fastapi import APIRouter, HTTPException
import json
from pathlib import Path

router = APIRouter(
    prefix="/places",
    tags=["Places"]
)

DATA_FILE = Path("app/database/places.json")


def load_places():
    with open(DATA_FILE, "r", encoding="utf-8") as file:
        data = json.load(file)

    if isinstance(data, dict):
        if "places" in data:
            return data["places"]
        if "data" in data:
            return data["data"]

    return data


@router.get("/")
def get_all_places():
    return load_places()


@router.get("/city/{city}")
def get_places_by_city(city: str):
    places = load_places()

    result = [
        place for place in places
        if str(place.get("city", "")).lower() == city.lower()
        or str(place.get("governorate", "")).lower() == city.lower()
    ]

    return result


@router.get("/category/{category}")
def get_places_by_category(category: str):
    places = load_places()

    result = [
        place for place in places
        if str(place.get("category", "")).lower() == category.lower()
    ]

    return result


@router.get("/search/{name}")
def search_place(name: str):
    places = load_places()

    result = [
        place for place in places
        if name.lower() in str(place.get("name", "")).lower()
        or name.lower() in str(place.get("arabic_name", "")).lower()
    ]

    return result


@router.get("/{place_id}")
def get_place(place_id: int):
    places = load_places()

    for place in places:
        if int(place.get("id", -1)) == place_id:
            return place

    raise HTTPException(status_code=404, detail="Place not found")