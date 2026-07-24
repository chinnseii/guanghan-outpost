"""Create right-walk frame 03 (opposite contact) from the locked master."""
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

# Frame 03 arm reversal: near right arm forward/right; far left arm backward/left.
poly([(139, 235), (149, 237), (145, 260), (135, 280), (128, 294), (119, 292),
      (118, 284), (127, 267), (132, 246)], FAR_M, 3)
d.line([(143, 243), (137, 263), (125, 285)], fill=FAR_L, width=3)
poly([(119, 286), (127, 287), (129, 294), (124, 300), (118, 297)], SKIN, 2)

poly([(119, 244), (130, 246), (140, 264), (154, 282), (162, 290), (158, 298),
      (150, 297), (137, 280), (126, 258)], NEAR_L, 3)
d.line([(123, 251), (137, 274), (154, 290)], fill=NEAR_M, width=4)
poly([(156, 289), (164, 291), (167, 297), (163, 303), (157, 300)], SKIN, 2)

# Far anatomical LEFT leg: moves forward/right and touches the common baseline.
poly([(132, 286), (149, 287), (156, 305), (166, 321), (179, 338), (188, 352),
      (181, 358), (172, 351), (158, 334), (145, 316), (128, 302)], FAR_M, 3)
d.line([(140, 294), (156, 316), (177, 345)], fill=FAR_L, width=4)
poly([(178, 350), (195, 351), (206, 359), (205, 368), (198, 373), (180, 373),
      (173, 366)], FAR_D, 3)
d.line([(178, 360), (201, 363)], fill=FAR_L, width=3)

# Near anatomical RIGHT leg: moves backward/left as the restrained trailing push-off.
poly([(148, 287), (163, 289), (160, 305), (151, 320), (136, 336), (124, 350),
      (115, 348), (113, 340), (128, 324), (143, 305)], NEAR_L, 3)
d.line([(157, 297), (149, 316), (129, 343)], fill=NEAR_M, width=4)
poly([(113, 347), (126, 349), (135, 357), (134, 367), (128, 372), (111, 369),
      (106, 362), (107, 354)], NEAR_L, 3)
d.line([(111, 359), (128, 365)], fill=NEAR_M, width=3)
d.line([(114, 352), (123, 355)], fill=HI, width=3)

d.line([(132, 286), (148, 286), (163, 289)], fill=OUT, width=2)
Path("user/walk_frame_test").mkdir(parents=True, exist_ok=True)
out.save("user/walk_frame_test/female_light_black_longhair_right_03.png")
