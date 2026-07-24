from pathlib import Path
from zipfile import ZipFile


SOURCE = Path("user/female_light_black_longhair_walk.zip")
MEMBER = "female_longhair_walk_4dir_6frame_v3_frames/female_longhair_walk_right_00.png"
OUTPUT = Path("user/walk_frame_test/female_light_black_longhair_right_00_preview.png")

with ZipFile(SOURCE) as archive:
    OUTPUT.write_bytes(archive.read(MEMBER))
