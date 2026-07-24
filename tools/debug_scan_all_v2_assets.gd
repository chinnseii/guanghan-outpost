extends SceneTree

const PATHS := [
	"res://assets/art/training_hub_v2/doors/door_frame_horizontal_01.png",
	"res://assets/art/training_hub_v2/doors/door_frame_vertical_01.png",
	"res://assets/art/training_hub_v2/doors/door_sign_air.png",
	"res://assets/art/training_hub_v2/doors/door_sign_greenhouse.png",
	"res://assets/art/training_hub_v2/doors/door_sign_power.png",
	"res://assets/art/training_hub_v2/doors/door_sign_suit.png",
	"res://assets/art/training_hub_v2/doors/door_status_light_amber_01.png",
	"res://assets/art/training_hub_v2/doors/door_status_light_blue_01.png",
	"res://assets/art/training_hub_v2/doors/door_status_light_green_01.png",
	"res://assets/art/training_hub_v2/lighting/ceiling_light_strip_01.png",
	"res://assets/art/training_hub_v2/props/emergency_kit_01.png",
	"res://assets/art/training_hub_v2/props/fire_extinguisher_01.png",
	"res://assets/art/training_hub_v2/props/hub_console_01.png",
	"res://assets/art/training_hub_v2/props/storage_shelf_01.png",
	"res://assets/art/training_hub_v2/tiles/floor_grate_center_01.png",
	"res://assets/art/training_hub_v2/tiles/floor_maintenance_mark_01.png",
	"res://assets/art/training_hub_v2/tiles/floor_plate_inspection_01.png",
	"res://assets/art/training_hub_v2/tiles/floor_plate_plain_01.png",
	"res://assets/art/training_hub_v2/walls/wall_corner_outer_01.png",
	"res://assets/art/training_hub_v2/walls/wall_corner_outer_rot_0.png",
	"res://assets/art/training_hub_v2/walls/wall_corner_outer_rot_180.png",
	"res://assets/art/training_hub_v2/walls/wall_corner_outer_rot_270.png",
	"res://assets/art/training_hub_v2/walls/wall_corner_outer_rot_90.png",
	"res://assets/art/training_hub_v2/walls/wall_horizontal_run_01.png",
	"res://assets/art/training_hub_v2/walls/wall_vent_01.png",
	"res://assets/art/training_hub_v2/walls/wall_vertical_run_01.png",
]

static func _is_bad_pixel(image: Image, x: int, y: int, w: int, h: int) -> bool:
	var c := image.get_pixel(x, y)
	if c.a <= 0.0:
		return false
	var hue_deg := c.h * 360.0
	if hue_deg >= 250.0 and hue_deg <= 335.0 and c.s >= 0.3 and c.v >= 0.12:
		return true
	var on_border := x == 0 or y == 0 or x == w - 1 or y == h - 1
	if on_border and c.v > 0.85 and c.s < 0.2:
		var ix := x
		if x == 0: ix = clampi(2, 0, w - 1)
		elif x == w - 1: ix = clampi(w - 3, 0, w - 1)
		var iy := y
		if y == 0: iy = clampi(2, 0, h - 1)
		elif y == h - 1: iy = clampi(h - 3, 0, h - 1)
		var inner := image.get_pixel(ix, iy)
		if not (inner.a > 0.0 and inner.v > 0.85 and inner.s < 0.2):
			return true
	return false

func _initialize() -> void:
	var total_bad := 0
	for path in PATHS:
		var tex: Texture2D = load(path)
		if tex == null:
			print(path, " -> FAILED TO LOAD")
			continue
		var image: Image = tex.get_image()
		if image.is_compressed():
			image.decompress()
		var w := image.get_width()
		var h := image.get_height()
		var bad := 0
		for y in range(h):
			for x in range(w):
				if _is_bad_pixel(image, x, y, w, h):
					bad += 1
		total_bad += bad
		print(path, " size=", w, "x", h, " bad_pixels=", bad)
	print("=== TOTAL bad pixels across all V2 assets: ", total_bad, " ===")
	quit()
