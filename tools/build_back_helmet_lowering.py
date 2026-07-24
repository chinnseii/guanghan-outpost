"""Build a rear-view helmet-lowering animation from shipped suit artwork."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import shutil

from PIL import Image


CELL = 512
BACK_ROW = 3
HELMET_BOX = (130, 108, 384, 260)
HELMET_LANDING_Y = 108
HELMET_Y = (-28, 0, 28, 56, 82, 102)


def rear_idle(sheet_path: Path) -> Image.Image:
    image = Image.open(sheet_path).convert("RGBA")
    if image.size != (3072, 2048):
        raise ValueError(f"Unexpected sheet size: {sheet_path}: {image.size}")
    return image.crop((0, BACK_ROW * CELL, CELL, (BACK_ROW + 1) * CELL))


def key_magenta(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA").copy()
    px = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = px[x, y]
            if r > 170 and b > 120 and g < 110:
                px[x, y] = (0, 0, 0, 0)
    return image


def normalize_inner(image: Image.Image) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if not bbox:
        raise ValueError("Inner-suit image has no opaque pixels")
    subject = image.crop(bbox)
    height = 358
    width = round(subject.width * height / subject.height)
    subject = subject.resize((width, height), Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    canvas.alpha_composite(subject, ((CELL - width) // 2, 480 - height))
    return canvas


def without_helmet(rear: Image.Image) -> Image.Image:
    body = rear.copy()
    alpha = body.getchannel("A")
    px = alpha.load()
    # Preserve collar and shoulders; only the rear helmet itself is removed.
    for y in range(96, 240):
        for x in range(120, 392):
            px[x, y] = 0
    body.putalpha(alpha)
    return body


def soft_hood(inner: Image.Image) -> Image.Image:
    # The generic full-coverage hood is derived from the approved inner suit,
    # not from a second helmet, so the descent reads as one shell closing.
    hood = inner.crop((178, 102, 334, 244))
    out = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    out.alpha_composite(hood, ((CELL - hood.width) // 2, 126))
    return out


def frame(body: Image.Image, hood: Image.Image, helmet: Image.Image, helmet_y: int) -> Image.Image:
    out = body.copy()
    out.alpha_composite(hood)
    out.alpha_composite(helmet, ((CELL - helmet.width) // 2, helmet_y))
    return out


def build(accent: str, sheet_path: Path, inner: Image.Image, target: Path):
    rear = rear_idle(sheet_path)
    helmet = rear.crop(HELMET_BOX)
    body = without_helmet(rear)
    hood = soft_hood(inner)
    frames = [frame(body, hood, helmet, y) for y in HELMET_Y] + [rear]
    target.mkdir(parents=True)
    frames_dir = target / "frames"
    frames_dir.mkdir()
    for index, image in enumerate(frames):
        image.save(frames_dir / f"suit_helmet_lower_{accent}_{index:02d}.png")
    sheet = Image.new("RGBA", (CELL * 4, CELL * 2), (0, 0, 0, 0))
    for index, image in enumerate(frames):
        sheet.alpha_composite(image, ((index % 4) * CELL, (index // 4) * CELL))
    sheet.save(target / f"suit_helmet_lower_{accent}_7f_4x2.png")
    frames[0].save(target / f"suit_helmet_lower_{accent}_preview.gif", save_all=True, append_images=frames[1:],
                   duration=[150, 130, 130, 130, 130, 170, 350], loop=0, disposal=2, transparency=0)
    (target / "manifest.json").write_text(json.dumps({
        "frame_size": {"width": CELL, "height": CELL},
        "layout": {"columns": 4, "rows": 2, "order": "row-major"},
        "frames": 7,
        "direction": "up/back",
        "final_frame_source": sheet_path.as_posix(),
        "note": "Frames 00-05 use helmet pixels cropped from the shipped rear idle; frame 06 is the exact shipped rear idle frame.",
    }, ensure_ascii=False, indent=2), encoding="utf-8")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--suits", type=Path, required=True)
    parser.add_argument("--inner", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists():
        shutil.rmtree(args.output)
    inner = normalize_inner(key_magenta(Image.open(args.inner)))
    for accent in ("red", "yellow", "blue"):
        build(accent, args.suits / f"walk_cycle_{accent}.png", inner, args.output / accent)
    (args.output / "README.md").write_text(
        "# Rear helmet-lowering animation\n\n"
        "Seven frames, 4x2 layout. Play once at 8 FPS; frame 06 is the shipped rear idle.\n",
        encoding="utf-8",
    )
    archive = shutil.make_archive(str(args.output), "zip", root_dir=args.output)
    print(f"Created {args.output}\nCreated {archive}")


if __name__ == "__main__":
    main()
