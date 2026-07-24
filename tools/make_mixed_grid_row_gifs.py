"""Make row GIF previews from a sheet whose rows have differing frame counts."""
from pathlib import Path
import argparse
from PIL import Image

parser = argparse.ArgumentParser()
parser.add_argument("input", type=Path)
parser.add_argument("output", type=Path)
parser.add_argument("--row-counts", default="6,6,5,5,5")
args = parser.parse_args()

source = Image.open(args.input).convert("RGBA")
row_counts = [int(value) for value in args.row_counts.split(",")]
args.output.mkdir(parents=True, exist_ok=True)

for row, count in enumerate(row_counts):
    y0 = round(row * source.height / len(row_counts))
    y1 = round((row + 1) * source.height / len(row_counts))
    cells = [
        source.crop((round(col * source.width / count), y0, round((col + 1) * source.width / count), y1))
        for col in range(count)
    ]
    width = max(cell.width for cell in cells)
    frames = []
    for cell in cells:
        frame = Image.new("RGBA", (width, y1 - y0), (255, 255, 255, 255))
        frame.alpha_composite(cell, ((width - cell.width) // 2, 0))
        frames.append(frame)
    frames[0].save(
        args.output / f"row_{row + 1:02}_preview.gif",
        save_all=True,
        append_images=frames[1:],
        duration=125,
        loop=0,
        disposal=2,
    )
