import os
from pathlib import Path
from uuid import uuid4

from dotenv import load_dotenv
from google import genai
from PIL import Image


# تحديد مسار مجلد backend
BACKEND_DIRECTORY = Path(__file__).resolve().parents[2]

# قراءة ملف backend/.env
ENV_FILE = BACKEND_DIRECTORY / ".env"
load_dotenv(dotenv_path=ENV_FILE)


GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

if not GEMINI_API_KEY:
    raise RuntimeError(
        f"GEMINI_API_KEY was not found inside: {ENV_FILE}"
    )


client = genai.Client(api_key=GEMINI_API_KEY)


GENERATED_DIRECTORY = Path(
    "app/static/reconstruction/generated"
)

GENERATED_DIRECTORY.mkdir(
    parents=True,
    exist_ok=True,
)


def build_reconstruction_prompt(
    place_name: str,
    architectural_style: str | None,
    historical_context: str | None,
    original_prompt: str | None,
) -> str:
    """
    Build the historical reconstruction prompt.
    """

    return f"""
Edit the provided photograph of {place_name}.

Reconstruct the damaged, collapsed, or missing architectural parts so the
historical site appears as it may plausibly have looked before destruction.

Historical information:
- Place: {place_name}
- Architectural style:
  {architectural_style or "Use a historically plausible architectural style"}
- Historical context:
  {historical_context or "Use historically plausible references"}
- Additional instructions:
  {original_prompt or "Restore only the missing historical architecture"}

Important requirements:
- Preserve the original camera angle.
- Preserve the original perspective and scale.
- Preserve the surrounding landscape.
- Preserve the original lighting direction.
- Preserve the visible stone and material textures.
- Keep all surviving original structures recognizable.
- Restore only damaged, collapsed, or missing historical architecture.
- Produce a realistic photographic result.
- Make the result look like the same photograph before the site was damaged.
- Do not create a painting, illustration, drawing, or fantasy scene.
- Do not add tourists, vehicles, signs, modern buildings, advertisements,
  electrical wires, or unsupported decorative elements.
- Do not transform the place into a different historical site.

The result is an AI-generated visual hypothesis based on historical references,
not a confirmed historical fact.
""".strip()


def generate_reconstruction_image(
    original_image_path: Path,
    place_name: str,
    architectural_style: str | None = None,
    historical_context: str | None = None,
    original_prompt: str | None = None,
) -> Path:
    """
    Send the original image and historical prompt to Gemini,
    save the generated result, and return its path.
    """

    if not original_image_path.exists():
        raise FileNotFoundError(
            f"Original image was not found: {original_image_path}"
        )

    prompt = build_reconstruction_prompt(
        place_name=place_name,
        architectural_style=architectural_style,
        historical_context=historical_context,
        original_prompt=original_prompt,
    )

    try:
        original_image = Image.open(original_image_path)

        response = client.models.generate_content(
            model="gemini-3.1-flash-image",
            contents=[
                prompt,
                original_image,
            ],
        )

        if not response.candidates:
            raise RuntimeError(
                "Gemini returned no candidates."
            )

        candidate = response.candidates[0]

        if (
            candidate.content is None
            or not candidate.content.parts
        ):
            raise RuntimeError(
                "Gemini returned no image content."
            )

        generated_image_bytes = None

        for part in candidate.content.parts:
            if (
                part.inline_data is not None
                and part.inline_data.data is not None
            ):
                generated_image_bytes = part.inline_data.data
                break

        if generated_image_bytes is None:
            raise RuntimeError(
                "Gemini response did not contain a generated image."
            )

        generated_filename = (
            f"{uuid4().hex}_reconstructed.png"
        )

        generated_path = (
            GENERATED_DIRECTORY / generated_filename
        )

        with open(generated_path, "wb") as output_file:
            output_file.write(generated_image_bytes)

        return generated_path

    except Exception as error:
        raise RuntimeError(
            f"Gemini heritage reconstruction failed: {str(error)}"
        ) from error