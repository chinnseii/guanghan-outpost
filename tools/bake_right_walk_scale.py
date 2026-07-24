#!/usr/bin/env python3
"""Bake the former right-facing runtime scale fix into 6x4 player assets.

The old renderer shrank row 2 by 1/1.10.  This tool applies the same nearest
neighbour scale around the row's aligned centre/feet pivot to every active
walk sheet and to its matching skin mask, allowing the renderer to stay at
uniform scale in every direction.
"""

from __future__ import annotations

import json
import shutil
import statistics
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
CHARACTERS = ROOT / "assets" / "characters"
SHEETS_ROOT = CHARACTERS / "player_preview"
BACKUP_ROOT = CHARACTERS / "_walk_cycle_pre_right_scale_bake_backup"
REPORT_PATH = CHARACTERS / "right_walk_scale_bake_report.json"
RIGHT_ROW = 2
SCALE = 1.0 / 1.10

MASK_REFERENCES = {
    "female_longhair_skin_mask.png": SHEETS_ROOT / "female/light/black/walk_cycle_native.png",
    "female_ponytail_skin_mask.png": SHEETS_ROOT / "female/light/black/walk_cycle_ponytail.png",
    "female_shorthair_skin_mask.png": SHEETS_ROOT / "female/light/black/walk_cycle_short.png",
    "male_buzzcut_skin_mask.png": SHEETS_ROOT / "male/medium/black/walk_cycle_buzz.png",
    "male_longhair_skin_mask.png": SHEETS_ROOT / "male/medium/black/walk_cycle_long.png",
    "male_shortfringe_skin_mask.png": SHEETS_ROOT / "male/medium/black/walk_cycle_short.png",
}


def backup_once(path: Path) -> None:
    backup = BACKUP_ROOT / path.relative_to(CHARACTERS)
    if not backup.exists():
        backup.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, backup)


def pivots(image: Image.Image) -> tuple[int, int, float, float]:
    if image.width % 6 or image.height % 4:
        raise ValueError(f"{image.size} is not a 6x4 sheet")
    cell_w, cell_h = image.width // 6, image.height // 4
    alpha = image.getchannel("A")
    boxes = [
        alpha.crop((column * cell_w, RIGHT_ROW * cell_h, (column + 1) * cell_w, (RIGHT_ROW + 1) * cell_h)).getbbox()
        for column in range(6)
    ]
    if any(box is None for box in boxes):
        raise ValueError("right-facing row contains an empty frame")
    pivot_x = statistics.median((box[0] + box[2]) / 2.0 for box in boxes if box)

    all_boxes = [
        alpha.crop((column * cell_w, row * cell_h, (column + 1) * cell_w, (row + 1) * cell_h)).getbbox()
        for row in range(4) for column in range(6)
    ]
    pivot_y = statistics.median(box[3] for box in all_boxes if box)
    return cell_w, cell_h, pivot_x, pivot_y


def scale_row(image: Image.Image, cell_w: int, cell_h: int, pivot_x: float, pivot_y: float) -> Image.Image:
    result = image.copy()
    inverse = 1.0 / SCALE
    matrix = (
        inverse, 0.0, pivot_x - pivot_x * inverse,
        0.0, inverse, pivot_y - pivot_y * inverse,
    )
    for column in range(6):
        x0, y0 = column * cell_w, RIGHT_ROW * cell_h
        cell = image.crop((x0, y0, x0 + cell_w, y0 + cell_h))
        scaled = cell.transform(
            (cell_w, cell_h), Image.Transform.AFFINE, matrix,
            resample=Image.Resampling.NEAREST, fillcolor=(0, 0, 0, 0),
        )
        result.paste(scaled, (x0, y0))
    return result


def process_sheet(path: Path) -> dict:
    image = Image.open(path).convert("RGBA")
    cell_w, cell_h, pivot_x, pivot_y = pivots(image)
    backup_once(path)
    scale_row(image, cell_w, cell_h, pivot_x, pivot_y).save(path)
    return {"cell_size": [cell_w, cell_h], "pivot": [pivot_x, pivot_y]}


def process_mask(path: Path, reference: dict) -> None:
    image = Image.open(path).convert("RGBA")
    cell_w, cell_h = image.width // 6, image.height // 4
    ref_w, ref_h = reference["cell_size"]
    pivot_x = reference["pivot"][0] * cell_w / ref_w
    pivot_y = reference["pivot"][1] * cell_h / ref_h
    backup_once(path)
    scale_row(image, cell_w, cell_h, pivot_x, pivot_y).save(path)


def main() -> None:
    reports: dict[str, dict] = {}
    for path in sorted(SHEETS_ROOT.rglob("walk_cycle_*.png")):
        reports[str(path.relative_to(ROOT))] = process_sheet(path)
    for mask_name, reference_path in MASK_REFERENCES.items():
        key = str(reference_path.relative_to(ROOT))
        mask = CHARACTERS / "skin_masks" / mask_name
        if mask.exists() and key in reports:
            process_mask(mask, reports[key])
    REPORT_PATH.write_text(json.dumps(reports, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Baked right-facing scale {SCALE:.8f} into {len(reports)} sheets.")


if __name__ == "__main__":
    main()
