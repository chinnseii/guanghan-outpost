"""Slice the approved 2×2 EVA direction reference into four transparent PNGs."""
from pathlib import Path
from PIL import Image

ROOT = Path(r"C:\Users\csw83\Documents\Codex\2026-06-27\wo-x\outputs\lunar_base_godot")
OUT = ROOT / "user/eva_red_topdown_directions_v1"
source = Image.open(OUT / "eva_red_topdown_2x2.png").convert("RGBA")
half_w, half_h = source.width // 2, source.height // 2
layout = {
    "down": (0, 0),
    "left": (1, 0),
    "right": (0, 1),
    "up": (1, 1),
}

overview = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
for name, (col, row) in layout.items():
    quadrant = source.crop((col * half_w, row * half_h, (col + 1) * half_w, (row + 1) * half_h))
    bbox = quadrant.getchannel("A").getbbox()
    if bbox is None:
        raise RuntimeError(f"Empty {name} quadrant")
    sprite = quadrant.crop(bbox)
    # Preserve source pixel edges and give each direction an equal developer-friendly canvas.
    scale = min(220 / sprite.width, 220 / sprite.height)
    resized = sprite.resize((round(sprite.width * scale), round(sprite.height * scale)), Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    canvas.alpha_composite(resized, ((256 - resized.width) // 2, 236 - resized.height))
    canvas.save(OUT / f"eva_red_topdown_{name}.png")
    overview.alpha_composite(canvas, ((col * 256), (row * 256)))
overview.save(OUT / "eva_red_topdown_4_directions.png")
