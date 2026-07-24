#!/usr/bin/env python3
"""Apply one fixed black-hair palette and median brightness to every frame.

This is deliberately stronger than hue normalization.  It removes the warm
brown versus cool gray-green shift visible between directional walk frames,
while retaining the silhouette and a compact pixel-art shading ramp.
"""

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
BACKUP_ROOT = PROJECT_ROOT / "assets" / "characters" / "_walk_cycle_pre_fixed_black_hair_palette_backup"
REPORT_PATH = PROJECT_ROOT / "assets" / "characters" / "fixed_black_walk_hair_palette_report.json"

# A neutral charcoal ramp. Every black-hair walk frame uses these exact RGB
# colors, avoiding source-frame-specific green/brown casts.
PALETTE = [
    (25, 28, 27), (38, 43, 40), (52, 58, 54), (67, 74, 69),
    (83, 91, 85), (101, 110, 103), (121, 131, 123),
]


def backup(path: Path) -> None:
    relative = path.relative_to(PROJECT_ROOT / "assets" / "characters")
    target = BACKUP_ROOT / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    if not target.exists():
        shutil.copy2(path, target)


def main() -> None:
    report: dict[str, object] = {"palette": PALETTE, "sheets": {}}
    paths = sorted(SHEETS_ROOT.rglob("black/walk_cycle_*.png"))
    for path in paths:
        with Image.open(path) as source:
            image = source.convert("RGBA")
        cell_width, cell_height = image.width // COLUMNS, image.height // ROWS
        selected_per_cell: list[set[tuple[int, int]]] = []
        medians: list[float] = []
        for row in range(ROWS):
            for column in range(COLUMNS):
                cell = image.crop((column * cell_width, row * cell_height, (column + 1) * cell_width, (row + 1) * cell_height))
                selected, _ = hair_pixels(cell, profile_for(path))
                selected_per_cell.append(selected)
                values = [colorsys.rgb_to_hsv(*(channel / 255.0 for channel in cell.getpixel(pixel)[:3]))[2] for pixel in selected]
                if not values:
                    raise ValueError(f"No black-hair pixels selected in {path}, frame {row}:{column}")
                medians.append(statistics.median(values))
        target_median = statistics.median(medians)
        output = image.copy()
        recolored = 0
        for index, selected in enumerate(selected_per_cell):
            row, column = divmod(index, COLUMNS)
            cell = output.crop((column * cell_width, row * cell_height, (column + 1) * cell_width, (row + 1) * cell_height))
            pixels = cell.load()
            offset = target_median - medians[index]
            for x, y in selected:
                red, green, blue, alpha = pixels[x, y]
                value = max(0.0, min(1.0, colorsys.rgb_to_hsv(red / 255.0, green / 255.0, blue / 255.0)[2] + offset))
                palette_index = min(len(PALETTE) - 1, max(0, round((value - 0.08) / 0.64 * (len(PALETTE) - 1))))
                pixels[x, y] = (*PALETTE[palette_index], alpha)
                recolored += 1
            output.paste(cell, (column * cell_width, row * cell_height))
        backup(path)
        temporary = path.with_suffix(".black-palette-tmp.png")
        output.save(temporary)
        temporary.replace(path)
        report["sheets"][str(path.relative_to(PROJECT_ROOT))] = {
            "recolored_pixels": recolored,
            "frame_medians_before": medians,
            "target_median": target_median,
        }
    REPORT_PATH.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Locked fixed black-hair palette in {len(paths)} sheets.")


if __name__ == "__main__":
    main()
