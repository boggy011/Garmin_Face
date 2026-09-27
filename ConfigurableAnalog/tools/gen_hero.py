# /// script
# requires-python = ">=3.12"
# dependencies = ["pillow>=10"]
# ///
"""Compose the Connect IQ store hero image (1440x720) from the listing screenshots.

Three native resolution screenshots are masked to circles, given a thin rim and
placed on a dark banner with the app name and tagline. Run from the project folder:

    uv run tools/gen_hero.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
LISTING = ROOT / "release" / "listing"
FONTS = ROOT / "assets" / "fonts"
OUTPUT = LISTING / "hero-1440x720.png"

WIDTH = 1440
HEIGHT = 720
SUPERSAMPLE = 4
RIM_COLOR = (70, 70, 70)
RIM_WIDTH = 3
TITLE_COLOR = (240, 240, 240)
TAGLINE_COLOR = (170, 170, 170)
TITLE = "ConfigurableAnalog"
TAGLINE = (
    "Analog face with weather, health and calendar pages, three skins, live weather"
)

# (file, diameter, centre x, centre y)
FACES: tuple[tuple[str, int, int, int], ...] = (
    ("fenix847mm-generic.png", 380, 260, 430),
    ("fenix847mm-weather.png", 500, 720, 430),
    ("fenix847mm-health.png", 380, 1180, 430),
)


def background() -> Image.Image:
    """Return the banner background: a vertical dark gradient with a soft centre glow."""
    canvas = Image.new("RGB", (WIDTH, HEIGHT), (8, 8, 8))
    draw = ImageDraw.Draw(canvas)
    for y in range(HEIGHT):
        level = 22 - int(16 * y / HEIGHT)
        draw.line([(0, y), (WIDTH, y)], fill=(level, level, level))
    glow = Image.new("L", (WIDTH, HEIGHT), 0)
    glow_draw = ImageDraw.Draw(glow)
    for radius in range(520, 0, -8):
        alpha = int(26 * (1 - radius / 520))
        glow_draw.ellipse(
            [WIDTH // 2 - radius, 430 - radius, WIDTH // 2 + radius, 430 + radius],
            fill=alpha,
        )
    return Image.composite(
        Image.new("RGB", (WIDTH, HEIGHT), (48, 48, 52)), canvas, glow
    )


def round_face(path: Path, diameter: int) -> Image.Image:
    """Return the screenshot scaled to the diameter, masked to a circle, with a rim."""
    size = diameter * SUPERSAMPLE
    face = (
        Image.open(path).convert("RGB").resize((size, size), Image.Resampling.LANCZOS)
    )
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, size - 1, size - 1], fill=255)
    rim = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    rim_draw = ImageDraw.Draw(rim)
    rim_draw.ellipse(
        [0, 0, size - 1, size - 1],
        outline=(*RIM_COLOR, 255),
        width=RIM_WIDTH * SUPERSAMPLE,
    )
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    layer.paste(face, (0, 0), mask)
    layer.alpha_composite(rim)
    return layer.resize((diameter, diameter), Image.Resampling.LANCZOS)


def draw_text(canvas: Image.Image) -> None:
    """Draw the app name and tagline centred in the top band."""
    draw = ImageDraw.Draw(canvas)
    title_font = ImageFont.truetype(str(FONTS / "Montserrat-SemiBold.ttf"), 54)
    tagline_font = ImageFont.truetype(str(FONTS / "Rajdhani-SemiBold.ttf"), 30)
    draw.text((WIDTH // 2, 62), TITLE, font=title_font, fill=TITLE_COLOR, anchor="mm")
    draw.text(
        (WIDTH // 2, 118), TAGLINE, font=tagline_font, fill=TAGLINE_COLOR, anchor="mm"
    )


def main() -> int:
    """Compose and write the hero image."""
    canvas = background().convert("RGBA")
    for name, diameter, cx, cy in FACES:
        face = round_face(LISTING / name, diameter)
        canvas.alpha_composite(face, (cx - diameter // 2, cy - diameter // 2))
    draw_text(canvas)
    canvas.convert("RGB").save(OUTPUT, optimize=True)
    print(f"wrote {OUTPUT.relative_to(ROOT)} {canvas.size[0]}x{canvas.size[1]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
