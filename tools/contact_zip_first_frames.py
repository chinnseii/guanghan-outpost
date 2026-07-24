"""Build a contact sheet from the first PNG in every supplied ZIP."""
from pathlib import Path
import argparse
from io import BytesIO
import zipfile
from PIL import Image, ImageDraw

parser = argparse.ArgumentParser()
parser.add_argument("output", type=Path)
parser.add_argument("zips", nargs="+", type=Path)
args = parser.parse_args()

tiles = []
for path in args.zips:
    with zipfile.ZipFile(path) as archive:
        names = sorted(name for name in archive.namelist() if name.lower().endswith(".png"))
        if not names:
            continue
        image = Image.open(BytesIO(archive.read(names[0]))).convert("RGBA")
        image.thumbnail((180, 180), Image.Resampling.NEAREST)
        tile = Image.new("RGBA", (200, 220), (32, 32, 32, 255))
        tile.alpha_composite(image, ((200 - image.width) // 2, 24))
        ImageDraw.Draw(tile).text((6, 4), path.name, fill=(255, 255, 255, 255))
        tiles.append(tile)

sheet = Image.new("RGBA", (800, ((len(tiles) + 3) // 4) * 220), (16, 16, 16, 255))
for index, tile in enumerate(tiles):
    sheet.alpha_composite(tile, ((index % 4) * 200, (index // 4) * 220))
args.output.parent.mkdir(parents=True, exist_ok=True)
sheet.save(args.output)
