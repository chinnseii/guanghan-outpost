#!/usr/bin/env python3
"""Lock every walk sheet to the approved hair-color specifications."""

from __future__ import annotations

import colorsys
import json
import shutil
import statistics
from pathlib import Path

from PIL import Image

from normalize_walk_hair_palette import COLUMNS, ROWS, hair_pixels, profile_for


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SHEETS_ROOT = PROJECT_ROOT / "assets" / "characters" / "player_preview"
BACKUP_ROOT = PROJECT_ROOT / "assets" / "characters" / "_walk_cycle_pre_approved_hair_palette_backup"
REPORT_PATH = PROJECT_ROOT / "assets" / "characters" / "walk_hair_palette_spec_report.json"

PALETTES = {
    "black": [(15, 15, 16), (22, 22, 24), (28, 28, 30), (36, 36, 38), (46, 46, 49), (57, 57, 61), (69, 69, 74)],
    "blonde": [(108, 91, 50), (142, 118, 63), (173, 145, 79), (216, 181, 99), (229, 197, 121), (240, 214, 148), (248, 228, 173)],
    "auburn": [(61, 30, 18), (81, 40, 23), (101, 51, 30), (122, 59, 35), (145, 74, 45), (169, 90, 56), (198, 110, 73)],
}
BLACK_PREVIOUS_PALETTE = {(25, 28, 27), (38, 43, 40), (52, 58, 54), (67, 74, 69), (83, 91, 85), (101, 110, 103), (121, 131, 123)}


def backup(path: Path) -> None:
    relative = path.relative_to(PROJECT_ROOT / "assets" / "characters")
    target = BACKUP_ROOT / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    if not target.exists():
        shutil.copy2(path, target)


def selected_black_pixels(cell: Image.Image) -> set[tuple[int, int]]:
    pixels = cell.load()
    return {(x, y) for y in range(cell.height) for x in range(cell.width) if pixels[x, y][:3] in BLACK_PREVIOUS_PALETTE and pixels[x, y][3] > 0}


def main() -> None:
    report: dict[str, object] = {"approved_base_colors": {"black": "#1C1C1E", "blonde": "#D8B563", "auburn": "#7A3B23"}, "sheets": {}}
    for path in sorted(SHEETS_ROOT.rglob("walk_cycle_*.png")):
        color = path.parts[-2]
        palette = PALETTES[color]
        with Image.open(path) as source:
            image = source.convert("RGBA")
        width, height = image.width // COLUMNS, image.height // ROWS
        selections: list[set[tuple[int, int]]] = []
        medians: list[float] = []
        for row in range(ROWS):
            for column in range(COLUMNS):
                cell = image.crop((column * width, row * height, (column + 1) * width, (row + 1) * height))
                selected = selected_black_pixels(cell) if color == "black" else hair_pixels(cell, profile_for(path))[0]
                if not selected:
                    raise ValueError(f"No {color} hair pixels in {path}, frame {row}:{column}")
                selections.append(selected)
                medians.append(statistics.median(colorsys.rgb_to_hsv(*(channel / 255.0 for channel in cell.getpixel(pixel)[:3]))[2] for pixel in selected))
        target_median = statistics.median(medians)
        output = image.copy()
        recolored = 0
        for index, selected in enumerate(selections):
            row, column = divmod(index, COLUMNS)
            cell = output.crop((column * width, row * height, (column + 1) * width, (row + 1) * height))
            pixels = cell.load()
            offset = target_median - medians[index]
            for x, y in selected:
                red, green, blue, alpha = pixels[x, y]
                value = max(0.0, min(1.0, colorsys.rgb_to_hsv(red / 255.0, green / 255.0, blue / 255.0)[2] + offset))
                level = min(len(palette) - 1, max(0, round((value - 0.08) / 0.70 * (len(palette) - 1))))
                pixels[x, y] = (*palette[level], alpha)
                recolored += 1
            output.paste(cell, (column * width, row * height))
        backup(path)
        temporary = path.with_suffix(".approved-palette-tmp.png")
        output.save(temporary)
        temporary.replace(path)
        report["sheets"][str(path.relative_to(PROJECT_ROOT))] = {"hair_color": color, "recolored_pixels": recolored, "target_frame_value": target_median}
    REPORT_PATH.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Locked approved palettes in {len(report['sheets'])} walk sheets.")


if __name__ == "__main__":
    main()
