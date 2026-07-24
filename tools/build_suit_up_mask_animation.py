"""Build deterministic suit-up frames from the shipped astronaut art.

No AI-generated suit components are used after frame 00: the delivered
walk-cycle down idle is progressively revealed so the final design is exact.
"""
from __future__ import annotations

import argparse
import colorsys
import json
from pathlib import Path
import shutil

from PIL import Image


CELL = 512
BASELINE = 480
PHASES = [
    "inner_pressure_layer",
    "boots_lock",
    "leg_armor_lock",
    "lower_torso_seal",
    "torso_and_arms_seal",
    "chest_system_lock",
    "helmet_shell_close",
    "visor_close_final",
]
ACCENT_HUE = {"red": 0.0, "yellow": 0.125, "blue": 0.59}


def key_magenta(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA").copy()
    px = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = px[x, y]
            if r > 170 and b > 120 and g < 110:
                px[x, y] = (0, 0, 0, 0)
    return image


def centered_to_baseline(image: Image.Image, height: int = 358) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if not bbox:
        raise ValueError("Inner-suit source has no opaque pixels")
    subject = image.crop(bbox)
    width = round(subject.width * height / subject.height)
    subject = subject.resize((width, height), Image.Resampling.NEAREST)
    out = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    out.alpha_composite(subject, ((CELL - width) // 2, BASELINE - height))
    return out


def tint_gold(image: Image.Image, accent: str) -> Image.Image:
    if accent == "yellow":
        return image.copy()
    image = image.copy()
    px = image.load()
    for y in range(CELL):
        for x in range(CELL):
            r, g, b, a = px[x, y]
            if not a:
                continue
            h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
            if s > 0.28 and 0.08 < h < 0.20 and r > 90:
                nr, ng, nb = colorsys.hls_to_rgb(ACCENT_HUE[accent], l, s)
                px[x, y] = (round(nr * 255), round(ng * 255), round(nb * 255), a)
    return image


def down_idle(sheet_path: Path) -> Image.Image:
    sheet = Image.open(sheet_path).convert("RGBA")
    if sheet.size != (CELL * 6, CELL * 4):
        raise ValueError(f"Unexpected sheet size: {sheet_path}: {sheet.size}")
    return sheet.crop((0, 0, CELL, CELL))


def masked_final(final: Image.Image, start_y: int | None = None, unlit_visor: bool = False) -> Image.Image:
    result = final.copy()
    alpha = result.getchannel("A")
    px = alpha.load()
    if start_y is not None:
        for y in range(start_y):
            for x in range(CELL):
                px[x, y] = 0
    if unlit_visor:
        # The helmet is closed but the visor has not powered to its final dark
        # state yet. Recolor only its dark interior; keep the approved outline.
        pixels = result.load()
        for y in range(158, 243):
            for x in range(158, 354):
                dx = (x - 256) / 98
                dy = (y - 201) / 43
                if dx * dx + dy * dy <= 1:
                    r, g, b, a = pixels[x, y]
                    if a and max(r, g, b) < 150:
                        pixels[x, y] = (185, 194, 198, a)
    result.putalpha(alpha)
    return result


def compose_frames(base: Image.Image, final: Image.Image):
    masks = [None, 390, 340, 290, 240, 205, None, 0]
    frames = []
    for index, start_y in enumerate(masks):
        frame = base.copy()
        if index:
            overlay = masked_final(final, start_y, unlit_visor=index == 6)
            frame.alpha_composite(overlay)
        frames.append(frame)
    return frames


def build_variant(base: Image.Image, accent: str, sheet: Path, target: Path):
    target.mkdir(parents=True, exist_ok=True)
    frames_dir = target / "frames"
    frames_dir.mkdir()
    frames = compose_frames(tint_gold(base, accent), down_idle(sheet))
    for index, frame in enumerate(frames):
        frame.save(frames_dir / f"suit_up_{accent}_{index:02d}.png")

    atlas = Image.new("RGBA", (CELL * 4, CELL * 2), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        atlas.alpha_composite(frame, ((index % 4) * CELL, (index // 4) * CELL))
    atlas_name = f"suit_up_{accent}_8f_4x2.png"
    atlas.save(target / atlas_name)
    frames[0].save(target / f"suit_up_{accent}_preview.gif", save_all=True, append_images=frames[1:],
                   duration=[240, 110, 110, 110, 110, 110, 150, 350], loop=0, disposal=2, transparency=0)
    (target / "manifest.json").write_text(json.dumps({
        "frame_size": {"width": CELL, "height": CELL},
        "layout": {"columns": 4, "rows": 2, "order": "row-major"},
        "frames": 8,
        "feet_baseline_y": BASELINE,
        "phases": PHASES,
        "final_frame_source": sheet.as_posix(),
        "note": "Frames 01-07 reveal regions from the shipped final suit art; frame 07 is the exact final idle frame.",
    }, ensure_ascii=False, indent=2), encoding="utf-8")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--inner", type=Path, required=True)
    parser.add_argument("--suits", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists():
        shutil.rmtree(args.output)
    base = centered_to_baseline(key_magenta(Image.open(args.inner)))
    for accent in ("red", "yellow", "blue"):
        build_variant(base, accent, args.suits / f"walk_cycle_{accent}.png", args.output / accent)
    (args.output / "README.md").write_text(
        "# Deterministic suit-up animations\n\n"
        "Each variant is an 8-frame 4x2 sheet. Frame 07 is copied from the shipped final suit idle art.\n"
        "Play once at roughly 10 FPS; keep the sprite origin at feet center.\n",
        encoding="utf-8",
    )
    archive = shutil.make_archive(str(args.output), "zip", root_dir=args.output)
    print(f"Created {args.output}\nCreated {archive}")


if __name__ == "__main__":
    main()
