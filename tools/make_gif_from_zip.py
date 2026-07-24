"""Create a looping GIF from numbered PNG frames inside a ZIP archive."""
from pathlib import Path
import argparse
from io import BytesIO
import re
import zipfile
from PIL import Image

parser = argparse.ArgumentParser()
parser.add_argument("input_zip", type=Path)
parser.add_argument("output_gif", type=Path)
parser.add_argument("--duration", type=int, default=125)
args = parser.parse_args()

def natural_key(name: str):
    return [int(part) if part.isdigit() else part.casefold() for part in re.split(r"(\d+)", name)]

with zipfile.ZipFile(args.input_zip) as archive:
    names = sorted(
        (name for name in archive.namelist() if name.lower().endswith(".png")),
        key=natural_key,
    )
    if not names:
        raise SystemExit("The ZIP contains no PNG frames")
    frames = [Image.open(BytesIO(archive.read(name))).convert("RGBA") for name in names]

# Remove a solid magenta key if the matte export retained it.
for frame in frames:
    px = frame.load()
    for y in range(frame.height):
        for x in range(frame.width):
            r, g, b, a = px[x, y]
            if (r > 185 and b > 145 and g < 110) or (r > 90 and b > 80 and g < min(r, b) * 0.75):
                px[x, y] = (0, 0, 0, 0)

width = max(frame.width for frame in frames)
height = max(frame.height for frame in frames)
normalized = []
for frame in frames:
    canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    canvas.alpha_composite(frame, ((width - frame.width) // 2, height - frame.height))
    normalized.append(canvas)

args.output_gif.parent.mkdir(parents=True, exist_ok=True)
normalized[0].save(
    args.output_gif,
    save_all=True,
    append_images=normalized[1:],
    duration=args.duration,
    loop=0,
    disposal=2,
    transparency=0,
)
print(f"Created {args.output_gif} from {len(normalized)} frames")
