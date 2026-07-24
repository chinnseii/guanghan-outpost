"""Create right-walk frame 02 from the locked master.

This is the requested third pose: the near right foot bears weight on the shared
baseline; the far left foot is only slightly lifted.  Head, hair, face, and
torso pixels are retained from the master.
"""
from pathlib import Path
from PIL import Image, ImageDraw

master = Image.open("user/walk_frame_test/female_light_black_longhair_right_master.png").convert("RGBA")
out = master.copy()
d = ImageDraw.Draw(out)

def bg(y):
    return master.getpixel((20, y))

for y in range(292, 389):
    d.line((93, y, 222, y), fill=bg(y))

OUT = (14, 20, 19, 255)
FAR_D = (59, 79, 79, 255)
FAR_M = (99, 121, 122, 255)
FAR_L = (144, 163, 163, 255)
NEAR_M = (171, 193, 193, 255)
NEAR_L = (226, 235, 228, 255)
HI = (242, 245, 233, 255)
SKIN = (246, 207, 153, 255)

def poly(points, fill, width=0):
    d.polygon(points, fill=fill)
    if width:
        d.line(points + [points[0]], fill=OUT, width=width, joint="curve")

# Passing-pose arms: both closer to the suit, while retaining far/near values.
poly([(140, 235), (148, 237), (158, 253), (166, 267), (162, 274), (155, 271),
      (148, 258), (141, 246)], FAR_M, 3)
d.line([(145, 242), (157, 264)], fill=FAR_L, width=3)
poly([(159, 267), (166, 269), (169, 275), (165, 281), (159, 278)], SKIN, 2)

poly([(119, 245), (130, 246), (127, 266), (121, 281), (115, 289), (108, 286),
      (108, 279), (114, 267)], NEAR_L, 3)
d.line([(123, 251), (119, 273)], fill=NEAR_M, width=3)
poly([(108, 280), (115, 281), (117, 287), (113, 293), (107, 290)], SKIN, 2)

# Far anatomical LEFT leg: clearly bent and lifted; dark boot stays above ground.
poly([(132, 286), (149, 287), (151, 303), (142, 318), (132, 333), (121, 342),
      (111, 339), (110, 331), (121, 317), (128, 302)], FAR_M, 3)
d.line([(140, 294), (134, 315), (121, 333)], fill=FAR_L, width=4)
poly([(108, 336), (122, 338), (132, 344), (132, 353), (124, 359), (109, 356),
      (102, 350), (103, 341)], FAR_D, 3)
d.line([(108, 346), (124, 351)], fill=FAR_L, width=3)

# Near anatomical RIGHT leg: broad, readable support leg with a full planted boot.
poly([(148, 287), (164, 289), (171, 308), (176, 327), (180, 347), (179, 356),
      (170, 359), (162, 352), (157, 333), (152, 316), (143, 303)], NEAR_L, 3)
d.line([(158, 298), (165, 319), (172, 348)], fill=NEAR_M, width=5)
poly([(166, 351), (187, 351), (200, 358), (200, 368), (193, 373), (169, 373),
      (161, 367)], NEAR_L, 3)
d.line([(166, 361), (195, 363)], fill=NEAR_M, width=4)
d.line([(177, 354), (187, 357)], fill=HI, width=3)

# Fixed pelvis edge above limb roots.
d.line([(132, 286), (148, 286), (163, 289)], fill=OUT, width=2)

Path("user/walk_frame_test").mkdir(parents=True, exist_ok=True)
out.save("user/walk_frame_test/female_light_black_longhair_right_02.png")
