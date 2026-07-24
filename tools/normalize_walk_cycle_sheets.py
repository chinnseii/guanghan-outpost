#!/usr/bin/env python3
"""Normalize grounded 6x4 player walk sheets for the Guanghan Outpost runtime.

The runtime already draws every cell at a fixed size and foot anchor.  This
tool fixes source-art drift instead: each frame is translated (never scaled)
so that its alpha-bounds centre matches the direction-row median and all feet
share one sheet-wide baseline.  Matching skin masks receive the same transform.

Original PNGs are copied once to assets/characters/_walk_cycle_pre_alignment_backup.
Run from the repository root:
    python tools/normalize_walk_cycle_sheets.py
"""

from __future__ import annotations

import json
import shutil
import statistics
from dataclasses import asdict, dataclass
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
CHARACTERS = ROOT / "assets" / "characters"
SHEETS_ROOT = CHARACTERS / "player_preview"
BACKUP_ROOT = CHARACTERS / "_walk_cycle_pre_alignment_backup"
REPORT_PATH = CHARACTERS / "walk_cycle_alignment_report.json"

# The shader masks are shared by hair colour.  These reference sheets have the
# corresponding geometry and provide the transform to apply to each mask.
MASK_REFERENCES = {
    "female_longhair_skin_mask.png": SHEETS_ROOT / "female/light/black/walk_cycle_native.png",
    "female_ponytail_skin_mask.png": SHEETS_ROOT / "female/light/black/walk_cycle_ponytail.png",
    "female_shorthair_skin_mask.png": SHEETS_ROOT / "female/light/black/walk_cycle_short.png",
    "male_buzzcut_skin_mask.png": SHEETS_ROOT / "male/medium/black/walk_cycle_buzz.png",
    "male_longhair_skin_mask.png": SHEETS_ROOT / "male/medium/black/walk_cycle_long.png",
    "male_shortfringe_skin_mask.png": SHEETS_ROOT / "male/medium/black/walk_cycle_short.png",
}


@dataclass
class FrameTransform:
    row: int
    column: int
    dx: int
    dy: int
    bbox: tuple[int, int, int, int]


def _alpha_bbox(cell: Image.Image) -> tuple[int, int, int, int]:
    bbox = cell.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("found an empty animation cell")
    return bbox


def _copy_original_once(path: Path) -> None:
    backup = BACKUP_ROOT / path.relative_to(CHARACTERS)
    if not backup.exists():
        backup.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, backup)


def _transforms(image: Image.Image) -> tuple[list[FrameTransform], int, int]:
    if image.width % 6 or image.height % 4:
        raise ValueError(f"{image.size} is not a 6x4 sheet")
    cell_w, cell_h = image.width // 6, image.height // 4
    boxes: list[list[tuple[int, int, int, int]]] = []
    for row in range(4):
        row_boxes = []
        for column in range(6):
            cell = image.crop((column * cell_w, row * cell_h, (column + 1) * cell_w, (row + 1) * cell_h))
            row_boxes.append(_alpha_bbox(cell))
        boxes.append(row_boxes)

    # A row's centre is resilient to the expected left/right movement of feet,
    # while the one global foot line prevents a pop when the player turns.
    row_centres = [statistics.median((box[0] + box[2]) / 2.0 for box in row) for row in boxes]
    foot_line = round(statistics.median(box[3] for row in boxes for box in row))

    transforms = []
    for row, row_boxes in enumerate(boxes):
        for column, box in enumerate(row_boxes):
            centre = (box[0] + box[2]) / 2.0
            transforms.append(
                FrameTransform(
                    row=row,
                    column=column,
                    dx=round(row_centres[row] - centre),
                    dy=foot_line - box[3],
                    bbox=box,
                )
            )
    return transforms, cell_w, cell_h


def _apply(image: Image.Image, transforms: list[FrameTransform], cell_w: int, cell_h: int) -> Image.Image:
    result = Image.new("RGBA", image.size, (0, 0, 0, 0))
    for transform in transforms:
        x0, y0 = transform.column * cell_w, transform.row * cell_h
        cell = image.crop((x0, y0, x0 + cell_w, y0 + cell_h))
        translated = Image.new("RGBA", (cell_w, cell_h), (0, 0, 0, 0))
        translated.paste(cell, (transform.dx, transform.dy))
        result.alpha_composite(translated, (x0, y0))
    return result


def _process_sheet(path: Path) -> dict:
    image = Image.open(path).convert("RGBA")
    transforms, cell_w, cell_h = _transforms(image)
    _copy_original_once(path)
    _apply(image, transforms, cell_w, cell_h).save(path)
    return {
        "cell_size": [cell_w, cell_h],
        "foot_line": round(statistics.median(t.bbox[3] for t in transforms)),
        "transforms": [asdict(t) for t in transforms],
    }


def _process_mask(mask_path: Path, reference: dict) -> None:
    image = Image.open(mask_path).convert("RGBA")
    if image.width % 6 or image.height % 4:
        raise ValueError(f"mask {mask_path.name} is not a 6x4 sheet")
    ref_w, ref_h = reference["cell_size"]
    cell_w, cell_h = image.width // 6, image.height // 4
    sx, sy = cell_w / ref_w, cell_h / ref_h
    transforms = [
        FrameTransform(
            row=t["row"], column=t["column"],
            dx=round(t["dx"] * sx), dy=round(t["dy"] * sy),
            bbox=(0, 0, 0, 0),
        )
        for t in reference["transforms"]
    ]
    _copy_original_once(mask_path)
    _apply(image, transforms, cell_w, cell_h).save(mask_path)


def main() -> None:
    reports: dict[str, dict] = {}
    for path in sorted(SHEETS_ROOT.rglob("walk_cycle_*.png")):
        reports[str(path.relative_to(ROOT))] = _process_sheet(path)

    for name, reference_path in MASK_REFERENCES.items():
        mask_path = CHARACTERS / "skin_masks" / name
        key = str(reference_path.relative_to(ROOT))
        if mask_path.exists() and key in reports:
            _process_mask(mask_path, reports[key])

    REPORT_PATH.write_text(json.dumps(reports, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Aligned {len(reports)} walk sheets. Backups: {BACKUP_ROOT}")


if __name__ == "__main__":
    main()
