"""Build a normalized 4-direction, 6-frame EVA walk sheet from approved raw frames."""
from pathlib import Path
from PIL import Image, ImageChops
import json

ROOT = Path(r"C:\Users\csw83\Documents\Codex\2026-06-27\wo-x\outputs\lunar_base_godot")
RAW = Path(r"C:\Users\csw83\.codex\generated_images\019f6f8c-730a-7340-9391-2d27d12acdda")
OUT = ROOT / "user" / "eva_red_walk_cycle_v1"
OUT.mkdir(parents=True, exist_ok=True)

down = [
    "exec-dd08db3f-6ac1-433f-b45b-21e93cfa0e7b.png", "exec-41af20c8-39ea-4572-ad2b-9a0706479be9.png",
    "exec-6fc07c29-2c4f-449f-be5c-e2c6442403e7.png", "exec-b1266d1f-d679-462c-b617-3332e31fbd9d.png",
    "exec-9e47dea9-1253-4773-9576-522a3c04713b.png", "exec-4035df12-9d16-4910-8ca5-4bf5de774495.png",
]
left = [
    "exec-d4e8c525-77d0-494c-a779-265807902508.png", "exec-5455c2c8-42a5-44db-aa8f-754815a8f880.png",
    "exec-3fdec7ba-3a0b-445f-8c2d-ce5f64bff2d3.png", "exec-1cdaeef0-a318-4df5-90aa-acdcabb33c10.png",
    "exec-aede2153-5783-46f8-8856-ccc94ed0543f.png", "exec-74a952ad-d17c-4673-b89a-b2d3f94dfad9.png",
]
up = [
    "exec-15ab98ed-1d3e-4b63-ac58-ac03ac672586.png", "exec-0f3c1130-820e-4bc1-9cee-1bfbf5f0c03e.png",
    "exec-1e063108-ab8f-462e-a1b5-e3603afb64cd.png", "exec-f30d9514-8cfa-477f-89e3-5121a451b366.png",
    "exec-b8c03e78-1589-4486-9175-4ba568a571b1.png", "exec-876b5a19-9e00-4ddb-a643-dfee2a34efe3.png",
]

def clean_and_normalize(name: str, mirror: bool = False) -> Image.Image:
    src = Image.open(RAW / name).convert("RGBA")
    px = src.load()
    for y in range(src.height):
        for x in range(src.width):
            r, g, b, _ = px[x, y]
            # Chroma key: high red+blue, very low green. Keep the suit's red paint.
            if r > 190 and b > 150 and g < 110:
                px[x, y] = (r, g, b, 0)
    alpha = src.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        raise RuntimeError(f"No non-key pixels in {name}")
    crop = src.crop(bbox)
    target_h = 112
    target_w = max(1, round(crop.width * target_h / crop.height))
    crop = crop.resize((target_w, target_h), Image.Resampling.NEAREST)
    if mirror:
        crop = crop.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    frame = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    frame.alpha_composite(crop, ((128 - target_w) // 2, 122 - target_h))
    return frame

rows = {
    "down": [clean_and_normalize(p) for p in down],
    "left": [clean_and_normalize(p) for p in left],
    "right": [clean_and_normalize(p, mirror=True) for p in left],
    "up": [clean_and_normalize(p) for p in up],
}

sheet = Image.new("RGBA", (128 * 6, 128 * 4), (0, 0, 0, 0))
for row_i, (direction, frames) in enumerate(rows.items()):
    for frame_i, frame in enumerate(frames):
        frame.save(OUT / f"eva_red_walk_{direction}_{frame_i:02}.png")
        sheet.alpha_composite(frame, (frame_i * 128, row_i * 128))
sheet.save(OUT / "eva_red_walk_6x4.png")

# Small loop previews make it possible to assess cadence before integration.
for direction, frames in rows.items():
    frames[0].save(
        OUT / f"eva_red_walk_{direction}_preview.gif",
        save_all=True,
        append_images=frames[1:],
        duration=115,
        loop=0,
        disposal=2,
        transparency=0,
    )

manifest = {
    "frame_size": [128, 128],
    "directions": ["down", "left", "right", "up"],
    "frames_per_direction": 6,
    "order": ["00_contact", "01_weight_acceptance", "02_passing", "03_opposite_contact", "04_opposite_weight_acceptance", "05_opposite_passing"],
    "feet_baseline_y": 122,
    "right_direction": "lossless horizontal mirror of left direction",
    "source": "AI-generated red EVA suit frames; normalized without changing original raw images",
}
(OUT / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
