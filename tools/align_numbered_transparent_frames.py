"""Normalize numbered transparent PNG frames onto one shared canvas and baseline."""
from pathlib import Path
import argparse
from PIL import Image

parser = argparse.ArgumentParser()
parser.add_argument("folder", type=Path)
parser.add_argument("--height", type=int, default=352, help="visible sprite height in pixels")
parser.add_argument("--width", type=int, default=256, help="output canvas width")
parser.add_argument("--canvas-height", type=int, default=384)
parser.add_argument("--baseline", type=int, default=368, help="bottom y of visible sprite")
args = parser.parse_args()

folder = args.folder.resolve()
out = folder / "aligned_1_to_8"
out.mkdir(exist_ok=True)

for number in range(1, 9):
    path = folder / f"{number}.png"
    frame = Image.open(path).convert("RGBA")
    bbox = frame.getchannel("A").getbbox()
    if bbox is None:
        raise RuntimeError(f"{path.name} has no visible pixels")
    sprite = frame.crop(bbox)
    target_width = round(sprite.width * args.height / sprite.height)
    if target_width > args.width:
        raise RuntimeError(f"{path.name} would exceed the {args.width}px canvas")
    sprite = sprite.resize((target_width, args.height), Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", (args.width, args.canvas_height), (0, 0, 0, 0))
    canvas.alpha_composite(sprite, ((args.width - target_width) // 2, args.baseline - args.height))
    canvas.save(out / path.name)

print(f"Aligned 1–8 to {out}")
