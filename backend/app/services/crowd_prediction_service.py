from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any
from urllib.parse import urlencode
from urllib.request import urlopen
import json
import random


JORDAN_TIMEZONE = timezone(timedelta(hours=3))

DATA_FILE = (
    Path(__file__).resolve().parent.parent
    / "database"
    / "places.json"
)


WEATHER_CODES: dict[int, str] = {
    0: "Clear",
    1: "Mainly clear",
    2: "Partly cloudy",
    3: "Cloudy",
    45: "Foggy",
    48: "Foggy",
    51: "Light drizzle",
    53: "Drizzle",
    55: "Heavy drizzle",
    61: "Light rain",
    63: "Rain",
    65: "Heavy rain",
    71: "Light snow",
    73: "Snow",
    75: "Heavy snow",
    80: "Rain showers",
    81: "Rain showers",
    82: "Heavy rain showers",
    95: "Thunderstorm",
    96: "Thunderstorm",
    99: "Thunderstorm",
}


def clamp(value: int, minimum: int, maximum: int) -> int:
    return max(minimum, min(value, maximum))


def load_places() -> list[dict[str, Any]]:
    if not DATA_FILE.exists():
        raise ValueError("Places database file was not found.")

    try:
        with open(DATA_FILE, "r", encoding="utf-8") as file:
            data = json.load(file)
    except json.JSONDecodeError as error:
        raise ValueError(
            f"Places database contains invalid JSON: {error}"
        ) from error
    except OSError as error:
        raise ValueError(
            f"Could not read places database: {error}"
        ) from error

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

        all_places: list[dict[str, Any]] = []

        for value in data.values():
            if isinstance(value, list):
                all_places.extend(
                    item
                    for item in value
                    if isinstance(item, dict)
                )

        return all_places

    return []


def find_place(place_id: int) -> dict[str, Any]:
    for place in load_places():
        try:
            current_id = int(place.get("id", -1))
        except (TypeError, ValueError):
            continue

        if current_id == place_id:
            return place

    raise ValueError(
        f"Place with id {place_id} was not found."
    )


def normalize_place(
    raw_place: dict[str, Any],
) -> dict[str, Any]:
    name = (
        raw_place.get("name_en")
        or raw_place.get("name")
        or "Unknown place"
    )

    city = (
        raw_place.get("city")
        or raw_place.get("governorate")
        or "Jordan"
    )

    latitude = raw_place.get("latitude")
    longitude = raw_place.get("longitude")

    if latitude is None or longitude is None:
        raise ValueError(
            f"Coordinates are missing for {name}."
        )

    category = str(
        raw_place.get("category", "")
    ).lower()

    subcategory = str(
        raw_place.get("subcategory", "")
    ).lower()

    place_type = "outdoor"

    if any(
        keyword in category or keyword in subcategory
        for keyword in (
            "museum",
            "indoor",
            "cultural center",
            "gallery",
        )
    ):
        place_type = "indoor"
    elif any(
        keyword in category or keyword in subcategory
        for keyword in (
            "castle",
            "palace",
            "heritage",
            "religious",
        )
    ):
        place_type = "mixed"

    default_level = str(
        raw_place.get(
            "crowd_level_default",
            "Medium",
        )
    ).lower()

    base_crowd = {
        "low": 35,
        "medium": 55,
        "high": 75,
    }.get(default_level, 50)

    capacity = raw_place.get(
        "crowd_capacity_estimate",
        3000,
    )

    try:
        estimated_capacity = max(
            1,
            int(capacity),
        )
    except (TypeError, ValueError):
        estimated_capacity = 3000

    alternatives = (
        raw_place.get("nearby_places")
        or raw_place.get("alternatives")
        or []
    )

    if not isinstance(alternatives, list):
        alternatives = []

    return {
        "id": int(raw_place["id"]),
        "name": str(name),
        "name_ar": str(
            raw_place.get("name_ar", "")
        ),
        "city": str(city),
        "latitude": float(latitude),
        "longitude": float(longitude),
        "type": place_type,
        "base_crowd": base_crowd,
        "estimated_capacity": estimated_capacity,
        "alternatives": [
            str(item)
            for item in alternatives
        ],
        "best_visit_time": str(
            raw_place.get(
                "best_visit_time",
                "Early morning",
            )
        ),
    }


