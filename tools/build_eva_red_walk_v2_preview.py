"""Fill the original 24-frame walk poses with a compact red EVA suit preview.

This is a pose-preserving art study. It intentionally starts from the shipped player
walk sheet so no foot, hand or hip location is regenerated.
"""
import os
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(r"C:\Users\csw83\Documents\Codex\2026-06-27\wo-x\outputs\lunar_base_godot")
SOURCE = ROOT / "assets/characters/player_preview/female/light/black/walk_cycle_long.png"
OUT = ROOT / "user" / os.environ.get("EVA_PREVIEW_DIR", "eva_red_walk_cycle_v2_preview")
OUT.mkdir(parents=True, exist_ok=True)
HELMET_REFERENCE = Path(r"C:\Users\csw83\AppData\Local\Temp\codex-clipboard-0e0c2af6-3c2b-4e7d-94fb-aea9e86e9037.png")

WHITE = (224, 234, 236, 255)
SHADE = (137, 158, 169, 255)
DARK = (30, 42, 51, 255)
VISOR = (19, 29, 38, 255)
RED = (190, 62, 57, 255)
RED_DARK = (126, 43, 43, 255)

src = Image.open(SOURCE).convert("RGBA")
sheet = Image.new("RGBA", src.size, (0, 0, 0, 0))

def load_front_helmet() -> Image.Image:
    """Use the user's selected helmet, not a newly invented geometric substitute."""
    ref = Image.open(HELMET_REFERENCE).convert("RGBA").crop((56, 10, 166, 145))
    px = ref.load()
    for y in range(ref.height):
        for x in range(ref.width):
            r, g, b, a = px[x, y]
            if r > 185 and b > 145 and g < 110:  # supplied magenta background
                px[x, y] = (r, g, b, 0)
    box = ref.getchannel("A").getbbox()
    ref = ref.crop(box)
    return ref.resize((46, 55), Image.Resampling.NEAREST)

FRONT_HELMET = load_front_helmet()

def erase_hair_and_head(frame: Image.Image, row: int) -> None:
    px = frame.load()
    # Erase the original head/hair mass. The lower-body pixels are untouched.
    if row == 0:
        bounds = (31, 8, 97, 62)
    elif row in (1, 2):
        bounds = (31, 8, 96, 77)
    else:
        bounds = (28, 8, 100, 82)
    for y in range(bounds[1], bounds[3] + 1):
        for x in range(bounds[0], bounds[2] + 1):
            r, g, b, a = px[x, y]
            # Remove all head pixels above the collar; below it remove only the
            # dark hair, retaining original white suit pixels and stride geometry.
            if y < 57 or (r < 72 and g < 72 and b < 72):
                px[x, y] = (0, 0, 0, 0)
    # Any exposed skin in the small hand zones becomes a glove.
    for y in range(58, 94):
        for x in list(range(26, 50)) + list(range(79, 103)):
            r, g, b, a = px[x, y]
            if a and r > 150 and 65 < g < 220 and b < 180 and r > b + 35:
                px[x, y] = (170, 187, 193, a)

def draw_front(frame: Image.Image) -> None:
    frame.alpha_composite(FRONT_HELMET, (41, 7))

def draw_side(frame: Image.Image, facing_left: bool) -> None:
    d = ImageDraw.Draw(frame)
    d.polygon([(45, 16), (51, 13), (72, 13), (80, 21), (80, 43), (73, 55), (49, 55), (42, 44), (42, 25)], fill=DARK)
    d.polygon([(47, 17), (53, 15), (71, 15), (78, 22), (78, 42), (71, 52), (50, 52), (45, 42), (45, 26)], fill=WHITE)
    if facing_left:
        d.polygon([(42, 26), (53, 23), (58, 29), (57, 45), (47, 48), (42, 43)], fill=VISOR)
        d.rectangle((45, 51, 74, 56), fill=RED)
        d.rectangle((37, 61, 48, 65), fill=RED)
    else:
        d.polygon([(68, 25), (80, 27), (81, 43), (76, 48), (67, 45), (66, 30)], fill=VISOR)
        d.rectangle((49, 51, 78, 56), fill=RED)
        d.rectangle((79, 61, 90, 65), fill=RED)

def draw_back(frame: Image.Image) -> None:
    d = ImageDraw.Draw(frame)
    d.ellipse((42, 13, 86, 57), fill=DARK)
    d.ellipse((44, 14, 84, 55), fill=WHITE)
    d.line((64, 16, 64, 51), fill=SHADE, width=2)
    d.rectangle((50, 50, 78, 55), fill=RED_DARK)
    d.rectangle((52, 50, 76, 52), fill=RED)
    # Compact backpack, kept within the original wide hair silhouette.
    d.rectangle((48, 57, 80, 75), fill=DARK)
    d.rectangle((51, 58, 77, 73), fill=SHADE)
    d.rectangle((53, 60, 75, 71), fill=WHITE)
    d.rectangle((38, 60, 49, 64), fill=RED)
    d.rectangle((79, 60, 90, 64), fill=RED)

for row in range(4):
    for col in range(6):
        frame = src.crop((col * 128, row * 128, (col + 1) * 128, (row + 1) * 128))
        erase_hair_and_head(frame, row)
        if row == 0:
            draw_front(frame)
        elif row == 1:
            draw_side(frame, facing_left=True)
        elif row == 2:
            draw_side(frame, facing_left=False)
        else:
            draw_back(frame)
        # Red boot/leg trim, only where original opaque pixels already exist.
        px = frame.load()
        for y in range(86, 112):
            for x in range(30, 98):
                r, g, b, a = px[x, y]
                if a and r > 125 and g > 125 and b > 125 and (y in (91, 92) or y in (105, 106)):
                    px[x, y] = RED if y == 91 else RED_DARK
        frame.save(OUT / f"eva_red_walk_v2_{['down','left','right','up'][row]}_{col:02}.png")
        sheet.alpha_composite(frame, (col * 128, row * 128))

sheet.save(OUT / "eva_red_walk_v2_preview_6x4.png")

# Upscaled loop previews: presentation-only, nearest-neighbour to preserve pixels.
for row, direction in enumerate(["down", "left", "right", "up"]):
    frames = [
        Image.open(OUT / f"eva_red_walk_v2_{direction}_{col:02}.png").convert("RGBA").resize(
            (384, 384), Image.Resampling.NEAREST
        )
        for col in range(6)
    ]
    frames[0].save(
        OUT / f"eva_red_walk_v2_{direction}_preview.gif",
        save_all=True,
        append_images=frames[1:],
        duration=125,
        loop=0,
        disposal=2,
        transparency=0,
    )
