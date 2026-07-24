#!/usr/bin/env python3
"""Lock each walk sheet's hair hue/saturation across every animation frame.

The frames retain their original value/brightness (therefore hair volume and
shading), but hair-colored connected components use one shared hue and
saturation for the whole sheet.  Components must originate at the head, so
skin and spacesuit pixels are not selected.
"""

from __future__ import annotations

import colorsys
import json
import shutil
import statistics
from collections import deque
from pathlib import Path

from PIL import Image


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SHEETS_ROOT = PROJECT_ROOT / "assets" / "characters" / "player_preview"
BACKUP_ROOT = PROJECT_ROOT / "assets" / "characters" / "_walk_cycle_pre_hair_palette_normalization_backup"
REPORT_PATH = PROJECT_ROOT / "assets" / "characters" / "walk_hair_palette_normalization_report.json"
COLUMNS, ROWS = 6, 4


def profile_for(path: Path) -> dict[str, tuple[float, float]]:
    color = path.parts[-2]
    profiles = {
        "black": {"hue": (0.11, 0.29), "sat": (0.08, 1.0), "value": (0.05, 0.72)},
        "auburn": {"hue": (0.0, 0.095), "sat": (0.25, 1.0), "value": (0.12, 0.82)},
        "blonde": {"hue": (0.085, 0.17), "sat": (0.22, 1.0), "value": (0.22, 0.93)},
    }
    if color not in profiles:
        raise ValueError(f"Unknown hair color folder: {color}")
    return profiles[color]


def hue_in_range(hue: float, low: float, high: float) -> bool:
    return low <= hue <= high if low <= high else hue >= low or hue <= high


def candidate(rgb: tuple[int, int, int], alpha: int, profile: dict[str, tuple[float, float]]) -> tuple[bool, tuple[float, float, float]]:
    if alpha < 80:
        return False, (0.0, 0.0, 0.0)
    h, s, v = colorsys.rgb_to_hsv(*(channel / 255.0 for channel in rgb))
    selected = (
        hue_in_range(h, *profile["hue"])
        and profile["sat"][0] <= s <= profile["sat"][1]
        and profile["value"][0] <= v <= profile["value"][1]
    )
    return selected, (h, s, v)


def hair_pixels(cell: Image.Image, profile: dict[str, tuple[float, float]]) -> tuple[set[tuple[int, int]], list[tuple[float, float]]]:
    rgba = cell.load()
    width, height = cell.size
    alpha_box = cell.getchannel("A").getbbox()
    if alpha_box is None:
        return set(), []
    top = alpha_box[1]
    head_limit = top + max(12, int((alpha_box[3] - top) * 0.38))
    possible: set[tuple[int, int]] = set()
    hsv_values: dict[tuple[int, int], tuple[float, float, float]] = {}
    for y in range(height):
        for x in range(width):
            red, green, blue, alpha = rgba[x, y]
            ok, hsv = candidate((red, green, blue), alpha, profile)
            if ok:
                possible.add((x, y))
                hsv_values[(x, y)] = hsv

    selected: set[tuple[int, int]] = set()
    seen: set[tuple[int, int]] = set()
    for seed in possible:
        if seed in seen:
            continue
        component: set[tuple[int, int]] = set()
        queue: deque[tuple[int, int]] = deque([seed])
        seen.add(seed)
        while queue:
            x, y = queue.popleft()
            component.add((x, y))
            for neighbor in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if neighbor in possible and neighbor not in seen:
                    seen.add(neighbor)
                    queue.append(neighbor)
        if len(component) >= 16 and min(y for _, y in component) <= head_limit:
            selected.update(component)
    return selected, [(hsv_values[pixel][0], hsv_values[pixel][1]) for pixel in selected]


def backup(path: Path) -> None:
    relative = path.relative_to(PROJECT_ROOT / "assets" / "characters")
    target = BACKUP_ROOT / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    if not target.exists():
        shutil.copy2(path, target)


def normalize_sheet(path: Path) -> dict[str, object]:
    # Close the source handle before replacing its PNG on Windows.
    with Image.open(path) as source:
        image = source.convert("RGBA")
    profile = profile_for(path)
    cell_width, cell_height = image.width // COLUMNS, image.height // ROWS
    selected_by_cell: list[set[tuple[int, int]]] = []
    hs_values: list[tuple[float, float]] = []
    for row in range(ROWS):
        for column in range(COLUMNS):
            cell = image.crop((column * cell_width, row * cell_height, (column + 1) * cell_width, (row + 1) * cell_height))
            selected, values = hair_pixels(cell, profile)
            selected_by_cell.append(selected)
            hs_values.extend(values)
    if not hs_values:
        raise ValueError(f"No hair pixels selected in {path}")
    target_hue = statistics.median(value[0] for value in hs_values)
    target_sat = statistics.median(value[1] for value in hs_values)
    output = image.copy()
    for index, selected in enumerate(selected_by_cell):
        row, column = divmod(index, COLUMNS)
        cell = output.crop((column * cell_width, row * cell_height, (column + 1) * cell_width, (row + 1) * cell_height))
        pixels = cell.load()
        for x, y in selected:
            red, green, blue, alpha = pixels[x, y]
            _, _, value = colorsys.rgb_to_hsv(red / 255.0, green / 255.0, blue / 255.0)
            nr, ng, nb = colorsys.hsv_to_rgb(target_hue, target_sat, value)
            pixels[x, y] = (round(nr * 255), round(ng * 255), round(nb * 255), alpha)
        output.paste(cell, (column * cell_width, row * cell_height))
    backup(path)
    temporary_path = path.with_suffix(".palette-tmp.png")
    output.save(temporary_path)
    temporary_path.replace(path)
    return {
        "hair_color": path.parts[-2],
        "target_hue": target_hue,
        "target_saturation": target_sat,
        "recolored_pixels": sum(len(pixels) for pixels in selected_by_cell),
    }


def main() -> None:
    report: dict[str, object] = {"sheets": {}}
    sheets = sorted(SHEETS_ROOT.rglob("walk_cycle_*.png"))
    for path in sheets:
        report["sheets"][str(path.relative_to(PROJECT_ROOT))] = normalize_sheet(path)
    REPORT_PATH.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Normalized hair palettes in {len(sheets)} walk sheets.")


if __name__ == "__main__":
    main()
