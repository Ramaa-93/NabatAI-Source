from datetime import datetime
import json
from pathlib import Path
import re

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from app.services.crowd_prediction_service import predict_crowd


router = APIRouter(
    prefix="/crowd",
    tags=["Crowd Management"],
)


DATA_FILE = (
    Path(__file__).resolve().parent.parent
    / "database"
    / "places.json"
)


class CrowdRequest(BaseModel):
    place_id: int = Field(..., gt=0)
    current_visitors: int = Field(..., ge=0)


def load_places() -> list[dict]:
    if not DATA_FILE.exists():
        raise HTTPException(
            status_code=500,
            detail="Places database file was not found.",
        )

    try:
        with open(DATA_FILE, "r", encoding="utf-8") as file:
            data = json.load(file)

    except json.JSONDecodeError:
        raise HTTPException(
            status_code=500,
            detail="Places database file contains invalid JSON.",
        )

    except OSError:
        raise HTTPException(
            status_code=500,
            detail="Could not read places database file.",
        )

    if isinstance(data, list):
        return [
            item
            for item in data
            if isinstance(item, dict)
        ]

    if isinstance(data, dict):
        if isinstance(data.get("places"), list):
            return [
                item
                for item in data["places"]
                if isinstance(item, dict)
            ]

        all_places: list[dict] = []

        for value in data.values():
            if isinstance(value, list):
                all_places.extend(
                    item
                    for item in value
                    if isinstance(item, dict)
                )

        return all_places

    return []


def find_place(place_id: int) -> dict:
    for place in load_places():
        try:
            current_id = int(place.get("id", -1))
        except (TypeError, ValueError):
            continue

        if current_id == place_id:
            return place

    raise HTTPException(
        status_code=404,
        detail="Place not found.",
    )


def normalize_name(value: str) -> str:
    normalized = value.lower().strip()

    normalized = normalized.replace("&", "and")
    normalized = normalized.replace("theatre", "theater")

    normalized = re.sub(
        r"[^a-z0-9]+",
        " ",
        normalized,
    )

    ignored_words = {
        "archaeological",
        "park",
        "city",
        "site",
        "reserve",
        "jordan",
    }

    words = [
        word
        for word in normalized.split()
        if word not in ignored_words
    ]

    return " ".join(words)


def find_place_by_name(
    place_name: str,
    places: list[dict],
) -> dict | None:
    target = normalize_name(place_name)

    if not target:
        return None

    # تطابق كامل بعد تنظيف الاسم.
    for place in places:
        candidate_names = [
            str(place.get("name_en", "")),
            str(place.get("name", "")),
            str(place.get("slug", "")).replace("-", " "),
        ]

        if any(
            normalize_name(candidate) == target
            for candidate in candidate_names
            if candidate
        ):
            return place

    # تطابق جزئي كخيار احتياطي.
    for place in places:
        candidate_names = [
            str(place.get("name_en", "")),
            str(place.get("name", "")),
            str(place.get("slug", "")).replace("-", " "),
        ]

        for candidate in candidate_names:
            normalized_candidate = normalize_name(candidate)

            if (
                normalized_candidate
                and (
                    target in normalized_candidate
                    or normalized_candidate in target
                )
            ):
                return place

    return None


def get_nearby_names(
    selected_place: dict,
) -> list[str]:
    nearby = (
        selected_place.get("nearby_places")
        or selected_place.get("alternatives")
        or []
    )

    if not isinstance(nearby, list):
        return []

    return [
        str(item)
        for item in nearby
        if item is not None
    ]