def fetch_current_weather(
    latitude: float,
    longitude: float,
) -> dict[str, Any]:
    params = {
        "latitude": latitude,
        "longitude": longitude,
        "current": (
            "temperature_2m,"
            "apparent_temperature,"
            "precipitation,"
            "weather_code,"
            "wind_speed_10m"
        ),
        "timezone": "Asia/Amman",
        "forecast_days": 1,
    }

    url = (
        "https://api.open-meteo.com/v1/forecast?"
        + urlencode(params)
    )

    try:
        with urlopen(url, timeout=6) as response:
            data = json.loads(
                response.read().decode("utf-8")
            )

        current = data.get("current", {})

        temperature = float(
            current.get("temperature_2m", 25)
        )
        apparent_temperature = float(
            current.get(
                "apparent_temperature",
                temperature,
            )
        )
        precipitation = float(
            current.get("precipitation", 0)
        )
        wind_speed = float(
            current.get("wind_speed_10m", 0)
        )
        weather_code = int(
            current.get("weather_code", 0)
        )

        return {
            "temperature": round(temperature, 1),
            "apparent_temperature": round(
                apparent_temperature,
                1,
            ),
            "precipitation": round(
                precipitation,
                1,
            ),
            "wind_speed": round(
                wind_speed,
                1,
            ),
            "weather": WEATHER_CODES.get(
                weather_code,
                "Unknown",
            ),
            "weather_code": weather_code,
            "weather_source": "Open-Meteo",
        }

    except Exception:
        jordan_now = datetime.now(
            JORDAN_TIMEZONE
        )

        month = jordan_now.month
        hour = jordan_now.hour

        if month in (12, 1, 2):
            fallback_temperature = 14
        elif month in (3, 4, 5):
            fallback_temperature = 23
        elif month in (6, 7, 8):
            fallback_temperature = 32
        else:
            fallback_temperature = 25

        if hour < 7:
            fallback_temperature -= 5
        elif hour >= 20:
            fallback_temperature -= 4
        elif 12 <= hour <= 15:
            fallback_temperature += 2

        return {
            "temperature": float(
                fallback_temperature
            ),
            "apparent_temperature": float(
                fallback_temperature
            ),
            "precipitation": 0.0,
            "wind_speed": 8.0,
            "weather": "Clear",
            "weather_code": 0,
            "weather_source": (
                "Fallback estimation"
            ),
        }


def normalize_prediction_time(
    prediction_time: datetime | None,
) -> datetime:
    if prediction_time is None:
        return datetime.now(
            JORDAN_TIMEZONE
        )

    if prediction_time.tzinfo is None:
        return prediction_time.replace(
            tzinfo=JORDAN_TIMEZONE
        )

    return prediction_time.astimezone(
        JORDAN_TIMEZONE
    )


