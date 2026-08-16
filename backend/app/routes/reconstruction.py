from fastapi import (
    APIRouter,
    File,
    Form,
    HTTPException,
    UploadFile,
)
import json
import shutil
from pathlib import Path
from uuid import uuid4

from app.services.image_generation import (
    generate_reconstruction_image,
)


router = APIRouter(
    prefix="/reconstruction",
    tags=["AI Heritage Reconstruction"],
)


DATA_FILE = Path("app/database/places.json")

ORIGINALS_DIRECTORY = Path(
    "app/static/reconstruction/originals"
)
ORIGINALS_DIRECTORY.mkdir(
    parents=True,
    exist_ok=True,
)

GENERATED_DIRECTORY = Path(
    "app/static/reconstruction/generated"
)
GENERATED_DIRECTORY.mkdir(
    parents=True,
    exist_ok=True,
)


ALLOWED_IMAGE_TYPES = {
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/webp",
}

MAX_IMAGE_SIZE = 10 * 1024 * 1024  # 10 MB


def load_places():
    if not DATA_FILE.exists():
        raise HTTPException(
            status_code=500,
            detail="places.json file was not found",
        )

    with open(
        DATA_FILE,
        "r",
        encoding="utf-8",
    ) as file:
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


def find_place(place_id: int):
    places = load_places()

    for place in places:
        if int(place.get("id", -1)) == place_id:
            return place

    return None


def get_image_extension(image: UploadFile) -> str:
    original_extension = Path(
        image.filename or ""
    ).suffix.lower()

    allowed_extensions = {
        ".jpg",
        ".jpeg",
        ".png",
        ".webp",
    }

    if original_extension in allowed_extensions:
        return original_extension

    extension_by_type = {
        "image/jpeg": ".jpg",
        "image/jpg": ".jpg",
        "image/png": ".png",
        "image/webp": ".webp",
    }

    return extension_by_type.get(
        image.content_type,
        ".jpg",
    )


@router.post("/")
async def generate_heritage_reconstruction(
    place_id: int = Form(...),
    image: UploadFile = File(...),
):
    selected_place = find_place(place_id)

    if selected_place is None:
        raise HTTPException(
            status_code=404,
            detail="Place not found",
        )

    supports_reconstruction = selected_place.get(
        "supports_reconstruction",
        False,
    )

    if supports_reconstruction is False:
        raise HTTPException(
            status_code=400,
            detail=(
                "This place does not currently support "
                "AI heritage reconstruction."
            ),
        )

    if image.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(
            status_code=400,
            detail=(
                "Only JPG, JPEG, PNG, and WEBP "
                "images are allowed."
            ),
        )

    image.file.seek(0, 2)
    image_size = image.file.tell()
    image.file.seek(0)

    if image_size > MAX_IMAGE_SIZE:
        raise HTTPException(
            status_code=400,
            detail="Image size must be less than 10 MB.",
        )

    original_extension = get_image_extension(image)

    original_filename = (
        f"{uuid4().hex}{original_extension}"
    )

    original_path = (
        ORIGINALS_DIRECTORY / original_filename
    )

    try:
        with open(
            original_path,
            "wb",
        ) as output_file:
            shutil.copyfileobj(
                image.file,
                output_file,
            )

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=(
                "Failed to save uploaded image: "
                f"{str(error)}"
            ),
        )

    finally:
        await image.close()

    place_name = (
        selected_place.get("name_en")
        or selected_place.get("name")
        or "Historical Site"
    )

    architectural_style = selected_place.get(
        "architectural_style"
    )

    historical_context = selected_place.get(
        "historical_context"
    )

    ai_reconstruction_prompt = selected_place.get(
        "ai_reconstruction_prompt"
    )

    try:
        generated_path = generate_reconstruction_image(
            original_image_path=original_path,
            place_name=place_name,
            architectural_style=architectural_style,
            historical_context=historical_context,
            original_prompt=ai_reconstruction_prompt,
        )

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=(
                "The original image was uploaded, "
                "but AI reconstruction failed: "
                f"{str(error)}"
            ),
        )

    original_image_url = (
        "/static/reconstruction/originals/"
        f"{original_filename}"
    )

    reconstructed_image_url = (
        "/static/reconstruction/generated/"
        f"{generated_path.name}"
    )

    return {
        "success": True,
        "status": "reconstruction_completed",
        "message": (
            "The AI heritage reconstruction "
            "was generated successfully."
        ),
        "place_id": place_id,
        "place_name": place_name,
        "place_name_ar": selected_place.get(
            "name_ar"
        ),
        "supports_reconstruction": True,
        "original_image_url": original_image_url,
        "reconstructed_image_url": (
            reconstructed_image_url
        ),
        "architectural_style": architectural_style,
        "historical_context": historical_context,
        "ai_reconstruction_prompt": (
            ai_reconstruction_prompt
        ),
        "warning": (
            "This reconstruction is an AI-generated "
            "visual hypothesis based on historical "
            "references, not a confirmed historical fact."
        ),
    }