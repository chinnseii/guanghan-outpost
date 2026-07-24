"""Create a looping GIF from numbered image files beside this script.

Examples of supported ordering: 1.png, 2.png, 10.png (numeric, not alphabetical).
Run: python make_ordered_gif.py
"""
from pathlib import Path
import re
from PIL import Image

FOLDER = Path(__file__).resolve().parent
OUTPUT = FOLDER / "ordered_preview.gif"
EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp"}

def sort_key(path: Path):
    parts = re.split(r"(\d+)", path.stem)
    return [int(part) if part.isdigit() else part.casefold() for part in parts]

paths = sorted(
    (path for path in FOLDER.iterdir() if path.suffix.lower() in EXTENSIONS),
    key=sort_key,
)
if not paths:
    raise SystemExit("No PNG/JPG/WEBP images found beside make_ordered_gif.py")

frames = [Image.open(path).convert("RGBA") for path in paths]
width = max(frame.width for frame in frames)
height = max(frame.height for frame in frames)
normalized = []
for frame in frames:
    canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    canvas.alpha_composite(frame, ((width - frame.width) // 2, height - frame.height))
    normalized.append(canvas)

normalized[0].save(
    OUTPUT,
    save_all=True,
    append_images=normalized[1:],
    duration=125,  # 8 FPS
    loop=0,
    disposal=2,
    transparency=0,
)
print(f"Created {OUTPUT.name} from {len(paths)} frames: " + ", ".join(path.name for path in paths))