def calculate_crowd_prediction(
    place: dict[str, Any],
    weather: dict[str, Any],
    now: datetime,
    active_users: int | None,
) -> dict[str, Any]:
    crowd_score = int(place["base_crowd"])
    reasons: list[str] = []

    hour = now.hour
    weekday = now.weekday()

    temperature = float(weather["temperature"])
    apparent_temperature = float(
        weather["apparent_temperature"]
    )
    precipitation = float(
        weather["precipitation"]
    )
    wind_speed = float(weather["wind_speed"])
    weather_code = int(weather["weather_code"])
    place_type = str(place["type"]).lower()

    if 5 <= hour < 8:
        crowd_score -= 18
        reasons.append(
            "Early morning usually has fewer visitors."
        )
    elif 8 <= hour < 11:
        crowd_score += 12
        reasons.append(
            "Morning is a popular visiting time."
        )
    elif 11 <= hour < 14:
        crowd_score += 18
        reasons.append(
            "This is one of the main visiting hours."
        )
    elif 14 <= hour < 17:
        crowd_score += 8
        reasons.append(
            "Afternoon visitor activity is moderate."
        )
    elif 17 <= hour < 20:
        crowd_score += 15
        reasons.append(
            "Sunset hours can attract more visitors."
        )
    else:
        crowd_score -= 25
        reasons.append(
            "Visitor numbers are usually lower at this hour."
        )

    is_weekend = weekday in (4, 5)

    if is_weekend:
        crowd_score += 17
        reasons.append(
            "Weekend demand increases visitor numbers."
        )
    else:
        crowd_score -= 3
        reasons.append(
            "Weekday demand is usually lower."
        )

    if place_type == "outdoor":
        if temperature >= 40:
            crowd_score -= 30
            reasons.append(
                "Extreme heat strongly reduces outdoor visits."
            )
        elif temperature >= 35:
            crowd_score -= 20
            reasons.append(
                "Hot weather reduces outdoor activity."
            )
        elif temperature >= 31:
            crowd_score -= 10
            reasons.append(
                "High temperature slightly reduces visits."
            )
        elif 18 <= temperature <= 28:
            crowd_score += 16
            reasons.append(
                "Comfortable temperature encourages visits."
            )
        elif temperature <= 8:
            crowd_score -= 15
            reasons.append(
                "Cold weather reduces outdoor visits."
            )
    elif place_type == "mixed":
        if temperature >= 36:
            crowd_score -= 8
            reasons.append(
                "Hot weather slightly reduces visits."
            )
        elif 17 <= temperature <= 29:
            crowd_score += 8
            reasons.append(
                "The temperature is suitable for visiting."
            )

    rainy_codes = {
        51, 53, 55,
        61, 63, 65,
        80, 81, 82,
    }

    storm_codes = {95, 96, 99}

    if weather_code in storm_codes:
        crowd_score -= 35
        reasons.append(
            "Thunderstorms strongly reduce visitor activity."
        )
    elif (
        weather_code in rainy_codes
        or precipitation > 0
    ):
        if place_type == "outdoor":
            crowd_score -= 25
            reasons.append(
                "Rain reduces visits to outdoor attractions."
            )
        else:
            crowd_score -= 8
            reasons.append(
                "Rain slightly reduces visitor activity."
            )
    elif weather_code in (0, 1):
        crowd_score += 7
        reasons.append(
            "Clear weather encourages tourism activity."
        )
    elif weather_code in (2, 3):
        crowd_score += 3
        reasons.append(
            "Cloudy weather remains suitable for visiting."
        )

    if (
        wind_speed >= 45
        and place_type == "outdoor"
    ):
        crowd_score -= 18
        reasons.append(
            "Strong winds reduce outdoor visitor activity."
        )
    elif (
        wind_speed >= 30
        and place_type == "outdoor"
    ):
        crowd_score -= 8
        reasons.append(
            "Windy weather may reduce outdoor visits."
        )

    if active_users is not None:
        active_users = max(0, int(active_users))

        estimated_capacity = int(
            place["estimated_capacity"]
        )

        occupancy_percentage = (
            active_users
            / estimated_capacity
        ) * 100

        if occupancy_percentage >= 85:
            crowd_score += 35
            reasons.append(
                "The reported number of visitors is near full capacity."
            )
        elif occupancy_percentage >= 65:
            crowd_score += 25
            reasons.append(
                "The reported number of visitors is high."
            )
        elif occupancy_percentage >= 40:
            crowd_score += 12
            reasons.append(
                "The reported number of visitors is moderate."
            )
        elif occupancy_percentage <= 15:
            crowd_score -= 8
            reasons.append(
                "The reported number of visitors is low."
            )
    else:
        occupancy_percentage = None

    variation_seed = (
        str(place["id"])
        + str(place["name"])
        + now.strftime("%Y-%m-%d-%H")
    )

    random_generator = random.Random(
        variation_seed
    )

    crowd_score += random_generator.randint(
        -4,
        4,
    )

    crowd_percentage = clamp(
        round(crowd_score),
        5,
        98,
    )

    if crowd_percentage < 35:
        crowd_level = "Low"
        crowd_level_ar = "منخفض"
        message = (
            f"{place['name']} is currently expected "
            "to be quiet. This is a good time to visit."
        )
        message_ar = (
            f"من المتوقع أن تكون الزحمة في "
            f"{place['name_ar'] or place['name']} "
            "منخفضة حاليًا، وهذا وقت مناسب للزيارة."
        )
    elif crowd_percentage < 70:
        crowd_level = "Medium"
        crowd_level_ar = "متوسط"
        message = (
            f"{place['name']} currently has moderate "
            "visitor activity. Some busy areas may be expected."
        )
        message_ar = (
            f"مستوى الزحمة في "
            f"{place['name_ar'] or place['name']} "
            "متوسط حاليًا، وقد تكون بعض المناطق مزدحمة قليلًا."
        )
    else:
        crowd_level = "High"
        crowd_level_ar = "مرتفع"
        message = (
            f"{place['name']} is expected to be crowded. "
            "Consider visiting at another time."
        )
        message_ar = (
            f"من المتوقع أن تكون الزحمة في "
            f"{place['name_ar'] or place['name']} "
            "مرتفعة، ويُفضل الزيارة في وقت آخر."
        )

    suggested_alternatives: list[str] = []

    if crowd_level == "High":
        suggested_alternatives = list(
            place["alternatives"]
        )

    return {
        "place_id": place["id"],
        "place_name": place["name"],
        "city": place["city"],
        "crowd_percentage": crowd_percentage,
        "crowd_level": crowd_level,
        "crowd_level_ar": crowd_level_ar,
        "message": message,
        "message_ar": message_ar,
        "active_users": active_users,
        "estimated_capacity": place[
            "estimated_capacity"
        ],
        "occupancy_percentage": (
            round(occupancy_percentage, 1)
            if occupancy_percentage is not None
            else None
        ),
        "temperature": temperature,
        "apparent_temperature": (
            apparent_temperature
        ),
        "weather": weather["weather"],
        "precipitation": precipitation,
        "wind_speed": wind_speed,
        "visit_hour": now.strftime(
            "%I:%M %p"
        ),
        "day_name": now.strftime("%A"),
        "is_weekend": is_weekend,
        "weather_source": weather[
            "weather_source"
        ],
        "prediction_reasons": reasons,
        "suggested_alternatives": (
            suggested_alternatives
        ),
        "best_visit_time": place[
            "best_visit_time"
        ],
        "last_updated": now.isoformat(),
    }


def predict_crowd(
    place_id: int,
    active_users: int | None = None,
    prediction_time: datetime | None = None,
) -> dict[str, Any]:
    raw_place = find_place(place_id)
    place = normalize_place(raw_place)

    now = normalize_prediction_time(
        prediction_time
    )

    weather = fetch_current_weather(
        latitude=float(place["latitude"]),
        longitude=float(place["longitude"]),
    )

    return calculate_crowd_prediction(
        place=place,
        weather=weather,
        now=now,
        active_users=active_users,
    )