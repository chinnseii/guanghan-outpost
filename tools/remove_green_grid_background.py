"""Remove a bright green/grid chroma background while preserving non-green sprite pixels."""
from pathlib import Path
from PIL import Image

ROOT = Path(r"C:\Users\csw83\Documents\Codex\2026-06-27\wo-x\outputs\lunar_base_godot")
folder = ROOT / "user/eva_red_front_walk_frames"
src = Image.open(folder / "eva_red_front_walk_raw_grid.png").convert("RGBA")
px = src.load()

for y in range(src.height):
    for x in range(src.width):
        r, g, b, a = px[x, y]
        # Covers the lime field and its dark-green grid lines. The astronaut has
        # white/gray/red/blue-black pixels only, so this leaves all suit details intact.
        if g > 40 and g > r * 1.12 and g > b * 1.12:
            px[x, y] = (0, 0, 0, 0)

src.save(folder / "eva_red_front_walk_transparent.png")
