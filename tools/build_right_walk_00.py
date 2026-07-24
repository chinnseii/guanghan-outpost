"""Create one locked-master right-walk contact frame.

The master is copied first; pixels above the hip are never changed.  Only the
four limbs/boots are reposed on the same canvas and shared 371px foot baseline.
"""
from pathlib import Path
from PIL import Image, ImageDraw

master = Image.open("user/walk_frame_test/female_light_black_longhair_right_master.png").convert("RGBA")
out = master.copy()
d = ImageDraw.Draw(out)

# Reconstruct the unobstructed pink backdrop in the lower-limb edit region.
def bg(y):
    return master.getpixel((20, y))

for y in range(292, 389):
    d.line((93, y, 222, y), fill=bg(y))

# Palette sampled from the locked master: outline, far (dark), near (light).
OUT = (14, 20, 19, 255)
FAR_D = (59, 79, 79, 255)
FAR_M = (99, 121, 122, 255)
FAR_L = (144, 163, 163, 255)
NEAR_D = (104, 128, 130, 255)
NEAR_M = (171, 193, 193, 255)
NEAR_L = (226, 235, 228, 255)
HI = (242, 245, 233, 255)
SKIN = (246, 207, 153, 255)

def poly(points, fill, width=0):
    d.polygon(points, fill=fill)
    if width:
        d.line(points + [points[0]], fill=OUT, width=width, joint="curve")

# Far anatomical LEFT arm: forward/right, dark blue-gray, behind the torso.
poly([(139, 234), (148, 236), (164, 258), (179, 276), (176, 284), (168, 284),
      (155, 269), (142, 250)], FAR_M, 3)
d.line([(145, 242), (160, 263), (174, 278)], fill=FAR_L, width=3)
poly([(173, 276), (181, 278), (184, 284), (179, 290), (173, 287)], SKIN, 2)

# Near anatomical RIGHT arm: backward/left, light suit value in front.
poly([(119, 244), (130, 245), (126, 272), (118, 292), (111, 304), (103, 302),
      (102, 294), (110, 281), (114, 258)], NEAR_L, 3)
d.line([(122, 251), (118, 273), (109, 294)], fill=NEAR_M, width=4)
poly([(102, 295), (110, 296), (112, 303), (107, 310), (100, 307)], SKIN, 2)

# Far anatomical LEFT leg: restrained rear push-off, dark blue-gray.
poly([(132, 286), (149, 287), (150, 304), (140, 320), (127, 338), (116, 352),
      (108, 350), (106, 342), (120, 326), (130, 307)], FAR_M, 3)
d.line([(140, 294), (135, 312), (121, 336)], fill=FAR_L, width=4)
poly([(111, 348), (124, 350), (133, 359), (132, 368), (125, 373), (109, 369),
      (104, 362), (105, 354)], FAR_D, 3)
d.line([(110, 360), (125, 366)], fill=FAR_L, width=3)

# Near anatomical RIGHT leg: modest forward/right contact; boot shares baseline.
poly([(148, 287), (163, 289), (169, 309), (176, 326), (184, 344), (190, 353),
      (182, 360), (174, 353), (160, 335), (153, 319), (143, 303)], NEAR_L, 3)
d.line([(158, 298), (163, 319), (177, 346)], fill=NEAR_M, width=4)
poly([(178, 350), (195, 351), (205, 359), (204, 368), (197, 372), (178, 372),
      (172, 366)], NEAR_L, 3)
d.line([(177, 360), (200, 362)], fill=NEAR_M, width=4)
d.line([(185, 354), (194, 357)], fill=HI, width=3)

# Restore the untouched pelvis edge over limb roots, preventing a torso redraw.
d.line([(132, 286), (148, 286), (163, 289)], fill=OUT, width=2)

Path("user/walk_frame_test").mkdir(parents=True, exist_ok=True)
out.save("user/walk_frame_test/female_light_black_longhair_right_00.png")