def get_lower_crowd_alternatives(
    selected_place: dict,
    current_prediction: dict,
    prediction_time: datetime,
) -> list[str]:
    crowd_level = str(
        current_prediction.get("crowd_level", "")
    ).lower()

    # في حالة Low لا نحتاج اقتراح بدائل.
    if crowd_level not in {"medium", "high"}:
        return []

    try:
        current_percentage = int(
            current_prediction.get(
                "crowd_percentage",
                100,
            )
        )
    except (TypeError, ValueError):
        current_percentage = 100

    all_places = load_places()
    recommendations: list[dict] = []
    used_ids: set[int] = set()

    for nearby_name in get_nearby_names(selected_place):
        nearby_place = find_place_by_name(
            nearby_name,
            all_places,
        )

        if nearby_place is None:
            continue

        try:
            nearby_id = int(nearby_place.get("id"))
        except (TypeError, ValueError):
            continue

        if nearby_id in used_ids:
            continue

        used_ids.add(nearby_id)

        try:
            nearby_prediction = predict_crowd(
                place_id=nearby_id,
                active_users=None,
                prediction_time=prediction_time,
            )
        except Exception:
            # إذا تعذر حساب مكان واحد، لا نفشل الطلب كاملًا.
            continue

        try:
            nearby_percentage = int(
                nearby_prediction.get(
                    "crowd_percentage",
                    100,
                )
            )
        except (TypeError, ValueError):
            continue

        # لا نعرض إلا مكانًا أقل ازدحامًا من المكان الحالي.
        if nearby_percentage >= current_percentage:
            continue

        recommendations.append(
            {
                "id": nearby_id,
                "name": str(
                    nearby_place.get("name_en")
                    or nearby_prediction.get("place_name")
                    or nearby_name
                ),
                "percentage": nearby_percentage,
                "level": str(
                    nearby_prediction.get(
                        "crowd_level",
                        "",
                    )
                ),
            }
        )

    recommendations.sort(
        key=lambda item: (
            item["percentage"],
            item["name"],
        )
    )

    # صيغة نصية متوافقة مع موديل Flutter الحالي.
    return [
        (
            f"{item['name']} — "
            f"{item['percentage']}% "
            f"({item['level']})"
        )
        for item in recommendations[:3]
    ]


def build_prediction_response(
    place_id: int,
    selected_place: dict,
    prediction: dict,
    prediction_time: datetime,
) -> dict:
    suggested_alternatives = (
        get_lower_crowd_alternatives(
            selected_place=selected_place,
            current_prediction=prediction,
            prediction_time=prediction_time,
        )
    )

    # نضعها داخل prediction وخارجه لتبقى متوافقة مع Flutter.
    prediction["suggested_alternatives"] = (
        suggested_alternatives
    )

    return {
        "success": True,
        "place": {
            "id": place_id,
            "name_en": selected_place.get(
                "name_en",
                "",
            ),
            "name_ar": selected_place.get(
                "name_ar",
                "",
            ),
            "city": selected_place.get(
                "city",
                "",
            ),
        },
        "prediction": prediction,
        "suggested_alternatives": (
            suggested_alternatives
        ),
    }


@router.post("/predict")
def predict_place_crowd(
    request: CrowdRequest,
):
    selected_place = find_place(
        request.place_id
    )

    prediction_time = datetime.now()

    try:
        prediction = predict_crowd(
            place_id=request.place_id,
            active_users=request.current_visitors,
            prediction_time=prediction_time,
        )

    except ValueError as error:
        raise HTTPException(
            status_code=404,
            detail=str(error),
        )

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=(
                f"Crowd prediction failed: {error}"
            ),
        )

    return build_prediction_response(
        place_id=request.place_id,
        selected_place=selected_place,
        prediction=prediction,
        prediction_time=prediction_time,
    )


@router.get("/predict/{place_id}")
def get_place_crowd_prediction(
    place_id: int,
):
    selected_place = find_place(
        place_id
    )

    prediction_time = datetime.now()

    try:
        prediction = predict_crowd(
            place_id=place_id,
            active_users=None,
            prediction_time=prediction_time,
        )

    except ValueError as error:
        raise HTTPException(
            status_code=404,
            detail=str(error),
        )

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=(
                f"Crowd prediction failed: {error}"
            ),
        )

    return build_prediction_response(
        place_id=place_id,
        selected_place=selected_place,
        prediction=prediction,
        prediction_time=prediction_time,
    )


@router.get("/health")
def crowd_health():
    return {
        "success": True,
        "status": "ok",
        "service": "smart crowd prediction",
    }