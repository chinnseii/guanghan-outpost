#!/usr/bin/env python3
"""Match each right-facing walk frame to its same-index left-facing frame.

Rows are down, left, right, up; columns are walk-frame indices 0..5.  A
single scale factor per sheet left visible left/right discrepancies in some
packs.  This pass is deliberately stricter: every right frame is scaled and
translated so its alpha-box height and feet line match the corresponding left
frame.  Nearest-neighbour sampling keeps the source pixel art crisp.
"""

from __future__ import annotations

import json
import shutil
from pathlib import Path

from PIL import Image


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SHEETS_ROOT = PROJECT_ROOT / "assets" / "characters" / "player_preview"
MASKS_ROOT = PROJECT_ROOT / "assets" / "characters" / "skin_masks"
BACKUP_ROOT = PROJECT_ROOT / "assets" / "characters" / "_walk_cycle_pre_left_right_frame_match_backup"
REPORT_PATH = PROJECT_ROOT / "assets" / "characters" / "right_walk_left_frame_match_report.json"
COLUMNS, ROWS = 6, 4
LEFT_ROW, RIGHT_ROW = 1, 2

MASK_REFERENCES = {
    "female_longhair_skin_mask.png": SHEETS_ROOT / "female" / "light" / "black" / "walk_cycle_long.png",
    "female_ponytail_skin_mask.png": SHEETS_ROOT / "female" / "light" / "black" / "walk_cycle_ponytail.png",
    "female_shorthair_skin_mask.png": SHEETS_ROOT / "female" / "light" / "black" / "walk_cycle_short.png",
    "male_buzzcut_skin_mask.png": SHEETS_ROOT / "male" / "medium" / "black" / "walk_cycle_buzz.png",
    "male_longhair_skin_mask.png": SHEETS_ROOT / "male" / "medium" / "black" / "walk_cycle_long.png",
    "male_shortfringe_skin_mask.png": SHEETS_ROOT / "male" / "medium" / "black" / "walk_cycle_short.png",
}


def alpha_bbox(cell: Image.Image) -> tuple[int, int, int, int]:
    bbox = cell.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("Encountered an empty animation frame")
    return bbox


def backup(path: Path) -> None:
    relative = path.relative_to(PROJECT_ROOT / "assets" / "characters")
    target = BACKUP_ROOT / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    if not target.exists():
        shutil.copy2(path, target)


def cell_transforms(image: Image.Image) -> list[dict[str, float]]:
    cell_width, cell_height = image.width // COLUMNS, image.height // ROWS
    transforms: list[dict[str, float]] = []
    for column in range(COLUMNS):
        left = image.crop((column * cell_width, LEFT_ROW * cell_height, (column + 1) * cell_width, (LEFT_ROW + 1) * cell_height))
        right = image.crop((column * cell_width, RIGHT_ROW * cell_height, (column + 1) * cell_width, (RIGHT_ROW + 1) * cell_height))
        left_box, right_box = alpha_bbox(left), alpha_bbox(right)
        left_height, right_height = left_box[3] - left_box[1], right_box[3] - right_box[1]
        factor = left_height / right_height
        # Preserve the right frame's horizontal center. Map its bottom edge to
        # the matching left frame's bottom edge, thereby locking the feet.
        pivot_x = (right_box[0] + right_box[2]) * 0.5
        tx = pivot_x * (1.0 - factor)
        ty = left_box[3] - factor * right_box[3]
        transforms.append({
            "factor": factor,
            "tx": tx,
            "ty": ty,
            "left_top": left_box[1],
            "left_bottom": left_box[3],
            "left_height": left_height,
            "right_top_before": right_box[1],
            "right_bottom_before": right_box[3],
            "right_height_before": right_height,
        })
    return transforms


def apply_transforms(image: Image.Image, transforms: list[dict[str, float]], x_ratio: float = 1.0, y_ratio: float = 1.0) -> Image.Image:
    cell_width, cell_height = image.width // COLUMNS, image.height // ROWS
    output = image.copy()
    for column, transform in enumerate(transforms):
        factor = transform["factor"]
        tx, ty = transform["tx"] * x_ratio, transform["ty"] * y_ratio
        inverse = 1.0 / factor
        matrix = (inverse, 0.0, -tx * inverse, 0.0, inverse, -ty * inverse)
        box = (column * cell_width, RIGHT_ROW * cell_height, (column + 1) * cell_width, (RIGHT_ROW + 1) * cell_height)
        fixed = image.crop(box).transform(
            (cell_width, cell_height), Image.Transform.AFFINE, matrix,
            resample=Image.Resampling.NEAREST, fillcolor=(0, 0, 0, 0),
        )
        output.paste(fixed, box)
    return output


def matched_metrics(image: Image.Image) -> list[dict[str, int]]:
    cell_width, cell_height = image.width // COLUMNS, image.height // ROWS
    output: list[dict[str, int]] = []
    for column in range(COLUMNS):
        left = alpha_bbox(image.crop((column * cell_width, LEFT_ROW * cell_height, (column + 1) * cell_width, (LEFT_ROW + 1) * cell_height)))
        right = alpha_bbox(image.crop((column * cell_width, RIGHT_ROW * cell_height, (column + 1) * cell_width, (RIGHT_ROW + 1) * cell_height)))
        output.append({
            "left_top": left[1], "left_bottom": left[3], "left_height": left[3] - left[1],
            "right_top": right[1], "right_bottom": right[3], "right_height": right[3] - right[1],
        })
    return output


def main() -> None:
    sheets = sorted(SHEETS_ROOT.rglob("walk_cycle_*.png"))
    corrections: dict[Path, tuple[list[dict[str, float]], int, int]] = {}
    report: dict[str, object] = {"sheets": {}, "masks": {}}
    for path in sheets:
        image = Image.open(path).convert("RGBA")
        transforms = cell_transforms(image)
        backup(path)
        corrected = apply_transforms(image, transforms)
        corrected.save(path)
        corrections[path] = (transforms, image.width // COLUMNS, image.height // ROWS)
        report["sheets"][str(path.relative_to(PROJECT_ROOT))] = {
            "per_frame": transforms,
            "after": matched_metrics(corrected),
        }

    for mask_name, reference in MASK_REFERENCES.items():
        mask_path = MASKS_ROOT / mask_name
        if not mask_path.exists() or reference not in corrections:
            continue
        transforms, ref_width, ref_height = corrections[reference]
        image = Image.open(mask_path).convert("RGBA")
        backup(mask_path)
        corrected = apply_transforms(image, transforms, (image.width // COLUMNS) / ref_width, (image.height // ROWS) / ref_height)
        corrected.save(mask_path)
        report["masks"][mask_name] = {"reference": str(reference.relative_to(PROJECT_ROOT)), "per_frame_factors": [item["factor"] for item in transforms]}

    REPORT_PATH.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Matched {len(sheets)} sheets and {len(report['masks'])} masks.")


if __name__ == "__main__":
    main()
