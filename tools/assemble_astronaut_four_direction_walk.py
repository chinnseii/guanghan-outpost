"""Assemble four supplied astronaut walk-cycle ZIPs into a transparent Godot-ready bundle.

The input sets are ordered down, up, left, right.  The forward/backward rows
have their blue shoe tint neutralized to the suit's white/gray palette.
"""
from __future__ import annotations

import argparse
from io import BytesIO
import json
from pathlib import Path
import re
import shutil
import zipfile

from PIL import Image


ORDER = ("down", "left", "right", "up")


def natural_key(name: str):
    return [int(p) if p.isdigit() else p.casefold() for p in re.split(r"(\d+)", name)]


def load_zip_frames(path: Path):
    with zipfile.ZipFile(path) as source:
        names = sorted((n for n in source.namelist() if n.lower().endswith(".png")), key=natural_key)
        if len(names) != 6:
            raise ValueError(f"{path.name}: expected 6 PNG frames, found {len(names)}")
        return [Image.open(BytesIO(source.read(name))).convert("RGBA") for name in names]


def remove_key_and_fix_down_boots(image: Image.Image, fix_boots: bool) -> Image.Image:
    image = image.copy()
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            # Source sets use a magenta / purple chroma-key background.
            if (r > 185 and b > 145 and g < 120) or (r > 85 and b > 75 and g < min(r, b) * 0.74):
                pixels[x, y] = (0, 0, 0, 0)
                continue
            # The forward/backward rows have a cool-blue boot highlight. Neutralize only
            # in the lower third, retaining value so the pixel-art shading stays.
            if fix_boots and y >= image.height * 0.64 and b > r + 12 and b > g + 6:
                luminance = round(0.2126 * r + 0.7152 * g + 0.0722 * b)
                pixels[x, y] = (luminance, luminance, max(0, luminance - 2), a)
    return image


def alpha_bounds(image: Image.Image):
    return image.getchannel("A").getbbox()


def normalize(image: Image.Image, size: tuple[int, int], baseline: int) -> Image.Image:
    bounds = alpha_bounds(image)
    output = Image.new("RGBA", size, (0, 0, 0, 0))
    if not bounds:
        return output
    subject = image.crop(bounds)
    x = (size[0] - subject.width) // 2
    y = baseline - subject.height
    output.alpha_composite(subject, (x, y))
    return output


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--down", type=Path, required=True)
    parser.add_argument("--up", type=Path, required=True)
    parser.add_argument("--left", type=Path, required=True)
    parser.add_argument("--right", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    source_rows = {
        "down": load_zip_frames(args.down),
        "up": load_zip_frames(args.up),
        "left": load_zip_frames(args.left),
        "right": load_zip_frames(args.right),
    }
    rows = {
        direction: [remove_key_and_fix_down_boots(frame, direction in ("down", "up")) for frame in frames]
        for direction, frames in source_rows.items()
    }

    # Preserve the original 512-pixel art scale. All cycles share a feet line.
    cell = (512, 512)
    baseline = 480
    out = args.output
    frames_dir = out / "frames"
    if out.exists():
        shutil.rmtree(out)
    frames_dir.mkdir(parents=True)

    sheet = Image.new("RGBA", (cell[0] * 6, cell[1] * 4), (0, 0, 0, 0))
    manifest_frames = []
    for row, direction in enumerate(ORDER):
        prepared = [normalize(frame, cell, baseline) for frame in rows[direction]]
        for column, frame in enumerate(prepared):
            filename = f"astronaut_red_walk_{direction}_{column:02d}.png"
            frame.save(frames_dir / filename)
            sheet.alpha_composite(frame, (column * cell[0], row * cell[1]))
            manifest_frames.append(filename)
        prepared[0].save(
            out / f"astronaut_red_walk_{direction}.gif",
            save_all=True,
            append_images=prepared[1:],
            duration=125,
            loop=0,
            disposal=2,
            transparency=0,
        )

    sheet.save(out / "astronaut_red_walk_4dir_6f.png")
    (out / "manifest.json").write_text(json.dumps({
        "frame_size": {"width": 512, "height": 512},
        "frames_per_direction": 6,
        "direction_order": list(ORDER),
        "fps": 8,
        "feet_baseline_y": baseline,
        "sheet": "astronaut_red_walk_4dir_6f.png",
        "frames": manifest_frames,
        "front_back_boot_tint": "neutralized to white-gray",
    }, ensure_ascii=False, indent=2), encoding="utf-8")
    (out / "README.md").write_text(
        "# Red astronaut walk cycle\n\n"
        "Rows: down, up, left, right. Columns: 00 through 05.\n\n"
        "Import PNG assets with nearest-neighbor filtering and alpha preserved. "
        "Create four looping `AnimatedSprite2D` animations at 8 FPS.\n",
        encoding="utf-8",
    )
    archive = shutil.make_archive(str(out), "zip", root_dir=out)
    print(f"Created {out}")
    print(f"Created {archive}")


if __name__ == "__main__":
    main()
