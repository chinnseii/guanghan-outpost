from __future__ import annotations

"""Build RGB skin masks from the approved black-hair character bases.

The generated mask uses R=skin shadow, G=skin midtone, B=skin highlight.
Only skin pixels retain alpha; all hair, suits, packs, and background are transparent.
"""

import colorsys
import json
from pathlib import Path

from PIL import Image


ROOT = Path("user")
OUT = ROOT / "skin_masks"
SOURCES = {
    "female_longhair_skin_mask.png": ROOT / "female_light_black_longhair_walk_4dir" / "female_light_black_longhair_walk_4dir_6x4.png",
    "female_ponytail_skin_mask.png": ROOT / "female_light_black_ponytail_walk" / "female_light_black_ponytail_walk_4dir_6x4.png",
    "female_shorthair_skin_mask.png": ROOT / "female_light_black_shorthair_walk" / "female_light_black_shorthair_walk_4dir_6x4.png",
    "male_buzzcut_skin_mask.png": ROOT / "male_medium_black_buzzcut_walk" / "male_medium_black_buzzcut_walk_4dir_6x4.png",
    "male_shortfringe_skin_mask.png": ROOT / "male_medium_black_shortfringe_walk" / "male_medium_black_shortfringe_walk_4dir_6x4.png",
    "male_longhair_skin_mask.png": ROOT / "male_medium_black_longhair_walk" / "male_medium_black_longhair_walk_4dir_6x4.png",
}


def is_skin(red: int, green: int, blue: int, alpha: int) -> bool:
    if alpha < 16:
        return False
    hue, saturation, value = colorsys.rgb_to_hsv(red / 255, green / 255, blue / 255)
    # Peach-to-brown pixel clusters used by the approved face/hand art.
    # The threshold intentionally rejects low-saturation suit whites and dark hair.
    return 0.025 <= hue <= 0.135 and saturation >= 0.23 and value >= 0.40


def mask_for(source: Path, destination: Path) -> dict:
    image = Image.open(source).convert("RGBA")
    pixels = image.load()
    result = Image.new("RGBA", image.size, (0, 0, 0, 0))
    mask = result.load()
    counts = {"shadow": 0, "midtone": 0, "highlight": 0}
    for y in range(image.height):
        for x in range(image.width):
            red, green, blue, alpha = pixels[x, y]
            if not is_skin(red, green, blue, alpha):
                continue
            _, _, value = colorsys.rgb_to_hsv(red / 255, green / 255, blue / 255)
            if value < 0.65:
                mask[x, y] = (255, 0, 0, 255)
                counts["shadow"] += 1
            elif value < 0.86:
                mask[x, y] = (0, 255, 0, 255)
                counts["midtone"] += 1
            else:
                mask[x, y] = (0, 0, 255, 255)
                counts["highlight"] += 1
    result.save(destination)
    return {"source": str(source), "size": list(image.size), "pixels": counts}


OUT.mkdir(exist_ok=True)
report = {name: mask_for(source, OUT / name) for name, source in SOURCES.items()}
(OUT / "mask_generation_report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
