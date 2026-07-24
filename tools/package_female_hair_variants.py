from __future__ import annotations

import json
import zipfile
from pathlib import Path

from PIL import Image


ROOT = Path("user")
ROWS = ("down", "left", "right", "up")
VARIANTS = (
    "female_light_blonde_longhair_walk",
    "female_light_auburn_longhair_walk",
    "female_light_blonde_ponytail_walk",
    "female_light_auburn_ponytail_walk",
    "female_light_blonde_shorthair_walk",
    "female_light_auburn_shorthair_walk",
    "male_medium_blonde_buzzcut_walk",
    "male_medium_auburn_buzzcut_walk",
    "male_medium_black_shortfringe_walk",
    "male_medium_black_wavy_walk",
    "male_medium_black_longhair_walk",
    "male_medium_blonde_shortfringe_walk",
    "male_medium_auburn_shortfringe_walk",
    "male_medium_blonde_longhair_walk",
    "male_medium_auburn_longhair_walk",
)


def package_variant(slug: str) -> None:
    folder = ROOT / slug
    sheet = folder / f"{slug}_4dir_6x4.png"
    image = Image.open(sheet).convert("RGBA")
    if image.width % 6 or image.height % 4:
        raise ValueError(f"{sheet}: not a 6x4 sheet: {image.size}")
    cell_w, cell_h = image.width // 6, image.height // 4
    if cell_w != cell_h:
        raise ValueError(f"{sheet}: expected square cells, got {cell_w}x{cell_h}")

    frames = folder / "frames"
    frames.mkdir(exist_ok=True)
    for row, direction in enumerate(ROWS):
        for column in range(6):
            crop = image.crop((column * cell_w, row * cell_h, (column + 1) * cell_w, (row + 1) * cell_h))
            crop.save(frames / f"{direction}_{column:02}.png")

    appearance_id = slug.removesuffix("_walk")
    manifest = {
        "appearance_id": appearance_id,
        "action": "walk",
        "sprite_sheet": sheet.name,
        "grid": {"columns": 6, "rows": 4, "row_order": list(ROWS)},
        "frame_size": [cell_w, cell_h],
        "frame_count": 24,
        "suggested_fps": 8,
        "loop": True,
        "background": "transparent",
        "pivot": "feet_center",
        "skin_tone_baked": slug.split("_")[1],
    }
    (folder / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (folder / "README.md").write_text(
        f"# {appearance_id}\n\n"
        "- 4 directions × 6 walk frames\n"
        f"- Frame size: {cell_w}×{cell_h}\n"
        "- Row order: down, left, right, up\n"
        "- Recommended playback: 8 FPS, looped\n"
        "- PNG background is transparent; use feet-center origin/pivot.\n"
        "- This source has the light skin tone baked in. Do not use whole-sprite modulate for skin variants.\n",
        encoding="utf-8",
    )
    archive = ROOT / f"{slug}.zip"
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as output:
        for path in sorted(folder.rglob("*")):
            if path.is_file():
                output.write(path, path.relative_to(ROOT))


for variant in VARIANTS:
    package_variant(variant)
