import json
import os
from typing import Any

from dotenv import load_dotenv
from google import genai
from google.genai import types

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

if not GEMINI_API_KEY:
    raise RuntimeError(
        "GEMINI_API_KEY is missing. Add it to the backend/.env file."
    )

client = genai.Client(api_key=GEMINI_API_KEY)

MODEL_NAME = "gemini-2.5-flash"


def _clean_json_text(text: str) -> str:
    cleaned = text.strip()

    if cleaned.startswith("```json"):
        cleaned = cleaned[len("```json"):].strip()
    elif cleaned.startswith("```"):
        cleaned = cleaned[len("```"):].strip()

    if cleaned.endswith("```"):
        cleaned = cleaned[:-3].strip()

    return cleaned


def generate_ai_itinerary(
    user_request: dict[str, Any],
    places: list[dict[str, Any]],
) -> dict[str, Any]:
    short_places = []

    for place in places[:40]:
        short_places.append(
            {
                "id": place.get("id"),
                "name_en": place.get("name_en"),
                "name_ar": place.get("name_ar"),
                "city": place.get("city"),
                "category": place.get("category"),
                "budget_level": place.get("budget_level"),
                "visit_duration_hours": place.get(
                    "visit_duration_hours"
                ),
                "best_visit_time": place.get("best_visit_time"),
                "nearby_places": place.get("nearby_places", []),
            }
        )

    prompt = f"""
You are NabatAI, an AI tourism planner for Jordan.

Create a realistic travel itinerary based on the user's request.

User request:
{json.dumps(user_request, ensure_ascii=False)}

Available places:
{json.dumps(short_places, ensure_ascii=False)}

Rules:
- Return valid JSON only.
- Do not return Markdown.
- Group the itinerary by days.
- Each day should contain 2 to 3 places maximum.
- Consider budget, interests, visit duration, and nearby places.
- Use place IDs from the available places only.
- Add a short reason for each day.

Use this JSON structure:

{{
  "summary": "Short summary of the trip",
  "days": [
    {{
      "day": 1,
      "reason": "Reason for this day's choices",
      "places": [
        {{
          "id": "place id",
          "name": "place name",
          "suggested_time": "morning",
          "duration_hours": 2
        }}
      ]
    }}
  ]
}}
"""

    try:
        response = client.models.generate_content(
            model=MODEL_NAME,
            contents=prompt,
            config=types.GenerateContentConfig(
                temperature=0.4,
                response_mime_type="application/json",
            ),
        )

        text = response.text

        if not text or not text.strip():
            return {
                "error": "Gemini returned an empty response.",
                "fallback_message": (
                    "The AI planner did not return a trip. "
                    "Please try again."
                ),
            }

        cleaned_text = _clean_json_text(text)

        try:
            return json.loads(cleaned_text)
        except json.JSONDecodeError as json_error:
            return {
                "error": f"Invalid JSON returned by Gemini: {json_error}",
                "raw_response": cleaned_text,
                "fallback_message": (
                    "The AI generated a response, but its format was invalid."
                ),
            }

    except Exception as error:
        print(f"Gemini itinerary error: {type(error).__name__}: {error}")

        return {
            "error": f"{type(error).__name__}: {error}",
            "fallback_message": (
                "AI planner is currently unavailable. "
                "Check the API key, quota, model access, or internet connection."
            ),
        }


def answer_tourist_question(
    question: str,
    language: str = "English",
    place: dict[str, Any] | None = None,
) -> str:

    place_context = ""

    if place:
        place_context = f"""
Current place information:
{json.dumps(place, ensure_ascii=False)}
"""
    else:
        place_context = """
No specific place selected.
Answer using your knowledge about Jordan tourism,
history, archaeology and culture.
"""

    if language.lower() == "arabic":
        language_instruction = """
IMPORTANT LANGUAGE RULE:
- Respond ONLY in Arabic.
- Do not use English unless it is absolutely necessary for a proper name.
- Use clear Modern Standard Arabic.
- The entire answer must be written in Arabic.
"""
    else:
        language_instruction = """
IMPORTANT LANGUAGE RULE:
- Respond ONLY in English.
- The entire answer must be written in English.
"""

    prompt = f"""
You are NabatAI, an intelligent AI voice tourism guide specialized in Jordan.

Your job is to answer tourists' questions about:
- Archaeological sites
- Historical places
- Jordanian culture
- Tourism recommendations
- Heritage stories

{place_context}

Tourist question:
{question}

Selected language:
{language}

{language_instruction}

Rules:
- Be friendly like a professional tour guide.
- Give interesting historical details.
- Keep the answer easy for tourists to understand.
- If information is uncertain, mention that.
- Return plain text only.
"""

    try:
        response = client.models.generate_content(
            model=MODEL_NAME,
            contents=prompt,
            config=types.GenerateContentConfig(
                temperature=0.5,
            ),
        )

        if not response.text or not response.text.strip():
            raise ValueError(
                "Gemini returned an empty response."
            )

        return response.text.strip()

    except Exception as error:
        print(
            f"Gemini guide error: {type(error).__name__}: {error}"
        )

        if language.lower() == "arabic":
            return (
                "دليل الذكاء الاصطناعي غير متاح حاليًا. "
                "يرجى المحاولة مرة أخرى لاحقًا."
            )

        return (
            "The AI guide is currently unavailable. "
            "Please try again later."
        )