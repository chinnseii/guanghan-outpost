"""Derive red/yellow/blue astronaut walk bundles while preserving China flags."""
from __future__ import annotations

import argparse
import colorsys
import json
from pathlib import Path
import shutil

from PIL import Image


def flag_protection(image: Image.Image) -> tuple[int, int, int, int] | None:
    """Locate the flag by its yellow stars and return a padded safe rectangle."""
    stars = []
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            # Flag stars are saturated gold; do not mistake warm-red suit
            # antialiasing for stars.
            if a > 100 and r > 200 and g > 120 and b < 100 and g > r * 0.55:
                stars.append((x, y))
    if not stars:
        return None
    # Each Chinese flag uses a small cluster of these gold pixels. The source has
    # no other gold feature, so one padded rectangle protects its red field too.
    return (
        max(0, min(x for x, _ in stars) - 20),
        max(0, min(y for _, y in stars) - 20),
        min(image.width - 1, max(x for x, _ in stars) + 20),
        min(image.height - 1, max(y for _, y in stars) + 20),
    )


def recolor(image: Image.Image, accent: str) -> Image.Image:
    image = image.copy()
    if accent == "red":
        return image
    protected = flag_protection(image)
    hue = {"yellow": 0.125, "blue": 0.59}[accent]
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            if protected and protected[0] <= x <= protected[2] and protected[1] <= y <= protected[3]:
                continue
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            h, lightness, saturation = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
            # Red suit trim (including its dark and light antialiasing shades).
            if saturation >= 0.20 and (h <= 0.12 or h >= 0.94) and r > 55:
                # Retain shade and saturation, changing only the suit accent hue.
                nr, ng, nb = colorsys.hls_to_rgb(hue, lightness, saturation)
                pixels[x, y] = (round(nr * 255), round(ng * 255), round(nb * 255), a)
    return image


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--accent", choices=("red", "yellow", "blue"), required=True)
    args = parser.parse_args()
    source_frames = args.source / "frames"
    if args.output.exists():
        shutil.rmtree(args.output)
    (args.output / "frames").mkdir(parents=True)

    frame_paths = sorted(source_frames.glob("*.png"))
    grouped: dict[str, list[Image.Image]] = {direction: [] for direction in ("down", "left", "right", "up")}
    for frame_path in frame_paths:
        frame = recolor(Image.open(frame_path).convert("RGBA"), args.accent)
        target_name = frame_path.name.replace("astronaut_red", f"astronaut_{args.accent}")
        frame.save(args.output / "frames" / target_name)
        for direction in grouped:
            if f"_{direction}_" in target_name:
                grouped[direction].append(frame)
                break

    cell = (512, 512)
    order = ("down", "left", "right", "up")
    sheet = Image.new("RGBA", (cell[0] * 6, cell[1] * 4), (0, 0, 0, 0))
    for row, direction in enumerate(order):
        frames = grouped[direction]
        if len(frames) != 6:
            raise ValueError(f"{direction}: expected six frames")
        for column, frame in enumerate(frames):
            sheet.alpha_composite(frame, (column * cell[0], row * cell[1]))
        frames[0].save(args.output / f"astronaut_{args.accent}_walk_{direction}.gif", save_all=True,
                      append_images=frames[1:], duration=125, loop=0, disposal=2, transparency=0)
    sheet_name = f"astronaut_{args.accent}_walk_4dir_6f.png"
    sheet.save(args.output / sheet_name)

    manifest = json.loads((args.source / "manifest.json").read_text(encoding="utf-8"))
    manifest["sheet"] = sheet_name
    manifest["frames"] = [name.replace("astronaut_red", f"astronaut_{args.accent}") for name in manifest["frames"]]
    manifest["accent_color"] = {
        "red": "original red, China flag preserved",
        "yellow": "yellow (#d8b563-style), China flag preserved",
        "blue": "blue (#5d91c4-style), China flag preserved",
    }[args.accent]
    (args.output / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    (args.output / "README.md").write_text(
        f"# {args.accent.title()}-accent astronaut walk cycle\n\n"
        "Suit trim uses the selected accent color. China flag red fields and yellow stars are preserved.\n",
        encoding="utf-8",
    )
    archive = shutil.make_archive(str(args.output), "zip", root_dir=args.output)
    print(f"Created {args.output}\nCreated {archive}")


if __name__ == "__main__":
    main()
