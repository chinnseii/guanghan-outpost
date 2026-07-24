"""Create non-destructive pose guides from the approved player walk sheet.

The guides deliberately retain the original frame alpha silhouette and only colour-code
the approximate construction regions. They are for redrawing the EVA suit inside the
existing animation envelope; they are not game assets.
"""
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(r"C:\Users\csw83\Documents\Codex\2026-06-27\wo-x\outputs\lunar_base_godot")
SOURCE = ROOT / "assets/characters/player_preview/female/light/black/walk_cycle_long.png"
OUT = ROOT / "user/eva_red_walk_cycle_v2_pose_guides"
OUT.mkdir(parents=True, exist_ok=True)

src = Image.open(SOURCE).convert("RGBA")
sheet = Image.new("RGBA", src.size, (16, 24, 34, 255))

COLORS = {
    "head": (255, 202, 77, 255),
    "torso": (94, 183, 255, 255),
    "arms": (220, 109, 255, 255),
    "legs": (75, 226, 154, 255),
}

def region_mask(alpha: Image.Image, row: int, name: str) -> Image.Image:
    # These zones are intentionally broad: the original alpha remains the final
    # authority for every limb extremity and every stride.
    mask = Image.new("L", (128, 128), 0)
    d = ImageDraw.Draw(mask)
    if name == "head":
        d.ellipse((34, 10, 94, 63), fill=255)
    elif name == "torso":
        d.polygon([(43, 52), (85, 52), (89, 83), (78, 91), (50, 91), (39, 82)], fill=255)
    elif name == "arms":
        d.rectangle((27, 51, 48, 92), fill=255)
        d.rectangle((80, 51, 101, 92), fill=255)
    elif name == "legs":
        d.rectangle((33, 75, 96, 123), fill=255)
    # Preserve only pixels belonging to this original frame.
    return ImageChops.multiply(mask, alpha)

for row in range(4):
    for col in range(6):
        box = (col * 128, row * 128, (col + 1) * 128, (row + 1) * 128)
        frame = src.crop(box)
        alpha = frame.getchannel("A")
        guide = Image.new("RGBA", (128, 128), (16, 24, 34, 255))
        # Original silhouette boundary, expanded by one pixel.
        expanded = alpha.filter(ImageFilter.MaxFilter(3))
        outer = ImageChops.subtract(expanded, alpha)
        guide = Image.composite(Image.new("RGBA", (128, 128), (220, 235, 245, 255)), guide, outer)
        for name, color in COLORS.items():
            mask = region_mask(alpha, row, name)
            overlay = Image.new("RGBA", (128, 128), color)
            guide = Image.composite(overlay, guide, mask)
        # Preserve a 1 px true contour on top for exact redraw positioning.
        inner = alpha.filter(ImageFilter.MinFilter(3))
        contour = ImageChops.subtract(alpha, inner).point(lambda a: 255 if a > 0 else 0)
        guide = Image.composite(Image.new("RGBA", (128, 128), (10, 16, 24, 255)), guide, contour)
        # Common feet baseline and frame index.
        d = ImageDraw.Draw(guide)
        d.line((8, 122, 120, 122), fill=(255, 255, 255, 100), width=1)
        d.text((4, 4), f"{row}:{col}", fill=(255, 255, 255, 210))
        guide.save(OUT / f"pose_{row}_{col:02}.png")
        sheet.alpha_composite(guide, (col * 128, row * 128))

sheet.save(OUT / "walk_pose_guide_6x4.png")
(OUT / "README.md").write_text(
    "# EVA walk pose guide\\n\\n"
    "Rows follow the current player sheet: down, left, right, up.\\n"
    "Columns 00–05 are the existing step phases.\\n\\n"
    "Colour legend: yellow=head/helmet envelope; blue=torso; purple=arms/gloves; "
    "green=legs/boots. The pale outer contour and white y=122 line are the strict "
    "silhouette and feet-baseline constraints for the redraw.\\n",
    encoding="utf-8",
)
