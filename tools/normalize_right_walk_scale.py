#!/usr/bin/env python3
"""Apply a per-sheet right-walk scale correction and keep skin masks aligned.

The source walk sheets use four rows: down, left, right, up.  Some character
sources have a right-facing body that is taller than the other directions, but
the amount varies by hairstyle.  This script measures each sheet and scales
only its right-facing row around its feet, preserving pixel edges.
"""

from __future__ import annotations

import json
import shutil
import statistics
from pathlib import Path

from PIL import Image


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SHEETS_ROOT = PROJECT_ROOT / "assets" / "characters" / "player_preview"
MASKS_ROOT = PROJECT_ROOT / "assets" / "characters" / "skin_masks"
BACKUP_ROOT = PROJECT_ROOT / "assets" / "characters" / "_walk_cycle_pre_per_sheet_right_scale_backup"
REPORT_PATH = PROJECT_ROOT / "assets" / "characters" / "per_sheet_right_scale_report.json"

COLUMNS = 6
ROWS = 4
RIGHT_ROW = 2
REFERENCE_ROWS = (0, 1, 3)

MASK_REFERENCES = {
    "female_longhair_skin_mask.png": SHEETS_ROOT / "female" / "light" / "black" / "walk_cycle_native.png",
    "female_ponytail_skin_mask.png": SHEETS_ROOT / "female" / "light" / "black" / "walk_cycle_ponytail.png",
    "female_shorthair_skin_mask.png": SHEETS_ROOT / "female" / "light" / "black" / "walk_cycle_short.png",
    "male_buzzcut_skin_mask.png": SHEETS_ROOT / "male" / "medium" / "black" / "walk_cycle_buzz.png",
    "male_longhair_skin_mask.png": SHEETS_ROOT / "male" / "medium" / "black" / "walk_cycle_long.png",
    "male_shortfringe_skin_mask.png": SHEETS_ROOT / "male" / "medium" / "black" / "walk_cycle_short.png",
}


def alpha_bbox(image: Image.Image):
    return image.getchannel("A").getbbox()


def row_metrics(image: Image.Image) -> dict[str, object]:
    cell_width = image.width // COLUMNS
    cell_height = image.height // ROWS
    rows: list[dict[str, float]] = []
    for row in range(ROWS):
        heights: list[float] = []
        centers_x: list[float] = []
        bottoms: list[float] = []
        for column in range(COLUMNS):
            cell = image.crop((column * cell_width, row * cell_height, (column + 1) * cell_width, (row + 1) * cell_height))
            bbox = alpha_bbox(cell)
            if bbox is None:
                continue
            left, top, right, bottom = bbox
            heights.append(bottom - top)
            centers_x.append((left + right) * 0.5)
            bottoms.append(float(bottom))
        if not heights:
            raise ValueError(f"No opaque pixels found in row {row}")
        rows.append({
            "height": float(statistics.median(heights)),
            "center_x": float(statistics.median(centers_x)),
            "bottom": float(statistics.median(bottoms)),
        })
    return {"cell_width": cell_width, "cell_height": cell_height, "rows": rows}


def transform_right_row(image: Image.Image, factor: float, pivot_x: float, pivot_y: float) -> Image.Image:
    cell_width = image.width // COLUMNS
    cell_height = image.height // ROWS
    result = image.copy()
    inverse = 1.0 / factor
    matrix = (
        inverse, 0.0, pivot_x - pivot_x * inverse,
        0.0, inverse, pivot_y - pivot_y * inverse,
    )
    for column in range(COLUMNS):
        box = (column * cell_width, RIGHT_ROW * cell_height, (column + 1) * cell_width, (RIGHT_ROW + 1) * cell_height)
        source = image.crop(box)
        corrected = source.transform(
            (cell_width, cell_height),
            Image.Transform.AFFINE,
            matrix,
            resample=Image.Resampling.NEAREST,
            fillcolor=(0, 0, 0, 0),
        )
        result.paste(corrected, box)
    return result


def build_correction(image: Image.Image) -> dict[str, float]:
    metrics = row_metrics(image)
    rows = metrics["rows"]
    right_height = rows[RIGHT_ROW]["height"]
    target_height = statistics.median([rows[row]["height"] for row in REFERENCE_ROWS])
    factor = target_height / right_height
    return {
        "factor": float(factor),
        "target_height": float(target_height),
        "right_height_before": float(right_height),
        "pivot_x": float(rows[RIGHT_ROW]["center_x"]),
        "pivot_y": float(statistics.median([row["bottom"] for row in rows])),
        "cell_width": int(metrics["cell_width"]),
        "cell_height": int(metrics["cell_height"]),
    }


def backup(source: Path) -> None:
    relative = source.relative_to(PROJECT_ROOT / "assets" / "characters")
    destination = BACKUP_ROOT / relative
    destination.parent.mkdir(parents=True, exist_ok=True)
    if not destination.exists():
        shutil.copy2(source, destination)


def main() -> None:
    sheets = sorted(path for path in SHEETS_ROOT.rglob("walk_cycle_*.png") if "_backup" not in path.parts)
    corrections: dict[Path, dict[str, float]] = {}
    report: dict[str, object] = {"sheets": {}, "masks": {}}

    for source in sheets:
        image = Image.open(source).convert("RGBA")
        correction = build_correction(image)
        backup(source)
        corrected = transform_right_row(image, correction["factor"], correction["pivot_x"], correction["pivot_y"])
        corrected.save(source)
        after = row_metrics(corrected)["rows"][RIGHT_ROW]["height"]
        correction["right_height_after"] = float(after)
        corrections[source] = correction
        report["sheets"][str(source.relative_to(PROJECT_ROOT))] = correction

    for mask_name, reference in MASK_REFERENCES.items():
        source = MASKS_ROOT / mask_name
        if not source.exists() or reference not in corrections:
            continue
        image = Image.open(source).convert("RGBA")
        reference_correction = corrections[reference]
        cell_width = image.width // COLUMNS
        cell_height = image.height // ROWS
        pivot_x = reference_correction["pivot_x"] * cell_width / reference_correction["cell_width"]
        pivot_y = reference_correction["pivot_y"] * cell_height / reference_correction["cell_height"]
        backup(source)
        corrected = transform_right_row(image, reference_correction["factor"], pivot_x, pivot_y)
        corrected.save(source)
        report["masks"][mask_name] = {
            "reference": str(reference.relative_to(PROJECT_ROOT)),
            "factor": reference_correction["factor"],
            "pivot_x": pivot_x,
            "pivot_y": pivot_y,
        }

    REPORT_PATH.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Corrected {len(sheets)} walk sheets and {len(report['masks'])} skin masks.")


if __name__ == "__main__":
    main()
